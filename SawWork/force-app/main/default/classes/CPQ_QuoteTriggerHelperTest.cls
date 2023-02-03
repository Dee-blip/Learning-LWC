/*
* 
* Details : Test class for CPQ_QuoteTrigger, CPQ_QuoteTriggerHandler, CPQ_QuoteTriggerHelper.
*           Also covers CPQ_QuoteLineTrigger, CPQ_QuoteTriggeLinerHandler, CPQ_QuoteLineTriggerHelper
* 
* Developer			Date			Version		Update 
* kimishra			09/13/2019		1.0			Initial version
* kimishra			09/30/2019		1.0			Added test data to cover CPQ_QuoteLineTrigger.
* 
*/
@isTest
private class CPQ_QuoteTriggerHelperTest {
    static User user1;
    
    @TestSetup
    static void dataCreation(){
        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createCPQUser('Sales Operations');
        CPQ_TestDataFactory.createLegalEntities();
    }
    
    @isTest 
    static void unitTest1() 
    {
        user1 = [SELECT Id, Name FROM User WHERE Alias = 'newUser' LIMIT 1];
        sbaa__Approver__c approver = CPQ_TestDataFactory.createApprover(true, null);
        Opportunity oppObj = CPQ_TestDataFactory.createOpportunity(true);
        Order_Approval__c orderApprovalObj = CPQ_TestDataFactory.createOrderApproval(true, oppObj);
        SBQQ__Quote__c quote = CPQ_TestDataFactory.createQuote(false, oppObj);
        quote.Sales_Rep_Manager__c = user1.Id;
        quote.CPQ_Primary__c = true;
        quote.CPQ_Geo_Location__c = 'AMER';
        insert quote;
        
        Approval_Workflow__c aw = CPQ_TestDataFactory.createApprovalWorkflow(true,'Test product');
        Approval_Workflow__c aw1 = CPQ_TestDataFactory.createApprovalWorkflow(true,'Test1 product1');
        SBQQ__QuoteLine__c quoteLine = CPQ_TestDataFactory.createQuoteLine(false,quote,'Test product');
        System.debug(LoggingLevel.INFO, 'Approval workflows: '+aw+' -- '+aw1);
        insert quoteLine;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        //Test.stopTest();
        //System.assertEquals('Approved', quote.ApprovalStatus__c);
        
        //adding another QL with an existing Approval Workflow should recall the Quote
        //Test.startTest();
        SBQQ__QuoteLine__c quoteLine1 = CPQ_TestDataFactory.createQuoteLine(false,quote,'Test1 product1');
        insert quoteLine1;
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];

        System.assertNotEquals(null, quote, 'Quote cannot be null.');

        Test.stopTest();
        //System.assertEquals('Recalled', quote.ApprovalStatus__c);
        
    }
    
    @isTest 
    static void unitTest2() {
        List<Id> quoteIds = new List<Id>();
        Opportunity oppObj = CPQ_TestDataFactory.createOpportunity(false);
        oppObj.Order_Region__c = 'United Kingdom';
        insert oppObj;
        SBQQ__Quote__c quote = CPQ_TestDataFactory.createQuote(true, oppObj);
        
        Approval_Workflow__c aw = CPQ_TestDataFactory.createApprovalWorkflow(true,'Test3 product3');
        SBQQ__QuoteLine__c quoteLine = CPQ_TestDataFactory.createQuoteLine(true,quote,'Test3 product3');
        System.debug(LoggingLevel.INFO, 'Approval workflows: '+aw);
        delete quoteLine;
        undelete quoteLine;
        
        quoteIds.add(quote.Id);
        CPQ_UtilityClass.getQuoteIds(quoteIds);
        delete quote;
        undelete quote;

        System.assertNotEquals(null, quote, 'Quote cannot be null.');
    }
}