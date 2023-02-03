@isTest
public class SendEmailOnJobFailure_IsTest {
	
    @IsTest
    static void testJobScheduler(){
        
        Test.startTest();
         List<Job_Scheduler__c> jobQueueSchedulerList = new List<Job_Scheduler__c>();
        
        Job_Scheduler__c jobQueueScheduler = new Job_Scheduler__c();
        jobQueueScheduler.Status__c = 'Queued';
        jobQueueScheduler.start_Time__c = System.now();
        jobQueueScheduler.job_type__c = 'Batch';
        jobQueueScheduler.Frequency__c = 'Hour'; 
        jobQueueScheduler.Run_Every__c = 1; 
        jobQueueScheduler.Retry_Count__c = 0;
        jobQueueScheduler.job_id__C  = '28908902892187898778';
        jobQueueScheduler.Email_Receipients__c = 'aaagrawa@akamai.com';
        jobQueueScheduler.Active__c = true;


        insert jobQueueScheduler;


        Job_Run__c jobDetail = new Job_Run__c();
        jobDetail.Job_Scheduler__c = jobQueueScheduler.id;
        jobDetail.Execution_Time__c = System.now();
        jobDetail.Status__c = 'Holding';
        jobDetail.Class__c = 'test';
        jobDetail.error_message__c = 'test';
        insert jobDetail;        
        SendEmailOnJobFailure.sendEmailOnFailure(new List<ID>{jobQueueScheduler.id});
        Test.stopTest();
        
    }
    
}