global class BatchableOpportunityShares implements Database.Batchable<sObject>
{
    global Integer FailedRecords = 0;
    global Integer SuccessRecords = 0;

    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        String OpptyRecordType = NAPSettings.getValue('Opportunity_Share_Record_Type');
        List<String> OpptyTypes = OpptyRecordType.trim().split(',');
        System.debug('GSP: '+OpptyTypes);
        return Database.getQueryLocator([select id,Partner_Involved__c,Partner_Involved__r.ParentId,Deal_Type__c,RecordTypeId,AccountID from Opportunity where Deal_Type__c = 'Indirect' and RecordType.Name in :OpptyTypes and Partner_Involved__c != null]);
    }

    global void execute(Database.BatchableContext bc, List<Opportunity> scope)
    {
        Set<Id> IndividualOpptyIds = new Set<Id>();
        Map<Id,Id> partnerGroupIdAccountIdMap=new Map<Id,Id>();
        Map<Id,Id> partnerAccountIdGroupIdMap=new Map<Id,Id>();
        Map<Id,List<OpportunityShare>> opptyIdShareListMap=new Map<Id,List<OpportunityShare>>();
        System.debug('GSP: '+scope);
        for(Opportunity eachOppty : scope)
        {
            IndividualOpptyIds.add(eachOppty.Id);
        }

        Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
        List<String> accIdList = new List<String>();
        Map<Id,Id> oppIdToPartnerInvolved = new Map<Id,Id>();
        List<OpportunityShare> OpportunitySharestoBeCreated=new List<OpportunityShare>();
        for(Opportunity opp : scope)
        {
            oppIdToPartnerInvolved.put(opp.id,opp.Partner_Involved__c);
            accIdList.add(opp.Partner_Involved__c);
        }

        Map<Id,List<Id>> parentHierarchy = new Map<Id,List<Id>>();
        Integer parentHierarchyLevel = Integer.valueOf(NAPSettings.getValue('Opportunity_Share_Hierarchy_Level'));
        parentHierarchy = GSMUtilClass.getAccParentsInHierarchy(accIdList,parentHierarchyLevel);
        System.debug('GSP: '+parentHierarchy);
        List<Id> accountIdList = new List<Id>();
        for(Id accId: parentHierarchy.keySet())
        {
            accountIdList.add(accId);
            accountIdList.addAll(parentHierarchy.get(accId));
        }
        Map<Id,Set<Id>> opptyToGroupMap = new Map<Id,Set<Id>>();
        System.debug('GSP: '+oppIdToPartnerInvolved);
        if(!oppIdToPartnerInvolved.isEmpty())
        {
            List<UserRole> userRoleIds = [SELECT Id,portalAccountId FROM UserRole where portalAccountId IN :accountIdList and Name like '%Executive'];

            List<Group> userGroups = [select Id,relatedId from Group where relatedId IN :userRoleIds and Type = 'RoleAndSubordinates'];
       
            Map<Id,Id> roleToGroupMap = new Map<Id,Id>();
       
            for(Group userGroup : userGroups)
            {
                roleToGroupMap.put(userGroup.relatedId,userGroup.Id);
            }

            system.debug('GSP: roleToGroupMap: '+roleToGroupMap);

            List<OpportunityShare> existingSharesForOppty = [SELECT Id, Opportunity.RecordTypeId, OpportunityAccessLevel, OpportunityId, UserOrGroupId, Opportunity.Partner_Involved__c,Opportunity.Partner_Involved__r.ParentId FROM OpportunityShare where OpportunityId in :IndividualOpptyIds];
            Map<Id,List<UserRole>> accountIdUserRoleListMap=new Map<Id,List<UserRole>>();

            for(UserRole ur: userRoleIds)
            {
                partnerGroupIdAccountIdMap.put(roleToGroupMap.get(ur.Id),ur.PortalAccountId);
                partnerAccountIdGroupIdMap.put(ur.PortalAccountId,roleToGroupMap.get(ur.Id));
            }

            for(OpportunityShare opptyShare: existingSharesForOppty)
            {
                Id UserGroupAccountId=partnerGroupIdAccountIdMap.get(opptyShare.UserOrGroupId);
                List<OpportunityShare> individualOpportunityShareList=null;

                if(!opptyIdShareListMap.containsKey(opptyShare.OpportunityId))
                {
                   individualOpportunityShareList=new List<OpportunityShare>();
                }
                else
                {
                    individualOpportunityShareList=opptyIdShareListMap.get(opptyShare.OpportunityId);
                }
                individualOpportunityShareList.add(opptyShare);
                opptyIdShareListMap.put(opptyShare.OpportunityId,individualOpportunityShareList);
            }
            System.debug('GSP: '+opptyIdShareListMap);
        }
        for(Opportunity oppty : scope)
        {
            Boolean isParentAccountShareExists=false;
            
            Boolean isParentAccountsParentShareExists=false;
            Id UserGroupAccountId=null;
            if(opptyIdShareListMap != null)
            {
                if(opptyIdShareListMap.get(oppty.Id)!=null)
                {
                    for(OpportunityShare opptyShare : opptyIdShareListMap.get(oppty.Id))
                    {
                        UserGroupAccountId=partnerGroupIdAccountIdMap.get(opptyShare.UserOrGroupId);
                        if(UserGroupAccountId==opptyShare.Opportunity.Partner_Involved__c)
                        {
                          isParentAccountShareExists=true;
                        }
                        if(UserGroupAccountId==opptyShare.Opportunity.Partner_Involved__r.ParentId)
                        {
                            isParentAccountsParentShareExists=true;
                        }
                    }
                }
            }
            
            if(!isParentAccountShareExists || !isParentAccountsParentShareExists)
            {

                OpportunityShare newOpptyShare = null;
                if(UserGroupAccountId ==null || !isParentAccountShareExists)
                {
                    UserGroupAccountId= oppty.Partner_Involved__c;
                    String userOrGroupId=partnerAccountIdGroupIdMap.get(UserGroupAccountId);
                    if(userOrGroupId!=null)
                    {
                        String currentOppRecordtype = rtMap.get(Oppty.RecordTypeId).getName();
                        if(currentOppRecordtype == 'Deal Reg Unsubmitted')
                        {
                            newOpptyShare=new OpportunityShare(UserOrGroupId=userOrGroupId,OpportunityId = oppty.Id,OpportunityAccessLevel = 'Edit');
                        }
                        else
                        {
                            newOpptyShare=new OpportunityShare(UserOrGroupId=userOrGroupId,OpportunityId = oppty.Id,OpportunityAccessLevel = 'Read');
                        }
                        OpportunitySharestoBeCreated.add(newOpptyShare);
                    }
                }
                if((UserGroupAccountId ==null || !isParentAccountsParentShareExists)&&oppty.Partner_Involved__r.parentId!=null)
                {
                    UserGroupAccountId= oppty.Partner_Involved__r.parentId;  
                    //UserGroupAccountId can be null if parent account is not there
                    //if(UserGroupAccountId!=null){
                    String userOrGroupId=partnerAccountIdGroupIdMap.get(UserGroupAccountId);
                    if(userOrGroupId!=null)
                    {
                        String currentOppRecordtype = rtMap.get(Oppty.RecordTypeId).getName();
                        if(currentOppRecordtype == 'Deal Reg Unsubmitted')
                        {
                            newOpptyShare=new OpportunityShare(UserOrGroupId=userOrGroupId,OpportunityId = oppty.Id,OpportunityAccessLevel = 'Edit');
                        }
                        else
                        {
                            newOpptyShare=new OpportunityShare(UserOrGroupId=userOrGroupId,OpportunityId = oppty.Id,OpportunityAccessLevel = 'Read');
                        }
                        OpportunitySharestoBeCreated.add(newOpptyShare);
                    }                    
                }       
            }
        }

        System.debug('====OpportunitySharestoBeCreated==='+OpportunitySharestoBeCreated);

        if(OpportunitySharestoBeCreated.size()>0)
        {
            try 
            {
                Database.SaveResult[] results = Database.insert(OpportunitySharestoBeCreated,false);
                Integer index = 0;
                List<Error_log__c> erroLogList = new List<Error_log__c>();
                if (results != null)
                {
                    for (Database.SaveResult result : results)
                    {
                        if(result.isSuccess())
                        {
                            SuccessRecords++;
                        }

                        if (!result.isSuccess())
                        {
                            FailedRecords++;
                            Database.Error[] errs = result.getErrors();
                    
                            for(Database.Error err : errs)
                            {
                                Error_log__c erroLog = new Error_log__c(Class__c = 'BatchableOpportunityShares',Error_Message__c = err.getMessage(),RecordId__c = OpportunitySharestoBeCreated.get(index).Id);
                     
                                erroLogList.add(erroLog);
                                System.debug(err.getStatusCode() + ' - ' + err.getMessage());
                            }
                    
                        }
                        index++;
                    }
                    if(!erroLogList.isEmpty())
                        insert erroLogList;
                }

            } 
            catch (Exception err)
            {
                System.debug(err.getTypeName() + ' - ' + err.getCause() + ': ' + err.getMessage());
                Error_log__c erroLog = new Error_log__c(Class__c = 'BatchableOpportunityShares',Error_Message__c = err.getMessage()+'-'+err.getCause());
                insert erroLog;
            }
        }
    }

    global void finish(Database.BatchableContext bc)
    {
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new list<string> {'sganesan@akamai.com'};
        if(FailedRecords > 0 )
        {
            String subject ='Partner Executive Shares Job - Failed Record'+FailedRecords + 'And Processed Record'+SuccessRecords;
            email.setSubject(subject);
            email.setPlainTextBody('Email Alert for exception');
        } 
        else
        {
            String subject ='Partner Executive Shares Job Completed successfully'+ SuccessRecords;
            email.setSubject(subject);
            email.setPlainTextBody('Email Alert for completion');
        }
        email.setToAddresses( toAddresses );
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    }
}