/*
Author: Jayalakshmi A
Description: Contains test cases for CS_ChangeSurveyStatus. CR 1636771
Created Date: 12/1/2011
*/

@isTest
private class CS_ChangeSurveyStatus_Test 
{
    static CS_Survey__c survey1;
    static String surveyName = 'SQ-Test-Survey';
    static String surveyType = 'Test';
    static String surveyStatus = 'Active';
    static String surveyOpenedDate = '12/5/2011';
    static Date surveyClosedDate = System.today();
    
    static CS_Survey__c survey2;
    static String surveyName2 = 'SQ-Test-Survey';
    static String surveyType2 = 'Test';
    static String surveyStatus2 = 'Inactive';
    static String surveyOpenedDate2 = '12/5/2011';
    
    /*
        Author: Jayalakshmi A
        Description: This method initializes the test data.
        Created Date: 12/1/2011
    */
    static testMethod void init() 
    {
		ManagedPkgErrorClass.isFromManagedPackage=false;
        survey1 = CS_InitializeObjects.createSurvey(surveyName,surveyType,surveyStatus,surveyOpenedDate);
        survey1.CS_SurveyClosedOn__c = surveyClosedDate;
        insert survey1;
        
        survey2 = CS_InitializeObjects.createSurvey(surveyName2,surveyType2,surveyStatus2,surveyOpenedDate2);
        insert survey2;
    }
    
    /*
        Author: Jayalakshmi A
        Description: This method invokes the methos in CS_ChangeSurveyStatus
        Created Date: 12/1/2011
    */
    static testMethod void testChangeSurveyStatus()
    {
        init();
        CS_ChangeSurveyStatus.activateSurvey(survey2.Id);
        CS_ChangeSurveyStatus.closeSurvey(survey1.Id);
    }
}