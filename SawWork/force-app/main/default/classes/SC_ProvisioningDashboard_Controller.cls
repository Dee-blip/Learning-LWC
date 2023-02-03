/*
***********************************************************************************************************
Author              :   VIKAS RUDRAPPA
Created             :   02-June-2020
Purpose             :   Controller for Provisioning Dashboard
JIRA Story			:   ESESP-3663 :: Provisioning Dashboard: Provisioning Dashboard and Case Improvements

18 June 2020			Sumukh SS		 ESESP-4067		Changing backend object for saveable filters and adding geo

09 Dec 2020				Tejaswini		ESESP-4234       Added icons for new Priority Type picklist value 
21 Jan 2021				Tejaswini 		ESESP- 4685 	Modified Existing dashboard case filter criteria to display cases with Service=Prolexic as well 
03 May 2021             Tejaswini       ESESP-4953      Changed variable name in search() method
19 Aug 2021             Aditi           ESESP-5670      Removed all occurrence of PS_Product__c and added the Case Product instead
***********************************************************************************************************
*/
public class SC_ProvisioningDashboard_Controller {
    public Static Integer numOfClosedCases=0;
    public Static Integer numberOfOpenCase=0;
    public Static  Integer numOfTasksOpen = 0;
    public Static  Integer numOfTasksCompleted = 0;
    
    //CASE WRAPPER
    public class CaseWrapper
    {
        @AuraEnabled public Case caseRec;
        @AuraEnabled public Id caseId;
        @AuraEnabled public string Geography;
        @AuraEnabled public String hotCustomer;
        @AuraEnabled public Integer casePriorityNum;
        @AuraEnabled public String priorityType;
        @AuraEnabled public String fundType;
        @AuraEnabled public String logoType;
        @AuraEnabled public String deferredRevenue;
        @AuraEnabled public String akamCaseId;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountTier;
        @AuraEnabled public String subject;
        @AuraEnabled public String severity;
        @AuraEnabled public Double ageDays;
		@AuraEnabled public Date requestCompletionDate;
        @AuraEnabled public String shiftOwner;
        @AuraEnabled public Id shiftOwnerId;
        @AuraEnabled public String subType;
        @AuraEnabled public Integer escCount;
        @AuraEnabled public Integer pendingTasksCount;
        //@AuraEnabled public String platformProduct;//Commented for ESESP-5670 - aditi
        @AuraEnabled public String caseProduct;//Updated for ESESP-5670 - aditi
        @AuraEnabled public Id projectId;
        @AuraEnabled public String projectName;
        @AuraEnabled public DateTime lastUpdatedDate;
        @AuraEnabled public Integer lastUpdatedMins;
        @AuraEnabled public String lastUpdatedDateTimeString;
        @AuraEnabled public String lastUpdatedBy;
        
        @AuraEnabled public String caseColour;
        @AuraEnabled public Integer caseColourNum;
        @AuraEnabled public String pendingTaskColour;
        @AuraEnabled public String completionDateColour;
        
        @AuraEnabled public String caseUrl;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String shiftOwnerUrl;
        @AuraEnabled public String projectUrl;
        @AuraEnabled public String lastUpdatedByUrl;
		
        @AuraEnabled public String service;
        @AuraEnabled public String caseStatus;
        @AuraEnabled public String caseType;
        @AuraEnabled public String taskNext;
        @AuraEnabled public String taskCompleted;
        @AuraEnabled public List<Engagement_Request__c> lEscalationRecords;
        @AuraEnabled public String escStatus;
        
    }
    
    //TASK WRAPPER
    public class TaskWrapper
    {
        @AuraEnabled public Task taskRec;
        @AuraEnabled public Id taskId;
        @AuraEnabled public String akamActivityId;
        @AuraEnabled public String relatedCaseAKAMId;
        @AuraEnabled public Id relatedCaseId;
        @AuraEnabled public String relatedCaseAccountName;
        
        @AuraEnabled public String subject;
        @AuraEnabled public String taskDescription;
        @AuraEnabled public String taskType;
        @AuraEnabled public Id assignedToId; 
        @AuraEnabled public String assignedToName;
        @AuraEnabled public String assignedShift;
        @AuraEnabled public String status;
        @AuraEnabled public String taskPriority;
        @AuraEnabled public Integer dueInMins;
        @AuraEnabled public String dueIn;
        @AuraEnabled public String taskColour;
        @AuraEnabled public String taskStatusColour;
        @AuraEnabled public DateTime lastUpdatedDate;
        @AuraEnabled public Integer lastUpdatedMins;
        @AuraEnabled public String lastUpdatedDateTimeString;
        
        @AuraEnabled public String taskUrl;
        @AuraEnabled public String assignedToUrl;
        @AuraEnabled public String caseUrl; 
        @AuraEnabled public String accountUrl;
        //@AuraEnabled public Integer pdCount=2;
    }
    
    //ESCALATION WRAPPER
    public class EscalationWrapper
    {
        @AuraEnabled public Engagement_Request__c escRec;
        @AuraEnabled public Id escRecId;
        @AuraEnabled public String escIDUrl;
        @AuraEnabled public String escID;
        @AuraEnabled public String escStatus;
        @AuraEnabled public String escSubject;
        @AuraEnabled public String escSubjectURL;
        @AuraEnabled public String escSeverity;
        @AuraEnabled public String escOwnerName;
        @AuraEnabled public String escCreated;
        @AuraEnabled public String escClosed;
    }
    
    //HOME SCREEN : Fetch all Case Records
    @AuraEnabled
    public static List<CaseWrapper> getCaseList(String caseSeverity, String casePriority, String caseFundType, String caseLogoType, String caseSubType, String colorCategory, string geos) {
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Id plxTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Provisioning Activity').getRecordTypeId();
        
        Map<String,String> mapSCUtilMDTVal = new Map<String,String>();
        
        List<Case> caseList = new List<Case>();
        List<CaseWrapper> caseWrapperList = new List<CaseWrapper>();
        List<CaseWrapper> finalCaseWrapperList = new List<CaseWrapper>();
        List<String> colVals = new List<String>();
        CaseWrapper caseWrap = new CaseWrapper();      
        
        String sevQuery = '';
        String priorityQuery = '';
        String fundTypeQuery = '';
        String logoTypeQuery = '';
        String subTypeQuery = '';
        string GeoQuery = '';
        
        List<SC_Utility__mdt> lstSCUtilMDT = [SELECT DeveloperName,Value_Text__c
                                              FROM SC_Utility__mdt
                                              WHERE DeveloperName IN ('Owner_Not_Assigned_User_Id','Plx_Products','Plx_Queue_Id','Plx_Service_Values')];
        
        for(SC_Utility__mdt eachRec : lstSCUtilMDT)
        {
            mapSCUtilMDTVal.put(eachRec.DeveloperName,eachRec.Value_Text__c);
        }
        
        List<String> plxProductList = mapSCUtilMDTVal.get('Plx_Products').split(',');
        List<String> plxServiceValueList = mapSCUtilMDTVal.get('Plx_Service_Values').split(',');
        Id plxQId = mapSCUtilMDTVal.get('Plx_Queue_Id');
        
        String caseQuery = 'Select Id, AKAM_Case_ID__c, Account.Name, Case_Account_Name__c,Geography__c , Account.Customer_Tier__c, Subject, Severity__c, Age_days__c, Requested_Completion_Date_UTC__c,'
            			   	+ 'Shift_Owner__c,Shift_Owner__r.Name, Sub_Type__c, LastModifiedDate, LastModifiedBy.Name, Priority_Type__c,Fund_Type__c,Plx_Update__c,Requested_Completion_Time_UTC__c,'
            				+ 'Logo_Type__c,Deferred_Revenue__c,Last_Customer_Activity_Date__c,Last_Case_Update__c,Case_Transition_Date__c,Status,ContactId,pse_Project__c,pse_Project__r.name,Case_Prod_Name__c,'
            				+ '(SELECT Id,ID__c, Request_Status__c FROM Engagement_Requests__r),' 
            				+ '(SELECT Id,Subject,Type__c,DueDateProlexic__c,Assigned_Division__c FROM Tasks WHERE Status != \'Completed\' AND Status != \'Not Applicable\' AND Status != \'Failed\' AND RecordTypeId = \'' + plxTaskRecTypeId + '\' ORDER BY Type__c)'
            				+ 'FROM Case WHERE RecordTypeId = \''+ psRecTypeId + '\' AND IsClosed = FALSE AND (OwnerId = \'' + plxQId + '\' OR '
            				+ '(Service__c IN:plxServiceValueList AND Case_Prod_Name__c IN:plxProductList)'+' OR '+ 'Service__c = \'Prolexic\')';
        
        String orderByQuery = ' ORDER BY Severity__c,Requested_Completion_Date_UTC__c DESC NULLS LAST';
        
        if(!String.isBlank(caseSeverity) && !caseSeverity.equalsIgnoreCase('1,2,3,4')) 
        {
            List<String> sevVals = caseSeverity.split(',');
            sevQuery = ' AND Severity__c IN :sevVals';
        }
        if(!String.isBlank(colorCategory) && !colorCategory.equalsIgnoreCase('blue,white,red,yellow')) 
        {
            colVals = colorCategory.split(',');
        }
        if(!String.isBlank(casePriority) && !casePriority.equalsIgnoreCase('all')) 
        {
            List<String> priorVals = casePriority.split(',');
            priorityQuery = ' AND Priority_Type__c IN :priorVals';
        }
        if(!String.isBlank(caseFundType) && !caseFundType.equalsIgnoreCase('all')) 
        {
            List<String> fundTypeVals = caseFundType.split(',');
            fundTypeQuery = ' AND Fund_Type__c IN :fundTypeVals';
        }
        if(!String.isBlank(caseLogoType) && !caseLogoType.equalsIgnoreCase('all')) 
        {
            List<String> logoTypeVals = caseLogoType.split(',');
            logoTypeQuery = ' AND Logo_Type__c IN :logoTypeVals';
        }
        if(!String.isBlank(caseSubType) && !caseSubType.equalsIgnoreCase('all')) 
        {
            List<String> subTypeVals = caseSubType.split(',');
            subTypeQuery = ' AND Sub_Type__c IN :subTypeVals';
        }
		if(!String.isBlank(geos) && !geos.equalsIgnoreCase('Americas,EMEA,Japan,AP,Others')) 
        {     
            List<String> geoVals = geos.split(',');
            GeoQuery = ' AND Geography__c IN :geoVals';
        }
        caseQuery += sevQuery + priorityQuery + fundTypeQuery + logoTypeQuery + subTypeQuery + GeoQuery+orderByQuery;
        caseList = Database.query(caseQuery);
        for(Case thisCase : caseList){
            caseWrap = new CaseWrapper();
            caseWrap.caseRec = thisCase;
            caseWrap.priorityType = thisCase.Priority_Type__c;
            caseWrap.fundType = thisCase.Fund_Type__c;
            caseWrap.logoType = thisCase.Logo_Type__c;
            if(thisCase.Priority_Type__c == 'Hot Customer')
            {
                caseWrap.hotCustomer = '🔥';
                caseWrap.casePriorityNum = 10;
            }
            else if(thisCase.Priority_Type__c == 'High Alert Case/Task')
            {
                caseWrap.hotCustomer = '❗';
                caseWrap.casePriorityNum = 20;
            }
            else if(thisCase.Priority_Type__c == 'Special Instructions')
            {
                caseWrap.hotCustomer = '✋🏼';
                caseWrap.casePriorityNum = 30;
            }
            else
            {
                caseWrap.hotCustomer = '';
                caseWrap.casePriorityNum = 50;
            }
            if (thisCase.Deferred_Revenue__c)
            { 
                caseWrap.hotCustomer += ' 💲';
                if(caseWrap.hotCustomer == null)
                {
                    caseWrap.casePriorityNum = 40;
                }
                else
                {
                    caseWrap.casePriorityNum = caseWrap.casePriorityNum-1;
                }
            }
            
            caseWrap.caseId = thisCase.id;
            caseWrap.akamCaseId = thisCase.AKAM_Case_ID__c;
            caseWrap.caseUrl = '/lightning/r/Case/' + thisCase.Id + '/view';
            caseWrap.accountId = thisCase.AccountId;
            caseWrap.geography = thisCase.geography__c;
            caseWrap.accountName = thisCase.Account.Name;
            caseWrap.accountUrl = '/lightning/r/Account/' + thisCase.AccountId + '/view';
            caseWrap.accountTier = thisCase.Account.Customer_Tier__c;
            caseWrap.subject = thisCase.Subject;
            caseWrap.severity = thisCase.Severity__c;
            //if(thisCase.Severity__c.isNumeric())
            	//caseWrap.severity = Integer.valueOf(thisCase.Severity__c);
            caseWrap.ageDays = thisCase.Age_days__c;
            caseWrap.requestCompletionDate = thisCase.Requested_Completion_Date_UTC__c;

            if(thisCase.Requested_Completion_Date_UTC__c != null){
                Datetime currentDate = (DateTime)Date.today();
                String dayOfWeek = currentDate.format('EEEE');
                Integer daysBetween = Date.today().daysBetween(thisCase.Requested_Completion_Date_UTC__c);

                if(dayOfWeek == 'Thursday' || dayOfWeek == 'Friday'){
                    system.debug('TODAY 1: '+Date.today().addDays(4));
                    system.debug('2 Days 1: '+thisCase.Requested_Completion_Date_UTC__c);

                    if(daysBetween <= 4){
                        caseWrap.completionDateColour = 'red';
                    }
                }
                else if(dayOfWeek == 'Saturday'){
                    system.debug('TODAY 2: '+Date.today().addDays(3));
                    system.debug('2 Days 2: '+thisCase.Requested_Completion_Date_UTC__c);

                    if(daysBetween <= 3){
                        caseWrap.completionDateColour = 'red';
                    }
                }
                else{
                    system.debug('TODAY 3: '+Date.today().addDays(2));
                    system.debug('2 Days 3: '+thisCase.Requested_Completion_Date_UTC__c);
                    
                    if(daysBetween <= 2){
                        caseWrap.completionDateColour = 'red';
                    }
                }
            }

            if(String.isNotBlank(thisCase.Shift_Owner__r.Name))
            {
                caseWrap.shiftOwner = thisCase.Shift_Owner__r.Name;
                caseWrap.shiftOwnerId = thisCase.Shift_Owner__c;
                caseWrap.shiftOwnerUrl = '/lightning/r/User/' + thisCase.Shift_Owner__c + '/view';
            }
            caseWrap.subType = thisCase.Sub_Type__c; 
            caseWrap.escCount = thisCase.Engagement_Requests__r.isEmpty() ? 0 : thisCase.Engagement_Requests__r.size();
            caseWrap.pendingTasksCount = thisCase.Tasks.isEmpty() ? 0 : thisCase.Tasks.size();
            //caseWrap.platformProduct = thisCase.PS_Product__c;//Commented for ESESP-5670 - aditi
            caseWrap.caseProduct = thisCase.Case_Prod_Name__c;//Updated for ESESP-5670 - aditi
            if(String.isNotBlank(thisCase.pse_Project__r.Name))
            {
                caseWrap.projectName = thisCase.pse_Project__r.Name;
                caseWrap.projectId = thisCase.pse_Project__c;
                caseWrap.projectUrl = '/lightning/r/pse__Proj__c/' + thisCase.pse_Project__c + '/view';
            }
            caseWrap.lastUpdatedDate = thisCase.LastModifiedDate;
            caseWrap.lastUpdatedDateTimeString = '';
            
            Integer min = Integer.valueOf((DateTime.now().getTime() - thisCase.LastModifiedDate.getTime())/1000/60);
            caseWrap.lastUpdatedMins = min;
            if(min/24/60 > 0)
                caseWrap.lastUpdatedDateTimeString += min/24/60 + 'd ';
            if(Math.mod(min/60,24) > 0)
                caseWrap.lastUpdatedDateTimeString += Math.mod(min/60,24) + 'h ';
            if(Math.mod(min,60) > 0)
                caseWrap.lastUpdatedDateTimeString += Math.mod(min,60) + 'm ';
            if(String.isNotBlank(caseWrap.lastUpdatedDateTimeString))
            {
                caseWrap.lastUpdatedDateTimeString += 'ago';
            }
            
            caseWrap.lastUpdatedBy = thisCase.LastModifiedBy.Name;
            caseWrap.lastUpdatedByUrl = '/lightning/r/User/' + thisCase.LastModifiedById + '/view';
            
            //Color code for cases
            caseWrap.caseColour = 'blue';
            caseWrap.caseColourNum = 4;

            if(thisCase.Plx_Update__c){
                caseWrap.caseColour = 'yellow';
                caseWrap.caseColourNum = 2;
                caseWrap.lastUpdatedBy = 'Customer';
                caseWrap.lastUpdatedByUrl = '/lightning/r/Contact/' + thisCase.ContactId + '/view';
            }
            if(!thisCase.Tasks.isEmpty())
            {
                for(Task t : thisCase.Tasks)
                {
                    //if(t.Type__c == 'Case Acknowledgement'){
                        if(t.DueDateProlexic__c != null && t.DueDateProlexic__c < System.now() /*&& t.Assigned_Division__c == 'plxautogen'*/){
                            caseWrap.caseColour = 'red';
                            caseWrap.caseColourNum = 3;
                        }
                    //}
                }
            }
            if(thisCase.Status == 'Unassigned')
            {
                caseWrap.caseColour = 'white';
                caseWrap.caseColourNum = 1;
            }
            if(thisCase.Tasks.isEmpty())
                caseWrap.pendingTaskColour = 'red';
            
			caseWrapperList.add(caseWrap);            
        }
        
        if(colVals.size() > 0){
            for(CaseWrapper eachCaseWrap : caseWrapperList){
                if(colVals.contains(eachCaseWrap.caseColour.toLowerCase())){
                    finalCaseWrapperList.add(eachCaseWrap);
                }
            }
        }
        else{
            finalCaseWrapperList.addAll(caseWrapperList);
        }
        
        return finalCaseWrapperList;
    }
    
    //HOME SCREEN : Fetch all Task Records
    @AuraEnabled
    public static List<TaskWrapper> getTaskList(String taskStatus, String caseSeverity, String casePriority, String caseFundType, String caseLogoType, String caseSubType, String colorCategory, string geos) 
    {
        Id plxTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Provisioning Activity').getRecordTypeId();
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
		Map<String,String> mapSCUtilMDTVal = new Map<String,String>();
        
        List<CaseWrapper> caseWrapperList = new List<CaseWrapper>();
        Map<Id,Case> mapRelatedCases = new Map<Id,Case>();
        Set<Id> lCaseId = new Set<Id>();
        
        List<Task> taskList = new List<Task>();
        List<TaskWrapper> taskWrapperList = new List<TaskWrapper>();
        TaskWrapper taskWrap = new TaskWrapper();
        
        String shiftQuery = '';
        String statusQuery = '';
        
        List<SC_Utility__mdt> lstSCUtilMDT = [SELECT DeveloperName,Value_Text__c
                                              FROM SC_Utility__mdt
                                              WHERE DeveloperName IN ('Owner_Not_Assigned_User_Id','Plx_Products','Plx_Queue_Id')];
        
        for(SC_Utility__mdt eachRec : lstSCUtilMDT)
        {
            mapSCUtilMDTVal.put(eachRec.DeveloperName,eachRec.Value_Text__c);
        }
        List<String> plxProductList = mapSCUtilMDTVal.get('Plx_Products').split(',');
        Id plxQId = mapSCUtilMDTVal.get('Plx_Queue_Id');
		
        caseWrapperList = SC_ProvisioningDashboard_Controller.getCaseList(caseSeverity, casePriority, caseFundType, caseLogoType, caseSubType, colorCategory,geos);
        
        for(CaseWrapper eachCaseWrapper : caseWrapperList){
            mapRelatedCases.put(eachCaseWrapper.caseId,eachCaseWrapper.caseRec);
        }
        lCaseId = mapRelatedCases.keyset();
        
        String taskQuery = 	'SELECT Id,Subject,Type__c,OwnerId,Owner.Name,Status,Priority,DueDateProlexic__c,WhatId,Assigned_Shift__c,AKAM_Activity_ID__c,LastModifiedDate '
            				+ 'FROM Task '
            				+ ' WHERE RecordTypeId = \'' + plxTaskRecTypeId + '\' AND Status != \'Completed\' AND Status != \'Failed\' AND Status != \'Not Applicable\' '
            				+ ' AND WhatID IN :lCaseId';
        
        String orderByQuery = ' ORDER BY DueDateProlexic__c NULLS FIRST';
        
       /* if(!String.isBlank(taskShift) && !taskShift.equalsIgnoreCase('all')) 
        {
            List<String> shiftVals = taskShift.split(',');
            shiftQuery = ' AND Assigned_Shift__c IN :shiftVals';
        }*/
        if(!String.isBlank(taskStatus) && !taskStatus.equalsIgnoreCase('all')) 
        {
            List<String> statusVals = taskStatus.split(',');
            statusQuery = ' AND Status IN :statusVals';
        }
        
        taskQuery += shiftQuery + statusQuery + orderByQuery;
        taskList = Database.query(taskQuery); 
        for(Task thisTask : taskList)
        {
            taskWrap = new TaskWrapper();
            taskWrap.taskRec = thisTask;
            taskWrap.taskId = thisTask.Id;
            taskWrap.akamActivityId = thisTask.AKAM_Activity_ID__c;
            if(mapRelatedCases.containsKey(thisTask.WhatId)) 
            {
                taskWrap.relatedCaseAKAMId = mapRelatedCases.get(thisTask.WhatId).AKAM_Case_ID__c ; 
                taskWrap.relatedCaseId = thisTask.WhatId;
                taskWrap.relatedCaseAccountName = mapRelatedCases.get(thisTask.WhatId).Account.Name;
                taskWrap.caseUrl = '/lightning/r/Case/' + thisTask.WhatId + '/view';
                taskWrap.accountUrl = '/lightning/r/Account/' + mapRelatedCases.get(thisTask.WhatId).AccountId + '/view';
            }
            else 
            {
                taskWrap.relatedCaseAKAMId = taskWrap.relatedCaseAccountName = '';
                taskWrap.relatedCaseId = NULL;
                taskWrap.caseUrl = taskWrap.accountUrl = ''; 
            }
            
            taskWrap.subject = thisTask.Subject;
            taskWrap.taskType = thisTask.Type__c;
            taskWrap.assignedToId = thisTask.OwnerId;
            taskWrap.assignedToName = thisTask.Owner.Name;
            taskWrap.assignedShift = thisTask.Assigned_Shift__c;
            taskWrap.status = thisTask.Status;
            taskWrap.taskPriority = thisTask.Priority;
            
            Integer min = 0;
            if(thisTask.DueDateProlexic__c != null){
                min = Integer.valueOf((thisTask.DueDateProlexic__c.getTime() - DateTime.now().getTime())/1000/60);
                taskWrap.dueInMins = min;
                if(min < 0)
                {
                    taskWrap.dueIn = '-' + (min/60 * -1) + 'h ' +  (Math.mod(min,60)) * -1 + 'm';
                    taskWrap.taskColour = 'red';
                }
                else
                {
                    taskWrap.dueIn = min/60 + 'h ' +  Math.mod(min,60) + 'm';
                    if(min <= 360)
                        taskWrap.taskColour = 'orange';
                    else
                        taskWrap.taskColour = 'green';
                }
            }
            
            taskWrap.lastUpdatedDate = thisTask.LastModifiedDate;
            min = Integer.valueOf((thisTask.LastModifiedDate.getTime() - DateTime.now().getTime())/1000/60);
            taskWrap.lastUpdatedMins = min;
            
            taskWrap.lastUpdatedDateTimeString = '';
            min = Integer.valueOf((DateTime.now().getTime() - thisTask.LastModifiedDate.getTime())/1000/60);
            if(min/24/60 > 0)
                taskWrap.lastUpdatedDateTimeString += min/24/60 + 'd ';
            if(Math.mod(min/60,24) > 0)
                taskWrap.lastUpdatedDateTimeString += Math.mod(min/60,24) + 'h ';
            if(Math.mod(min,60) > 0)
                taskWrap.lastUpdatedDateTimeString += Math.mod(min,60) + 'm ';
            if(String.isNotBlank(taskWrap.lastUpdatedDateTimeString))
            {
                taskWrap.lastUpdatedDateTimeString += 'ago';
            }
            
            taskWrap.taskUrl = '/lightning/r/Task/' + thisTask.Id + '/view';
            taskWrap.assignedToUrl = '/lightning/r/User/' + thisTask.OwnerId + '/view';
            
            taskWrapperList.add(taskWrap);
        }
        taskList.clear();

        return taskWrapperList;                   
    }
    
    //CASE DASHBOARD : Fetch escalations for a case
    @AuraEnabled
    public static List<EscalationWrapper> getEscalationRecs(Id caseId)
    {
        List<EscalationWrapper> lstEscWrap = new List<EscalationWrapper>();
        
        List<Engagement_Request__c> lstEsc = new List<Engagement_Request__c>();
        EscalationWrapper escWrapperRec;
        
        lstEsc = [SELECT Id,Case__c,ID__c,Request_Status__c,Subject__c,URL__c,ER_Severity__c ,Escalation_Owner__r.Name,Escalation_Owner__c,
                  Escalation_Created_Date__c,Escalation_Closed_Date__c
                  FROM Engagement_Request__c
                  WHERE Case__c = :caseId
                 ];
        if(!lstEsc.isEmpty())
        {
            for(Engagement_Request__c eR : lstEsc)
            {
                escWrapperRec = new EscalationWrapper();
                escWrapperRec.escRec = eR;
                escWrapperRec.escID = eR.ID__c;
                escWrapperRec.escSubjectURL = String.isNotBlank(eR.Subject__c) ? '/lightning/r/Engagement_Request__c/' + eR.Id + '/view' : '';
                escWrapperRec.escIDUrl = String.isNotBlank(eR.URL__c) ? eR.URL__c : '';
                escWrapperRec.escStatus = String.isNotBlank(eR.Request_Status__c) ? eR.Request_Status__c : '';
                escWrapperRec.escSubject = String.isNotBlank(eR.Subject__c) ? eR.Subject__c : '';
                escWrapperRec.escSeverity = String.isNotBlank(eR.ER_Severity__c ) ? eR.ER_Severity__c  : '';
                escWrapperRec.escOwnerName = String.isNotBlank(eR.Escalation_Owner__r.Name) ? eR.Escalation_Owner__r.Name : '';
                escWrapperRec.escCreated = String.isNotBlank(String.valueOf(eR.Escalation_Created_Date__c)) ? String.valueOf(eR.Escalation_Created_Date__c.format('MM/dd/yyyy')) : '';
                escWrapperRec.escClosed = String.isNotBlank(String.valueOf(eR.Escalation_Closed_Date__c)) ? String.valueOf(eR.Escalation_Closed_Date__c.format('MM/dd/yyyy')) : '';
                
                lstEscWrap.add(escWrapperRec);
            }
        }
        return lstEscWrap;
    }

    //CASE DASHBOARD : Fetch all Tasks for a case
    @AuraEnabled
    public static List<TaskWrapper> getAllTaskRecs(Id caseId)
    {
        List<TaskWrapper> lstTaskWrap = new List<TaskWrapper>();
        
        List<Task> lstTask = new List<Task>();
        TaskWrapper taskWrapperRec;
        
        Id plxTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Provisioning Activity').getRecordTypeId();

        lstTask = [SELECT Id,Subject,Type__c,OwnerId,Owner.Name,Status,Description,Priority,DueDateProlexic__c,
                   WhatId,Assigned_Shift__c,AKAM_Activity_ID__c,LastModifiedDate,IsClosed,Completed_Date_Time__c
                   FROM Task 
                   WHERE WhatId = :caseId AND RecordTypeId =:plxTaskRecTypeId
                   ORDER BY IsClosed,Completed_Date_Time__c,DueDateProlexic__c 
                  ];
        
        if(!lstTask.isEmpty())
        {
            for(Task thisTask : lstTask)
            {
                taskWrapperRec = new TaskWrapper();
                taskWrapperRec.taskRec = thisTask;
                taskWrapperRec.taskId = thisTask.Id;
                taskWrapperRec.akamActivityId = thisTask.AKAM_Activity_ID__c; 
                taskWrapperRec.subject = thisTask.Subject;
                taskWrapperRec.taskUrl = '/lightning/r/Task/' + thisTask.Id + '/view';
                taskWrapperRec.taskType = thisTask.Type__c;
                taskWrapperRec.assignedToId = thisTask.OwnerId;
                taskWrapperRec.assignedToName = thisTask.Owner.Name;
                taskWrapperRec.assignedShift = thisTask.Assigned_Shift__c;
                taskWrapperRec.status = thisTask.Status;
                taskWrapperRec.taskDescription = thisTask.Description;
                Integer min = 0;
                if(thisTask.DueDateProlexic__c != null)
                {
                    if(thisTask.IsClosed && String.isNotBlank(String.valueOf(thisTask.Completed_Date_Time__c )))
                    {
                        taskWrapperRec.dueIn = thisTask.Completed_Date_Time__c.format();
                        if(thisTask.Completed_Date_Time__c  > thisTask.DueDateProlexic__c)
                        {
                           taskWrapperRec.taskStatusColour = 'red';
                        }
                    }
                    else
                    {
                        min = Integer.valueOf((thisTask.DueDateProlexic__c.getTime() - DateTime.now().getTime())/1000/60);
                        taskWrapperRec.dueInMins = min;
                        if(min < 0)
                        {
                            taskWrapperRec.taskColour = 'red';
                            taskWrapperRec.dueIn = '-' + (min/60 * -1) + 'h ' +  (Math.mod(min,60)) * -1 + 'm';
                        }
                        else
                        {
                            taskWrapperRec.dueIn = min/60 + 'h ' +  Math.mod(min,60) + 'm';
                        }   
                    }
                }
                lstTaskWrap.add(taskWrapperRec);
            }
        }
        return lstTaskWrap;
    }
    
    //CASE DASHBOARD : Return Record Type Id
    @AuraEnabled
    public static Id returnRecTypeId(String sObjName, String recTypeName)
    {
        String query = 'SELECT Id FROM RecordType WHERE SobjectType = \'' + sObjName + '\'' + ' AND Name = \'' + recTypeName + '\'';
        SObject so = Database.query(query);
        return so.Id;
    }
    
    //CASE DASHBOARD : Change Shift Owner 
    @AuraEnabled
    public static void changeShiftOwner(List<Id> lstCaseIDs, String shiftOwnerId)
    {
        String errorMessage = '';
        List<Case> casesToUpdate = new List<Case>();
        List<Case> lstCases = new List<Case>();
        
        lstCases = [SELECT Id,Shift_Owner__c FROM Case WHERE Id IN :lstCaseIDs FOR UPDATE];
        
        for(Case eachCase : lstCases)
        {
            if(String.isNotBlank(shiftOwnerId))
                eachCase.Shift_Owner__c = shiftOwnerId;
            else
                eachCase.Shift_Owner__c = null;
            casesToUpdate.add(eachCase);
        }
        try
        {
            update casesToUpdate;
        }
        catch(exception e){
            System.debug(Logginglevel.ERROR, e.getMessage());
            String recordId = e.getMessage().substringBetween('id ',';');
			String excep = e.getMessage().substringBetween('EXCEPTION, ',':');
            if(String.isNotBlank(recordId) && String.isNotBlank(excep)){
                String akamCaseId =[Select AKAM_Case_ID__c from case where id=: Id.valueOf(recordId)].AKAM_Case_ID__c;
                errorMessage = excep+ 'FOR : '+akamCaseId;
            }
            else{
                errorMessage = e.getMessage();
            }
            throw new AuraHandledException(errorMessage);
        }
    }
    
    //CASE DASHBOARD : Change Case Owner 
    @AuraEnabled
    public static String changeCaseOwner(List<Id> lstCaseIDs, String caseOwnerId) 
    {
        String errorMessage = ''; 
        String returnMessage = '';
        Map<String,String> mapReturnMessage = new Map<String,String>();
        Set<Id> setCaseError = new Set<Id>();
        
        List<Case> casesToUpdate = new List<Case>();
        Map<String,Database.SaveResult> mapErroredCases = new Map<String,Database.SaveResult>();
        //map<String,String> mapAKAMCaseIdErrorMssg = new Map<String,String>();
        String mssg = '';
        
        Map<String,String> mapSCUtilMDTVal = new Map<String,String>();
        
        List<SC_Utility__mdt> lstSCUtilMDT = [SELECT DeveloperName,Value_Text__c
                                              FROM SC_Utility__mdt
                                              WHERE DeveloperName IN ('Plx_Queue_Id')];

        for(SC_Utility__mdt eachRec : lstSCUtilMDT)
        {
            mapSCUtilMDTVal.put(eachRec.DeveloperName,eachRec.Value_Text__c);
        }
        
        Map<Id,Case> mapCases = new Map<Id,Case>([SELECT OwnerId,AKAM_Case_Id__c FROM Case WHERE Id IN :lstCaseIDs FOR UPDATE]);
        
        for(Case eachCase : mapCases.values())
        {
            if(String.isNotBlank(caseOwnerId))
            {
                eachCase.OwnerId = caseOwnerId;
            }
            else
            {
                if(mapSCUtilMDTVal.get('Plx_Queue_Id') != null)
                	eachCase.OwnerId = mapSCUtilMDTVal.get('Plx_Queue_Id');
            }
            casesToUpdate.add(eachCase);
        }
        try
        {
            //update casesToUpdate;
			List<Database.SaveResult> lstResultOfCaseUpdate = Database.update(casesToUpdate, false);
            
            for(Integer i=0; i<casesToUpdate.size(); i++)
            {
                if(!lstResultOfCaseUpdate[i].isSuccess())
                {
                    //mapErroredCases.put(casesToUpdate[i].Id,lstResultOfCaseUpdate[i]);
                    setCaseError.add(casesToUpdate[i].Id);
                    for(Database.Error err : lstResultOfCaseUpdate[i].getErrors()) 
                    {                
                       errorMessage= err.getMessage();
                    }    
                }
            }
            
            if(!setCaseError.isEmpty())
            {
            	mapReturnMessage.put('mssg',errorMessage);
                mapReturnMessage.put('set', JSON.serialize(setCaseError));
                returnMessage = JSON.serialize(mapReturnMessage);
            }
        }
        catch(exception e)
        {
            System.debug(Logginglevel.ERROR, e.getMessage());
            String recordId = e.getMessage().substringBetween('id ',';');
			String excep = e.getMessage().substringBetween('EXCEPTION, ',':');
            if(String.isNotBlank(recordId) && String.isNotBlank(excep))
            {
                String akamCaseId =[Select AKAM_Case_ID__c from case where id=: Id.valueOf(recordId)].AKAM_Case_ID__c;
                errorMessage = excep+ 'FOR : '+akamCaseId;
            }
            else
            {
                errorMessage = e.getMessage();
            }
            throw new AuraHandledException(errorMessage);
        }
        return returnMessage;
    }

    //TASK DASHBOARD : Change Task Assigned To
    @AuraEnabled
    public static String changeTaskAssignedTo(List<Id> lstTaskIDs, String assignedToId)
    {
        String errorMessage = '';
        String returnMessage = '';
        Map<String,String> mapReturnMessage = new Map<String,String>();
        Set<Id> setTaskError = new Set<Id>();
        
        Id onaID = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Owner_Not_Assigned_User_Id' LIMIT 1].Value_Text__c;  
        List<Task> tasksToUpdate = new List<Task>();
        List<Task> lstTasks = [SELECT OwnerId FROM Task WHERE Id IN :lstTaskIDs FOR UPDATE];
        for(Task eachTask : lstTasks)
        {
            if(String.isNotBlank(assignedToId))
                eachTask.OwnerId = assignedToId;
            else
                eachTask.OwnerId = onaID;
            tasksToUpdate.add(eachTask);
        }
        
        try
        {
            //update tasksToUpdate;
			List<Database.SaveResult> lstResultOfTaskUpdate = Database.update(tasksToUpdate, false);
            
            for(Integer i=0; i<tasksToUpdate.size(); i++)
            {
                if(!lstResultOfTaskUpdate[i].isSuccess())
                {
                    //mapErroredCases.put(casesToUpdate[i].Id,lstResultOfCaseUpdate[i]);
                    setTaskError.add(tasksToUpdate[i].Id);
                    for(Database.Error err : lstResultOfTaskUpdate[i].getErrors()) 
                    {                
                       errorMessage= err.getMessage();
                    }    
                }
            }
            
            if(!setTaskError.isEmpty())
            {
            	mapReturnMessage.put('mssg',errorMessage);
                mapReturnMessage.put('set', JSON.serialize(setTaskError));
                returnMessage = JSON.serialize(mapReturnMessage);
            }
        }
        catch(exception e){
            System.debug(Logginglevel.ERROR, e.getMessage());
            String recordId = e.getMessage().substringBetween('id ',';');
			String excep = e.getMessage().substringBetween('EXCEPTION, ',':');
            if(String.isNotBlank(recordId) && String.isNotBlank(excep)){
                //errorMessage = excep+ 'FOR : '+recordId;
                Task excepTask =[Select subject,whatId from task where id=: Id.valueOf(recordId) limit 1];
                String akamCaseId =[Select AKAM_Case_ID__c from case where id=: excepTask.whatid].AKAM_Case_ID__c;
                errorMessage = excep+ 'FOR : '+excepTask.subject +' ON : '+akamCaseId;
            }
            else{
                errorMessage = e.getMessage();
            }
            throw new AuraHandledException(errorMessage);
        }
        return returnMessage; 
    }

    //TASK DASHBOARD : Change Task Status
    @AuraEnabled
    public static void changeStatus(List<Id> lstTaskIDs, String status)
    {
        String errorMessage = '';
        List<Task> tasksToUpdate = new List<Task>();
        List<Task> lstTasks = [SELECT Status FROM Task WHERE Id IN :lstTaskIDs FOR UPDATE];
        for(Task eachTask : lstTasks)
        {
            if(String.isNotBlank(status))
                eachTask.Status = status;

            tasksToUpdate.add(eachTask);
        }
        try{
            update tasksToUpdate;
        }
        catch(exception e){
            System.debug(Logginglevel.ERROR, e.getMessage());
            String recordId = e.getMessage().substringBetween('id ',';');
			String excep = e.getMessage().substringBetween('EXCEPTION, ',':');
            if(String.isNotBlank(recordId) && String.isNotBlank(excep)){
                Task excepTask =[Select subject,whatId from task where id=: Id.valueOf(recordId) limit 1];
                String akamCaseId =[Select AKAM_Case_ID__c from case where id=: excepTask.whatid].AKAM_Case_ID__c;
                errorMessage = excep+ 'FOR : '+excepTask.subject +' ON : '+akamCaseId;
            }
            else{
                errorMessage = e.getMessage();
            }
            throw new AuraHandledException(errorMessage);
        }
    }
    
    //SUMMARY DASHBOARD : SAVE FILTERS
    @AuraEnabled
    public static Map<String,String> savePlxFilters(String filterToSave)
    {
        Map<String,String> savedFilterVal = new Map<String,String>();

      string rectypeid = SC_User_Filter__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Provisioning').getRecordTypeId();
		string uniqueid = userinfo.getUserId()+'-'+rectypeid;
        
        List<SC_User_Filter__c> filter = new List<SC_User_Filter__c>();

        filter = [SELECT Unique_ID__c ,Filter_Values__c  
                  FROM SC_User_Filter__c 
                  WHERE Unique_ID__c = :uniqueid limit 1];
        
        String selectAll = 'CaseSeverity:1,2,3,4&ColorCategory:blue,white,red,yellow&CasePriority:All&CaseFundType:All&CaseLogoType:All&CaseSubType:All&Geo:Americas,EMEA,Japan,AP,Others&TaskStatus:All';
        savedFilterVal.put('CaseSeverity','1,2,3,4');
        savedFilterVal.put('ColorCategory','blue,white,red,yellow');
        savedFilterVal.put('Geo','Americas,EMEA,Japan,AP,Others');
        savedFilterVal.put('CasePriority','All');
        savedFilterVal.put('CaseFundType','All');
        savedFilterVal.put('CaseLogoType','All');
        savedFilterVal.put('CaseSubType','All');
        savedFilterVal.put('TaskStatus','All');

        if(filter.size() == 0)
        {
            SC_User_Filter__c newrow = new SC_User_Filter__c(Filter_Values__c = selectAll,Unique_ID__c = uniqueid, recordtypeid=rectypeid);
            upsert newrow;
        }
        else if(String.isBlank(filter[0].Filter_Values__c))
        {
            filter[0].Filter_Values__c = selectAll;
            upsert filter;
        }
        else
        {
            if(String.isNotBlank(filterToSave))
            {
                filter[0].Filter_Values__c = filterToSave;
                upsert filter;
                return NULL;
            }
            else
            {
                savedFilterVal = new Map<String,String>();
                List<String> filterVals = filter[0].Filter_Values__c.split('&');
                for(String s : filterVals)
                {
                    List<String> text = s.split(':');
                    savedFilterVal.put(text[0],text[1]);
                }
            }
        }   
        return savedFilterVal; 
    }
    
    //TASK DASHBOARD : Assign Task Shift
    //scProvisioningAssignShift lwc : Assign Task Shift from task detail page
    @AuraEnabled
    public static void assignTaskShift(List<Id> taskIdList, String shift)
    {
        String errorMessage = '';
        List<Task> tasksToUpdate = new List<Task>();
        List<Task> lstTasks = [SELECT Assigned_Shift__c FROM Task WHERE Id IN :taskIdList];
        for(Task eachTask : lstTasks)
        {
            if(String.isNotBlank(shift))
                eachTask.Assigned_Shift__c = shift;

            tasksToUpdate.add(eachTask);
        }

        try
        {
            update tasksToUpdate;
        }
        catch(exception e)
        {
            System.debug(Logginglevel.ERROR, e.getMessage());
            System.debug('Entered exception');
            String recordId = e.getMessage().substringBetween('id ',';');
			String excep = e.getMessage().substringBetween('EXCEPTION, ',':');
            if(String.isNotBlank(recordId) && String.isNotBlank(excep)){
                //errorMessage = excep+ 'FOR : '+recordId;
                Task excepTask =[Select subject,whatId from task where id=: Id.valueOf(recordId) limit 1];
                String akamCaseId =[Select AKAM_Case_ID__c from case where id=: excepTask.whatid].AKAM_Case_ID__c;
                errorMessage = excep+ 'FOR : '+excepTask.subject +' ON : '+akamCaseId;
            }
            else{
                errorMessage = e.getMessage();
            }
            throw new AuraHandledException(errorMessage);
        }
    }

    //scProvisioningAssignShift lwc : Get the assigned task shift for the task
    @AuraEnabled
    public static String fetchTaskShift(Id taskId)
    {
        return [Select Assigned_Shift__c from task where id =: taskId limit 1].Assigned_Shift__c;
    }
    
    //TASK DASHBOARD : Fetch Owner Not Assigned User Id
    @AuraEnabled(cacheable=true)
    public static String returnONAId()
    {
        String onaId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Owner_Not_Assigned_User_Id'].Value_Text__c;
        return onaId;
    }
    
    //SUMMARY DASHBOARD : SEND SHIFT HANDOVER REPORT
    @AuraEnabled
    public static void emailShiftHandoverReport()
    {
        SC_S2ET_SendEmailHTML.getShiftDetailsPLX();
    }
    
    //SUMMARY DASHBOARD : GENERATE EMAIL BODY FOR HANDOVER REPORT
    @AuraEnabled(cacheable=true)
    public static List<List<CaseWrapper>> getCaseListForReport(Datetime startDate,Datetime endDate) 
    {
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Id plxTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Provisioning Activity').getRecordTypeId();
        List<List<CaseWrapper>> lListCaseWrapper = new List<List<CaseWrapper>>();
        Datetime startDateLast6Hours = startDate.addHours(-6);
        
        Map<String,String> mapSCUtilMDTVal = new Map<String,String>();
        List<SC_Utility__mdt> lstSCUtilMDT = [SELECT DeveloperName,Value_Text__c
                                              FROM SC_Utility__mdt
                                              WHERE DeveloperName IN ('Owner_Not_Assigned_User_Id','Plx_Products','Plx_Queue_Id','Plx_Service_Values')];
        
        for(SC_Utility__mdt eachRec : lstSCUtilMDT)
        {
            mapSCUtilMDTVal.put(eachRec.DeveloperName,eachRec.Value_Text__c);
        }
        List<String> plxProductList = mapSCUtilMDTVal.get('Plx_Products').split(',');
        List<String> plxServiceValueList = mapSCUtilMDTVal.get('Plx_Service_Values').split(',');
        Id plxQId = mapSCUtilMDTVal.get('Plx_Queue_Id');
        
        List<Case> lstCase = new List<Case>();
        List<Task> lstTask = new List<Task>();
        List<Id> caseIdLIst = new List<Id>();
        List<CaseWrapper> lClosedHighPriorityCases = new List<CaseWrapper>();
        List<CaseWrapper> lClosedCases = new List<CaseWrapper>();
        List<CaseWrapper> lOpenHighPriorityCases = new List<CaseWrapper>();
        List<CaseWrapper> lOpenCases = new List<CaseWrapper>();
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        CaseWrapper caseWrap = new CaseWrapper();

        lstTask = [Select Id,Subject,Type__c,DueDateProlexic__c,WhatID,Status 
                   FROM Task 
                   WHERE RecordTypeId=:plxTaskRecTypeId AND Status != 'Completed' and Status != 'Failed' and Status != 'Not Applicable' 
                   AND DueDateProlexic__c >= :startDate AND DueDateProlexic__c <= :endDate ORDER BY Type__c];
        for(Task thisTask : lstTask){
            caseIdLIst.add(thisTask.WhatId);
        }
        lstCase = [SELECT Id,AKAM_Case_ID__c,Account.Name, Case_Account_Name__c, Account.Customer_Tier__c, Subject, Severity__c, Age_days__c, Requested_Completion_Date_UTC__c,Requested_Completion_Time_UTC__c,
                   Shift_Owner__c,Shift_Owner__r.Name, Sub_Type__c, LastModifiedDate, LastModifiedBy.Name, Priority_Type__c,Fund_Type__c,Plx_Update__c,pse_Project__c,pse_Project__r.Name,
                   Logo_Type__c,Deferred_Revenue__c,Last_Customer_Activity_Date__c,Last_Case_Update__c,Case_Transition_Date__c,Status,ContactId,ParentId,Service__c,isClosed,Parent.AKAM_Case_ID__c,Case_Prod_Name__c,
                   //(SELECT Id,ID__c,Request_Status__c,URL__c FROM Engagement_Requests__r WHERE Request_Status__c != 'Closed'),
                   (SELECT Id,Subject,Type__c,DueDateProlexic__c,Status,Priority 
                    FROM Tasks 
                    WHERE RecordTypeId =:plxTaskRecTypeId AND Status != 'Failed' and Status != 'Not Applicable' 
                    AND ((DueDateProlexic__c >= :startDate AND DueDateProlexic__c <= :endDate) OR (Status = 'Completed' AND Completed_Date_Time__c >= :startDateLast6Hours))
                    ORDER BY Type__c)
                   FROM Case WHERE ID in:caseIdLIst AND RecordTypeId = :psRecTypeId AND isClosed != true
                   AND (OwnerId = :plxQId OR (Service__c IN:plxServiceValueList AND Case_Prod_Name__c IN: plxProductList) OR Service__c = 'Prolexic')
                   ORDER BY Severity__c,Requested_Completion_Date_UTC__c DESC NULLS LAST];
        
        for(Case eachCase : lstCase)
        {
            caseWrap = new CaseWrapper();
            caseWrap.caseRec = eachCase;
            caseWrap.caseId = eachCase.Id;
            caseWrap.akamCaseId = eachCase.AKAM_Case_ID__c;
            caseWrap.escCount = eachCase.Engagement_Requests__r.isEmpty() ? 0 : eachCase.Engagement_Requests__r.size();
            caseWrap.accountName = eachCase.Account.Name;
            caseWrap.accountId = eachCase.AccountId;
            caseWrap.subject = eachCase.Subject;
            //caseWrap.severity = Integer.valueOf(eachCase.Severity__c);
            caseWrap.severity = eachCase.Severity__c;
            caseWrap.ageDays = eachCase.Age_days__c;
            if(String.isNotBlank(eachCase.Shift_Owner__r.Name))
            {
                caseWrap.shiftOwner = eachCase.Shift_Owner__r.Name;
            }
            caseWrap.service = eachCase.Service__c;
            caseWrap.pendingTasksCount = eachCase.Tasks.isEmpty() ? 0 : eachCase.Tasks.size();
            
            if(eachCase.Priority_Type__c == 'Hot Customer')
            {
                caseWrap.hotCustomer = '🔥';
            }
            else if(eachCase.Priority_Type__c == 'High Alert Case/Task')
            {
                caseWrap.hotCustomer = '❗';
            }
            else if(eachCase.Priority_Type__c == 'Special Instructions')
            {
                caseWrap.hotCustomer = '✋🏼';
            }
            else 
            {
                caseWrap.hotCustomer = '';
            }
            if (eachCase.Deferred_Revenue__c)
            {
                //caseWrap.hotCustomer += ' 💲';
            }
            
            caseWrap.lastUpdatedDate = eachCase.LastModifiedDate;
            caseWrap.lastUpdatedDateTimeString = '';
            Integer min = Integer.valueOf((DateTime.now().getTime() - eachCase.LastModifiedDate.getTime())/1000/60);
            if(min/24/60 > 0)
                caseWrap.lastUpdatedDateTimeString += min/24/60 + 'd ';
            if(Math.mod(min/60,24) > 0)
                caseWrap.lastUpdatedDateTimeString += Math.mod(min/60,24) + 'h ';
            if(Math.mod(min,60) > 0)
                caseWrap.lastUpdatedDateTimeString += Math.mod(min,60) + 'm ';
            if(String.isNotBlank(caseWrap.lastUpdatedDateTimeString))
            {
                caseWrap.lastUpdatedDateTimeString += 'ago';
            }
            
            caseWrap.lastUpdatedBy = eachCase.LastModifiedBy.Name;
            caseWrap.caseStatus = eachCase.IsClosed ? 'Closed' : 'Open';
            
            caseWrap.caseColour = 'white';
            if(eachCase.Priority_Type__c == 'Hot Customer')
                caseWrap.caseColour = 'red';
            
            caseWrap.escStatus = '';
            /*
            caseWrap.lEscalationRecords = new List<Engagement_Request__c>();
            if(!eachCase.Engagement_Requests__r.isEmpty())
            {
                for(Engagement_Request__c e : eachCase.Engagement_Requests__r)
                {
                    caseWrap.lEscalationRecords.add(e);
                    caseWrap.escStatus += e.ID__c + '-' + e.Request_Status__c + '<br>';
                }
            }
            */
            
            caseWrap.taskNext = '';
            caseWrap.taskCompleted = '';
            
            if(!eachCase.Tasks.isEmpty())
            {
                for(Task t : eachCase.Tasks)
                {
                    system.debug('adkjhsd : '+t);
                    if(t.Status != 'Not Applicable' && t.Status != 'Completed' && t.Status != 'Failed')
                    {
                        numOfTasksOpen++;
                        caseWrap.taskNext += t.Type__c + '<br>'; 
                    } 
                    else if(t.Status == 'Completed')
                    {
                        numOfTasksCompleted++;
                        caseWrap.taskCompleted += t.Type__c + '<br>'; 
                    }
                }
            }
            if (caseWrap.hotCustomer == '') {
                if (eachCase.Status.containsIgnoreCase('close')) {
                    numOfClosedCases++;
                    caseWrap.caseType = 'ClosedCase';
                    lClosedCases.add(caseWrap);
                }
                else {
                    numberOfOpenCase++;
                    caseWrap.caseType = 'OpenCase';
                    lOpenCases.add(caseWrap);
                }
            }
            else {
                if (!eachCase.Status.containsIgnoreCase('close')) {
                    numberOfOpenCase++;
                    caseWrap.caseType = 'HighPriorityOpenCase';
                    lOpenHighPriorityCases.add(caseWrap);
                }
                else {
                    numOfClosedCases++;
                    caseWrap.caseType = 'HighPriorityClosedCase';
                    lClosedHighPriorityCases.add(caseWrap);
                }
            }
            
        }
        lListCaseWrapper.add(lOpenHighPriorityCases);
        lListCaseWrapper.add(lOpenCases);
        lClosedHighPriorityCases.addAll(lClosedCases);
        lListCaseWrapper.add(lClosedHighPriorityCases);

        return lListCaseWrapper;                   
    }
    
    //scProvisioningTaskPDMapping : Get the existing Mapping Records
    @AuraEnabled(cacheable=true)
    public static List<SC_LookupSearchResult> getPDs(Id recordTaskID) 
    {
        String objIcon = 'custom:custom20';
        String PDURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Policy_Domain__c/';
        List<SC_LookupSearchResult> results = new List<SC_LookupSearchResult>();
        for(Policy_Domain__c thisPD : [select id,name from Policy_Domain__c where 
            id IN (select Policy_Domain__c from Task_PD_Mapping__c where Task_ID__c =:recordTaskID)])
            {
                results.add(
                new SC_LookupSearchResult(
                        thisPD.Id,
                        'Policy_Domain__c',
                        objIcon,
                        thisPD.Name,
                        PDURL+thisPD.Id
                    )
                );
            }
        return results;
    }
    
    //scProvisioningTaskPDMapping : Save the selected mappings
    @AuraEnabled
    public static void savePDMappings(List<Id> policyDomainList,id recordTaskID) 
    {
        List<Task_PD_Mapping__c> taskPDMapList = new List<Task_PD_Mapping__c>();
        Map<Id,Task_PD_Mapping__c> taskPDMap = new Map<Id,Task_PD_Mapping__c>();

        for(Task_PD_Mapping__c thisRec :[select id,Policy_Domain__c,Task_ID__c from Task_PD_Mapping__c where Task_ID__c =: recordTaskID ]){
            taskPDMap.put(thisRec.Policy_Domain__c,thisRec);
        }

        Map<Id,Task> taskMap = new Map<Id,Task>([Select id,Subject,Description,Type__c,DueDateProlexic__c,Status from task where id=:recordTaskID]);

        for(ID pdId : policyDomainList){
            if(!taskPDMap.keyset().contains(pdId)){
                Task_PD_Mapping__c taskPDMapRec = new Task_PD_Mapping__c(); 
                taskPDMapRec.Policy_Domain__c = pdID;
                taskPDMapRec.Task_ID__c = recordTaskID;
                taskPDMapRec.Task_Subject__c = taskMap.get(recordTaskID).Subject;
                taskPDMapRec.Task_Comments__c = taskMap.get(recordTaskID).Description;
                taskPDMapRec.Task_Type__c = taskMap.get(recordTaskID).Type__c;
                taskPDMapRec.Task_Due_Date__c = taskMap.get(recordTaskID).DueDateProlexic__c;
                taskPDMapRec.Task_Status__c = taskMap.get(recordTaskID).Status;

                taskPDMapList.add(taskPDMapRec);
            }
        }

        if(taskPDMapList.size() > 0){
            insert taskPDMapList;
        }
    }
    
    //scProvisioningTaskPDMapping : Save the selected mappings
    @AuraEnabled
    public static void deletePDMappings(List<Id> policyDomainList,id recordTaskID) 
    {
        List<Task_PD_Mapping__c> taskPDMapDeleteList = new List<Task_PD_Mapping__c>();
        Map<Id,Task_PD_Mapping__c> taskPDMap = new Map<Id,Task_PD_Mapping__c>();

        for(Task_PD_Mapping__c thisRec :[select id,Policy_Domain__c,Task_ID__c from Task_PD_Mapping__c where Task_ID__c =: recordTaskID ]){
            taskPDMap.put(thisRec.Policy_Domain__c,thisRec);
        }

        for(Id pdId : taskPDMap.keyset()){
            if(policyDomainList.size() == 0 || (policyDomainList.size() > 0 && !policyDomainList.contains(pdId))){
                taskPDMapDeleteList.add(taskPDMap.get(pdId));
            }
        }
            
        if(taskPDMapDeleteList.size() > 0){
            delete taskPDMapDeleteList;
        }
    }
    
    private final static Integer MAX_RESULTS = 5;
    @AuraEnabled(Cacheable=true)
    public static List<SC_LookupSearchResult> search(String searchTerm, List<String> selectedIds, String objId) 
    {
        // Prepare query paramters
        searchTerm += '*';

        Id caseId = [Select whatid from task where id =: Id.valueOf(objId) limit 1].WhatId;
        Id accountId = [Select AccountId from Case where id =: caseId limit 1].AccountId;
        // Execute search query
        List<List<SObject>> searchResults = [
            FIND :searchTerm
            IN ALL FIELDS
            RETURNING
                Policy_Domain__c(Id, Name WHERE id NOT IN :selectedIds and Account_Name__c =: accountId)
            LIMIT :MAX_RESULTS
        ];

        // Prepare results
        List<SC_LookupSearchResult> results = new List<SC_LookupSearchResult>();

        // Extract Policy Domains & convert them into SC_LookupSearchResult
        String objIcon = 'custom:custom20';
        String PDURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Policy_Domain__c/';
        Policy_Domain__c[] PDList = (List<Policy_Domain__c>) searchResults[0];
        for (Policy_Domain__c pdRec : PDList) {
            results.add(
                new SC_LookupSearchResult(
                    pdRec.Id,
                    'Policy_Domain__c',
                    objIcon,
                    pdRec.Name,
                    PDURL+pdRec.Id
                )
            );
        }
        results.sort(); //sort based on PD Name
        return results;
    }
}