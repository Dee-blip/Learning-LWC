/*
Author: Sharath
Created: 1/19/2011
Description: Test class to check if Contact and name-value rows updation is happening as expected
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
Modified: Sharath 3/25/2011
CR 1014942 : CSAT: Reduce Processing time for the Scheduled Apex Job Contacts Update
    - introduced a new method in CS_UpdateContacts class. Hence had to add a new method in the test class to cover that scenario.
    - made changes to CS_InitializeObjects
05/19/2011 - Sharath
CR 1112835 CSAT: Contacts Update Apex Job to directly update Survey Contacts 
    - Make necessary changes to test class like creating survey accounts and survey contacts
Modified: Sharath 06/03/2011
CR 1140535 CSAT: Contacts Update Apex Job to look at Response Date
    - Adding Feedback Receieved Date SRNV records in the test class
    - Adding additional parameter - "surveyOpenedDate" to CS_InitializeObjects.createSurvey()
10/03/2013 - Sonia 
Fixed the test class for not updating the account network account field which causes the validation rule to fail
*/
@isTest(SeeAllData=true)
private class CS_UpdateContacts_Test{

static CS_Survey__c testSurvey;
static CS_SurveyResponse__c testSurveyResponse;
static List<CS_SurveyResponseNameValue__c> testNVRows = new List<CS_SurveyResponseNameValue__c>();
static CS_SurveyResponseNameValue__c nvRow;
static Account acco1;
static Account acco2;
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

// method to initialize test data
static void init(){
    ManagedPkgErrorClass.isFromManagedPackage=false;
    //  all surveys in Active state , if any, should be made inactive
    List<CS_Survey__c> surveys = [ select Id from CS_Survey__c where CS_Status__c = 'Active'];
    if(surveys !=null){
    for(CS_Survey__c survey : surveys){
        survey.CS_Status__c = 'Inactive';
        database.update(survey);
        }
    }
    // create an active survey
    /*  CR 1140535 - Adding additional parameter - "surveyOpenedDate"   */
    testSurvey = CS_InitializeObjects.createSurvey('Feb/Nov2011', 'CSAT', 'Active','3/15/2011');
    Database.insert(testSurvey);
    
    //create a survey response for that survey
    testSurveyResponse = CS_InitializeObjects.createSurveyResponse('SFeb/Aug-022011',testSurvey.Id,'New');
    Database.insert(testSurveyResponse);
    
    //create Account for testing purpose
    acco1 = CS_InitializeObjects.createAccount('TestAccount_01'); 
    Database.insert(acco1); 
    acco2 = CS_InitializeObjects.createAccount('TestAccount_02'); 
    Database.insert(acco2);
    
    //create Survey Account for testing purpose
    surveyAcc01 = CS_InitializeObjects.createSurveyAccount(acco1.Id,testSurvey.Id);
    Database.insert(surveyAcc01);
    surveyAcc02 = CS_InitializeObjects.createSurveyAccount(acco2.Id,testSurvey.Id);
    Database.insert(surveyAcc02);
    
    //create Contacts for testing purpose
    con1 = CS_InitializeObjects.createContact('Fname','Lname',acco1.Id,'abc-1234');
    Database.insert(con1);
    con2 = CS_InitializeObjects.createContact('Fname','Lname',acco2.Id, 'xyz-1234');
    Database.insert(con2);
    
    //create Survey Contact for testing purpose
    surveyCon01 = CS_InitializeObjects.createSurveyContact(surveyAcc01.Id,con1.Id,testSurvey.Id);
    Database.insert(surveyCon01);
    surveyCon02 = CS_InitializeObjects.createSurveyContact(surveyAcc02.Id,con2.Id,testSurvey.Id);
    Database.insert(surveyCon02);
    
    // Modified: Sharath 3/25/2011-  make the account a network account. This way, the contact cannot be updated, hence covering the exception block
    //acco1.Network_Account__c = true;
    //database.update(acco1);
    
    CS_FieldMapping__c orgValues = CS_FieldMapping__c.getOrgDefaults();

    // create name-value pairs for the active survey, survey response
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ConactIDMapping__c,con1.akam_contact_id__c , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_NPSMapping__c, '10,Very Likely', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_SalesProcessMapping__c,'5' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_EdgeControlSatisfactionMapping__c,'1' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_OverallSatisfactionMapping__c, '4','2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ProductSatisfactionMapping__c, '1', '2', 'Pending');
    testNVRows.add(nvRow);
    /*  CR 1140535 - Adding Feedback Receieved Date SRNV records in the test class  */
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_FeedbackReceivedDateMapping__c, '3/20/2011', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ImplementationProcessMapping__c, '1, vey bad', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_BusinessSupportMapping__c, '5', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_AccountIdMapping__c ,acco1.Id , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_CustomerCareSatisfactionMapping__c, '4', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_BillingOperationsMapping__c, '5', '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallAccountMgmtSupportMapping__c ,'6' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallAdvertisingProductMapping__c ,'6' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallEnterpriseAppsMapping__c ,'5' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallSatImplementationChangeMapping__c ,'6' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallSatSoftwareProductsMapping__c ,'1' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallSatStreamingMediaMapping__c ,'3' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallSatWithOtherProductsMapping__c ,'6' , '2', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_OverallSatWithWebSiteMapping__c ,'6' , '2', 'Pending');
    testNVRows.add(nvRow);
    
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ConactIDMapping__c, con2.akam_contact_id__c, '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_NPSMapping__c, '3', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_SalesProcessMapping__c, '1' , '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_EdgeControlSatisfactionMapping__c,'3' , '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ProductSatisfactionMapping__c, '7', '3', 'Pending');
    testNVRows.add(nvRow);
    /*  CR 1140535 - Adding Feedback Receieved Date SRNV records in the test class  */
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_FeedbackReceivedDateMapping__c, '1/20/2011', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_OverallSatisfactionMapping__c, '0', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_BusinessSupportMapping__c, '1', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_ImplementationProcessMapping__c , '9', '3', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV(orgValues.CS_AccountIdMapping__c , acco2.Id, '3', 'Pending');
    testNVRows.add(nvRow);
    // invalid akam contact id
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_ConactIDMapping__c,'test', '4', 'Pending');
    testNVRows.add(nvRow);
    nvRow = CS_InitializeObjects.createSurveyResponseNV( orgValues.CS_NPSMapping__c, '0, very unlikely', '4', 'Pending');
    testNVRows.add(nvRow);
    database.insert(testNVRows);
    
    testSurveyResponse.CS_SyncStatus__c = 'Pending';
    database.update(testSurveyResponse);

    //Modified: Sharath 3/25/2011 - Changes in CS_InisitalizeObjects class. initialize the surveyQuestionnare, question Set and SurveyQuestions table
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

// tests both positive and negative test cases
static testMethod void myTest(){
    init();
    CS_UpdateContacts testScenario = new CS_UpdateContacts();
    Test.startTest();
    testScenario.execute();
    Test.stopTest();
    //testScenario.processNameValueAndContacts(testSurveyResponse.Id, testSurvey.Id);
    }

/*
Modified: Sharath 3/25/2011 . New method to cover CS_BatchableNVUpdate Class
Initializing these manually here:
    - the NV Rows should  have RecordStatus = 'Processed'/'Failed' to cover the CS_BatchableNVUpdate class
    - the surveyResponse file shud be 'Contacts Processed' status. 
*/
static testMethod void testNVUpdate(){
    init();
    List<CS_SurveyResponseNameValue__c> updateRows = new List<CS_SurveyResponseNameValue__c>();
    String responseId = testSurveyResponse.Id;
    List<CS_SurveyResponseNameValue__c> rowsToUpdate = [select Id,CS_RecordStatus__c from CS_SurveyResponseNameValue__c where CS_SurveyResponse__c = :responseId and CS_CustomOrder__c = 0];
    for(CS_SurveyResponseNameValue__c rowToUpdate : rowsToUpdate){
        rowToUpdate.CS_RecordStatus__c = 'Processed';
        updateRows.add(rowToUpdate);
    }
    database.update(updateRows,false);
    testSurveyResponse.CS_SyncStatus__c = 'Contacts Processed';
    database.update(testSurveyResponse);
    
    CS_UpdateContacts testScenario2 = new CS_UpdateContacts();
    Test.startTest();
    testScenario2.execute();
    Test.stopTest();
}

static testMethod void testInvokeJob()
{
    init();
    Test.startTest();
    CS_InvokeJob.invokeContactsProcessing();
    Test.stopTest();
}

static testMethod void testBatchableContactUpdate()
{
 init();
 List <String> SCList = new list <String>();
 SCList.add(con1.ID); 
 SCList.add(con1.ID);
 Test.startTest();
 // Sajha : CR 2333667 : Case Creation for Low Sat Score   
 CS_CreateCaseForDetractors testCaseCreation = new CS_CreateCaseForDetractors(SCList,testSurvey.Id);
 testCaseCreation.csCreateCaseFunction();
 Test.stopTest();
// Sajha : CR 2333667 : Case Creation for Low Sat Score   
}
}