@isTest(seeAllData=false)
public class SC_RCA_AllUseCase_TC {
	@testSetup
    static void createData(){
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('Test Account1');
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        accList.add(acc);

        acc = utilTestClass.CreateAccount('Test Account2');
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        accList.add(acc);
        insert accList;

        Contact con = utilTestClass.CreateContact('__Test1FirstName','__Test1LastName');
        con.AKAM_Contact_ID__c = 'ABC123';
        con.AccountId = acc.Id;
        con.email='abc@123.com';
        insert con;
		
        List<Case> lstCase = new List<Case>();


        Case cp = new Case();
        cp.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        cp.AccountId= acc.id;
        cp.Subject= 'Test AMG autogen';
        cp.Description ='Test AMG autogen';
        cp.Origin='Autogen';
        cp.Status = 'Assigned';
        cp.Autogen_UseCase__c = 'ECOB';
        cp.Validation_Override__c = true;
        cp.AKAM_System__c = 'MYAKAMAI';
        SC_CaseTriggerHelperClass.flags = false;
        SC_CaseTriggerHelperClass.sentEmailFlag = true;
        cp.Case_Assignment_Using_Active_Rules__c = True;
        lstCase.add(cp);
        
        
      	

        insert lstCase;
        Id iraptUsrId;
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
            iraptUsrId = creatIraptUser();
        }
        SlaProcess sla = [Select id from slaprocess Where Name='rca process' and IsVersionDefault =true];
        Entitlement ent = new Entitlement(Name='RCA', AccountId=acc.Id, 
                                           StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)));
        ent.SlaProcessId = sla.id;
        insert ent;
        //Id entId = [Select id FROM Entitlement where Name = 'RCA'].Id;
		insert new EntitlementID__c (Name='RCA', Case_Record_Type__c = 'RCA Request', EntitlementID__c  =ent.Id);
        System.runAs ( new User(Id = iraptUsrId) ) {
            Case rca = new Case();
            rca.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Request').getRecordTypeId();
            rca.Description ='Test AMG autogen';
            rca.RCA_Owner__c=iraptUsrId;
            rca.Next_Action_Owner__c = 'IRAPT';
            rca.Status = 'Unssigned';
            rca.Resolution_Summary__c = 'tes';
            rca.ParentId = cp.id;
            insert rca;
        }
    }

    public static Id creatIraptUser(){
        Profile pr = [select id from profile where name='Sales - Media'][0];
        User usr = new User(alias = 'user', email='test1test@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        usr.SC_SI_IRAPT_User__c = true;
        insert usr;
        PermissionSet ps = [Select Id FROM PermissionSet Where Name ='SC_SI_Service_Incidents_IRAPT_User'];
        PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = ps.Id, AssigneeId = usr.Id);
        insert psa;
        return usr.Id;
    }
    public static Id creatIraptAdminUser(){
        Profile pr = [select id from profile where name='Sales - Media'][0];
        User usr = new User(alias = 'user1', email='admin@akamai.com',emailencodingkey='UTF-8', lastname='adminUser', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__123usr2505@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC124';
        usr.SC_SI_IRAPT_User__c = true;
        insert usr;
        PermissionSet ps = [Select Id FROM PermissionSet Where Name ='SC_SI_Service_Incidents_IRAPT_User'];
        PermissionSetAssignment psa = new PermissionSetAssignment (PermissionSetId = ps.Id, AssigneeId = usr.Id);
        PermissionSet ps1 = [Select Id FROM PermissionSet Where Name ='SC_SI_Service_Incidents_IRAPT_Admin_User'];
        PermissionSetAssignment psa1 = new PermissionSetAssignment (PermissionSetId = ps1.Id, AssigneeId = usr.Id);
        insert new List<PermissionSetAssignment>{psa,psa1};
        return usr.Id;
    }

    @IsTest
    static void testqualityCoachingFromAdminUsr(){
        Test.startTest();
        Task ts;
        Case rca = [Select Id FROM Case Where RecordType.Name =  'RCA Request' LIMIT 1];
        Id userId = creatIraptAdminUser();
        System.runAs(new User(id = userId)){
            SC_QualityCoaching_RCA_Handler.QualityCoachingWrapper wrap = SC_QualityCoaching_RCA_Handler.getRecords(rca.Id, 'RCA','RCA');
            System.assertEquals(true, wrap != null);
            SC_QualityCoaching_RCA_Handler.updateQualityCoachingDetails (JSON.serialize(wrap.tableData), 'test', ''+rca.Id, 'RCA', 'RCA', 22, 4);
            Id rcaActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Activity').getRecordTypeId();
            ts = new Task();
            ts.whatId = rca.Id;
            ts.Start_Date_Time__c = DateTime.Now();
            ts.Completed_Date_Time__c = DateTime.now().addDays(1);
            ts.RecordTypeId = rcaActivityId;
            ts.LOE_hours__c = 3;
            insert ts;
        }
        System.assertEquals(3,[Select Id, Total_LOE_Hours_RCA__c FROM Case WHERE Id=: rca.Id].Total_LOE_Hours_RCA__c);
        System.runAs(new User(id = userId)){delete ts;}
        System.assertEquals(0,[Select Id, Total_LOE_Hours_RCA__c FROM Case WHERE Id=: rca.Id].Total_LOE_Hours_RCA__c);
        
        Test.stopTest();
        
    }
    
    @IsTest
    static void testqualityCoachingFromIraptUsr(){
        Test.startTest();
        Case rca = [Select Id FROM Case Where RecordType.Name =  'RCA Request' LIMIT 1];
        User irapt = [Select Id From User WHERE Email = 'test1test@akamai.com' LIMIT 1];
        System.runAs(irapt){
            SC_QualityCoaching_RCA_Handler.QualityCoachingWrapper wrap = SC_QualityCoaching_RCA_Handler.getRecords(rca.Id, 'RCA','RCA');
            System.assertEquals(true, wrap != null);
            SC_QualityCoaching_RCA_Handler.updateQualityCoachingDetails (JSON.serialize(wrap.tableData), 'test', ''+rca.Id, 'RCA', 'RCA', 22, 4);
        }
        SC_KCS_Scorecard__c score;
        try{
            score = [Select Id,Coaching_Occurred_By__c FROM SC_KCS_Scorecard__c LIMIT 1];
            score.Coaching_Occurred_By__c = UserInfo.getUserId();
            update score;
        } catch(exception e){}
        try{
            score = [Select Id,Coaching_Occurred_By__c FROM SC_KCS_Scorecard__c LIMIT 1];
            score.Coaching_Start_Date__c  = Datetime.now();
            update score;
        } catch(exception e){}
        try{
            score = [Select Id,Coaching_Occurred_By__c FROM SC_KCS_Scorecard__c LIMIT 1];
            score.Coaching_Occurred_By__c = UserInfo.getUserId();
            score.Coaching_Start_Date__c  = Datetime.now();
            update score;
        } catch(exception e){}
        System.assertEquals(null, [Select Id,Coaching_Occurred_By__c FROM SC_KCS_Scorecard__c WHERE Id = :score.Id].Coaching_Occurred_By__c);
        try{
            System.runAs(irapt){
                delete score;
            }
        } catch(exception e){
            
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void testTransitionHoursMethods(){
        Test.startTest();
        Case rca = [Select Id,OwnerId FROM Case Where RecordType.Name =  'RCA Request' LIMIT 1];
        
        SC_RCA_TransitionController cntrl = new SC_RCA_TransitionController();
        SC_RCA_TransitionController.getCurrentShiftDetails(rca.Id);
        String wakeUpTime = SC_RCA_TransitionController.wakeUpTimeMethod('EMEA');
        System.assertEquals(true,Datetime.parse(wakeUpTime) > Datetime.now());
        SC_RCA_TransitionController.createTransitionRecord(rca.id, 'EMEA', wakeUpTime, userinfo.getuserId(), 'test');
        Case_Transition__c ct = [Select Id,completed__c From Case_Transition__c WHERE completed__c = False];
        ct.completed__c = true;
        update ct;
        SC_CaseTriggerHelperClass3.completeTransition( new List<Id>{rca.Id}, new Map<Id, Case>{rca.Id=>rca});
        SC_RCA_TransitionController.createTransitionRecord(rca.id, 'Transition Now', wakeUpTime, userinfo.getuserId(), 'test');
		Test.stopTest();
    }
    @IsTest
    static void testRcaCaseCreation(){
        Id knowledgeRecTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Document').getRecordTypeId();
        Id rcaActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Activity').getRecordTypeId();
        Id peerReviewerRecTypeId = Peer_Reviewer__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Peer Review').getRecordTypeId();
        Test.startTest();
        Case rca = [Select Id FROM Case Where RecordType.Name =  'RCA Request' LIMIT 1];
        User irapt = [Select Id From User WHERE Email = 'test1test@akamai.com' LIMIT 1];
        System.runAs(irapt){
            rca.status='Assigned';
            rca.IRAPT_Approver__c = userInfo.getUserId();
            rca.Legal_Reviewer__c = userInfo.getUserId();
            rca.Exec_Approver__c = userInfo.getUserId();
            rca.Google_Draft_URL__c = 'www.test.com';
            rca.SC_EQ_Notes__c = 'tes';
            update rca;
        }
        
    }
    @IsTest
    static void testRcaCaseUpdate()
    {    
        Id knowledgeRecTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Document').getRecordTypeId();
        Id rcaActivityId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Activity').getRecordTypeId();
        Id peerReviewerRecTypeId = Peer_Reviewer__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Peer Review').getRecordTypeId();
        
        Case rca = [Select Id FROM Case Where RecordType.Name =  'RCA Request' LIMIT 1];
        User irapt = [Select Id From User WHERE Email = 'test1test@akamai.com' LIMIT 1];
        Id adminUserId = [SELECT id,name from user where alias='CRMOPS'].Id;
        Test.startTest();
        System.runAs(irapt)
        {
            knowledge__kav newArticle = new knowledge__kav(Title='test',summary='xyz',urlname='xyz');
            newArticle.RecordTypeId = knowledgeRecTypeId;
            newArticle.Source_Case__c = rca.Id;
            insert newArticle;
			Task tsRec = new Task();
            tsRec.whatId = rca.Id;
            tsRec.Start_Date_Time__c = DateTime.Now();
            tsRec.Completed_Date_Time__c = DateTime.now().addDays(1);
            tsRec.RecordTypeId = rcaActivityId;
            tsRec.LOE_hours__c = 3;
            insert tsRec;
            Peer_Reviewer__c  pr = new Peer_Reviewer__c ();
            pr.RecordTypeId = peerReviewerRecTypeId;
            pr.Case__c = rca.Id;
            pr.Reviewer_Name__c = adminUserId;
            insert pr;
            //update RCA
            rca.OwnerId = userInfo.getUserId();
            rca.IRAPT_Approver__c = userInfo.getUserId();
            rca.Legal_Reviewer__c = userInfo.getUserId();
            rca.Exec_Approver__c = userInfo.getUserId();
            rca.Google_Draft_URL__c = 'www.test.com';
            rca.SC_EQ_Notes__c = 'tes';
            rca.status='KB Article Created';
            update rca;
        }
        
        System.runAs(irapt)
        {       
            rca.status='RCA Delivered';
            update rca;
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testRcaCaseUpdateServInc(){
        
        Test.startTest();
        Case rca = [Select Id,Service_Incident__c FROM Case Where RecordType.Name =  'RCA Request' LIMIT 1];
        Case amg = [Select Id FROM Case Where RecordType.Name =  'AMG' LIMIT 1];
        User irapt = [Select Id From User WHERE Email = 'test1test@akamai.com' LIMIT 1];
        System.runAs(irapt){
            Id siId = createServiceIncident();
            amg.Service_Incident__c = siId;
            amg.Customer_Temperature__c = 'Medium';
        	amg.Level_of_Impact__c = 'Medium';
            update amg;
            SC_CaseTriggerHelperClass3.rcaCasePendingFollowupCondition(new List<Id>{rca.Id}, new List<Id>{siId}, new Map<Id,Case>{rca.id=>rca});
        }
        
		Test.stopTest();
        
         
    }
    
    public static Id createServiceIncident(){
        // Creating Account
        Account acc = utilTestClass.CreateAccount('TestAccoun1t');
        acc.Customer_Tier__c = 'A';
        insert acc;
        
        
        //Creating BMC category type
        BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest' );
        insert ctype;
        
        //Creating category for BMC incident
        BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c();
        cat.Name='TempCategory'; 
        cat.SI_Applies_to_Service_Incident__c = true;
        cat.BMCServiceDesk__AvailableForServiceCatalog__c = true;
        cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;
        insert cat;
        
        //Creating BMC urgency
        BMCServiceDesk__Urgency__c  urg = new BMCServiceDesk__Urgency__c();
        urg.Name='tempUrgency1';
        urg.SI_Applies_to_Service_Incident__c = true;
        insert urg;
        
        //Creating BMC impact
        BMCServiceDesk__Impact__c ima = new BMCServiceDesk__Impact__c();
        ima.Name='tempImpact';
        ima.SI_Applies_to_Service_Incident__c = true;
        insert ima;
        
        //Creating BMC Service Incident
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        incident.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKUrgency__c = urg.id;
        incident.BMCServiceDesk__FKImpact__c = ima.Id;
        incident.BMCServiceDesk__shortDescription__c = 'Inc1';
        incident.how_was_the_issue_detected__c = 'others';
        incident.BMCServiceDesk__Service_Request_Title__c= 'Test1234';
       
        
        //insert incident; 
        
        SC_SI_Service_Incident__c siRecord = new SC_SI_Service_Incident__c();
        siRecord.Status__c = 'Incident Request';
        siRecord.Severity__c ='Severity 1';
        siRecord.Title__c = 'Test Incident 2';
        siRecord.Summary__c ='Test Summary';
        siRecord.Symptoms__c ='Test Symptoms';
        siRecord.What_Incident_Criteria_is_Met__c='Test Criteria';
        siRecord.Customer_Temperature__c ='High';
        siRecord.How_was_the_issue_detected__c = 'Customer';
        siRecord.Customer_Advisory__c = 'Test Advisory';
        
        
        insert siRecord;
        return siRecord.id;
    }
    
    
    @IsTest
    static void testRcaCaseStatusValidation(){
        
        Test.startTest();
        String fields ='';
        List<Metadata.Metadata> layouts = 
        Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
                                     new List<String> {'Case-RCA Request Layout'});
        Metadata.Layout layoutMd = (Metadata.Layout) layouts.get(0);
        
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            for (Metadata.LayoutColumn column : section.layoutColumns) {
                if (column.layoutItems != null) {
                    for (Metadata.LayoutItem item : column.layoutItems) {
                        fields += ','+item.field ;
                    }
                }
            }
        }
        String query = 'Select Id,Validation_Override__c,RecordTypeId '+fields+ ' FROM Case Where RecordType.Name =  \'RCA Request\' LIMIT 1';
       // String query = 'Select Id,Validation_Override__c,RecordTypeId '+fields+ ' FROM Case Where RecordType.Name =  \'RCA Request\' LIMIT 1'; 
        Case rca = (case)Database.query(query)[0];
            //[Select Id,RecordTypeId, RCA_Owner__c, OwnerId, Status,Validation_Override__c,Next_Action_Owner__c FROM Case Where RecordType.Name =  'RCA Request' LIMIT 1];
        User irapt = [Select Id From User WHERE Email = 'test1test@akamai.com' LIMIT 1];
        Map<Id,String> mRecordType = new Map<Id, String>();
        Id rcaRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Request').getRecordTypeId();
        mRecordType.put(rcaRecordTypeId, 'RCA Request');
        Case newCase = new Case();
        newCase = rca;
        newCase.RCA_Owner__c = UserInfo.getUserId();
        newCase.Status = 'Rejected';
        newCase.OwnerId = UserInfo.getUserId();
        Map<id, Case> oldMap = new Map<Id, Case>();
        oldMap.put(rca.Id, rca);
        Set<Id> userIdSet = new Set<Id>{UserInfo.getUserId()};
        Id peerReviewerRecTypeId = Peer_Reviewer__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('RCA Peer Review').getRecordTypeId();
        SC_CaseTriggerHelperClass3.rcaNonIraptValidationCheck (null, new List<Case>{newCase}, null );
        SC_CaseTriggerHelperClass3.rcaNonIraptValidationCheck (null, new List<Case>{newCase}, oldMap );
        User extUser = [SELECT id,name, email from user where not(email like '%akamai.com') limit 1];
        System.runAs(irapt){
            SC_CaseTriggerHelperClass3.checkRCA_OwnerValidation( new List<Case>{newCase}, oldMap,userIdSet, mRecordType );
            
            SC_CaseTriggerHelperClass3.getWorkingDays(Date.today(), Date.Today().addYears(1).addDays(50));
            Peer_Reviewer__c  pr = new Peer_Reviewer__c ();
            pr.RecordTypeId = peerReviewerRecTypeId;
            pr.Case__c = rca.Id;
            pr.Reviewer_Name__c = irapt.Id;
            insert pr;
            rca.IRAPT_Approver__c = irapt.id;
            SC_CaseTriggerHelperClass3.checkIraptApproverValidation( new Set<Id>{irapt.Id}, new List<Case>{rca} );
            rca.Exec_Approver__c = extUser.id;
            SC_CaseTriggerHelperClass3.checkIsUserInternal( new List<Id>{extUser.Id}, new List<Case>{rca} );
            
        }
        
		Test.stopTest();
        
         
    }
    
    @isTest public static void testCaseTransition() {
        Account Acc = utilTestClass.CreateAccount('TestAccount');
        test.startTest();
        Case c = utilTestClass.CreateCase(Acc.id);
        c.OwnerId = userInfo.getuserid();
        c.Issue_Summary__c = 'Test';
        c.Troubleshooting_to_Date__c = 'test';
        c.Data_Collected__c = 'test';
        c.Customer_Expectations__c = 'test';
        c.Next_Action_Recommendation__c = 'test';
        c.Validation_Override__c  = true;
        update c;
        PageReference pageRef = Page.SC_CaseTransitionCreateV2;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('Id',c.id);
          SC_CaseTransitionControllerV2 ctc = new SC_CaseTransitionControllerV2(sc);
          case_transition__c ct = new case_transition__c();
          ct.target_shift__C = 'Transition Now';
          ct.approved_by__c = userinfo.getUserId();
          ct.case__c = c.id;
          ctc.caseTransitionObject = ct;
          List<Id> lCt = new List<Id>{ct.id};
          List<Id> lC = new List<Id>{c.id};
          ctc.approveTransition();
          ctc.getActiveTransition();
          ctc.getDisplayTransitionButton();
          ctc.updateTargetDate();
          SC_CaseTransitionControllerV2.updateCaseAsync(lCt, lC);
          Case caseRec = SC_CaseTransitionControllerV2.retCaseDetails(c.id);
          Boolean canCreateTransition = SC_CaseTransitionControllerV2.canCreateCT(caseRec);
          String transtionCreationStatus = SC_CaseTransitionControllerV2.createTransitionRec(caseRec, false, 'APAC');
          String username = SC_CaseTransitionControllerV2.getUserName();
          String currentShiftDetails = SC_CaseTransitionControllerV2.getCurrentShiftDetails();
          Id transitionRecTypeId = SC_CaseTransitionControllerV2.getCaseTransRecTypeId('Akatec');
          String shiftWakeUpTime = SC_CaseTransitionControllerV2.wakeUpTimeMethod('APAC');
          shiftWakeUpTime = SC_CaseTransitionControllerV2.wakeUpTimeMethod('None'); 
          shiftWakeUpTime = SC_CaseTransitionControllerV2.wakeUpTimeMethod('transition now');
        test.stopTest();
      }
     
    
    // Method# 33 for case transition 
    @isTest public static void testCaseTransition3() {
        
        Account Acc = utilTestClass.CreateAccount('TestAccount');
        test.startTest();
        Case c = utilTestClass.CreateCase(Acc.id);
        c.OwnerId = userInfo.getuserid();
        c.Issue_Summary__c = 'Test';
        c.Troubleshooting_to_Date__c = 'test';
        c.Data_Collected__c = 'test';
        c.Customer_Expectations__c = 'test';
        c.Next_Action_Recommendation__c = 'test';
        c.has_active_transition__c = false;
        update c;
        
        PageReference pageRef = Page.SC_CaseTransitionCreateV2;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('Id',c.id);
        
          SC_CaseTransitionControllerV2 ctc = new SC_CaseTransitionControllerV2(sc);
          case_transition__c ct = new case_transition__c();
          //This will give the next shift name
          String currentShift = SC_utility.getCurrentShiftDetails('Akatec');
          //String nextShift = SC_utility.getNextShift(currentShift);
          ct.target_shift__C = 'APAC';
          ct.approved_by__c = userinfo.getUserId();
          ct.Shift_Tracker__c = true;
          ct.case__c = c.id;
          ctc.caseTransitionObject = ct;
          ctc.getActiveTransition();
          ctc.getDisplayTransitionButton();
          ctc.updateTargetDate();
          ctc.approveTransition();
        c.OwnerId = userInfo.getuserid();
        SC_CaseTriggerHelperClass.flagvalue = False;
        update c;
        test.stopTest();
        }
}