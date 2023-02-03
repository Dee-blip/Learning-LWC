@isTest
public class JobQueueSchedulerFramework_IsTest {
    
    @TestSetup
    static void setupData(){
        List<Job_Scheduler__c> jobQueueSchedulerList = new List<Job_Scheduler__c>();
        
        Job_Scheduler__c jobQueueScheduler = new Job_Scheduler__c();
        jobQueueScheduler.Status__c = 'Queued';
        jobQueueScheduler.start_Time__c = System.now();
        jobQueueScheduler.job_type__c = 'Batch';
        jobQueueScheduler.Frequency__c = 'Hour'; 
        jobQueueScheduler.Run_Every__c = 1; 
        jobQueueScheduler.Retry_Count__c = 0;
        jobQueueScheduler.job_id__C  = '28908902892187898778';
        jobQueueScheduler.Active__c = true;


        Job_Scheduler__c jobQueueScheduler1 = new Job_Scheduler__c();
        jobQueueScheduler1.Status__c = 'Queued';
        jobQueueScheduler1.start_Time__c = System.now();
        jobQueueScheduler1.job_type__c = 'Queueable';
        jobQueueScheduler1.Frequency__c = 'Hour'; 
        jobQueueScheduler1.Run_Every__c = 1; 
        jobQueueScheduler1.Retry_Count__c = 0;
        jobQueueScheduler1.job_id__C  = '28908902892187898778';
        jobQueueScheduler1.Active__c = true;



        Job_Scheduler__c jobQueueScheduler2 = new Job_Scheduler__c();
        jobQueueScheduler2.Status__c = 'Queued';
        jobQueueScheduler2.start_Time__c = System.now();
        jobQueueScheduler2.job_type__c = 'Callable';
        jobQueueScheduler2.Frequency__c = 'Hour'; 
        jobQueueScheduler2.Run_Every__c = 1; 
        jobQueueScheduler2.Retry_Count__c = 0;
        jobQueueScheduler2.job_id__C  = '28908902892187898778';
        jobQueueScheduler2.Active__c = true;



        Job_Scheduler__c jobQueueScheduler3 = new Job_Scheduler__c();
        jobQueueScheduler3.Status__c = 'Queued';
        jobQueueScheduler3.start_Time__c = System.now();
        jobQueueScheduler3.job_type__c = 'Batch';
        jobQueueScheduler3.Frequency__c = 'Day'; 
        jobQueueScheduler3.Run_Every__c = 1;  
        jobQueueScheduler3.Retry_Count__c = 0;
        jobQueueScheduler3.job_id__C  = '28908902892187898778';
        jobQueueScheduler3.Active__c = true;



        Job_Scheduler__c jobQueueScheduler4 = new Job_Scheduler__c();
        jobQueueScheduler4.Status__c = 'Queued';
        jobQueueScheduler4.start_Time__c = System.now();
        jobQueueScheduler4.job_type__c = 'Batch';
        jobQueueScheduler4.Frequency__c = 'Month'; 
        jobQueueScheduler4.Run_Every__c = 1; 
        jobQueueScheduler4.Retry_Count__c = 0;
        jobQueueScheduler4.job_id__C  = '28908902892187898778';
        jobQueueScheduler4.Active__c = true;



        Job_Scheduler__c jobQueueScheduler5 = new Job_Scheduler__c();
        jobQueueScheduler5.Status__c = 'Queued';
        jobQueueScheduler5.start_Time__c = System.now();
        jobQueueScheduler5.job_type__c = 'Batch';
        jobQueueScheduler5.Frequency__c = 'Year'; 
        jobQueueScheduler5.Run_Every__c = 1; 
        jobQueueScheduler5.Retry_Count__c = 0;
        jobQueueScheduler5.job_id__C  = '28908902892187898778';
        jobQueueScheduler5.Active__c = true;



        Job_Scheduler__c jobQueueScheduler6 = new Job_Scheduler__c();
        jobQueueScheduler6.Status__c = 'Queued';
        jobQueueScheduler6.start_Time__c = System.now();
        jobQueueScheduler6.job_type__c = 'Batch';
        jobQueueScheduler6.Frequency__c = 'Year'; 
        jobQueueScheduler6.Run_Every__c = 1;
        jobQueueScheduler6.Retry_Count__c = 0;
        jobQueueScheduler6.job_id__C  = '28908902892187898778';
        jobQueueScheduler6.Active__c = true;



        jobQueueSchedulerList.add(jobQueueScheduler);
        jobQueueSchedulerList.add(jobQueueScheduler1);
        jobQueueSchedulerList.add(jobQueueScheduler2);
        jobQueueSchedulerList.add(jobQueueScheduler3);
        jobQueueSchedulerList.add(jobQueueScheduler4);
        jobQueueSchedulerList.add(jobQueueScheduler5);
        jobQueueSchedulerList.add(jobQueueScheduler6);
        
        insert jobQueueSchedulerList;
    }
    @IsTest
    static void testJobScheduler(){
        
        Test.startTest();
        //System.runAs(contextuser){
            JobQueueSchedulerFramework myClass = new JobQueueSchedulerFramework ();   
            String chron = '0 0 23 * * ?';        

            JobQueueSchedulerFramework.updateJobDetailRecords('28908902892187898778' , 'test' ,'test' , '', 0 , 0);
       
            system.schedule('Test Sched', chron, myClass);
            List<Job_Run__c> jrList = [select id,status__c from job_run__c];
        List<Job_Scheduler__c> jsList = [select id from Job_Scheduler__c];
            for(Job_Run__c jr : jrList){
                jr.status__c = 'completed';
            }
            
            update jrList;
            system.schedule('Test Sched1', chron, myClass);
                    //}
        Test.stopTest();
        
    }
    @IsTest
    static void testJobScheduler1(){
        
        Test.startTest();
        //System.runAs(contextuser){
            JobQueueSchedulerFramework myClass = new JobQueueSchedulerFramework ();   
            String chron = '0 0 23 * * ?';        

            JobQueueSchedulerFramework.updateJobDetailRecords('28908902892187898778' , 'test' ,'test' , '', 0 , 0);
       
            system.schedule('Test Sched', chron, myClass);
            List<Job_Run__c> jrList = [select id,status__c from job_run__c];
        List<Job_Scheduler__c> jsList = [select id from Job_Scheduler__c];
            for(Job_Run__c jr : jrList){
                jr.status__c = 'completed';
            }
            
            update jrList;
            JobQueueSchedulerFramework.runJob(new List<Id>{jsList[0].id});
        //}
        Test.stopTest();
        
    }

   
}