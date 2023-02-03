// File added as part of SFDC-2201 by Mayank Bansal

@isTest(SeeAllData=false)
public class AutomateScoreCardReportTest {

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
            acc.website='www.cardreport.com';
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
        AutomateScoreCardReport ascr = new AutomateScoreCardReport();
        ascr.fetchrecords();
        Test.stopTest();
    }
}