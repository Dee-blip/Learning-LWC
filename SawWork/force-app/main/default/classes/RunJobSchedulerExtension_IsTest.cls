/*
@Created By : Aayushi Agrawal
@Created Date : 18 Dec, 2020
@Task : SFDC-7505
*/
@isTest
public class RunJobSchedulerExtension_IsTest{
    @IsTest
    static void runJobSchedulerIsTest(){
         List <Job_Scheduler__c> lstJobScheduler = new List<Job_Scheduler__c>();
 
        Job_Scheduler__c jobQueueScheduler = new Job_Scheduler__c();
        jobQueueScheduler.Status__c = 'Queued';
        jobQueueScheduler.start_Time__c = System.now();
        jobQueueScheduler.job_type__c = 'Batch';
        jobQueueScheduler.Frequency__c = 'Hour'; 
        jobQueueScheduler.Run_Every__c = 1; 
        jobQueueScheduler.Retry_Count__c = 0;
        jobQueueScheduler.job_id__C  = '28908902892187898778';
        jobQueueScheduler.Active__c = true;
        lstJobScheduler.add(jobQueueScheduler);
         insert  lstJobScheduler;
         
         Test.startTest();
         Test.setCurrentPage(Page.RunJobScheduler);
         ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstJobScheduler);
         RunJobSchedulerExtension job = new RunJobSchedulerExtension(stdSetController);
         job.scheduleEngine();
         job.cancel();
         Test.stopTest();
        
    }
}