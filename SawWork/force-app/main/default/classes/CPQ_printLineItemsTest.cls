/**
* This class includes the test method for CPQ_QuoteFactory, CPQ_printLineItems_ctrl
* @author  Kirti Mishra
* @version 1.0
*/

@IsTest
public class CPQ_printLineItemsTest {
    @TestSetup
    static void setup() {
    
        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createLegalEntities();

    }

    @IsTest
    public static void testPrintLinesPositive() {
        

        Test.startTest();
        CPQ_TestQuoteSetupMethods.autonomyQuoteWithBundleSetup();
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PageReference pageRef = Page.CPQ_printLineItems;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('qid',testQuote.Id);
        ApexPages.StandardController sc = new ApexPages.standardController(testQuote);
        CPQ_printLineItems_ctrl controller = new CPQ_printLineItems_ctrl();

        System.assertEquals(null,controller.init());

        Test.stopTest();
    }

    @IsTest
    public static void testPrintLinesNegative() {
        

        Test.startTest();

        CPQ_TestQuoteSetupMethods.autonomyQuoteWithBundleSetup();
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        PageReference pageRef = Page.CPQ_printLineItems;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('qid','am8190000004CFk');   //give incorrect quote id to cover catch block
        ApexPages.StandardController sc = new ApexPages.standardController(testQuote);
        CPQ_printLineItems_ctrl controller = new CPQ_printLineItems_ctrl();

        System.assertEquals(null,controller.init());
        System.assertNotEquals(0, ApexPages.getMessages().size());

        Test.stopTest();
    }
}