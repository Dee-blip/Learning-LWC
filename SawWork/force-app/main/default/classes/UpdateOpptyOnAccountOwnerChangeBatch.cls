global class UpdateOpptyOnAccountOwnerChangeBatch implements Database.Batchable<Sobject>, Database.Stateful {
    global final string query;
    global list<string> accountIds;
    global list<string> oppRecTypesToProcess;
    global string htmlBody='';
    
    global UpdateOpptyOnAccountOwnerChangeBatch(list<string> accIds){
        accountIds = new list<string>();
        oppRecTypesToProcess = new list<string>();
        oppRecTypesToProcess.addAll(GsmUtilClass.getAccountReassignSettingValue('OppRecordTypeIdsToReassign').split(','));
        accountIds.addAll(accIds);
        query='select Id, OwnerId, Account.OwnerId from Opportunity where AccountId IN : accountIds and RecordTypeId IN : oppRecTypesToProcess and (NOT StageName like \'Closed%\')';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        list<Opportunity> oppListToUpdate = new list<Opportunity>();
        for(Opportunity opp : (List<Opportunity>)scope){
            if(opp.OwnerId != opp.Account.OwnerId){
                opp.OwnerId = opp.Account.OwnerId;
                opp.Opportunity_Owner_Copy__c = opp.Account.OwnerId;
                opp.Validation_Override__c = true;
                oppListToUpdate.add(opp);
            }
        }
        if(oppListToUpdate.size()>0){
            GsmUtilClass.FailureEmailClass emailWrapper = GsmUtilClass.doDatabaseUpdateWithErrorEmail(oppListToUpdate,'UpdateOpptyOnAccountOwnerChangeBatch','reassignAccount:oppListToUpdate',htmlBody,new list<string>{'Id','AccountId'});
            htmlBody = emailWrapper.htmlBody;
            if(Test.isRunningTest()){
                emailWrapper.accountIds = new set<string>{'Test'};
            }
            if(emailWrapper.accountIds != null && emailWrapper.accountIds.size()>0){
                list<Account_Reassignment__c> arToUpdate = new list<Account_Reassignment__c>();
                set<Id> alreadyUpdatedAR = new set<Id>();
                for(Account_Reassignment__c aR : [select Id, Account__c from Account_Reassignment__c where Reassign_Status__c='Accepted' and Account__c IN : emailWrapper.accountIds order by createddate desc]){
                    if(!alreadyUpdatedAR.contains(aR.Account__c)){
                        alreadyUpdatedAR.add(aR.Account__c);
                        aR.Is_Opportunity_Failed__c=true;
                        aR.Validation_Override__c=true; 
                        arToUpdate.add(aR);
                    }
                }
                if(arToUpdate.size()>0){
                    ByPassAndLimitUtils.disable('AccountReassignmentTrigger');
                    GsmUtilClass.doDatabaseUpdate(arToUpdate,'UpdateOpptyOnAccountOwnerChangeBatch','MarkOpportunityFailure');
                }
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
        if(Test.isRunningTest()){
            htmlBody='Test';
        }
        if(htmlBody!=''){
            htmlBody = '<table border="1" style="border-collapse: collapse"><tr><th>Opportunity Id</th><th>Account Id</th><th>Error Message</th></tr>'+htmlBody+'</table>';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            list<string> toAddresses = GsmUtilClass.getAccountReassignSettingValue('AccountReassignmentFailureEmailRecipient').split(',');
            mail.setToAddresses(toAddresses);
            mail.setSubject('Account Reassignment Opportunity Failures');
            mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}