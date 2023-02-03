global class UpdateLeadOnAccountOwnerChangeBatch implements Database.Batchable<Sobject>, Database.Stateful {
    global final string query;
    global list<string> accountIds;
    global list<string> leadRecTypes;
    global string htmlBody='';
    global string marketoLeadRecordTypeId,akamaiLeadRecordTypeId;
    
    global UpdateLeadOnAccountOwnerChangeBatch(list<string> accIds){
        marketoLeadRecordTypeId = MarketingUtilClass.getMarketingSettingsValue('MarketoLeadRecordTypeId');
        akamaiLeadRecordTypeId = MarketingUtilClass.getMarketingSettingsValue('AkamaiLeadRecordTypeId');
        accountIds = new list<string>();
        leadRecTypes = new list<string>();
        accountIds.addAll(accIds);
        leadRecTypes.addAll(new list<string>{marketoLeadRecordTypeId,akamaiLeadRecordTypeId});
        query='select Id, RecordTypeId, adg_Projected_Account_Owner__c, Projected_SDR__c, Associated_Account__r.adg_Projected_Account_Owner__c, Associated_Account__r.Projected_SDR__c from Lead where Associated_Account__c IN : accountIds and (Status = \'New\' OR Status = \'In Process\') and RecordTypeId IN : leadRecTypes';
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        list<Lead> leadListToUpdate = new list<Lead>();
        boolean needUpdate=false;
        for(Lead l : (List<Lead>)scope){
            if(l.adg_Projected_Account_Owner__c != l.Associated_Account__r.adg_Projected_Account_Owner__c){
                l.adg_Projected_Account_Owner__c = l.Associated_Account__r.adg_Projected_Account_Owner__c;
                needUpdate=true;
            }
            if(l.Projected_SDR__c != l.Associated_Account__r.Projected_SDR__c && l.RecordTypeId == marketoLeadRecordTypeId){
                l.Projected_SDR__c = l.Associated_Account__r.Projected_SDR__c;
                needUpdate=true;
            }
            if(needUpdate){
                l.Validation_Override__c = true;
                leadListToUpdate.add(l);
            }
        }
        if(leadListToUpdate.size()>0){
            GsmUtilClass.FailureEmailClass emailWrapper = GsmUtilClass.doDatabaseUpdateWithErrorEmail(leadListToUpdate,'UpdateLeadOnAccountOwnerChangeBatch','reassignAccount:leadListToUpdate',htmlBody,new list<string>{'Id','Associated_Account__c'});
            htmlBody = emailWrapper.htmlBody;
        }
    }
    global void finish(Database.BatchableContext BC) {
        if(Test.isRunningTest()){
            htmlBody='Test';
        }
        if(htmlBody!=''){
            htmlBody = '<table border="1" style="border-collapse: collapse"><tr><th>Lead Id</th><th>Account Id</th><th>Error Message</th></tr>'+htmlBody+'</table>';
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            list<string> toAddresses = GsmUtilClass.getAccountReassignSettingValue('AccountReassignmentFailureEmailRecipient').split(',');
            mail.setToAddresses(toAddresses);
            mail.setSubject('Account Reassignment Lead Failures');
            mail.setHtmlBody(htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}