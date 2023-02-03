/*

   Author - Anand Hegde Oct 2016
   */

global class ContentVersionTagCopyBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global DMLResults results;


     global Database.QueryLocator start(Database.BatchableContext BC)
     {
         results= new DMLResults(); 
         results.storeObjectState();
         return Database.getQueryLocator([select id, tagcsv, tag__c from ContentVersion where isLatest=true]);
             //and tagcsv!=null and tag__c!=null]); 
             // tagcsv cant be filtered in query call
     }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<ContentVersion> cvList = (List<ContentVersion>)scope;

        List<ContentVersion> cvListToBeUpdated = NAPUtilClass.getFilesToBeUpdated(cvList);

        if(cvListToBeUpdated.size()>0)
        {
            results.add(Database.update(cvListToBeUpdated,false),cvListToBeUpdated);
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        System.Debug(LoggingLevel.Error, 'AGH_D finish method');
        results.withJobName('ContentVersion Tag Copy').toAddress(NAPSettings.getValue('ContentVersionTagCopyBatchEmail')).sendLogMail();
        results.withClassName('ContentVersionTagCopyBatchClass').insertRecordsInErrorLog();
    }
 }