/*
Author: Sharath
Created: 1/19/2011
Description: Test class to check if scheduling is working
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
*/
@istest(SeeAllData=true)
class CS_HourlyScheduleClass_Test {

static CS_Survey__c testSurvey;
static CS_SurveyResponse__c testSurveyResponse;
static List<CS_SurveyResponseNameValue__c> testNVRows = new List<CS_SurveyResponseNameValue__c>();
static CS_SurveyResponseNameValue__c nvRow;
static Account accOld;
static Contact con1;
static contact con2;
static CS_SurveyQuestion__c q;
static List<CS_SurveyQuestion__c> questions = new List<CS_SurveyQuestion__c>();

// method to initialize test data
    static void init(){
    //  all surveys in Active state , if any, should be made inactive
    List<CS_Survey__c> surveys = [ select Id from CS_Survey__c where CS_Status__c = 'Active'];
    if(surveys !=null){
    for(CS_Survey__c survey : surveys){
        survey.CS_Status__c = 'Inactive';
        database.update(survey);
        }
    }
    // create an active survey
    testSurvey = CS_InitializeObjects.createSurvey('Feb/Nov2011', 'CSAT', 'Active','3/15/2011');
    Database.insert(testSurvey);
    
    //create a survey response for that survey
    testSurveyResponse = CS_InitializeObjects.createSurveyResponse('SFeb/Aug-022011',testSurvey.Id,'New');
    Database.insert(testSurveyResponse);
}

   static testmethod void test() {
   Test.startTest();
   init();
   CS_HourlyScheduleClass.jobName ='Test_scheduled_job';
    CS_HourlyScheduleClass.start();
   Test.stopTest();
   }
}