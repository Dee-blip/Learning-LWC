@isTest(SeeAllData=false)
private class PSASetAccountCurrencyTest
{
    public static Account acct;
    public static User usr;
    public static PSA_Products__c p;
    static
    {
        // SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        // scSetting.Name = 'BOCC';
        // scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scSetting.Product_Id__c = 'M-LC-160618';
        // insert scSetting;
        utilTestClass.createCustomSettings();    
        PSA_TestUtility testUtil = new PSA_TestUtility();
        
        acct = testUtil.newAccount(true);        
        usr = testUtil.newUserSysAdmin(true); 
        
        p = new PSA_Products__c();
        p.Name='2123';
        p.Product_Name__c='Cotendo Professional Services';
        insert p;        
    }
    
    static testMethod void testForActiveContracts()
    {               
        
        Merge_Contract_Header__c contract = new Merge_Contract_Header__c();
        contract.Account_Name__c = acct.Id;
        contract.Active__c = true;
        contract.Currency__c = 'SGD';
        contract.Effective_Start_Date__c = System.TODAY();
        contract.Effective_End_Date__c = System.TODAY()+10;
        insert contract;
        
        Merge_Contract_Detail__c contractDetail = new Merge_Contract_Detail__c();
        contractDetail.Original_Contract_Id__c = contract.Id;
        contractDetail.Product__c = 'Cotendo Professional Services';
        contractDetail.Effective_End_Date__c = System.TODAY()+20;
        insert contractDetail;                       
        
        /* Test for non expired contracts */
        Test.startTest();
        setAccountCurrency accCur = new setAccountCurrency();
        Database.executeBatch(accCur,200);
        Test.stopTest();
        
    }
    
     static testMethod void testForExpiredContracts()
    {       
               
        /* Test for expired contracts */
        Merge_Contract_Header__c contract1 = new Merge_Contract_Header__c();
        contract1.Account_Name__c = acct.Id;
        contract1.Active__c = true;
        contract1.Currency__c = 'TWD';
        contract1.Effective_Start_Date__c = System.TODAY();
        contract1.Effective_End_Date__c = System.TODAY()+10;
        insert contract1;
        
        Merge_Contract_Detail__c contractDetail1 = new Merge_Contract_Detail__c();
        contractDetail1.Original_Contract_Id__c = contract1.Id;
        contractDetail1.Product__c = 'Cotendo Professional Services';
        contractDetail1.Effective_End_Date__c = System.TODAY()-1;
        insert contractDetail1;        
        
        /* Test for non expired contracts */
        Test.startTest();
        setAccountCurrency accCur = new setAccountCurrency();
        Database.executeBatch(accCur,200);
        Test.stopTest();
        
    }
    
    //Call the scheduler class - PSA_SETCURRENCY
    public static testmethod void testForScheduler()
    {
        test.startTest();
        PSA_SETCURRENCY testSc = new PSA_SETCURRENCY();
        String jobId = System.schedule('testPSASetCurrency', '0 0 0 3 9 ? 2022', testSc);
        test.stopTest();
    }
}