@isTest(SeeAllData=false)
public with sharing class CPQ_Test_CPQ_Create_Products {

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

        datetime today = datetime.now();
        DateTime newDateTime = today.addMonths(1);

        PLU__c newLaunch = new PLU__c(Name= newDateTime.month() + '-' + newDateTime.year(), PLU_Date__c = newDateTime.date(),Status__c = 'Pending' );
        Database.insert(newLaunch);

        CPQ_TestQuoteSetupMethods.testProductBundleBuilder();
        CPQ_TestQuoteSetupMethods.testProductBundleBuilderCarrier();
    }
    @IsTest
    static void testNewProductCreation(){

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());

        Test.startTest();

        PLU__c launch = [SELECT  Id, Name, PLU_Date__c, Status__c from PLU__c LIMIT 1];
        CPQ_ProductLaunchSetting__c testRecord = new CPQ_ProductLaunchSetting__c(Name= 'M-LC-84827', UsageSectionNumber__c=1, billingModels__c='Straight Line Commitment;Usage Commitment');
        Map<String, CPQ_ProductLaunchSetting__c> testMap = new Map<String, CPQ_ProductLaunchSetting__c>();
        testMap.put('M-LC-84827',testRecord);

    
        Map<String, CPQ_ProductLaunchManagement__c> plmMap = new Map<String, CPQ_ProductLaunchManagement__c>();
        CPQ_ProductLaunchManagement__c launchManagement = new CPQ_ProductLaunchManagement__c(Name = 'M-LC-84827');
        plmMap.put('M-LC-84827',launchManagement);
        CPQ_Create_Products.createProducts(plmMap, testMap,'Partner');

        

        Test.stopTest();

        List<Product2> testProducts = [SELECT Id, Name from Product2 WHERE ProductCode = 'M-LC-84827'];
        System.assert(testProducts.size() > 0, 'Failed to create product');
        
    }
   
    @IsTest
    static void testExistingProductCreation(){

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());

        Test.startTest();

        PLU__c launch = [SELECT  Id, Name, PLU_Date__c, Status__c from PLU__c LIMIT 1];
        CPQ_ProductLaunchSetting__c testRecord = new CPQ_ProductLaunchSetting__c(Name= 'M-LC-162045', UsageSectionNumber__c=1, billingModels__c='Straight Line Commitment;Usage Commitment');
        Map<String, CPQ_ProductLaunchSetting__c> testMap = new Map<String, CPQ_ProductLaunchSetting__c>();
        testMap.put('M-LC-162045',testRecord);

        Map<String, CPQ_ProductLaunchManagement__c> plmMap = new Map<String, CPQ_ProductLaunchManagement__c>();

        
        CPQ_ProductLaunchManagement__c launchManagement = new CPQ_ProductLaunchManagement__c(Name = 'M-LC-162045');
        plmMap.put('M-LC-162045',launchManagement);
        CPQ_Create_Products.createProducts(plmMap, testMap,'Partner');

        Test.stopTest();

        //The new product will be created with code M-LC-84827 for any request in test class because mock PAC response is set to return M-LC-84827
        List<Product2> testProducts = [SELECT Id, Name from Product2 WHERE ProductCode = 'M-LC-84827'];
        System.assert(testProducts.size() > 0, 'Failed to create product');


    }

    @IsTest
    static void testInvalidResponse(){

        

        CPQ_Generic_Settings__c attributeEndpoint = CPQ_Generic_Settings__c.getValues('PAC_Endpoint_Get_Attributes');
        attributeEndpoint.CPQ_Value__c = '/pac-api/v2/products/PROD_ID/versions/curr';
        update attributeEndpoint;

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibrary());
        Test.startTest();

        PLU__c launch = [SELECT  Id, Name, PLU_Date__c, Status__c from PLU__c LIMIT 1];
        CPQ_ProductLaunchSetting__c testRecord = new CPQ_ProductLaunchSetting__c(Name= 'M-LC-162045', UsageSectionNumber__c=1, billingModels__c='Straight Line Commitment;Usage Commitment');
        Map<String, CPQ_ProductLaunchSetting__c> testMap = new Map<String, CPQ_ProductLaunchSetting__c>();
        testMap.put('M-LC-162045',testRecord);

        Map<String, CPQ_ProductLaunchManagement__c> plmMap = new Map<String, CPQ_ProductLaunchManagement__c>();

        CPQ_ProductLaunchManagement__c launchManagement = new CPQ_ProductLaunchManagement__c(Name = 'M-LC-162045');
        plmMap.put('M-LC-162045',launchManagement);

        CPQ_Create_Products.createProducts(plmMap, testMap,'Partner');

        Test.stopTest();

        //Product creation should be stopped 
        List<Product2> testProducts = [SELECT Id, Name from Product2 WHERE ProductCode = 'M-LC-84827'];
        System.assert(testProducts.size() == 0, 'Failed to test the exception scenario');


    }
    @IsTest
    static void testNewProductCreationCarrier(){

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibraryCarrier());

        PLU__c launch = [SELECT  Id, Name, PLU_Date__c, Status__c from PLU__c LIMIT 1];
        CPQ_ProductLaunchSetting__c testRecord = new CPQ_ProductLaunchSetting__c(Name= 'M-LC-160315');
        Map<String, CPQ_ProductLaunchSetting__c> testMap = new Map<String, CPQ_ProductLaunchSetting__c>();
        testMap.put('M-LC-160315',testRecord);

    
        Map<String, CPQ_ProductLaunchManagement__c> plmMap = new Map<String, CPQ_ProductLaunchManagement__c>();
        CPQ_ProductLaunchManagement__c launchManagement = new CPQ_ProductLaunchManagement__c(Name = 'M-LC-160315',Product_Type__c='Carrier');
        plmMap.put('M-LC-160315',launchManagement);
        Test.startTest();

        
        CPQ_Create_Products.createProducts(plmMap, testMap,'Carrier');
        Test.stopTest();

        List<Product2> testProducts = [SELECT Id, Name from Product2 WHERE ProductCode = 'M-LC-160315'];
        System.assert(testProducts.size() > 0, 'Failed to create product');

        

        
    }
    @IsTest
    static void testExistingProductCreationCarrier(){

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibraryCarrier());
        Test.startTest();

        PLU__c launch = [SELECT  Id, Name, PLU_Date__c, Status__c from PLU__c LIMIT 1];
        CPQ_ProductLaunchSetting__c testRecord = new CPQ_ProductLaunchSetting__c(Name= 'M-LC-162097');
        Map<String, CPQ_ProductLaunchSetting__c> testMap = new Map<String, CPQ_ProductLaunchSetting__c>();
        testMap.put('M-LC-162097',testRecord);

    
        Map<String, CPQ_ProductLaunchManagement__c> plmMap = new Map<String, CPQ_ProductLaunchManagement__c>();
        CPQ_ProductLaunchManagement__c launchManagement = new CPQ_ProductLaunchManagement__c(Name = 'M-LC-162097',Product_Type__c='Carrier');
        plmMap.put('M-LC-162097',launchManagement);
        CPQ_Create_Products.createProducts(plmMap, testMap,'Carrier');
        Test.stopTest();

        //The new product will be created with code M-LC-84827 for any request in test class because mock PAC response is set to return M-LC-84827
        List<Product2> testProducts = [SELECT Id, Name from Product2 WHERE ProductCode = 'M-LC-160315'];
        System.assert(testProducts.size() > 0, 'Failed to create product');


    }

    @IsTest
    static void testInvalidResponseCarrier(){

        

        CPQ_Generic_Settings__c attributeEndpoint = CPQ_Generic_Settings__c.getValues('PAC_Endpoint_Get_Attributes');
        attributeEndpoint.CPQ_Value__c = '/pac-api/v2/products/PROD_ID/versions/curr';
        update attributeEndpoint;

        Test.setMock(HttpCalloutMock.class, new CPQ_Test_MockPMResponseLibraryCarrier());
        Test.startTest();

        PLU__c launch = [SELECT  Id, Name, PLU_Date__c, Status__c from PLU__c LIMIT 1];
        CPQ_ProductLaunchSetting__c testRecord = new CPQ_ProductLaunchSetting__c(Name= 'M-LC-160315');
        Map<String, CPQ_ProductLaunchSetting__c> testMap = new Map<String, CPQ_ProductLaunchSetting__c>();
        testMap.put('M-LC-160315',testRecord);

    
        Map<String, CPQ_ProductLaunchManagement__c> plmMap = new Map<String, CPQ_ProductLaunchManagement__c>();
        CPQ_ProductLaunchManagement__c launchManagement = new CPQ_ProductLaunchManagement__c(Name = 'M-LC-160315',Product_Type__c='Carrier');
        plmMap.put('M-LC-160315',launchManagement);

       

        CPQ_Create_Products.createProducts(plmMap, testMap,'Carrier');

        Test.stopTest();

        //Product creation should be stopped 
        List<Product2> testProducts = [SELECT Id, Name from Product2 WHERE ProductCode = 'M-LC-160315'];
        System.assert(testProducts.size() == 0, 'Failed to test the exception scenario');


    }
    
}