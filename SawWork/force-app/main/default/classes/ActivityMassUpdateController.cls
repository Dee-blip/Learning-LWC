/*
* This class is to update status or owner of the tasks. 
* 
* Class calls from the Pages ActivityOwnerUpdate and ActivityStatusUpdate
* It accepts tasks list as parameter and taskObj object value
*/
public class ActivityMassUpdateController{
      public Task taskObj{get; set;}
      String checkEmail;
      
     public ActivityMassUpdateController()
      {
        taskObj=new Task();
      }

     public String getCheckEmail(){
     return checkEmail;
     }
     public void setCheckEmail(String checkEmail) {
        this.checkEmail = checkEmail;
     }
     public PageReference updateOwner()
     {
         String allList= System.currentPagereference().getParameters().get('actList');
         List<Id> actvList=allList.split(',',-1);
         List<Task> taskarray=new List<Task>();
         String newOwner=taskObj.OwnerId;
        
        for(Task t:[SELECT Id,OwnerId FROM Task WHERE Id IN:actvList]){
        
            t.OwnerId=newOwner;
            taskarray.add(t);
        }
        
        if(taskarray.size()>0)
            update taskarray;    
         if(checkEmail=='true')
               newOwnerMail(allList);
       // MOB-169 Lightning : Redirect differently to Activity List views
       if(UserInfo.getUiThemeDisplayed() == 'Theme4d')
       {
            return new PageReference('/apex/Lightning_ActivityListView');
       }
       else
       {
            return new PageReference('/home/actlist.jsp');
       }
     }
     public PageReference updateStatus()
     {
         String taskList= System.currentPagereference().getParameters().get('actList');
         List<Id> actvList=taskList.split(',',-1);
         List<Task> taskarray=new List<Task>();
        for(Task t:[SELECT Id,Status FROM Task WHERE Id IN:actvList]){
        
            t.Status=taskObj.Status;
            taskarray.add(t);
        }
 
        if(taskarray.size()>0)
            update taskarray;   
            
        // MOB-169 Lightning : Redirect differently to Activity List views      
        if(UserInfo.getUiThemeDisplayed() == 'Theme4d')
        {
            return new PageReference('/apex/Lightning_ActivityListView');
        }
        else
        {
            return new PageReference('/home/actlist.jsp');
        }
     }
     public PageReference returnPage()
     {
        // MOB-169 Lightning : Redirect differently to Activity List views      
        if(UserInfo.getUiThemeDisplayed() == 'Theme4d')
        {
            return new PageReference('/apex/Lightning_ActivityListView');
        }
        else
        {
            return new PageReference('/home/actlist.jsp');
        }
       
     }
     public void newOwnerMail(String allList)
     {
         EmailTemplate et=[select Id,Body,Subject,HtmlValue from EmailTemplate where Name IN ('ActivityAssignmentEmail')][0];
         String emailSubject=et.Subject;
         User usr=[Select Id,Email from User where Id=:taskObj.OwnerId];
         String urlPath=[Select Division from Organization limit 1][0].Division;
         String fullUrl='';
         List<String> actvList=allList.split(',');
         
         for(String eachId:actvList)
           fullUrl+=urlPath+'/'+eachId+'\n';
           
         String emailBody=et.Body.replace('##urlPath##',fullUrl);
         Messaging.SingleEmailMessage mail = GsmUtilClass.createSingleEmailWithOrgId(usr.Email,'',emailSubject,emailBody,'','');
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
     }
}