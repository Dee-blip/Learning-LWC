/*Created By: Vivek Baidya
* Created Date: 23-Aug-2018
* JIRA Ticket: SFDC-3262
* Description: Notify opportunity owner and manager when the close date is past due 
               in 7 days, 14 days and 30 days for open opportunities.
*/

global class PastOpptyCloseDateNotificationBatch implements Database.Batchable<sObject>, Database.Stateful {
    global List<Id> recordTypeList;
    global string query;
    global id templateId;
    global integer totalEmailToBeSent;
    global integer totalSuccessEmailSent;
    global list<Date> managerAlertDays;
    global list<OrgWideEmailAddress> orgWideAddress;
    
    global PastOpptyCloseDateNotificationBatch(){
        recordTypeList = new List<Id>();
        recordTypeList.add(GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType'));
        if(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Closed_Opportunity') != null){
            recordTypeList.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('Closed_Opportunity').getRecordTypeId());
        }
        string pastDayCondition = '';
        totalEmailToBeSent = 0;
        totalSuccessEmailSent = 0;
        managerAlertDays = new list<Date>();
        orgWideAddress = [select Id from OrgWideEmailAddress where Address = 'crm-noreply@akamai.com'];
        for(string s : GsmUtilClass.getGSMSettingValue('PastOpptyCloseDate_ManagerAlertDays').split(',')){
            managerAlertDays.add(system.today().adddays(-(Integer.valueOf(s))));
        }
        templateId = [Select Id From EmailTemplate Where DeveloperName = 'Past_Opportunity_Closed_Date_Template'][0].Id;
        query = 'Select Id, OwnerId, Owner.Email, Owner.Manager.Email, CloseDate, StageName, PAE_Channel_Manager_Email__c from Opportunity where IsClosed = false and RecordTypeId IN : recordTypeList';
        for(string s : GsmUtilClass.getGSMSettingValue('PastOpptyCloseDate_AlertDays').split(',')){
            pastDayCondition = pastDayCondition + 'CloseDate = ' + system.now().addDays(-(Integer.valueOf(s))).format('yyyy-MM-dd') + ' OR ';
        }
        if(pastDayCondition != '')
            pastDayCondition = ' and (' + pastDayCondition.substring(0,pastDayCondition.length()-4) + ')';
        query = query + pastDayCondition;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(Opportunity o : scope){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toEmail = new List<String>();
            toEmail.add(o.Owner.Email);
            //mail.setToAddresses(new list<string>{o.Owner.Email});
            if(o.PAE_Channel_Manager_Email__c != null){
                toEmail.add(o.PAE_Channel_Manager_Email__c);
            }
            mail.setToAddresses(toEmail);
            mail.setTemplateId(templateId);
            mail.setSaveAsActivity(false);
            mail.setWhatId(o.Id);
            mail.setTargetObjectId(o.OwnerId);
            if(orgWideAddress.size() > 0)
                mail.setOrgWideEmailAddressId(orgWideAddress[0].Id);
            if(managerAlertDays.contains(o.CloseDate) && o.Owner.Manager != null){
                mail.setCcAddresses(new list<string>{o.Owner.Manager.Email});
            }
            mails.add(mail);
        }
        if(mails.size() > 0){
            totalEmailToBeSent = totalEmailToBeSent + mails.size();
            Messaging.SendEmailResult[] sendEmailResultList = Messaging.sendEmail(mails);
            for(Messaging.SendEmailResult result : sendEmailResultList){
                if(result.isSuccess())
                    totalSuccessEmailSent++;
            }
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        string results = 'Total emails to be sent: '+totalEmailToBeSent+', Success: '+totalSuccessEmailSent+', Failure: '+(totalEmailToBeSent-totalSuccessEmailSent);
        Util.updateCronRunWithResult('Past Oppty Close Date Notification', results);
    }
}