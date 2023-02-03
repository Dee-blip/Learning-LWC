@IsTest(seeallData=false)
public class HD_Test_CMRScheduledTimeReminderTest {
    
    static TestMethod void testCMRReminderPositive(){
        
        HD_CMR_ScheduledTimeReminder cmr_reminder = new HD_CMR_ScheduledTimeReminder();
   		String Csec,Cmin,Chr1,Cday,Cmonth,CYear;

   		Datetime  dt1 = System.now();
   		Datetime  dt =  dt1.addDays(2);
		Cmin=String.valueof(dt.minute());
   		Chr1=String.valueof(dt.hour());
   		Cday=String.valueof(dt.day());
   		Cmonth=String.valueof(dt.month());
   		CYear=String.valueof(dt.Year());
   		Csec=String.valueof(dt.addSeconds(8).second());
   		String SchTimer=Csec+' '+Cmin+' '+Chr1+' '+Cday+' '+Cmonth+' ? '+CYear;
		
        String jobId = System.schedule('CMR Scheduled Time Reminder Test', SchTimer, cmr_reminder);
    
           
      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(SchTimer, ct.CronExpression);
    }

}