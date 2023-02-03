/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR/JIRA          DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                    
|  20-July-2020     Komal Dwivedi    ESESP-3929   - Set seeAllData = false
												  - Added utilTestClass.createCustomSettings to the createcustomSettings method
+=====================================================================================================*/

@isTest(seeAllData = false)
public class SC_ExistingSearchPageCtrlTestClass {
    
    
    public static void createCustomSettings(){
       /*list<SObject> lSObjects = new list<SObject>(); 
       utilTestClass.createCustomSettings();
       SCRecordTypeCustomSetting__c varSCRTCS = new SCRecordTypeCustomSetting__c();
       varSCRTCS.RecordTypeName__c = 'Technical,AMG,Billing,GSS CSAT,Emerging Products Engineering,Managed Security';
       varSCRTCS.Name = 'EmailToCaseRT ';
       lSObjects.add(varSCRTCS);

       SC_FromEmailAddress__c varSCFromEmailAdd = new SC_FromEmailAddress__c();
       varSCFromEmailAdd.Name = 'ProlexicFromEmailAddress';
       varSCFromEmailAdd.FromAddress__c = 'all@all.com';
       lSObjects.add(varSCFromEmailAdd); 
       
       EmailHandler_CS__c varEmailHandlerCS1 = new EmailHandler_CS__c(); 
       varEmailHandlerCS1.Name = 'billing';
       varEmailHandlerCS1.Email_Address__c = 'billing@akamai.com';
       varEmailHandlerCS1.Record_Type__c = 'Billing'; 
       lSObjects.add(varEmailHandlerCS1);
       
       EmailHandler_CS__c varEmailHandlerCS2 = new EmailHandler_CS__c(); 
       varEmailHandlerCS2.Name = 'care-att';
       varEmailHandlerCS2.Email_Address__c = 'ccare-att@akamai.com';
       varEmailHandlerCS2.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS2);
       
       EmailHandler_CS__c varEmailHandlerCS3 = new EmailHandler_CS__c(); 
       varEmailHandlerCS3.Name = 'ccare';
       varEmailHandlerCS3.Email_Address__c = 'ccare@akamai.com';
       varEmailHandlerCS3.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS3);
        
       EmailHandler_CS__c varEmailHandlerCS4 = new EmailHandler_CS__c(); 
       varEmailHandlerCS4.Name = 'ccare-att';
       varEmailHandlerCS4.Email_Address__c = 'ccare-att@akamai.com';
       varEmailHandlerCS4.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS4);
        
       EmailHandler_CS__c varEmailHandlerCS5 = new EmailHandler_CS__c(); 
       varEmailHandlerCS5.Name = 'client-endusersupport';
       varEmailHandlerCS5.Email_Address__c = 'client-endusersupport@akamai.com';
       varEmailHandlerCS5.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS5);
       
       EmailHandler_CS__c varEmailHandlerCS6 = new EmailHandler_CS__c(); 
       varEmailHandlerCS6.Name = 'CustomerCare';
       varEmailHandlerCS6.Email_Address__c = 'customercare@akamai.com';
       varEmailHandlerCS6.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS6);
        
       EmailHandler_CS__c varEmailHandlerCS7 = new EmailHandler_CS__c(); 
       varEmailHandlerCS7.Name = 'Emerging Product Group';
       varEmailHandlerCS7.Email_Address__c = 'epe-support@akamai.com';
       varEmailHandlerCS7.Record_Type__c = 'Emerging Products Engineering'; 
       lSObjects.add(varEmailHandlerCS7); 
       
       EmailHandler_CS__c varEmailHandlerCS8 = new EmailHandler_CS__c(); 
       varEmailHandlerCS8.Name = 'portal-feedback';
       varEmailHandlerCS8.Email_Address__c = 'portal-feedback@akamai.com';
       varEmailHandlerCS8.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS8); 
       
       EmailHandler_CS__c varEmailHandlerCS9 = new EmailHandler_CS__c(); 
       varEmailHandlerCS9.Name = 'prolexic';
       varEmailHandlerCS9.Email_Address__c = 'prolexic@akamai.com';
       varEmailHandlerCS9.Record_Type__c = 'Managed Security'; 
       lSObjects.add(varEmailHandlerCS9);
       
       EmailHandler_CS__c varEmailHandlerCS10 = new EmailHandler_CS__c(); 
       varEmailHandlerCS10.Name = 'specialist';
       varEmailHandlerCS10.Email_Address__c = 'specialist@akamai.com';
       varEmailHandlerCS10.Record_Type__c = 'AMG'; 
       lSObjects.add(varEmailHandlerCS10);
       
       EmailHandler_CS__c varEmailHandlerCS11 = new EmailHandler_CS__c(); 
       varEmailHandlerCS11.Name = 'ps-tix';
       varEmailHandlerCS11.Email_Address__c = 'ps-tix@akamai.com';
       varEmailHandlerCS11.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS11);
        
       EmailHandler_CS__c varEmailHandlerCS12 = new EmailHandler_CS__c(); 
       varEmailHandlerCS12.Name = 'support';
       varEmailHandlerCS12.Email_Address__c = 'support@akamai.com';
       varEmailHandlerCS12.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS12); 
        
       SCUserIdCustomSetting__c varSCUSerIdCS = new SCUserIdCustomSetting__c();
       varSCUSerIdCS.Name = 'LunaPortalIntegration';
       varSCUSerIdCS.UserId__c = '005G0000003dnrRIAQ';
       lSObjects.add(varSCUSerIdCS);
       
       SurveyEmailHandler_CS__c varSurveyEmailCS1 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS1.Name = 'Billing Survey';
       varSurveyEmailCS1.Email_Address__c = 'billing_survey_feedback@akamai.com';
       lSObjects.add(varSurveyEmailCS1);
        
       SurveyEmailHandler_CS__c varSurveyEmailCS2 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS2.Name = 'ccare';
       varSurveyEmailCS2.Email_Address__c = 'ccare@akamai.com';
       lSObjects.add(varSurveyEmailCS2);
        
       SurveyEmailHandler_CS__c varSurveyEmailCS3 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS3.Name = 'specialist';
       varSurveyEmailCS3.Email_Address__c = 'specialist@akamai.com';
       lSObjects.add(varSurveyEmailCS3); 
        
       System.runas(new User(Id = Userinfo.getUserId())){ 
           insert lSObjects;
           
           Environment_Setup__c setting = Environment_Setup__c.getOrgDefaults();
        setting.Active_Org__c = true;
        update setting;
       } */
       utilTestClass.createCustomSettings();
    }
    
    static testMethod void testSearchPage(){
        
        createCustomSettings();
        List<Case> lTestCasesToInsert = new List<Case>();
        Case objCase = new Case();
        objCase.Subject = 'Test Case';
        objCase.Description = 'Test Description';
        objCase.Status = 'Open';
        objCase.AKAM_Case_ID__c = 'TESTCASE-EXISTINGCASE';
        objCase.origin = 'Others';
        lTestCasesToInsert.add(objCase);
        
        Case objCase2 = new Case();
        objCase2.Subject = 'Test Case';
        objCase2.Description = 'Test Description';
        objCase2.Status = 'Open';
        objCase2.AKAM_Case_ID__c = 'TESTCASE-NEWCASE';
        objCase2.origin = 'Others';
        lTestCasesToInsert.add(objCase2);

        insert lTestCasesToInsert;
        
        Case varCase = [SELECT Id,CaseNumber FROM Case LIMIT 1];
        
        PageReference urlForSearchCase = new PageReference('/apex/SC_ExistingCaseSearchPage?caseId=' + lTestCasesToInsert[0].Id);
        Test.setCurrentPage(urlForSearchCase);
        
        SC_ExistingCaseSearchCtrl controller = new SC_ExistingCaseSearchCtrl();
        controller.akamCaseId='TESTCASE-NEWCASE,TESTCASE-EXISTINGCASE';
        controller.searchBasedOn = 'Akam Case Id';
        controller.searchCaseBasedOnAkamId();
        controller.lCaseWrapperToDisplay[0].selectedCase = true;
        controller.lCaseWrapperToDisplay[1].selectedCase = true;
        controller.updateParentCase();
        
        
        controller.akamCaseId= varCase.CaseNumber;
        controller.searchBasedOn = 'Case Number';
        controller.searchCaseBasedOnAkamId();
    }
}