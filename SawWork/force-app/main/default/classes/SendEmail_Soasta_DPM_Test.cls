/* History:
 * =========================
 *  @author     Ruchika Sharma,     24th May 2017
    Test class for SendEmail_Soasta_DPM
    SFDC-1632
 */
@isTest
public class SendEmail_Soasta_DPM_Test {
    
    @testSetup static void createTestData() {
    	utilTestClass.insertCustomSettings();
    	Account acc = utilTestClass.createAccount(utilTestClass.getRandomString(9));
    	insert acc;
    }

    static testmethod void test1() {
        // startTest/stopTest block to force async processes to run in the test.
        Test.startTest();        
        Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Soasta Accounts With Pool User Email','Soasta Accounts With Pool User Email');
		insert testBatchJob;
		Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
		insert testBatchRun;
		testBatchRun.Trigger_Batch_Run__c = true;
		update testBatchRun;
		System.enqueueJob(new SendEmail_Soasta_DPM());
        Test.stopTest();
       
    }

}