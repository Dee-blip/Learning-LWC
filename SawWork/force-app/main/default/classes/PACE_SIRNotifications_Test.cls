@isTest
public class PACE_SIRNotifications_Test {
	testmethod static void testSIRNotifications()
	{
		PACE_Program__c program = new PACE_Program__c (Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Development Phase Pgm',Program_Type__c='New Product',Version__c='1.0');
	    insert program;

	    program.Program_Phase__c = 'Development';
	    program.Status__c = 'In Progress';
	    upsert program;

	    PACE_Review_Calendar__c cal = new PACE_Review_Calendar__c(Review_Date__c=Date.today() + 1, Name='October 15 2017', Cut_off_Date_for_Package_Submission__c=Date.today()+1, Cut_off_Date_to_Schedule_Catalog_Update__c = Date.today()+1, RecordTypeId = Schema.SObjectType.PACE_Review_Calendar__c.getRecordTypeInfosByName().get('SIR Meeting').getRecordTypeId());
	    insert cal;

	    PACECustomSettings__c cs = new PACECustomSettings__c(Name='SIR_CC_Receipients', Value__c='gjain@akamai.com');
	    insert cs;

		Test.startTest();
	    Datetime dt = Datetime.now().addSeconds(1);
	    String CRON_EXP = dt.second() + ' ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
	    String jobId = System.schedule('Test_Run', CRON_EXP, new PACE_SIRNotifications());
	    Test.stopTest();
	    // Get the information from the CronTrigger API object
	    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	    System.assertEquals(CRON_EXP, ct.CronExpression);
	}
}