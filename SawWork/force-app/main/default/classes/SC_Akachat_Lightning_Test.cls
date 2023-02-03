/*
Author          : Sheena Bhan
Description     : Test Class for SC_Akachat_Lightning


Date                Developer             JIRA #                            Description                                                       
------------------------------------------------------------------------------------------------------------------
22 May 2020         Sheena               ESESP-2347               		Akachat Migration to Lightning
------------------------------------------------------------------------------------------------------------------
*/

@isTest
public class SC_Akachat_Lightning_Test {
    
    @testSetup
    static void setupMethod()
    {
        utilTestClass.createCustomSettings();

        Account newAccount = utilTestClass.CreateAccount('Test Aka Account');
        insert newAccount;
        
        Contact newContact = utilTestClass.CreateContact('Aka','Chat');
        newContact.AccountId = newAccount.id;
        insert newContact;
        
        List<case> caseList = new List<case>();
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        newCase.Subject = 'Test Case';
        newCase.Description = 'TestDescription';  
        newCase.origin='AkaChat Community';
        newCase.ContactId = newContact.id;
        caseList.add(newCase);
        
        Case newCase2 = new Case();
        newCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase2.Subject = 'Test Tech Case';
        newCase2.Description = 'TestDescription';  
        newCase2.origin='AkaChat Community';
        caseList.add(newCase2);
        insert caseList;
        
        LiveChatVisitor chatVisitor = new LiveChatVisitor();
        insert chatVisitor;
        
        LiveChatTranscript chatTranscript = new LiveChatTranscript();
        chatTranscript.Body = 'Test';
        chatTranscript.StartTime = system.now();
        chatTranscript.EndTime = system.now() + 20;
        chatTranscript.CaseId = newCase.Id;
        chatTranscript.LiveChatVisitorId = chatVisitor.Id;
        insert chatTranscript; 
    }
    
    @isTest
    static void testPostChatActions()
    {
        Test.startTest();
        Case newCase = [Select Id from Case where Subject = 'Test Case'];
       
        Map<String,String> mCaseValues = new Map<String,String>();
        mCaseValues.put('Root_Cause__c','Test Root Cause');
        mCaseValues.put('Chat_Summary__c','Test Summary');
        mCaseValues.put('Resolution__c','Test Resolution');
        mCaseValues.put('Why_not_Resolved__c','More analysis needed');
        mCaseValues.put('Severity__c','3');
        mCaseValues.put('Customer_Expectations__c','Lot of expectations');
        mCaseValues.put('Troubleshooting_to_Date__c','Test Troubleshooting');
        
        SC_Akachat_Lightning.getRadioOptions();
        SC_Akachat_Lightning.getValidations(newCase.Id);
        SC_Akachat_Lightning.getCaseRecType(newCase.Id);
        SC_Akachat_Lightning.techincalCaseResolved(newCase.Id,mCaseValues,'Resolved');
        //SC_Akachat_Lightning.amgCaseResolved(newCase.Id,mCaseValues,'Resolved');
        
        Test.stopTest();
    }
    
    @isTest
    static void testPostChatActions1()
    {
        
        Case newCase = [Select Id from Case where Subject = 'Test Case'];
       
        Map<String,String> mCaseValues = new Map<String,String>();
        mCaseValues.put('Root_Cause__c','Test Root Cause');
        mCaseValues.put('Chat_Summary__c','Test Summary');
        mCaseValues.put('Resolution__c','Test Resolution');
        mCaseValues.put('Why_not_Resolved__c','More analysis needed');
        mCaseValues.put('Severity__c','3');
        mCaseValues.put('Customer_Expectations__c','Lot of expectations');
        mCaseValues.put('Troubleshooting_to_Date__c','Test Troubleshooting');

        Test.startTest();
        SC_Akachat_Lightning.amgCaseResolved(newCase.Id,mCaseValues,'Resolved');
        Test.stopTest();
    }
    
    @isTest
    static void testPostChatActions2()
    {
        Test.startTest();
        Case newCase = [Select Id from Case where Subject = 'Test Tech Case'];
        
        Map<String,String> mCaseValues = new Map<String,String>();
        mCaseValues.put('Root_Cause__c','Test Root Cause');
        mCaseValues.put('Chat_Summary__c','Test Summary');
        mCaseValues.put('Resolution__c','Test Resolution');
        mCaseValues.put('Why_not_Resolved__c','More analysis needed');
        mCaseValues.put('Severity__c','3');
        mCaseValues.put('Customer_Expectations__c','Lot of expectations');
        mCaseValues.put('Troubleshooting_to_Date__c','Test Troubleshooting');
        
        SC_Akachat_Lightning.getValidations(newCase.Id);
        SC_Akachat_Lightning.techincalCaseNotResolved(newCase.Id,mCaseValues,'Not Resolved');
        //SC_Akachat_Lightning.amgCaseNotResolved(newCase.Id,mCaseValues,'Not Resolved');
        
        Test.stopTest();
    }
    
    @isTest
    static void testPostChatActions3()
    {
        
        Case newCase = [Select Id from Case where Subject = 'Test Tech Case'];
        
        Map<String,String> mCaseValues = new Map<String,String>();
        mCaseValues.put('Root_Cause__c','Test Root Cause');
        mCaseValues.put('Chat_Summary__c','Test Summary');
        mCaseValues.put('Resolution__c','Test Resolution');
        mCaseValues.put('Why_not_Resolved__c','More analysis needed');
        mCaseValues.put('Severity__c','3');
        mCaseValues.put('Customer_Expectations__c','Lot of expectations');
        mCaseValues.put('Troubleshooting_to_Date__c','Test Troubleshooting');
     
        Test.startTest();
        SC_Akachat_Lightning.amgCaseNotResolved(newCase.Id,mCaseValues,'Not Resolved');
        Test.stopTest();
    }
}