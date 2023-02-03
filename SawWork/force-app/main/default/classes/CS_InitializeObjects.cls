/*
Author - Sharath K
Created- 1/25/2011
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
Description - This class contains static methods that can be used to Initialize objects for various Test classes for CSAT project
Initializes the following objects
1. Accounts
2. Contacts
3. Survey
4. SurveyResponse
5. SurveyResponse Name-Value
6. SurveyQuestion
Modified: Sharath - 3/25/2011 - adding 2 new objects to initialize
7. CS_QuestionSet__c
8. CS_Questionnare__c
Modified: Sharath - 5/19/2011 - adding 2 more objects to initialize
9. Survey Accounts
10. Survey Contacts
Modified On: 06/12/2012 by janantha for CR 1744933
*/

public class CS_InitializeObjects{

public static Account createAccount(String pAccName){
    //function to create accounts
    // parameters - Account Name
    Account newAccount = new Account();
    newAccount.Name = pAccName;
    newAccount.BillingCountry = 'India';
    newAccount.BillingState = 'Delhi';
    return newAccount;

  }

public static Contact createContact(String fName, String lName, String accId, String akamcontactId){
    //function to create Contacts
    // parameters - Contact 1st Name, Contact Last Name, Associated Account Id
    Contact newContact = new Contact();
    newContact.FirstName = fName;
    newContact.LastName = lName;
    newContact.AccountId = accId;
    newContact.Phone = '99999';
    newContact.Validation_Override__c = true;
    String strCustomGUID = getCustomGUID('Test');
    //Start of changes by janantha for CR 1744933
    newContact.Email = 'janantha'+strCustomGUID+'@akamai.com';
    //End of changes by janantha for CR 1744933
    newContact.Title = 'Tester';   
    newContact.MailingCountry = 'India';
    newContact.akam_contact_id__c = akamcontactId;
    return newContact;
  }
  
  //Start of changes by janantha for CR 1744933
  public static String getCustomGUID(String env)
  {
      double randomNumber = Math.random();
      DateTime ranTime = System.Now();
      String ranString = env+ranTime+randomNumber;
      ranString = ranString.replaceAll(' ','');
      ranString = ranString.replaceAll('-','');
      ranString = ranString.replaceAll(':','');
      return ranString;
  }
  //End of changes by janantha for CR 1744933

  // create a new Survey record
  /* Modified: Sharath 06/03/2011  - CR 1140535 CSAT: adding an additional parameter - "surveyOpenedDate")   */
public static CS_Survey__c createSurvey(String surveyName,String surveyType,String surveyStatus,String surveyOpenedDate){
    CS_Survey__c survey = new CS_Survey__c();
    survey.Name = surveyName;
    survey.CS_Type__c = surveyType;
    survey.CS_Status__c = surveyStatus;
    survey.CS_SurveyOpenedOn__c = Date.parse(surveyOpenedDate);
    return survey;
    }

    //create a new SurveyResponse record
public static CS_SurveyResponse__c createSurveyResponse(String surveyResponseName,String surveyId,String syncStatus){
    CS_SurveyResponse__c surveyResponse = new CS_SurveyResponse__c();
    surveyResponse.Name = surveyResponseName;
    surveyResponse.CS_Survey__c = surveyId;
    surveyResponse.CS_SyncStatus__c = syncStatus;
    return surveyResponse;
    }
    
    //create a new surveyResponse name-balue record
public static CS_SurveyResponseNameValue__c createSurveyResponseNV(String field,String fieldValue,String rowIdentifier,String syncStatus){
    CS_SurveyResponseNameValue__c nameVal = new CS_SurveyResponseNameValue__c();
    nameVal.CS_Name__c = field;
    nameVal.CS_Value__c = fieldValue;
    nameVal.CS_RecordId__c = rowIdentifier;
    nameVal.CS_SyncStatus__c = syncStatus;
    return nameVal;
    }
   
//create a new surevy Question record   
public static CS_SurveyQuestion__c createSurveyQuestion(String surveyQuestion,String mapToField,Integer qNumber,String questionSetId){
    CS_SurveyQuestion__c question = new CS_SurveyQuestion__c();
    question.CS_Question__c = surveyQuestion;
    question.CS_MapToField__c = mapToField;
    question.CS_QuestionNumber__c = qNumber;
    question.CS_QuestionSet__c = questionSetId;
    return question;
    }
   
public static CS_QuestionSet__c createSurveyQuestionSet(String questionnaireId,String questionSetName){
    CS_QuestionSet__c questionSet = new CS_QuestionSet__c();
    questionSet.CS_QuestionnareNumber__c = questionnaireId;
    questionSet.CS_QuestionSetName__c = questionSetName;
    return questionSet;
    }
    
public static CS_Questionnare__c createSurveyQuestionnare(String surveyId){
    CS_Questionnare__c questionnare = new CS_Questionnare__c();
    questionnare.CS_SurveyId__c = surveyId;
    return questionnare;
    }
 
//create new Survey Account 
public static CS_SurveyAccount__c createSurveyAccount(String accId, String surveyId){
    CS_SurveyAccount__c surveyAcc = new CS_SurveyAccount__c();
    surveyAcc.CS_Account__c = accId;
    surveyAcc.CS_Survey__c = surveyId;
    return surveyAcc;
    }

// create new survey Contact    
public static CS_SurveyContacts__c createSurveyContact(String surveyAccId, String conId, String surveyId){
    CS_SurveyContacts__c surveyCon = new CS_SurveyContacts__c();
    surveyCon.CS_SurveyAccount__c = surveyAccId;
    surveyCon.CS_Survey__c = surveyId;
    surveyCon.CS_Contact__c = conId;
    return surveyCon;
    }
}