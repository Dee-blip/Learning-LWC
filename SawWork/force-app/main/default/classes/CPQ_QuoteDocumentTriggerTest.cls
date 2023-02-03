/**
* Test class for: CPQ_QuoteDocumentTrigger, CPQ_QuoteDocumentTriggerHandler, CPQ_QuoteDocumentTriggerHelper
* @author  Shashank Hegade 
* @version 1.0
* @since   2021-04-01
*/

@IsTest(seeAllData = false)
public with sharing class CPQ_QuoteDocumentTriggerTest {
    @TestSetup
    static void makeData(){

        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createLegalEntities();
        
    }

    @IsTest
    static void testQuoteDocumentGeneration(){
        
        Test.startTest();
        CPQ_TestQuoteSetupMethods.simpleAutonomyQuoteSetup();
        SBQQ__Quote__c parentQuote = [SELECT Id , Name FROM SBQQ__Quote__c LIMIT 1];
        Attachment quoteAttachment = new CPQ_TestDataFactory.AttachmentBuilder(parentQuote.Id,'test message').saveRecord();
        SBQQ__QuoteDocument__c quoteDoc = new CPQ_TestDataFactory.QuoteDocumentBuilder(parentQuote.Id, quoteAttachment.Id).saveRecord();
        //to test the isUpdate trigger call
        quoteDoc.SBQQ__Version__c = 1;
        update quoteDoc;
        //to test the isDelete and isUndelete trigger calls
        delete quoteDoc;
        undelete quoteDoc;

        Test.stopTest();

        List<SBQQ__QuoteDocument__c> testDoc = [SELECT Id, Name FROM SBQQ__QuoteDocument__c LIMIT 10];

        System.assert(testDoc.size() > 0, 'No quote document generated');
        
    }

}