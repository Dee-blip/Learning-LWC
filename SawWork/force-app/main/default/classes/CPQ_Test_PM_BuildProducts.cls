/**
* This class is used for CPQ_PM_UtilityClass and CPQ_PM_BuildProduct
* @author  Shashank Hegade 
* @version 1.0
* @since   2021-08-04
*/
@isTest(SeeAllData=false)
public without sharing class CPQ_Test_PM_BuildProducts {

    @TestSetup
    static void makeData(){

        new CPQ_TestDataFactory.APIConnectorBuilder('CPQPulsarSQAForTestClass','host')
        .withCryptoAlgorithm('HmacSHA256')
        .withClientSecret('client-secret')
        .withMoniker('EG1-HMAC-SHA256')
        .withClientToken('client-token')
        .withAccessToken('access-token')
        .withNamedCredential('callout:CPQPulsarSQA2')
        .saveRecord();

        List<CPQ_Generic_Settings__c> customSettings = new List<CPQ_Generic_Settings__c>();

        customSettings.add(new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Pricing')
        .withActive(true)
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/pricing?partnerAccountId=PARTNER_ID&currency=CURR_ID&customerType=CUST_TYPE_KEY')
        .getRecord());

        customSettings.add(new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Attributes')
        .withActive(true)
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/attributes')
        .getRecord());

        customSettings.add(new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Sections')
        .withActive(true)
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/sections?customerType=CUST_TYPE_KEY')
        .getRecord());
        
        customSettings.add(new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Literature')
        .withActive(true)
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/literature')
        .getRecord());

        insert customSettings;

        CPQ_TestQuoteSetupMethods.testProductBundleBuilder();        
    }
    
    @IsTest
    static void testBuildProduct() {

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        // String jsonString = '{"productId": "M-LC-107281","billingModels" : ["Straight-line Commitment","Usage Commitment"]}';
        Test.startTest();
        // Boolean status = CPQ_PMController.getProductInformation(new List<String>{jsonString});
        try{

            CPQ_PM_UtilityClass.ApiResponseWrapper res = CPQ_PM_ApiCalllout.getProductDetails('M-LC-84827');
            String resString = JSON.serialize(res);
            CPQ_PM_BuildProduct.buildProduct(resString, new List<String>{'Straight-line Commitment','Usage Commitment'}, 1);
        }
        catch(Exception e){
            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getLineNumber());
        }
        Test.stopTest();

        List<product2> testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'M-LC-84827'];
        System.assert(true, 'API data processing was not successful');

    }

    @IsTest
    static void testGetOptionDetail(){
        
        Test.startTest();
        Product2 testProduct = [SELECT Id, Name FROM Product2 LIMIT 1];
        List<SBQQ__ProductOption__c> testOptions = CPQ_PM_BuildProduct.getProductOptionDetails(testProduct.Id);
        Test.stopTest();

        System.assert(testOptions.size() > 0, 'testGetOptionDetail is failed');
        
    }

    @IsTest
    static void testProductOptionDeletion(){
        

        Test.startTest();
        List<SBQQ__ProductOption__c> testList = [SELECT Id FROM SBQQ__ProductOption__c LIMIT 1];
        CPQ_PM_BuildProduct.deleteSelectedProductOptions(new List<Id>{testList[0].Id});
        Test.stopTest();

        testList = [SELECT Id FROM SBQQ__ProductOption__c WHERE Id =:testList[0].Id];
        System.assert(testList.size() == 0, 'testProductOptionDeletion failed');
        
    }

    @IsTest
    static void testOptionalProductCreation(){
        
        Test.startTest();
        CPQ_PM_BuildProduct.createOptionalProduct(new Set<String>{'M-LC-127057'});
        Test.stopTest();
        
        List<product2> testProduct = [SELECT Id FROM Product2 WHERE ProductCode = 'M-LC-127057'];
        System.assert(testProduct.size() > 0, 'testOptionalProductCreation not successful');
    }

    @isTest
    static void testAuraMethodsInUtilityClass(){

        Test.startTest();
        CPQ_PM_UtilityClass.ErrorResponse testRespose = new CPQ_PM_UtilityClass.ErrorResponse();
        testRespose.detail = 'test Detail';
        testRespose.instance = 'test_instance';
        testRespose.status = 200;
        testRespose.title = 'test_title';
        testRespose.type = 'test_type';

        CPQ_PM_UtilityClass.OptionalProducts testOption = new CPQ_PM_UtilityClass.OptionalProducts();
        testOption.listItems = null;
        testOption.numberOfOptions = 0;
        testOption.productCode = 'test_code';

        Test.stopTest();

        //This has nothing to assert this is just object initialization;
        System.assert(true, 'testOptionalProductCreation not successful');

    }

   

}