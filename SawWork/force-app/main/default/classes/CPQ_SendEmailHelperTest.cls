/**
* Test class for CPQ_sendEmailHelper class
* @author  Shashank Hegade 
* @version 1.0
* @since   2020-11-04
*/

@IsTest(seeAllData = false)
public with sharing class CPQ_SendEmailHelperTest {
   
    @TestSetup
    static void makeData(){

    
        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createLegalEntities();
        CPQ_TestQuoteSetupMethods.simpleAutonomyQuoteSetup();

    }

    @IsTest
    static void testSimpleEmail(){
        
        
        Test.startTest();
        try{
            CPQ_SendEmailHelper dummyCall = new CPQ_SendEmailHelper();
            CPQ_SendEmailHelper.MailingInfo testBundle = new CPQ_SendEmailHelper.MailingInfo('Testing Simple main sender','<h1>Sample Body<h1>',new List<String>{'shegade@akamai.com'});
            CPQ_SendEmailHelper testMail = new CPQ_SendEmailHelper(testBundle, true);
            Messaging.SingleEmailMessage message = testMail.setDefaultOrgWideId(new Set<String>{'shegade@akamai.com'}).getMessageObject();
            Messaging.SendEmailResult[] results = testMail.sendTheEmail();
        }
        catch(Exception e){
            System.assert(false, e.getMessage());
        }
        Test.stopTest();

        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'An email has not been sent');
        
    }

    @IsTest
    static void testTemplateEmail(){

        SBQQ__Quote__c testQuote = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1]; 

        Test.startTest();
        try{
            Messaging.SendEmailResult[] result = new CPQ_SendEmailHelper('Autonomy Process Initiation Notification', testQuote.id, new List<string>{'shegade@akamai.com'}).sendTheEmail();
        }
        catch(Exception e){
            System.assert(false, e.getMessage());
        }
        Test.stopTest();

        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'An email has not been sent');
        
    }

    @IsTest
    static void testFutureEmailMethod(){

        SBQQ__Quote__c testQuote = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        
        Test.startTest();
        try{
            CPQ_SendEmailHelper.sendTemplateBasedEmails('Autonomy Process Initiation Notification',new List<Id>{testQuote.Id},new List<String>{'shegade@akamai.com'});

        }
        Catch(Exception e){
            System.assert(false, e.getMessage());
        }
        Test.stopTest();
        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'An email has not been sent');

        
    }

    @IsTest
    static void testInvocableEmailMethod(){
        
        
        CPQ_SendEmailHelper.FlowRequest testRequest  = new CPQ_SendEmailHelper.FlowRequest();
        testRequest.body = '<h1> HELLO WORLD! <h1>';
        testRequest.isHtmlBody = true;
        testRequest.subject = 'test subject';
        testRequest.toAddressList = new List<String>{ 'shegade@akamai.com'};

        Test.startTest();
        try{
            CPQ_SendEmailHelper.sendEmail(new List<CPQ_SendEmailHelper.FlowRequest>{testRequest});
        }
        Catch(Exception e){
            system.assert(false, e.getMessage());
        }

        Test.stopTest();

        Integer invocations = Limits.getEmailInvocations();
        System.assert(invocations > 0, 'An email has not been sent');

        
    }
}