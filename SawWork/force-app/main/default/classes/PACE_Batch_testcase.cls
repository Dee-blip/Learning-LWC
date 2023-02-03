@isTest
public class PACE_Batch_testcase {
	testmethod static void testBatchClass()	{
     
		PACECustomSettings__c obj=new PACECustomSettings__c(Name='PACE_Batch_mail',Value__c='mpadakan@akamai.com');
		insert obj;

		PACE_Program__c  programObject = new PACE_Program__c (Division__c = 'Media',Name = 'PgmName',Program_Type__c='New Product',Version__c='1.0');
		insert programObject;
		System.assertNotEquals(programObject.id, null);

		Date today = Date.today();
		Date oneMonthBack = today.addMonths(-1);

		programObject.Original_LA__c=today;
		programObject.Original_GA__c=today;
		programObject.Planned_LA__c=oneMonthBack;
		programObject.Planned_GA__c=oneMonthBack;
		update programObject;
		System.assertEquals(programObject.Original_LA__c, today); 
		System.assertEquals(programObject.Original_GA__c, today); 
		System.assertEquals(programObject.Planned_LA__c, oneMonthBack); 
		System.assertEquals(programObject.Planned_GA__c, oneMonthBack);                         


		/*  PACE_BatchSchedule scheduler = new PACE_BatchSchedule();
		scheduler.Object_Type__c = 'PACE_Program__c';
		scheduler.Scheduled_Date_Time__c = System.now();
		scheduler.Status__c = 'Scheduled';
		insert scheduler;*/

		//PACE_Batch bc = new PACE_Batch();
		////bc.soql = 'Select Id From PACE_Program__c Limit 200';

		//Test.startTest();
		//Database.executeBatch(bc);
		//Test.stopTest();

		Test.startTest();
	    Datetime dt = Datetime.now().addSeconds(1);
	    String CRON_EXP = dt.second() + ' ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
	    String jobId = System.schedule('Test_Run', CRON_EXP, new PACE_BatchSchedule());
	    Test.stopTest();
	    // Get the information from the CronTrigger API object
	    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	    System.assertEquals(CRON_EXP, ct.CronExpression);


	}
}