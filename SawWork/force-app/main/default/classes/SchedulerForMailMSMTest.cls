@isTest
public class SchedulerForMailMSMTest {
    @isTest
    static void checkScheduler() {
        // Schedule the test job
        String CRON_EXP = '0 0 0 3 9 ? 2040';
        SchedulerForMailMSM sch = new SchedulerForMailMSM();
        String jobId = System.schedule('MSM-Mail-2-hour job', CRON_EXP, sch);

        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression);

        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);

        // Verify the next time the job will run
        System.assertEquals('2040-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        System.assertEquals(0, Limits.getEmailInvocations());
    }
}