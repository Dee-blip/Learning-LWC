global class HD_ApprovalReminder_Scheduler implements Schedulable {

  global void execute(SchedulableContext sc) 
    {
      try{
      
       HD_Incident_Pending_Approval_Reminder.runPendingApprovalWrapper();
      
      } catch (Exception e) {
        System.debug('Error '+e);
      }
     
      
    }  

}