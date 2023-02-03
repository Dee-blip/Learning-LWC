/******

Author: Sharath Prasanna
Created Date: 14th July 2020
Description: This Batch class is used to process errored out records in the Staging object.

Developer               Date                Jira            Description
Sharath Prasanna     17th July 2020              		Initial Development
*/
public class SC_CaseSiebelIssueSyncBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts
{
    //The error message variable
    public string errorMessage;
    //The query varible
    public string query;
    //Setting the retry variable
    public Integer retryCount;
    //The constructor. Sets the class variables
    public SC_CaseSiebelIssueSyncBatch()
    {
        errorMessage = '';
        query = '';
    }
    
    //the start method
	public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        //fetch the hierarchy custom setting record for System Admins: this stores the connection credentials
        Id profileId = [SELECT Id FROM Profile WHERE name = 'System Administrator'].Id;
        SC_SiebelIssueSync.ipScrub = SC_Case_Issue_Sync_Admin_Setting__c.getInstance(profileId);
        String certificate = SC_SiebelIssueSync.ipScrub.Client_Certificate__c;
		
        //get a new Token
		SC_SiebelIssueSync.getAccessToken();        
        
        //Update the token in the custom setting
        SC_SiebelIssueSync.ipScrub.Access_Token_Issues_API__c = SC_SiebelIssueSync.accessToken;
        SC_SiebelIssueSync.ipScrub.Token_Expiry_Date_Issues_API__c =  Datetime.now().addHours(12);
        //try catch block for update
        try 
        {
            update SC_SiebelIssueSync.ipScrub;
        } 
        catch (Exception e) 
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync Batch job: Error',e.getMessage());     
        }
        
        
        //Set the status of the records to be considered: Failure and Not Processed
        List<string> status = new List<string>{'Failure','Not Processed'};
        //Set the query: Fetch all the errored out records
        if(String.isBlank(query))
        {
            query = 'Select Id,Activity_Id__c,Issue__c,Retry_Count__c,'
                + 'Unique_Key__c,Case__c,Case__r.AKAM_Case_ID__c,Case__r.CaseNumber ' 
                + 'from SC_CaseIssueStaging__c where Last_Sync_Status__c in :status and Retry_Count__c > 0';
        }
        
        //For test classes: Set limit to 1
        query = (System.Test.isRunningTest()) ? query + ' order by createddate desc limit 1' : query;
		
		//return the query locator        
        return Database.getQueryLocator(query);    
    }
    //The execute method
    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        //Get the records in the current batch
        List <SC_CaseIssueStaging__c> stagingRecs = (List <SC_CaseIssueStaging__c>) scope;
        //system.debug('The recs: ' + stagingRecs);
        //List of Akam activity Ids
        List <String> activities = new List <String>();
        //Set of unique keys
        Set<String> uniqueKeys = new Set<String>();
        //Map of the activity id to the wrapper
        Map<String, SC_SiebelIssueSync.IssueActivityWrapper> activityToWrapper = new Map<String, SC_SiebelIssueSync.IssueActivityWrapper>();
        //Iterative wrapper variable
        SC_SiebelIssueSync.IssueActivityWrapper wrapper;
        //For each record, create the wrapper. Set all values excluding the description
        for(SC_CaseIssueStaging__c stagingRec: stagingRecs)
        {
				wrapper = new SC_SiebelIssueSync.IssueActivityWrapper(stagingRec.Activity_Id__c,stagingRec.Case__c, stagingRec.Case__r.AKAM_Case_ID__c
                                       ,stagingRec.Case__r.CaseNumber, stagingRec.Issue__c, stagingRec.Unique_Key__c, 
                                        '');
                activityToWrapper.put(stagingRec.Activity_Id__c,wrapper);  
            	uniqueKeys.add(stagingRec.Unique_Key__c);
        }
		//system.debug('activityToWrapper ' + activityToWrapper);  
		//Query on Task. get the latest description value      
        for (Task taskRec : [Select AKAM_Activity_ID__c, Description from Task where AKAM_Activity_ID__c in :activityToWrapper.keySet()])
        {
            	//UPdate the desctiption in the wrapper
         		wrapper =  activityToWrapper.get(taskRec.AKAM_Activity_ID__c);
            	wrapper.description = taskRec.Description;
            	activityToWrapper.put(taskRec.AKAM_Activity_ID__c,wrapper);
        }
		//system.debug('activityToWrapper ' + activityToWrapper);        
		//If there are records to be processed: Call the method in the SC_SiebelIssueSync class
        if(!activityToWrapper.isEmpty())
        {
            errorMessage += SC_SiebelIssueSync.syncActivitySiebel(JSON.serialize(activityToWrapper.values()), uniqueKeys,false,true);
        }
        //system.debug('errorMessage ' + errorMessage);        
    }
    //the finish method
    public void finish(Database.BatchableContext BC) 
    {
        //If the error messages from the batches is empty: return success mail
        String emailBody;
        emailBody = !String.isBlank(errorMessage) ? 'The Batch job processes with some errors: ' + errorMessage: 'Successfully Processed!';
        PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync Batch job:',emailBody);     
    }
}