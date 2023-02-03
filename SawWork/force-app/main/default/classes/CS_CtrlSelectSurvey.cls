/*
Author: Jayalakshmi
Version: 1.0
Created date: 04/18/2012
CR 1636762: Functionality to clone survey questionnare.
*/

public class CS_CtrlSelectSurvey
{
    public CS_Questionnare__c surveyName = new CS_Questionnare__c();
    public string testSurvey{get;set;}
    public string displaySurveyName{get;set;}
    public string displaySurveyStatus{get;set;}
    public date displaySurveyOpenedOn{get;set;}
    public date displaySurveyClosedOn{get;set;}
    string currentSurveyId;
    
    public CS_CtrlSelectSurvey(ApexPages.StandardController stdController)
    {
        currentSurveyId = ApexPages.currentPage().getParameters().get('surveyId');
        CS_Survey__c displaySurveyDetails = new CS_Survey__c();
        displaySurveyDetails = [select Name,CS_Status__c,CS_SurveyClosedOn__c,CS_SurveyOpenedOn__c from CS_Survey__c where Id = :currentSurveyId][0];
        displaySurveyName = displaySurveyDetails.Name;
        displaySurveyStatus = displaySurveyDetails.CS_Status__c;
        displaySurveyOpenedOn = displaySurveyDetails.CS_SurveyOpenedOn__c;
        displaySurveyClosedOn = displaySurveyDetails.CS_SurveyClosedOn__c;
    }
    
    /*Return the questionnare object*/
    public CS_Questionnare__c getSurveyName()
    {
        surveyName = new CS_Questionnare__c();
        return surveyName;
    }
    
    /*Clone logic to clone the questionnare and attach it to the selected survey.*/
    public PageReference populateQuestionnare()
    {
        try
        {
            string surveyId = surveyName.CS_Survey__c;
           // List<CS_Questionnare__c> dataExists = [select Id from CS_Questionnare__c where CS_SurveyId__c = :surveyId limit 1];
           /* if(dataExists.size()!=0)
            {
                ApexPages.Message myMsg1;
                myMsg1 = new ApexPages.Message(ApexPages.Severity.FATAL,'Questionnaire data already exists for the picked Survey record.');
                ApexPages.addMessage(myMsg1);
            }*/
            /*else
            {*/
            
            
            List<CS_Questionnare__c> dataExists = [select Id from CS_Questionnare__c where CS_Survey__c = :currentSurveyId limit 1];
            //System.assertEquals(dataExists.size(),10);
            if(dataExists.size()!=0)
            {
                ApexPages.Message myMsg1;
                myMsg1 = new ApexPages.Message(ApexPages.Severity.FATAL,'Questionnaire data already exists for the current Survey.');
                ApexPages.addMessage(myMsg1);
                return null;
            }
            else
            {
                string questionnareId;
                List<string> questionSetIdList = new List<string>();
                List<string> questionIdList = new List<string>();
                List<CS_Questionnare__c> questionnareToBeInserted = new List<CS_Questionnare__c>();
                List<CS_QuestionSet__c> questionSetToBeInserted = new List<CS_QuestionSet__c>();
                List<CS_SurveyQuestion__c> questionToBeInserted = new List<CS_SurveyQuestion__c>();
                CS_Questionnare__c newQuestionnare = new CS_Questionnare__c();
                
                Map<string,string> oldQuestionSetIdNewQuestionSetId = new Map<string,string>();
                List<string> oldQuestionSetIds = new List<string>();
                List<string> newQuestionSetIds = new List<string>();
                
                newQuestionnare.CS_SurveyId__c = CurrentSurveyId;
                newQuestionnare.CS_Survey__c = CurrentSurveyId;
                
                insert newQuestionnare;
                
                //questionnareId = [select Id from CS_Questionnare__c where CS_Survey__c = :surveyId][0].Id;
                
                for(CS_QuestionSet__c questionSet:[select Id,CS_QuestionSetName__c from CS_QuestionSet__c where CS_QuestionnareNumber__r.CS_Survey__c = :surveyId])
                {
                    CS_QuestionSet__c newQuestionSet = new CS_QuestionSet__c();
                    newQuestionSet.CS_QuestionnareNumber__c = newQuestionnare.Id;
                    newQuestionSet.CS_QuestionSetName__c = questionSet.CS_QuestionSetName__c;
                    questionSetToBeInserted.add(newQuestionSet);
                    questionSetIdList.add(questionSet.Id);
                    oldQuestionSetIds.add(questionSet.Id);
                }
                insert questionSetToBeInserted;
                    
                for(CS_QuestionSet__c questionSet:[select Id,CS_QuestionSetName__c from CS_QuestionSet__c where CS_QuestionnareNumber__c = :newQuestionnare.Id])
                {
                    newQuestionSetIds.add(questionSet.Id);
                }
                for(integer i=0;i<oldQuestionSetIds.size();i++)
                {
                    oldQuestionSetIdNewQuestionSetId.put(oldQuestionSetIds.get(i),newQuestionSetIds.get(i));
                }
                for(CS_SurveyQuestion__c question:[select Id,CS_QuestionSet__c,CS_QuestionNumber__c,CS_Question__c,CS_MapToField__c from CS_SurveyQuestion__c where CS_QuestionSet__c in :questionSetIdList])
                {
                    CS_SurveyQuestion__c newQuestion = new CS_SurveyQuestion__c();
                    newQuestion.CS_QuestionSet__c = oldQuestionSetIdNewQuestionSetId.get(question.CS_QuestionSet__c);
                    newQuestion.CS_QuestionNumber__c = question.CS_QuestionNumber__c;
                    newQuestion.CS_Question__c = question.CS_Question__c;
                    newQuestion.CS_MapToField__c = question.CS_MapToField__c;
                    
                    questionIdList.add(question.Id);
                    questionToBeInserted.add(newQuestion);
                }
                insert questionToBeInserted;
                
                PageReference navigateBackToSurvey = new PageReference('/'+currentSurveyId);
                return navigateBackToSurvey;
                return null;
            }
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg1;
            myMsg1 = new ApexPages.Message(ApexPages.Severity.FATAL, e.getMessage());
            ApexPages.addMessage(myMsg1);
            return null;
        }
    }
}