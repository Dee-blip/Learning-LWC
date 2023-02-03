/*
************************************************************************************************************
    Author              :   Vandhana Krishnamurthy
    Created             :   22-April-2020
    Purpose             :   Controller for S2ET Dashboard
    JIRA Story          :   ESESP-3524 :: Security Services Dashboard: S2ET Dashboard and Case Improvements
    Test Class          :   SC_SecurityServices_Ctrlr_Test

	@History
	--Developer           --Date            --Change
	Tejaswini			09-Dec-2020			ESESP-3944 Added icons for new Priority Type picklist value 
	Sujay 				07-Sep-2021			ESESP-5678 : Adding new entry in dashboard for 24PS Cases
	Jay                 28-Sep-2021         ESESP-3945: Added controller methods for reading/updating special notes.
    Sujay               12-OCT-2021         ESESP-5981 : Sorting Age Desc for Shift Handover report.
************************************************************************************************************

*/

public class SC_SecurityServices_Ctrlr 
{
    public Static Integer numberOfClosedCases=0;
    public Static Integer numberOfOpenCase=0;
    public Static Integer numberOfTotalOpenCases=0;
    
    public class CaseWrapper
    {
        @AuraEnabled public Case caseRec;
        @AuraEnabled public Id caseId;
        @AuraEnabled public String akamCaseId;
        @AuraEnabled public String parentCaseAKAMId;
        @AuraEnabled public Id parentCaseId;
        @AuraEnabled public Integer escCount;
        @AuraEnabled public String accountName;
        @AuraEnabled public String subject;
        @AuraEnabled public Id accountId;
        @AuraEnabled public String severity;
        @AuraEnabled public Double ageDays;
        @AuraEnabled public String shiftOwner;
        @AuraEnabled public Id shiftOwnerId;
        @AuraEnabled public String service;
        @AuraEnabled public Integer pendingTasksCount;
        @AuraEnabled public DateTime lastUpdatedDate;
        @AuraEnabled public Integer lastUpdatedMins;
        @AuraEnabled public String lastUpdatedDateTimeString;
        @AuraEnabled public String lastUpdatedBy;
        @AuraEnabled public String hotCustomer;
        @AuraEnabled public String priorityType;
        @AuraEnabled public List<Engagement_Request__c> lEscalationRecords;
        @AuraEnabled public Integer casePriorityNum;
        @AuraEnabled public String caseStatus;
        //@AuraEnabled public Integer numOfClosedCases=0;
        //@AuraEnabled public Integer numberOfOpenCase=0;
        @AuraEnabled public String caseType;

        @AuraEnabled public String livingSummary;
        @AuraEnabled public String taskCompleted;
        @AuraEnabled public String taskNext;
        @AuraEnabled public String escStatus;
        
        @AuraEnabled public String caseColour;
        @AuraEnabled public Integer caseColourNum;
        @AuraEnabled public String pendingTaskColour;
        
        @AuraEnabled public String caseUrl;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String shiftOwnerUrl;
        @AuraEnabled public String parentCaseUrl;
        @AuraEnabled public String lastUpdatedByUrl;

        @AuraEnabled public String accountAKAMId;//Added by Aditi for ESESP-3947
    }
    
    @AuraEnabled
    public static List<CaseWrapper> getCaseList(String caseSeverity, String casePriority) 
    {
        System.debug('CASE LIST CALLED');
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Id secServTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
        
        Id s2etQId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'S2ET_Queue_Id' LIMIT 1].Value_Text__c;
        //ESESP-5678 fetching 24PS Cases Queue Id
        Id PS24QId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'PS24_Queue_Id' LIMIT 1].Value_Text__c;

        String sevQuery = '';
        String priorityQuery = '';
        
        List<Case> lstCase = new List<Case>();
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        CaseWrapper caseWrap = new CaseWrapper();        
        
        //Updated by Aditi for ESESP-3947 - to query Account.AKAM_Account_ID__c
        String caseQuery = 'SELECT Id,AKAM_Case_ID__c,Subject,ParentId,Parent.AKAM_Case_ID__c, Case_Account_Name__c,Account.Name,ContactId,Account.AKAM_Account_ID__c,'
                            + 'Severity__c,Age_days__c,Shift_Owner__c,Shift_Owner__r.Name,Service__c,Status,Priority_Type__c,IsClosed,'
                            + 'LastModifiedDate, LastModifiedBy.Name,LastModifiedById,Request_Type__c,Living_Summary_Next_Steps__c,Last_Customer_Activity_Date__c,Last_Case_Update__c,'
                            + '(SELECT Id,ID__c, Request_Status__c FROM Engagement_Requests__r WHERE Request_Status__c != \'Completed\'),' 
                            + '(SELECT Id,Subject,Type__c,DueDateProlexic__c,Assigned_Division__c FROM Tasks WHERE Status != \'Completed\' AND Status != \'Cancelled\' AND RecordTypeId = \'' + secServTaskRecTypeId + '\' ORDER BY Type__c)'
                            + 'FROM Case WHERE RecordTypeId = \''+ psRecTypeId + '\' AND IsClosed = FALSE AND (OwnerId = \'' + s2etQId + '\' OR OwnerId = \'' + PS24QId + '\' )'  ;
                            //ESESP-5678 : Added 24PS Queue owener case
        
        String orderByQuery = ' ORDER BY Severity__c,CreatedDate desc ';
        
        system.debug('caseSeverity: '+caseSeverity);
        if(!caseSeverity.equalsIgnoreCase('1,2,3,4')) 
        {
            List<String> sevVals = caseSeverity.split(',');
            sevQuery = ' AND Severity__c IN :sevVals';
        }
        
        if(!casePriority.equalsIgnoreCase('all')) 
        {
            List<String> priorVals = casePriority.split(',');
            priorityQuery = ' AND Priority_Type__c IN :priorVals';
        }
        
        caseQuery += sevQuery + priorityQuery + orderByQuery;
        System.debug(caseQuery);
        
        lstCase = Database.query(caseQuery);
        
        /*
        lstCase = [SELECT Id,AKAM_Case_ID__c,Subject,ParentId,Parent.AKAM_Case_ID__c, Case_Account_Name__c,Account.Name,ContactId,
                   Severity__c,Age_days__c,Shift_Owner__c,Shift_Owner__r.Name,Service__c,Status,Priority_Type__c,IsClosed,
                   LastModifiedDate, LastModifiedBy.Name,LastModifiedById,Request_Type__c,Living_Summary_Next_Steps__c,Last_Customer_Activity_Date__c,Last_Case_Update__c,
                   (SELECT Id,ID__c, Request_Status__c FROM Engagement_Requests__r WHERE Request_Status__c != 'Completed'),
                   (SELECT Id,Subject,Type__c,DueDateProlexic__c 
                    FROM Tasks 
                    WHERE Status != 'Completed' AND Status != 'Cancelled' AND RecordTypeId =:secServTaskRecTypeId ORDER BY Type__c)
                   FROM Case
                   WHERE RecordTypeId = :psRecTypeId AND IsClosed = FALSE
                   AND OwnerId = :s2etQId
                   AND Severity__c IN :sevVals AND Priority_Type__c IN :priorityVals
                   ORDER BY Severity__c,CreatedDate desc];
        */
        
        
        for(Case eachCase : lstCase)
        {
            caseWrap = new CaseWrapper();
            caseWrap.caseRec = eachCase;
            caseWrap.caseId = eachCase.Id;
            caseWrap.akamCaseId = eachCase.AKAM_Case_ID__c;
            caseWrap.caseUrl = '/lightning/r/Case/' + eachCase.Id + '/view';
            caseWrap.caseStatus = eachCase.Status;
            if(String.isNotBlank(eachCase.ParentId))
            {
                caseWrap.parentCaseAKAMId = eachCase.Parent.AKAM_Case_ID__c;
                caseWrap.parentCaseId = eachCase.ParentId;
                caseWrap.parentCaseUrl = '/lightning/r/Case/' + eachCase.ParentId + '/view';
            }
            caseWrap.escCount = eachCase.Engagement_Requests__r.isEmpty() ? 0 : eachCase.Engagement_Requests__r.size();
            caseWrap.accountName = eachCase.Account.Name;
            caseWrap.accountId = eachCase.AccountId;
            caseWrap.accountAKAMId = eachCase.Account.AKAM_Account_ID__c;//Added by Aditi for ESESP-3947
            if(String.isNotBlank(eachCase.AccountId))
                caseWrap.accountUrl = '/lightning/r/Account/' + eachCase.AccountId + '/view';
            caseWrap.subject = eachCase.Subject;
            //caseWrap.severity = Integer.valueOf(eachCase.Severity__c);
            caseWrap.severity = eachCase.Severity__c;
            caseWrap.ageDays = eachCase.Age_days__c;
            if(String.isNotBlank(eachCase.Shift_Owner__r.Name))
            {
                caseWrap.shiftOwner = eachCase.Shift_Owner__r.Name;
                caseWrap.shiftOwnerId = eachCase.Shift_Owner__c;
                caseWrap.shiftOwnerUrl = '/lightning/r/User/' + eachCase.Shift_Owner__c + '/view';
            }
            caseWrap.service = eachCase.Service__c;
            caseWrap.pendingTasksCount = eachCase.Tasks.isEmpty() ? 0 : eachCase.Tasks.size();
            caseWrap.priorityType = eachCase.Priority_Type__c;
            if(eachCase.Priority_Type__c == 'Hot Customer')
            {
                caseWrap.hotCustomer = '🔥';
                caseWrap.casePriorityNum = 1;
            }
            else if(eachCase.Priority_Type__c == 'High Alert Case/Task')
            {
                caseWrap.hotCustomer = '❗';
                caseWrap.casePriorityNum = 2;
            }
            else if(eachCase.Priority_Type__c == 'Special Instructions')
            {
                caseWrap.hotCustomer = '✋🏼';
                caseWrap.casePriorityNum = 3;
            }
            else 
            {
                caseWrap.hotCustomer = '';
                caseWrap.casePriorityNum = 4;
            }
            
            caseWrap.lastUpdatedDate = eachCase.LastModifiedDate;
            caseWrap.lastUpdatedDateTimeString = '';
            
            Integer min = Integer.valueOf((DateTime.now().getTime() - eachCase.LastModifiedDate.getTime())/1000/60);
            caseWrap.lastUpdatedMins = min;
            if(min/24/60 > 0)
                caseWrap.lastUpdatedDateTimeString += min/24/60 + 'd ';
            if(Math.mod(min/60,24) > 0)
                caseWrap.lastUpdatedDateTimeString += Math.mod(min/60,24) + 'h ';
            if(Math.mod(min,60) >= 0)
                caseWrap.lastUpdatedDateTimeString += Math.mod(min,60) + 'm ';
            if(String.isNotBlank(caseWrap.lastUpdatedDateTimeString))
            {
                caseWrap.lastUpdatedDateTimeString += 'ago';
            }
            
            caseWrap.lastUpdatedBy = eachCase.LastModifiedBy.Name;
            caseWrap.lastUpdatedByUrl = '/lightning/r/User/' + eachCase.LastModifiedById + '/view';
            
            caseWrap.caseColour = 'blue';
            caseWrap.caseColourNum = 4;
            
            if(String.isNotBlank(String.valueOf(eachCase.Last_Customer_Activity_Date__c)) 
               && (String.isBlank(String.valueOf(eachCase.Last_Case_Update__c)) 
                   || (String.isNotBlank(String.valueOf(eachCase.Last_Case_Update__c)) && eachCase.Last_Case_Update__c <= eachCase.Last_Customer_Activity_Date__c))
              )
            {
                caseWrap.caseColour = 'yellow';
                caseWrap.caseColourNum = 3;
                caseWrap.lastUpdatedBy = 'Customer';
                caseWrap.lastUpdatedByUrl = '/lightning/r/Contact/' + eachCase.ContactId + '/view';
            }
            
            caseWrap.taskCompleted = '';
            if(!eachCase.Tasks.isEmpty())
            {
                for(Task t : eachCase.Tasks)
                {
                    //if(t.Type__c == 'Case Acknowledgement')
                    //{
                        if(t.DueDateProlexic__c < System.now() /*&& t.Assigned_Division__c == 's2etautogen'*/)
                        {
                            caseWrap.caseColour = 'red';
                            caseWrap.caseColourNum = 2;
                        }
                        /*
                        else if(eachCase.Status == 'Unassigned' && t.DueDateProlexic__c >= System.now() )
                        {
                            caseWrap.caseColour = 'white';
                            caseWrap.caseColourNum = 1;
                        }
                        */
                    //}
                }
            }
            
            if(eachCase.Status == 'Unassigned')
            {
                caseWrap.caseColour = 'white';
                caseWrap.caseColourNum = 1;
            }
                
            if(eachCase.Tasks.isEmpty())
                caseWrap.pendingTaskColour = 'red';
            
            //caseWrap.livingSummary = eachCase.Living_Summary_Next_Steps__c;

            lstCaseWrapper.add(caseWrap);
        }
        System.debug('Case Size' + lstCaseWrapper.size());
        
        lstCase.clear();
        return lstCaseWrapper;                   
    }
    
    @AuraEnabled(cacheable=true)
    public static List<List<CaseWrapper>> getCaseListForReport(Datetime startDate, DateTime endDate) 
    {
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Id secServTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
        List<List<CaseWrapper>> lListCaseWrapper = new List<List<CaseWrapper>>();


        Id s2etQId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'S2ET_Queue_Id' LIMIT 1].Value_Text__c;        
        //Add 24 PS cases to view
        Id PS24QId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'PS24_Queue_Id' LIMIT 1].Value_Text__c;

        List<Case> lstCase = new List<Case>();
        List<CaseWrapper> lClosedHighPriorityCases = new List<CaseWrapper>();
        List<CaseWrapper> lClosedCases = new List<CaseWrapper>();
        List<CaseWrapper> lOpenHighPriorityCases = new List<CaseWrapper>();
        List<CaseWrapper> lOpenCases = new List<CaseWrapper>();
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        CaseWrapper caseWrap = new CaseWrapper();
        DateTime last6Hours = System.now().addHours(-6);
        System.debug('startDate ' + startDate + ' endDate ' + endDate);
        lstCase = [SELECT Id,AKAM_Case_ID__c,Subject,ParentId,Parent.AKAM_Case_ID__c, Case_Account_Name__c,Account.Name,Case_Transition_Date__c,
                   Severity__c,Age_days__c,Shift_Owner__c,Shift_Owner__r.Name,Service__c,Status,Priority_Type__c,IsClosed,
                   LastModifiedDate, LastModifiedBy.Name,LastModifiedById,Request_Type__c,Living_Summary_Next_Steps__c,
                   CreatedDate,
                   (SELECT Id,ID__c,Request_Status__c,URL__c 
                    FROM Engagement_Requests__r 
                    WHERE Request_Status__c != 'Closed'),
                   (SELECT Id,Subject,Type__c,DueDateProlexic__c,Status 
                    FROM Tasks 
                    WHERE RecordTypeId =:secServTaskRecTypeId
                    AND Status = 'Completed' AND Completed_Date_Time__c >= :startDate 
                    AND Completed_Date_Time__c < :endDate ORDER BY Type__c)
                    FROM Case
                   WHERE RecordTypeId = :psRecTypeId 
                   //ESESP-5678 : including 24 PS cases for the report
                   AND (OwnerId = :s2etQId OR OwnerId = :PS24QId)
                   AND ((isClosed != true)
                   OR (ClosedDate >= :startDate AND  ClosedDate < :endDate))
                   //ESESP-5981 : ordering by Age as well
                   ORDER BY Severity__c ASC, Age_days__c DESC];
        
        for(Case eachCase : lstCase)
        {
            caseWrap = new CaseWrapper();
            //caseWrap.caseRec = eachCase;
            caseWrap.caseId = eachCase.Id;
            caseWrap.akamCaseId = eachCase.AKAM_Case_ID__c;
            if(String.isNotBlank(eachCase.ParentId))
            {
                caseWrap.parentCaseAKAMId = eachCase.Parent.AKAM_Case_ID__c;
            }
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
            
            //caseWrap.numberOfOpenCase = numberOfOpenCase;
            //caseWrap.numOfClosedCases = numOfClosedCases;
            caseWrap.escStatus = '';
            caseWrap.lEscalationRecords = new List<Engagement_Request__c>();
            if(!eachCase.Engagement_Requests__r.isEmpty())
            {
                for(Engagement_Request__c e : eachCase.Engagement_Requests__r)
                {
                    caseWrap.lEscalationRecords.add(e);
                    caseWrap.escStatus += e.ID__c + '-' + e.Request_Status__c + '<br>';
                }
               // caseWrap.escStatus = caseWrap.escStatus.substring(0,caseWrap.escStatus.length() - 1);
            }
            
            caseWrap.taskCompleted = '';
            caseWrap.taskNext = '';
            if(!eachCase.Tasks.isEmpty())
            {
                for(Task t : eachCase.Tasks)
                {
                    if(t.Status == 'Completed')
                        caseWrap.taskCompleted += t.Type__c + '<br>'; 
                    else if(t.Status == 'Not Started' || t.Status == 'In Progress' || t.Status == 'Deferred')
                        caseWrap.taskNext += t.Type__c + '<br>'; 
                }
                //caseWrap.taskCompleted = caseWrap.taskCompleted.substring(0,caseWrap.taskCompleted.length() - 1);
                //caseWrap.taskNext = caseWrap.taskNext.substring(0,caseWrap.taskNext.length() - 1);
            }
            if (caseWrap.hotCustomer == '') {
                if (eachCase.Status.containsIgnoreCase('close')) {
                    numberOfClosedCases++;
                    caseWrap.caseType = 'ClosedCase';
                    lClosedCases.add(caseWrap);
                }
                else {
                    numberOfTotalOpenCases++;
                    if (eachCase.Case_Transition_Date__c >= startDate && eachCase.Case_Transition_Date__c <endDate) {
                        numberOfOpenCase++;
                    }                    
                    caseWrap.caseType = 'OpenCase';
                    lOpenCases.add(caseWrap);
                }
            }
            else {
                if (!eachCase.Status.containsIgnoreCase('close')) {
                    numberOfTotalOpenCases++;
                    if (eachCase.Case_Transition_Date__c >= startDate && eachCase.Case_Transition_Date__c <endDate) {
                        numberOfOpenCase++;
                    }
                    caseWrap.caseType = 'HighPriorityOpenCase';
                    lOpenHighPriorityCases.add(caseWrap);
                }
                else {
                    numberOfClosedCases++;
                    caseWrap.caseType = 'HighPriorityClosedCase';
                    lClosedHighPriorityCases.add(caseWrap);
                }
            }
            
        }
        lListCaseWrapper.add(lOpenHighPriorityCases);
        lListCaseWrapper.add(lOpenCases);
        lClosedHighPriorityCases.addAll(lClosedCases);
        lListCaseWrapper.add(lClosedHighPriorityCases);
        //lListCaseWrapper.add(lClosedCases);

        // lstCaseWrapper.addAll(lOpenHighPriorityCases);
        // lstCaseWrapper.addAll(lOpenCases);
        // lstCaseWrapper.addAll(lClosedHighPriorityCases);
        // lstCaseWrapper.addAll(lClosedCases);        
        //System.debug('###lstCaseWrapper ' + lstCaseWrapper[0].akamCaseId);

        return lListCaseWrapper;                   
    }

    
    public class TaskWrapper
    {
        @AuraEnabled public Task taskRec;
        @AuraEnabled public Id taskId;
        @AuraEnabled public String akamActivityId;
        @AuraEnabled public String relatedCaseAKAMId;
        @AuraEnabled public Id relatedCaseId;
        @AuraEnabled public String relatedCaseAccountName;
        @AuraEnabled public String subject;
        @AuraEnabled public String taskType;
        @AuraEnabled public Id assignedToId;
        @AuraEnabled public String assignedToName;
        @AuraEnabled public String assignedShift;
        @AuraEnabled public String status;
        @AuraEnabled public String dueIn;
        @AuraEnabled public Integer dueInMins;
        @AuraEnabled public String taskColour;
        @AuraEnabled public String taskStatusColour;
        @AuraEnabled public DateTime lastUpdatedDate;
        @AuraEnabled public Integer lastUpdatedMins;
        @AuraEnabled public String lastUpdatedDateTimeString;
        @AuraEnabled public String taskUrl;
        @AuraEnabled public String caseUrl;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String assignedToUrl;
        @AuraEnabled public String taskDescription;
    }
    
    @AuraEnabled
    public static List<TaskWrapper> getTaskList(String taskShift, String taskStatus,String caseSeverity, String casePriority) 
    {
        Id secServTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Id s2etQId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'S2ET_Queue_Id' LIMIT 1].Value_Text__c;
        //ESESP-5678 : diplay tasks of 24 PS cases as well.
        Id PS24QId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'PS24_Queue_Id' LIMIT 1].Value_Text__c;

        
        String sevQuery = '';
        String priorityQuery = '';
        String shiftQuery = '';
        String statusQuery = '';
        
        Map<Id,Case> mapRelatedCases = new Map<Id,Case>();
        List<Case> lstCase = new List<Case>();
        Set<Id> lCaseId = new Set<Id>();
        
        //ESESP-5678 : adding 24 ps cases as well
        String caseQuery = 'SELECT Id,AKAM_Case_ID__c,AccountId,Account.Name '
            			   	+ ' FROM Case WHERE RecordTypeId = \''+ psRecTypeId + '\' AND IsClosed = FALSE AND (OwnerId = \'' + s2etQId + '\' OR OwnerId = \'' + PS24QId + '\')';
        
        if(!caseSeverity.equalsIgnoreCase('1,2,3,4')) 
        {
            List<String> sevVals = caseSeverity.split(',');
            sevQuery = ' AND Severity__c IN :sevVals';
        }
        
        if(!casePriority.equalsIgnoreCase('all')) 
        {
            List<String> priorVals = casePriority.split(',');
            priorityQuery = ' AND Priority_Type__c IN :priorVals';
        }
        
        caseQuery += sevQuery + priorityQuery;
        
        lstCase = Database.query(caseQuery);
        for(Case c : lstCase)
        {
            mapRelatedCases.put(c.Id,c);
        }
        lCaseId = mapRelatedCases.keyset();
        /*
        mapRelatedCases = new map<Id,Case>([SELECT Id,AKAM_Case_ID__c,AccountId,Account.Name
                                            FROM Case
                                            WHERE RecordTypeId = :psRecTypeId AND IsClosed = FALSE
                                            AND Severity__c IN :caseSevVals AND Priority_Type__c IN :casePriorityVals
                                            AND OwnerId = :s2etQId]);
        */
            
        List<Task> lstTask = new List<Task>();
        
        List<TaskWrapper> lstTaskWrapper = new List<TaskWrapper>();
        TaskWrapper taskWrap = new TaskWrapper();
        
        String taskQuery =  'SELECT Id,Subject,Type__c,OwnerId,Owner.Name,Status,DueDateProlexic__c,WhatId,Assigned_Shift__c,AKAM_Activity_ID__c,LastModifiedDate '
                            + 'FROM Task '
                            + ' WHERE RecordTypeId = \'' + secServTaskRecTypeId + '\' AND Status != \'Completed\' AND Status != \'Cancelled\' '
                            + ' AND WhatID IN :lCaseId ';
        
        String orderByQuery = ' ORDER BY DueDateProlexic__c ';
        if(!taskShift.equalsIgnoreCase('all')) 
        {
            List<String> shiftVals = taskShift.split(',');
            shiftQuery = ' AND Assigned_Shift__c IN :shiftVals';
        }
        
        if(!taskStatus.equalsIgnoreCase('all')) 
        {
            List<String> statusVals = taskStatus.split(',');
            statusQuery = ' AND Status IN :statusVals';
        }
        
        taskQuery += shiftQuery + statusQuery + orderByQuery;
        System.debug('Task Query : ' + taskQuery);
        lstTask = Database.query(taskQuery);   
        
        /*
        lstTask = [SELECT Id,Subject,Type__c,OwnerId,Owner.Name,Status,DueDateProlexic__c,WhatId,Assigned_Shift__c,AKAM_Activity_ID__c,LastModifiedDate
                   FROM Task
                   WHERE RecordTypeId = :secServTaskRecTypeId AND Status != 'Completed' AND Status != 'Cancelled'
                   AND WhatID IN :mapRelatedCases.keyset()
                   AND Assigned_Shift__c IN :taskShiftVals AND Status IN :taskStatusVals
                   ORDER BY DueDateProlexic__c
                   ];
        */
        
        for(Task t : lstTask)
        {
            taskWrap = new TaskWrapper();
            taskWrap.taskRec = t;
            taskWrap.taskId = t.Id;
            taskWrap.akamActivityId = t.AKAM_Activity_ID__c;
            //System.assertEquals(true,mapTaskCase.containsKey(t.Id));
            if(mapRelatedCases.containsKey(t.WhatId)) 
            {
                taskWrap.relatedCaseAKAMId = mapRelatedCases.get(t.WhatId).AKAM_Case_ID__c ; 
                taskWrap.relatedCaseId = t.WhatId;
                taskWrap.relatedCaseAccountName = mapRelatedCases.get(t.WhatId).Account.Name;
                taskWrap.caseUrl = '/lightning/r/Case/' + t.WhatId + '/view';
                if(String.isNotBlank(mapRelatedCases.get(t.WhatId).AccountId))
                {
                    taskWrap.accountUrl = '/lightning/r/Account/' + mapRelatedCases.get(t.WhatId).AccountId + '/view';
                }
            }
            else 
            {
                taskWrap.relatedCaseAKAMId = taskWrap.relatedCaseAccountName = '';
                taskWrap.relatedCaseId = NULL;
                taskWrap.caseUrl = taskWrap.accountUrl = ''; 
            }
            
            taskWrap.subject = t.Subject;
            taskWrap.taskType = t.Type__c;
            taskWrap.assignedToId = t.OwnerId;
            taskWrap.assignedToName = t.Owner.Name;
            taskWrap.assignedShift = t.Assigned_Shift__c;
            taskWrap.status = t.Status;
            
            Integer min = Integer.valueOf((t.DueDateProlexic__c.getTime() - DateTime.now().getTime())/1000/60);
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
            
            taskWrap.lastUpdatedDate = t.LastModifiedDate;
            min = Integer.valueOf((t.LastModifiedDate.getTime() - DateTime.now().getTime())/1000/60);
            taskWrap.lastUpdatedMins = min;
            
            taskWrap.lastUpdatedDateTimeString = '';
            min = Integer.valueOf((DateTime.now().getTime() - t.LastModifiedDate.getTime())/1000/60);
            if(min/24/60 > 0)
                taskWrap.lastUpdatedDateTimeString += min/24/60 + 'd ';
            if(Math.mod(min/60,24) > 0)
                taskWrap.lastUpdatedDateTimeString += Math.mod(min/60,24) + 'h ';
            if(Math.mod(min,60) >= 0)
                taskWrap.lastUpdatedDateTimeString += Math.mod(min,60) + 'm ';
            if(String.isNotBlank(taskWrap.lastUpdatedDateTimeString))
            {
                taskWrap.lastUpdatedDateTimeString += 'ago';
            }
            
            taskWrap.taskUrl = '/lightning/r/Task/' + t.Id + '/view';
            taskWrap.assignedToUrl = '/lightning/r/User/' + t.OwnerId + '/view';
            lstTaskWrapper.add(taskWrap);
        }
        System.debug('Task Size' + lstTaskWrapper.size());
        lstTask.clear();
        return lstTaskWrapper;                   
    }
    
    @AuraEnabled
    public static List<TaskWrapper> getAllTaskRecs(Id caseId)
    {
        List<TaskWrapper> lstTaskWrap = new List<TaskWrapper>();
        
        List<Task> lstTask = new List<Task>();
        TaskWrapper taskWrapperRec;
        
        Id secServTaskRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();

        lstTask = [SELECT Id,Subject,Type__c,OwnerId,Owner.Name,Status,Description,Priority,DueDateProlexic__c,
                   WhatId,Assigned_Shift__c,AKAM_Activity_ID__c,LastModifiedDate,IsClosed,Completed_Date_Time__c
                   FROM Task 
                   WHERE WhatId = :caseId AND RecordTypeId =:secServTaskRecTypeId
                   ORDER BY IsClosed,Completed_Date_Time__c DESC,DueDateProlexic__c 
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
                    if(thisTask.IsClosed && String.isNotBlank(String.valueOf(thisTask.Completed_Date_Time__c)))
                    {
                        taskWrapperRec.dueIn = thisTask.Completed_Date_Time__c.format();
                        if(thisTask.Completed_Date_Time__c > thisTask.DueDateProlexic__c)
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
                            taskWrapperRec.dueIn = '-' + (min/60 * -1) + 'h ' +  (Math.mod(min,60)) * -1 + 'm';
                            taskWrapperRec.taskColour = 'red';
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
    
    public class EscalationWrapper
    {
        //@AuraEnabled public Engagement_Request__c escRec;
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
    
    
    @AuraEnabled(cacheable=true)
    public static sObject getRecordDetails(Id recordId, String objectName, String fields)
    {
        sObject sObj;
        String baseQuery = 'SELECT ' + fields + ' FROM ' + objectName + ' WHERE ID = \'' + recordId + '\'';
        System.debug(baseQuery);
        sObj = Database.query(baseQuery);
        //Task t = [SELECT DueDateProlexic__c FROM Task WHERE Id = :recordId];
        return sObj;
    }
    
    @AuraEnabled
    public static Id returnRecTypeId(String sObjName, String recTypeName)
    {
        System.debug('Entered');
        String query = 'SELECT Id FROM RecordType WHERE SobjectType = \'' + sObjName + '\'' + ' AND Name = \'' + recTypeName + '\'';
        SObject so = Database.query(query);
        return so.Id;
    }
    
    @AuraEnabled
    public static void changeShiftOwner(List<Id> lstCaseIDs, String shiftOwnerId)
    {   
        List<Case> lstCases = [SELECT Id,Shift_Owner__c FROM Case WHERE Id IN :lstCaseIDs FOR UPDATE];
        
        List<Case> casesToUpdate = new List<Case>();
        for(Case eachCase : lstCases)
        {
            if(String.isNotBlank(shiftOwnerId))
                eachCase.Shift_Owner__c = shiftOwnerId;
            else
                eachCase.Shift_Owner__c = NULL;
            casesToUpdate.add(eachCase);
        }
        
        //update casesToUpdate;
        
        try
        {
            update casesToUpdate;
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
            //throw new AuraHandledException(e.getMessage());
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));
        }
    }
    
    @AuraEnabled
    public static void changeAssignedTo(List<Id> lstTaskIDs, String assignedToId)
    {
        System.debug('changeAssignedTo entered ' + assignedToId + ':: ' + lstTaskIDs.size());
        Id onaID = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Owner_Not_Assigned_User_Id' LIMIT 1].Value_Text__c;        
        
        List<Task> lstTasks = [SELECT Id,OwnerId FROM Task WHERE Id IN :lstTaskIDs FOR UPDATE];
        List<Task> tasksToUpdate = new List<Task>();
        
        for(Task eachTask : lstTasks)
        {
            if(String.isNotBlank(assignedToId))
                eachTask.OwnerId = assignedToId;
            else
                eachTask.OwnerId = onaID;
            tasksToUpdate.add(eachTask);
        }
        //update tasksToUpdate;

        try
        {
            update tasksToUpdate;
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));
        }
    }
    
    @AuraEnabled
    public static void changeStatus(List<Id> lstTaskIDs, String status)
    {
        List<Task> lstTasks = [SELECT OwnerId FROM Task WHERE Id IN :lstTaskIDs FOR UPDATE];
        List<Task> tasksToUpdate = new List<Task>();
        
        for(Task eachTask : lstTasks)
        {
            eachTask.Status = status;
            tasksToUpdate.add(eachTask);
        }
        //update tasksToUpdate;
        
        try
        {
            update tasksToUpdate;
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));
        }
    }
    
    @AuraEnabled
    public static void deferTasks(List<Id> lstTaskIDs, String defer)
    {
        List<Task> lstTasks = [SELECT Id,DueDateProlexic__c,Status FROM Task WHERE Id IN :lstTaskIDs FOR UPDATE];
        List<Task> tasksToUpdate = new List<Task>();
        
        for(Task eachTask : lstTasks)
        {
            eachTask.Status = 'Deferred';
            eachTask.DueDateProlexic__c = eachTask.DueDateProlexic__c.addHours(Integer.valueOf(defer));
            //System.assertEquals(eachTask.DueDateProlexic__c, eachTask.DueDateProlexic__c.addHours(Integer.valueOf(defer)));
            
            tasksToUpdate.add(eachTask);
        }
        //update tasksToUpdate;
        
        try
        {
            SC_TaskTriggerHandler.s2etTaskDeferBypass = false;
            update tasksToUpdate;
        }
        catch(Exception e)
        {
            System.debug(e.getMessage());
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));
        }
    }
    
    @AuraEnabled
    public static List<System_to_Area_Mapping__c> systemAreaMappingRecords()
    {
        List<System_to_Area_Mapping__c> lst = [SELECT System__c, Area__c, System_URL__c 
                                               FROM System_to_Area_Mapping__c
                                               ORDER BY System__c];
        return lst;
    }
    
    @AuraEnabled
    public static void emailShiftHandoverReport(String shiftInfo)
    {
        System.debug('##shiftInfo ' + shiftInfo);
        SC_S2ET_SendEmailHTML.getShiftDetails(shiftInfo);
    }
    
    @AuraEnabled(cacheable=true)
    public static String returnONAId()
    {
        String onaId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Owner_Not_Assigned_User_Id'].Value_Text__c;
        return onaId;
    }
    
    @AuraEnabled
    public static Engagement_Request__c returnEscalationRec(String escId)
    {
        Engagement_Request__c escRec = [SELECT System__c,Area__c,Case__c FROM Engagement_Request__c WHERE Id = :escId];
        return escRec;
    }

    @AuraEnabled
    public static Map<String,String> saveS2ETFilters(String filterToSave)
    {
        Map<String,String> savedFilterVal = new Map<String,String>();

        List<SC_QM_User_Filter__c> filter = new List<SC_QM_User_Filter__c>();

        filter = [SELECT User_Id__c,S2ET_Dashboard_Filter__c 
                  FROM SC_QM_User_Filter__c 
                  WHERE User_Id__c = :UserInfo.getUserId() limit 1];
        
        String selectAll = 'CaseSeverity:1,2,3,4&CasePriority:All&TaskShift:All&TaskStatus:All';
        savedFilterVal.put('CaseSeverity','1,2,3,4');
        savedFilterVal.put('CasePriority','All');
        savedFilterVal.put('TaskShift','All');
        savedFilterVal.put('TaskStatus','All');

        if(filter.size() == 0)
        {
            SC_QM_User_Filter__c newrow = new SC_QM_User_Filter__c(S2ET_Dashboard_Filter__c = selectAll,User_Id__c = UserInfo.getUserId());
            upsert newrow;
        }
        else if(String.isBlank(filter[0].S2ET_Dashboard_Filter__c))
        {
            filter[0].S2ET_Dashboard_Filter__c = selectAll;
            upsert filter;
        }
        else
        {
            if(String.isNotBlank(filterToSave))
            {
                filter[0].S2ET_Dashboard_Filter__c = filterToSave;
                upsert filter;
                return NULL;
            }
            else
            {
                savedFilterVal = new Map<String,String>();
                List<String> filterVals = filter[0].S2ET_Dashboard_Filter__c.split('&');
                for(String s : filterVals)
                {
                    List<String> text = s.split(':');
                    savedFilterVal.put(text[0],text[1]);
                }
            }
        }   
        return savedFilterVal; 
    }

    @AuraEnabled(Cacheable=false)
    public static Map<String,Object> getSpecialNotes(){
        String key = '-SPCLNOTES-';
        List<SC_QM_User_Filter__c> filters = [SELECT Id,SpecialNotes__c,LastModifiedBy.Name,LastModifiedDate FROM SC_QM_User_Filter__c WHERE User_Id__c=:key LIMIT 1];
        if (filters.size() > 0) {
            return new Map<String, Object>{
                    'notes' => filters[0].SpecialNotes__c,
                    'lastModifiedBy' => filters[0].LastModifiedBy.Name,
                    'lastModifiedDate' => filters[0].LastModifiedDate
            };
        }
        return null;
    }

    @AuraEnabled(Cacheable=false)
    public static void updateSpecialNotes(String notes){
        String key = '-SPCLNOTES-';
        SC_QM_User_Filter__c filter = new SC_QM_User_Filter__c(User_Id__c=key,SpecialNotes__c = notes);
        upsert filter User_Id__c;
    }

}