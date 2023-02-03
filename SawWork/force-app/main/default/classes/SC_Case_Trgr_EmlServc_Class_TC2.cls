/*=====================================================================================================+
    Class name          :   SC_Case_Trgr_EmlServc_Class_TC2 
    Author              :   Pinkesh Rathore
    Created             :   07-Nov-17
    Purpose             :   This test class is used to cover code for below Components
                            1. HomePageV2
    
	Last Modified    Developer  Purpose            
    =============    =========  =======
	27-04-2018      Sumanth      ESESP 445
	30-Sep-2020		Tejaswini    ESESP-4020 : Set seeAllData = false , added testSetup method
	
+=====================================================================================================*/

@isTest
public class SC_Case_Trgr_EmlServc_Class_TC2 {
    
    @testSetup static void setup() {
        utilTestClass.createCustomSettings(); 
        utilTestClass.createData_SC_SupportEmail();
        
        List<Case> lstCase = new List <Case>();
        Case casenew1 = new Case();
        casenew1.Subject = 'Test Case Notification';
        casenew1.Recent_Update__c = True;
        casenew1.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew1.Origin = 'Email';
        casenew1.Case_Assignment_Using_Active_Rules__c = true;
        
        lstCase.add(casenew1);
        
        Case casenew2 = new Case();
        casenew2.Subject = 'New Case 1';
        casenew2.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew2.Sub_Type__c = 'Product Support';
        casenew2.Validation_Override__c = true;
        casenew2.Origin = 'Email';
        casenew2.Case_Assignment_Using_Active_Rules__c = true;
        
        lstCase.add(casenew2);
        
        Case casenew3 = new Case();
        casenew3.Subject = 'Test Case Notification1';
        casenew3.Recent_Update__c = True;
        casenew3.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew3.Origin = 'Email';
        casenew3.Sub_Type__c = 'Product Support';
        casenew3.Case_Assignment_Using_Active_Rules__c = true;
        casenew3.Validation_Override__c = true;
        lstCase.add(casenew3);
        insert lstCase;
        
        Engagement_Request__c request = new Engagement_Request__c(Case__c = casenew2.Id, OwnerId = UserInfo.getUserId(),Request_Status__c = 'Open');
        insert request;
        
        
        
        
        
        String timecardLimitCustomSetting = PSA_Settings__c.getInstance('Work Item Limit').Value__c;
            
       	
    }
    
    //Create Test Data variables 
    static Account accRec;
    static Merge_Contract_Header__c  merge_contract;
    static EB_AccountProductMap__c  eb_product;
    static Case csRec;
    static Contact conRec;
    static ApexPages.StandardController AccountCon;
    static GSSActiveContractsCon ActiveCon;
    static GSSInactiveContractsCon InactiveCon;
  
  //Creates the test data 
    static void createTestData() {
        User currentusr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.RunAs(currentusr)
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            update environmentSetup;
        }
        
        // For Account Record
        accRec = new Account(Name='Test Account1 zpxtx',AKAM_Account_ID__c='Test-111');
        insert accRec;
        
        // For Contract Record
        merge_contract = new Merge_Contract_Header__c(Name='Test Merge Contract',Contract_Id__c='Test-123',
                                                      Original_Contract_Id__c = 'Test-123',Account_Name__c = accRec.Id);
        
        
        // For Case Product
        eb_product = new EB_AccountProductMap__c(Name='Test Product',EB_MarkedForDeletion__c = false,EB_Product__c='Test-456',
                                                 EB_Account__c=accRec.id);
        
        Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
        User usr = [select Id from User where IsActive = True and ProfileId = :pfl.Id limit 1];
        
        // For Case Record
        RecordType rectype= [select id from RecordType where sObjectType='Case' and Name='Technical' and isActive=true limit 1];    // For Case Record
        csRec = new Case(subject='Test', description='test',Ownerid = usr.Id,AKAM_Case_ID__c='ehsdsg',
                         RecordTypeId=rectype.Id,Do_not_show_in_portal__c = true,Origin = 'Email');
        
        insert merge_contract;
        insert eb_product;
        Insert csRec;
        
        // Creating Contact Record
        conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz@akamai.com',
                             No_Longer_with_Company__c = false, LastName = 'Test Contact');
        Insert conRec;
        
        // create a new Account standard controller by passing the account record
        AccountCon = new ApexPages.StandardController(accRec);
        
    }
    
    //Method# 1-a For SC_HomePageCtrlV2 
    @isTest public static void testHomePage(){
        //new Case object
        /*list<Case> lstCase = new list <Case>();
	Case casenew1 = new Case();
	casenew1.Subject = 'Test Case Notification';
	casenew1.Recent_Update__c = True;
	casenew1.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
	casenew1.Origin = 'Email';
	casenew1.Case_Assignment_Using_Active_Rules__c = true;
	lstCase.add(casenew1);

	Case casenew2 = new Case();
	casenew2.Subject = 'New Case 1';
	casenew2.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
	casenew2.Sub_Type__c = 'Product Support';
	casenew2.Validation_Override__c = true;
	casenew2.Origin = 'Email';
	casenew2.Case_Assignment_Using_Active_Rules__c = true;
	lstCase.add(casenew2);
	insert lstCase;

	Engagement_Request__c request = new Engagement_Request__c(Case__c = casenew2.Id, OwnerId = UserInfo.getUserId());
	insert request;*/
        
        Case casenew2 = [Select Id,Resolved_Date__c from Case where Subject = 'New Case 1' limit 1];
        Task newtask = new Task();
        newtask.Subject         =   'Random54321';
        newtask.Description     =   'Test1';
        newtask.ActivityDate    =   System.today() + 2;                             
        newtask.DueDateProlexic__c    =   System.now().addDays(2);                             
        newtask.Type__c         =   'Email';
        newtask.Status          =   'Not Started';
        newtask.WhatId          =   casenew2.Id;
        newtask.OwnerId         =   UserInfo.getUserId();
        newtask.LOE_hours__c    =   0;
        insert newtask; 
        
        //Case casenew1 = [Select Resolved_Date__c from Case where Subject = 'New Case 1' limit 1];
        //newtask = [Select LOE_hours__c from Task where Subject = 'Random54321' limit 1];
        
        /*List<Group> queueId = [Select Id from Group where Name = 'ATS_AMP_QUEUE' limit 1];
        
        List<Case> lUpdateCase = new List<Case>();
        for(Case eachCase :[Select Id,OwnerId,Owner.Name from Case Limit 3] )
        {
            System.debug('The case owner  is '+eachCase.Owner.Name);
            eachCase.OwnerId = queueId[0].Id;
            lUpdateCase.add(eachCase);
        }
        update lUpdateCase;
        
        Engagement_Request__c engReq = [Select Id,OwnerId from Engagement_Request__c Limit 1];
        engReq.OwnerId = queueId[0].Id;
        update engReq;*/
        
        List<Case> lcs = [Select Id from case where isClosed=False and RecordType.Name != 'Invalid Case' and origin != null limit 1];
        //List<Case> lcs = [Select Id from case where isClosed=False and Owner.Name like 'ATS%' and RecordType.Name != 'Invalid Case' and origin != null limit 1];
        System.debug('----------The list of cases are '+lcs);
        List<Engagement_Request__c> ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') limit 1];
        //List<Engagement_Request__c> ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') and Owner.Name like 'ATS%' limit 1];
        System.debug('----------The list of Engagement request are '+ler);
        test.startTest();
        SC_HomePageCtrlV2 c = new SC_HomePageCtrlV2();
        c.getenableLOEPolling();
        c.getenableSIPolling();
        
        if(lcs.size()>0)
        {
            c.passRecId = lcs[0].Id;
            c.pickCaseER();
        }
        
        
        if(ler.size()>0)
        {
            c.passRecId = ler[0].Id;
            c.pickCaseER();
        }
        c.hiddenCaseId = casenew2.Id;
        c.EMEACheckBox = true;
        c.APJCheckBox = true;
        c.NORTHAMCheckBox = true;
        c.updateUserPreference();
        c.SIFilter = 'All Open';
        //c.MyFilter = 'Hide Pending';
        c.MyFilter = 'My Work';
        c.QFilter = 'All CCare Queues - Cases';
        c.DashboardFilter = 'Quarter';
        c.updateDashboard();
        c.updateLOE();
        c.populateQTable();
        c.populateMyTable();
        c.populateSITable();
        c.SIFilter = '7 Days';
        c.MyFilter = 'Followed';
        c.QFilter = 'All CCare Queues - ERs';
        c.QFilter = 'ATS_Transition_Queue';
        c.DashboardFilter = 'Year';
        
        casenew2.Status = 'Closed';
        casenew2.Resolved_Date__c = System.today().addDays(1);
        casenew2.Validation_Override__c = true;
        //update casenew2;
        
        c.updateDashboard();
        //c.updateLOE();
        //c.populateQTable();
        c.populateMyTable();
        c.populateSITable();
        c.suppressCaseUpdate_homectrl();
        test.stopTest();
    }
    
    //Method #1-b For SC_Home PAge
    @isTest public static void testHomePage2()
    {
        
        List<Case> lcs = [Select Id from case where isClosed=False and RecordType.Name != 'Invalid Case'  and origin != null limit 1];
       	//List<Case> lcs = [Select Id from case where isClosed=False and Owner.Name like 'CC%' and RecordType.Name != 'Invalid Case'  and origin != null limit 1];
        System.debug('----------The list of cases are '+lcs);
        List<Engagement_Request__c> ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') limit 1];
        //List<Engagement_Request__c> ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') and Owner.Name like 'CC%' limit 1];
        System.debug('----------The list of ER are '+ler);
        /*Case casenew = new Case();
        casenew.Subject = 'Test Case Notification';
        casenew.Recent_Update__c = True;
        casenew.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew.Origin = 'Email';
        casenew.Sub_Type__c = 'Product Support';
        casenew.Case_Assignment_Using_Active_Rules__c = true;
        casenew.Validation_Override__c = true;
        insert casenew;*/
        Case casenew = [Select Id from Case where Subject = 'Test Case Notification1' limit 1];
        Task newtask = new Task();
        newtask.Subject         =   'Test';
        newtask.Description     =   'Test';
        newtask.ActivityDate    =   System.today() + 2;  
        newtask.DueDateProlexic__c    =   System.now().addDays(2); 
        newtask.Type__c         =   'Email';
        newtask.Status          =   'Not Started';
        newtask.WhatId          =   casenew.Id;
        newtask.OwnerId         =   UserInfo.getUserId();
        newtask.LOE_hours__c    =   4;
        
        
        //Task t = [Select LOE_hours__c from Task where Subject = 'Test' limit 1];
        //Case casenew = [Select Id from Case where Subject = 'Test Case Notification1' limit 1];
        
        SC_HomePageCtrlV2 c = new SC_HomePageCtrlV2();
        test.startTest();
        
        //casenew.Resolved_Date__c = System.today().addDays(1);
        //casenew.Status = 'Closed';
        //update casenew;
        Insert newtask; 
        if(lcs.size()>0)
        {
            c.passRecId = lcs[0].Id;
            c.pickCaseER();
        }
        if(ler.size()>0)
        {
            c.passRecId = ler[0].Id;
            c.pickCaseER();
        }
        c.SIFilter = 'Unmitigated';
        //c.MyFilter = 'Followed';
        c.MyFilter = 'Hide Pending';
        c.QFilter = 'My Queues';
        c.DashboardFilter = 'This Month';
        c.updateDashboard();
        /*c.updateLOE();
        newtask.LOE_hours__c = 5;update newtask;
        c.updateLOE();*/
        c.suppressCaseUpdate_homectrl();
        c.populateQTable();
        c.populateMyTable();
        //c.populateSITable();
        test.stopTest();
    }

    @isTest public static void testHomePage3()
    {
        List<Case> lcs = [Select Id from case where isClosed=False and RecordType.Name != 'Invalid Case'  and origin != null limit 1];
       	//List<Case> lcs = [Select Id from case where isClosed=False and Owner.Name like 'CC%' and RecordType.Name != 'Invalid Case'  and origin != null limit 1];
        System.debug('----------The list of cases are '+lcs);
        List<Engagement_Request__c> ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') limit 1];
        //List<Engagement_Request__c> ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') and Owner.Name like 'CC%' limit 1];
        System.debug('----------The list of ER are '+ler);
        /*Case casenew = new Case();
        casenew.Subject = 'Test Case Notification';
        casenew.Recent_Update__c = True;
        casenew.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew.Origin = 'Email';
        casenew.Sub_Type__c = 'Product Support';
        casenew.Case_Assignment_Using_Active_Rules__c = true;
        casenew.Validation_Override__c = true;
        insert casenew;*/
        Case casenew = [Select Id from Case where Subject = 'Test Case Notification1' limit 1];
        Task newtask = new Task();
        newtask.Subject         =   'Test';
        newtask.Description     =   'Test';
        newtask.ActivityDate    =   System.today() + 2;  
        newtask.DueDateProlexic__c    =   System.now().addDays(2); 
        newtask.Type__c         =   'Email';
        newtask.Status          =   'Not Started';
        newtask.WhatId          =   casenew.Id;
        newtask.OwnerId         =   UserInfo.getUserId();
        newtask.LOE_hours__c    =   4;
        
        
        //Task t = [Select LOE_hours__c from Task where Subject = 'Test' limit 1];
        //Case casenew = [Select Id from Case where Subject = 'Test Case Notification1' limit 1];
        
        SC_HomePageCtrlV2 c = new SC_HomePageCtrlV2();
        test.startTest();
        
        //casenew.Resolved_Date__c = System.today().addDays(1);
        //casenew.Status = 'Closed';
        //update casenew;
        Insert newtask; 
        
        c.SIFilter = 'Unmitigated';
        //c.MyFilter = 'Followed';
        c.MyFilter = 'Hide Pending';
        c.QFilter = 'My Queues';
        c.DashboardFilter = 'This Month';
        
        c.updateLOE();
        newtask.LOE_hours__c = 5;update newtask;
        c.updateLOE();
        c.populateSITable();
        test.stopTest();
    }
    
    
    //Method# 2 For SC_HomePageuBulletin
    @isTest public static void testHomePageBulletin(){
        test.startTest();
        
        User u = [Select Id from User where Profile.Name = 'Support - Tech Support Agent' and isActive=true limit 1];
        if(u!=null)
        {
            System.runAs(u)
            { 
                SC_HomePageBulletinCtrl c = new SC_HomePageBulletinCtrl();
            }
        }
        test.stopTest();
        
    }
    
    //Method# 3 For SC_HomePageCaseNotifications 
    @isTest public static void testSC_HomePageCaseNotifications(){
        test.startTest();
        User u = [Select Id from User where Profile.Name = 'Support - Tech Support Agent' and isActive=true limit 1];
        if(u!=null)
        {
            System.runAs(u)
            {
                SC_HomePageCaseNotificationsCtrl c = new SC_HomePageCaseNotificationsCtrl();
                c.suppressCaseUpdate();
                //Increase Code Coverage
                c.updatelCaseUpdates();
            }
        }
        test.stopTest();
    }
    
    //Method #4 For SC_Monacle_CaseIssue
    @isTest public static void Test_CarrierProducts(){
        Test.startTest();
        id carrierProductsRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        Case cs = new Case(subject='Test', description='test',RecordTypeId = carrierProductsRTId,Sub_Type__c = 'Carrier',Origin = 'Email',status ='Assigned',OwnerId = userInfo.getuserid());
        insert cs;
        cs.status = 'Awaiting Customer Response';
        CaseTriggerClass.isOneTimeRun = True;
        Update cs;
        cs.Status = 'Work In Progress';
        CaseTriggerClass.isOneTimeRun = True;
        Update cs;
        test.stopTest();
    }
    
    //Method #5 For SC_Monacle_CaseIssue
    @isTest public static void Test_AccuracyCheck(){
        Test.startTest();
        id technicalRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        Case cs = new Case(subject='Test', description='test',RecordTypeId = technicalRTId,Sub_Type__c = 'Carrier',Origin = 'Web',status ='Assigned',OwnerId = userInfo.getuserid());
        insert cs;
        
        Id PSRTId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByDeveloperName().get('Troubleshooting_Procedure').getRecordTypeId();
        Knowledge__kav  procedureKAV = new Knowledge__kav (Summary = 'Test Procedure 198',Title = 'Test Procedure 198',UrlName='TestProcedureOneNineEight',language= 'en_US', Recordtypeid = PSRTId);
        insert procedureKAV;
        KnowledgeArticleVersion kb = [SELECT Id, KnowledgeArticleId from KnowledgeArticleVersion where Language ='en_US' and Id =:procedureKAV.Id Limit 1];
        KbManagement.PublishingService.publishArticle(kb.KnowledgeArticleId, true);
        
        caseArticle ca = new CaseArticle();
        ca.CaseID = cs.Id;
        ca.KnowledgeArticleId = kb.KnowledgeArticleId;
        insert ca;
        SC_CaseTriggerHelperClass.flagvalue = False;
        cs.Subject = 'Test 123';
        Update cs;
        test.stopTest();
        
    }
    
    @isTest public static void testHome3()
    {
       /* list<Case> lstCase = new list <Case>();
        Case casenew1 = new Case();
        casenew1.Subject = 'Test Case Notification';
        casenew1.Recent_Update__c = True;
        casenew1.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew1.Origin = 'Email';
        casenew1.Case_Assignment_Using_Active_Rules__c = true;
        lstCase.add(casenew1);
        
        Case casenew2 = new Case();
        casenew2.Subject = 'New Case 1';
        casenew2.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew2.Sub_Type__c = 'Product Support';
        casenew2.Validation_Override__c = true;
        casenew2.Origin = 'Email';
        casenew2.Case_Assignment_Using_Active_Rules__c = true;
        lstCase.add(casenew2);
        insert lstCase;
        
        Engagement_Request__c request = new Engagement_Request__c(Case__c = casenew2.Id, OwnerId = UserInfo.getUserId());
        insert request;*/
        
        Case casenew2 = [Select Id from Case where Subject = 'New Case 1' Limit 1];
        Engagement_Request__c request = [Select Id from Engagement_Request__c Limit 1];
        Engagement_Request__c er =[Select Id,Name,Accept_Target_Mins__c,Accept_Completed__c,Accept_Violation__c,Accept_Target_Date__c, ER_Severity__c,Case__c,Case__r.AKAM_Case_ID__c,Case__r.AccountId,Case__r.Account.Name,Case__r.CaseNumber, Description__c, Case__r.Support_Level__c,AKAM_Created_Date__c,Case__r.Case_Prod_Name__c,Case__r.Resolution_Sent__c,OwnerId,Owner.Name,Request_Status__c,Case__r.Task_LOE__c,Age__c,Case__r.has_active_transition__c from Engagement_Request__c where id =:request.id];
        
        Task newtask = new Task();
        newtask.Subject         =   'Random54321';
        newtask.Description     =   'Test1';
        newtask.ActivityDate    =   System.today();                             
        newtask.Type__c         =   'Email';
        newtask.Status          =   'Not Started';
        newtask.WhatId          =   casenew2.Id;
        
        newtask.OwnerId         =   UserInfo.getUserId();
        //newtask.LOE_hours__c    =   0;
        newtask.LOE_hours__c    =   6;
        insert newtask; 
        
        Case casenew1 = [Select Id,CaseNumber,Override_Next_Case_Update__c ,AKAM_Case_ID__c,AccountId,Account.Name,Subject, Support_Level__c, Severity__c, AKAM_Created_Date__c, Case_Prod_Name__c,OwnerId,Owner.Name,Age_days__c,Status,Resolution_Sent__c,Recent_Update__c,Task_LOE__c,Support_Geography__c,has_active_transition__c, (Select Id,TargetResponseInMins,StartDate,isviolated,IsCompleted from CaseMilestones where milestonetype.Name IN ('Initial Response','First Update', 'Case Update','Time to Respond')) from Case where Subject = 'New Case 1' limit 1];
        //newtask = [Select LOE_hours__c from Task where Subject = 'Random54321' limit 1];
        
        
        List<Case> lcs = new List<Case>();
        lcs = [Select Id from case where isClosed=False and Owner.Name like 'ATS%' and RecordType.Name != 'Invalid Case' and origin != null limit 1];
        List<Engagement_Request__c> ler = new List<Engagement_Request__c>();
        ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') and Owner.Name like 'ATS%' limit 1];
        
        //Dummy Maps to increase code coverage
        Map<Id,CaseMilestone> Idmilestone = new Map<Id,CaseMilestone>();
        Map<Id,case_transition__c> Idtransition = new Map<Id,case_transition__c>();
        Map<Id,String> Idstring = new Map<Id,String>();
        Map<Id,CaseMilestone> Idmilestone1 = new Map<Id,CaseMilestone>();
        Map<Id,CaseMilestone> Idmilestone2 = new Map<Id,CaseMilestone>();
        
        test.startTest();
        
        //SC_HomePageCtrlV2 c = new SC_HomePageCtrlV2();
        SC_HomePageCtrlV2 c;
        c = new SC_HomePageCtrlV2();
        c.QFilter = 'All CCare Queues - Cases';
        c.populateQTable();
        c.isKCSLevelRed();
        SC_HomePageCtrlV2.CaseERWrapperClass CWER = new SC_HomePageCtrlV2.CaseERWrapperClass(casenew1,Idmilestone,Idtransition,Idstring,'queue',Idmilestone1,Idmilestone2);
        SC_HomePageCtrlV2.CaseERWrapperClass CWER2 = new SC_HomePageCtrlV2.CaseERWrapperClass(er,Idmilestone,Idtransition,Idstring,'queue');
        CWER.minsToDay(100);
        CWER.minsToHrs(100);
        //Increase code coverage
        c.updateLOE();
        newtask.LOE_hours__c = 2;
        update newtask;
        c.updateLOE();
        test.stopTest();
        
    }
    
    @isTest public static void testHome4()
    {
        test.startTest();
        SC_HomePageCtrlV2 c = new SC_HomePageCtrlV2();
        c.QFilter = 'ATS_Transition_Queue';
        c.populateQTable();
        test.stopTest();
    }
    
    
    @isTest public static void testSC_UserTriggerClass(){
        Test.startTest();
        List<User> lUser = new List<User>();
        User newUser = new User(
            Username='testSC987@akamai.com',
            Alias = 'testSC',
            Email='testSC987@akamai.com',
            FirstName='Test',
            LastName='SC',
            ProfileId = Userinfo.getProfileId(),
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            Department = 'AkaTec',
            TimeZoneSidKey='America/Los_Angeles',
            isActive = true
        );
        lUser.add(newUser);
        User newUser2 = new User(
            Username='testSC9876@akamai.com',
            Alias = 'testSC2',
            Email='testSC9876@akamai.com',
            FirstName='Test2',
            LastName='SC2',
            ProfileId = Userinfo.getProfileId(),
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US',
            EmailEncodingKey='UTF-8',
            Department = 'AkaTec',
            TimeZoneSidKey='America/Los_Angeles',
            isActive = true
        );
        lUser.add(newUser2);
        insert lUser;
        newUser.Department = 'AkaTec EMEA';
        newUser2.SC_KCS_Coach__c = newUser.Id;
        update lUser;
        newUser.isActive = false;
        update newUser;
        
        Test.stopTest();
    }
    
    //Test Class for SC_AccountTeamUpdate_Scheduler
    @isTest public static void test_SC_AccountTeamUpdate_Scheduler(){
        Test.startTest();
        createTestData();
        User PSResCountry = [SELECT Id FROM User WHERE Profile.name = 'GSS Professional Services - Restricted Country' and Isactive = True LIMIT 1];
        AccountTeamMember newATM = new AccountTeamMember();
        newATM.AccountId = accRec.Id;
//        newATM.UserId = PSResCountry.Id;
        newATM.UserId = UserInfo.getUserId();
        newATM.CaseAccessLevel = 'None';
        newATM.TeamMemberRole = 'Partner';
        Insert newATM;
        SC_AccountTeamUpdate_Scheduler testATMUpdate = new SC_AccountTeamUpdate_Scheduler();
        String jobId = System.schedule('testATMUpdate', '0 0 0 3 9 ? 2022', testATMUpdate);
        SC_Utility.sendExceptionEmail('Error in AccountTeamMember Update', 'Error Message');
        Test.stopTest();
        
        
    }
    
    //Test Class for UpdateCaseShare
    @isTest public static void test_UpdateCaseShare(){
        Test.startTest();
        Case casenew2 = new Case();
        casenew2.Subject = 'New Case 1';
        Casenew2.OwnerID = [SELECT Id FROM User WHERE Profile.name = 'GSS Professional Services' and Isactive = True LIMIT 1].ID;
        casenew2.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Invoice Review Case').getRecordTypeId();
        casenew2.Validation_Override__c = true;
        casenew2.Origin = 'Email';
        casenew2.Case_Assignment_Using_Active_Rules__c = true;
        Casenew2.IR_Escal_Owner__c = Userinfo.getUserId();
        Insert casenew2;
        
        List<Case> CaseList = new  List<Case>();
        CaseList.add(casenew2);
        
        Map<Id, Case> caseMap = new Map<Id, Case>();
        caseMap.put(casenew2.Id, casenew2);
        CaseTriggerClass.irCaseEscalOwnerFirstRunFlag = True;
        CaseTriggerClass.updateCaseShare(False, True, CaseList, caseMap);
        Test.stopTest();
    }
    
   
    
    
}