/*
Author: Jayalakshmi A
Description: Contains methos to Activate and close survey. CR 1636771
Created Date: 18/04/2012
*/

global class CS_ChangeSurveyStatus
{
    /*
        Author: Jayalakshmi A
        Description: This method activates the survey and populates the Survey Opened On field to today's date
        Created Date: 18/04/2012
    */
    webservice static void activateSurvey(string surveyId)
    {
        try
        {
            CS_Survey__c survey = [select Id,CS_Status__c,CS_SurveyOpenedOn__c from CS_Survey__c where Id=:surveyId];
            survey.CS_Status__c = 'Active';
            survey.CS_SurveyOpenedOn__c = System.today();
            update survey;
        }
        catch(Exception e)
        {
        }
    }
    
    /*
        Author: Jayalakshmi A
        Description: This method closes the survey and populates the Survey closed On field to today's date
        Created Date: 18/04/2012
    */
    webservice static void closeSurvey(string surveyId)
    {
        try
        {
            CS_Survey__c survey = [select Id,CS_Status__c,CS_SurveyClosedOn__c from CS_Survey__c where Id=:surveyId];
            survey.CS_Status__c = 'Closed';
            survey.CS_SurveyClosedOn__c = System.today();
            update survey;
        }
        catch(Exception e)
        {
        }
    }
}