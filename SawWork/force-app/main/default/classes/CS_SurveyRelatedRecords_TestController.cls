/*
Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
*/
@isTest
private class CS_SurveyRelatedRecords_TestController {

    static CS_Survey__c survey;
    static CS_SurveyAccount__c surveyAccount;
    static CS_SurveyContacts__c surveyContact;
    static CS_SurveyContacts__c surveyContact1;
    static Account account;
    static Account account1;
    static Contact contact1;
    static Contact contact2;
    static Contact contact3;
    static String accountName = 'SurveyRelatedRecordsAccount';
    static String accountName1 = 'SurveyRelatedRecordsAccount1';
    static String surveyName = 'SQ-Test-Survey';
    static String surveyType = 'CSAT';
    static String surveyStatus = 'Active';
    static String surveyOpenedDate = '12/4/2012';
    
    /*
     Author : Sharath K
     Description: This method initialises data. CR
     Created Date: 13/4/2012
    */ 
    static void init() 
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        survey = CS_InitializeObjects.createSurvey(surveyName,surveyType,surveyStatus,surveyOpenedDate);
        insert survey;
        
        account = CS_InitializeObjects.createAccount(accountName);
        insert account;
        
        account1 = CS_InitializeObjects.createAccount(accountName1);
        insert account1;
        
        contact1 = CS_InitializeObjects.createContact('Test', 'Test1', account.Id, 'A-Test');
        contact1.Survey_Opt_Out__c = true;
        contact1.Network_Contact__c = false;
        insert contact1;
        
        contact2 = CS_InitializeObjects.createContact('Test', 'Test2', account.Id, 'A2-Test');
        contact2.Survey_Opt_Out__c = true;
        contact2.Network_Contact__c = false;
        insert contact2;
        
        contact3 = CS_InitializeObjects.createContact('Test', 'Test3', account.Id, 'A3-Test');
        contact3.Survey_Opt_Out__c = true;
        contact3.Network_Contact__c = false;
        insert contact3;
        
        surveyAccount = CS_InitializeObjects.createSurveyAccount(account1.Id,survey.Id);
        insert surveyAccount;
        
        surveyContact = CS_InitializeObjects.createSurveyContact(surveyAccount.Id,contact2.Id,survey.Id);
        insert surveyContact;
        
        surveyContact1 = CS_InitializeObjects.createSurveyContact(surveyAccount.Id,contact3.Id,survey.Id);
        insert surveyContact1;
        
        contact2.CS_AssociatedSurveyContact__c = surveyContact.Id;
        update contact2;
        
        contact3.CS_AssociatedSurveyContact__c = surveyContact1.Id;
        update contact3;
        
        account1.CS_SurveyAccount__c = surveyAccount.Id;
        update account1;
       
    }
    
    static testMethod void myTestMethod(){
        init();
        PageReference pg = new PageReference('/apex/CS_VfpCreateSurveyRelatedRecords?survey_id=' + survey.Id);
        Test.setCurrentPage(pg);
        test.startTest();
        CS_CreateSurveyRecordsController controller = new CS_CreateSurveyRecordsController();
        controller.akamContactsList = contact1.AKAM_Contact_ID__c ;
        controller.addContactsToSurvey();
        
        PageReference pg1 = new PageReference('/apex/CS_VfpDeleteSurveyRelatedRecords?survey_id=' + survey.Id);
        Test.setCurrentPage(pg1);
      
      //CS_DeleteSurveyRelatedRecords controller = new CS_DeleteSurveyRelatedRecords();
      //controller.akamContactsList = contact1.AKAM_Contact_ID__c ;
        controller.removeContactsFromSurvey();
        test.stopTest();
    }
}