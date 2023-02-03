/*
Author: Jayalakshmi
Version: 1.0
Created date: 04/18/2012
CR 1636762: Functionality to clone survey questionnare.
*/

@isTest
private class CS_CtrlSelectSurvey_Test 
{
    static CS_Survey__c survey1;
    static CS_Survey__c survey2;
    static String surveyName = 'SQ-Test-Survey';
    static String surveyType = 'Test';
    static String surveyStatus = 'Active';
    static String surveyOpenedDate = '12/5/2011';
    static CS_SurveyResponse__c surveyResponse1;
    static CS_SurveyQuestion__c surveyQuestion;
    static String mapToField = '';
    static String surveyResponseName = 'SurveyResponse1';
    static CS_Questionnare__c questionnare;
    static CS_QuestionSet__c questionSet;
    static ApexPages.StandardController stdController;
    
    /*
	Author: Jayalakshmi
	Created date: 04/18/2012
	Description: Initialize the required data
	*/
    
     static testMethod void init() 
     {
		ManagedPkgErrorClass.isFromManagedPackage=false;
        CS_FieldMapping__c orgValues = CS_FieldMapping__c.getOrgDefaults();
        survey1 = CS_InitializeObjects.createSurvey(surveyName,surveyType,surveyStatus,surveyOpenedDate);
        insert survey1;
        
        survey2 = CS_InitializeObjects.createSurvey('SQ-Test-Survey2',surveyType,surveyStatus,surveyOpenedDate);
        insert survey2;
        
        questionnare = CS_InitializeObjects.createSurveyQuestionnare(survey2.Id);
        database.insert(questionnare);
        
        questionSet = CS_InitializeObjects.createSurveyQuestionSet(questionnare.Id,'Default Question Set');
        questionSet.CS_QuestionnareNumber__r = questionnare;
        questionSet.CS_QuestionnareNumber__r.CS_Survey__c = survey2.Id;
        database.insert(questionSet);
        
        surveyResponse1 = CS_InitializeObjects.createSurveyResponse(surveyResponseName,survey2.Id,'New');
        insert surveyResponse1;
        
        surveyQuestion = CS_InitializeObjects.createSurveyQuestion('likelihood to recommend Akamai',orgValues.CS_NPSMapping__c,1,questionSet.Id);
        insert surveyQuestion;
    }
    
    /*
	Author: Jayalakshmi A
	Created date: 04/18/2012
	Description: Invoke methods from the main class to clone questionnare data
	*/
    static testMethod void testPopulateQuestionnare()
    {
        init();
        ApexPages.currentPage().getParameters().put('surveyId',survey1.id);
        CS_CtrlSelectSurvey selectSurvey = new CS_CtrlSelectSurvey(stdController);
        selectSurvey.surveyName.CS_Survey__c = survey2.Id;
        CS_Questionnare__c ques = selectSurvey.getSurveyName();
        selectSurvey.populateQuestionnare();
    }
}