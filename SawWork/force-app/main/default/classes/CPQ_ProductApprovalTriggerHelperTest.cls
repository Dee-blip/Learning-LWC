/*
* Details : Test class for CPQ_ProductApprovalTrigger, CPQ_ProductApprovalTriggerHandler, CPQ_ProductApprovalTriggerHelper.
* 
* Developer			Date			Version		Update 
* kimishra			09/28/2019		1.0			Initial version
* 
*/
@isTest
private class CPQ_ProductApprovalTriggerHelperTest {
    static User user1;
    static Opportunity oppObj;
    static Order_Approval__c orderApprovalObj;
    static List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
    static SBQQ__Quote__c quote;
    static SBQQ__Quote__c quote1;
    static Approval_Workflow__c approvalWorkflow;
    static List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
    static SBQQ__QuoteLine__c quoteLine;
    static SBQQ__QuoteLine__c quoteLine1;
    static sbaa__ApprovalRule__c rule1;
    static sbaa__ApprovalCondition__c rule1Condition1;
    static sbaa__ApprovalRule__c rule2;
    static sbaa__ApprovalCondition__c rule2Condition1;
    static sbaa__Approval__c approval1;
    static sbaa__Approval__c approval2;
    static Group grp;
    static Product_Approvals__c prodAppr;
    
    @TestSetup
    static void dataCreation(){
        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createCPQUser('Sales - Carrier');
        CPQ_TestDataFactory.createGroup('OM Approval Group');
    }
    
    @isTest 
    static void unitTest1(){
        user1 = [SELECT Id, Name FROM User WHERE Alias = 'newUser' LIMIT 1];
        grp = [SELECT Id, Name FROM Group WHERE Name = 'OM Approval Group'];
        CPQ_TestDataFactory.createGroupMember(grp.Id, user1.Id);
        
        //create an open quote with Approval record of Requested Status
        oppObj = CPQ_TestDataFactory.createOpportunity(true);
        orderApprovalObj = CPQ_TestDataFactory.createOrderApproval(true, oppObj);
        quote = CPQ_TestDataFactory.createQuote(false, oppObj);
        quote.CPQ_Primary__c = true;
        quotes.add(quote);
        
        quote1 = CPQ_TestDataFactory.createQuote(false, oppObj);
        quotes.add(quote1);
        
        //no need for Quote triggers to run
        CPQ_QuoteTriggerHandler.TriggerDisabled = true;
        insert quotes;
        
        approvalWorkflow = CPQ_TestDataFactory.createApprovalWorkflow(true, 'Test product');
        quoteLine1 = CPQ_TestDataFactory.createQuoteLine(false,quote1,'Test product');
        quoteLine1.CPQ_Approval_Workflow__c = approvalWorkflow.Id;
        quoteLines.add(quoteLine1);
        
        quoteLine = CPQ_TestDataFactory.createQuoteLine(false,quote,'Test product');
        quoteLine.CPQ_Approval_Workflow__c = approvalWorkflow.Id;
        quoteLines.add(quoteLine);
        

        insert quoteLines;
        
        //make the quote open/ in review stage
        quote1.SBQQ__Status__c = 'In Review';
        quote1.ApprovalStatus__c = 'Pending';
        //CPQ_QuoteTriggerHandler.TriggerDisabled = true;
        update quote1;
        
        rule1 = CPQ_TestDataFactory.createApprovalRule(true, 'Product Approval Rule', null);
        rule1Condition1 = CPQ_TestDataFactory.createRuleCondition(true, rule1);
        approval1 = CPQ_TestDataFactory.createApproval(true, rule1, quote.Id, 'Requested');
        approval2 = CPQ_TestDataFactory.createApproval(true, rule1, quote1.Id, 'Requested');
        
        Test.startTest();
        CPQ_ProductApprovalTriggerHandler.TriggerDisabled = false;
        Product_Approvals__c prodAppr = [SELECT Id, Status__c FROM Product_Approvals__c WHERE Opportunity__c = :oppObj.Id];
        prodAppr.Status__c = 'Approved';
        update prodAppr;

        System.AssertEquals('Approved', prodAppr.Status__c, 'Status should be approved');

        Test.stopTest();
    }
    
    @isTest 
    static void unitTest2(){
        Product_Approvals__c prodAppr = new Product_Approvals__c();
        insert prodAppr;
        
        delete prodAppr;
        undelete prodAppr;

        System.AssertNotEquals(null, prodAppr, 'prodAppr should not be null.');
    }
}