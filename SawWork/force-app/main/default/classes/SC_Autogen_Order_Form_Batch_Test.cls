/*
_________________________________________________________________________________________________________
DESCRIPTION         : Test class for SC_Autogen_Order_Form_Batch / SC_Autogen_Order_Form_Support
Author              : Vandhana Krishnamurthy
Date                : 25/01/2018
_________________________________________________________________________________________________________*/
@isTest(seeAlldata = false)
public class SC_Autogen_Order_Form_Batch_Test 
{
    public Id oppId;
    
    @testSetup static void createTestData()
    {
        utilTestClass.insertCustomSettings();
        utilTestClass.SC_Autogen_init_Method();
        
        User usr = new User(id=UserInfo.getUserId());
        Order_Approval__c oa;
        System.runAs(usr)
        {
            Account acc = utilTestClass.CreateAccount('TestAccount');
            acc.Type = 'Agency - Active';
            acc.AKAM_Account_ID__c = 'TestAKAM123';
            insert acc;
            
            Opportunity opp = utilTestClass.CreateOpportunity('testOpp','1. Identify Need');
            opp.CloseDate = Date.today().addDays(60);
            opp.Momentum_Order_Form_Initiated__c = true;
            opp.AccountId = acc.Id;
            opp.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();
            opp.Validation_Override__c = true;
            insert opp;
            
            Product2 testProduct2= new Product2();
            testProduct2.Name = 'TEST';
            insert(testProduct2);
            
            PricebookEntry pbEntry= new PricebookEntry();
            pbEntry.Pricebook2Id = Test.getStandardPricebookId();
            pbEntry.Product2Id   = testProduct2.id;
            pbEntry.CurrencyIsoCode = 'USD';
            pbEntry.IsActive     = true;
            pbEntry.UnitPrice    = 1;
            insert(pbEntry);
            
            List<OpportunityLineItem> OpportunityLineItemList= new OpportunityLineItem[]{};
            for(Integer num = 1; num <= 2; num++) 
            {
                OpportunityLineItem i = new OpportunityLineItem();
                i.opportunityId       = opp.id;
                i.pricebookentryid    = pbEntry.Id;
                i.quantity            = 1;
                i.unitprice           = 1;
                i.Projected_Monthly_commit_fees__c = 2;
                i.Average_Renewal_Commit_MRR__c =1;
                OpportunityLineItemList.add(i);
            }
            Database.insert(OpportunityLineItemList);
            
            oa = new Order_Approval__c();
            oa.RecordTypeId = Schema.SObjectType.Order_Approval__c.getRecordTypeInfosByName().get('CCG Only Approval').getRecordTypeId();
            oa.Associated_Opportunity__c = opp.Id;
            oa.AKAM_OrderApproval_ID__c = 'OATest123';
            oa.Validation_Override__c = true;
            insert oa;
            
            SC_AutogenJob__c scAutoJob = new SC_AutogenJob__c();
            scAutoJob.Active__c = true;
            scAutoJob.Autogen_UseCase_Name__c = 'AMG-OFR';
            scAutoJob.Case_Record_Type__c = 'AMG';
            scAutoJob.Description__c = 'The following Opportunity has been created for [insert Opportunity name]. Please review and update the case.';
            scAutoJob.IS_Case_Routing_Required__c = true;
            scAutoJob.Origin__c = 'Autogen';
            scAutoJob.Request_Type__c = 'Order Form Review';
            scAutoJob.Service__c = 'Account Audits';
            scAutoJob.Subject__c = 'OFR for [insert opportunity name]';
            scAutoJob.Severity__c = '3';
            insert scAutoJob;
        }
        
        usr = [Select Name from User where Profile.Name = 'SA - Analyst' AND isActive = true limit 1];
        
        System.runAs(usr)
        {
            Task t = new Task();
            t.Task_Type__c = 'OM';
            t.Subject = 'New OM Task';
            t.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Order Approval Activity').getRecordTypeId();
            t.WhatId = oa.Id;
            t.OwnerId = [Select Id,Name from User where Name = 'OM Queue' limit 1].Id;
            t.Status = 'Not Started';
            insert t;
        }
        
    }
    
    static testMethod void testOrderFormSupport()
    {
        Test.startTest();
        	Database.executeBatch(new SC_Autogen_Order_Form_Batch());
        Test.stopTest();
    }
    
    static testMethod void testOrderFormSupport_exception()
    {
        Test.startTest();
        	try
            {
                SC_Autogen_Order_Form_Batch obj = new SC_Autogen_Order_Form_Batch();
                obj.noOfErrors = 5;
                Database.executeBatch(obj);
            }
        	catch(Exception e)
            {}
        Test.stopTest();
    }
}