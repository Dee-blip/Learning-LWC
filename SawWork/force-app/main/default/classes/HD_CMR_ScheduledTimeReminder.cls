global class HD_CMR_ScheduledTimeReminder implements Schedulable
{

  global void execute(SchedulableContext sc) 
    {
      try{
      
       HD_ChangeReqMgmt_class.remindScheduledDate();
      
      } catch (Exception e) {
        System.debug('Error '+e);
      }
     
      
    }  
    
 }