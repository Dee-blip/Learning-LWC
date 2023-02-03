/*****************************************************************************
* Name             : Test_AgentHomePageController
* Created By       : Pitamber Sharma
* Created Date     : 21-May-2013
* Purpose          : Test Class for AgentHomePageController
* 22-Apr-14        : avidapan - Optimization of the test class
* 23-Jul-14        : avidapan - Replaced CC_T2_OTHER_QUEUE with CC_ER_WEBEXP_QUEUE 
* 09-Jan-16        : Pinkesh Rathore - CR#3528581 Update CCare queue label prefixes from CC to ATS (Akamai Technical Support)
* 3-July-'18       : Vandhana - ESESP 692 : Add AMG Backup User on Home Screen
*****************************************************************************/

@isTest(seeAllData=false)
private class Test_AgentHomePageController 
{    
    static testMethod void myUnitTest() 
    {
        
        //Create test data
        User cUser = new User(Id = Userinfo.getUserId());
        User usr = [Select id,Name from user where profile.name ='System Administrator' and isActive = true limit 1];//utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
        usr.Backup_User__c = cUser.Id;
        update usr;
        System.runas(cUser) 
        {
            utilTestClass.createCustomSettings();
            utilTestClass.CreateAgentPageCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        }
        
        //Create list of Groups
        List<Group> gLst = new List<Group>();
        Group g1 = new Group(Name='STBE Media Queue', type='Queue');
        gLst.add(g1);
        Group g2 = new Group(Name='AMG EMEA Queue', type='Queue');
        gLst.add(g2);
        Group g3 = new Group(Name='ATS_WEB_QUEUE', type='Queue');
        gLst.add(g3);
        Group g4 = new Group(Name='Billing Queue', type='Queue');
        gLst.add(g4);
        Group g5 = new Group(Name='ATS_ER_MEDIA_QUEUE', type='Queue');
        gLst.add(g5);
        Group g6 = new Group(Name='STBE Media Escalation Queue', type='Queue');
        gLst.add(g6);
        Group g7 = new Group(Name='ATS_ER_WEB_QUEUE', type='Queue');
        gLst.add(g7);
        Group g8 = new Group(Name='AMG Orphan Queue',type='Queue');
        gLst.add(g8);
        Group g9 = new Group(Name='STBE Media Engagement Queue',type='Queue');
        gLst.add(g9);
        System.runas(cUser) 
        {
            insert gLst;
        }
        
        //Create list of queues 
        List<QueuesObject> qLst = new List<QueuesObject>(); 
        QueuesObject q1 = new QueueSObject(QueueID = g1.id, SobjectType = 'Case');
        qLst.add(q1);
        QueuesObject q2 = new QueueSObject(QueueID = g2.id, SobjectType = 'Case');
        qLst.add(q2);
        QueuesObject q3 = new QueueSObject(QueueID = g3.id, SobjectType = 'Case');
        qLst.add(q3);
        QueuesObject q4 = new QueueSObject(QueueID = g4.id, SobjectType = 'Case');
        qLst.add(q4);
        QueuesObject q5 = new QueueSObject(QueueID = g5.id, SobjectType = 'Case');
        qLst.add(q5);
        QueuesObject q6 = new QueueSObject(QueueID = g2.id, SobjectType = 'Case');
        qLst.add(q6);
        QueuesObject q7 = new QueueSObject(QueueID = g5.id, SobjectType = 'Engagement_Request__c');
        qLst.add(q7);
        QueuesObject q8 = new QueueSObject(QueueID = g6.id, SobjectType = 'Engagement_Request__c');
        qLst.add(q8);
        QueuesObject q9 = new QueueSObject(QueueID = g7.id, SobjectType = 'Engagement_Request__c');
        qLst.add(q9);
        QueuesObject q10 = new QueueSObject(QueueID = g8.id, SobjectType = 'Case');
        qLst.add(q10);
        QueuesObject q11 = new QueueSObject(QueueID = g9.id, SobjectType = 'Engagement_Request__c');
        qLst.add(q11);
        System.runas(cUser) 
        {
            insert qLst;
        }
        
        //Adding the user to the groups
        List<GroupMember> gmLst = new List<GroupMember>();
        GroupMember gm1 = new GroupMember(GroupId=g1.id, UserOrGroupId = usr.id); 
        gmLst.add(gm1);
        GroupMember gm2 = new GroupMember(GroupId=g2.id, UserOrGroupId = usr.id); 
        gmLst.add(gm2);
        GroupMember gm3 = new GroupMember(GroupId=g3.id, UserOrGroupId = usr.id); 
        gmLst.add(gm3);
        GroupMember gm4 = new GroupMember(GroupId=g4.id, UserOrGroupId = usr.id); 
        gmLst.add(gm4);
        GroupMember gm5 = new GroupMember(GroupId=g5.id, UserOrGroupId = usr.id); 
        gmLst.add(gm5);
        GroupMember gm6 = new GroupMember(GroupId=g6.id, UserOrGroupId = usr.id); 
        gmLst.add(gm6);
        GroupMember gm7 = new GroupMember(GroupId=g7.id, UserOrGroupId = usr.id); 
        gmLst.add(gm7);
        GroupMember gm8 = new GroupMember(GroupId=g8.id, UserOrGroupId = usr.id); 
        gmLst.add(gm8);
        GroupMember gm9 = new GroupMember(GroupId=g9.id, UserOrGroupId = usr.id); 
        gmLst.add(gm9);
        System.runas(cUser) 
        {
            insert gmLst;
        }
        
        //Create Cases
        List<Case> caseLst = utilTestClass.createCases(3, false, usr.Id, '1');
        caseLst.addAll(utilTestClass.createCases(3, false, usr.Id, '2'));
        caseLst.addAll(utilTestClass.createCases(3, false, usr.Id, '3'));
        caseLst.addAll(utilTestClass.createCases(3, false, g1.Id, '1'));
        caseLst.addAll(utilTestClass.createCases(3, false, g1.Id, '2'));
        caseLst.addAll(utilTestClass.createCases(3, false, g2.Id, '3'));
        caseLst.addAll(utilTestClass.createCases(3, false, g2.Id, '1'));
        caseLst.addAll(utilTestClass.createCases(3, false, g3.Id, '2'));
        caseLst.addAll(utilTestClass.createCases(3, false, g4.Id, '3'));
        caseLst.addAll(utilTestClass.createCases(3, false, g5.Id, '1'));
        caseLst.addAll(utilTestClass.createCases(3, false, g8.Id, '3'));
        
        caseLst.get(15).OwnerId = g2.Id;
        insert caseLst;
        
        // List<Case> clistWithEntitlement = new List<Case>([Select Id, CaseNumber, AKAM_Case_ID__c, Subject, Severity__c, AutoClose__c, Status,Do_Not_Show_In_Portal_Picklist__c, Recent_Update__c, Account.Name, origin, Account.Support_Level__c, MilestoneStatus,AKAM_Created_Date__c,Isclosed,Age_days__c,Do_Not_Show_In_Portal__c,Autogen_UseCase__c,CreatedDate,Total_LOE_min__c,Request_Type__c,OwnerId,ClosedDate, (Select StartDate,IsCompleted,IsViolated,TargetResponseInMins From CaseMilestones) From Case where isClosed = False and EntitlementId != '' Limit 10]);
        //List<Case> clistWithEntitlementVoilated = new List<Case>([Select Id, CaseNumber, AKAM_Case_ID__c, Subject, Severity__c, AutoClose__c, Status,Do_Not_Show_In_Portal_Picklist__c, Recent_Update__c, Account.Name, origin, Account.Support_Level__c, MilestoneStatus,AKAM_Created_Date__c,Isclosed,Age_days__c,Do_Not_Show_In_Portal__c,Autogen_UseCase__c,CreatedDate,Total_LOE_min__c,Request_Type__c,OwnerId,ClosedDate, (Select StartDate,IsCompleted,IsViolated,TargetResponseInMins From CaseMilestones where IsViolated = True) From Case where isClosed = False and EntitlementId != '' Limit 10]);
/*
        String entitlementId;
        if (lstEntitlementProcess.size()>0)
        {
            entitlementId = lstEntitlementProcess[0].id;       
        }
        for(integer i=0;i<2;i++){
            Case c = new Case();
            c.entitlementId = entitlementId;
        }
        update clistWithEntitlement;*/
         
        
        
        
        
        Task newTask = new Task(OwnerId = usr.Id, Subject = 'Other', LOE_hours__c = 5, WhatId = caseLst[0].Id);
        System.runas(cUser) 
        {
            insert newTask;
        }
        
        List<Engagement_Request__c> erLst = new List<Engagement_Request__c>();
        Engagement_Request__c er1 = new Engagement_Request__c();
        er1.Case__c = caseLst[0].Id;
        er1.OwnerId = g5.Id;
        er1.Area__c = 'Media';
        erLst.add(er1);
        Engagement_Request__c er2 = new Engagement_Request__c();
        er2.Case__c = caseLst[3].Id;
        er2.OwnerId = g7.Id;
        er2.Area__c = 'Media';
        erLst.add(er2);
        Engagement_Request__c er3 = new Engagement_Request__c();
        er3.Case__c = caseLst[6].Id;
        er3.OwnerId = g6.Id;
        er3.Area__c = 'Media';
        erLst.add(er3);
        Engagement_Request__c er4 = new Engagement_Request__c();
        er4.Case__c = caseLst[4].Id;
        er4.OwnerId = g8.Id;
        er4.Area__c = 'Media';
        erLst.add(er4);
        insert erLst;
        
        Account acc = new Account();
        acc.Name = 'pAccNameSLA';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        insert acc;
        
        Entitlement entl = new entitlement(name='Test Entilement',accountid = acc.id,type ='Phone Support', StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)));
        insert entl;
        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name FROM SlaProcess WHERE Name='AMG' and IsActive = true LIMIT 1];
        if (lstEntitlementProcess.size()>0)
        {
            entl.SlaProcessId = lstEntitlementProcess[0].id;
            update entl;        
        }
        


        Id rt = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        list<Case> caseSlaList = new List<Case>();
        list<Case> createCaseSlaList = new List<Case>();
        list<Case> caseWithMilestoneComplete = new List<Case>();        
        
        Case c = new Case();
        c.AccountId = acc.Id;
        c.Request_Type__c = 'Customer Onboarding';
        c.Subject = 'New Account : XYZ';
        c.Description = 'Test New Account';
        c.Service__c = 'Account Audit';
        c.RecordTypeID = rt;
        c.do_not_show_in_portal__c = false;
        c.Origin = 'Autogen';
        c.AKAM_Created_Date__c = system.Today()-60;
        createCaseSlaList.add(c);
        
        Case c01 = new Case();
        c01.AccountId = acc.Id;
        c01.Request_Type__c = 'Customer Onboarding';
        c01.Subject = 'New Account : XYZ';
        c01.Description = 'Test New Account';
        c01.Service__c = 'Account Audit';
        c01.RecordTypeID = rt;
        c01.do_not_show_in_portal__c = false;
        c01.Origin = 'Autogen'; 
        
        createCaseSlaList.add(c01);
        
        Case c02 = new Case();
        c02.AccountId = acc.Id;
        c02.Request_Type__c = 'Customer Onboarding';
        c02.Subject = 'New Account : XYZ';
        c02.Description = 'Test New Account';
        c02.Service__c = 'Account Audit';
        c02.RecordTypeID = rt;
        c02.do_not_show_in_portal__c = false;
        c02.Origin = 'Autogen'; 
        createCaseSlaList.add(c02); 
        
        Case ca1 = new Case();
        ca1.AccountId = acc.Id;
        ca1.Request_Type__c = 'Order Form Review';
        ca1.Subject = 'New Alerts';
        ca1.Description = 'Test New Alerts';
        ca1.Service__c = 'Alerts';
        ca1.RecordTypeID = rt;
        ca1.do_not_show_in_portal__c = false;
        ca1.Origin = 'Email';
        ca1.AKAM_Created_Date__c = system.Today()-60; 
        createCaseSlaList.add(ca1);
        
        Case ca2 = new Case();
        ca2.AccountId = acc.Id;
        ca2.Request_Type__c = 'Customer Onboarding';
        ca2.Subject = 'New Account : XYZ';
        ca2.Description = 'Test New Alerts';
        ca2.Service__c = 'Account Audit';
        ca2.RecordTypeID = rt;
        ca2.do_not_show_in_portal__c = false;
        ca2.Origin = 'Autogen'; 
        createCaseSlaList.add(ca2);
        
        Case ca3 = new Case();
        ca3.AccountId = acc.Id;
        ca3.Request_Type__c = 'Add Alerts';
        ca3.Subject = 'New Alerts';
        ca3.Description = 'Test New Alerts';
        ca3.Service__c = 'Alerts';
        ca3.RecordTypeID = rt;
        ca3.do_not_show_in_portal__c = false;
        ca3.Origin = 'Email';
        ca3.AKAM_Created_Date__c = system.Today()-30;
        ca3.AKAM_Closed_Date__c = system.Today();
        ca3.Status = 'Closed';
        ca3.Validation_Override__c = true;
        createCaseSlaList.add(ca3);
        
        Case ca4 = new Case();
        ca4.AccountId = acc.Id;
        ca4.Request_Type__c = 'Add Alerts';
        ca4.Subject = 'New Account : XYZ';
        ca4.Description = 'Alerts';
        ca4.Service__c = 'Alerts';
        ca4.RecordTypeID = rt;
        ca4.do_not_show_in_portal__c = false;
        ca4.Origin = 'Email'; 
        createCaseSlaList.add(ca4);
        
        Case ca5 = new Case();
        ca5.AccountId = acc.Id;
        ca5.Request_Type__c = 'Customer Onboarding';
        ca5.Subject = 'New Account : XYZ';
        ca5.Description = 'Test New Alerts';
        ca5.Service__c = 'Account Audit';
        ca5.RecordTypeID = rt;
        ca5.do_not_show_in_portal__c = false;
        ca5.Origin = 'Autogen';
        ca5.EntitlementId = entl.Id;
        createCaseSlaList.add(ca5);

        insert createCaseSlaList;
        
        createCaseSlaList = new List<Case>();
        //id ent = [Select id from Entitlement where id=:entl.Id limit 1].Id;
        ca5.EntitlementId =entl.Id;
        ca5.Validation_Override__c = true;
        createCaseSlaList.add(ca5);
        
        c01.EntitlementId =entl.Id;
        c01.Validation_Override__c = true;
        createCaseSlaList.add(c01);
        
        ca3.AKAM_Created_Date__c = system.Today()-31;
        ca3.Validation_Override__c = true;
        createCaseSlaList.add(ca3);
        Test.startTest();

        update createCaseSlaList;
        
        Engagement_Request__c er5 = new Engagement_Request__c();
        er5.Case__c = ca3.Id;
        er5.OwnerId = usr.Id;
        er5.Area__c = 'Media';
        insert er5;
        
        List<Task> tlist =  new List<Task>();         
        Task t = new task();
        t.Subject = 'User Setup';
        t.status = 'In Progress';
        t.WhatId = c.Id;
        t.Type = 'Task';
        t.ActivityDate = System.Today()+5;
        //t.Completed_Date_Time__c = System.Today()-1;
        tlist.add(t);
        
        Task t1 = new task();
        t1.Subject = 'User Setup';
        t1.status = 'Completed';
        t1.WhatId = c01.Id;
        t1.Type = 'Task';
        t1.ActivityDate = System.Today()-1;
        t1.Completed_Date_Time__c = System.Today();
        tlist.add(t1);
        
        Task t2 = new task();
        t2.Subject = 'User Setup';
        t2.status = 'Completed';
        t2.WhatId = c02.Id;
        t2.Type = 'Task';
        t2.ActivityDate = System.Today()-1;
        t2.Completed_Date_Time__c = System.Today();
        tlist.add(t2);
        
        Task t3 = new task();
        t3.Subject = 'User Setup';
        t3.status = 'Completed';
        t3.WhatId = ca2.Id;
        t3.Type = 'Task';
        t3.ActivityDate = System.Today();
        t3.Completed_Date_Time__c = System.Today()+2;
        tlist.add(t3);
        
        Task t4 = new task();
        t4.Subject = 'User Setup';
        t4.status = 'Completed';
        t4.WhatId = ca4.Id;
        t4.Type = 'Task';
        t4.ActivityDate = System.Today();
        t4.Completed_Date_Time__c = System.Today()-1;
        tlist.add(t4);
        
        insert tlist;
        
        caseSlaList.add(c);
        caseSlaList.add(ca1);
        caseSlaList.add(c01);
        caseSlaList.add(c02);
        caseSlaList.add(ca2);
        caseSlaList.add(ca3);
        caseSlaList.add(ca4);
        caseSlaList.add(ca5);
        
        caseWithMilestoneComplete.add(ca1);
        caseWithMilestoneComplete.add(c01);
        caseWithMilestoneComplete.add(c02);
        caseWithMilestoneComplete.add(ca2);
        caseWithMilestoneComplete.add(ca3);
        caseWithMilestoneComplete.add(ca4);
        caseWithMilestoneComplete.add(ca5);
        List<CaseMilestone> cmsToUpdate = [select Id,caseId, completionDate
                                           from CaseMilestone cm
                                           where caseId IN : caseWithMilestoneComplete and completionDate = null];
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                if(cm.CaseId != c02.Id && cm.CaseId != ca2.Id)
                    cm.completionDate = System.now();
            }
            update cmsToUpdate;
        }
        list<Case> clistForSLA = new List<Case>([Select Id, CaseNumber, AKAM_Case_ID__c, Subject, Severity__c, AutoClose__c, Status,Do_Not_Show_In_Portal_Picklist__c, Recent_Update__c, Account.Name, origin, Account.Support_Level__c, AKAM_Created_Date__c,Isclosed, Age_days__c,Do_Not_Show_In_Portal__c,Autogen_UseCase__c,CreatedDate,Total_LOE_min__c,Request_Type__c,OwnerId,ClosedDate,RecordType.Name, (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins, TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays From CaseMilestones order by createddate asc) From Case where Id IN :caseWithMilestoneComplete]);
        
        //Display Cases,Activities,Incidents in the sections of Home Page
        
        System.runAs(usr) 
        {
            AgentHomePageController controller = new AgentHomePageController();
            controller.updateBackupUser();
            //if(clistWithEntitlement.size()>0)
            // controller.SLAAlertButtonColor(clistWithEntitlement);
            //if(clistForSLA.size()>0)
            controller.isTestRunning = true;
            //controller.populateLists();
            controller.SLAAlertButtonColor(clistForSLA);
            controller.SLAAlertButtonColor(caseSlaList);
            controller.listToStringIds(caseSlaList);
            controller.caseFilter = 'My Resolved Cases';
            controller.populateCases();
            controller.caseFilter = 'Closed Cases';
            controller.populateCases();
            controller.caseFilter = 'Resolved Cases';
            controller.populateCases();
            controller.caseFilter = 'All My Cases';
            controller.populateCases();
            controller.caseFilter = 'My Owned Cases';
            controller.populateCases();
            controller.caseFilter = 'My Team Cases';
            controller.populateCases();
            controller.caseFilter = 'My Closed Cases';
            controller.populateCases();
            controller.caseFilter = 'Order Form Review';
            controller.populateCases();
            controller.caseFilter = 'My Managers Cases';
            controller.populateCases();
            
            controller.taskFilter = 'Overdue Tasks';
            controller.populateTasks();
            controller.taskFilter = 'My Tasks Due Today';
            controller.populateTasks();
            controller.taskFilter = 'My Activities';
            controller.populateTasks();
            controller.taskFilter = 'My Team\'s Open Activities';
            controller.populateTasks();
            
            controller.incidentFilter = 'All Open Incidents';
            controller.populateIncidents();
            
            controller.toggleUserAvailability();
            //controller.testCoverageMethodCaseMilestone();
        }
        Test.stopTest();
        Map<String, List<String>> queuesMap = new Map<String, List<String>>();
        Map<String, List<Engagement_Request__c>> queueERMap = new Map<String, List<Engagement_Request__c>>();
        queuesMap.put('ATS_ER_MEDIA_QUEUE', new String[]{'0', '0', '0', '', 'ER'});
        queuesMap.put('STBE Media Engagement Queue', new String[]{'0', '0', '0', '', 'ER'});
        queuesMap.put('ATS_ER_WEB_QUEUE', new String[]{'0', '0', '0', '', 'ER'});
        List<Engagement_Request__c> erList = [select Id, Createddate from Engagement_Request__c order by createddate desc limit 200];
        queueERMap.put('ATS_ER_MEDIA_QUEUE', erList);
        queueERMap.put('STBE Media Engagement Queue', erList);
        queueERMap.put('ATS_ER_WEB_QUEUE', erList);
        QueueColorUtility.assignColorToERQueue(queuesMap,queueERMap);
    }
}