@isTest(seeAllData=false)
public class SF1_CreateOpportunityControllerTest {

    static testmethod void getOpptyCurrencyOptionsTest(){
        List<String> CurrList = SF1_CurrencySelectionController.getOpptyCurrencyOptions();
        Integer size= CurrList.size();
        //System.assertNotEquals(size,0);
    }


    // static testmethod void getOpportunitiesTest(){
    //     List<Opportunity> OpptyList = SF1_CreateOpportunityController.getOpportunities();
    //     Integer size= OpptyList.size();
    //     System.assertNotEquals(size,0);
    // }

    public static Renewal_Contract_Object__c CreateRenewalContract(Merge_Contract_Header__c contract, Id opptyId)
    {

        Renewal_Contract_Object__c renewalContract = new Renewal_Contract_Object__c();
        renewalContract.Name = contract.Original_Contract_Id__c;
        renewalContract.Contract__c = contract.Id;
        renewalContract.Opportunity__c = opptyId;
        renewalContract.Contract_Id_Text__c = contract.Original_Contract_Id__c;
        renewalContract.Contract_Effective_End_Date__c = contract.Effective_End_Date__c;
        //renewalContract.Parent_Contract__c = contract.Parent_Contract__c;
        renewalContract.Order_Id__c = contract.Order_Id__c;
        //renewalContract.Cancellation_Clause__c = contract.AK_Cancellation_Clause__c;
        renewalContract.Contract_Type__c = contract.Contract_Type__c;
        //renewalContract.Parent_Account_Name__c = contract.Parent_Account_Name__c;
        return renewalContract;
    }

    private static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId,String currencyString)
    {
        Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = pOrignalContractId;
        newHeader.Name = pOrignalContractId;
        Integer numDays = 30 ; //Integer.valueOf(GSM_Custom_Settings__c.getInstance('Contract_HierarchyEndDateDays').Value__c)+2;
        newHeader.Effective_End_Date__c = Date.today().addDays(-Integer.valueOf(numDays));
        newHeader.Account_Name__c = pAccountId;
        newHeader.Active__c= true;
        newHeader.Contract_Type__c = 'Direct';
        newHeader.Order_Id__c = 'asdaf';
        newHeader.Currency__c = currencyString;
        return newHeader;
    }

    static testmethod void getOpportunitiesByContractIdsTest(){
       Account account = utilTestClass.CreateAccount('Test_Account');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity      = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '50052';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        insert account;

        Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C-YJSEX45', account.Id,'USD'  );
        insert renewalContract1;

        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;
        contractProduct1.Forecast_Product_Id__c = 'Prod-12';
        insert contractProduct1;

        Merge_Contract_Header__c renewalContract2 = CreateContractHeader('C-YJSEX46', account.Id ,'SGD' );
            insert renewalContract2;

        Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract2.Original_Contract_Id__c ,'PROD-124','AKAM-124');
        contractProduct2.Average_Renewal_Commit_MRR__c = 400;
        contractProduct2.Average_Renewal_Usage_MRR__c = 400;
        contractProduct2.UnitPrice__c = 1;
        contractProduct2.Original_Contract_id__c = renewalContract2.Id;
        contractProduct2.Forecast_Product_Id__c = 'Prod-21';


        insert contractProduct2;


        Pricebook2 pb = new Pricebook2();
        pb.name = 'Standard Price Book 2009';
        pb.Description = 'Price Book 2009 Products';
        pb.isactive = true;

        insert pb;

        Id pbId = Test.getStandardPricebookId();



        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;

        Database.insert(p);


        /* Create a pricebook entry. */
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pbId;
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        pbe.UseStandardPrice = false;
       // pbe.product2.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;

        Database.insert(pbe);

        Product2 p1 = new Product2();
        p1.Name     = 'TEST2';
        p1.Akam_Product_Id__c = contractProduct2.Forecast_Product_Id__c;

        Database.insert(p1);

        /* Create a pricebook entry. */
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = pbId;
        pbe2.Product2Id   = p1.id;
        pbe2.IsActive     = true;
        pbe2.UnitPrice    = 1;
                pbe2.UseStandardPrice = false;

        //pbe2.product2.Akam_Product_Id__c = contractProduct2.Forecast_Product_Id__c;

        Database.insert(pbe2);

        List<Opportunity> opptyLists = new List<Opportunity>();

        Opportunity oppty = utilTestClass.CreateOpportunity('Test_Opportunity', '1. Identify Need');
        oppty.AccountId      = account.Id;
        oppty.CurrencyIsoCode = 'INR';
        oppty.CloseDate   = System.today();
        oppty.Opportunity_Type__c ='Renewal';
        opptyLists.add(oppty);

        Opportunity oppty2 = utilTestClass.CreateOpportunity('Test_Opportunity2', '1. Identify Need');
        oppty2.AccountId      = account.Id;
        oppty2.CurrencyIsoCode = 'INR';
        oppty2.CloseDate   = System.today();
        oppty2.Opportunity_Type__c ='Auto-Renewal';

        opptyLists.add(oppty2);

        insert opptyLists;

        List<Renewal_Contract_Object__c> renewalContractList = new List<Renewal_Contract_Object__c>();
        Renewal_Contract_Object__c renewalContractObj1 = CreateRenewalContract(renewalContract1, oppty.Id);
        renewalContractList.add(renewalContractObj1);

        Renewal_Contract_Object__c renewalContractObj2 = CreateRenewalContract(renewalContract2, oppty2.Id);
        renewalContractList.add(renewalContractObj2);

        Insert renewalContractList;

        //Create Renewal Opptys
        List<Opportunity> renewalOpptyList = new List<Opportunity>();
        for(Integer i=1;i<9;i++)
        {
            Opportunity opptyRec = utilTestClass.CreateOpportunity('Test_Oppty'+i, '1-Create');
            opptyRec.AccountId      = account.Id;
            opptyRec.CurrencyIsoCode = 'INR';
            opptyRec.CloseDate   = System.today();
            renewalOpptyList.add(opptyRec);
        }

        insert renewalOpptyList;

        List<String> contractIds =new List<String>();
        contractIds.add(renewalContract1.id);
        contractIds.add(renewalContract2.id);
        List<Opportunity> OpptyList = SF1_CreateOpportunityController.getOpportunitiesByContractIds(account.id,contractIds);
        Integer size= OpptyList.size();

        /**
            For - SF1_CreateOpportunityController
            - getRenewalContractsByOpttyId (LAST)
                - return: public static List<Renewal_Contract_Object__c> getRenewalContractsByOpttyId(String opptyId)
            - getOpportunitiesByAccountIdPaginated
                - public static ResultSetCustom getOpportunitiesByAccountIdPaginated(String accountId, Integer lim, Integer currentPage, String sortField, String sortOrder)
            - getOpportunitiesByContractIdsPaginated
                -  public static ResultSetCustom getOpportunitiesByContractIdsPaginated
                   (String accountId, String[] contractIds, Integer lim, Integer currentPage, String sortField, String sortOrder) { // contract -> mch: merge_contract_header__c

            - public ResultSetCustom(List<sObject> rw, Integer siz, Map<Id, sObject> rwMap)
            this.rows = rw;
            this.size = siz;
            this.rowsMap = rwMap;

        */

        SF1_CreateOpportunityController.ResultSetCustom opptybyAccIDs= SF1_CreateOpportunityController.getOpportunitiesByAccountIdPaginated(account.id, 10, 0, null, null);
        //System.assertEquals(Json.serialize(opptybyAccIDs), '');
        System.assertNotEquals(opptybyAccIDs.size, 0);
        System.assertNotEquals(null, opptybyAccIDs.rows);

        SF1_CreateOpportunityController.ResultSetCustom opptybyContractIDs= SF1_CreateOpportunityController.getOpportunitiesByContractIdsPaginated(account.id, contractIds, 10, 0, null, null);
        //System.assertEquals(Json.serialize(opptybyContractIDs), '');
        System.assertNotEquals(opptybyContractIDs.size, 0);
        System.assertNotEquals(null, opptybyContractIDs.rows);

        List<Renewal_Contract_Object__c> renwalContractList= SF1_CreateOpportunityController.getRenewalContractsByOpttyId(oppty.Id);
        //System.assertEquals(Json.serialize(renwalContractList), '');
        System.assertNotEquals(renwalContractList.size(), 0);

    }
     static testmethod void getOpportunitiesByAccountIdTest(){

        Account account = utilTestClass.CreateAccount('Test_Account');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity      = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '56002';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        insert account;

        Opportunity oppty = utilTestClass.CreateOpportunity('Test_Opportunity', '1-Create');
        oppty.AccountId      = account.Id;
        oppty.CurrencyIsoCode = 'INR';
        oppty.CloseDate   = System.today();
        insert oppty;

        List<Opportunity> OpptyList = SF1_CreateOpportunityController.getOpportunitiesByAccountId(account.id);
        Integer size= OpptyList.size();
        //System.assertNotEquals(size,0);

    }

     static testmethod void getOpptyCurrencyOptionsTestdsv(){

        Account account = utilTestClass.CreateAccount('Test_Account1');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity      = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '56005';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        insert account;
        
        List<Account> AccList =  SF1_CustomLookupController.fetchAccount('Test');
        Integer size= AccList.size();
        System.assertNotEquals(size,0);

        Account acc = [Select id from Account where name like 'Test_Account1'];
        List<Account> AccList1 =  SF1_CustomLookupController.fetchAccountBasedOnId(acc.id);
        size= AccList1.size();
        System.assertNotEquals(size,0);

    }
}