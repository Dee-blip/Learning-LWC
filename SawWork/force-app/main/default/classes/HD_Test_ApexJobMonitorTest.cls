@isTest
public class HD_Test_ApexJobMonitorTest {
	public static testMethod void testschedule() {
	
        HDApexJobSubscriber__c js = new HDApexJobSubscriber__c();
        js.Class_Names__c = 'HDApexJobMonitor,HDApexJobMonitorScheduler';
        js.SubscribedEmail__c = 'pprashan@akamai.com';
        js.Last_Seen__c = System.now() - 1;
        insert js; 
		HDApexJobMonitorScheduler ajms = new HDApexJobMonitorScheduler();
        String sch = '0 0 23 * * ?'; 
        String jobID =  system.schedule('HD Apex Job Test1', sch, ajms);   
        System.abortJob((ID)jobID);
        jobID =  system.schedule('HD Apex Job Test1', sch, ajms);   
        System.abortJob((ID)jobID);
        
        Test.StartTest();
        jobID = system.schedule('HD Apex Job Test1', sch, ajms); 
        Test.stopTest(); 
    }
}