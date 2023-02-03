/*
************************************************************************************************************
    Author              :   Vandhana Krishnamurthy
    Created             :   22-April-2020
    Purpose             :   Test Class for SC_SecurityServices_Ctrlr - S2ET Dashboard Controller
	JIRA Story			:   ESESP-3524 :: Security Services Dashboard: S2ET Dashboard and Case Improvements

************************************************************************************************************

*/

@isTest
public class SC_SecurityServices_Ctrlr_Test 
{
	/* TEST DATA SETUP */
    
    @testSetup
    static void testDataSetup()
    {
        utilTestClass.createCustomSettings();
        
        Group amgNAHotseatQ = [Select Id, Name FROM Group 
                               WHERE Type = 'Queue' 
                               AND Name = 'PS_Security_Escalation_Team'];
        
        // Creating Account
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestS2ETAccount');   
        accList.add(acc);
        insert accList;
        
        System.debug('1.Number of Queries used after Account Insert: ' + Limits.getQueries());
        
        Test.startTest();
        
        List<Case> newCaseInsertList = new List<Case>();
        Case newCase = new Case();
        
        User u = [Select Id FROM User WHERE Profile.Name = 'GSS Professional Services' AND IsActive = TRUE LIMIT 1];
        for(Integer i=0; i<3; i++)
        {
            newCase = new Case();
            newCase.Subject = 'New S2ET Case ' + i;
            newCase.Description = 'New S2ET Description ' + i;
            newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            newCase.Validation_Override__c = true;
            newCase.AccountId = acc.Id;
            newCase.OwnerId = amgNAHotseatQ.Id;
            newCase.origin='Akamai';
            newcase.Status = 'Unassigned';
            newcase.Close_Code__c = 'Complete';
            if(Math.mod(i,3) == 0)
            {
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Other';
                newcase.Is_SOCC_Priority__c = true;
                newcase.Priority_Type__c = 'Hot Customer';
                newcase.Priority_Expiry_Date__c = System.now().addDays(3);
                newcase.Last_Customer_Activity_Date__c = System.now();
            }
            else if(Math.mod(i,3) == 1)
            {
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Scheduled Deployment';
                newcase.Requested_Completion_Date_UTC__c = System.today().addDays(1);
                newcase.Requested_Completion_Time_UTC__c = '00:00';
                newcase.Is_SOCC_Priority__c = true;
                newcase.Priority_Type__c = 'Special Instructions';
                newcase.Priority_Expiry_Date__c = System.now().addDays(3);
                newcase.Last_Case_Update__c = System.now();
            }
            else
            {
                newcase.Service__c = 'Emergency Integration';
                newcase.Request_Type__c = 'Scheduled Deployment';
                newcase.Requested_Completion_Date_UTC__c = System.today().addDays(1);
                newcase.Requested_Completion_Time_UTC__c = '00:00';
            }
            newCaseInsertList.add(newCase); 
        }
        Task t = new Task();
        t.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
        t.Type__c = 'Gather Logs';
        t.Subject = 'Testing New Task';
        t.WhatId = newcase.Id;
        t.DueDateProlexic__c = System.now();
        
        System.runAs(u)
        {
            insert newCaseInsertList;
            insert t;
        }
    }
    
    public static testMethod void s2etTestCases()
    {
        Test.startTest();
        List<SC_SecurityServices_Ctrlr.CaseWrapper> caseWrapperList = SC_SecurityServices_Ctrlr.getCaseList('1,2,3,4','All');
        List<List<SC_SecurityServices_Ctrlr.CaseWrapper>> caseWrapperListReport = SC_SecurityServices_Ctrlr.getCaseListForReport(System.now(),System.now().addHours(1));
        
        SC_QM_User_Filter__c filter = new SC_QM_User_Filter__c();
        filter.User_Id__c = UserInfo.getUserId();
        filter.S2ET_Dashboard_Filter__c = 'CaseSeverity:1,2,3&CasePriority:All&TaskShift:All&TaskStatus:All';
        insert filter;
        Map<String,String> mapStrStr = SC_SecurityServices_Ctrlr.saveS2ETFilters('CaseSeverity:1,2,3,4&CasePriority:All&TaskShift:All&TaskStatus:All');
        Test.stopTest();
    }
    
    public static testMethod void s2etTestReport()
    {
        Test.startTest();
        SC_SecurityServices_Ctrlr.emailShiftHandoverReport('CURRENTSHIFT');
        SC_SecurityServices_Ctrlr.emailShiftHandoverReport('PREVIOUSSHIFT');
        Test.stopTest();
    }
    
    public static testMethod void s2etTestTask()
    {
        Test.startTest();
        List<SC_SecurityServices_Ctrlr.TaskWrapper> taskWrapperList = SC_SecurityServices_Ctrlr.getTaskList('All','All','1,2,3,4','All'); 
        Map<String,String> mapStrStr = SC_SecurityServices_Ctrlr.saveS2ETFilters('CaseSeverity:1,2,3&CasePriority:All&TaskShift:All&TaskStatus:All');
        Test.stopTest();
    }
    
    public static testMethod void s2etTestEscalation()
    {
        Case c = [SELECT Id,Owner.Name FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        
        Engagement_Request__c escReq = new Engagement_Request__c();
        escReq.ID__c = 'JIRA-123';
        escReq.System__c = 'JIRA';
        escReq.Case__c = c.Id;
        escReq.RecordTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('AMG Escalation').getRecordTypeId();
        
        Test.startTest();
        
        insert escReq;
        List<SC_SecurityServices_Ctrlr.EscalationWrapper> escWrapperList = SC_SecurityServices_Ctrlr.getEscalationRecs(c.Id);
        sObject sobj = SC_SecurityServices_Ctrlr.getRecordDetails(c.Id,'Case','Id,Subject');
        Id recTypeId = SC_SecurityServices_Ctrlr.returnRecTypeId('Case','Professional Services');
        String s = SC_SecurityServices_Ctrlr.returnONAId();
        escReq = SC_SecurityServices_Ctrlr.returnEscalationRec(escReq.Id);
        List<System_to_Area_Mapping__c> lst = SC_SecurityServices_Ctrlr.systemAreaMappingRecords();
        Test.stopTest();
    }
    
    public static testMethod void s2etChangeOwners()
    {
        Case c = [SELECT Id,Owner.Name FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        Task t = [SELECT Id,Status,WhatId FROM Task WHERE RecordType.DeveloperName = 'Security_Services_Activity' LIMIT 1];
        Test.startTest();
        SC_SecurityServices_Ctrlr.changeShiftOwner(new List<Id>{c.Id},UserInfo.getUserId());
        SC_SecurityServices_Ctrlr.changeAssignedTo(new List<Id>{t.Id},UserInfo.getUserId());
        SC_SecurityServices_Ctrlr.changeStatus(new List<Id>{t.Id},'In Progress');
        SC_SecurityServices_Ctrlr.getAllTaskRecs(t.WhatId);
        Test.stopTest();
    }
    
    public static testMethod void updateS2ETTask()
    {
        Task t = [SELECT Id,Status FROM Task WHERE RecordType.DeveloperName = 'Security_Services_Activity' LIMIT 1];
        Test.startTest();
        t.DueDateProlexic__c = System.now().addHours(2);
        update t;
        SC_SecurityServices_Ctrlr.deferTasks(new List<Id>{t.Id},'2');
        Test.stopTest();
    }   


     public static testMethod void updateS2ETTaskForCaseTrigerHelperClass2()
    {
        List<Task> t = [SELECT Id,Status,WhatId,RecordTypeId,DueDateProlexic__c FROM Task WHERE RecordType.DeveloperName = 'Security_Services_Activity' LIMIT 1];
        Test.startTest();
        SC_CaseTriggerHelperClass2.createS2ETTaskSchedDeploy(t);
        Test.stopTest();
    }

    @IsTest
    public static void test_updateSpecialNotes(){
        Test.startTest();
        String notes = 'Test 1234';
        SC_SecurityServices_Ctrlr.updateSpecialNotes(notes);
        Test.stopTest();
        Map<String,Object> specialNotes = SC_SecurityServices_Ctrlr.getSpecialNotes();
        System.assert(specialNotes!=null,'Special Notes filter record not found');
        System.assert((String)specialNotes.get('notes') == notes, 'Special notes not updated on filter record');
    }

}