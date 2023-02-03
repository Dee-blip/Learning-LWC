global class PLM_LaunchItemClass 
{
    
    public static boolean firstRun = true; 
    
    public static Id plmTaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PLM Task').getRecordTypeId();
    
    public static Task CreateTask(Id pOwnerId, String pSubject,Id pWhatId,Date activityDate)
    {
        Task tsk = new Task();
        tsk.Subject = pSubject;
        tsk.WhatId = pWhatId;
        tsk.OwnerId = pOwnerId;
        tsk.RecordTypeId = plmTaskRecTypeId;
        tsk.ActivityDate = activityDate;
        
        return tsk;
        
    }
    
    public static PLM_Task_Notification_User__c CreateTaskList(Id pUserID, Id pLaunchItemId)
    {
        PLM_Task_Notification_User__c temp = new PLM_Task_Notification_User__c();
        temp.Launch_Item__c = pLaunchItemId;
        temp.User__c = pUserID;
        return temp;
    }
    

    public static List<PLM_Task_Notification_User__c> CreateDistributionList(Id pLaunchItemId){
        
             
            PLM_Task_Notification_User__c temp;
            List<PLM_Task_Notification_User__c> notificationList = new List<PLM_Task_Notification_User__c>();
            List<Product_Launch_RASCI_List__c>  rasciList = [Select p.User__c From Product_Launch_RASCI_List__c p 
                                where Product_Line__c in (Select Product_Line_pickList__c From Launch_Item__c where  Id = :pLaunchItemId)];
            
            for(Product_Launch_RASCI_List__c pl: rasciList){
                    
                    temp = new PLM_Task_Notification_User__c();
                    temp.Launch_Item__c = pLaunchItemId;
                    temp.User__c = pl.User__c;
                    notificationList.add(temp);
            }
                
                return notificationList;
        
    }
    
    
    public static Map<String, Date> ResolveDateForTask(Id pLaunchItemId)
    {
        
        Launch_Item__c lic = [Select PLU__r.System_Integration_Review_Date__c, PLU__r.Backend_Integration_Test__c, PLU__r.Package_Design_Submission_Date__c,PLU__r.Product_Launch_Update__c 
        From Launch_Item__c  where Id = :pLaunchItemId]; 
              
        Map<String, Date> milestoneMap = new Map<String, Date>();
        milestoneMap.put( 'Upload Scope Document', lic.PLU__r.Package_Design_Submission_Date__c); 
        milestoneMap.put( 'Upload Product Design Documents', lic.PLU__r.Package_Design_Submission_Date__c); 
        milestoneMap.put( 'Upload Package Design Documents', lic.PLU__r.Package_Design_Submission_Date__c); 
        milestoneMap.put( 'Upload Go-To-Market Design Documents', lic.PLU__r.Package_Design_Submission_Date__c); 
             
        milestoneMap.put('Setup Package Design Review Date', lic.PLU__r.System_Integration_Review_Date__c);
        milestoneMap.put('Assign Readiness Date', lic.PLU__r.System_Integration_Review_Date__c);
        milestoneMap.put('Post Prototype Order Forms', lic.PLU__r.System_Integration_Review_Date__c);
        milestoneMap.put('Setup System Integration Review Date', lic.PLU__r.System_Integration_Review_Date__c);
        milestoneMap.put('Update Product Catalog Structure', lic.PLU__r.System_Integration_Review_Date__c);
        milestoneMap.put('Post Test Order Forms and Invoice Item Designs', lic.PLU__r.System_Integration_Review_Date__c);
        milestoneMap.put('Complete Portal Provisioning', lic.PLU__r.System_Integration_Review_Date__c);
  
        milestoneMap.put('Assign Backend Integration Completion Date', lic.PLU__r.Backend_Integration_Test__c); 
        
        milestoneMap.put('Upload Launch Checklist', lic.PLU__r.Product_Launch_Update__c);
        milestoneMap.put('Upload PLU Presentation', lic.PLU__r.Product_Launch_Update__c);         Integer noOfDays=Integer.valueOf(PLM_Custom_Settings__c.getInstance('LaunchItemCls#NoOfDays').value__c);        Date approvalDueDate=lic.PLU__r.Product_Launch_Update__c;        if(approvalDueDate!=null)        {        milestoneMap.put('Seek Division GM approval', approvalDueDate.addDays(noOfDays));         }        else        {         milestoneMap.put('Seek Division GM approval', approvalDueDate);	
        }
        return milestoneMap;
    }
    
    Webservice static String Create_Task(Id p_launchItemId,String p_TaskType)
	{
		// Initialize static variables
		PageReference returnURL = new Pagereference ('/00T/e?');			

		// Set the "Record Type" to "PLM Task"	
		returnURL.getParameters().put('RecordType', plmTaskRecTypeId);		

		// Set the "Task.Related To" to the Order
		returnURL.getParameters().put('what_id', p_launchItemId);

		// Set the navigation parameters for the URL
		returnURL.getParameters().put('retURL', p_launchItemId);	
		returnURL.setRedirect(true);
		return returnURL.getUrl();		
	}
}