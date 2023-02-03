global class HD_CMR_Reminder implements Schedulable
{

  global void execute(SchedulableContext sc) 
    {
  
      try{
        HD_ChangeReqMgmt_class.remindUnclosed();
        HD_ChangeReqMgmt_class.autoClose();
      } catch (Exception e) {
        System.debug('Error '+e);
     }
     
    }
  }