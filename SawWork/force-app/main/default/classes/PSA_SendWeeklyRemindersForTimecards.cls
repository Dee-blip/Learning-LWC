/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for sending weekly email reminder to all Project owners 
    and Time-Card Owners of projects which have saved timecards logged & 
    do not have contract line items associated to perform the necessary action                 
    Created Date : 21/07/2014
    Changes by Sharath: 8th August 2016: setting the test class limit to 2
    ======================================================================== */
global class PSA_SendWeeklyRemindersForTimecards implements Database.Batchable<sObject>
{  
    
    //start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {   
       //fetch all projects and related assignments where the Contract Line Item is missing and has saved timecards
       string query = 'Select Id, pse__Project_Manager__c, (Select pse__resource__c from pse__Assignments__r where Project_Contract_Line_Item__c = null and Id in (Select pse__Assignment__c from pse__Timecard_Header__c where pse__Status__c = \'Saved\')) from pse__Proj__c where pse__Is_Billable__c = true and Id in (Select pse__Project__c from pse__Timecard_Header__c where pse__Assignment__r.Project_Contract_Line_Item__c = null and pse__Status__c = \'Saved\')';
       if(system.Test.isRunningTest())
       {
           //changes by sharath: setting the limit to 2
            //query += ' ORDER BY CreatedDate LIMIT 200';           
           query += ' ORDER BY CreatedDate desc LIMIT 2';           
       }
       return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc,List<pse__Proj__c> lstProjects)
    {                 
         
         //fetch the email template name and from email address from custom setting
         //string emailTemplate = PSA_Settings__c.getInstance('TimeCardReminderTemplate').Value__c.trim(); 
         //string fromEmailAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c.trim();  

         string emailTemplate  = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='TimeCardReminderTemplate'  limit 1].Value_Long__c;
         string fromEmailAddress = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='FromEmailAdress'  limit 1].Value_Long__c;

         string orgWideEmailId = [select Id from OrgWideEmailAddress where Address= :fromEmailAddress limit 1].Id;
         string emailTemplateId = [select Id from EmailTemplate where DeveloperName =:emailTemplate].Id;
         
         Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
         Messaging.Singleemailmessage objEmail;
         set<pse__Assignment__c> assignments = new set<pse__Assignment__c>();
         
         for(pse__Proj__c proj : lstProjects)
         {
             //Create an email that needs to be sent to the Project Manager
             objEmail = new Messaging.Singleemailmessage();
             objEmail.setTemplateId(emailTemplateId);
             objEmail.setTargetObjectId(proj.pse__Project_Manager__c);
             objEmail.setWhatId(proj.Id);
             objEmail.setOrgWideEmailAddressId(orgWideEmailId);
             objEmail.setSaveAsActivity(false) ;
             mailsToBeSent.add(objEmail);
             //Loop through the assignments and create emails for each assignment resource
             for(pse__Assignment__c assignment: proj.pse__Assignments__r)
             {  
                 //Do not send another email if the Project manager is same as the assignment resource
                 if(proj.pse__Project_Manager__c !=  assignment.pse__resource__c)
                 {
                     assignments.add(assignment);   
                 }
             }
         }
         //Fetch all timecard information for the Assignments and create one email for each assignment with the timecard links
         list<pse__Assignment__c> lstAssignments = [Select Name, pse__resource__c, (Select Id from pse__Timecards__r where pse__Status__c = 'Saved') from pse__Assignment__c where Id in :assignments];
         //fetch the environment URL
         string environmentURL = URL.getSalesforceBaseUrl().toExternalForm();
         for(pse__Assignment__c assignment : lstAssignments)
         {
             //Create one email for each assignment
             objEmail = new Messaging.Singleemailmessage();
             objEmail.setTargetObjectId(assignment.pse__resource__c);
             objEmail.setWhatId(assignment.Id);
             objEmail.setOrgWideEmailAddressId(orgWideEmailId);
             objEmail.setSaveAsActivity(false) ;
             string body = 'Hello,\n\nYour time-cards are in saved stage, please take necessary action: \n\nTimecard Link :- \n';
             for(pse__Timecard_Header__c timecard : assignment.pse__Timecards__r)
             {
                 body+= environmentURL  + '/' + timecard.Id + '\n';
             }
             body+='\nThanks,\nAutomated notifications -Time-Card Reminder';
             objEmail.setPlainTextBody(body);
             objEmail.setSubject('Time-Card Reminder: ' + assignment.Name);
             mailsToBeSent.add(objEmail);
         }
         
         //Send all the emails
         Messaging.sendEmail(mailsToBeSent,false);
    }
    
    global void finish(Database.BatchableContext BC)
    {  
        // Query the AsyncApexJob object to retrieve the current job's information.
        AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                  FROM AsyncApexJob WHERE Id = :BC.getJobId()];
                  
        // Send an email to the Apex job's submitter notifying of job completion. 
        //string JobNotificationAdress = PSA_Settings__c.getInstance('JobNotificationAdress').Value__c.trim();
        string JobNotificationAdress  = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='JobNotificationAdress'  limit 1].Value_Long__c;
  
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {JobNotificationAdress};
        mail.setToAddresses(toAddresses);
        mail.setSubject('SendWeelyRemindersForTimecards Apex job is ' + a.Status);
        mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}