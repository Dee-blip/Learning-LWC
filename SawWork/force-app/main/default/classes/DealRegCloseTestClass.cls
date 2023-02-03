@isTest(SeeAllData = false)
public with sharing class DealRegCloseTestClass {
    
  
    public static Id testAccountCreation(){
        //utilTestClass.insertCustomSettings();
        Account acc = utilTestClass.CreateAccount('Creating Account record ');
        acc.Website = 'www.account.com';
        acc.BillingState = 'MA';
        acc.BillingCountry = 'USA';
        acc.BillingPostalCode ='89765';
        insert acc;
        return acc.id ;
    }
    public static  ID  testOpptyCreation( Integer days , String RecordType){
        Opportunity oppty = utilTestClass.CreateOpportunity('Test Oppty', '1-Create');
        oppty.AccountId =testAccountCreation();
        oppty.CloseDate = Date.today().addDays(-(days));
        oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(RecordType).getRecordTypeId();
        insert oppty;
        return oppty.id;
    }
    static testmethod void updateCloseAdminfromSubmittedDeal(){
        Test.StartTest();
        String id = testOpptyCreation(32,'Deal Reg Submitted');
        DealRegAutoClose deal = new DealRegAutoClose();
        String res = deal.DealClose('Deal Reg Submitted', 30, false);
        Test.StopTest();
        Opportunity opp = [Select Id , StageName from Opportunity Where ID =: id ];
        System.AssertEquals('Closed Admin', opp.StageName);
    }
    static testmethod void updateCloseAdminFromunsubmittedDeal(){
        Test.StartTest();
        String id = testOpptyCreation(32,'Deal Reg Unsubmitted');
        DealRegAutoClose deal = new DealRegAutoClose();
        String res = deal.DealClose('Deal Reg Unsubmitted', 30, false);
        Test.StopTest();
        Opportunity opp = [Select Id , StageName from Opportunity Where ID =: id ];
        System.AssertEquals('Closed Admin', opp.StageName);
    
    }
     static testmethod void updateCloseAdminFromRejectedDeal(){
        Test.StartTest();
        String id = testOpptyCreation(32,'Deal Reg Rejected');
        DealRegAutoClose deal = new DealRegAutoClose();
        deal.DealClose('Deal Reg Rejected', 30, false);
        Test.StopTest();
        Opportunity opp = [Select Id , StageName from Opportunity Where ID =: id ];
        System.AssertEquals('Closed Admin', opp.StageName);
    
    }
    static testmethod void failUpdateCloseAdminFromSubmitted(){
        User standarduser = utilTestClass.testUserCreation('Read Only' ,'Stduser' , 'testStandarduser' ,'standardusr1@akamai.com' , 'user2name@akmai.com.sfdev');
        Test.StartTest();
        String id = testOpptyCreation(32 , 'Deal Reg Submitted');
        System.RunAs(standarduser) {
            DealRegAutoClose deal = new DealRegAutoClose();
            deal.DealClose('Deal Reg Submitted', 30, false);
            }
        Opportunity opp = [Select Id , StageName from Opportunity Where ID =: id ];
        System.AssertNotEquals('Closed Admin', opp.StageName);
        Test.StopTest();
        }
        
    static testmethod void failUpdateCloseAdminFromUnSubmitted(){
        User standarduser = utilTestClass.testUserCreation('Read Only' ,'Stduser' , 'testStandarduser' ,'standardusr1@akamai.com' , 'user2name@akmai.com.sfdev');
        Test.StartTest();
        String id = testOpptyCreation(32 , 'Deal Reg Unsubmitted');
        System.RunAs(standarduser) {
            DealRegAutoClose deal = new DealRegAutoClose();
            deal.DealClose('Deal Reg Unsubmitted', 30, false);
            }
        Opportunity opp = [Select Id , StageName from Opportunity Where ID =: id ];
        System.AssertNotEquals('Closed Admin', opp.StageName);
        Test.StopTest();
        }
        
        static testmethod void failUpdateCloseAdminFromRejected(){
        User standarduser = utilTestClass.testUserCreation('Read Only' ,'Stduser' , 'testStandarduser' ,'standardusr1@akamai.com' , 'user2name@akmai.com.sfdev');
        Test.StartTest();
        String id = testOpptyCreation(32 , 'Deal Reg Rejected');
        System.RunAs(standarduser) {
            DealRegAutoClose deal = new DealRegAutoClose();
            deal.DealClose('Deal Reg Rejected', 30, false);
            }
        Opportunity opp = [Select Id , StageName from Opportunity Where ID =: id ];
        System.AssertNotEquals('Closed Admin', opp.StageName);
        Test.StopTest();
        }  
         
    static testmethod void tesEmailNotify(){
        Test.StartTest();
        testOpptyCreation(14 , 'Deal Reg Submitted');
        DealRegAutoClose deal = new DealRegAutoClose();
        String res =deal.DealClose('Deal Reg Submitted', 14, true);
        Test.StopTest();
    }
     
    static testmethod void testFailEmailNotify(){
        User standarduser = utilTestClass.testUserCreation('Read Only' ,'Stduser' , 'testStandarduser' ,'standardusr1@akamai.com' , 'user2name@akmai.com.sfdev');
        Test.StartTest();
        testOpptyCreation(14 , 'Deal Reg Submitted');
        System.RunAs(standarduser) {
            DealRegAutoClose deal = new DealRegAutoClose();
            String res =deal.DealClose('Deal Reg Submitted', 14, true);
        }
        Test.StopTest();
     }
 }