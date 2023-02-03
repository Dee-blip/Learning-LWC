/***
    Test class: CS_PopulateMaster_Test
    @version 1.0
    @author Jayalakshmi Anantharaman (janantha@akamai.com)
    @date 01/03/2010
    @description This is a test class for testing the functionality of CS_PopulateMaster trigger 
    @Modified date: CR 1115769
    19th May 2011 for testing the flow of the trigger when two survey responses are created with the same created date and time.             
*/ 

@isTest
private class CS_PopulateMaster_Test
{ 
    /*Method: positiveTest
      @version 1.0
      @author Jayalakshmi Anantharaman (janantha@akamai.com)
      @date 01/03/2010
      @description This is a test case for the trigger CS_PopulateMaster, where a 
      Survey Response record which is in 'New' status is present*/
      
    static testMethod void Test()
    {
		ManagedPkgErrorClass.isFromManagedPackage=false;
        CS_Survey__c survey = new CS_Survey__c();
        survey.Name = 'Feb/Nov2011';
        survey.CS_Type__c = 'CSAT';
        survey.CS_Status__c = 'Active';
		// modified - 06/13/2011 . The following piece of line has been added to negate the validation rule ( Survey Opened On must be populated if survey Status = 'Active')
        survey.CS_SurveyOpenedOn__c = Date.parse('02/20/2011');
        Database.insert(survey);
        //start of changes for CR CR 1115769
        List<CS_SurveyResponse__c> surveyResponse = new List<CS_SurveyResponse__c>();
        CS_SurveyResponse__c surveyResponse1 = new CS_SurveyResponse__c();
        CS_SurveyResponse__c surveyResponse2 = new CS_SurveyResponse__c();
        surveyResponse1.Name = 'SFeb/Aug-022011';
        surveyResponse1.CS_Survey__c = survey.Id;
        surveyResponse1.CS_SyncStatus__c = 'New';
        surveyResponse2.Name = 'SFeb/Aug-022011';
        surveyResponse2.CS_Survey__c = survey.Id;
        surveyResponse2.CS_SyncStatus__c = 'New';
        surveyResponse.add(surveyResponse1);
        surveyResponse.add(surveyResponse2);
        Database.insert(surveyResponse);
        //end of changes for CR CR 1115769
        List<CS_SurveyResponseNameValue__c> surveyNameValue = new List<CS_SurveyResponseNameValue__c>();
        CS_SurveyResponseNameValue__c nameVal1 = new CS_SurveyResponseNameValue__c();
        nameVal1.CS_SyncStatusMessage__c = 'Testing Triggers1';
        nameVal1.CS_RecordId__c = '1';
        nameVal1.CS_ExternalId__c = '11';
        surveyNameValue.add(nameVal1);
        CS_SurveyResponseNameValue__c nameVal2 = new CS_SurveyResponseNameValue__c();
        nameVal2.CS_SyncStatusMessage__c = 'Testing Triggers2';
        nameVal2.CS_RecordId__c = '2';
        nameVal2.CS_ExternalId__c = '22';
        surveyNameValue.add(nameVal2);
        insert surveyNameValue;
    }
}