/**
* Test class for CPQ_SObjectDeepClone Class
* @author  Shashank Hegade 
* @version 1.0
* @since   2020-11-04
*/

@IsTest(seeAllData = false)
public class CPQ_SObjectDeepCloneTest {

    @TestSetup
    static void makeData(){

        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createLegalEntities();
        CPQ_TestQuoteSetupMethods.simpleAutonomyQuoteSetup();
        
    }
    /**
     * testSameOpportunityClone is used to test when the quote is being cloned on the same opportunity 
     */ 
    @IsTest
    static void testSameOpportunityClone(){

        CPQ_SObjectDeepClone.Request testRequest = new CPQ_SObjectDeepClone.Request();
        testRequest.childSobjectType = 'SBQQ__QuoteLine__c';
        testRequest.parentSobjectType = 'SBQQ__Quote__c';

        Test.startTest();
        SBQQ__Quote__c parentQuote = [SELECT Id , Name FROM SBQQ__Quote__c LIMIT 1];
        testRequest.recordId = parentQuote.Id;
        CPQ_SObjectDeepClone.clonesObject(new List<CPQ_SObjectDeepClone.Request>{ testRequest });
        Test.stopTest();

        List<SBQQ__Quote__c> clonedQuotes = [SELECT Id , Name, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE CPQ_IsClonedQuote__c = true LIMIT 1];
        System.assert(clonedQuotes.size() > 0, 'Cloning Failed');
        
    }

    /**
     * testDifferentOpportunityClone is used to clone quote to the different opportunity
     */
    @IsTest
    static void testDifferentOpportunityClone(){

        CPQ_SObjectDeepClone.Request testRequest = new CPQ_SObjectDeepClone.Request();
        testRequest.childSobjectType = 'SBQQ__QuoteLine__c';
        testRequest.parentSobjectType = 'SBQQ__Quote__c';
        testRequest.lookupUpdateField_1_name = 'SBQQ__Opportunity2__c';
        testRequest.lookupUpdateField_2_name = 'SBQQ__Account__c';
        
        Test.startTest();
        List<SBQQ__Quote__c> parentQuote = [SELECT Id , Name, SBQQ__Opportunity2__c	 FROM SBQQ__Quote__c LIMIT 1];
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 1];
        List<Opportunity> destOpportunity = new List<Opportunity> { CPQ_TestDataFactory.createOpportunity(true,testAccounts[0].Id) };
        testRequest.recordId = parentQuote[0].Id;
        testRequest.lookupUpdateField_1_value = destOpportunity[0].Id;
        testRequest.lookupUpdateField_2_value = destOpportunity[0].AccountId;
        testRequest.currencyType = destOpportunity[0].CurrencyIsoCode;
        
        CPQ_SObjectDeepClone.clonesObject(new List<CPQ_SObjectDeepClone.Request>{ testRequest });
        Test.stopTest();

        List<SBQQ__Quote__c> clonedQuotes = [SELECT Id , Name, SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE CPQ_IsClonedQuote__c = true LIMIT 1];
        System.assert(clonedQuotes.size() > 0, 'Cloning Failed');
        
    }

    /**
     * testProductUpdateClone is used to check the checkProductValidity method
     */
    @IsTest
    static void testProductUpdateClone(){
        
        
        CPQ_SObjectDeepClone.Request testRequest = new CPQ_SObjectDeepClone.Request();
        testRequest.childSobjectType = 'SBQQ__QuoteLine__c';
        testRequest.parentSobjectType = 'SBQQ__Quote__c';
       
        Test.startTest();
        SBQQ__Quote__c parentQuote = [SELECT Id , Name FROM SBQQ__Quote__c LIMIT 1];
        testRequest.recordId = parentQuote.Id;

        Product2 testProduct = [SELECT id, Name, CPQ_ProductUpdateCode__c FROM Product2 WHERE Name = 'Test Product 1' LIMIT 1];
        testProduct.CPQ_ProductUpdateCode__c = 'update1';
        update testProduct;

        List<CPQ_SObjectDeepClone.Response> testResponse = CPQ_SObjectDeepClone.clonesObject(new List<CPQ_SObjectDeepClone.Request>{ testRequest });
        Test.stopTest();

        List<SBQQ__QuoteLine__c> testLine = [SELECT Id, Name FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = :testResponse[0].clonedParentId ];
        System.assert(testLine.size() == 0, 'Quote Line check failed');
        
    }

    /**
     * testDiffrentCurrency is used to check the checkCurencyAvailability method
     */
    @IsTest
    static void testDiffrentCurrency(){

        CPQ_SObjectDeepClone.Request testRequest = new CPQ_SObjectDeepClone.Request();
        testRequest.childSobjectType = 'SBQQ__QuoteLine__c';
        testRequest.parentSobjectType = 'SBQQ__Quote__c';
        testRequest.lookupUpdateField_1_name = 'SBQQ__Opportunity2__c';
        testRequest.lookupUpdateField_2_name = 'SBQQ__Account__c';

        Test.startTest();
        
        List<SBQQ__Quote__c> parentQuote = [SELECT Id , Name, SBQQ__Opportunity2__c	 FROM SBQQ__Quote__c LIMIT 1];
        List<Account> testAccounts = [SELECT Id, Name FROM Account LIMIT 1];
        List<Opportunity> destOpportunity = new List<Opportunity> { CPQ_TestDataFactory.createOpportunity(false,testAccounts[0].Id) };
        destOpportunity[0].CurrencyIsoCode = 'EUR';
        insert destOpportunity;

        testRequest.recordId = parentQuote[0].Id;
        testRequest.lookupUpdateField_1_value = destOpportunity[0].Id;
        testRequest.lookupUpdateField_2_value = destOpportunity[0].AccountId;
        testRequest.currencyType = destOpportunity[0].CurrencyIsoCode;
        
        List<CPQ_SObjectDeepClone.Response> testResponse = CPQ_SObjectDeepClone.clonesObject(new List<CPQ_SObjectDeepClone.Request>{ testRequest });
        Test.stopTest();

        System.assert(testResponse[0].isSuccess == false, 'Test Case Failed');
        
    }
    
}