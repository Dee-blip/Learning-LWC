/***
Author: Jaya
Description: This batch class sends out email notifications to Account Team members, resource and the Timecard approver about the negative hour timecards.
Created Date: 14/09/2015
*/

global class FFSendNegativeHourNotification implements Database.Batchable<sObject> {
    
    public String query;
    
    global FFSendNegativeHourNotification() {
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        /*Get all the Time Date records where the rejection reason is due to net negative hours. */
        query = 'Select Id, pse__Date__c, Product_Id__c, Contract_Id__c, pse__Hours__c, pse__Timecard__c, pse__Timecard__r.Name, pse__Timecard__r.pse__Resource__r.Name, pse__Timecard__r.pse__Resource__r.Email, pse__Timecard__r.pse__Approver__r.Name, pse__Timecard__r.pse__Approver__r.Email, pse__Timecard__r.pse__Project__r.pse__Account__c, pse__Timecard__r.pse__Project__r.pse__Account__r.Name, Negative_Notification_Sent__c, Project_Id__c, pse__Timecard__r.pse__Project__r.Owner.Email from pse__Time_Date__c where pse__Hours__c < 0 and Negative_Notification_Sent__c = false and pse__Timecard__r.pse__Status__c = \'Submitted\'';
        if(Test.isRunningTest())
            query = 'Select Id, pse__Date__c, Product_Id__c, Contract_Id__c, pse__Hours__c, pse__Timecard__c, pse__Timecard__r.Name, pse__Timecard__r.pse__Resource__r.Name, pse__Timecard__r.pse__Resource__r.Email, pse__Timecard__r.pse__Approver__r.Name, pse__Timecard__r.pse__Approver__r.Email, pse__Timecard__r.pse__Project__r.pse__Account__c, pse__Timecard__r.pse__Project__r.pse__Account__r.Name, Negative_Notification_Sent__c, Project_Id__c, pse__Timecard__r.pse__Project__r.Owner.Email from pse__Time_Date__c where pse__Hours__c < 0 and Negative_Notification_Sent__c = false and pse__Timecard__r.pse__Status__c = \'Submitted\' limit 2';
        return Database.getQueryLocator(query);
    }

    //test for resource and project manager email ids same case.
    global void execute(Database.BatchableContext BC, List<pse__Time_Date__c> lstTimeDates) 
    {
        //String fromAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c;
        String fromAddress = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'FromEmailAdress'].Value_Long__c ;
        System.debug('From Address: '+fromAddress);
        String orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
        System.debug(orgWideEmailId);
        List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage objEmail;
        Set<Id> accIds = new Set<Id>();
        List<String> sendTo = new List<String>();
        //Map<Id, List<AccountTeamMember>> accIdTeamMembers = new Map<Id, List<AccountTeamMember>>();
        Map<Id,Account> accIdTeamMembers = new Map<Id,Account>();
        List<Account> accDetails = new List<Account>();
        list<pse__Time_Date__c> updateTimeDates = new List<pse__Time_Date__c>();

        /*Get all the account ids that have negative hour timedates that total to a net negative */
        for(pse__Time_Date__c timeDate:lstTimeDates)
        {
            if(timeDate.pse__Timecard__r.pse__Project__r.pse__Account__c != null)
                accIds.add(timeDate.pse__Timecard__r.pse__Project__r.pse__Account__c);      
            //Map<Id, Account> mpAccountTeams= new Map<Id, Account>(new list<Account>(Select Id, (Select User.Email from AccountTeamMember where TeamMemberRole in (‘Sales - Primary’,‘Services - Primary’)) from Account where Id in :accIds));
        }

        //System.debug('Account IDs'+accIds);
        
        if(accIds != null && accIds.size() > 0)
        {
            /*Map of Account Id and Account. Inner query has a list of Account Team Members for this Account. */
            accIdTeamMembers = new Map<Id,Account>(new List<Account>([select id, (select User.Email from AccountTeamMembers where TeamMemberRole in ('Sales - Primary','Services - Primary')) from Account where Id in :accIds]));
            
            /*Send an email to the Resource, Approver of the Timecard and to the list of Account Team Members of that Project.*/
            for(pse__Time_Date__c timeDate:lstTimeDates)
            {
                objEmail = new Messaging.SingleEmailMessage();
                sendTo = new List<String>();
                sendTo.add(timeDate.pse__Timecard__r.pse__Resource__r.Email);
                sendTo.add(timeDate.pse__Timecard__r.pse__Approver__r.Email);
                //Project owner
                sendTo.add(timeDate.pse__Timecard__r.pse__Project__r.Owner.Email);
                
                Account acc = accIdTeamMembers.get(timeDate.pse__Timecard__r.pse__Project__r.pse__Account__c);
                
                if(acc.AccountTeamMembers != null && acc.AccountTeamMembers.size() > 0)
                {
                    for(AccountTeamMember accTeam:acc.AccountTeamMembers)
                    {
                        sendTo.add(accTeam.User.Email);
                    }
                }
                /*Set the list of to addresses, Subject, Body. */
                objEmail.setToAddresses(sendTo);
                objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                objEmail.setSubject('Negative services hours have been reported against ' + timeDate.pse__Timecard__r.pse__Project__r.pse__Account__r.Name + ' for  ' + timeDate.pse__Timecard__r.pse__Resource__r.Name  + ' on ' + timeDate.pse__Date__c);
                objEmail.setHTMLBody('<html><body>Negative services hours have been reported against this Account: ' + timeDate.pse__Timecard__r.pse__Project__r.pse__Account__r.Name + ' for  ' + timeDate.pse__Timecard__r.pse__Resource__r.Name  + ' on ' + timeDate.pse__Date__c +'. Be advised that reporting negative hours will not result in a credit and all hours reported will be invoiced to the Customer. If a credit is intended, this must be raised via the standard credit request process.  If this is the required action, it is strongly recommended that the account team notify the Customer prior to the invoice being released. <br/> Details:<br/>Time Card #: ' + timeDate.pse__Timecard__c+','+ timeDate.pse__Timecard__r.Name + '<br/> Resource Name: ' + timeDate.pse__Timecard__r.pse__Resource__r.Name + 'Date: ' + timeDate.pse__Date__c + '<br/>Project: ' + timeDate.Project_Id__c + '<br/>Contract: ' + timeDate.Contract_Id__c+ '<br/>Product: ' + timeDate.Product_Id__c + '<br/>URL: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + timeDate.pse__Timecard__c+'</body></html>');
                mailsToBeSent.add(objEmail);
                timeDate.Negative_Notification_Sent__c = true;
                updateTimeDates.add(timeDate);
            }
            System.debug('Mails To Be Sent '+mailsToBeSent);
            //System.assertEquals(mailsToBeSent,null);
            if(mailsToBeSent != null && mailsToBeSent.size()>0)
                Messaging.sendEmail(mailsToBeSent,false);
            if(updateTimeDates != null && updateTimeDates.size()>0)
                update updateTimeDates;
        }  
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        //String JobNotificationAdress = PSA_Settings__c.getInstance('JobNotificationAdress').Value__c;
        String JobNotificationAdress = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='JobNotificationAdress'  limit 1].Value_Long__c;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        List<String> toAddresses = new List<String>();
        AsyncApexJob a = 
           [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
            FROM AsyncApexJob WHERE Id =
            :BC.getJobId()];
        toAddresses.add(JobNotificationAdress);
        mail.setToAddresses(toAddresses);
        mail.setSubject('FFSendNegativeHourNotification Apex job is ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        mailsToBeSent.add(mail);
        System.debug('Finish Method mails to be sent '+mailsToBeSent);
        Messaging.sendEmail(mailsToBeSent,false);
    }
    
}