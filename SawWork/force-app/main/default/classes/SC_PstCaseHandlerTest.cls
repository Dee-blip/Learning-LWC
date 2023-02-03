@isTest
public with sharing class SC_PstCaseHandlerTest {
    
    static Deal_Support_Request__c getDsr(Id oppId, String req, String appStatus ) {
        return new Deal_Support_Request__c(Opportunity__c = oppId, Request_Type__c = req, Approval_Status__c = appStatus,  Product__c = 'Client Reputation', SE__c = UserInfo.getUserId(), RVP__c = UserInfo.getUserId());
    }
    
    static Account getAccount(String accountName, String country ) {
        return new Account(Name = accountName, BillingCountry = country);
    }
    
    static Opportunity getOpportunity(Id accountId, String oppName ) {
        return new Opportunity(AccountId = accountId, name = oppName, StageName  = '1. Identify Need', CloseDate = System.today());
    }
    
    static Case getPstCase(Id accId, Id oppId, Id dsrId, String service, String reqType, string prod ) {
      return new Case(AccountId = accId, RecordtypeId = PST_RT_ID, Opportunity__c = oppId, Deal_Support_Request__c = dsrId, Service__c = service, Request_Type__c = reqType, PST_Case_Product__c = prod );  
    }
    
    static SC_Trial_Request_Form__c getTrf(String rtName) {
        Id recordTypeId =  Schema.SObjectType.SC_Trial_Request_Form__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
		return new SC_Trial_Request_Form__c(RecordTypeId = recordTypeId);
    }
    
    static RSS_Form__c getErss(String name) {
		return new RSS_Form__c(Name = name, Published__c = true);
    }
    
    
    static Id PST_RT_ID = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('PST_Case').getRecordTypeId();
    
    @testSetup static void testInit() {
        // to fix GSM Custom settings, error in Case trigger
        insert new GSM_Custom_Settings__c(Name = 'CaseTrigger#updateContact', value__c = 'Collections');
        insert new GSM_Custom_Settings__c(Name = 'IR_CaseDefaultRecordTypeId', value__c = 'Collections');
        insert new GSM_Custom_Settings__c(Name = 'IR_CaseRecordTypeIds', value__c = 'Collections');
                // to fix GSM Custom settings, error in Case trigger
        insert new GSM_Custom_Settings__c(Name = 'CaseTrigger#updateContact', value__c = 'Collections');
        insert new GSM_Custom_Settings__c(Name = 'IR_CaseDefaultRecordTypeId', value__c = 'Collections');
        insert new GSM_Custom_Settings__c(Name = 'IR_CaseRecordTypeIds', value__c = 'Collections');
        insert new SCUserIdCustomSetting__c(Name = 'Cash Apps');
        insert new SCRecordTypeCustomSetting__c(Name = 'NotificationTeam');  
        insert new SC_RiverbedCaseProdID__c(Name = 'Riverbed_SAAS_OEM', RecordTypeID__c = 'test', Case_Product_ID__c = 'test');
        insert new Email_to_Case__c(Name = 'Momentum');
        insert new Email_to_Case__c(Name = 'ProdMgmt');
        
        Account acc1 = getAccount('testAcc12', 'USA');
        insert acc1;
        
        Opportunity opp1 = getOpportunity(acc1.id, 'testOpp1212' );
        insert opp1;
            
        Deal_Support_Request__c pocDsr = getDsr(opp1.Id, 'DEMO', 'Approved');
        
        insert pocDsr;
        
        RSS_Form__c pocErss = getErss('Test1233');
        insert pocErss;
        
        Case testCase = getPstCase(acc1.Id, opp1.Id, pocDsr.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        testCase.eRSS_Form__c = pocErss.Id;
        testCase.status = 'Unassigned';
        insert testCase;
        testCase.ownerid = System.UserInfo.getUserId();
        testCase.POD__c = 'Americas';
        update testCase;
        
    }
    
    testMethod static void testDsr() {
        Test.startTest();
        Account acc1 = getAccount('testAcc', 'USA');
        insert acc1;
        
        Opportunity opp1 = getOpportunity(acc1.id, 'testOpp1' );
        Opportunity opp2 = getOpportunity(acc1.id, 'testOpp2' );
        insert new List<Opportunity>{opp1, opp2};
            
        Deal_Support_Request__c pocDsr = getDsr(opp1.Id, 'DEMO', 'Approved');
        Deal_Support_Request__c carDSR = getDsr(opp1.Id, 'CAR', 'Approval Pending');
        Deal_Support_Request__c rejectedDsr = getDsr(opp1.Id, 'DEMO', 'Rejected');
        Deal_Support_Request__c invalidOppDsr = getDsr(opp2.Id, 'CAR', 'Approval Pending');
        
        insert new List<Deal_Support_Request__c> {pocDsr, carDSR, rejectedDsr, invalidOppDsr};

        SC_Trial_Request_Form__c carTrf = getTrf('Customer Analysis Report');
        insert carTrf;
        update carTrf;
        
        RSS_Form__c pocErss = getErss('Test');
        insert pocErss;
        
        Case pocCase = getPstCase(acc1.Id, opp1.Id, pocDsr.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        pocCase.eRSS_Form__c = pocErss.Id;
        
        Case carCase = getPstCase(acc1.Id, opp1.Id, carDSR.Id, 'Trial / PoC', 'Customer Analysis Report(Synthetic Trial)', 'DSA');
        carCase.Trial_Request_Form__c = carTrf.Id; 
        
        Case invalidOppCase = getPstCase(acc1.Id, opp2.Id, invalidOppDsr.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        Case invalidCarCase = getPstCase(acc1.Id, opp1.Id, pocDsr.Id, 'Trial / PoC', 'Customer Analysis Report(Synthetic Trial)', 'DSA');
        Case invalidPocCase = getPstCase(acc1.Id, opp1.Id, carDSR.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        

        List<Database.SaveResult> saveRes = Database.insert(new List<Case> {pocCase, carCase, invalidOppCase, invalidCarCase, invalidPocCase}, false);
        
        for(Database.SaveResult sr: saveRes) {
            if(sr.isSuccess()) {
                continue;
            }

            System.debug('The following error has occurred.');                    
            
            for(Database.Error err : sr.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Case fields that affected this error: ' + err.getFields());
            }
            
        }
        Case invalidTrfforCase = getPstCase(acc1.Id, opp1.Id, pocDsr.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        invalidTrfforCase.Trial_Request_Form__c = carTrf.Id; 

        try {
            insert invalidTrfforCase;
        } Catch(exception ex) {
            system.debug(ex);
        }
        
        System.debug('carCase ' + carCase.id);
        System.debug('invalidTrfforCase ' + invalidTrfforCase.id);
        Test.stopTest();
    }
        
    
    testmethod static void testPstNotes() {
        Test.startTest();
        Account acc1 = getAccount('testAcc', 'USA');
        insert acc1;
        
        Opportunity opp1 = getOpportunity(acc1.id, 'testOpp1' );
        insert opp1;
            
        Deal_Support_Request__c pocDsr = getDsr(opp1.Id, 'DEMO', 'Approved');
        
        insert pocDsr;
        
        RSS_Form__c pocErss = getErss('Test');
        insert pocErss;
        
        Case pocCase = getPstCase(acc1.Id, opp1.Id, pocDsr.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        pocCase.eRSS_Form__c = pocErss.Id;
        
        insert pocCase;
        
        FeedItem pstNotes = new FeedItem();
        pstNotes.Body = 'Post body 1';
        pstNotes.Title = 'New Title';
        pstNotes.ParentId = pocCase.Id;
        Boolean updateError = false;
        Boolean deleteError = false;
        try {
            insert pstNotes;
            pstNotes.body ='post body 2';
            update pstNotes;
        } catch(exception ex) {
            updateError = true;
        }
        
        try {
            delete pstNotes;
        } catch(exception ex) {
            deleteError = true;
        }
        System.assertEquals(true, deleteError);
        System.assertEquals(true, updateError);
		test.stopTest();
    }
    
    testMethod static void testTriggerAbstract() {
        SC_TriggerHandlerAbstract fiTrigger = new SC_FeedItemTriggerHandler();
        fiTrigger.handleBeforeInsert();
        fiTrigger.handleAfterUpdate();
        fiTrigger.handleAfterDelete();
        fiTrigger.handleAfterUndelete();
        
        SC_TriggerHandlerAbstract trfTrigger = new SC_TrialFormTriggerHandler();
        trfTrigger.handleAfterInsert();
        trfTrigger.handleBeforeDelete();
    }
    
    
    
     testmethod static void testClosedCaseFeedback() {
          Test.startTest();
         List<Case> caseList = [select id, status from case limit 1];
		 Case testCase = caseList[0];
         testCase.status = 'Closed';
         testCase.Implementation_Status__c = 'Closed';
         testCase.Close_Code__c = 'Completed';
         SC_Performance_Metrics__c pm = new SC_Performance_Metrics__c (Test_Setup__c  = 'No', Case__c = testCase.Id);
         insert pm;
         try{
             update testCase;
         } catch(exception ex) {
             
         }
         Test.stopTest();

     }
    
    testmethod static void testToCloneCases() {
        List<Case> caseList = [select id, status, PST_Case_Product__c, Request_Type__c from case limit 1];

        Case pocCase = caseList[0];
        pocCase.PST_Case_Product__c = 'Prod1;Prod2';
        SC_PSTCaseHandler.getCloneCases(pocCase);
        
    }
    
    
    testMethod static void testCaseReport1() {
        List<SC_Case_Report__c> cReps = [select id from SC_Case_Report__c];
        System.assertEquals(1, cReps.size());
        Id accountId = [Select id from Account where name = 'testAcc12'][0].Id;
        insert new Case(AccountId = accountId, Opportunity__r = new Opportunity(Name = 'testOpp1212'), RecordtypeId = PST_RT_ID, Service__c = 'Trial / PoC', Request_Type__c = 'PoC(PST)' , PST_Case_Product__c = 'DSA', Validation_Override__c  = true);  
        cReps = [select id from SC_Case_Report__c];
        System.assertEquals(2, cReps.size());  
    }
    
    testMethod static void testCaseReport2() {
        
        Case cs = [select id from Case limit 1];
        cs.Implementation_Status__c =  'Initial Results Available';
        cs.Status =  'Work in Progress';
        cs.ownerid = System.UserInfo.getUserId();
        update cs;
        
        List<SC_Case_Report__c> cReps = [select id from SC_Case_Report__c];
        System.assertEquals(1, cReps.size());
    }

    @IsTest
    static void testCaseAssignorValueScenario(){
        //Create a case with Owner Id a PST Queue
        Group pstQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'PS_Global_PST_PoC_Queue'];
        Account acc1 = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE AccountId = :acc1.Id LIMIT 1];
        Deal_Support_Request__c dsr = [SELECT Id FROM Deal_Support_Request__c WHERE Opportunity__c =: opp1.Id LIMIT 1];
        RSS_Form__c pocErrs = [SELECT Id FROM RSS_Form__c LIMIT 1];
        Case testCase = getPstCase(acc1.Id, opp1.Id, dsr.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        testCase.eRSS_Form__c = pocErrs.Id;
        testCase.Status = 'Unassigned';
        testCase.OwnerId = pstQueue.Id;
        insert testCase;
        Test.startTest();
        Case aCase = [SELECT Id,OwnerId FROM Case WHERE Id=:testCase.Id];
        System.assert(String.valueOf(aCase.OwnerId).startsWith('00G'),'Case Owner should\'ve been a Queue. Test cannot continue: '+aCase.OwnerId);
        aCase.OwnerId = UserInfo.getUserId();
        aCase.POD__c = 'Americas';
        update aCase;
        Test.stopTest();
        SC_Case_Report__c caseReport = [SELECT Id,CaseAssignor__c FROM SC_Case_Report__c WHERE Case__c =:aCase.Id LIMIT 1];
        System.assert(caseReport!=null);
        System.assert(caseReport.CaseAssignor__c==UserInfo.getUserId(),'CaseAssignor value incorrect: '+caseReport.CaseAssignor__c);
    }

    @IsTest
    static void testTTIR(){
        Account acc1 = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp1 = [SELECT Id FROM Opportunity WHERE AccountId = :acc1.Id LIMIT 1];
        Deal_Support_Request__c dsr = [SELECT Id FROM Deal_Support_Request__c WHERE Opportunity__c =: opp1.Id LIMIT 1];
        RSS_Form__c pocErrs = [SELECT Id FROM RSS_Form__c LIMIT 1];
        Case aCase = getPstCase(acc1.Id, opp1.Id, dsr.Id, 'Trial / PoC', 'PoC(PST)', 'DSA');
        aCase.eRSS_Form__c = pocErrs.Id;
        aCase.Status = 'Assigned';
        aCase.OwnerId = UserInfo.getUserId();
        aCase.POD__c = 'Americas';
        insert aCase;
        Test.startTest();
        aCase.Status = 'Pending';
        aCase.Implementation_Status__c = 'Awaiting Go Live';
        update aCase;
        Test.stopTest();
        SC_Case_Report__c caseReport = [SELECT Id,TTIR__c FROM SC_Case_Report__c WHERE Case__c=:aCase.Id LIMIT 1];
        System.assert(caseReport!=null,'CaseReport record not found');
        System.assert(caseReport.TTIR__c == 1.5,'Incorrect TTIR value: '+caseReport.TTIR__c);
    }

    @IsTest
    static void testTTGLWithIR(){
        Case aCase = [SELECT Id FROM Case WHERE RecordType.Name = 'PST' AND Status = 'Assigned' LIMIT 1];
        aCase.Status = SC_CaseReportTriggerHandler.PENDING;
        aCase.Implementation_Status__c = 'Awaiting Response - SE';
        update aCase;
        Test.startTest();
        aCase.Status = SC_CaseReportTriggerHandler.WORK_IN_PROGRESS;
        aCase.Implementation_Status__c = SC_CaseReportTriggerHandler.CUST_LIVE_ON_AKAMAI;
        update aCase;
        Test.stopTest();
        SC_Case_Report__c caseReport = [SELECT Id,TTGLWithIR__c,TTGLWithoutIR__c FROM SC_Case_Report__c WHERE Case__c=:aCase.Id LIMIT 1];
        System.assert(caseReport.TTGLWithIR__c == 1.23,'TTGLWithIR calculation failed: '+caseReport.TTGLWithIR__c);
        System.assert(caseReport.TTGLWithoutIR__c == 0.91,'TTGLWithIR calculation failed: '+caseReport.TTGLWithoutIR__c);


    }

}