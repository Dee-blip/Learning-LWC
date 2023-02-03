/*
@Created By : Aayushi Agrawal
@Created Date : 18 Dec, 2020
@Task : SFDC-7505
*/
public class RunJobSchedulerExtension {
    public runJobSchedulerExtension(ApexPages.StandardSetController stdController) {
        
        
    }
    public void scheduleEngine(){
        List< AsyncApexJob > jobList = [SELECT Id FROM AsyncApexJob 
        where ApexClass.Name = 'JobQueueSchedulerFramework' AND Status IN ('Holding','Queued','Preparing','Processing')];
        if(jobList.size() == 0){
            try{
                System.schedule('JobQueueSchedulerFramework 1', '0 0 * * * ?', new JobQueueSchedulerFramework());
                apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'Job Scheduled successfully!!'));
                return;
            }catch(Exception e){
                 apexpages.addMessage(new ApexPages.message(Apexpages.Severity.Error,'An Error occured : '+ e.getMessage()));
                 return;
            }
            
        }else{
            apexpages.addMessage(new ApexPages.message(Apexpages.Severity.INFO,'Scheduling engine already running in background!!'));
            return;
        }
    }
    
    public pageReference cancel(){
      Schema.DescribeSObjectResult result = Job_Scheduler__c.SObjectType.getDescribe(); 
      PageReference pageRef = new PageReference('/' + result.getKeyPrefix()); 
      pageRef.setRedirect(true); 
      return pageRef; 

    }
}