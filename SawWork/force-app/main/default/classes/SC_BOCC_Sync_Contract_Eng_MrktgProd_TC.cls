/*=====================================================================================================+
    Class name          :   SC_Autogen_AllUseCase_TC 
    Author              :   Himanshu Kar
    Created             :   14-MAR-17
    Purpose             :   This test class is used to cover code for below Components
                            1. SC_Sync_Contract_Eng_MrktgProd_Batch (class)
                            2. RecalculateEnggProductSync (Trigger)
                            
    Last Modified   Developer                   Purpose            
    =============   =========                   =======
    14-MAR-17     Himanshu                  Initial Development 
    09-OCT-17   Vandhana Krishnamurthy      Coverage for CaseTriggerClass as part of ESESP-354
    26-April-18 Vandhana Krishnamurthy      Added testcases for SC_Sync_SupportAdvocacy_Batch
+=====================================================================================================*/

@isTest
public class SC_BOCC_Sync_Contract_Eng_MrktgProd_TC
{
        // For Account Record
        public static Account accRec;
    
        // For Contract Header Record
        public static List<Merge_Contract_Header__c> contrctList;
        
        public static List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> allCEPDInsertList;
    
    // Method-1: Creating Test Data for Account + Contract Header
    public static void testDataSetup()
    {    
        //Create All custom setting to set seeAllData=false
        utilTestClass.createCustomSettings();
        
        //Creating a custom setting instance
        SC_SupportEmail__c scemail = new SC_SupportEmail__c();
        scemail.Support_Email_AMS__c = 'eae-ops-qa-qa@akamai.com';
        scemail.Name='1';
        insert scemail;
        
    
        // 1. For Account Record
        accRec = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-111-ABC-XYZ',Type='Brand - Active',Parent_Division__c='APJ_');
        accRec.Support_Advocate__c = true;
        insert accRec;
        
        // 2. For Contract Record Creation
        contrctList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c merge_contract;
        for(integer count =0; count < 5 ; count++)
        {
            merge_contract = new Merge_Contract_Header__c();
            merge_contract.Name                     ='Test Merge Contract-' + count;
            merge_contract.Contract_Id__c           ='Test-123-' + count;
            merge_contract.Original_Contract_Id__c  = 'Test-123-ABC-XYZ-' + count;
            merge_contract.Account_Name__c          = accRec.Id;
            merge_contract.Effective_Start_Date__c  = system.Today().addDays(-64);
            merge_contract.Effective_End_Date__c    = system.Today().addMonths(6);
            merge_contract.Active__c                = true;
            
            contrctList.add(merge_contract);
        }
        
        Insert contrctList;
        
        // Map to store BOCC Engg Product Name + Display Name
        Map<string,string> BOCCProdmap = new Map<string,string>();
        for (SC_BOCC_Entitlement_Product__mdt eachRec : [select Mapping_Prod_Name__c,MasterLabel  from 
                                                         SC_BOCC_Entitlement_Product__mdt WHERE MasterLabel != ''])
        {
            BOCCProdmap.put(eachRec.Mapping_Prod_Name__c, eachRec.MasterLabel);                     
        }
        
        // Map to store Support Advocacy Product Name + Display Name
        Map<String,String> suppAdvoProdmap = new Map<String,String>();
        for (SC_Utility__mdt eachRec : [SELECT Value_Text__c,MasterLabel
                                        FROM SC_Utility__mdt 
                                        WHERE MasterLabel = 'Support Advocacy Products' AND Active__c = TRUE])
        {
            suppAdvoProdmap.put(eachRec.Value_Text__c, eachRec.MasterLabel);                     
        }
    
        // 3. For CONTRACT_ENGINEERING_PRODUCT_DETAIL__c creation
        allCEPDInsertList = new List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
        CONTRACT_ENGINEERING_PRODUCT_DETAIL__c forachCEPDRec;
        
        for(string eachEnggProd : BOCCProdmap.keyset())
        {    
            forachCEPDRec = new CONTRACT_ENGINEERING_PRODUCT_DETAIL__c();
            forachCEPDRec.CONTRACT_ID__c      = 'Test-123-ABC-XYZ-0';
            forachCEPDRec.EFFECTIVE_START_DATE__c = system.Today().addDays(-60);
            forachCEPDRec.EFFECTIVE_END_DATE__c   = system.Today().addMonths(6);
            forachCEPDRec.ENGINEERING_PRODUCT_NAME__c = eachEnggProd;
            forachCEPDRec.MARKETING_PRODUCT_ID__c = 'M-LC-101';
            forachCEPDRec.MARKETING_PRODUCT_NAME__c = 'ION';
            forachCEPDRec.UNIQUE_KEY__c     = 'Test-123-ABC-XYZ-0' + 'M-LC-101' + eachEnggProd;
            allCEPDInsertList.add(forachCEPDRec);
        }
        
        for(string eachSAProd : suppAdvoProdmap.keyset())
        {    
            forachCEPDRec = new CONTRACT_ENGINEERING_PRODUCT_DETAIL__c();
            forachCEPDRec.CONTRACT_ID__c      = 'Test-123-ABC-XYZ-1';
            forachCEPDRec.EFFECTIVE_START_DATE__c = system.Today().addDays(-60);
            forachCEPDRec.EFFECTIVE_END_DATE__c   = system.Today().addMonths(6);
            forachCEPDRec.ENGINEERING_PRODUCT_NAME__c = 'Support::Support_Advocacy';
            forachCEPDRec.MARKETING_PRODUCT_ID__c = 'M-LC-102';
            forachCEPDRec.MARKETING_PRODUCT_NAME__c = 'Support Advocacy';
            forachCEPDRec.UNIQUE_KEY__c     = 'Test-123-ABC-XYZ-1' + 'M-LC-102' + eachSAProd;
            allCEPDInsertList.add(forachCEPDRec);
        }
        
        insert allCEPDInsertList;
        
    }
       
      
      // Method# 1 -Test Case: SC_Sync_Contract_Eng_MrktgProd_Batch class
    static testmethod void Test_BatchJob()  
    {
        testDataSetup();
        
        //Creating a custom setting instance
        SC_SupportEmail__c scemail = new SC_SupportEmail__c();
        scemail.Support_Email_AMS__c = 'eae-ops-qa-qa@akamai.com';
        scemail.Name='1';
        insert scemail;
        
        // Update the Custom Setting Value with Past Time Stamp for Last Run
        SC_SupportEmail__c UpdateLastRun = SC_SupportEmail__c.getValues('1');
        UpdateLastRun.Last_EngMrktgProd_Synch_Job_Run__c = system.now().addMonths(-6);
        UpdateLastRun.Last_SupportAdvocacy_EngProd_Job_Run__c = system.now().addMonths(-6);
        Update UpdateLastRun;
        
        Account acc = [Select Id,Name,Support_Advocate__c from Account where Name = 'Test Account1'];
        Case casenew = new Case(AccountId = acc.Id,Subject = 'Test Case Notification');
        casenew.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();
        insert casenew;
        
        test.startTest();
            Database.executeBatch(new SC_Sync_Contract_Eng_MrktgProd_Batch());
            
            Database.executeBatch(new SC_Sync_SupportAdvocacy_Batch());
            System.assertEquals(true,acc.Support_Advocate__c);
            
            PageReference pageRef = Page.SC_showContractDetOnCase;
            pageRef.getParameters().put('id', casenew.Id);
            Test.setCurrentPage(pageRef);
          
            ApexPages.StandardController sc = new ApexPages.StandardController(acc);
            
            SC_Sync_Contract_Eng_MrktgProd_Batch testObj = new SC_Sync_Contract_Eng_MrktgProd_Batch(sc);
        
            List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> lst =  testObj.getBoccDataForCasePage();
            testObj.first();testObj.last();testObj.next();testObj.previous();
            Boolean b = testObj.hasNext; b = testObj.hasPrev;
            Integer i = testObj.getPageNumber;i = testObj.getTotalPageNumber;
            test.stopTest(); 
    }
    
      // Method# 1 -Test Case: RecalculateEnggProductSync Trigger
    static testmethod void Test_Trigger()  
    {
       testDataSetup();
                  
        test.startTest();
            delete[select Id from CONTRACT_ENGINEERING_PRODUCT_DETAIL__c where UNIQUE_KEY__c = 'Test-123-ABC-XYZ-0M-LC-101Managed_Media_Services::Managed_Media_Services'];
            delete[select Id from CONTRACT_ENGINEERING_PRODUCT_DETAIL__c where UNIQUE_KEY__c = 'Test-123-ABC-XYZ-0M-LC-101Services_and_Support::Services_and_Support'];
            delete[select Id from CONTRACT_ENGINEERING_PRODUCT_DETAIL__c where UNIQUE_KEY__c = 'Test-123-ABC-XYZ-1M-LC-102Support::Support_Advocacy'];
        test.stopTest(); 
    }
    
    static testmethod void test_ProfessionalServCases()
    {
        testDataSetup();
        Account acc = [Select Id,Name from Account where Name = 'Test Account1'];
        
        // 3. For SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c creation
        List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> allBOCCProdInsertList = new List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c>();
        
        SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c foreachRec = new SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c();
        foreachRec.Account__c = acc.Id;
        foreachRec.Area__c = 'Professional_Services';
        foreachRec.Contract_ID__c  = 'Test-123-ABC-XYZ-0';
        foreachRec.Effective_Start_Date__c = system.Today().addDays(-60);
        foreachRec.Effective_End_Date__c   = system.Today().addMonths(6);
        foreachRec.Marketing_Product_Name__c = 'Guided Delivery Service';
        foreachRec.UNIQUE_KEY__c     = 'Test-123-ABC-XYZ-0' + 'M-LC-101' + 'GDS';
        allBOCCProdInsertList.add(foreachRec);
        
        foreachRec = new SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c();
        foreachRec.Account__c = acc.Id;
        foreachRec.Area__c = 'Professional_Services';
        foreachRec.Contract_ID__c  = 'Test-123-ABC-XYZ-0';
        foreachRec.Effective_Start_Date__c = system.Today().addDays(-60);
        foreachRec.Effective_End_Date__c   = system.Today().addMonths(6);
        foreachRec.Marketing_Product_Name__c = 'Kona DDoS Defender';
        foreachRec.UNIQUE_KEY__c     = 'Test-123-ABC-XYZ-0' + 'M-LC-101' + 'KDD';
        
        allBOCCProdInsertList.add(foreachRec);
        
        Insert allBOCCProdInsertList;
        
        List<Case> lstCase = new List<Case>();
        
        Case cs = new Case();
        cs.Description = 'testPreSales1';
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        cs.Subject = 'testPreSalesSub1';
        cs.Service__c = 'Managed Integration';
        cs.Validation_Override__c = true;
        cs.AccountId = acc.Id;
        lstCase.add(cs);
        
        Case cs1 = new Case();
        cs1.Description = 'Test Tech with SA';
        cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs1.Subject = 'Test Tech with SA';
        cs1.Sub_Type__c = 'Product Support';
        cs1.Do_Not_Show_in_Portal__c = false;
        cs1.Validation_Override__c = true;
        cs1.AccountId = acc.Id;
        lstCase.add(cs1);
        
        Test.startTest();
            insert lstCase;
            lstCase.clear();
            
            cs.Service__c = 'Technical Advisory Services';
            lstCase.add(cs);
            cs1.Escalate_Technical_Mgmt_Case__c = true;
            cs1.Technical_Mgmt_Escalation_Date__c = System.now();
            lstCase.add(cs1);
        
            try
            {
                update lstCase;
            }   
            catch(Exception e)
            {
                System.debug('Exception : ' + e);
            }
        Test.stopTest();
    }
      
  }