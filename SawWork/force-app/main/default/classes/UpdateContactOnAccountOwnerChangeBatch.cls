global class UpdateContactOnAccountOwnerChangeBatch implements Database.Batchable<Sobject>, Database.Stateful {
    global final string query;
    global list<string> accountIds;
    global string htmlBody='';
    
    global UpdateContactOnAccountOwnerChangeBatch(list<string> accIds){
        accountIds = new list<string>();
        accountIds.addAll(accIds);
        query='select Id, OwnerId, adg_Projected_Account_Owner__c, Projected_SDR__c, Account.OwnerId, Account.adg_Projected_Account_Owner__c, Account.Projected_SDR__c from Contact where AccountId IN : accountIds';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        list<Contact> conListToUpdate = new list<Contact>();
        boolean needUpdate=false;
        for(Contact con : (List<Contact>)scope){
            if(con.OwnerId != con.Account.OwnerId){
                con.OwnerId = con.Account.OwnerId;
                needUpdate = true;
            }
            /* Start of Marketing Team Changes */
            if(con.adg_Projected_Account_Owner__c != con.Account.adg_Projected_Account_Owner__c){
                con.adg_Projected_Account_Owner__c = con.Account.adg_Projected_Account_Owner__c;
                needUpdate = true;
            }
            if(con.Projected_SDR__c != con.Account.Projected_SDR__c){
                con.Projected_SDR__c = con.Account.Projected_SDR__c;
                needUpdate = true;
            }
            /* End of Marketing Team Changes */
            if(needUpdate){
                con.Validation_Override__c = true;
                conListToUpdate.add(con);
            }
        }
        if(conListToUpdate.size()>0){
            GsmUtilClass.FailureEmailClass emailWrapper = GsmUtilClass.doDatabaseUpdateWithErrorEmail(conListToUpdate,'UpdateContactOnAccountOwnerChangeBatch','reassignAccount:conListToUpdate',htmlBody,new list<string>{'Id','AccountId'});
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
                        aR.Is_Contact_Failed__c=true;
                        aR.Validation_Override__c=true; 
                        arToUpdate.add(aR);
                    }
                }
                if(arToUpdate.size()>0){
                    ByPassAndLimitUtils.disable('AccountReassignmentTrigger');
                    GsmUtilClass.doDatabaseUpdate(arToUpdate,'UpdateContactOnAccountOwnerChangeBatch','MarkContactFailure');
                }
            }
        }        
    }
    global void finish(Database.BatchableContext BC) {
        if(Test.isRunningTest()){
            htmlBody='Test';
        }
        if(htmlBody!=''){
            htmlBody = '<table border="1" style="border-collapse: collapse"><tr><th>Contact Id</th><th>Account Id</th><th>Error Message</th></tr>'+htmlBody+'</table>';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            list<string> toAddresses = GsmUtilClass.getAccountReassignSettingValue('AccountReassignmentFailureEmailRecipient').split(',');
            mail.setToAddresses(toAddresses);
            mail.setSubject('Account Reassignment Contact Failures');
            mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}