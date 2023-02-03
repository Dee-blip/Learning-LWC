/**
 * This class contains unit tests for validating the behavior of Release__c object related Apex classes
 * and triggers.
 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Ali Khan		    14/Mar/12   Created this Class.
 								CR 1565005 Release Object - Email alerts changes
 */
@isTest
private class ReleaseTriggerTestClass 
{
	// Release User
	private static User devUser=null;
	private static final List<String> REMINDER_OFFSET = GsmUtilClass.GetCustomSettingValue('Release', 'ReminderOffSet_day:hh:mm').split(':');
	
	/**
		CreateRelease()
		- Method to create single Release record.
	*/
	public static Release__c CreateRelease(String pReleaseName, Date pProdReleaseDate, Date pQAReleaseDate, String pSoxApprovalURL)
	{
		Release__c rel = new Release__c();
		rel.Active__c = true;
		rel.Business_Owner_Approver__c = devUser.Id;
		rel.Manager__c = devUser.Id;
		rel.SQA_Approver__c = devUser.id;
		rel.Technical_Approver__c = devUser.id;
		rel.SOX_Approval_URL__c = pSoxApprovalURL;
		rel.Name = pReleaseName;
		rel.QA_Release_Date__c = pQAReleaseDate;
		rel.Release_Date__c = pProdReleaseDate;
		return rel;
	}
	
	/**
		refreshRelease()
		- Method to refresh single Release record.
	*/
	public static List<Release__c> refreshRelease(Release__c pRelease)
	{
		return refreshRelease(new List<Release__c> {pRelease});
	}
	
	/**
		refreshRelease()
		- Overloaded to refresh bulk Release records
	*/ 
	public static List<Release__c> refreshRelease(List<Release__c> pReleaseList)
	{
		return [Select Active__c, SFQA_Release_Reminder_Date__c, SF_Release_Reminder_Date__c, Business_Owner_Approver__c, Manager__c, SQA_Approver__c,Technical_Approver__c, 
			SOX_Approval_URL__c, Name, QA_Release_Date__c, Release_Date__c From Release__c Where Id IN : pReleaseList];
	}
 
 	/*
 		init()
 		- Method to initialize all components necessary for testing Release record(s)
 	**/
 	private static void init()
 	{
 		User dmlUser = new User(id = UserInfo.getUserId());
 		// create Dev User.
 		if (devUser==null)
 		{
			devUser = utilTestClass.CreateUser('RELEUSER', 'Worldwide', 'Engineering');
			System.runAs(dmlUser)
			{
				insert devUser;
			}
 		}
 	}
 
	/**
		releaseReminderDatePositiveTest()
		- Positive test to ensure Reminder QA & PROD dates are set right.
	*/ 
    static testMethod void releaseReminderDatePositiveTest() 
    {		
		// initialize
		init();
		
		Date qaReleaseDate = date.parse('11/04/2012');
		Date prodReleaseDate = date.parse('11/11/2012');
		Release__c rel = CreateRelease('Test Release', prodReleaseDate, qaReleaseDate, 'www.nowheretorun.com');
		insert rel;
		
		// refresh Release record.
		rel = refreshRelease(rel)[0];
		
		// ensure reminder dates are not null
		System.assertNotEquals(rel.SFQA_Release_Reminder_Date__c, null);
		System.assertNotEquals(rel.SF_Release_Reminder_Date__c, null);
		
		// calculate QA reminder dates based on custom settings.
		Date tmp_Date = rel.QA_Release_Date__c;
		Datetime QAReminderDateTimeGmt =  datetime.newInstanceGmt(tmp_Date.year(), tmp_Date.month(), tmp_Date.day(), Integer.valueOf(REMINDER_OFFSET.get(1)), Integer.valueOf(REMINDER_OFFSET.get(2)), 0);
		QAReminderDateTimeGmt =  QAReminderDateTimeGmt.addDays(Integer.valueOf(REMINDER_OFFSET.get(0)));
		// ensure reminder date is calculated correctly.
		System.assertEquals(QAReminderDateTimeGmt, rel.SFQA_Release_Reminder_Date__c);
		 
		// calculate PROD reminder dates based on custom settings. 
		tmp_Date = rel.Release_Date__c;
		Datetime sfPRODReleaseReminderDate =  datetime.newInstanceGmt(tmp_Date.year(), tmp_Date.month(), tmp_Date.day(), Integer.valueOf(REMINDER_OFFSET.get(1)), Integer.valueOf(REMINDER_OFFSET.get(2)), 0);
		sfPRODReleaseReminderDate =  sfPRODReleaseReminderDate.addDays(Integer.valueOf(REMINDER_OFFSET.get(0)));
		// ensure reminder date is calculated correctly.
		System.assertEquals(sfPRODReleaseReminderDate, rel.SF_Release_Reminder_Date__c);	
    }
}