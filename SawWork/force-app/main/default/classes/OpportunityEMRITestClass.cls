@isTest
public class OpportunityEMRITestClass {


 	@testSetup
 	static void createTestData()
	{
		utilTestClass.insertCustomSettings(new List<String>{'GSM_Custom_Settings'});
		
		Account account = utilTestClass.CreateAccount('Test_Account');
		account.BillingStreet = '#39,7th Cross';
		account.BillingCity	  = 'LA';
		account.BillingState = 'CA';
		account.BillingPostalCode = '56005';
		account.BillingCountry = 'USA';
        account.Type='Lead';
		insert account;

        List<Merge_Contract_Header__c> mchList = new List<Merge_Contract_Header__c>();
		Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C - YJSEX11', account.Id,'USD'  );
		Merge_Contract_Header__c renewalContract2 = CreateContractHeader('C - YJSEX10', account.Id ,'SGD' );
        mchList.add(renewalContract1);
        mchList.add(renewalContract2);
        insert mchList;
        renewalContract1.Account_Name__c =account.id;
        update mchList;


        


        Pricebook2 pb = new Pricebook2();
        pb.name = 'Standard Price Book 2009';
        pb.Description = 'Price Book 2009 Products';
        pb.isactive = true;


        insert pb;

        Id pbId = Test.getStandardPricebookId();
        


        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.Akam_Product_Id__c = 'F-PR-4575';	
        p.IsActive     = true;	
        p.CurrencyIsoCode = 'INR';

        Database.insert(p);

        p = [Select Name,Akam_Product_Id__c from Product2 where Name = 'Test'];
        /* Create a pricebook entry. */
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pbId;
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        pbe.CurrencyIsoCode = 'INR';
        //pbe.UseStandardPrice = false;
       // pbe.product2.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;

        Database.insert(pbe);

        Product2 p1 = new Product2();
        p1.Name     = 'TEST2';
        p1.IsActive     = true;	
        p1.CurrencyIsoCode = 'INR';	
        p1.Akam_Product_Id__c = 'F-PR-4576';

        Database.insert(p1);
		p1 = [Select Name,Akam_Product_Id__c from Product2 where Name = 'Test2'];
        /* Create a pricebook entry. */
        PricebookEntry pbe2 = new PricebookEntry();
        pbe2.Pricebook2Id = pbId;
        pbe2.Product2Id   = p1.id;
        pbe2.IsActive     = true;
        pbe2.UnitPrice    = 1;
                //pbe2.UseStandardPrice = false;

        //pbe2.product2.Akam_Product_Id__c = contractProduct2.Forecast_Product_Id__c;

        
        Database.insert(pbe2);

        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD - 123','AKAM - 123');	
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;	
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;	
        contractProduct1.UnitPrice__c = 1;	
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;	
        contractProduct1.Forecast_Product_Id__c = p.Akam_Product_Id__c;	

		Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract2.Original_Contract_Id__c ,'PROD - 124','AKAM - 124');	
		contractProduct2.Average_Renewal_Commit_MRR__c = 400;	
        contractProduct2.Average_Renewal_Usage_MRR__c = 400;	
        contractProduct2.UnitPrice__c = 1;	
        contractProduct2.Original_Contract_id__c = renewalContract2.Id;	
        contractProduct2.Forecast_Product_Id__c = p1.Akam_Product_Id__c;	

        List<Contract_Product__c> contractProducts = new List<Contract_Product__c>();	
        contractProducts.add(contractProduct1);	
        contractProducts.add(contractProduct2);	
        insert contractProducts;

		Opportunity oppty = utilTestClass.CreateOpportunity('Test_Opportunity', '1-Create');
		oppty.AccountId	  = account.Id;
		oppty.CurrencyIsoCode = 'INR'; 
		oppty.CloseDate   = System.today(); 
		insert oppty;

		//Create Renewal Opptys
		List<Opportunity> renewalOpptyList = new List<Opportunity>();
		for(Integer i=1;i<9;i++)
		{
			Opportunity opptyRec = utilTestClass.CreateOpportunity('Test_Oppty_renewal'+i, '1-Create');
			opptyRec.AccountId	  = account.Id;
			opptyRec.CurrencyIsoCode = 'INR'; 
			opptyRec.CloseDate   = System.today(); 
			renewalOpptyList.add(opptyRec);
		}
		
		insert renewalOpptyList;

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

		Account account = [select id, name from account limit 1];

		Opportunity oppty = [select id, name,AccountId,CurrencyIsoCode,CloseDate,RecordTypeId from Opportunity where name ='Test_Opportunity' Limit 1];

		Merge_Contract_Header__c renewalContract1 = [select id,name,Original_Contract_id__c,Effective_End_Date__c,Account_Name__c,Active__c,Currency__c from  Merge_Contract_Header__c where Original_Contract_Id__c='C - YJSEX11' Limit 1];

		PageReference pageRef = Page.OpportunityCreateNew;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('accid',account.Id);
        
		ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
		OpportunityCreateNew controller = new OpportunityCreateNew(sc);

		controller.getContractBaselineOptions();
		String selectOptionWith = GSMUtilClass.getGSMSettingValue('ContractBaseLineOptionWith');
		controller.setContractBaselineOption(selectOptionWith);
		controller.getContractBaselineOption();
		controller.checkOptionValue();

		Test.startTest();
		List<OpportunityCreateNew.ContractWrapper> cwListC =  controller.getContractWrapper();
		controller.inputCheckForGetBaseline();
		for(OpportunityCreateNew.ContractWrapper cw :cwListC)
		{
			cw.Checkbox = true;
		}
		controller.getcurrencyOptions();
		controller.selectedcurrencyOption = 'Other Currency: ';
		controller.getCurrencies();
		controller.selectedcurrency = 'GBP';
		controller.inputCheckForRenewalOppty();
		controller.contractIdForProduct = renewalContract1.Original_Contract_id__c;
		
		List<OpportunityCreateNew.ContractProductWrapper> cpListC =  controller.getContractProductWrapper();
		controller.showContractProducts();
		controller.opportunityIdForContracts = oppty.Id;
		controller.showContractsAssociatedToOppty();
		controller.closeContractsAssociatedToOppty();
		controller.pageRedirect();
		controller.createOpportunity();
		List<String> listOfOriginalContractIds = new List<String>();
        Set<String> contractCurrencyList = new Set<String>();

		for(Merge_Contract_Header__c mch : controller.setOfSelectedContracts)
          {
            
            listOfOriginalContractIds.add(mch.Original_Contract_Id__c);
            contractCurrencyList.add(mch.Currency__c);
          }
		CreateRenewalOpptyWithMultipleContracts roc= new CreateRenewalOpptyWithMultipleContracts(listOfOriginalContractIds);
		roc.setOpportunityCurrency(controller.selectedCurrency);
        roc.setContractCurrency(contractCurrencyList);

        Opportunity opptyCreated;
        opptyCreated = roc.createRenewalOpportunityWithProducts(''); //SFDC-SFDC-3550 : Passed Parameter
        system.debug(LoggingLevel.ERROR,'HC Oppty Created  '+opptyCreated);
		if(opptyCreated != null)
			{
				roc.refreshOpportunityProducts(opptyCreated.Id);
				system.debug(LoggingLevel.ERROR,'Error din occured '+opptyCreated);

			}
 		else
			system.debug(LoggingLevel.ERROR,'Error occured ');
		system.assertEquals(opptyCreated!=null,true);
		
		PageReference pageRef2 = Page.OpportunityGetBaseline;
		Test.setCurrentPage(pageRef2);
		pageRef2.getParameters().put('currencyCode','USD');
		pageRef2.getParameters().put('opportunityID',oppty.id);
		pageRef2.getParameters().put('closeDate',System.today().addDays(30).format());
        
		//ApexPages.StandardController sc2 = new ApexPages.StandardController(oppty);
		OpportunityGetBaseline controller2 = new OpportunityGetBaseline(sc);
		controller2.execute();
		controller2.inputCheckForGetBaseline();
		controller2.getBaseline();
        Test.stopTest();

	}


}