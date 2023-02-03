/* ========================================================================
    Author: Deepak Saxena
    Description: Batch Class to delete App Logs Data
    Created Date : 01/13/2015
    ======================================================================== */
global class PSA_DeleteAppLogData implements Database.Batchable<sObject >
{
    global string errorMessage = 'Batch Class Name = PSA_SendWeeklyRemindersForTimecards: \n';
    global integer noOfErrors = 0;
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        PSA_Settings__c mc = PSA_Settings__c.getValues('Days');
        Integer days = Integer.valueOf(mc.value__c);
        DateTime endDate = DateTime.now().addDays(-days);
        String query = 'Select Id, Name, appirio_core__Category__c, appirio_core__Data__c, appirio_core__Data2__c, appirio_core__Level__c, appirio_core__Message__c, appirio_core__Origin__c From appirio_core__App_Log__c Where CreatedDate <= :endDate';
        if(Test.isRunningTest())
            query = 'Select Id, Name, appirio_core__Category__c, appirio_core__Data__c, appirio_core__Data2__c, appirio_core__Level__c, appirio_core__Message__c, appirio_core__Origin__c From appirio_core__App_Log__c';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    { 
        
        try
        {
            //Creating Back Up Records for App Log
            List<App_Log_BackUp__c> appLogBackUpToInsert = new List<App_Log_BackUp__c>();
            for(appirio_core__App_Log__c a : (List<appirio_core__App_Log__c>)scope)
            {
                App_Log_BackUp__c ab = new App_Log_BackUp__c(Name = a.Name, Category__c = a.appirio_core__Category__c, Data__c = a.appirio_core__Data__c,
                Data2__c = a.appirio_core__Data2__c, Level__c = a.appirio_core__Level__c, Message__c = a.appirio_core__Message__c, Origin__c = a.appirio_core__Message__c);
                appLogBackUpToInsert.add(ab);
            }
            
            insert appLogBackUpToInsert;
            
            // Delete App Log Data
            
            List<appirio_core__App_Log__c> appLogsToDelete = (List<appirio_core__App_Log__c>)scope;
            delete appLogsToDelete;
        }
        
        catch(Exception e)
        {
            string errHdr = ' ******* ';
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
        }
    
    }
    
    global void finish(Database.BatchableContext BC)
    {
        
        // Sending Confirmation Email 
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email, ExtendedStatus From AsyncApexJob where Id = :bc.getJobId()];        

        if(a.Status == 'Completed') {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            // Send the email to all the people mentioned in Custom Label Label.Email_Ids_for_App_Log_Batch_Completion_Email
            String[] toAddresses = (PSA_Settings__c.getInstance('Email').value__c).split(',');
            
            mail.setToAddresses(toAddresses);
            mail.setSenderDisplayName('Batch Processing');
            mail.setSubject('Delete App Logs Batch Job Status: ' + a.Status);
            /* mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems +
                ' batches with '+ a.NumberOfErrors + ' failures. You can find the deleted records in App Log BackUp Object.'); */
            
            mail.setHTMLBody('App Logs Data Deletion Batch Job is complete. <br/> Total Number of Batches Processed: ' + a.TotalJobItems +
                '<br/> Number of Errors:  '+ a.NumberOfErrors + ' <br/> You can find the deleted records under <a href="' +URL.getSalesforceBaseUrl().toExternalForm() +'/aCy/o">App Log BackUp </a> Tab.');
    
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    
    }

}