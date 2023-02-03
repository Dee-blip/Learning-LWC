global with sharing class SF1_MobileTaskManagementAppController
{
    public SF1_MobileTaskManagementAppController()
    {
        
    }
    
    /*returns list of opportunities where current user is owner*/
    @AuraEnabled
    public static List<Opportunity> getOpportunities()
    {
        Id ownerId = UserInfo.getUserId();
        List<Opportunity> opptyrelatedToCurrentUser = SF1_OpportunityService.getOpportunitiesForCurrentOwner(ownerId);
        return opptyrelatedToCurrentUser;
    }
    
    @AuraEnabled
    public static Order_Approval__c getOARelatedData(Id oaID)
    {
        Order_Approval__c oa = [SELECT Id, Name, Approvals_Required__c, Associated_Opportunity__r.Name, Associated_Account__c,
                                Associated_Opportunity_Sales_Stage__c, Order_Expires_Unless_Duly_Executed_By__c, Opportunity_Owner__c, Type__c,
                                AKAM_OrderApproval_ID__c, Rebate__c, Discount__c, Discount_Status__c, Small_Deal__c
                                FROM Order_Approval__c where Id=:oaID limit 1];
        return oa;
    }
    
    @AuraEnabled
    public static String createNewTask(Map<String, String> paramMap)
    {
        System.debug('paramMap :'+paramMap);
        Task tsk = new Task();
        tsk.OwnerId = paramMap.get('tsk1_lkid');
        tsk.WhatId  = paramMap.get('WhatId');
        tsk.Subject  = paramMap.get('tsk5');
        if(!(paramMap.get('subject')).equals('---None---'))
        {
            tsk.Subject  = paramMap.get('subject');
        }
        tsk.Status  = paramMap.get('status');
        tsk.Priority  = paramMap.get('priority');
        tsk.Description   = paramMap.get('description');
        
        
        if(paramMap.get('RecordType')!=null)
        {
             tsk.RecordTypeId    = String.valueOf(paramMap.get('RecordType'));
        }
        
        
        if(paramMap.get('activityDate')!=null && paramMap.get('activityDate')!='')
        {
             tsk.ActivityDate    = Date.valueOf(paramMap.get('activityDate'));
        }
        
        
        
        
        //if(paramMap.get('legalFollowUpNeeded')!=null)
        //{
             //tsk.Legal_Followup_Needed__c    = Boolean.valueOf(paramMap.get('legalFollowUpNeeded'));
        //}
        
        try
        {
            insert tsk;
        }
        catch(Exception e)
        {
          return e.getMessage();
        }
        return 'success';
    }
    
    
    @AuraEnabled
    public static Order_Approval__c getOrderApproval(Id opptyId)
    {
        Order_Approval__c oa = SF1_OpportunityService.getOAForCurrentOpportunity(opptyId);
        return oa;
    }
    
    @AuraEnabled
    public static Order_Approval__c getOrderApprovalById(Id oaId)
    {
        Order_Approval__c oa = [SELECT Id, Name, Approvals_Required__c, Associated_Opportunity__r.Name, Associated_Account__c,
                                Associated_Opportunity_Sales_Stage__c,Order_Expires_Unless_Duly_Executed_By__c,  Opportunity_Owner__c, Type__c,
                                AKAM_OrderApproval_ID__c, Rebate__c, Discount__c, Discount_Status__c, Small_Deal__c
                                FROM Order_Approval__c where Id=:oaId limit 1];
        return oa;
    }
    
    @AuraEnabled
    public static List<String> loadPickListValuesFromUtil(String sobjectName, String picklistFieldName)
    {
        List<String> options = GSMLite_UtilClass.populatePickList(sobjectName,picklistFieldName);
        return options;
    }
    
    @AuraEnabled
    public static List<Task> getTasksRelatedToOrderApproval(Id oaId,List<String> listOfStatus)
    {
        /*List<Task>  taskList; 
        if(oaId !=null)
        {
        taskList = [SELECT Id, OwnerId , WhatId, Subject, Status,Priority, Description FROM Task where WhatId= :oaId and Status IN :listOfStatus  Order By CreatedDate Desc limit 1000];
        }
        
        else 
            taskList = null;
        */
        System.debug('oaId :'+oaId);
        System.debug('listOfStatus :'+listOfStatus);
        List<Task>  taskList = new List<Task>();
        if(oaId!=null)
        {
         taskList = [SELECT Id, OwnerId , WhatId, Subject, Status,Priority, Description FROM Task where WhatId= :oaId and Status IN :listOfStatus  Order By CreatedDate Desc];
        }
        System.debug('taskList :'+taskList);
        return taskList;
    }
    
    
    @AuraEnabled
    public static Map<String, String> Create_Task_Ltng(Id p_orderId,String p_TaskType)
    {
        //PageReference returnURL =  OrderApprovalClass.Create_Task_GetPageReference(p_orderId,p_TaskType); 
        Map<String, String> paramMap = new Map<String, String>();
        return paramMap;
    }
    
    
}