/**
* Test class for P2r_excel_template_manipulator class
* @author  Shashank Hegade 
* @version 1.0
* @since   2020-11-04
*/

@IsTest(seeAllData = false)
public with sharing class CPQ_ExcelManipulatorTest {
    
    @TestSetup
    static void makeData(){
        
        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createLegalEntities();
        CPQ_TestQuoteSetupMethods.autonomyQuoteWithBundleSetup();

    }

    @IsTest
    static void testExcelDataGeneration(){
        
        
        Test.startTest();
        SBQQ__Quote__c testQuote = [SELECT Id, Name FROM SBQQ__Quote__c LIMIT 1];
        P2r_Excel_Template_Manipulator testResponse = P2r_Excel_Template_Manipulator.classObject(testQuote.Id);
        Test.stopTest();

        System.assert(testResponse.response != '{}','Quote Data did not get Generated');
        
    }
}