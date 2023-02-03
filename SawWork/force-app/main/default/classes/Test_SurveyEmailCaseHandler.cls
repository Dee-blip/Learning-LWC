/*****************************************************************************
 * Name             : Test_SurveyEmailCaseHandler
 * Created By       : Pitamber Sharma
 * Created Date     : 22-May-2013
 * Purpose          : Test Class for SurveyEmailCaseHandler
 * 22-Apr-14    : avidapan-Optimizization of test class
 *****************************************************************************/
 
@isTest(seeAllData=false)
private class Test_SurveyEmailCaseHandler {

    //Test method-1
    static testMethod void myUnitTest() {
         
        Test.startTest();   
        utilTestClass.createCustomSettings();
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           
        // setup the data for the html email
        email.subject = 'Test Email Service';
          email.fromAddress = 'ccare_dsat@feedback.akamai.com';
          email.htmlBody = '<p>email body</p>2225256325</br>Title Manager: PSHAR';
          email.ToAddresses = new String[]{'ccare@akamai.com'};
          
          // call the email service class and test it with the data in the testMethod
          SurveyEmailCaseHandler  testInbound = new SurveyEmailCaseHandler();
          testInbound.handleInboundEmail(email, env);
          Test.stopTest();
    }
    
    //Test method-2
    static testMethod void myUnitTest1() {
       
        Test.startTest();   
         utilTestClass.createCustomSettings();
        Account acc = utilTestClass.CreateAccount('Test Acc');
        acc.Parent_Division__c = 'ABC_abcd';
                insert acc;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
          Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           
        // setup the data for the plain text email   
          email.subject = 'Test Email Service';
          email.fromAddress = 'service_desk@feedback.akamai.com';
          email.plainTextBody = 'email body/n2225256325/nTitle Manager: ABCD Account ID:' + acc.AKAM_Account_ID__c;
          email.ToAddresses = new String[]{'specialist@akamai.com'};
          
       // call the email service class and test it with the data in the testMethod
          SurveyEmailCaseHandler testInbound = new SurveyEmailCaseHandler();
          testInbound.handleInboundEmail(email, env);
          Test.stopTest();
    }
    
    //Test method-3
    static testMethod void myUnitTest3() {
       
        Test.startTest();   
         utilTestClass.createCustomSettings();
        Account acc = utilTestClass.CreateAccount('Test Acc');
        acc.Parent_Division__c = 'ABC_abcd';
                insert acc;
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
          Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
           
        // setup the data for the plain text email   
          email.subject = 'Test Email Service';
          email.fromAddress = 'ccare_team@feedback.akamai.com';
          email.ToAddresses = new String[]{'ccare@akamai.com'};
          
       // call the email service class and test it with the data in the testMethod
          SurveyEmailCaseHandler testInbound = new SurveyEmailCaseHandler();
          testInbound.handleInboundEmail(email, env);
          Test.stopTest();
    }
}