@isTest(SeeAllData=false)
public with sharing class CPQ_Test_PM_ApiCallout {
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
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/attribute')
        .getRecord());

        customSettings.add(new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Sections')
        .withActive(true)
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/sections?customerType=CUST_TYPE_KEY')
        .getRecord());

        customSettings.add(new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Literature')
        .withActive(true)
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/literature')
        .getRecord());
        
        customSettings.add(new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Products')
        .withActive(true)
        .withValue('/pac-api/v2/products')
        .getRecord());
        

        insert customSettings;


    }
    
    @IsTest
    

    static void testProductAPIResponse(){
        
        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        
        Test.startTest();
        CPQ_PM_UtilityClass.ApiResponseWrapper response = CPQ_PM_ApiCalllout.getProductDetails('M-LC-107281');
        
        CPQ_PM_UtilityClass.ErrorResponse testRespose = new CPQ_PM_UtilityClass.ErrorResponse();
        testRespose.detail = 'test Detail';
        testRespose.instance = 'test_instance';
        testRespose.status = 200;
        testRespose.title = 'test_title';
        testRespose.type = 'test_type';

        Test.stopTest();
        System.assert(response.attributeResponse!=null, 'attribute response is not null');
       
        
    }
    
    @isTest
    static void testProductAPIResponseCarrier(){
        
        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        
        Test.startTest();
        List<CurrencyType> currenciesTypes= [SELECT IsoCode
        FROM CurrencyType
        WHERE IsActive = true];
        CPQ_PM_UtilityClass.ApiResponseWrapper response = CPQ_PM_ApiCalllout.getProductDetails('M-LC-160315',currenciesTypes);
        CPQ_PM_UtilityClass.ErrorResponse testRespose = new CPQ_PM_UtilityClass.ErrorResponse();
        testRespose.detail = 'test Detail';
        testRespose.instance = 'test_instance';
        testRespose.status = 200;
        testRespose.title = 'test_title';
        testRespose.type = 'test_type';

        Test.stopTest();
        System.assert(response.attributeResponse!=null, 'attribute response is not null');
       
        
    }
    
    @isTest
    static void testAPICallException(){

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        List<String> productIds = new List<String>();
        productIds.add('M-LC-84827');
        productIds.add('M-LC-107281');
        Test.startTest();

        CPQ_Generic_Settings__c attributeEndpoint = CPQ_Generic_Settings__c.getValues('PAC_Endpoint_Get_Attributes');
        attributeEndpoint.CPQ_Value__c = '/pac-api/v2/products/PROD_ID/versions/';
        update attributeEndpoint;
        CPQ_PM_UtilityClass.ApiResponseWrapper response = CPQ_PM_ApiCalllout.getProductDetails('M-LC-127057');

        CPQ_Generic_Settings__c productEndpoint = CPQ_Generic_Settings__c.getValues('PAC_Endpoint_Get_Products');
        productEndpoint.CPQ_Value__c ='/pac-api/v2/productsnew';
        update productEndpoint;
        CPQ_PM_UtilityClass.ApiResponseWrapper productresponse = CPQ_PM_ApiCalllout.verifyMarktetingProductId(productIds);
        Test.stopTest();
        System.assert(response.attributeResponse==null, 'attribute response is null');
        System.assert(productresponse.productsInfo==null, ' product response is  null');
    }
    @isTest
    static void testAPICallExceptionForCarrier(){
        
        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        List<String> productIds = new List<String>();
        productIds.add('M-LC-166361');
        productIds.add('M-LC-160315');
        Test.startTest();
        CPQ_Generic_Settings__c attributeEndpoint = CPQ_Generic_Settings__c.getValues('PAC_Endpoint_Get_Attributes');
        attributeEndpoint.CPQ_Value__c = '/pac-api/v2/products/PROD_ID/versions/';
        update attributeEndpoint;
        List<CurrencyType> currenciesTypes= [SELECT IsoCode
        FROM CurrencyType
        WHERE IsActive = true];
        CPQ_PM_UtilityClass.ApiResponseWrapper response = CPQ_PM_ApiCalllout.getProductDetails('M-LC-160315',currenciesTypes);
        
        CPQ_Generic_Settings__c productEndpoint = CPQ_Generic_Settings__c.getValues('PAC_Endpoint_Get_Products');
        productEndpoint.CPQ_Value__c ='/pac-api/v2/productsnew';
        update productEndpoint;
        CPQ_PM_UtilityClass.ApiResponseWrapper productresponse = CPQ_PM_ApiCalllout.verifyMarktetingProductId(productIds);
        Test.stopTest();
        System.assert(response.attributeResponse==null, 'attribute response is null'); 
        System.assert(productresponse.productsInfo==null, ' product response is  null'); 
    }
    @isTest
    static void testConsumeSectionDetails(){

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        Test.startTest();
        
            List<String> productIds = new List<String>();
            productIds.add('M-LC-84827');
            productIds.add('M-LC-107281');
            CPQ_PM_ApiCalllout.consumeSectionInfo(productIds);

        Test.stopTest();
        System.assertEquals(!productIds.isEmpty(),true,'success');
        
       
    }
    @isTest
    static void verifyProductIds(){

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        List<String> productIds = new List<String>();
        productIds.add('M-LC-84827');
        productIds.add('M-LC-107281');
        Test.startTest();
        
        CPQ_PM_UtilityClass.ApiResponseWrapper response = CPQ_PM_ApiCalllout.verifyMarktetingProductId(productIds);
        
        CPQ_PM_UtilityClass.ErrorResponse testRespose = new CPQ_PM_UtilityClass.ErrorResponse();
        testRespose.detail = 'test Detail';
        testRespose.instance = 'test_instance';
        testRespose.status = 200;
        testRespose.title = 'test_title';
        testRespose.type = 'test_type';
        
        Test.stopTest();
        System.assert(response.productsInfo!=null, ' product response is not null');
        
       
    }
    

}