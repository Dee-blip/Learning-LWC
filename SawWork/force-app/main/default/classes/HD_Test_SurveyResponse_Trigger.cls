/*
* File Name: HD_Test_SurveyResponse_Trigger
* Description : Test class for HD_SurveyResponse_Trigger
* @author : Arihant Jain
* Modification Log ===============================================================
* Date 				Author 					Modification
* May 15th, 2020	Arihant Jain			PRTORES-1728 - Mail Notification on Survey Feedback for ITOC Leads
*
*/
@isTest (seeAllData=false)
private class HD_Test_SurveyResponse_Trigger {
    
    @testSetup static void setup() {
        User staff = HD_Test_Remedyforce_TestDataFactory.runAsUser('ServiceDesk Staff',true);
        
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        BMCServiceDesk__Status__c new_status = [Select Id from BMCServiceDesk__Status__c where Name = 'ASSIGNED'limit 1];
        BMCServiceDesk__Incident__c incident = obj.getNewIncident(HD_IncidentTestDataFactory.Team.GENERIC);
        incident.OwnerId = staff.id;
        incident.BMCServiceDesk__queueName__c = 'Default Queue';
        incident.BMCServiceDesk__FKStatus__c = new_status.Id;
        incident.HD_Owner_Manager__c = System.UserInfo.getUserId();
        insert incident;
        
        //Survey Form Creation
        HD_Survey_Form__c hsf = new HD_Survey_Form__c();
        hsf.Days_Response_Will_Expire__c = 1;
        hsf.Available_for_Categories__c = 'Server Request';
        hsf.Description__c	= 'This is for ITOC Test Template';         
        hsf.Form_meta__c='{"question1": {"title": "How do you rate the responsiveness from the engineer?","type": "star","value": ""},"question2": {"title": "How satisfied are you with the professionalism of the engineer?","type": "star","value": ""}}';
        hsf.IsActive__c=true;
        hsf.Survey_Intro__c='Please take a moment to provide feedback about your recent Service Request to help us improve our service.';
        hsf.Survey_Title__c	='ITOC Test Survey';
        hsf.Survey_Type__c='Overall Survey';
        hsf.Team_Tag__c= 'ITOC';
        insert hsf;
    }
    
    static TestMethod void testSendCustomNotification(){
        
        BMCServiceDesk__Incident__c incident = [Select Id from BMCServiceDesk__Incident__c limit 1];
        HD_Survey_Form__c hsf = [Select Id from HD_Survey_Form__c limit 1];
        
        //Survey Response Data Creation
        List<HD_Survey_Response__c> surveyResponseList = new List<HD_Survey_Response__c>();
        
        HD_Survey_Response__c surveyResponse1 = new HD_Survey_Response__c();              
        surveyResponse1.HD_Survey_Form__c = hsf.Id;
        surveyResponse1.Incident__c = incident.Id;
        surveyResponse1.Question__c = 'How do you rate the responsiveness from the engineer?';
        surveyResponse1.Field_Type__c = System.Label.HD_Star;
        surveyResponse1.Response__c = '4';
        surveyResponse1.Response_User__c = System.UserInfo.getUserId();
        surveyResponseList.add(surveyResponse1);
        
        HD_Survey_Response__c surveyResponse2 = new HD_Survey_Response__c();              
        surveyResponse2.HD_Survey_Form__c = hsf.Id;
        surveyResponse2.Incident__c = incident.Id;
        surveyResponse2.Question__c = 'How satisfied are you with the professionalism of the engineer?';
        surveyResponse2.Field_Type__c = System.Label.HD_Star;
        surveyResponse2.Response__c = '3';
        surveyResponse2.Response_User__c = System.UserInfo.getUserId();
        surveyResponseList.add(surveyResponse2);
        
        Test.startTest();
        
        insert surveyResponseList;
        Integer invocations = Limits.getEmailInvocations();
        
        //For increasing the HD_SurveyResponseTriggerHandler coverage 
        delete surveyResponseList[0];
        undelete surveyResponseList[0];
        update surveyResponseList[0];
        
        Test.stopTest();
        
        System.assertEquals(1, invocations, 'An email has not been sent');
    }
    
    
    static TestMethod void negativeTestCaseSendCustomNotification(){
		BMCServiceDesk__Incident__c incident = [Select Id from BMCServiceDesk__Incident__c limit 1];
		HD_Survey_Form__c hsf = [Select Id from HD_Survey_Form__c limit 1];        
        
        //Survey Response Data Creation
        List<HD_Survey_Response__c> surveyResponseList = new List<HD_Survey_Response__c>();
        
        HD_Survey_Response__c surveyResponse1 = new HD_Survey_Response__c();              
        surveyResponse1.HD_Survey_Form__c = hsf.Id;
        surveyResponse1.Incident__c = incident.Id;
        surveyResponse1.Question__c = 'How do you rate the responsiveness from the engineer?';
        surveyResponse1.Field_Type__c = System.Label.HD_Star;
        surveyResponse1.Response__c = '4';
        surveyResponse1.Response_User__c = System.UserInfo.getUserId();
        surveyResponseList.add(surveyResponse1);
        
        HD_Survey_Response__c surveyResponse2 = new HD_Survey_Response__c();              
        surveyResponse2.HD_Survey_Form__c = hsf.Id;
        surveyResponse2.Incident__c = incident.Id;
        surveyResponse2.Question__c = 'How satisfied are you with the professionalism of the engineer?';
        surveyResponse2.Field_Type__c = System.Label.HD_Star;
        surveyResponse2.Response__c = '5';
        surveyResponse2.Response_User__c = System.UserInfo.getUserId();
        surveyResponseList.add(surveyResponse2);
        
        Test.startTest();
        
        insert surveyResponseList;
        Integer invocations = Limits.getEmailInvocations();
        
        Test.stopTest();
        
        System.assertEquals(0, invocations, 'An email has been sent.');
    }
    
}