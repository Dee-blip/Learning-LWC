/*
 * Test class for - CPQ_Product_Launch_Controller 
 * Test class for - CPQ_Product_Search_Controller 
*/
@isTest(seeAllData=false)
public with sharing class CPQ_Test_Product_Search_Controller {
    @isTest
    static void returnProductLaunchSettingRecord() {
        List<Id> fixedResults = new Id[2];
        Product2 testProduct = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Partner_Products').saveRecord();
        testProduct.IsActive = TRUE;
        update testProduct;
        fixedResults.add(testProduct.Id);

        Test.setFixedSearchResults(fixedResults);
        List<String> selectedIds = new List<String>();

        List<CPQ_Lookup_Search_Result> results = CPQ_Product_Search_Controller.search('M-LC-107281', selectedIds, 'Partner');

        System.assertEquals(1, results.size(),'success');
        System.assertEquals(testProduct.Id, results.get(0).getId(),'success');
        
    }

    @isTest
    static void returnSelectedItem() {
        List<Id> fixedResults = new Id[2];
        Product2 testProduct = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Partner_Products').saveRecord();
        testProduct.IsActive = TRUE;
        update testProduct;
        fixedResults.add(testProduct.Id);

        Product2 testProduct2 = new CPQ_TestDataFactory.ProductBuilder('Test Product 2', 'Partner_Products').saveRecord();
        testProduct2.IsActive = TRUE;
        update testProduct2;
        fixedResults.add(testProduct2.Id);

        Test.setFixedSearchResults(fixedResults);
        List<String> selectedIds = new List<String>();
        selectedIds.add(testProduct2.Id);

        List<CPQ_Lookup_Search_Result> results = CPQ_Product_Search_Controller.search('M-LC-107281', selectedIds, 'Partner');

        System.assertEquals(1, results.size(),'success');
        System.assertEquals(testProduct.Id, results.get(0).getId(),'success');
    }

    @isTest
    static void testCreateProduct() {
        String sectionData ='[{"id":1,"name":"Ion - Usage Pricing","ranking":1,"listItemGroupInfo":{"groupName":"Ion - Usage Pricing","groupingCriterion":"Custom","setNames":["GB (Usage < 20000 GB)","GB (Usage > 20000 GB)","Usage - Mbps"]}},{"id":2,"name":"Ion Standard - Usage Pricing","ranking":2,"listItemGroupInfo":{"groupName":"Ion Standard - Usage Pricing","groupingCriterion":"Custom","setNames":["Fee","GB (Usage Pricing)","Mbps (Usage Pricing)"]}},{"id":3,"name":"Included","ranking":3,"listItemGroupInfo":null},{"id":4,"name":"Add-on","ranking":4,"listItemGroupInfo":null},{"id":5,"name":"Add-on - NetStorage Ireland with NetStorage - NetStorage","ranking":5,"listItemGroupInfo":{"groupName":"NetStorage","groupingCriterion":"Unit of Measure","setNames":["Average GB Stored","GB Stored"]}},{"id":6,"name":"SSL certificates","ranking":6,"listItemGroupInfo":null},{"id":7,"name":"Integration","ranking":7,"listItemGroupInfo":null}]';
        CPQ_ProductLaunchSetting__c testlaunchSetting = createLaunchSetting('M-LC-107281');
        Test.startTest();
        CPQ_Product_Search_Controller.getSectionDetails(testlaunchSetting.Product_Mkt_Code__c,sectionData);
        Test.stopTest();

        List<CPQ_ProductLaunchSetting__c> testLaunch = [SELECT Id, Name,Product_Mkt_Code__c FROM CPQ_ProductLaunchSetting__c WHERE Product_Mkt_Code__c='M-LC-107281'];
        System.assertEquals(!testLaunch.isEmpty(),true,'success');
        
    }
    @isTest
    static void testBuildSectionDeatils() {
        CPQ_ProductLaunchSetting__c testlaunchSetting = createLaunchSetting('Global Traffic Management Standard');
        Product2 testProduct = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Partner_Products').saveRecord();
        testProduct.ProductCode ='M-LC-107281';
        update testProduct;
     
        datetime today = datetime.now();
        DateTime newDateTime = today.addMonths(1);

        PLU__c newLaunch = new PLU__c(Name= 'SEP-2020', PLU_Date__c = newDateTime.date(),Status__c = 'Pending' );
        Database.insert(newLaunch);
        String productString ='[{"productId":"M-LC-107281","billingModels":"Straight Line Commitment;Usage Commitment","usage":1,"name":""}]';
        Test.startTest();
        CPQ_Product_Search_Controller.createProductSettings(newLaunch.id,productString,'Partner');
        Test.stopTest();
        
        List<PLU__c> testLaunch = [SELECT Id, Name FROM PLU__c WHERE Name = 'SEP-2020'];
        System.assertEquals(!testLaunch.isEmpty(),true,'success');
    }
    @isTest
    static void testLaunchSettingRecord(){
        
        CPQ_ProductLaunchManagement__c launchManagement = createLaunchManagement('M-LC-107281');
        Test.startTest();
        CPQ_Product_Launch_Controller.getProdLaunchList(launchManagement.id,'Partner');
        Test.stopTest();
        List<CPQ_ProductLaunchManagement__c> testLaunch = [SELECT Id, Name FROM CPQ_ProductLaunchManagement__c WHERE Name = 'M-LC-107281'];
        System.assertEquals(!testLaunch.isEmpty(),true,'success');

    }
    @isTest         
    static void testUpdateLaunch(){

        
        Product2 testProduct = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Partner_Products').saveRecord();
        Product2 testProduct1 = new CPQ_TestDataFactory.ProductBuilder('Test Product 2', 'Partner_Products').saveRecord();
        CPQ_ProductLaunchManagement__c launchManagement = createLaunchManagement('M-LC-107281');
        launchManagement.Product_Launch_Status__c = 'Activated';
        launchManagement.Product_previous_version__c = testProduct.id;
        launchManagement.Product__c=testProduct1.id;
        update launchManagement;
       
        List<CPQ_ProductLaunchManagement__c> testList = [SELECT Id FROM CPQ_ProductLaunchManagement__c LIMIT 1];
        
        Test.startTest();
        CPQ_Product_Launch_Controller.launchSelectedProduct(new List<Id>{testList[0].Id});
        Test.stopTest();

        List<CPQ_ProductLaunchManagement__c> testLaunch = [SELECT Id, Name,Product_Launch_Status__c FROM CPQ_ProductLaunchManagement__c WHERE Product_Launch_Status__c = 'Activated'];
        System.assertEquals(!testLaunch.isEmpty(),true,'success');
        

    }
    @isTest
    static void testFetchSection() {
        List<String> productIds = new List<String>();
        productIds.add('M-LC-84827');
        String sectionData ='[{"id":1,"name":"Ion - Usage Pricing","ranking":1,"listItemGroupInfo":{"groupName":"Ion - Usage Pricing","groupingCriterion":"Custom","setNames":["GB (Usage < 20000 GB)","GB (Usage > 20000 GB)","Usage - Mbps"]}},{"id":2,"name":"Ion Standard - Usage Pricing","ranking":2,"listItemGroupInfo":{"groupName":"Ion Standard - Usage Pricing","groupingCriterion":"Custom","setNames":["Fee","GB (Usage Pricing)","Mbps (Usage Pricing)"]}},{"id":3,"name":"Included","ranking":3,"listItemGroupInfo":null},{"id":4,"name":"Add-on","ranking":4,"listItemGroupInfo":null},{"id":5,"name":"Add-on - NetStorage Ireland with NetStorage - NetStorage","ranking":5,"listItemGroupInfo":{"groupName":"NetStorage","groupingCriterion":"Unit of Measure","setNames":["Average GB Stored","GB Stored"]}},{"id":6,"name":"SSL certificates","ranking":6,"listItemGroupInfo":null},{"id":7,"name":"Integration","ranking":7,"listItemGroupInfo":null}]';
        Map<String,String> sectionMap = new Map<String,String>();
        sectionMap.put('M-LC-84827',sectionData);
        Test.startTest();
        CPQ_Product_Search_Controller.fetchSectionDetails(productIds,sectionMap);
        Test.stopTest();

        System.assertEquals(!sectionMap.isEmpty(),true,'success');
        
    }
    @isTest
    static void testdeleteSelectedPlm(){
        datetime today = datetime.now();
        DateTime newDateTime = today.addMonths(1);
        
        PLU__c newLaunch = new PLU__c(Name= 'SEP-2020', PLU_Date__c = newDateTime.date(),Status__c = 'Pending' );
        Database.insert(newLaunch);
        
        Product2 testProduct1 = new CPQ_TestDataFactory.ProductBuilder('Test Product 2', 'Partner_Products').saveRecord();

        CPQ_ProductLaunchManagement__c launchManagement = createLaunchManagement('M-LC-107281');
        launchManagement.Launch__c = newLaunch.id;
        launchManagement.Product__c = testProduct1.id;
        update launchManagement;
        List<CPQ_ProductLaunchManagement__c> testlaunchManagementList = [SELECT Id,Launch__c FROM CPQ_ProductLaunchManagement__c LIMIT 1];
        Test.startTest();
        CPQ_Product_Launch_Controller.unlinkPlm(new List<Id>{testlaunchManagementList[0].Id});
        Test.stopTest();

        testlaunchManagementList = [Select id,Launch__c FROM CPQ_ProductLaunchManagement__c WHERE Id=:testlaunchManagementList[0].Id];
        System.assert(testlaunchManagementList[0].Launch__c == null, 'PLM is unlinked from the Launch');
    }

    private static CPQ_ProductLaunchSetting__c createLaunchSetting(String name) {
        CPQ_ProductLaunchSetting__c testlaunchSetting = new CPQ_ProductLaunchSetting__c(Name = name,Product_Mkt_Code__c='M-LC-107281');
        insert testlaunchSetting;
        return testlaunchSetting;
    }
    private static CPQ_ProductLaunchManagement__c createLaunchManagement(String name){
        CPQ_ProductLaunchManagement__c launchManagement = new CPQ_ProductLaunchManagement__c(Name = name,Product_Type__c='Partner');
        insert launchManagement;
        return launchManagement;
    }

    
}