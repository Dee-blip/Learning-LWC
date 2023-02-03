public with sharing class CronCleanUp
{
    public static String cleanUp(Integer period)
    {
        List <Cron_Batch_Run__c> batchruns = new List<Cron_Batch_Run__c>();
        
        datetime dt = datetime.now().addDays(-period);
        String res = '0: Error';
        String resIDs = ' ';
        Integer countId = 0;
        Integer limitNo =  Integer.valueof(GsmUtilClass.getGSMSettingValue('Cron_Clean_Up_Limit'));
        //batchruns = [SELECT Name, Id, Period__c, Completed__c, Run_Every__c, CreatedDate
                    //FROM Cron_Batch_Run__c
                    //WHERE CreatedDate < :dt
                    //LIMIT 900]; 
        // Can delete upto 900 records.
        for(Cron_Batch_Run__c cbr:[SELECT Name, Id, Period__c, Completed__c, Run_Every__c, CreatedDate FROM Cron_Batch_Run__c WHERE CreatedDate < :dt LIMIT :limitNo])
        {
            batchruns.add(cbr);
        }
        try{
            delete batchruns;
        }
        catch(Exception e){
            res = '0:Could not delete the records\n' + e.getMessage();
        }

        countId = batchruns.size();
        res = '1:Number of records deleted: ' + countId;// + 'Ids are: ' + resIDs;
        return res;
        
    } 
     //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //static testmethod void test()
    //{
    //    /*Integer cleanAfter = 1;
        
    //    Cron_Batch_Job__c batchJob = new Cron_Batch_Job__c();
    //    batchJob.Name = 'Clean Up : Testcase';
    //    batchJob.Batch_Job_Type__c = 'Clean Up';
    //    batchJob.RecordTypeId = Schema.SObjectType.Cron_Batch_Job__c.getRecordTypeInfosByName().get('Clean Up Job').getRecordTypeId();
    //    batchJob.Clean_After__c = cleanAfter;
        
    //    batchJob.Run_Every__c = 1;
    //    batchJob.Period__c = 'Day';
        
    //    insert batchJob;
        
    //    Cron_Batch_Run__c batchRun = new Cron_Batch_Run__c();
        
    //    batchRun.Trigger_Batch_Run__c = true;
    //    batchRun.Cron_Batch_Job__c = batchJob.Id; 
        
    //    insert batchRun;*/
    //    Integer cleanAfter = 1;
    //    //Changing the checking DateTime to one day before actual clean up job to accommodate Time zone difference.
    //    Integer checkUpto = cleanAfter + 1;
    //    DateTime checkUptoCreatedDateTime = DateTime.now().addDays(-checkUpto);
        
    //    Test.startTest();
    //    Integer batchRunsSize_Before = [select Id from Cron_Batch_Run__c where CreatedDate < :checkUptoCreatedDateTime LIMIT 1000].size();
    //    CronJobTypes.insertBatchJobAndRun('Clean Up', 'Clean Up Job', cleanAfter);
    //    Integer batchRunsSize_After = [select Id from Cron_Batch_Run__c where CreatedDate < :checkUptoCreatedDateTime LIMIT 1000].size();
    //    Test.stopTest();
        
    //    System.debug('after=' + batchRunsSize_After);
    //    System.debug('before=' + batchRunsSize_Before);
    //    system.assert(batchRunsSize_After<=batchRunsSize_Before);
    //}
}