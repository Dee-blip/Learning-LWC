/**
* This is the scheduler class for the class CPQ_sendEmailtoCarrierSupport 
* 
* @author  Shashank Hegade
* @version 1.0
* @since   2020-05-18
*/
public class CPQ_sendEmailtoCarrierSupportScheduler implements Schedulable{
    public void execute(SchedulableContext sc){
        CPQ_sendEmailtoCarrierSupport sendEmails = new CPQ_sendEmailtoCarrierSupport();
        Id jobId = System.enqueueJob(sendEmails);
        System.debug(LoggingLevel.INFO, 'JOBID-->' + jobId);

    }
}