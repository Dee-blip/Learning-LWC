/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  18-Dec-2015    Sonia      CR 3204831   Quick task creation widget is missing "Due Date" for managed security cases  
|  08-Mar-2016	  Aditya	 CR 3332051   Task Exception Message will populate only for non azure case	                                                   
+=====================================================================================================*/
public class QuickTaskCreate {
    public task newtaskToCreate{get;set;}
    public String caseId{get;set;}
    public String taskId{get;set;}
    public boolean defaultFields{get;set;}
    public boolean isMicrosoftAzureAccnt = false;
    
    public QuickTaskCreate(ApexPages.StandardController stdController) {
        caseId = ApexPages.currentPage().getParameters().get('id');
        newtaskToCreate = new task();

        if (caseId != null) {
            string recTypeName  = [Select RecordType.DeveloperName From Case Where Id = :caseId limit 1].RecordType.DeveloperName; 
            if(recTypeName == 'Managed_Security')
            {
                defaultFields = false;
            }
            else
            {
                defaultFields = true;
            }
        }
    }
    
    public void saveLOE(){
        taskId = '';
        Task newTask = newtaskToCreate.clone(false,true,false,false);
        if(defaultFields)
        {
            newTask.status = 'Completed';     
        }
        newTask.activityDate = date.today();
        //newTask.Description  = 'Quick LOE Entry';
        newTask.priority = 'Normal';
        newTask.OwnerId = userinfo.getUserId();
        //should be case id
        if (caseId != null) {
            newTask.whatId = caseId; 
            List<case> cList = [select contactId,IsMicrosoftAzureAccount__c from case where id=:caseId];
            if (cList !=null)
                newTask.whoId = cList.get(0).contactId;
                
            if(cList.get(0).IsMicrosoftAzureAccount__c)
                isMicrosoftAzureAccnt = true;    
        }
        try {
        	insert newTask;
        	taskId = newTask.id;
        }   
        catch(Exception e){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
            if(!isMicrosoftAzureAccnt && newTask.Visibility__c != 'Partner Only') 
            ApexPages.addMessage(myMsg);
        }
    }
    
    public boolean getWidgetEnabled(){
        return caseId != null ;
    }
}