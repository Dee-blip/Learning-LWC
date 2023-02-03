@isTest(seeAllData=false)
public class RenewalOpportunityCreationTestClass
{
    static{
        utilTestClass.insertCustomSettings();
    }

    private static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId, String currencyString)
    {
        Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = pOrignalContractId;
        newHeader.Name = pOrignalContractId;
        Integer numDays = 30 ;
        newHeader.Effective_End_Date__c = Date.today().addmonths(6);
        newHeader.Account_Name__c = pAccountId; 
        newHeader.Active__c= true;
        newHeader.Currency__c = currencyString;
        return newHeader;
    }
    
    static testmethod void testRenewalOpportunityBatchJobTest()
    {
        Test.startTest();
        Account account = utilTestClass.CreateAccount('Test_Account');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity   = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '99992';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        account.Parent_Division__c = 'Web EMEA_Web' ; // SFDC 7061
        insert account;

        List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
        Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C-YJSEX11', account.Id,'USD');
        mchList.add(renewalContract1);

        Merge_Contract_Header__c renewalContract2 = CreateContractHeader('C-YJSEX12', account.Id,'USD');
        renewalContract2.Auto_Renew__c = 'Standard - 30';
        mchList.add(renewalContract2);

        insert mchList;


        List<Contract_Product__c> cpList = new List<Contract_Product__c>();
        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;
        contractProduct1.Forecast_Product_Id__c = 'Prod-12';
        contractProduct1.Effective_End_Date__c = Date.today().addmonths(4);
        cpList.add(contractProduct1);

        Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract2.Original_Contract_Id__c,'PROD-124','AKAM-124');
        contractProduct2.Average_Renewal_Commit_MRR__c = 200;
        contractProduct2.Average_Renewal_Usage_MRR__c = 200;
        contractProduct2.UnitPrice__c = 1;
        contractProduct2.Original_Contract_id__c = renewalContract1.Id;
        contractProduct2.Forecast_Product_Id__c = 'Prod-22';
        contractProduct1.Effective_End_Date__c = Date.today().addmonths(5);
        cpList.add(contractProduct2);
       
        insert cpList;

        List<Pricebook2> pbList = new List<Pricebook2>();
        Pricebook2 pb = new Pricebook2();
        pb.name = 'Standard Price Book 2009';
        pb.Description = 'Price Book 2009 Products';
        pb.isactive = true;
        pbList.add(pb);

        Pricebook2 pb2 = new Pricebook2();
        pb2.name = 'Standard Price Book 2010';
        pb2.Description = 'Price Book 2010 Products';
        pb2.isactive = true;
        pbList.add(pb2);

        insert pbList;

        Id pbId = Test.getStandardPricebookId();

        List<Product2> product2List = new List<Product2>();
        Product2 p = new Product2();
        p.Name = 'TEST';
        p.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;
        product2List.add(p);

        Product2 p2 = new Product2();
        p2.Name     = 'TEST';
        p2.Akam_Product_Id__c = contractProduct2.Forecast_Product_Id__c;
        product2List.add(p2);

        insert product2List;

        /* Create a pricebook entry. */
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pbId;
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        pbe.UseStandardPrice = false;

        Database.insert(pbe);

        Id pbId2 = Test.getStandardPricebookId();


        /* Create a pricebook entry. */
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = pbId2;
        pbe2.Product2Id   = p2.id;
        pbe2.IsActive     = true;
        pbe2.UnitPrice    = 1;
        pbe2.UseStandardPrice = false;

        Database.insert(pbe2);
        
        RenewalOpportunityCreationClass obj= new RenewalOpportunityCreationClass();
        Database.executebatch(obj);

        Test.stopTest();
       
    }

    static testmethod void nonCoTerminusDataFixBatchClass(){
        
        Account acc = utilTestClass.CreateAccount('Test_Account');
        acc.BillingStreet = '#39,7th Cross';
        acc.BillingCity   = 'LA';
        acc.BillingState = 'CA';
        acc.BillingPostalCode = '99992';
        acc.BillingCountry = 'USA';
        acc.Type='Lead';
        acc.Parent_Division__c = 'Web EMEA_Web' ; // SFDC 7061
        insert acc;

        Merge_Contract_Header__c renewalContract = CreateContractHeader('C-YJSEX11', acc.Id,'USD');
        insert renewalContract;

        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract.Id;
        contractProduct1.Forecast_Product_Id__c = 'F-PR-4573';
        contractProduct1.Effective_End_Date__c = Date.today().addmonths(4);
        insert contractProduct1;

        test.startTest();

        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        insert oppty;

        Product2 testProduct= new Product2();
        testProduct.Name = 'Test_Service_Product';
        testProduct.family = 'Service';
        testProduct.AKAM_INT_ID__c = 333;
        testProduct.AKAM_Product_ID__c = 'F-PR-4573';
        insert testProduct;

        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry.Product2Id   = testProduct.id;
        pbEntry.CurrencyIsoCode = 'USD';
        pbEntry.IsActive     = true;
        pbEntry.UnitPrice    = 1; 
        insert pbEntry;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.opportunityId       = oppty.id;
        oli.pricebookentryid    = pbEntry.Id;
        oli.quantity            = 1;
        oli.unitprice           = 200;
        oli.Average_Renewal_Commit_MRR__c = 100;
        oli.Average_Renewal_Usage_MRR__c = 100;
        oli.Projected_Monthly_commit_fees__c = 100;
        oli.Projected_Avg_Rev_Non_Commit__c = 100;
        insert oli;

        Renewal_Contract_Object__c renewalContractRecord    = new Renewal_Contract_Object__c();
        renewalContractRecord.Name = renewalContract.Original_Contract_Id__c;
        renewalContractRecord.Contract__c = renewalContract.Id;
        renewalContractRecord.Opportunity__c = oppty.id;
        renewalContractRecord.Contract_Id_Text__c = renewalContract.Original_Contract_Id__c;
        renewalContractRecord.Contract_Effective_End_Date__c  = oppty.closeDate;
        insert renewalContractRecord;

        nonCoTerminusDataFixBatchClass obj1 = new nonCoTerminusDataFixBatchClass();
        Database.executebatch(obj1);
    
        test.stopTest();
    }
}