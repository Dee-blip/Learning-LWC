@isTest
public class PACE_SIRCatalogNotificationsTest {
	testmethod static void testSIRNotifications()
	{
		Features_Toggle__c ft = new Features_Toggle__c(Name='LaunchItemApproval', Toggle__c=true, Disabled_Alert_Message__c='This feature is currently unavailable. Sorry for the inconvenience. Please contact your System Administrator for assistance.');
	    insert ft;

	    PLM_Custom_Settings__c plmCs = new PLM_Custom_Settings__c(Name='LaunchApprvl#Division', value__c='Media:Service and Support:Web Experience:Carrier Products:Emerging Products:Security:Luna:Other:Web Performance');
	    insert plmCs;

		PACE_Program__c program = new PACE_Program__c (Program_Phase__c = 'Concept', Mail_exception__c = false, Program_Manager__c = UserInfo.getUserId(), Division__c = 'Media',Name = 'Development Phase Pgm',Program_Type__c='New Product',Version__c='1.0');
	    insert program;

	    program.Program_Phase__c = 'Development';
	    upsert program;

	    PACE_Review_Calendar__c cal = new PACE_Review_Calendar__c(Review_Date__c=Date.today() + 31, Name= String.valueOf(Date.today() + 31), Cut_off_Date_for_Package_Submission__c=Date.today()+31, Cut_off_Date_to_Schedule_Catalog_Update__c = Date.today()+31, RecordTypeId = Schema.SObjectType.PACE_Review_Calendar__c.getRecordTypeInfosByName().get('SIR Meeting').getRecordTypeId());
	    insert cal;

	    PLU__c plu = new PLU__c(Name='Oct-17', PLU_Date__c=Date.today()+31);
	    insert plu;

	    Launch_Item__c li = new Launch_Item__c(Name=String.valueOf(Date.today()+31), Program__c=program.Id, Version_Number__c='1', Activity_Status__c='New Product', Product_Phase__c='LA', Product_Manager__c=UserInfo.getUserId(), PLU__c=plu.Id, Division__c='Media', SIR_Meeting_Date__c=cal.Id, Package_Design_Document__c='');
	    insert li;

	    PACECustomSettings__c cs = new PACECustomSettings__c(Name='SIR_CC_Receipients', Value__c='gjain@akamai.com');
	    insert cs;

		Test.startTest();
	    Datetime dt = Datetime.now().addSeconds(1);
	    String CRON_EXP = dt.second() + ' ' + dt.minute() + ' * ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year();
	    String jobId = System.schedule('Test_Run', CRON_EXP, new PACE_SIRCatalogNotifications());
	    Test.stopTest();
	    // Get the information from the CronTrigger API object
	    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	    System.assertEquals(CRON_EXP, ct.CronExpression);
	}
}