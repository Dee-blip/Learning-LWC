/**
 * Name             : ChatterAutoFollowController
  Purpose           :   This class Contains Actual Class + Test Class
                            
  Last Modified Developer  Purpose            
  ============= =========  =======
  17-JUL-13     Appirio    Initial Development 
  05-AUG-14     Himanshu   Removed SeeAllData = True and optimized the class
 */

public class ChatterAutoFollowController{


    public PageReference Nightly(){
        ScheduleAutoFollowScheduler.Start();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Job Has Been Scheduled'));
        return null;
    }
    public PageReference RunNow(){
        ScheduleAutoFollow s = new ScheduleAutoFollow();
        s.autoFollowRecord();
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Chatter Following Has Been Started'));
        return null;
    }
    
    @isTest
    public static void testRunNow(){
    		ScheduleAutoFollowScheduler s = new ScheduleAutoFollowScheduler();
    		s.ScheduleAutoFollowScheduler();
        ChatterAutoFollowController c = new ChatterAutoFollowController();
        System.assert(c.RunNow() == null);
        System.assert(c.Nightly() == null);
    }

}