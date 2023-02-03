@isTest(seeAllData = false)
public class SF1_MobileTaskManagementAppTestClass {

    static testMethod void getOpportunitiestest()
    {
        SF1_MobileTaskManagementAppController.getOpportunities();
    }

    static testmethod void getOARelatedDataTest()
    {
        Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();

        User accOwner = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
        insert accOwner;

        Id akamaiRecTypeId = [select Id from RecordType where Name='Akamai Opportunity'][0].Id;

        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId = accOwner.Id;
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            insert acc;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(-1);
            opp.RecordTypeId = akamaiRecTypeId;


            insert opp;

            Order_Approval__c oa = new Order_Approval__c();
            oa.Associated_Opportunity__c = opp.Id;
            oa.Approvals_Required__c = 'Deal Desk; Legal';
            oa.Type__c = 'CDN';
            insert oa;

            SF1_MobileTaskManagementAppController.getOARelatedData(oa.Id);

            SF1_MobileTaskManagementAppController.getOrderApproval(opp.Id);

            SF1_MobileTaskManagementAppController.getOrderApprovalById(oa.Id);

            List<String> listOfStatus = new List<String>();
            listOfStatus.add('Completed');
            SF1_MobileTaskManagementAppController.getTasksRelatedToOrderApproval(oa.Id,listOfStatus);

            Map<String, String> paramMap = SF1_MobileTaskManagementAppController.Create_Task_Ltng(oa.Id,'Deal Desk');
            paramMap.put('subject','Test Subject');
            paramMap.put('status','Test status');
            paramMap.put('priority','Test priority');
            paramMap.put('description','Test description');
            paramMap.put('WhatId',oa.Id);

            SF1_MobileTaskManagementAppController.createNewTask(paramMap);
            Test.stopTest();
        }
    }

    private static testmethod void testLoadPickListValuesFromUtil()
    {

        SF1_MobileTaskManagementAppController.loadPickListValuesFromUtil('SFDC_MDF__c', 'SOE_or_PubSec_Event__c');
    }



}