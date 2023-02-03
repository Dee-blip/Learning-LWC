/*
************************************************************************************************************
    Author              :   Vikas 
    Created             :   22-July-2020
    Purpose             :   Test Class for SC_ProvisioningDashboard_Controller - Provisioning Dashboard Controller

************************************************************************************************************
*/

@isTest
public class SC_ProvisioningDashboard_Controller_Test {
/* TEST DATA SETUP */
    
    @testSetup
    static void testDataSetup()
    {
        utilTestClass.createCustomSettings();
        
        Group amgNAHotseatQ = [Select Id, Name FROM Group 
                               WHERE Type = 'Queue' 
                               AND Name = 'PS_AMER_Security_Prolexic'];
        
        // Creating Account
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestPLXAccount');   
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
            newCase.Subject = 'New Pls Case ' + i;
            newCase.Description = 'New Plx Description ' + i;
            newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            newCase.Validation_Override__c = true;
            newCase.AccountId = acc.Id;
            newCase.OwnerId = amgNAHotseatQ.Id;
            newCase.origin='Akamai';
            newcase.Status = 'Unassigned';
            newcase.Close_Code__c = 'Complete';
            newcase.PS_Product__c = 'PLX Connect';
            newcase.Shift_Owner__c = u.id;
            newcase.Sub_Type__c = 'Change';
            newcase.Fund_Type__c = 'IW';
            newcase.Logo_Type__c = 'New';
            
            if(Math.mod(i,3) == 0)
            {
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Onboarding / Integration';
                newcase.Is_SOCC_Priority__c = true;
                newcase.Priority_Type__c = 'Hot Customer';
                newcase.Priority_Expiry_Date__c = System.now().addDays(3);
                newcase.Last_Customer_Activity_Date__c = System.now();
            }
            else if(Math.mod(i,3) == 1)
            {
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Security Configuration Assistance';
                newcase.Requested_Completion_Date_UTC__c = System.today().addDays(1);
                newcase.Requested_Completion_Time_UTC__c = '00:00';
                newcase.Is_SOCC_Priority__c = true;
                newcase.Priority_Type__c = 'Special Instructions';
                newcase.Priority_Expiry_Date__c = System.now().addDays(3);
                newcase.Last_Case_Update__c = System.now();
                newcase.Plx_Update__c = true;
                newcase.Deferred_Revenue__c = true;
            }
            else
            {
                newcase.Service__c = 'Other (Security)';
                newcase.Request_Type__c = 'Scheduled Deployment';
                newcase.Priority_Type__c = 'High Alert Case/Task';
            }
            newCaseInsertList.add(newCase); 
        }
        
        Policy_Domain__c pd = new Policy_Domain__c();
        pd.Account_name__c = acc.Id;
        pd.Name = 'plx PD';
        pd.Product__c  = 'PLX';
        pd.Policy_Domain_State__c = 'Active';
        insert pd;
        
        System.runAs(u)
        {
            insert newCaseInsertList;
            
            for(Case ss : [Select id,Geography__c,Subject from case where id in:newCaseInsertList]){
                system.debug('askduasdh : '+ss);
            }
            Task t = new Task();
            t.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Provisioning_Activity').getRecordTypeId();
            t.Type__c = 'Gather Logs';
            t.Subject = 'Testing New Task for Prov';
            t.WhatId = newcase.Id;
            t.Status = 'Not Started';
            t.DueDateProlexic__c = System.now().addHours(2);
            insert t;
            
            Task_PD_Mapping__c taskPDMap = new Task_PD_Mapping__c();
            taskPDMap.Policy_Domain__c = pd.id;
            taskPDMap.Task_ID__c = t.id;
            insert taskPDMap;
        }
    }
    
    public static testMethod void plxTestCases()
    {
        Test.startTest();
        List<SC_ProvisioningDashboard_Controller.CaseWrapper> caseWrapperList = SC_ProvisioningDashboard_Controller.getCaseList('1,2,3,4','All','All','All','All','blue,white,red,yellow','Americas,AP,Japan,Others');
        caseWrapperList = SC_ProvisioningDashboard_Controller.getCaseList('3','Hot Customer','Security Bucket','Special','N/A','blue,white,red,yellow','Americas,AP,Japan,Others');
        List<List<SC_ProvisioningDashboard_Controller.CaseWrapper>> caseWrapperListReport = SC_ProvisioningDashboard_Controller.getCaseListForReport(System.now(),System.now().addHours(6));
        
        SC_QM_User_Filter__c filter = new SC_QM_User_Filter__c();
        filter.User_Id__c = UserInfo.getUserId();
        filter.Provisioning_Dashboard_Filter__c = 'CaseSeverity:1,2,3,4&ColorCategory:blue,white,red,yellow&CasePriority:All&CaseFundType:All&CaseLogoType:All&CaseSubType:All&Geo:Americas,EMEA,Japan,AP,Others&TaskStatus:All';
       insert filter;
        Map<String,String> mapStrStr = SC_ProvisioningDashboard_Controller.savePlxFilters('CaseSeverity:1,2,3,4&ColorCategory:blue,white,red,yellow&CasePriority:All&CaseFundType:All&CaseLogoType:All&CaseSubType:All&Geo:Americas,EMEA,Japan,AP,Others&TaskStatus:All');
         Test.stopTest();
    }
    
    public static testMethod void plxTestReport()
    {
        Test.startTest();
        SC_ProvisioningDashboard_Controller.emailShiftHandoverReport();
        Test.stopTest();
    }
    
    public static testMethod void plxTestTask()
    {
        Test.startTest();
        List<SC_ProvisioningDashboard_Controller.TaskWrapper> taskWrapperList = SC_ProvisioningDashboard_Controller.getTaskList('All','1,2,3,4','All','All','All','All','blue,white,red,yellow','Americas,AP,Japan,Others'); 
        Map<String,String> mapStrStr = SC_ProvisioningDashboard_Controller.savePlxFilters('CaseSeverity:1,2,3,4&ColorCategory:blue,white,red,yellow&CasePriority:All&CaseFundType:All&CaseLogoType:All&CaseSubType:All&Geo:Americas,EMEA,Japan,AP,Others&TaskStatus:All');
        Test.stopTest();
    }
    
    public static testMethod void plxTestEscalation()
    {
        Case c = [SELECT Id,Owner.Name FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        
        Engagement_Request__c escReq = new Engagement_Request__c();
        escReq.ID__c = 'JIRA-123';
        escReq.System__c = 'JIRA';
        escReq.Case__c = c.Id;
        
        Test.startTest();
        insert escReq;
        List<SC_ProvisioningDashboard_Controller.EscalationWrapper> escWrapperList = SC_ProvisioningDashboard_Controller.getEscalationRecs(c.Id);
        Id recTypeId = SC_ProvisioningDashboard_Controller.returnRecTypeId('Case','Professional Services');
        String s = SC_ProvisioningDashboard_Controller.returnONAId();
        Test.stopTest();
    }
    
    public static testMethod void plxChangeOwners()
    {
        Case c = [SELECT Id,Owner.Name FROM Case WHERE RecordType.Name = 'Professional Services' LIMIT 1];
        Task t = [SELECT Id,Status FROM Task WHERE RecordType.Name = 'Provisioning Activity' LIMIT 1];
        c.Fund_type__c = 'IW';
        c.Logo_type__c = 'New';
        c.Sub_Type__c = 'Change';
        c.PS_Product__c = 'PLX Connect';
        c.Validation_Override__c = true;
        update c;

        Test.startTest();
        SC_ProvisioningDashboard_Controller.getAllTaskRecs(c.Id);
        try{
        	SC_ProvisioningDashboard_Controller.changeShiftOwner(new List<Id>{c.Id},UserInfo.getUserId());
        }
        catch(Exception e){
            System.debug('Exception caught');
        }
        SC_ProvisioningDashboard_Controller.changeCaseOwner(new List<Id>{c.Id},UserInfo.getUserId());
        SC_ProvisioningDashboard_Controller.changeTaskAssignedTo(new List<Id>{t.Id},UserInfo.getUserId());
        SC_ProvisioningDashboard_Controller.assignTaskShift(new List<Id>{t.Id},'AMER First');
        SC_ProvisioningDashboard_Controller.fetchTaskShift(t.id);
        SC_ProvisioningDashboard_Controller.changeStatus(new List<Id>{t.Id},'In Progress');
        Test.stopTest();
    }
    
    public static testMethod void plxChangeForTask()
    {
        Task t = [SELECT Id,Status FROM Task WHERE RecordType.Name = 'Provisioning Activity' LIMIT 1];
        t.DueDateProlexic__c = null;

        Test.startTest();
        update t;
        SC_ProvisioningDashboard_Controller.changeTaskAssignedTo(new List<Id>{t.Id},UserInfo.getUserId());
        SC_ProvisioningDashboard_Controller.assignTaskShift(new List<Id>{t.Id},'AMER First');
        SC_ProvisioningDashboard_Controller.fetchTaskShift(t.id);
        SC_ProvisioningDashboard_Controller.changeStatus(new List<Id>{t.Id},'In Progress');
        Test.stopTest();
    }
    
    public static testMethod void updatePlxTask()
    {
        Task t = [SELECT Id,Status FROM Task WHERE RecordType.Name = 'Provisioning Activity' LIMIT 1];

        Test.startTest();
        t.DueDateProlexic__c = System.now().addHours(6);
        update t;
        List<List<SC_ProvisioningDashboard_Controller.CaseWrapper>> caseWrapperListReport = SC_ProvisioningDashboard_Controller.getCaseListForReport(System.now(),System.now().addHours(6));
        Test.stopTest();
    }
    
    public static testMethod void pdMappingTest()
    {
        Task t = [SELECT Id,WhatId,Status FROM Task WHERE RecordType.Name = 'Provisioning Activity' LIMIT 1];
        //List<Account> accList =  new List<Account>();
        //Account acc = utilTestClass.CreateAccount('TestPLXAccount New');   
        //accList.add(acc);
        //insert accList;
        Case testCase = [SELECT AccountId FROM Case WHERE Id = :t.WhatId];
        List<Id> pdList = new List<Id>();
        
        List<Policy_Domain__c> lstPD = new List<Policy_Domain__c>();
        Policy_Domain__c pd = new Policy_Domain__c();
        pd.Account_name__c = testCase.AccountId;
        pd.Name = 'plx PD 1';
        pd.Product__c = 'PLX';
        pd.Policy_Domain_State__c = 'Active';
        lstPD.add(pd);
        insert lstPD;
        
        pdList.add(pd.id);
        
        
        Test.startTest();
        SC_ProvisioningDashboard_Controller.getPDs(t.id);
        SC_ProvisioningDashboard_Controller.savePDMappings(pdList,t.id);
        SC_ProvisioningDashboard_Controller.deletePDMappings(pdList,t.id);
        
        Test.stopTest();
    }
    
    public static testMethod void searchLookupTest()
    {
        Policy_Domain__c pd = [SELECT Id FROM Policy_Domain__c LIMIT 1];
        Task t = [SELECT Id,WhatId,Status FROM Task WHERE RecordType.Name = 'Provisioning Activity' LIMIT 1];
        List<String> pdStrList = new List<String>();
        pdStrList.add(String.valueOf(pd.id));
        SC_ProvisioningDashboard_Controller.search('PLX',pdStrList,String.valueOf(t.id));
        String PDURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Policy_Domain__c/';
        List<SC_LookupSearchResult> results = new List<SC_LookupSearchResult>();
        results.add(
            new SC_LookupSearchResult(
                pd.Id,
                'Policy_Domain__c',
                'custom:custom20',
                'pd1',
                PDURL+pd.Id));
        results.add(
            new SC_LookupSearchResult(
                pd.Id,
                'Policy_Domain__c',
                'custom:custom20',
                'pd2',
                PDURL+pd.Id));
        results[0].getId();results[0].getSObjectType();
        results[0].getIcon();results[0].getTitle();
        results[0].getRecordUrl();
        results[1].compareTo(results[0]);
    }
    
}