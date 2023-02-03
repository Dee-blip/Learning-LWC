@isTest(SeeAllData = false)
public class RSSTemplateTest
{
    public static Survey__c RSSTemplate;
    static RSSEditTemplateController controller;
    public static testMethod void initClass()
    {

    RSSTemplate = new Survey__c();
    RSSTemplate.Name ='Apple';
    RSSTemplate.RecordTypeId = [select id from RecordType where name = 'RSS Template' limit 1][0].id; //Need to have a record Type RSS Template
    RSSTemplate.UniqueName__c = GuidUtil.NewGuid();
    RSSTemplate.Submit_Response__c = ' temp ';
    RSSTemplate.Version__c = 0;
    insert RSSTemplate;
        
    ApexPages.StandardController sc = new ApexPages.StandardController(RSSTemplate);
    
    PageReference pageRef = Page.RSSEditTemplate;
    pageRef.getParameters().put('id',RSSTemplate.id);
    Test.setCurrentPage(pageRef);
    controller = new RSSEditTemplateController(sc);
    controller.NewGroupname = 'Test Group 1';
    controller.createNewQuestionGroup();
    controller.NewGroupname = 'Test Group 2';
    controller.createNewQuestionGroup();
    controller.qQuestion.Name = 'Question 1';
    controller.qQuestion.Survey__c = controller.surveyRef;
    controller.qQuestion.Choices__c = '1\n2\n3\n4\n5';
    controller.qQuestion.Required__c =  True;
    controller.qQuestion.Type__c =  'Picklist';
    controller.questionType =  'Picklist';
    /*
    Single Select--Vertical
    Single Select--Horizontal
    Multi-Select--Vertical
    Free Text
    Picklist*/
    controller.qQuestion.OrderNumber__c =  0;
    controller.qQuestion.Question__c = 'Question 1';
    controller.qQuestion.QuestionDescription__c = 'Test Description';
    controller.questionGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    
    controller.createNewQuestion();
    
    controller.qQuestion.Name = 'Question 2';
    controller.qQuestion.Survey__c = controller.surveyRef;
    controller.qQuestion.Choices__c = '1\n2\n3\n4\n5';
    controller.qQuestion.Required__c =  True;
    controller.qQuestion.Type__c =  'Single Select--Vertical';
    controller.questionType ='Single Select--Vertical';
    /*
    Single Select--Vertical
    Single Select--Horizontal
    Multi-Select--Vertical
    Free Text
    Picklist*/
    controller.qQuestion.OrderNumber__c =  1;
    controller.qQuestion.Question__c = 'Question 2';
    controller.qQuestion.QuestionDescription__c = 'Test Description';
    controller.questionGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.createNewQuestion();
    
    controller.qQuestion.Name = 'Question 3';
    controller.qQuestion.Survey__c = controller.surveyRef;
    controller.qQuestion.Choices__c = '1\n2\n3\n4\n5';
    controller.qQuestion.Required__c =  True;
    controller.qQuestion.Type__c =  'Single Select--Horizontal';
    controller.questionType ='Single Select--Horizontal';
    /*
    Single Select--Vertical
    Single Select--Horizontal
    Multi-Select--Vertical
    Free Text
    Picklist*/
    controller.qQuestion.OrderNumber__c =  2;
    controller.qQuestion.Question__c = 'Question 3';
    controller.qQuestion.QuestionDescription__c = 'Test Description';
    controller.questionGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.createNewQuestion();
    
    
    controller.qQuestion.Name = 'Question 4';
    controller.qQuestion.Survey__c = controller.surveyRef;
    controller.qQuestion.Choices__c = '1\n2\n3\n4\n5';
    controller.qQuestion.Required__c =  True;
    Controller.qQUestion.Question__c = ' testtesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttesttest';
    controller.qQuestion.Type__c =  'Multi-Select--Vertical';
    controller.questionType ='Multi-Select--Vertical';
    /*
    Single Select--Vertical
    Single Select--Horizontal
    Multi-Select--Vertical
    Free Text
    Picklist*/
    controller.qQuestion.OrderNumber__c =  3;
    controller.qQuestion.QuestionDescription__c = 'Test Description';
    controller.questionGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.createNewQuestion();
    
    controller.qQuestion.Name = 'Question 5';
    controller.qQuestion.Survey__c = controller.surveyRef;
    controller.qQuestion.Choices__c = '';
    controller.qQuestion.Required__c =  True;
    controller.qQuestion.Type__c =  'Free Text';
    controller.questionType = 'Free Text';
    /*
    Single Select--Vertical
    Single Select--Horizontal
    Multi-Select--Vertical
    Free Text
    Picklist*/
    Survey_Question__c tempQuestion  = controller.qQuestion;
    controller.qQuestion.OrderNumber__c =  4;
    controller.qQuestion.Question__c = 'Question 5';
    controller.qQuestion.QuestionDescription__c = 'Test Description';
    controller.questionGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.createNewQuestion();
    RSSQuestionGroupWrapper tempGroupWrapper = new RSSQuestionGroupWrapper();
    
    controller.EditQuestionGroupUniqueName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.NewGroupname = 'Test Group 1 Updated';
    controller.updateQuestionGroup();
    
    controller.questionReference ='adas';
    controller.EditQuestionUniqueGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.EditQuestionUniqueName = controller.QuestionGroupWrappers[0].surveyQuestions[0].UniqueName;
    
    controller.editQuestion();
    controller.updateQuestion();
    
    controller.questionReference ='adas';
    controller.EditQuestionUniqueGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.EditQuestionUniqueName = controller.QuestionGroupWrappers[0].surveyQuestions[4].UniqueName;
    controller.editQuestion();
    controller.updateQuestion();

    controller.EditQuestionUniqueGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.EditQuestionUniqueName = controller.QuestionGroupWrappers[0].surveyQuestions[4].UniqueName;
    controller.deleteQuestion();
    
    controller.DeleteQuestionUniqueGroupName = controller.QuestionGroupWrappers[1].UniqueName;
    controller.deleteQuestionGroup();
    
    controller.questionReference ='adas';    
    controller.controllerSavQuestion();
    controller.qQuestion = tempQuestion;
    controller.controllerSavQuestion();
    
    controller.UpdateQuestionGroupName='ddd';
    controller.EditQuestionGroupUniqueName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.editQuestionGroup();
    
    
    controller.UpdateQuestionGroupName = controller.QuestionGroupWrappers[0].UniqueName;
    controller.controllerSavQuestionGroup();
    controller.NewGroupname = 'Test Group 3';
    controller.controllerSavQuestionGroup();
    
    controller.EditRSSTemplateDetails();
    controller.UpdateRSSTemplateDetails();
    controller.getSizeOfQuestionWrapper();
    controller.SaveTemplate();
    controller.PublishTemplate();
    controller.clearFields();
    controller.CreateNewVersion();
    controller.setupQuestionGroupsAndQuestions();
    controller.StartSaving();
    controller.StopSaving();
    
    }
    
    public static testMethod void eRSSQuestionCloneTest()
    {
        test.startTest();
        initClass();
        test.stopTest();
        
        List<Survey_Question__c> lSurveyQuestion = new List<Survey_Question__c>();
        for(Survey_Question__c objSurveyQuestion: [SELECT Id,Question__c FROM Survey_Question__c LIMIT 10])
        {
            objSurveyQuestion.Question__c = 'Update Question Name';
            lSurveyQuestion.add(objSurveyQuestion);
        }
        
        database.update(lSurveyQuestion,false);
    }
}