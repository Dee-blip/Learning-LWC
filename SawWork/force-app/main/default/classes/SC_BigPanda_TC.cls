/*
Author          : Tejaswini
Description     : Test class for Bigpanda classes

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
05 Jan 2022             Tejaswini                ESESP-6008                   Test class for SC_BigPanda_Case_Modal_Ctrl , SC_BigPandaAPI , SC_BigPanda_Notification_Ctrl
------------------------------------------------------------------------------------------------------------------
*/
@isTest
public class SC_BigPanda_TC {
    public static SC_Salesforce_Dash_Credentials__c  adminRec;
    @testSetup
    static void setupMethod() {

        utilTestClass.createCustomSettings(); 
        
        //create custom setting record
        adminRec = new SC_Salesforce_Dash_Credentials__c();
        adminRec.Access_Token__c = '';
        adminRec.BP_Header_Secret__c  = 'GtrH8je8R2ssdef';
        insert adminRec;
        
        Account acc = new Account(Name='Test Account',AKAM_Account_ID__c='Test-ABC-1234Addr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert acc;

        Policy_Domain__c  pd = new Policy_Domain__c();
        pd.Name = 'TestClassPD';
        pd.Account_Name__c = acc.Id;
        pd.Product__c = 'Kona DDoS Defender';
        pd.Policy_Domain_State__c  = 'Active';
        pd.Additional_Product__c = 'Application-based Monitoring';
        insert pd;
        
        List<Case> lCase = new List<Case>();
        Case c1 = new Case();
        c1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c1.AccountId=acc.Id;
        c1.Living_Summary_Next_Steps__c = 'Test case 1';
        c1.Subject = 'Testing the case 1';
        c1.origin = 'Akamai'; 
        c1.Do_Not_Show_in_Portal__c = true;
        c1.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        c1.Severity__c = '3';
        c1.Priority = 'Low';
        c1.Policy_Domain__c = pd.Id;
        c1.Sub_Type__c = 'Runbook Review';
        c1.Service_Category__c = 'Managed Security';
        c1.Problem__c = 'Specialist';
        c1.Case_Assignment_Using_Active_Rules__c = false;
        c1.Validation_Override__c = true;
        lCase.add(c1);
        
        Case c2 = new Case();
        c2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c2.AccountId=acc.Id;
        c2.Living_Summary_Next_Steps__c = 'Test case 1';
        c2.Subject = 'Testing the case 2';
        c2.origin = 'Akamai'; 
        c2.Do_Not_Show_in_Portal__c = true;
        c2.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        c2.Severity__c = '3';
        c2.Priority = 'Low';
        c2.Policy_Domain__c = pd.Id;
        c2.Sub_Type__c = 'Runbook Review';
        c2.Service_Category__c = 'Managed Security';
        c2.Problem__c = 'Technicians';
        c2.Case_Assignment_Using_Active_Rules__c = false;
        c2.Validation_Override__c = true;
        lCase.add(c2);

        insert lCase;
                
        List<Salesforce_BigPanda_Log__c> lLogs=new List<Salesforce_BigPanda_Log__c>();
        
        Salesforce_BigPanda_Log__c rec1 = new Salesforce_BigPanda_Log__c();
        rec1.RecordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();
        rec1.Incident_Id__c ='61d7cf6583c6c058819d05f6';
        rec1.Status__c ='Success';
        rec1.Request_Method__c = 'GET';
        rec1.Request_Endpoint__c ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidents/61d7cf6583c6c058819d05f6';
        rec1.Response_Status_Code__c = 200;
        rec1.Response_Status__c ='OK';
        rec1.Response_Body__c ='{"message": "F-AC-1242304","status": 200,"statusCode": "OK"}';
        rec1.Flow_Name__c = 'get_incidentsSub_Flow';
        rec1.Action__c = 'Get Incident' ;
        lLogs.add(rec1);
        
        Salesforce_BigPanda_Log__c rec2 = new Salesforce_BigPanda_Log__c();
        rec2.RecordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();
        rec2.Case_Id__c = String.valueOf(c1.Id);
        rec2.Status__c ='Success';
        rec2.Request_Method__c = 'POST';
        rec2.Request_Endpoint__c ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidents';
        rec2.Request_Body__c='[{"postbody":{"comments":"The case is escalated in Salesforce"},"incident_id":"61d7cf6583c6c058819d05f6"}]';
        rec2.Response_Status_Code__c = 204;
        rec2.Response_Status__c ='No Content';
        rec2.Response_Body__c ='{"message": "\"\"","status": "No Content","statusCode": 204}';
        rec2.Flow_Name__c = 'post_incidentsSub_Flow';
        rec2.Action__c = 'Case Escalation' ;
        lLogs.add(rec2);
        
        Salesforce_BigPanda_Log__c rec3 = new Salesforce_BigPanda_Log__c();
        rec3.RecordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();
        rec3.Case_Id__c = String.valueOf(c1.Id);
        rec3.Status__c ='Success';
        rec3.Request_Method__c = 'POST';
        rec3.Request_Endpoint__c ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidentTags';
        rec3.Request_Body__c='[{"requestBody":[{"tag_value":"SA","tag_id":"socc_queue","incident_id":"61d7cf6583c6c058819d05f6"}],"incidentid":"61d7cf6583c6c058819d05f6"}';
        rec3.Response_Status_Code__c = 204;
        rec3.Response_Status__c ='No Content';
        rec3.Response_Body__c ='{"message": "\"\"","status": "No Content","statusCode": 204}';
        rec3.Flow_Name__c = 'post_incidentTagsSub_Flow';
        rec3.Action__c = 'Case Escalation' ;
        lLogs.add(rec3);
        
        Salesforce_BigPanda_Log__c rec4 = new Salesforce_BigPanda_Log__c();
        rec4.RecordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();
        rec4.Incident_Id__c ='61d7cf6583c6c058819d05f6';
        rec4.Status__c ='Success';
        rec4.Request_Method__c = 'POST';
        rec4.Request_Endpoint__c ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidentTags';
        rec4.Request_Body__c='[{"requestBody":[{"tag_value":"F-CS-5463520","tag_id":"case_id","incident_id":"61d7cf6583c6c058819d05f6"},{"tag_value":"https://akamai--crmqa2.my.salesforce.com/lightning/r/Case/5004R00001lwajoQAA/view","tag_id":"case_url","incident_id":"61d7cf6583c6c058819d05f6"},{"tag_value":"SA","tag_id":"socc_queue","incident_id":"61d7cf6583c6c058819d05f6"}],"incidentid":"61d7cf6583c6c058819d05f6"}]';
        rec4.Response_Status_Code__c = 204;
        rec4.Response_Status__c ='No Content';
        rec4.Response_Body__c ='{"message": "\"\"","status": "No Content","statusCode": 204}';
      	rec4.Flow_Name__c = 'post_incidentTagsSub_Flow';
        rec4.Action__c = 'Case Association';
      	lLogs.add(rec4);
        
        Salesforce_BigPanda_Log__c rec5 = new Salesforce_BigPanda_Log__c();
        rec5.RecordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();
        rec5.Incident_Id__c ='61d7cf6583c6c058819d05f6';
        rec5.Status__c ='Success';
        rec5.Request_Method__c = 'POST';
        rec5.Request_Endpoint__c ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidents';
        rec5.Request_Body__c='[{"postbody":{"comments":"The case is escalated in Salesforce"},"incident_id":"61d7cf6583c6c058819d05f6"}]';
        rec5.Response_Status_Code__c = 204;
        rec5.Response_Status__c ='No Content';
        rec5.Response_Body__c ='{"message": "\"\"","status": "No Content","statusCode": 204}';
      	rec5.Flow_Name__c = 'post_incidentsSub_Flow';
        rec5.Action__c = 'Case Association'; 
        lLogs.add(rec5);
        
        Salesforce_BigPanda_Log__c rec6 = new Salesforce_BigPanda_Log__c();
        rec6.RecordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();
        rec6.Case_Id__c = String.valueOf(c1.Id);
        rec6.Status__c ='Success';
        rec6.Request_Method__c = 'POST';
        rec6.Request_Endpoint__c ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidents';
        rec6.Request_Body__c='[{"postbody":{"resolved":true,"comments":"The case is closed in Salesforce"},"incident_id":"61d7cf6583c6c058819d05f6"}]';        
        rec6.Response_Status_Code__c = 204;
        rec6.Response_Status__c ='No Content';
        rec6.Response_Body__c ='{"message": "\"\"","status": "No Content","statusCode": 204}';
      	rec6.Flow_Name__c = 'post_incidentsSub_Flow';
        rec6.Action__c = 'Case Close'; 
        lLogs.add(rec6);
        
        insert lLogs;
        
        List<BP_Incident__c> lIncidents = new List<BP_Incident__c>();
        BP_Incident__c bpInc1 = new BP_Incident__c();
        bpInc1.Incident_Id__c ='61d7cf6583c6c058819d05f6';
        bpInc1.Case__c = c1.Id;
        lIncidents.add(bpInc1);
        
        BP_Incident__c bpInc2 = new BP_Incident__c();
        bpInc2.Incident_Id__c ='61e90d9b97fa6a420d9c681d';
        bpInc2.Case__c = c2.Id;
        lIncidents.add(bpInc2);
        
        insert lIncidents;
    }

    @isTest
    static void getAllCasesTestMethod()
    {
        Test.startTest();
        Account acc =[Select Id,AKAM_Account_ID__c from Account where Name='Test Account' limit 1];
        List<SC_BigPanda_Case_Modal_Ctrl.CaseWrapper> lCases = SC_BigPanda_Case_Modal_Ctrl.getAllCaseRecs(acc.AKAM_Account_ID__c,'1,2,3,4','All');
        List<SC_BigPanda_Case_Modal_Ctrl.CaseWrapper> lCases1 = SC_BigPanda_Case_Modal_Ctrl.getAllCaseRecs(acc.AKAM_Account_ID__c,'1','Technicians');
        Test.stopTest();
    }

    @isTest
    static void createLogObjectTestMethod()
    {
         
        Test.startTest(); 
        //Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock_TC());
        Case c =[Select Id,Akam_Case_Id__c from Case where Subject='Testing the case 1' limit 1];
        List<Id> logIds= SC_BigPanda_Case_Modal_Ctrl.createLogObjectRec('61d7cf6583c6c058819d05f6','Get Incident',c.Akam_Case_Id__c);
        List<Id> logIds1 = SC_BigPanda_Case_Modal_Ctrl.createLogObjectRec('61d7cf6583c6c058819d05f6','Update Incident Tags',c.Akam_Case_Id__c);
       
        Test.stopTest();
    }
    
    @isTest
    static void getAccountIdStatusTestMethod()
    {
        Test.startTest();
        List<Id> lIds= new List<Id>();
        List<Id> lIds1 = new List<Id>();
        List<Salesforce_BigPanda_Log__c> lRecs = [Select Id,Request_Method__c from Salesforce_BigPanda_Log__c];
        //Case c =[Select Id,Akam_Case_Id__c from Case where Subject='Testing the case 1' limit 1];
        for(Salesforce_BigPanda_Log__c rec:lRecs)
        {
            if(rec.Request_Method__c=='GET')
            {
                lIds.add(rec.Id);
            }
            else if(rec.Request_Method__c=='POST')
            {
                lIds1.add(rec.Id);
            }
        }
        String accId = SC_BigPanda_Case_Modal_Ctrl.getAccountIdFromLogObject(lIds);
        String status = SC_BigPanda_Case_Modal_Ctrl.getStatusOfLogRecord(lIds1);
        Test.stopTest();
    }
    
    @isTest
    static void createWrapperTestMethod()
    {
        Test.startTest();
        List<BP_Incident__c> lBpIds = [Select Id,Incident_Id__c from BP_Incident__c];
        String caseEscWrapper = SC_BigPanda_Case_Modal_Ctrl.getIncidentWrapper(lBpIds,'Case Escalation');
        String caseCloseWrapper = SC_BigPanda_Case_Modal_Ctrl.getIncidentWrapper(lBpIds,'Case Close');
        String incidentWrapper = SC_BigPanda_Case_Modal_Ctrl.getIncidentTagWrapper(lBpIds);
        Test.stopTest();
    }
    
    @isTest
    static void getAccessTokenTestMethod()
    {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock_TC());
        String token= SC_BigPanda_Notification_Ctrl.getAccessToken();
        Test.stopTest();        
    }
    
    @isTest
    static void testgetLogStatus()
    {
        Case c = [Select Id from Case limit 1];
        String uniqueIdentifier = c.Id +'- get_incidentsFlow';
        Test.startTest();
        String status = SC_BigPanda_Case_Modal_Ctrl.getLogStatus(uniqueIdentifier);
        Test.stopTest();
    }
    
    //Test class for SC_BigPandaAPI
    @isTest
    static void testQueuableClass(){
       
        Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock_TC());
        String bpEndPoint ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidents' ;
        String method = 'POST';
        String requestBody = '[{"postbody":{"comments":"The case is escalated in Salesforce"},"incident_id":"61d7cf6583c6c058819d05f6"}]' ;
        Salesforce_BigPanda_Log__c sfbpLog = [Select Id,Case_Id__c,Request_Method__c,Request_Endpoint__c,Request_Body__c,Number_of_Tries__c,Flow_Name__c,Action__c from Salesforce_BigPanda_Log__c where Flow_Name__c='post_incidentsSub_Flow' and Action__c='Case Escalation' limit 1];
        Test.startTest();
        System.enqueueJob(new SC_BigPandaAPI(bpEndPoint, method,requestBody, sfbpLog));
        Test.stopTest();
    }
    
    
    //Test class for SC_BigPanda_Notification_Ctrl
    @isTest
    static void testHttpPost() {
      // prepare test-data
      //As Per Best Practice it is important to instantiate the Rest Context
      Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock_TC()); 
      RestRequest req = new RestRequest();
      RestResponse res = new RestResponse();
      req.requestURI = '/services/apexrest/bigpandaWebhookNotification'; //Request URL
      req.httpMethod = 'POST';

      RestContext.request = req;
      RestContext.response= res;

      Test.startTest();
      //String actual = null;//HttpClass.updateCustomObject();
      SC_BigPanda_Notification_Ctrl.doPost();
      SC_BigPanda_Notification_Ctrl.doGet();
      Test.stopTest();
      //System.assertEquals('expected value', actual, 'Value is incorrect');
   }
    
    //Test class for CaseTrigger_ai & SC_CaseTriggerHelperClass
    /*@isTest
    static void testupdateBPIncident()
    {
        Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock()); 
        Case c = [Select Id from Case limit 1];
        Test.startTest();
        SC_CaseTriggerHelperClass.updateBPIncident(c.Id,'Case Escalation');
        SC_CaseTriggerHelperClass.updateBPIncident(c.Id,'Case Close');
        Test.stopTest();
    }
    
    @isTest
    static void testupdateBPIncidentTags()
    {
        Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock()); 
        Case c = [Select Id from Case limit 1];
        Test.startTest();
        SC_CaseTriggerHelperClass.updateBPIncidentTags(c.Id);
        Test.stopTest();
        
    }*/
    
    @isTest
    static void testUpdateCase()
    {
        Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock_TC());
        List<Case> lc = [Select Id,Status,Problem__c,Validation_Override__c from Case where Subject='Testing the case 2'];
        for(Case c:lc)
        {
            c.Problem__c = 'Specialist';
        	c.Validation_Override__c = true;
        }
        
        Test.startTest();
        update lc;
        Test.stopTest();
    }
    
    @isTest
    static void testCloseCase()
    {
        Test.setMock(HttpCalloutMock.class, new SC_BigPanda_HttpRequestMock_TC());
        List<Case> lc = [Select Id,Status,Validation_Override__c from Case where Subject='Testing the case 2'];
        for(Case c:lc)
        {
            c.Status = 'Closed';
        	c.Validation_Override__c = true;
        }
        
        Test.startTest();
        update lc;
        Test.stopTest();
    }

}