/* ========================================================================
    Author: Vandhana Krishnamurthy
    Description: Batch Class to delete Billing Queue data for every month
    Created Date : 11/25/2015
    ======================================================================== */
global class PSA_DeleteBillingQueueData implements Database.Batchable<sObject>
{
PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');  
String fromEmailAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c.trim();  
    String orgWideEmailId = [select Id from OrgWideEmailAddress where Address= :fromEmailAddress limit 1].Id;

private String query;

global Database.QueryLocator start(Database.BatchableContext BC)
    {
        query = 'SELECT Id FROM pse__Billing_Queue__c'; //add created date filter
        if(Test.isRunningTest())
        {
   query = 'SELECT Id FROM pse__Billing_Queue__c LIMIT 200'; //add created date filter
}

        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {         
        //Delete Billing Queue Data
    delete (List<pse__Billing_Queue__c>)scope;
        //delete scope;
        Database.emptyRecycleBin(scope);
    }
    
    global void finish(Database.BatchableContext BC)
    {
        AsyncApexJob a =[SELECT Id, NumberOfErrors, JobItemsProcessed,TotalJobItems FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        objEmail = new Messaging.Singleemailmessage();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setOrgWideEmailAddressId(orgWideEmailId);
        objEmail.setToAddresses(new list<String>{EnggEmail.Value__c});
        objEmail.setSubject('Notification : Billing Queue records deleted');
        objEmail.setPlainTextBody('The batch Apex job to delete Billing Queue records processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures.');
         mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);
    }
  
}