global class HD_ChangeRequestStatusUpdater implements Schedulable
{

  global void execute(SchedulableContext sc) 
    {
      try{
       HD_CMR_Schedulerlogic.StatusUpdater15mins();
          
     }catch(Exception e) {
           System.debug('Error '+e);
           
     }finally {
     
       System.abortJob(sc.getTriggerId());
     }

         
    
    }
}