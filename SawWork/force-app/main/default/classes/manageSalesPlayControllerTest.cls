@isTest(seeAllData=false)
private class manageSalesPlayControllerTest {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            //Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            /* End Of Custom Setting Insertion */

            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
            List<User> userList = new List<User>();
            User accOwnerUser = utilTestClass.CreateUser('newUser', user_role, 'Sales Operations');
            userList.add(accOwnerUser);
            User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
            userList.add(usrSysAdmin);
            insert userList; 

            Account acc = new Account();
            acc.Name = '__Test Account SalesPlay';
            acc.OwnerId = accOwnerUser.Id;
            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            insert acc;

            Map<String, Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
            Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty1 Sales Play','1. Identify Need Create View');
            oppty1.AccountId = acc.Id;
            oppty1.CloseDate = Date.today().addMonths(4);
            oppty1.Partner_Forecast_Amount__c = 10;
            oppty1.Deal_Type__c='Direct';
            oppty1.stageName= '3. Verify Options';
            oppty1.recordtypeId = rtMap.get('Akamai Opportunity').getRecordTypeId();
            insert oppty1;
            
            Opportunity oppty2 = utilTestClass.CreateOpportunity('__Test Oppty2 Sales Play','1. Identify Need Create View');
            oppty2.AccountId = acc.Id;
            oppty2.CloseDate = Date.today().addMonths(4);
            oppty2.Partner_Forecast_Amount__c = 10;
            oppty2.Deal_Type__c='Direct';
            oppty2.stageName= '3. Verify Options';
            oppty2.recordtypeId = rtMap.get('Akamai Opportunity').getRecordTypeId();
            insert oppty2;
            
            List<Product2> productList = new List<Product2>();
            Product2 testProduct1= new Product2();
            testProduct1.Name = 'Test_Security_Product';
            testProduct1.family = 'Security';
            testProduct1.AKAM_INT_ID__c = 111;
            testProduct1.AKAM_Product_ID__c='F-PR-4575';
            productList.add(testProduct1);
            
            Product2 testProduct2= new Product2();
            testProduct2.Name = 'Test_Security_Product 1';
            testProduct2.family = 'Security';
            testProduct2.AKAM_INT_ID__c = 112;
            testProduct2.AKAM_Product_ID__c='F-PR-4576';
            productList.add(testProduct2);
            
           
            insert productList;
            
            String pId = String.valueOf(testProduct1.Id).substring(0, 15);
            
            List<PricebookEntry> pricebookList = new List<PricebookEntry>();
            PricebookEntry pbEntry= new PricebookEntry();
            pbEntry.Pricebook2Id = Test.getStandardPricebookId();
            pbEntry.Product2Id   = pId;
            pbEntry.CurrencyIsoCode = 'USD';
            pbEntry.IsActive     = true;
            pbEntry.UnitPrice    = 1; 
            pricebookList.add(pbEntry); 
            
            insert pricebookList;
            
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.opportunityId       = oppty1.id;
            oli.pricebookentryid    = pbEntry.Id;
            oli.quantity            = 1;
            oli.unitprice           = 200;
            oli.Average_Renewal_Commit_MRR__c = 100;
            oli.Average_Renewal_Usage_MRR__c = 100;
            oli.Projected_Monthly_commit_fees__c = 100;
            oli.Projected_Avg_Rev_Non_Commit__c = 100;
            insert oli;
             
            Sales_Play__c spRec = new Sales_Play__c();
            spRec.Start_Date__c = System.today();
            spRec.End_Date__c = System.today() + 5;
            spRec.Product_Id__c = pId;
            spRec.Name = 'Test Sales Play';
            spRec.Relevant_Products__c = 'Test_Security_Product';
            insert spRec;
        }
    }
    
    static testMethod void testManageSalesPlayController() {
        System.runAs(dmlUser) {
            manageSalesPlayProductsController mspObj = new manageSalesPlayProductsController();
            List<String> salesPlayNames = new List<String>();
            Map<String,String> productMap = new Map<String,String>();
            Set<Id> oppIds = new Set<Id>();
            Set<String> prodIds = new Set<String>();
            salesPlayNames.add('Test Sales Play');
            Sales_Play__c spRec = [select Id,Product_Id__c from Sales_Play__c 
                                   where Name in :salesPlayNames];
            Account accObj = [Select Id from Account where Name = '__Test Account SalesPlay'];
            
            List<OpportunityLineItem> oliList = [Select Id from OpportunityLineItem 
                                                 where Opportunity.Name = '__Test Oppty1 Sales Play'];
            Opportunity oppObj = [Select Id from Opportunity where Name = '__Test Oppty1 Sales Play'];
            Opportunity oppObj2 = [Select Id from Opportunity where Name = '__Test Oppty2 Sales Play'];
            oppIds.add(oppObj.Id);
            //PricebookEntry pe = [Select Id from PricebookEntry where Name = '__Test Oppty1 Sales Play'];
            Test.setCurrentPage(Page.manageSalesPlayProducts);
            ApexPages.currentPage().getParameters().put('Id',spRec.Id);

            mspObj.manageSalesPlayProductsCompSetUp();
            productMap = manageSalesPlayProductsController.fetchForecastingProducts(spRec.Id);
            productMap = new Map<String,String>();
            productMap.put(String.Valueof(spRec.Product_Id__c),'Test Sales Play');
            salesPlayNames = new List<String>();
            salesPlayNames.add(spRec.Product_Id__c);
            prodIds.add(spRec.Product_Id__c);
            String result = manageSalesPlayProductsController.saveForecastingProducts(spRec.Id,productMap,salesPlayNames);
            String productId = [select Id from Product2 where name = 'Test_Security_Product 1' limit 1][0].Id;
            productMap.put(productId,'Test_Security_Product 1');
            salesPlayNames.clear();
            salesPlayNames.add(productId);
            test.startTest();
            result = manageSalesPlayProductsController.saveForecastingProducts(spRec.Id,productMap,salesPlayNames);
            Account_Sales_Play_Association__c ASPARec = new Account_Sales_Play_Association__c();
            ASPARec.Sales_Play__c = spRec.Id;
            ASPARec.Account__c = accObj.Id;
            insert ASPARec;
            Opportunity_Sales_Play_Association__c ospa = new Opportunity_Sales_Play_Association__c();
            ospa.Opportunity__c = oppObj2.Id;
            ospa.Sales_Play__c = spRec.Id;
            insert ospa;
            
            Delete ASPARec;
            Delete spRec;
            test.stopTest();
        }
    }
    
    static testMethod void deleteOpportunitySalesPlayTest() {
        
        User businessOps = [select Id from User where Profile.Name = 'Business Operations' and IsActive=true limit 1][0];
        Opportunity oppObj = [Select Id, AccountId from Opportunity where Name = '__Test Oppty1 Sales Play'];
        Sales_Play__c spRec = [select Id,Product_Id__c from Sales_Play__c where Name = 'Test Sales Play'];
        List<OpportunityLineItem> oliList = [Select Id from OpportunityLineItem where Opportunity.Name = '__Test Oppty1 Sales Play'];
        oppObj.StageName = 'Closed Won';
        oppObj.No_of_Contracts__c = '1';
        oppObj.Validation_Override__c = true;
        Test.startTest();
        Account_Sales_Play_Association__c ASPARec = new Account_Sales_Play_Association__c();
        ASPARec.Sales_Play__c = spRec.Id;
        ASPARec.Account__c = oppObj.AccountId;
        insert ASPARec;
        update oppObj;
        system.runAs(businessOps){
            delete oliList;
            manageSalesPlayProductsController.deleteOpportunitySalesPlay(new Set<Id>{oppObj.Id});
        }
        Test.stopTest();
    }
}