/*
* Details : Test class for CPQ_ApprovalTrigger, CPQ_ApprovalTriggerHandler, CPQ_ApprovalTriggerHelper.
* 
* Developer			Date			Version		Update 
* kimishra			09/26/2019		1.0			Initial version
* 
*/
@isTest
private class CPQ_ApprovalTriggerHelperTest {
    static User user1;
    static Opportunity oppObj;
    static Order_Approval__c orderApprovalObj;
    static SBQQ__Quote__c quote;
    static Approval_Workflow__c approvalWorkflow;
    static SBQQ__QuoteLine__c quoteLine;
    static sbaa__ApprovalRule__c rule1;
    static sbaa__ApprovalCondition__c rule1Condition1;
    static sbaa__Approval__c approval1;
    static sbaa__ApprovalRule__c rule2;
    static sbaa__ApprovalCondition__c rule2Condition1;
    static sbaa__Approval__c approval2;
    static Group grp;
        
    @TestSetup
    static void dataCreation(){
        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createCPQUser('Sales - Carrier');
        CPQ_TestDataFactory.createGroup('OM Approval Group');
    }
    
    @isTest static void unitTest1() 
    {
        user1 = [SELECT Id, Name FROM User WHERE Alias = 'newUser' LIMIT 1];
        grp = [SELECT Id, Name FROM Group WHERE Name = 'OM Approval Group'];
        CPQ_TestDataFactory.createGroupMember(grp.Id, user1.Id);
        
        oppObj = CPQ_TestDataFactory.createOpportunity(true);
        orderApprovalObj = CPQ_TestDataFactory.createOrderApproval(true, oppObj);
        quote = CPQ_TestDataFactory.createQuote(false, oppObj);
        quote.CPQ_Primary__c = true;
        insert quote;
        
        approvalWorkflow = CPQ_TestDataFactory.createApprovalWorkflow(true, 'Test product');
        quoteLine = CPQ_TestDataFactory.createQuoteLine(false,quote,'Test product');
        quoteLine.CPQ_Approval_Workflow__c = approvalWorkflow.Id;
        insert quoteLine;
        
        rule1 = CPQ_TestDataFactory.createApprovalRule(true, 'Product Approval Rule', null);
        rule1Condition1 = CPQ_TestDataFactory.createRuleCondition(true, rule1);
        approval1 = CPQ_TestDataFactory.createApproval(true, rule1, quote.Id, 'Requested');
        
        delete approval1;
        undelete approval1;
        
        rule2 = CPQ_TestDataFactory.createApprovalRule(true, 'OM Approval Rule', 'OM Approval Group');
        rule2Condition1 = CPQ_TestDataFactory.createRuleCondition(true, rule2);
        approval2 = CPQ_TestDataFactory.createApproval(true, rule2, quote.Id, 'Requested');
        
        Test.startTest();
        try{
        approval2.sbaa__AssignedTo__c = user1.Id;
        update approval2;
        } catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('You cannnot assign the approval outside the Approver group') ? true : false;
            System.AssertEquals(expectedExceptionThrown, true, 'Exception should be thrown.');
        } 
        Test.stopTest();
    }
    
    @isTest static void unitTest2() {
        CPQ_QuoteTriggerHandler.TriggerDisabled = true;
        quote = CPQ_TestDataFactory.createQuote(true);
        rule1 = CPQ_TestDataFactory.createApprovalRule(true, 'Product Approval Rule', null);
        rule1Condition1 = CPQ_TestDataFactory.createRuleCondition(true, rule1);
        approval1 = CPQ_TestDataFactory.createApproval(true, rule1, quote.Id, 'Requested');
        
        delete approval1;
        undelete approval1;

        System.AssertNotEquals(null, approval1, 'approval1 should not be null.');
    }
}