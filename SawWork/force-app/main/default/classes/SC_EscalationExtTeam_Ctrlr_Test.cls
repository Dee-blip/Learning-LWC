/* 
Test Class for SC_EscalationExtTeam_Ctrlr

Date                  Developer            		JIRA #                 	Description                                                       
------------------------------------------------------------------------------------------------------------------
17 May 2018      Vandhana Krishnamurthy        ESESP-319      		OLAs for Escalation
*/

@isTest(seeAllData = false)
public class SC_EscalationExtTeam_Ctrlr_Test 
{
	@testSetup
    static void testDataSetup()
    {
        utilTestClass.createCustomSettings(); 
        SC_PSEditCaseProfileId__c psCS = new SC_PSEditCaseProfileId__c();
        psCS.Name = 'LunaPortalIntegration';
//        psCS.ProfileId__c = '00eG0000000f0ZFIAY';
        psCS.ProfileId__c = 'Test1234 ';
        insert psCS;
        
        System_to_Area_Mapping__c s2a = new System_to_Area_Mapping__c(System__c = 'JIRA',Area__c = 'JIRA',System_URL__c='jiralink');
        insert s2a;
        
        Account acc = utilTestClass.CreateAccount('Test Account');   
        insert acc;
        
        Case case1 = new Case();
        case1.AccountId = acc.Id;
        case1.Description = 'testTech';
        case1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        case1.Subject = 'testTech';
        case1.Sub_Type__c = 'Product Support';
        case1.Origin = 'Phone';
        case1.Validation_Override__c = true;
        insert case1;
    }
    
    static testMethod void controllerTest()
    {
        Id extTRTId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('External Team').getRecordTypeId();
        Case case1 = [Select Id from Case where Subject = 'testTech' limit 1];
        
        PageReference extTeamPage = Page.SC_EscalationExtTeam;
        Test.setCurrentPage(extTeamPage);
        
        Engagement_Request__c er = new Engagement_Request__c();
        er.System__c = 'JIRA';er.Area__c = 'JIRA';er.ID__c = 'JIRA-123';er.Case__c = case1.Id;
        insert er;
        
        System.currentPageReference().getParameters().put('RecordType',extTRTId);
        ApexPages.StandardController scEC = new ApexPages.StandardController(er);
        SC_EscalationExtTeam_Ctrlr ecCtrlr = new SC_EscalationExtTeam_Ctrlr();
        ecCtrlr = new SC_EscalationExtTeam_Ctrlr(scEC);
        
        System.currentPageReference().getParameters().put('id', case1.Id);
        System.currentPageReference().getParameters().put('RecordType',extTRTId);
        
        scEC = new ApexPages.StandardController(er);
        ecCtrlr = new SC_EscalationExtTeam_Ctrlr(scEC);
        
        ecCtrlr.clearValues();
        ecCtrlr.getarea();ecCtrlr.getsystem();ecCtrlr.Save();ecCtrlr.Redirect();
    }
    
    static testMethod void controllerTest_1()
    {
        Id extTRTId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('External Team').getRecordTypeId();
        Case case1 = [Select Id from Case where Subject = 'testTech' limit 1];
        
        PageReference extTeamPage = Page.SC_EscalationExtTeam;
        Test.setCurrentPage(extTeamPage);
        
        Engagement_Request__c er = new Engagement_Request__c();
        er.System__c = '--None--';er.Area__c = '--None--';er.ID__c = 'JIRA-123';er.Case__c = case1.Id;
        
        ApexPages.StandardController scEC = new ApexPages.StandardController(er);
        SC_EscalationExtTeam_Ctrlr ecCtrlr = new SC_EscalationExtTeam_Ctrlr(scEC);
    }
}