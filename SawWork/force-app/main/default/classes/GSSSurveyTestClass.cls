/**
 * Created by kusharma on 09/05/17.
 */

@isTest(SeeAllData=false)
public class GSSSurveyTestClass {
    Public static PSA_TestUtility testUtil;
    Public static pse__Region__c reg;
    Public static Account acct;
    Public static Contact resource;
    Public static Contact resource1;
    Public static pse__Project_Methodology__c  product1;
    Public static pse__Proj__c proj1;
    Public static pse__Practice__c pract;
    Public static Id practId;
    Public static pse__Milestone__c milestone;
    Public static pse__Assignment__c assign;
    Public static User usr;
    Public static User usr2;
    Public static Merge_Contract_Header__c contract;
    Public static Merge_Contract_Detail__c contDetail;
    Public static Project_Contract__c projCont;
    Public static Project_Contract_Line_Item__c projContItem;
    Public static pse__Schedule__c sched;
    Public static pse__Permission_Control__c pc;
    public static pse__Proj__c project;

    static {
        createTestData();
    }

    //The function which creates the test data: called from the static block
    Public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false);
        usr2 = testUtil.newUserSysAdmin(true);
        usr.ManagerId = usr2.id;
        insert usr;

        AccountTeamMember varATM = new AccountTeamMember(
                AccountId = acct.Id,
                UserId = UserInfo.getUserId(),
                TeamMemberRole = 'Services - Primary'
        );

        insert varATM;

        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;

         project = new pse__Proj__c(
                Name= 'Test Project',
                pse__Region__c = reg.id,
                pse__Practice__c = practId,
                pse__Is_Billable__c  = true,
                pse__Closed_for_Time_Entry__c = false,
                pse__Closed_for_Expense_Entry__c = false,
                pse__Stage__c = 'Closed',
                pse__Is_Active__c = true,
                pse__Allow_Timecards_Without_Assignment__c=true,
                pse__Allow_Expenses_Without_Assignment__c=true,
                CurrencyIsoCode = 'USD',
                pse__Project_Type__c = 'New Implementation',
                Project_Sub_Type__c = 'Akamai University',
                pse__Billing_Type__c = 'One-Time: Fixed Price',
                pse__Expense_Budget__c = 1000,
                pse__Start_Date__c = Date.today(),
                pse__End_Date__c = Date.today().addDays(1),
                Contract_Closed__c = 'No',
                pse__Project_Manager__c = resource.Id,
                pse__Account__c = acct.Id,
                pse__Planned_Hours__c = 1,
                Implementation_Complete__c = system.today().addDays(-2),
                Close_Code__c = 'Other',
                pse__Project_Status_Notes__c = 'Random text'
        );
        insert project;
        project.pse__Stage__c = 'Closed';
        update project;
        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        pse__Project_Methodology__c projectProduct = new pse__Project_Methodology__c(
                pse__Project__c = project.Id,
                Name = 'Bot Manager',
                Basic_Implementation_Complete__c = System.today().addDays(5),
                pse__Description__c = 'testmethodlogy',
                pse__Start_Date__c = System.today().addDays(-10),
                pse__End_Date__c = System.today().addDays(10),
                Product__c = 'Bot Manager'
        );
        insert projectProduct;



    }

    @isTest
    static void testSendSurveyToATMs(){
        Test.startTest();

        GSSSurvey_SendSurveyToUsers classInstanceToTest = new GSSSurvey_SendSurveyToUsers();
        classInstanceToTest.sendSurveyToATMs();

        Test.stopTest();
    }

    @isTest
    static void testSurveyCtrl1() {


        test.startTest();

        GSSSurvey_Survey_Form__c newSurveyFormToCreate = new GSSSurvey_Survey_Form__c();
        newSurveyFormToCreate.User__c = UserInfo.getUserId();
        newSurveyFormToCreate.Project__c = project.Id;
        newSurveyFormToCreate.Reminder_Date__c = System.now().addDays(7);
        newSurveyFormToCreate.Account__c = acct.Id;
        newSurveyFormToCreate.Security_Product_Name__c =  'Bot Manager';
        newSurveyFormToCreate.Response_Four__c = 'SA:: Exceeded Expectations\nTPM::Meet Expectations\nSSP::Needs Improvement\nSOC::Needs Improvement\nOther ::N/A';
        newSurveyFormToCreate.Response_Five__c = 'SA:: Exceeded Expectations\nTPM:: Exceeded Expectations\nSSP::Meet Expectations\nSOC:: N/A\nOther ::Needs Improvement';
        newSurveyFormToCreate.Response_Six__c = 'Prolexic Family::Custom Effort\nKona Family::Attack Monitoring/ Mitigation\nBot Manager::Integration/ Provisioning\nClient Reputation::Ongoing Service Management\nOther::N/A';
        newSurveyFormToCreate.Response_One__c = 'AMER';
        newSurveyFormToCreate.Response_Three__c ='YES';
        insert newSurveyFormToCreate;
        GSSSurvey_Survey_Form__c surveyDetailsToDisplay = [SELECT Id, OwnerId, IsDeleted, Name, Question_Two__c, Question_Four__c,Account__c,User__r.Name,
                Question_Five__c, Question_Six__c, Question_Seven__c, Question_Eight__c, Question_Nine__c, Question_Ten__c, Account__r.Division__c,
                Question_Eleven__c, Question_One__c, Question_Three__c, Choice_Question_One__c, Choice_Question_Three__c, Choice_Question_Four__c,
                Choice_Question_Five__c, Choice_Question_Six__c, Response_One__c, Response_Two__c, Response_Three__c, Response_Four__c,
                Response_Five__c, Response_Six__c, Response_Seven__c, Response_Eight__c, Response_Nine__c, Response_Ten__c, Response_Eleven__c,
                Project__c, User_Responded__c, User__c,Response_Four_1__c,Response_Four_2__c,Response_Four_3__c,Response_Four_4__c,Response_Four_5__c,
                Response_Five_1__c,Response_Five_2__c,Response_Five_3__c,Response_Five_4__c,Response_Five_5__c,Security_Product_Name__c,
                Response_Six_1__c,Response_Six_2__c,Response_Six_3__c,Response_Six_4__c,Response_Six_5__c,Account__r.Name
                FROM GSSSurvey_Survey_Form__c WHERE Id = :newSurveyFormToCreate.Id LIMIT 1];
        Test.setCurrentPageReference(new PageReference('Page.GSSSurveyForm'));
        ApexPages.currentPage().getParameters().put('Id', surveyDetailsToDisplay.Id);
        ApexPages.currentPage().getParameters().put('source', 'viewURL');
        ApexPages.StandardController sc = new ApexPages.standardController(surveyDetailsToDisplay);
        GSSSurveyFormCtrl gssCtrl = new GSSSurveyFormCtrl(sc);
        gssCtrl.surveyDetailsToDisplay = surveyDetailsToDisplay;
        gssCtrl.getSurveyDetailsForUser();
        List<SelectOption> lQues1 = gssCtrl.getQuestionOneChoices();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues4 = gssCtrl.getLQuesOptionFour();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues5 = gssCtrl.getLQuesFiveDetails();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues6 = gssCtrl.getLQuesSixDetails();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lHeaderDetail = gssCtrl.getLHeaderDetails();
        gssCtrl.setResponseQuestionOne('AMER');
        gssCtrl.setResponseQuestionThree('YES');
        String responseQ1 = gssCtrl.getResponseQuestionOne();
        String responseQ3 = gssCtrl.getResponseQuestionThree();
        List<SelectOption> lChoice3 = gssCtrl.getQuestionThreeChoices();
        gssCtrl.printResults();

        test.stopTest();



    }

    @isTest
    static void testSurveyCtrl2() {


        test.startTest();

        GSSSurvey_Survey_Form__c newSurveyFormToCreate = new GSSSurvey_Survey_Form__c();
        newSurveyFormToCreate.User__c = UserInfo.getUserId();
        newSurveyFormToCreate.Project__c = project.Id;
        newSurveyFormToCreate.Reminder_Date__c = System.now().addDays(7);
        newSurveyFormToCreate.Account__c = acct.Id;
        newSurveyFormToCreate.Security_Product_Name__c =  'Bot Manager';
        newSurveyFormToCreate.Response_Four__c = 'SA:: N/A\nTPM::N/A\nSSP::N/A\nSOC::N/A\nOther ::Needs Improvement';
        newSurveyFormToCreate.Response_Five__c = 'SA:: N/A\nTPM:: N/A\nSSP::N/A\nSOC:: Needs Improvement\nOther ::N/A';
        newSurveyFormToCreate.Response_Six__c = 'Prolexic Family::N/A\nKona Family::N/A\nBot Manager::N/A\nClient Reputation::N/A\nOther::Ongoing Service Management';
        newSurveyFormToCreate.Response_One__c = 'AMER';
        newSurveyFormToCreate.Response_Three__c ='YES';
        newSurveyFormToCreate.User_Responded__c = true;
        insert newSurveyFormToCreate;
        GSSSurvey_Survey_Form__c surveyDetailsToDisplay = [SELECT Id, OwnerId, IsDeleted, Name, Question_Two__c, Question_Four__c,Account__c,User__r.Name,
                Question_Five__c, Question_Six__c, Question_Seven__c, Question_Eight__c, Question_Nine__c, Question_Ten__c, Account__r.Division__c,
                Question_Eleven__c, Question_One__c, Question_Three__c, Choice_Question_One__c, Choice_Question_Three__c, Choice_Question_Four__c,
                Choice_Question_Five__c, Choice_Question_Six__c, Response_One__c, Response_Two__c, Response_Three__c, Response_Four__c,
                Response_Five__c, Response_Six__c, Response_Seven__c, Response_Eight__c, Response_Nine__c, Response_Ten__c, Response_Eleven__c,
                Project__c, User_Responded__c, User__c,Response_Four_1__c,Response_Four_2__c,Response_Four_3__c,Response_Four_4__c,Response_Four_5__c,
                Response_Five_1__c,Response_Five_2__c,Response_Five_3__c,Response_Five_4__c,Response_Five_5__c,Security_Product_Name__c,
                Response_Six_1__c,Response_Six_2__c,Response_Six_3__c,Response_Six_4__c,Response_Six_5__c,Account__r.Name
                FROM GSSSurvey_Survey_Form__c WHERE Id = :newSurveyFormToCreate.Id LIMIT 1];

        Test.setCurrentPageReference(new PageReference('Page.GSSSurveyForm'));
        ApexPages.currentPage().getParameters().put('Id', surveyDetailsToDisplay.Id);
        ApexPages.currentPage().getParameters().put('source', 'email');
        ApexPages.StandardController sc = new ApexPages.standardController(surveyDetailsToDisplay);
        GSSSurveyFormCtrl gssCtrl = new GSSSurveyFormCtrl(sc);
        gssCtrl.surveyDetailsToDisplay = surveyDetailsToDisplay;
        gssCtrl.getSurveyDetailsForUser();
        List<SelectOption> lQues1 = gssCtrl.getQuestionOneChoices();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues4 = gssCtrl.getLQuesOptionFour();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues5 = gssCtrl.getLQuesFiveDetails();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues6 = gssCtrl.getLQuesSixDetails();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lHeaderDetail = gssCtrl.getLHeaderDetails();
        gssCtrl.setResponseQuestionOne('AMER');
        gssCtrl.setResponseQuestionThree('YES');
        String responseQ1 = gssCtrl.getResponseQuestionOne();
        String responseQ3 = gssCtrl.getResponseQuestionThree();
        List<SelectOption> lChoice3 = gssCtrl.getQuestionThreeChoices();
        gssCtrl.printResults();

        test.stopTest();



    }

    @isTest
    static void testSurveyCtrl3() {


        test.startTest();

        GSSSurvey_Survey_Form__c newSurveyFormToCreate = new GSSSurvey_Survey_Form__c();
        newSurveyFormToCreate.User__c = UserInfo.getUserId();
        newSurveyFormToCreate.Project__c = project.Id;
        newSurveyFormToCreate.Reminder_Date__c = System.now().addDays(7);
        newSurveyFormToCreate.Account__c = acct.Id;
        newSurveyFormToCreate.Security_Product_Name__c =  'Bot Manager';
        newSurveyFormToCreate.Response_Four__c = 'SA:: N/A\nTPM::N/A\nSSP::N/A\nSOC::N/A\nOther ::Needs Improvement';
        newSurveyFormToCreate.Response_Five__c = 'SA:: N/A\nTPM:: N/A\nSSP::N/A\nSOC:: Needs Improvement\nOther ::N/A';
        newSurveyFormToCreate.Response_Six__c = 'Prolexic Family::N/A\nKona Family::N/A\nBot Manager::N/A\nClient Reputation::N/A\nOther::Ongoing Service Management';
        newSurveyFormToCreate.Response_One__c = 'AMER';
        newSurveyFormToCreate.Response_Three__c ='YES';
        newSurveyFormToCreate.User_Responded__c = false;
        insert newSurveyFormToCreate;
        GSSSurvey_Survey_Form__c surveyDetailsToDisplay = [SELECT Id, OwnerId, IsDeleted, Name, Question_Two__c, Question_Four__c,Account__c,User__r.Name,
                Question_Five__c, Question_Six__c, Question_Seven__c, Question_Eight__c, Question_Nine__c, Question_Ten__c, Account__r.Division__c,
                Question_Eleven__c, Question_One__c, Question_Three__c, Choice_Question_One__c, Choice_Question_Three__c, Choice_Question_Four__c,
                Choice_Question_Five__c, Choice_Question_Six__c, Response_One__c, Response_Two__c, Response_Three__c, Response_Four__c,
                Response_Five__c, Response_Six__c, Response_Seven__c, Response_Eight__c, Response_Nine__c, Response_Ten__c, Response_Eleven__c,
                Project__c, User_Responded__c, User__c,Response_Four_1__c,Response_Four_2__c,Response_Four_3__c,Response_Four_4__c,Response_Four_5__c,
                Response_Five_1__c,Response_Five_2__c,Response_Five_3__c,Response_Five_4__c,Response_Five_5__c,Security_Product_Name__c,
                Response_Six_1__c,Response_Six_2__c,Response_Six_3__c,Response_Six_4__c,Response_Six_5__c,Account__r.Name
        FROM GSSSurvey_Survey_Form__c WHERE Id = :newSurveyFormToCreate.Id LIMIT 1];

        Test.setCurrentPageReference(new PageReference('Page.GSSSurveyForm'));
        ApexPages.currentPage().getParameters().put('Id', surveyDetailsToDisplay.Id);
        ApexPages.currentPage().getParameters().put('source', 'email');
        ApexPages.StandardController sc = new ApexPages.standardController(surveyDetailsToDisplay);
        GSSSurveyFormCtrl gssCtrl = new GSSSurveyFormCtrl(sc);
        gssCtrl.surveyDetailsToDisplay = surveyDetailsToDisplay;
        gssCtrl.getSurveyDetailsForUser();
        List<SelectOption> lQues1 = gssCtrl.getQuestionOneChoices();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues4 = gssCtrl.getLQuesOptionFour();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues5 = gssCtrl.getLQuesFiveDetails();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lQues6 = gssCtrl.getLQuesSixDetails();
        List<GSSSurveyFormCtrl.GridQuestionResponseWrapper> lHeaderDetail = gssCtrl.getLHeaderDetails();
        gssCtrl.setResponseQuestionOne('AMER');
        gssCtrl.setResponseQuestionThree('YES');
        String responseQ1 = gssCtrl.getResponseQuestionOne();
        String responseQ3 = gssCtrl.getResponseQuestionThree();
        List<SelectOption> lChoice3 = gssCtrl.getQuestionThreeChoices();
        gssCtrl.printResults();

        test.stopTest();



    }

}