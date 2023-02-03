/*
Author : Sajha ese-force-3.38 CR 2333667 : Case Creation for Low Sat Score Survey Contacts

*/
public class CS_CreateCaseForDetractors
{
Public string ActiveSurveyID;
public string caseOrigin;
Public string caseGSSCSatRecordTypeID;
Public string caseService;
Public string caseSubject;
Public string caseDescription;
Public string caseRequestType; 
Public string sfdcBaseURL;
List<Contact> listDetractorContacts = new list<Contact>();
List<CS_SurveyContacts__c> SurveyContactList = new list<CS_SurveyContacts__c>();
list<Case> DetractorcaseInsert = new list<Case>();
Map<String,CS_SurveyContacts__c> ContactSurveyContactForDescriptionMap = new Map<String,CS_SurveyContacts__c>();

public CS_CreateCaseForDetractors(List<String> SurveyContactsList,String SurveyId)
{   ActiveSurveyID = SurveyId;
    List<String> CreateCaseForTheseSurveyContactsList = new List<String>(SurveyContactsList);
    listDetractorContacts = [select Id,AccountId,account.name from Contact where Id in : CreateCaseForTheseSurveyContactsList ];
    
    SurveyContactList =[ select Id,CS_Account__r.Name,CS_SyncDate__c,CS_NPS__c,CS_SyncStatus__c,CS_SurveyResponseSyncId__c,CS_Contact__c,CS_Contact__r.Name,CS_Contact__r.Email,
    CS_Contact__r.akam_contact_id__c,CS_OverallSatWithProductAdvertising__c,CS_OverallSatWithProductEnterpriseApps__c,
    CS_OverallSatWithImplementationChange__c,CS_OverallSatWithProductSoftware__c,CS_OverallSatWithAccountMgmtSupport__c,
    CS_OverallSatWithProductStreamingMedia__c,CS_OverallSatWithProductWebSite__c,CS_OverallSatWithProductOthers__c,
    CS_LikelihoodToRecommend__c,CS_Classification__c,CS_Type__c,CS_LowSatScore__c,CS_OverallSatisfaction__c,CS_ImplementationProcessSatisfaction__c,
    CS_BusinessSupportSatisfaction__c,CS_EdgeControlSatisfaction__c,CS_SalesProcessSatisfaction__c,CS_FeedbackReceivedDate__c,
    CS_CustomerCareSatisfaction__c,CS_BillingOperationsSatisfaction__c from CS_SurveyContacts__c where CS_Contact__c IN :CreateCaseForTheseSurveyContactsList AND CS_SurveyAccount__r.CS_Survey__c = :ActiveSurveyID];
    for(CS_SurveyContacts__c c: SurveyContactList )
    {
        String CurrentContactId = c.CS_Contact__c;
        if(!(ContactSurveyContactForDescriptionMap.containsKey(CurrentContactId)))
        {
            ContactSurveyContactForDescriptionMap.put(CurrentContactId,c);
        }
        
    }
    caseGSSCSatRecordTypeID= Schema.SObjectType.Case.getRecordTypeInfosByName().get('GSS CSAT').getRecordTypeId();
    caseOrigin= 'Survey – Detractor';
    caseService = 'Loyalty Survey';
    caseRequestType = 'Akamai Product/Portal';
    sfdcBaseURL = URL.getSalesforceBaseUrl().toExternalForm();
    }
    
    
public void csCreateCaseFunction()
{
    AssignmentRule assgnrule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
    Database.DMLOptions dmo = new Database.DMLOptions();
    dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
    Map<Case,CS_SurveyContacts__c> CasesurveyContactMap = new Map<Case,CS_SurveyContacts__c>();
  List<CS_SurveyContacts__c> ListToUpdateCaseIDs = new List<CS_SurveyContacts__c>();
    For (Contact c: listDetractorContacts)
    {
        try{
        
        CS_SurveyContacts__c surveyContactForThisContact = ContactSurveyContactForDescriptionMap.get(c.ID);
        Case detractorCase = new Case();
        detractorCase.AccountId = c.AccountId;
        detractorCase.ContactId = c.ID;
        detractorCase.Origin = caseOrigin;
        detractorCase.RecordTypeId = caseGSSCSatRecordTypeID;
        detractorCase.Subject = 'Relationship Survey: Detractor: ' + c.account.name;
        detractorCase.Service__c = caseService;
    CasesurveyContactMap.put(detractorCase,surveyContactForThisContact);
       try{
        detractorCase.Description = 'A survey response was received with the following answers : \n\n' + 
    'Overall Sat w/Akamai: ' + surveyContactForThisContact.CS_OverallSatisfaction__c +
    '\nWould you recommend Akamai: ' +  surveyContactForThisContact.CS_LikelihoodToRecommend__c + 
        '\n\nOverall Sat w/ Products used: [Streaming Media]  : ' + surveyContactForThisContact.CS_OverallSatWithProductStreamingMedia__c + 
    '\nOverall Sat w/ Products used: [Web Site] : ' + surveyContactForThisContact.CS_OverallSatWithProductWebSite__c + 
    '\nOverall Sat w/ Products used: [Enterprise Apps] : ' + surveyContactForThisContact.CS_OverallSatWithProductEnterpriseApps__c + 
    '\nOverall Sat w/ Products used: [Software] : ' + surveyContactForThisContact.CS_OverallSatWithProductSoftware__c +
    '\nOverall Sat w/ Products used: [Advertising] : ' + surveyContactForThisContact.CS_OverallSatWithProductAdvertising__c +
    '\nOverall Sat w/ Products used: [Other] : ' + surveyContactForThisContact.CS_OverallSatWithProductOthers__c + 
    '\n\nOverall Sat w/Sales : ' + surveyContactForThisContact.CS_SalesProcessSatisfaction__c +
    '\nPost Sales Business Support : ' + surveyContactForThisContact.CS_BusinessSupportSatisfaction__c +
    '\nOverall Implementation Experience : ' + surveyContactForThisContact.CS_ImplementationProcessSatisfaction__c +
    '\nOverall Sat w/Customer Care : ' + surveyContactForThisContact.CS_CustomerCareSatisfaction__c  +
    '\n\nThis response came from: \nAccount: ' + c.Account.Name + 
    '\nRespondent name: ' + surveyContactForThisContact.CS_Contact__r.Name + 
    '\nEmail address: ' + surveyContactForThisContact.CS_Contact__r.Email + 
    '\n\nTo view the entire response, please click on the link below.\n\n' + sfdcBaseURL + '/apex/CS_VfpSurveyDetails?id=' + surveyContactForThisContact.ID;
    
    detractorCase.Description=detractorCase.Description.replaceAll('null','');  
         }
       catch(exception e)
       {
       detractorCase.Description = 'Description could not be created due to internal error';
       } 
       detractorCase.Request_Type__c = caseRequestType;
        
        detractorCase.setOptions(dmo);
        if(DetractorcaseInsert.size() < 199)
        {
            DetractorcaseInsert.add(detractorCase);
        }
        else
        {
           Database.SaveResult[] srList = database.insert(DetractorcaseInsert,false);
           DetractorcaseInsert.clear();
           DetractorcaseInsert.add(detractorCase);
           //Iterate through Results to process errors
           for (Database.SaveResult sr : srList) 
           {
                if (sr.isSuccess()) 
                {
                    //Do Nothing for now in case of success.
                }
                else 
                {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors())
                    {
                      CS_SurveyException__c excpRecord = new CS_SurveyException__c();
                      excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
                      excpRecord.CS_ExceptionMessage__c = err.getMessage() + ' (Error in inserting Detractor Case)';
                      database.insert(excpRecord);
                    }
                }
            }
        }
        }
        Catch(Exception e)
        {
            CS_SurveyException__c excpRecord = new CS_SurveyException__c();
      excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
      excpRecord.CS_ExceptionMessage__c = e.getMessage() + ' (Error in creating Detractor Case)';
      database.insert(excpRecord);
        }
    }
    Database.SaveResult[] srList1 = database.insert(DetractorcaseInsert,false); 
    for (Database.SaveResult sr : srList1) 
           {
                if (sr.isSuccess()) 
                {
                    //Do Nothing for now in case of success.
                }
                else 
                {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors())
                    {
                      CS_SurveyException__c excpRecord = new CS_SurveyException__c();
                      excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
                      excpRecord.CS_ExceptionMessage__c = err.getMessage() + ' (Error in inserting Detractor Case)';
                      database.insert(excpRecord);
                    }
                }
            }   
  //CasesurveyContactMap.put(detractorCase,surveyContactForThisContact);
  //Set <String> colorSet = new Set<String>();
  //colorSet = colorCodes.keySet();
  Set<Case> CasesInserted = new Set<Case>();
  CasesInserted = CasesurveyContactMap.keySet();
  For(Case CaseForWhichID2beMapped : CasesInserted)
  {
    CS_SurveyContacts__c SurveyContactForWhichID2beMapped = new CS_SurveyContacts__c();
    SurveyContactForWhichID2beMapped = CasesurveyContactMap.get(CaseForWhichID2beMapped);
	if(SurveyContactForWhichID2beMapped != NULL)
	{
    SurveyContactForWhichID2beMapped.CS_CaseId__c = CaseForWhichID2beMapped.ID;
    ListToUpdateCaseIDs.add(SurveyContactForWhichID2beMapped);
    }
  }
  Database.SaveResult[] srList2 = Database.update(ListToUpdateCaseIDs,False);
  for (Database.SaveResult srUpdate : srList2) 
           {
                if (srUpdate.isSuccess())
                {
                    //Do Nothing for now in case of success.
                }
                else 
                {
                    // Operation failed, so get all errors                
                    for(Database.Error err : srUpdate.getErrors())
                    {
                      CS_SurveyException__c excpRecord = new CS_SurveyException__c();
                      excpRecord.CS_ExceptionInObject__c = 'UpdateContacts ApexClass';
                      excpRecord.CS_ExceptionMessage__c = err.getMessage() + ' (Error in updating Survey Contact with Detractor Case ID)';
                      database.insert(excpRecord);
                    }
                }
            }   
  
}
}