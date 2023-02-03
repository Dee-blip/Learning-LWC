/*
* 
* Details : Test class for AA QuoteExtController, CPQ__UtilityClass.
* 
* Developer			Date			Version		Update 
* kimishra			08/06/2019		1.0			Initial version
* kimishra      	09/16/2019    	1.1      	primary quote and OA validation logic added
* kimishra      	06/05/2019    	1.2      	AuraEnabled recall and submit methods
* shegade           05/04/2021      1.3         test quote creation made local to test methods, PMD warning fixes
*/
@isTest
private class QuoteExtControllerTests {
    
    @TestSetup
    static void dataCreation(){
        //CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createLegalEntities();
    }
    
    testMethod static void testSubmit() {
        //SBQQ__Quote__c quote = new SBQQ__Quote__c();
        Opportunity oppObj = CPQ_TestDataFactory.createOpportunity(true);
        //Opportunity oppObj = [SELECT Id, Name, AccountId FROM Opportunity LIMIT 1];
        CPQ_TestDataFactory.createOrderApproval(true, oppObj);
        SBQQ__Quote__c quote = CPQ_TestDataFactory.createQuote(false, oppObj);
        quote.CPQ_Primary__c = true;
        insert quote;
        
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onSubmit();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', quote.ApprovalStatus__c,'Approval status did not change to approved');
    }
    
    testMethod static void testRecall() {
        Opportunity oppObj = CPQ_TestDataFactory.createOpportunity(true);
        SBQQ__Quote__c quote = CPQ_TestDataFactory.createQuote(false, oppObj);
        quote.CPQ_Primary__c = true;
        insert quote;
        Test.startTest();
        QuoteExtController con = new QuoteExtController(new ApexPages.StandardController(quote));
        con.onRecall();
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', quote.ApprovalStatus__c, 'Approval status did not change to Recalled');
    }

    testMethod static void testAuraRecall() {
        Opportunity oppObj = CPQ_TestDataFactory.createOpportunity(true);
        SBQQ__Quote__c quote = CPQ_TestDataFactory.createQuote(false, oppObj);
        quote.CPQ_Primary__c = true;
        insert quote;
        Test.startTest();
        QuoteExtController.onRecall(quote.Id);
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Recalled', quote.ApprovalStatus__c,'Approval status did not change to Recalled');
    }
    
    testMethod static void testAuraSubmit() {
        Opportunity oppObj = CPQ_TestDataFactory.createOpportunity(true);
        //Opportunity oppObj = [SELECT Id, Name, AccountId FROM Opportunity LIMIT 1];
        CPQ_TestDataFactory.createOrderApproval(true, oppObj);
        SBQQ__Quote__c quote = CPQ_TestDataFactory.createQuote(false, oppObj);
        quote.CPQ_Primary__c = true;
        insert quote;
        
        Test.startTest();
        QuoteExtController.onSubmit(quote.Id);
        quote = [SELECT ApprovalStatus__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();
        
        System.assertEquals('Approved', quote.ApprovalStatus__c,'Approval status did not change to Approved');
    }

    @IsTest
    static void testOrderButtonVisibility(){

        Test.startTest();
        CPQ_TestQuoteSetupMethods.simpleAutonomyQuoteSetup();
        SBQQ__Quote__c testQuote = [SELECT  Id, Name, SBQQ__Status__c FROM SBQQ__Quote__c WHERE SBQQ__Status__c != 'Order Accepted' LIMIT 1];
        Boolean result = QuoteExtController.checkQuoteValidityForOrder(testQuote.Id);
        QuoteExtController.checkCPQPermission('CPQ_Partner_User');
        Test.stopTest();

        System.assert(result, 'Test Case Failed');
        
    }

    @IsTest
    static void testUtilityMethod(){
        
        Test.startTest();
        Boolean sandbox = CPQ_UtilityClass.isSandbox();
        System.debug(LoggingLevel.INFO,sandbox);
        String replaceString = CPQ_UtilityClass.specialCharacterReplacement('&');
        CPQ_UtilityClass.specialCharacterReplacement('%');
        Test.stopTest();
        
        system.assertEquals('and', replaceString, 'method failed to return correct replacement');
    }
}