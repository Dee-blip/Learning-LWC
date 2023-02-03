/*****************************************************************************
* Name             : Test_TaskTriggerHandler
* Created By       : Pitamber Sharma
* Created Date     : 21-May-2013
* Purpose          : Test Class for TaskTriggerHandler
Last Modified  Developer  Purpose            
=============    =========   =======
10-Mar-14       Himanshu    Optimize the Test Class
26-May-14       Himanshu    Optimize the Test Class(3.41.1)
06-Nov-2018     Vandhana     Increased Code Coverage
01-Jul-2018     Vishnu       testLunaWakeUpTransitions
27-Sept-2019    Vishnu       ESESP-2207: Preventative Activities on Paid Accounts
*****************************************************************************/

@isTest(seeAllData=false)
private class Test_TaskTriggerHandler
{
    static
    {
        System.runAs(new User(Id = Userinfo.getUserId()))
        { 
            utilTestClass.createCustomSettings();
        }
    }
    
    // Test Method - 1
    static testMethod void testTaskManipulations()
    {    
        Account acc = utilTestClass.CreateAccount('Test Account123');   
        insert acc;
        
        Case cs3 = new Case();
        cs3.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs3.AccountId = acc.Id;
        cs3.Status = 'Unassigned';
        cs3.Validation_Override__c=true;
        insert cs3;
        
        Test.startTest();   
        Task newTask = new Task();
        // Fetching Case Record Types
        //Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        //Id acc1 = [Select Id from Account where Name = 'Microsoft Azure' limit 1].Id;
        //Case cs3 = [select Id from case where RecordType.Name = 'Technical' AND (Not status like 'Close%') limit 1];
        
        try
        {
            // Creating Task   
            newTask = new Task(OwnerId = UserInfo.getUserId(), Subject = 'Other', LOE_hours__c = 5, WhatId = cs3.Id,Partner_Receipt_Status__c = 'Awaiting Receipt');
            newTask.RecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
            newTask.Internal_Only__c = false;
            insert newTask;
            delete newTask;
            newTask = [Select Id from Task where Subject = 'Other' limit 1 ALL ROWS];
            undelete newTask;
        }
        catch(exception e){}
        Test.stopTest();    
    }
    
    // Test Method - 2
    static testMethod void testTaskManipulations1()
    {     
        Account acc = utilTestClass.CreateAccount('Test Account123');   
        insert acc;
        
        Case cs = new Case();
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs.AccountId = acc.Id;
        cs.Status = 'Unassigned';
        cs.Validation_Override__c=true;
        insert cs;
        
        // Fetching Case Record Types
        //Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        //Case cs = [select Id from case where (Not status like 'Close%') limit 1];
        Id serviceActivityRTId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
        Map<Id,Task> tskMap = new Map<Id,Task>();
        Test.startTest();   
        try
        {
            // create task for verifying updateTypeAndInternalOnly
            List<Task> lstTask = new List<Task>();
            Task newTestTask = new Task(OwnerId = UserInfo.getUserId(), Subject = 'Call log', LOE_hours__c = 5, WhatId = cs.Id);
            lstTask.add(newTestTask);
            newTestTask = new Task(OwnerId = UserInfo.getUserId(), Subject = 'Call log', LOE_hours__c = 7, WhatId = cs.Id,RecordTypeId = serviceActivityRTId,Type__c = 'Call');
            lstTask.add(newTestTask);
            tskMap.put(newTestTask.id, newTestTask);
            insert lstTask; 
            MSAzureHandler.varActivateMSAzureCode = true;
            //TaskTriggerHandler.stamp_PartnerName_Receipt_Status(lstTask,tskMap,true);
            newTestTask.Subject = 'Call Log 1';
            update newTestTask;
        }
        catch(exception e){}
        
        Test.stopTest();
    }
    testMethod static void testLunaWakeUpTransitions() {
        Id techAgentProfile, techManagerProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'Support - Tech Support Agent' OR Name = 'Support - Tech Support Manager']){
            if( pf.Name == 'Support - Tech Support Agent')
                techAgentProfile = pf.id;
            else if(pf.Name == 'Support - Tech Support Manager')
                techManagerProfile = pf.Id;  
        }
        
        User techManager = [Select Id,Name from User where  ProfileId =: techManagerProfile and IsActive=true limit 1];
        User techAgent = [Select Id,Name from User where  ProfileId =: techAgentProfile and IsActive=true limit 1];
        
        /*        User techManager = new User(LastName = 'LIVESTON1',
FirstName='JASON1',
Alias = 'jliv1',
Email = 'jason1.liveston@akamai.com',
Username = 'jason1.liveston@akamai.com',
ProfileId = techManagerProfile,
TimeZoneSidKey = 'GMT',
LanguageLocaleKey = 'en_US',
EmailEncodingKey = 'UTF-8',
LocaleSidKey = 'en_US'
);
insert techManager;

User techAgent = new User(LastName = 'LIVESTON2',
FirstName='JASON2',
Alias = 'jliv2',
Email = 'jason2.liveston@akamai.com',
Username = 'jason2.liveston@akamai.com',
ProfileId = techAgentProfile,
TimeZoneSidKey = 'GMT',
LanguageLocaleKey = 'en_US',
EmailEncodingKey = 'UTF-8',
LocaleSidKey = 'en_US'
);
insert techAgent; */
        
        
        //User techAgent =  [select id, Manager.Id, Manager.Name from user where isActive = true and Manager.isActive = true and Profile.Name = 'Support - Tech Support Agent' and Manager.Profile.Name = 'Support - Tech Support Manager' limit 1];
        //User techManager = techAgent.Manager;
        
        Account acc = new Account(name = 'Test Accountzxsoccunique4');
        insert acc;
        
        EB_AccountProductMap__c ProdTest = new EB_AccountProductMap__c(); 
        ProdTest.Name = 'Riverbed_Product';
        ProdTest.EB_Account__c = acc.Id;
        ProdTest.EB_Product__c = 'Riverbed_Product';
        insert ProdTest;
        
        // Technical Case
        Case aCase = new Case(); 
        aCase.RecordType = new RecordType(Name = 'Technical');
        aCase.Sub_Type__c = 'Product Support';
        aCase.Origin = 'Web';
        aCase.Do_Not_Show_in_Portal__c = false;
        aCase.AccountId = acc.Id;
        aCase.OwnerId = techAgent.Id;
        aCase.Case_Product__c = ProdTest.Id;
        aCase.Issue_Summary__c = 'Test';
        aCase.Troubleshooting_to_Date__c = 'Test';
        aCase.Data_Collected__c = 'Test';
        aCase.Customer_Expectations__c = 'Test Expectation';
        aCase.Next_Action_Recommendation__c = 'Test Action';
        
        insert aCase;
        
        Test.startTest();
        System.runAs(techManager) {
            
            PageReference pageRef = Page.SC_CaseTransitionCreateV2;
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('Id',aCase.id);
            
            ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(aCase);
            
            SC_CaseTransitionControllerV2 ctc = new SC_CaseTransitionControllerV2(sc);
            case_transition__c ct = new case_transition__c();
            ct.Target_Shift__c = SC_Utility.getCurrentShiftDetails('Technical') == 'US West' ? 'APAC': 'US West';
            ct.approved_by__c = userinfo.getUserId();
            ct.case__c = aCase.id;
            ct.Shift_Tracker__c = true;
            ctc.caseTransitionObject = ct;
            List<Id> lCt = new List<Id>{ct.id};
                List<Id> lC = new List<Id>{aCase.id};
                    ctc.approveTransition();
            
        }
        
        aCase =  [select id, owner.name, ownerid from case where id = :aCase.Id];
        
        // empty the static list of processed transitiinIds, as we want trigger to run again for the update
        SC_CaseTriggerHelperClass.lstProcessedTransitionIds.clear();
        // uncheck the case trigger flag      
        SC_CaseTriggerHelperClass.flagvalue = false;
        
        // Creating Task 
        Task newTask = new Task(OwnerId = UserInfo.getUserId(), Subject = 'Other', WhatId = aCase.Id, type__c = 'Web Update', Internal_Only__c = false, Visibility__c  = 'Customer');
        newTask.RecordType = new RecordType( name = 'Service Activity');
        insert newTask; 
        
        // UpdateCaseAsync future logic isn't executed do to static flag check - SC_CaseTriggerHelperClass.flagvalue
        // Hence executing the assignment rules of case again
        Database.DMLOptions dmlOpts = new Database.DMLOptions();
        dmlOpts.assignmentRuleHeader.assignmentRuleId = [SELECT Id, Name, SobjectType, Active, CreatedById, CreatedDate, LastModifiedById, LastModifiedDate, SystemModstamp FROM AssignmentRule where SobjectType = 'Case' and name = 'Case Routing'].Id;
        aCase.setOptions(dmlOpts);
        update aCase ;
        Test.stopTest();
        
        aCase =  [select id, owner.name, ownerid from case where id = :aCase.Id];
        
        //System.assertEquals( 'ATS_WEB_QUEUE', aCase.owner.name, 'case should be in Web queue');
        
    }
    
    /***** Test class for SOCC Metrics through Task ****/
    static testmethod void soccmetricstask_Test()
    {
        Id usrId = Userinfo.getUserId();
        
        //Insert Account
        Account acc = utilTestClass.CreateAccount('test SOCCMetricAccount');
        insert acc;
        

        
        List<Task> tskList = new List<Task>();
        
        Test.startTest();
        
        //Insert Case
        Id rectypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        Case objCase = new Case();
        objCase.AccountId = acc.id;
        objCase.Subject = 'Test';
        objCase.Description = 'Test';
        objCase.Origin = 'Email';
        objCase.RecordTypeId = rectypeId;
        insert objCase;
        
        //Insert log a call task to Calculate IR metrics
        Task tsk =  utilTestClass.CreateTask(usrId, 'Customer Meeting', 'In Progress', 'Call', objCase.Id);
        tskList.add(tsk);
        
        //Insert log a call task to Calculate FU metrics
        Task tsk2 =  utilTestClass.CreateTask(usrId, 'Customer Meeting', 'In Progress', 'Call', objCase.Id);
        //tskList.add(tsk2); 
        //tskList.add(tsk2); 
        
        //Insert log a call task to Calculate FU metrics
        Task tsk3 =  utilTestClass.CreateTask(usrId, 'Customer Meeting', 'In Progress', 'Initial Analysis-Kona', objCase.Id);
        tskList.add(tsk3); 
        insert tskList;
        Test.stopTest();
        
    }
    //ESESP-2207: Preventative Activities on Paid Accounts
    testMethod static void testPreventativeTasks() {
        Id techAgentProfile, techManagerProfile;
        for( Profile pf :[SELECT Id,Name FROM Profile WHERE Name = 'Support - Tech Support Agent' OR Name = 'Support - Tech Support Manager']){
            if( pf.Name == 'Support - Tech Support Agent')
                techAgentProfile = pf.id;
            else if(pf.Name == 'Support - Tech Support Manager')
                techManagerProfile = pf.Id;  
        }
        
        User techManager = [Select Id,Name from User where  ProfileId =: techManagerProfile and IsActive=true limit 1];
        User techAgent = [Select Id,Name from User where  ProfileId =: techAgentProfile and IsActive=true limit 1];
        
        
        /*  User techManager = new User(LastName = 'LIVESTON1',
FirstName='JASON1',
Alias = 'jliv1',
Email = 'jason1.liveston@akamai.com',
Username = 'jason1.liveston@akamai.com',
ProfileId = techManagerProfile,
TimeZoneSidKey = 'GMT',
LanguageLocaleKey = 'en_US',
EmailEncodingKey = 'UTF-8',
LocaleSidKey = 'en_US'
);
insert techManager;

User techAgent = new User(LastName = 'LIVESTON2',
FirstName='JASON2',
Alias = 'jliv2',
Email = 'jason2.liveston@akamai.com',
Username = 'jason2.liveston@akamai.com',
ProfileId = techAgentProfile,
TimeZoneSidKey = 'GMT',
LanguageLocaleKey = 'en_US',
EmailEncodingKey = 'UTF-8',
LocaleSidKey = 'en_US'
);
insert techAgent; */
        
        
        
        //User techAgent =  [select id, Manager.Id, Manager.Name from user where isActive = true and Manager.isActive = true and Profile.Name = 'Support - Tech Support Agent' and Manager.Profile.Name = 'Support - Tech Support Manager' limit 1];
        //User techManager = techAgent.Manager;
        
        test.startTest();
        Account acc = new Account(name = 'taskTriggerHandlerTestAccount');
        insert acc;
        
        EB_AccountProductMap__c ProdTest = new EB_AccountProductMap__c(); 
        ProdTest.Name = 'Riverbed_Product';
        ProdTest.EB_Account__c = acc.Id;
        ProdTest.EB_Product__c = 'Riverbed_Product';
        insert ProdTest;
        
        // Technical Case
        Case aCase = new Case(); 
        aCase.RecordType = new RecordType(Name = 'Technical');
        aCase.Sub_Type__c = 'Product Support';
        aCase.Origin = 'Web';
        aCase.Do_Not_Show_in_Portal__c = false;
        aCase.AccountId = acc.Id;
        aCase.OwnerId = techAgent.Id;
        aCase.Case_Product__c = ProdTest.Id; 
        aCase.Issue_Summary__c = 'Test';
        aCase.Troubleshooting_to_Date__c = 'Test';
        aCase.Data_Collected__c = 'Test';
        aCase.Customer_Expectations__c = 'Test Expectation';
        aCase.Next_Action_Recommendation__c = 'Test Action';
        
        insert aCase;
        
        Id taskServActRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();        
        
        List<Task> pTasks = new List<Task>();
        // Create Preventative Task
        pTasks.add(new Task( Subject = 'Preventative Task', WhatId = aCase.Id, Type__c = 'Preventative', RecordTypeId = taskServActRT, LOE_hours__c = 10));
        pTasks.add(new Task( Subject = 'Proactive Task', WhatId = aCase.Id, Type__c = 'Proactive', RecordTypeId = taskServActRT, LOE_hours__c = 5));
        insert pTasks;
        
        aCase = [select id, Task_LOE__c, Proactive_LOE__c, Preventative_LOE__c from case where id = :aCase.Id];
        
        System.assertEquals(15, aCase.Task_LOE__c, 'total task loe check');
        System.assertEquals(5, aCase.Proactive_LOE__c, 'preventative task loe check');
        System.assertEquals(10, aCase.Preventative_LOE__c, 'proactive task loe check');
        test.stopTest();
    }
}