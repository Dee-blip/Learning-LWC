/******

Author: Sharath Prasanna
Created Date: 13th Aug 2020
Description: This is a Batch job that will set the case lookup and the unique key in the staging records. This is for one time run.

Developer               Date                Jira            Description
Sharath Prasanna     13th Aug 2020       ESESP-3536     	Initial Development
*/

public  class SC_CaseSiebelIssueSyncOneTimeBatch implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts
{
    //The query string
    public string query;
    
    public SC_CaseSiebelIssueSyncOneTimeBatch() 
    {

    }

    public Database.QueryLocator start(Database.BatchableContext BC) 
    {

        //Set the query
        if(String.isBlank(query))
        {
            //Fetch the records where Unique_Key__c is null
            query = 'Select Id,Activity_Id__c,Issue__c,Retry_Count__c,'
                + 'Unique_Key__c,Case__c ' 
                + 'from SC_CaseIssueStaging__c where Unique_Key__c = null';
        }
        query = (System.Test.isRunningTest()) ? query + ' limit 1' : query;

        return Database.getQueryLocator(query);    
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        //List to store the records in the current batch
        List <SC_CaseIssueStaging__c> stagingRecs = (List <SC_CaseIssueStaging__c>) scope;

        //The records to update
        List <SC_CaseIssueStaging__c> stagingToUpdate = new List <SC_CaseIssueStaging__c>();

        //Stores to activity ids
        Set <String> activities = new Set <String>();

        //Akam task id to Case map
        Map <String, Id> taskIdtoCaseId = new Map <String, Id>();

        //Case Id to akam case id map
        Map<Id,String> idToAkam = new Map<Id,String>();

        //loop through the records and get the akam activity Ids 
        for(SC_CaseIssueStaging__c caseIssueRec: stagingRecs)
        {
            activities.add(caseIssueRec.Activity_Id__c);
        }
        //query the task records and check if the parent is a case
        for(Task activityRecord: [Select id, akam_activity_id__c,whatid from Task where 
        akam_activity_id__c in: activities and whatid != null])        
        {
            if(String.valueOf(activityRecord.whatid).startsWith('500') )
            {
                taskIdtoCaseId.put(activityRecord.akam_activity_id__c,activityRecord.whatid);
            }
        }
        //if there are tasks with case as parent
        if(!taskIdtoCaseId.isEmpty())
        {

            String caseId;
            //Query the case records. Get the akam case id
            for(Case caseRec: [Select id, akam_case_id__c from case where id in : taskIdtoCaseId.values()])
            {
                //populate map of case id to akam case id
                idToAkam.put(caseRec.id, caseRec.akam_case_id__c);
            }
            //for each record in the current scope, set the case id and unique key
            for(SC_CaseIssueStaging__c caseIssueRec: stagingRecs)
            {
                //Get the case Id
                caseId = taskIdtoCaseId.get(caseIssueRec.Activity_Id__c);
                if(idToAkam.containsKey(caseId))
                {
                    //set the case lookup and unique key
                    caseIssueRec.Case__c = caseId;
                    caseIssueRec.Unique_Key__c = idToAkam.get(caseId) + caseIssueRec.Issue__c + caseIssueRec.Activity_Id__c;
                    stagingToUpdate.add(caseIssueRec);
                }
            }

            //update staging records
            if(!stagingToUpdate.isempty())
            {
                database.update(stagingToUpdate,false);
            }
        }


    }

    public void finish(Database.BatchableContext BC) 
    {
        PSA_AutoCreateProjectUtil.sendErrorMails('One time Batch is complete!',
                    'SC_CaseSiebelIssueSyncOneTimeBatch complete');
    }
}