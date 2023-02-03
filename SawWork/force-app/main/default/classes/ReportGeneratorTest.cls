/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    012/02/2018     Created this Class
    
*/
@isTest
public class ReportGeneratorTest {
	static User dmlUser = new User(id=UserInfo.getUserId());

    // Setup method to create test data.
    @testSetup
    static void setupMethod()
    {
        System.runAs(dmlUser) {
            utilTestClass.insertCustomSettings();
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
        }
    }

    public static void initializeObjects(){

        System.runAs(dmlUser) {
            Account acc = new Account();
            acc = utilTestClass.createAccount('TestAcc');
            insert acc;

            Opportunity opp = new Opportunity();
            opp = utilTestClass.CreateOpportunity('TestOpp', '3-Develop');
            opp.AccountId = acc.Id;
            opp.Closed_Datetime__c = DateTime.now();
            opp.CloseDate = Date.today();
            opp.Deal_Type__c = 'Direct';
            insert opp;

            Order_Approval__C oa = new Order_Approval__C();
            oa.Associated_Opportunity__c = opp.id;
            oa.Approvals_Required__c = 'Deal Desk; Legal';
            oa.Type__c = 'CDN';
            insert oa;

            Task task = new Task();
            task.WhatId = oa.id;
            task.Status = 'In Progress';
            task.Task_Type__C = 'OM';
            task.Order_Approval_Type__c = 'CDN';
            task.Task_Validation_Override__c = true;
            insert task;
        }
    }
    static testmethod void testAutomateScoreCardReportTest() {

        initializeObjects();

        Test.startTest();
        	GSM_Settings__mdt mdtRecord = [select Id, Value__c,label from GSM_Settings__mdt where DeveloperName = :'SA_Tasks_Report_2_Id'];
            String reportId = mdtRecord.value__c;
            String reportName = mdtRecord.label;
            String distributionList = GSMUtilClass.getGSMSettingValue('SA_Task_Report_Distribution_List');
            //ReportGenerator reportGen = new ReportGenerator();
            ReportGenerator.generateReport(reportId,reportName,distributionList);
		Test.stopTest();
    }
}