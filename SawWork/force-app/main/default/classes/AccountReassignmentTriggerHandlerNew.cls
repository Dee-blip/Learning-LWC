public without sharing class AccountReassignmentTriggerHandlerNew extends ApexTriggerHandlerAbstractClass {
    public static Boolean firstRunFlag = true;
    public static AccountReassignmentDataProvider dataObj = new AccountReassignmentDataProvider();
    
    public override void beforeInsertBeforeUpdateTrigger(){
        
        list<Account_Reassignment__c> arTriggerNew = (list<Account_Reassignment__c>)newList;
        map<Id,Account_Reassignment__c> arTriggerOldMap = (map<Id,Account_Reassignment__c>)oldMap;
        map<Id,Account_Reassignment__c> accIdToReassignmentMap = new map<Id,Account_Reassignment__c>();
        set<Id> accountIdSet = new set<Id>();
        set<Id> assignToSet = new set<Id>();
        set<Id> assignToUserSet = new set<Id>();
        string salesOpsError= GsmUtilClass.getGSMSettingValue('RevenueCreditSalesOpsError');   // SFDC-7770  

        
        if(firstRunFlag){
            dataObj.setReassignConfigSetting(GsmUtilClass.getKeyValueMetadata('Account_Reassignment_Config__mdt','Value__c','',true));
            dataObj.setReasonCodeSetting(GsmUtilClass.getReasonCodeSetting());
            string gsmSettingDeveloperNames = 'AccReassign_InternalRevAccountToggle,AccountReassignment_ErrorToCompare,AccountReassignment_ErrorToShow,AccTrgrCls_PartnerAdminProfile,AccountReassignment_Prefix,ATMOTMInvalidUserAlias';
            dataObj.setGsmSetting(GsmUtilClass.getKeyValueMetadata('GSM_Settings__mdt','Value__c',gsmSettingDeveloperNames,false));
            dataObj.setCurrentUserId(Userinfo.getUserId());
            
            for(Account_Reassignment__c aR : arTriggerNew){
                accountIdSet.add(aR.Account__c);
                assignToSet.add(aR.Assign_To__c);
                accIdToReassignmentMap.put(aR.Account__c,aR);
            }
            
            dataObj.setAccountIdSet(accountIdSet);
            dataObj.setAssignToRuleIdSet(assignToSet);
            dataObj.setNewReassignmentList(arTriggerNew);
            dataObj.setOldReassignmentMap(arTriggerOldMap);
            dataObj.setAccIdToReassignmentMap(accIdToReassignmentMap);
            set<string> oppRecordTypeIdsToReassign = new set<string>(dataObj.getReassignConfigSetting().get('OppRecordTypeIdsToReassign').split(','));
            dataObj.setReassignOpptyRecTypes(oppRecordTypeIdsToReassign);
            list<string> ReassignReasonValue = new list<string>(dataObj.getReassignConfigSetting().get('Revenue_Credit_Owner_Reason_Value').split(','));   // SFDC-7770
            dataObj.setAccReassignReasonList(ReassignReasonValue);
            dataObj = AccountReassignmentTriggerClass.setDataVariables(dataObj); //Set Account and Account Reassignment rule record.
            //dataObj = AccountReassignmentTriggerClass.setRegionalSalesOps(dataObj);
            dataObj.setAssociatedUserIdSet(new set<Id> {Userinfo.getUserId()});
            dataObj = AccountReassignmentTriggerClass.setUserIdToUserMap(dataObj);
            dataObj = AccountReassignmentTriggerClass.setRelatedOpportunities(dataObj);
            firstRunFlag = false;
        }
        
        if(Trigger.IsInsert)
            AccountReassignmentTriggerClass.preventDuplicateAccountReassignments(dataObj);
        
        Account acc;
        Account_Reassignment_Rule__c assignToRule;
        for(Account_Reassignment__c aR : arTriggerNew){
            acc = dataObj.getAccIdToAccountMap().get(aR.Account__c);
            //SFDC-9288 If account is not found, log error for this record and proceed with other records
            if(acc == null){
				aR.Account__c.addError('The specified Account does not exist.');
                continue;
            }
            if(Trigger.IsInsert){
                assignToRule = dataObj.getRuleIdToRuleMap().get(aR.Assign_To__c);
                aR = AccountReassignmentTriggerClass.setDGRAT(aR,acc,assignToRule,dataObj); //Setting GRATZ value on the Account Reassignment Request Object
                AccountReassignmentTriggerClass.decideAction(aR,dataObj);
                assignToUserSet.add(aR.Assign_To_User__c);
                // SFDC-7770
                if((dataObj.getAccReassignReasonList().contains(aR.Reason_Code__c) || !acc.Revenue_Account__c)
                  && aR.Revenue_credit_Owner__c == null){
                     aR.Revenue_credit_Owner__c = aR.Assign_To_User__c;
                 }
            }
            
            if(Trigger.IsUpdate && aR.Reassign_Status__c == 'Approved' && aR.Reassign_Status__c != arTriggerOldMap.get(aR.Id).Reassign_Status__c)
                aR.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Approved');
            if(Trigger.IsUpdate && aR.Reassign_Status__c == 'Rejected' && aR.Reassign_Status__c != arTriggerOldMap.get(aR.Id).Reassign_Status__c){
                aR.Reassign_Status__c = 'Rejected';
                aR.Rejected_On__c = Date.today();
                aR.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Rejected');
            }
            if(aR.Reassign_Status__c == 'Accepted' || aR.Reassign__c == true)
                AccountReassignmentTriggerClass.accept(aR,dataObj);
            aR = AccountReassignmentTriggerClass.setThirdLevelApproval(aR,dataObj);
            if(aR.Reassign__c)
                aR.Approval_Level__c = 'Reassignment Approved';
            if(Trigger.IsUpdate && aR.Approval_Level__c != arTriggerOldMap.get(aR.id).Approval_Level__c && aR.Approval_Level__c == 'Reassignment Approved')
                AccountReassignmentTriggerClass.accept(aR,dataObj);

                // SFDC-7770
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('RevenueCreditOwnerToggle')){

            if(Trigger.Isupdate && Util.hasChanges('Sales_Ops_Approver__c',arTriggerOldMap.get(aR.id),aR) && aR.Sales_Ops_Approver__c != null
                 && aR.Sales_Ops_Approval_Required__c && aR.Revenue_credit_Owner__c == null && !aR.Reassign__c
                 && acc.Revenue_Account__c && !dataObj.getAccReassignReasonList().contains(aR.Reason_Code__c)){
                     aR.AddError(salesOpsError);
                }
        }

        }
        if(Trigger.IsInsert)
            dataObj.setAssignToUserIdSet(assignToUserSet);
        
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('TransactionalLimitsTracking'))
           GsmUtilClass.captureTransactionalLimits('AccountReassignmentTriggerHandlerNew','beforeInsertBeforeUpdateTrigger',Limits.getHeapSize(),Limits.getLimitHeapSize(),Limits.getCpuTime(),Limits.getLimitCpuTime(),Limits.getDMLStatements(),Limits.getLimitDMLStatements(),Limits.getEmailInvocations(),Limits.getLimitEmailInvocations(),Limits.getQueries(),Limits.getLimitQueries());
    }
    
    public override void afterInsertAfterUpdateTrigger(){
        list<Account_Reassignment__c> arTriggerNew = (list<Account_Reassignment__c>)newList;
        map<Id,Account_Reassignment__c> arTriggerOldMap = (map<Id,Account_Reassignment__c>)oldMap;
        list<Account_Reassignment__c> accReassignmentsToBeDone = new list<Account_Reassignment__c>();
        list<Account_Reassignment__c> accReassignmentsToEscalateList = new list<Account_Reassignment__c>();
        set<Id> requestForSalesAccount = new set<Id>();
        list<Id> approvalRequired = new list<Id>();
        list<Id> noApprovalRequired = new list<Id>();
        set<String> criteriaFields = new set<String>{'Reassign_status__c','Reassign__c'};
        Map<String,AccountReassignmentTriggerClass.ReasonCodeSettings> accReasonCodeSettingsmap =  AccountReassignmentTriggerClass.getAccountReasonCodeSettings(dataObj);
        AccountReassignmentTriggerClass.ReasonCodeSettings reasonCodeSettings;
        map<Id,string> userToAssignToUserProfileMap = new map<Id,string>();
        list<string> includeProfilesIdsList = new list<string>();
        map<id,id> accIdToRevenueCreditOwnerMap=new map<id,id>(); //SFDC-7770

                
        if(Trigger.IsInsert){
            userToAssignToUserProfileMap = AccountReassignmentTriggerClass.getUserIdToProfileIdMap(dataObj.getAssignToUserIdSet());
            for(String includedProfilesIds: GsmUtilClass.getGSMSettingValuePartialMatch('AccReass_AllSalesProfileName_')){
                includeProfilesIdsList.addAll(includedProfilesIds.split(','));
            }
        }
                
        for(Account_Reassignment__c aR : arTriggerNew){
            
            if(aR.Reassign__c == true && (Trigger.IsInsert || (Trigger.IsUpdate && !arTriggerOldMap.get(aR.Id).Reassign__c)))
                accReassignmentsToBeDone.add(aR);
            
            if(Trigger.IsInsert){                
                if(aR.isNetOpsOwnedAccount__c && includeProfilesIdsList.contains(userToAssignToUserProfileMap.get(aR.Assign_To_User__c)))
                    requestForSalesAccount.add(aR.Account__c);
            }
            
            if(aR.Action__c == dataObj.getReassignConfigSetting().get('Action_Active_Approval') &&
                aR.isEscalated__c == true && (arTriggerOldMap.containsKey(aR.Id) && arTriggerOldMap.get(aR.Id).isEscalated__c == false))
                accReassignmentsToEscalateList.add(aR);
            
            if(aR.Reason_Code__c != null){
                string reasonCode = aR.Reason_Code__c.replace(' ','_');
                reasonCode = reasonCode.replace('-','_');
                reasonCodeSettings = accReasonCodeSettingsmap.get(reasonCode);
                if ((Trigger.isInsert && aR.Reassign_status__c=='Approval Pending' && !aR.Reassign__c) ||
                    (Trigger.isUpdate && Util.hasChanges(criteriaFields,aR,arTriggerOldMap.get(aR.id)) && aR.Reassign_status__c=='Approval Pending' && !aR.Reassign__c))
                {
                    if(reasonCodeSettings.approvalRequired){
                        approvalRequired.add(aR.Id);
                    }else{
                        noApprovalRequired.add(aR.Id);
                    }
                }
            }
            //SFDC-7770
            if((Trigger.isinsert || (Trigger.isUpdate && Util.hasChanges('Reassign_Status__c',aR,arTriggerOldMap.get(aR.id)))) && aR.Reassign_Status__c =='Accepted' && aR.Revenue_credit_Owner__c !=null){
                system.debug('inside '); 
                    accIdToRevenueCreditOwnerMap.put(aR.Account__c,aR.Revenue_credit_Owner__c);  
            }
        }
                
        if(accReassignmentsToBeDone.size()>0){
            AccountReassignmentTriggerClass.reassignAccount(accReassignmentsToBeDone,dataObj);
        }
        if(accReassignmentsToEscalateList.size()>0){
            Id pActiveAccountReqEscalationTemplateId = [Select Id, DeveloperName from EmailTemplate where DeveloperName='AccountReassignmentEscalationRequest'][0].Id;
            AccountReassignmentTriggerClass.sendActiveAccountReassignmentEmails(accReassignmentsToEscalateList,pActiveAccountReqEscalationTemplateId,dataObj);
        }
        if(requestForSalesAccount.size()>0){
            AccountReassignmentTriggerClass.updateRequestForSalesAccount(requestForSalesAccount);
        }
        if(approvalRequired.size()>0){
            AccountReassignmentTriggerClass.submitForApproval(approvalRequired);
        }
        if(noApprovalRequired.size()>0){
            AccountReassignmentTriggerClass.updateNoApprovalRequired(noApprovalRequired);
        }
        //SFDC-7770
        if(!accIdToRevenueCreditOwnerMap.isEmpty()){
            AccountReassignmentTriggerClass.updateRevenueCreditOwnerAccount(accIdToRevenueCreditOwnerMap);
        }
        
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('TransactionalLimitsTracking'))
           GsmUtilClass.captureTransactionalLimits('AccountReassignmentTriggerHandlerNew','afterInsertAfterUpdateTrigger',Limits.getHeapSize(),Limits.getLimitHeapSize(),Limits.getCpuTime(),Limits.getLimitCpuTime(),Limits.getDMLStatements(),Limits.getLimitDMLStatements(),Limits.getEmailInvocations(),Limits.getLimitEmailInvocations(),Limits.getQueries(),Limits.getLimitQueries());
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
    }
}