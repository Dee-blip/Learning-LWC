/*
Author: Sharath
Created: 1/19/2011
Description: Test class to check if Survey details page is working as expected
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
Modified: Sharath 03/20/2011 
- Changes in CS_InitializeObjects. so changes required here.
Modified: Sharath 05/19/2011
- Changes to CS_InitializeObjects and CS_MapSurveyQuestionsAndAnswers for CR 1112835 CSAT: Contacts Update Apex Job to directly update Survey Contacts 
Modified: Janantha 06/16/2011
CR 1159273: To display historical survey data
*/
@isTest
private class CS_MapSurveyQuestionsAndAnswers_Test{
static CS_Survey__c testSurvey;
static CS_SurveyResponse__c testSurveyResponse;
static List<CS_SurveyResponseNameValue__c> testNVRows = new List<CS_SurveyResponseNameValue__c>();
static CS_SurveyResponseNameValue__c nvRow;
static Account accOld;
static Contact con1;
static contact con2;
static CS_SurveyQuestion__c q;
static List<CS_SurveyQuestion__c> questions = new List<CS_SurveyQuestion__c>();
static CS_QuestionSet__c questionSet;
static CS_Questionnare__c questionnare; 
static CS_SurveyAccount__c surveyAcc01;
static CS_SurveyAccount__c surveyAcc02;
static CS_SurveyContacts__c surveyCon01;
static CS_SurveyContacts__c surveyCon02;

static void init(){
	ManagedPkgErrorClass.isFromManagedPackage=false;
    // create an active survey
    /*  CR 1140535 - Adding additional parameter - "surveyOpenedDate"   */
    testSurvey = CS_InitializeObjects.createSurvey('Feb/Nov2011', 'CSAT', 'Active','3/15/2011');
    Database.insert(testSurvey);
    
    //create a survey response for that survey
    testSurveyResponse = CS_InitializeObjects.createSurveyResponse('SFeb/Aug-022011',testSurvey.Id,'New');
    Database.insert(testSurveyResponse);
    
    //create Account for testing purpose
    accOld = CS_InitializeObjects.createAccount('TestAccount_01'); 
    Database.insert(accOld); 
    
    //create Contacts for testing purpose
    con1 = CS_InitializeObjects.createContact('Fname','Lname',accOld.Id,'abc-1234');
    Database.insert(con1);
    
    con2 = CS_InitializeObjects.createContact('Fname','Lname',accOld.Id, 'xyz-1234');
    Database.insert(con2);
    
    //create Survey Account for testing purpose
    surveyAcc01 = CS_InitializeObjects.createSurveyAccount(accOld.Id,testSurvey.Id);
    Database.insert(surveyAcc01);
    
    //create Survey Contact for testing purpose
    surveyCon01 = CS_InitializeObjects.createSurveyContact(surveyAcc01.Id,con1.Id,testSurvey.Id);
    Database.insert(surveyCon01);
    surveyCon01.CS_SurveyResponseSyncId__c = testSurveyResponse.Id;
    database.update(surveyCon01);
    surveyCon02 = CS_InitializeObjects.createSurveyContact(surveyAcc01.Id,con2.Id,testSurvey.Id);
    Database.insert(surveyCon02);
    surveyCon02.CS_SurveyResponseSyncId__c = testSurveyResponse.Id;
    database.update(surveyCon02);
    
    // associate Contact with Survey Contact - so that the new fields at contact will be able to retreive info from Survey Contact
    con1.CS_AssociatedSurveyContact__c = surveyCon01.Id;
    con1.CS_CurrentlySurveyed__c = true;
    Database.update(con1);
    
    CS_FieldMapping__c orgValues = CS_FieldMapping__c.getOrgDefaults();
    
    // create name-value pairs for the active survey, survey response
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ConactIDMapping__c,con1.akam_contact_id__c , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_NPSMapping__c, '10,Very Likely', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_SalesProcessMapping__c,'5' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_EdgeControlSatisfactionMapping__c,'9' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_OverallSatisfactionMapping__c, '9','2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ProductSatisfactionMapping__c, '8', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ImplementationProcessMapping__c, '1, vey bad', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_BusinessSupportMapping__c, '8', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_AccountIdMapping__c ,accOld.Id , '2', 'Pending');
    testNVRows.add(nvRow);
    
    //name-value records for 2nd contact
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ConactIDMapping__c, con2.akam_contact_id__c, '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_NPSMapping__c, '3', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_SalesProcessMapping__c, '5' , '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_EdgeControlSatisfactionMapping__c,'9' , '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ProductSatisfactionMapping__c, '7', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_OverallSatisfactionMapping__c, '0', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_BusinessSupportMapping__c, '10', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_ImplementationProcessMapping__c , '9', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_AccountIdMapping__c , accOld.Id, '3', 'Pending');
    testNVRows.add(nvRow);
    
    database.insert(testNVRows);
    
    //initialize the surveyQuestionnare, question Set and SurveyQuestions table
    /*
    04/01/2011 - changes in CS_Initialize objects. so had to make necessary changes here.
    */
    questionnare = CS_InitializeObjects.createSurveyQuestionnare(testSurvey.Id);
    database.insert(questionnare);
    questionSet = CS_InitializeObjects.createSurveyQuestionSet(questionnare.Id,'Default Question Set');
    database.insert(questionSet);
    q = CS_InitializeObjects.createSurveyQuestion('How likely are you to recommend Akamai to others?' , orgValues.CS_NPSMapping__c ,1,questionSet.Id);
    questions.add(q);
    q = CS_InitializeObjects.createSurveyQuestion('overall satisfaction with akamai' , orgValues.CS_OverallSatisfactionMapping__c ,2, questionSet.Id);
    questions.add(q);
    database.insert(questions);
    
    }
    
    static testMethod void myPositiveTest(){
    init();
    PageReference surveyDetailsPage = Page.CS_VfpSurveyDetails;
    Test.setCurrentPageReference(surveyDetailsPage);
    //start of changes by janantha for CR 1159273
    surveyDetailsPage.getParameters().put('id', surveyCon01.Id);
    //End of changes by janantha for CR 1159273
    CS_MapSurveyQuestionsAndAnswers retrieveResults = new CS_MapSurveyQuestionsAndAnswers();
    Test.startTest();
    retrieveResults.getIconForSurveyContact();
    retrieveResults.getMapping();
    retrieveResults.getSurveyContact();
    Test.stopTest();
    }
    
    static testMethod void myNegativeTest(){
    init();
    PageReference surveyDetailsPage = Page.CS_VfpSurveyDetails;
    Test.setCurrentPageReference(surveyDetailsPage);
    surveyDetailsPage.getParameters().put('id', con2.Id);
    CS_MapSurveyQuestionsAndAnswers retrieveResults = new CS_MapSurveyQuestionsAndAnswers();
    Test.startTest();
    retrieveResults.getMapping();
    retrieveResults.getSurveyContact();
    Test.stopTest();
    }
}