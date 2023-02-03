@isTest(seeAllData=false)
public class ViewContractProductPageControllerTest {

    static{
        utilTestClass.insertCustomSettings();
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
    newHeader.Currency__c = currencyString;
    return newHeader;
  }
    
    static testmethod void insertRenewalOpportunityTestMethod() {

        Account account = utilTestClass.CreateAccount('Test_Account');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity   = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '50052';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        insert account;

        Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C-YJSEX11', account.Id,'USD'  );
            insert renewalContract1;

        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;
        contractProduct1.Forecast_Product_Id__c = 'Prod-12';
        insert contractProduct1;

        Merge_Contract_Header__c renewalContract2 = CreateContractHeader('C-YJSEX10', account.Id ,'SGD' );
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



        Opportunity oppty = utilTestClass.CreateOpportunity('Test_Opportunity', '1-Create');
        oppty.AccountId   = account.Id;
        oppty.CurrencyIsoCode = 'INR'; 
        oppty.CloseDate   = System.today(); 
        insert oppty;

        //Create Renewal Opptys
        List<Opportunity> renewalOpptyList = new List<Opportunity>();
        for(Integer i=1;i<9;i++)
        {
            Opportunity opptyRec = utilTestClass.CreateOpportunity('Test_Oppty'+i, '1-Create');
            opptyRec.AccountId    = account.Id;
            opptyRec.CurrencyIsoCode = 'INR'; 
            opptyRec.CloseDate   = System.today(); 
            renewalOpptyList.add(opptyRec);
        }
        
        insert renewalOpptyList;


        PageReference pageRef = Page.OpportunityCreateNew;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('contractId',renewalContract1.Id);
        pageRef.getParameters().put('contractName',renewalContract1.Name);

        ViewContractProductPageController controller = new ViewContractProductPageController();

        controller.getProducts();
    }


}