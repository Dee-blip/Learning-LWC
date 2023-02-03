/*
Author: Jayalakshmi A & Sharath K
Description: Contains test cases for CS_CustomButtonMethods. CR# 1416592,1430119
Created Date: 12/1/2011
*/

@isTest
private class CS_CustomButtonMethods_Test 
{
	static CS_Survey__c survey;
	static CS_SurveyAccount__c surveyAccount;
	static CS_SurveyContacts__c surveyContact;
	static Account account;
	static Contact contact;
	static String accountName = 'TestAccount';
	static String surveyName = 'SQ-Test-Survey';
	static String surveyType = 'Test';
	static String surveyStatus = 'Active';
	static String surveyOpenedDate = '12/5/2011';
	
	/*
     Author : Jayalakshmi A & Sharath K
     Description: This method initialises data. CR 1416592,1430119
     Created Date: 12/1/2011
    */ 
    static testMethod void init() 
    {
		ManagedPkgErrorClass.isFromManagedPackage=false;
        survey = CS_InitializeObjects.createSurvey(surveyName,surveyType,surveyStatus,surveyOpenedDate);
        insert survey;
        
        account = CS_InitializeObjects.createAccount(accountName);
        insert account;
        
        contact = CS_InitializeObjects.createContact('Test', 'Test1', account.Id, 'A-Test');
        insert contact;
        
        surveyAccount = CS_InitializeObjects.createSurveyAccount(account.Id, survey.Id);
        insert surveyAccount;
        
        surveyContact = CS_InitializeObjects.createSurveyContact(surveyAccount.Id, contact.Id, survey.Id);
        insert surveyContact;
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method tests the deletion of Survey Account for the Survey Account created in the init method. CR 1416592
     Created Date: 12/1/2011
    */ 
    static testMethod void testDeleteSurveyAccount()
    {
    	init();
    	CS_CustomButtonMethods.deleteSurveyAccount(surveyAccount.Id);
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method tests the deletion of Survey Contact for the Survey Contact created in the init method. CR 1416592
     Created Date: 12/1/2011
    */ 
    static testMethod void testDeleteSurveyContact()
    {
    	init();
    	CS_CustomButtonMethods.deleteSurveyContact(surveyContact.Id);
    }
    
    /*
     Author : Sharath
     Description:CR 1430119- This method tests association between an account and latest survey account record
     Created Date: 12/1/2011
    */
    static testMethod void testAssociateSurveyAccount()
    {
    	init();
    	CS_CustomButtonMethods.associateSurveyAccount(surveyAccount.Id);
    }
    
    /*
     Author : Sharath
     Description:CR 1430119- This method tests the resetting of the associated survey account field ast account level
     Created Date: 12/1/2011
    */
    static testMethod void testRemoveSurveyAccountAssociation()
    {
    	init();
    	CS_CustomButtonMethods.removeSurveyAccountAssociation(surveyAccount.Id);
    }
    
    /*
     Author : Sharath
     Description:CR 1430119- This method tests the association between a contact and survey contact record
     Created Date: 12/1/2011
    */
    static testMethod void testAssociateSurveyContact()
    {
    	init();
    	CS_CustomButtonMethods.associateSurveyContact(surveyContact.Id);
    }
    
    /*
     Author : Sharath
     Description:CR 1430119- This method tests the resetting of associated survey contact field and currently surveyed flag
     Created Date: 12/1/2011
    */
    static testMethod void testRemoveSurveyContactAssociation()
    {
    	init();
    	CS_CustomButtonMethods.removeSurveyContactAssociation(surveyContact.Id);
    }
    
    static testmethod void testExceptionBlocks(){
    	init();
    	// calling all button methods with ivalid survey account/survey contact id
    	CS_CustomButtonMethods.removeSurveyContactAssociation('a1726181722');
    	CS_CustomButtonMethods.associateSurveyContact('a1726181722');
    	CS_CustomButtonMethods.removeSurveyAccountAssociation('a1726181722');
    	CS_CustomButtonMethods.associateSurveyAccount('a1726181722');
    	CS_CustomButtonMethods.deleteSurveyAccount('a1726181722');
    	CS_CustomButtonMethods.deleteSurveyContact('a1726181722');
    }
}