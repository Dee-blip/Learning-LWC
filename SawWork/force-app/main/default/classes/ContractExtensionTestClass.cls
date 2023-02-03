/***
ContractExtensionTestClass

Requirements :
CR 1092945 Only Account team members and SA should be able to Extend Term from SF
CR 1115760 1Click Extension of term: More informative message on contract extension
- Covers test cases for ContractExtensionClass 

*/
@isTest
private class ContractExtensionTestClass 
{
    private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
    
    private static Boolean initFlag = false;
    private static User testUser;
    // Changes for CR 2842878 -rahul gaira(fix the Mixed Dml Exception)
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    private static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId)
    {
        Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = pOrignalContractId;
        newHeader.Name = pOrignalContractId;
        newHeader.Account_Name__c = pAccountId;    
        return newHeader;
    }
    /**
    Added by Chandra
    refreshContractHeaderList()
    */
    private static List<Merge_Contract_Header__c> refreshContractHeaderList(List<Merge_Contract_Header__c> contractList)
    {
        return [select Id,Account_Name__c,Bill_To_Contact__C,Contract_transferred_To__c,Opportunity_Name__c
                ,Parent_Account_Name__c,Parent_Contract__C,Referred_By_Account__C From Merge_Contract_Header__c where id IN :contractList];
    }
    
    /**
    Added By Chandra
    refreshContractHeader()
    */
    private static Merge_Contract_Header__c refreshContractHeader(Merge_Contract_Header__c contract)
    {
        return refreshContractHeaderList(new List<Merge_Contract_Header__c> {contract})[0];
    }
    
    // Create Opportunity reuse function
    private static Opportunity CreateOpportunity(String stageName)
    {
        Opportunity opp = new Opportunity();
        opp.Name = '__Test Oppty';
        opp.StageName = '1-Create';
        return opp;
    } 
    
    // Create Order Approval Refresh function
    private static Order_Approval__c RefreshOrderOpp(String OrderAppId)
    {
        return [select  Id, 
                
                Approvals_Required__c, 
                Associated_Opportunity__c, 
                RecordTypeId, 
                CCG_Owner__c, 
                Deal_Desk_Owner__c,
                Legal_Owner__c, 
                CCG__c, 
                Deal_Desk__c, 
                Legal__c, 
                CCG_Approved_Date__c,
                Compliance_Issue_Type__c,
                Gross_Margin__c,
                Commission_Exception__c,
                CCG_Status__c,
                Deal_Desk_Status__c,
                Legal_Status__c
                from Order_Approval__c 
                where Id=:OrderAppId][0];
    } 
    
    // Create Opportunity Refresh function
    private static Opportunity RefreshOpportunity(String OppId)
    {
        return [select  Id, 
                CCG__c, 
                Type,
                StageName,
                RecordTypeId,
                Deal_Desk__c, 
                Legal_Control__c, 
                CCG_Approved_Date__c, 
                Compliance_Issue_Type__c,
                Gross_Margin__c,
                Commission_Exception__c                
                from Opportunity where Id=:OppId];
        
    } 
    
    // Create Order Approval Refresh function
    private static Order_Approval__c RefreshOrderOppAs(String OrderAppAsId)
    {
        return  [select Id, 
                 Associated_Opportunity__c, 
                 RecordTypeId, 
                 CCG_Owner__c, 
                 Deal_Desk_Owner__c,
                 Legal_Owner__c, 
                 CCG__c, 
                 Deal_Desk__c, 
                 Legal__c ,
                 Type__c,
                 CCG_Status__c
                 from Order_Approval__c 
                 where Associated_Opportunity__c=:OrderAppAsId][0];
    }
    
    /**
    Init()
    - Intialize the static variables for this Test Class
    */
    private static void Init()
    {
        if(initFlag)
            return;
        
        String profileName = 'Sales - Media';
        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        testUser = utilTestClass.CreateUser('TST_OUSR', roleName, profileName);
        insert testUser;
        initFlag = true;        
    }
    
    static testMethod void Contract_BED_Deferment_Button_SingleTest_Positive() 
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;

        ContractExtensionClass c1 =new ContractExtensionClass();
        c1.init();
        Account acc = utilTestClass.CreateAccount('_##Test Account 1');
        insert acc;
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(30);
        insert opp;
        Test.startTest();
        // Create Order Approval
        Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        insert oa;
        Merge_Contract_Header__c header = CreateContractHeader('#Test-FC-MCH1', acc.Id);
        header.BEDDeferment_OA_Id__c = oa.Id;
        insert header;
        String results; 
        
        // Use the CI field to associate to Header.
        // Call the button function from here.
        results = ContractExtensionClass.isContractExtensionEnabledProfileCheck( header.Id, 'BEDD', acc.Id );
        Test.stopTest();
    }
    
    static testMethod void Contract_Extension_Button_SingleTest_Positive() 
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        System.runAs(dmlUser){
            Init();
        }
        Account acc = utilTestClass.CreateAccount('_##Test Account 1');
        insert acc;
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(30);
        insert opp;
        Test.startTest();
        // Create Order Approval
        Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        insert oa;
        Merge_Contract_Header__c header = CreateContractHeader('#Test-FC-MCH1', acc.Id);
        header.BEDDeferment_OA_Id__c = oa.Id;
        insert header;
        String results; 
        
        system.runAs(testUser)
        {
            results = ContractExtensionClass.isContractExtensionEnabledProfileCheck( header.Id, 'CE', acc.Id );
            Test.stopTest();
        }
        // Assert
        system.assertNotEquals(results, '1:SUCCESS');
    }
    
    /*
    RenewalOpptyCheck_Positive()
    - To check if the manual renewal process from Contract is working by setting the Renewal_Process_Status__c = Pending for the contract. 
    */
    /* SFDC - 5392. Removed checkDuplicateRenewalOppty method from ContractExtensionClass
    static testMethod void RenewalOpptyCheck_Positive()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        System.runAs(dmlUser){
            Init();
        }
        Account acc = utilTestClass.CreateAccount('__TestAccount_renewalOppty');
        insert acc;
        
        Merge_Contract_Header__c header = CreateContractHeader('#Test-FC-MCH1', acc.Id);
        insert header;
        
        Opportunity opp = utilTestClass.CreateOpportunity('__TestOppty', 'Closed Won');
        opp.AccountId = acc.Id;
        opp.CloseDate = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp.Opportunity_Type__c = 'Renewal';
        opp.Validation_Override__c=true;
        insert opp;
        
        String result = '';
        
        Test.startTest();
        result = ContractExtensionClass.checkDuplicateRenewalOppty(header.Original_Contract_Id__c);
        Test.stopTest();
        
        System.assertEquals(result,'1:Confirm');
        
        Merge_Contract_Header__c h = [SELECT Id, Original_Contract_Id__c, Renewal_Process_Status__c FROM Merge_Contract_Header__c WHERE Original_Contract_Id__c =: header.Original_Contract_Id__c];
        
        System.assertEquals(h.Renewal_Process_Status__c,'Pending');
        
    }*/
    
    /*
    RenewalOpptyCheck_Negative()
    - To check contract is not submitted when there is an existing Oppty associated to it.
    */ 
    /* SFDC - 5392. Removed checkDuplicateRenewalOppty method from ContractExtensionClass
    static testMethod void RenewalOpptyCheck_Negative()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        System.runAs(dmlUser){
            Init();
        }
        Account acc = utilTestClass.CreateAccount('__TestAccount_renewalOppty');
        insert acc;
        
        Merge_Contract_Header__c header = CreateContractHeader('#Test-FC-MCH1', acc.Id);
        insert header;
        
        Opportunity opp = utilTestClass.CreateOpportunity('__TestOppty', '4-Prove');
        opp.AccountId = acc.Id;
        opp.CloseDate = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp.Opportunity_Type__c = 'Renewal';
        opp.Renew_Contract_Id_Text__c = header.Original_Contract_Id__c;
        opp.Validation_Override__c=true;
        insert opp;
        
        String result = '';
        
        Test.startTest();
        result = ContractExtensionClass.checkDuplicateRenewalOppty(header.Original_Contract_Id__c);
        Test.stopTest();
        
        System.assert(result.startsWith('2:'));
    }
    */
    
}