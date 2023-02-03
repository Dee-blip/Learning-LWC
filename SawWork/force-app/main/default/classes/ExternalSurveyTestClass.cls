@isTest(seeAllData = false)
public class ExternalSurveyTestClass
{
    static External_Survey_Form__c surveyForm;
    static ExternalSurveyConsoleController controller;
    static Account acct;
    static Contact customer;
    static External_Survey_Taken__c surveyTaken;
    static External_Survey_Question__c surveyQuestion;
    static External_Survey_Response__c surveyResponse;

    static {
        createData();
    }

    public static void createData() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);


        customer = new Contact();
        customer.FirstName = 'testFirst';
        customer.LastName = 'testLast';
        customer.email = 'testEmail@akamai.com';
        customer.accountId = acct.id;
        insert customer;

        surveyForm = new External_Survey_Form__c();
        surveyForm.Name = 'Survey1';
        surveyForm.Frequency__c = 12;
        surveyForm.From_Email__c = 'customerexperience@akamai.com';
        surveyForm.Reminder_Template__c = 'A gentle reminder to provide the feedback';
        surveyForm.Template__c = 'Please provide the feedback';
        surveyForm.Requested_By__c = 'Customer Experience';
        insert surveyForm;

        surveyQuestion = new External_Survey_Question__c();
        surveyQuestion.Question__c = 'Question From Test Class';
        surveyQuestion.Question_Type__c = 'Picklist';
        surveyQuestion.Question_Options__c = 'Opt 1 \n Opt 2';
        surveyQuestion.Question_Sequence__c = 1;
        surveyQuestion.External_Survey_Form__c = surveyForm.Id;
        surveyQuestion.UniqueName__c = '09RandomStringOnQuestion09';
        insert surveyQuestion;

        surveyTaken = new External_Survey_Taken__c();
        surveyTaken.External_Survey_Form__c = surveyForm.Id;
        surveyTaken.Contact__c = customer.Id;
        surveyTaken.Reminder_Email_Due_Date__c = System.today();
        insert surveyTaken;

        surveyResponse = new External_Survey_Response__c();
        surveyResponse.External_Survey_Question__c = surveyQuestion.Id;
        surveyResponse.External_Survey_Taken__c = surveyTaken.Id;
        insert surveyResponse;

    }

    @isTest static void testSendSurveyToCustomers(){
        Test.startTest();

        surveyTaken = [SELECT Id, Unique_Token__c FROM External_Survey_Taken__c WHERE Id =:surveyTaken.Id];
        Test.setCurrentPageReference(new PageReference('Page.ExternalSurveyPg'));
        ApexPages.currentPage().getParameters().put('id', surveyTaken.Id);
        ApexPages.currentPage().getParameters().put('securityToken', surveyTaken.Unique_Token__c);
        ExternalSurveyCtrl externalSurveyCtrl = new ExternalSurveyCtrl();
        externalSurveyCtrl.submitResponses();
        Test.stopTest();
    }

    @isTest
    static void testSurveyConsole()
    {
        Test.startTest();
        
        List<Id> contactIds = new List<Id>();
        contactIds.add(customer.Id);
        
        External_Survey_Question__c surveyQuestion2 = new External_Survey_Question__c();
        surveyQuestion2.Question__c = 'Question From Test Class';
        surveyQuestion2.Question_Type__c = 'Picklist';
        surveyQuestion2.Question_Options__c = 'Opt 1 \n Opt 2';
        surveyQuestion2.Question_Sequence__c = 1;
        surveyQuestion2.External_Survey_Form__c = surveyForm.Id;

        controller = new ExternalSurveyConsoleController();

        ApexPages.StandardController sc = new ApexPages.StandardController(new External_Survey_Form__c());
        PageReference pageRef = Page.ExternalSurveyConsole;

        Test.setCurrentPage(pageRef); 

        ApexPages.currentPage().getParameters().put('id', 'new');
        controller = new ExternalSurveyConsoleController(sc);
        controller.saveForm();

        ApexPages.currentPage().getParameters().put('id', surveyForm.Id);
        controller = new ExternalSurveyConsoleController(sc);
        
        String responseReport = controller.responseReport;
        String customerReport = controller.customerReport;
        List<ExternalSurveyConsoleController.questionWrapperClass> questions = controller.questions;
        Boolean locked = controller.lockedSurvey;
        Boolean closed = controller.closeSurvey;
        String message = controller.Message;
        Boolean newSurvey = controller.newSurvey;


        controller.saveForm();

        controller.cloneSurvey();

        controller.editAddQuestion();

        ApexPages.currentPage().getParameters().put('questionId', surveyQuestion.UniqueName__c);
        controller.editAddQuestion();

        controller.surveyQuestion = surveyQuestion2;
        controller.saveQuestion();

        controller.surveyQuestion = surveyQuestion;
        controller.saveQuestion();

        ApexPages.currentPage().getParameters().put('questionDeleteId', surveyQuestion.UniqueName__c);
        controller.deleteQuestion();

        controller.closeSurvey();        


        ExternalSurveyConsoleController.queryContacts('testEmail@akamai.com','Email');

        ExternalSurveyConsoleController.sendMail(contactIds,surveyForm.Id);

        controller = new ExternalSurveyConsoleController(sc);
        


        Test.stopTest();
    }
}