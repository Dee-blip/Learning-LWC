public with sharing class AccountTeamMemberTriggerHandler extends ApexTriggerHandlerAbstractClass
{
    public AccountTeamMemberTriggerHandler(){}

    public override void beforeInsertBeforeUpdateTrigger()
    {
        
        List<AccountTeamMember> atmTriggerNew = (List<AccountTeamMember>)newList;
        Map<Id,AccountTeamMember> atmOldMap = (Map<Id,AccountTeamMember>)oldMap;
        Set<Id> accountIds=new Set<Id>();
        Set<id> accountIdSet = new Set<id>();
        string dupTeamRole='';
           for(AccountTeamMember atm :atmTriggerNew)
           {
                //if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('DuplicateTeamMemberRoleEnabled')){
        
                    dupTeamRole =GsmUtilClass.getGSMSettingValue('TeamMemberRoleList');
                    if(atm.TeamMemberRole != null && dupTeamRole.contains(atm.TeamMemberRole)){
                        if(Trigger.Isinsert || (Trigger.IsUpdate && util.hasChanges('TeamMemberRole',atmOldMap.get(atm.id),atm)))
                                accountIds.add(atm.AccountId);
                            
                    }
                //}
                 accountIdSet.add(atm.AccountId);

            }
        //SFDC-9170  Rajul Vishwakarma
        //Start
        if(Trigger.isInsert){
            L2Q_AaccountTeamMemberTriggerClass.checkForNonAkamaiUsers(atmTriggerNew);
         }
         //End

                //L2Q_AaccountTeamMemberTriggerClass.checkATMUpdate(atmTriggerNew,accountIdSet);
            
            if(accountIds.size()>0 && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('DuplicateTeamMemberRoleEnabled') || test.isRunningTest())
                     L2Q_AaccountTeamMemberTriggerClass.duplicateRoleCheck(atmTriggerNew,accountIds,dupTeamRole);        
        
        
    }

    public override void afterInsertAfterUpdateTrigger()
    {
        List<AccountTeamMember> upsertATMList = new List<AccountTeamMember>();
        Map<Id,List<AccountTeamMember>> accountIdToATMListMap = new Map<Id,List<AccountTeamMember>>();
                System.Debug(Logginglevel.Error, 'Inside Trigger');

        for(SObject so: newList)
        {
            AccountTeamMember atm = (AccountTeamMember)so;
            System.debug('atm AccountId ' + atm.AccountId);

            if(!accountIdToATMListMap.containsKey(atm.AccountId))
            {
                List<AccountTeamMember> tempList = new List<AccountTeamMember>();
                tempList.add(atm);
                accountIdToATMListMap.put(atm.AccountId,tempList);
            }
            else {
            List<AccountTeamMember> tempList = accountIdToATMListMap.get(atm.AccountId);
            tempList.add(atm);
            accountIdToATMListMap.put(atm.AccountId,tempList);
            }
        }
        System.Debug(Logginglevel.Error, 'Inside Trigger'+accountIdToATMListMap);

        if(!accountIdToATMListMap.isEmpty()) {
            ContractSharing.upsertATMContractShares(accountIdToATMListMap);
            System.debug('accountIdToATMListMap ' + accountIdToATMListMap);
            AccountTeamMemberEventHandler.createRecordsToSync(accountIdToATMListMap.keySet(),'ACCOUNTTEAMMEMBER');
        }
    /** Start added by Chandra for SFDC-9619 */
    L2Q_AaccountTeamMemberTriggerClass.captureATMCreateUpdateDeleteAudit((List<AccountTeamMember>)newList,(Map<Id,AccountTeamMember>)oldMap);
        /**End added by Chandra for SFDC-9619 */

    }

    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        Set<id> accountIdSet = new Set<id>();
        List<AccountTeamMember> oldList= (List<AccountTeamMember>)trigger.old;
        if(trigger.isDelete){
            for(AccountTeamMember atm :oldList){
                accountIdSet.add(atm.AccountId);
            }
            //L2Q_AaccountTeamMemberTriggerClass.checkATMUpdate(oldList,accountIdSet);
        }
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {
        List<AccountTeamMember> atmTriggerOld = (List<AccountTeamMember>)oldList;


        //Set<String> atmsToBeDeleted = new Set<String>();
        Map<Id,Id> accountIDtoATMIdMap = new Map<Id,Id>();
        Map<Id,Id> emptyMap = new Map<Id,Id>();
        Set<Id> userIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        if(Trigger.isDelete )
        {
            // delete Contract Share records
            for(AccountTeamMember atm : atmTriggerOld)
            {
                accountIDtoATMIdMap.put(atm.AccountId,atm.Id);
                //SFDC-6112
                userIds.add(atm.UserId);
                accountIds.add(atm.AccountId);
            }
        }

        if(!accountIDtoATMIdMap.isEmpty())
        {
            ContractSharing.deleteATMOTMContractShares(accountIDtoATMIdMap,emptyMap);
            System.debug('deleted event map ' + accountIDtoATMIdMap);
            AccountTeamMemberEventHandler.createRecordsToSync(accountIDtoATMIdMap.keySet(),'ACCOUNTTEAMMEMBER');
        }
        
        //SFDC-6112
        if(userIds.size()>0 && accountIds.size()>0){
            AccountPlanTriggerClass.stampRemovedTeamMemberEmails(userIds,accountIds,atmTriggerOld);
        }
    /**Start added by Chandra for SFDC-9619 */
        L2Q_AaccountTeamMemberTriggerClass.captureATMCreateUpdateDeleteAudit(atmTriggerOld,(Map<Id,AccountTeamMember>)oldMap);
    /**End added by Chandra for SFDC-9619 */
    }
    

}