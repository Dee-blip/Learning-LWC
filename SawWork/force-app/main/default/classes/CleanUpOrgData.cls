/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for bulk delete of records from an organization
    Created Date : 09 April 2014
    ======================================================================== */
global class CleanUpOrgData implements Database.Batchable<sObject>, Database.Stateful
{
    global String objNames;
    global string currentObject;
    //constructor used for passing the parameters for creating the query
    global CleanUpOrgData(string objectNames)
    {
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        Id profileId = UserInfo.getProfileId();
        string profileName = [Select Name from Profile where Id =:profileId].Name;
        string host = URL.getSalesforceBaseUrl().getHost();
        string checkSandbox = host.substring(host.indexOf('.')+1).left(2); 
        if(environmentSetup.Environment_Type__c.equalsIgnorecase('DR') && profileName == 'System Administrator' && (checkSandbox.equalsignorecase('cs') || system.Test.isRunningTest()))
        {
            integer index = objectNames.indexOf(',');
            if(index > -1)
            { 
                objNames = objectNames.substring(index+1).trim();
                currentObject = objectNames.substring(0, index).trim();
            }
            else
            {
                objNames = '';
                currentObject = objectNames.trim();
            }
        }
        else
        {
            throw new CustomException('This job cannot run in this environment');
        }
    }
   
    //start method that creates the dynamic query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {       
        string query = 'select Id from ' + currentObject;
        if(system.Test.isRunningTest())
            query += ' ORDER BY CREATEDDATE DESC LIMIT 200 ';
        return Database.getQueryLocator(query);    
    }

    //delete the records
    global void execute(Database.BatchableContext bc,List<sObject> lstObjects)
    {        
        database.delete(lstObjects, false);
    }
    
    //BatchApex Completes
    // execution with this finish method
    global void finish(Database.BatchableContext BC)
    {
        if(objNames != null && objNames != '')
        {
            CleanUpOrgData cleanup = new CleanUpOrgData(objNames);
            database.executebatch(cleanup);
        }
        else
        {
            //Query the AsyncApexJob object to retrieve the current job's information.
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                      FROM AsyncApexJob WHERE Id = :BC.getJobId()];
                      
            // Send an email to the Apex job's submitter notifying of job completion. 
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Data Cleanup job completed');
            mail.setPlainTextBody('The data cleanup job has completed.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
        }
    }
    public class CustomException extends Exception {}
}