global class HD_ChangeRequestScheduler implements Schedulable
{

  global void execute(SchedulableContext sc) 
    {
      try{
      
      
      HD_CMR_Schedulerlogic.hourlyStatusCheck();
        
       
     } catch (Exception e) {
        System.debug('Error '+e);
     }
        
    
    }
    
    
   
    
    
    
    
}