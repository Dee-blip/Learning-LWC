/**
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Ali Khan		    14/Mar/12   Created this class to stamp SF Reminder & SF QA Reminder Data time fields to fire at specific datetime.
 								CR 1565005 Release Object - Email alerts changes
*/

public class ReleaseTriggerClass 
{	
	public static Boolean updateReminderDateFirstRunFlag=true;
	private static Integer offSetDays=0;
	private	static Integer offSetHours=0;
	private static Integer offSetMinutes=0;
	private static final List<String> REMINDER_OFFSET = GsmUtilClass.GetCustomSettingValue('Release', 'ReminderOffSet_day:hh:mm').split(':');
	
	public ReleaseTriggerClass()
	{
		this.init();
		System.debug('offSetDays=' + offSetDays);
		System.debug('offSetHours=' + offSetHours);
		System.debug('offSetMinutes=' + offSetMinutes);	
	}
	
	public String init()
	{
		// Release#ReminderOffSet_day:hh:mm=-3:13:30
		try 
		{
			if (REMINDER_OFFSET.size()==1)
			{
				offSetDays = Integer.valueOf(REMINDER_OFFSET.get(0));
			}
			else if (REMINDER_OFFSET.size()==2)
			{
				offSetDays = Integer.valueOf(REMINDER_OFFSET.get(0));
				offSetHours = Integer.valueOf(REMINDER_OFFSET.get(1));
			}
			else if (REMINDER_OFFSET.size()==3)
			{
				offSetDays = Integer.valueOf(REMINDER_OFFSET.get(0));
				offSetHours = Integer.valueOf(REMINDER_OFFSET.get(1));
				offSetMinutes = Integer.valueOf(REMINDER_OFFSET.get(2));
			}			
			return '1: Success';
		} 
		catch (Exception ex)
		{
			return '0: Failure; \n' + ex.getMessage();
		}
	}
	
	public void updateReminderDates(List<Release__c> pReleaseList)
	{
		if (!updateReminderDateFirstRunFlag)
			return;
		
		Date tempDate;
		for (Release__c rel : pReleaseList)
		{
			if (rel.Release_Date__c!=null)
				rel.SF_Release_Reminder_Date__c = getReminderDateTime(rel.Release_Date__c);
			//System.debug('release Id=' + rel.Id + '; rel.SF_Release_Reminder_Date__c=' + rel.SF_Release_Reminder_Date__c);
			if (rel.QA_Release_Date__c!=null)
				rel.SFQA_Release_Reminder_Date__c = getReminderDateTime(rel.QA_Release_Date__c);
			//System.debug('release Id=' + rel.Id + '; rel.SFQA_Release_Reminder_Date__c=' + rel.SFQA_Release_Reminder_Date__c);
		}
		updateReminderDateFirstRunFlag=false;
	}
	
	public Datetime getReminderDateTime(Date pReleaseDate)
	{
		Datetime tempDateTimeGmt =  datetime.newInstanceGmt(pReleaseDate.year(), pReleaseDate.month(), pReleaseDate.day(), offSetHours, offSetMinutes, 0);
		return tempDateTimeGmt.addDays(offSetDays);
	}
}