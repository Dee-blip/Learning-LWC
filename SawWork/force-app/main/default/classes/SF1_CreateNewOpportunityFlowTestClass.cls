/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 08-19-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-19-2021   apyati   Initial Version
**/
//@isTest(SeeAllData=true)
@isTest(SeeAllData=false)
private class SF1_CreateNewOpportunityFlowTestClass {

	//static{
 //       utilTestClass.insertCustomSettings();
 //   }

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
	
	static testmethod void newOpportunityFromRenewalContractsTest() {  


		// boilerplate data creation code start...

		Account account = utilTestClass.CreateAccount('Test_Account');
        account.Name ='Test_Account';
		account.BillingStreet = '#39,7th Cross'; 
		account.BillingCity	  = 'LA';
		account.BillingState = 'CA';
		account.BillingPostalCode = '98789';
		account.BillingCountry = 'USA';
        account.Type='Lead';
		insert account; 

		Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C-YJSEX11', account.Id+'','USD'  );
		renewalContract1.Account_Name__c = account.Id;
        insert renewalContract1;

        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;
        contractProduct1.Forecast_Product_Id__c = 'Prod-12';
        contractProduct1.Effective_Start_Date__c = System.today()+ 10;
        contractProduct1.Effective_End_Date__c = System.today()+ 100;

		insert contractProduct1;

		Merge_Contract_Header__c renewalContract2 = CreateContractHeader('C-YJSEX10', account.Id ,'SGD' );
		renewalContract2.Account_Name__c = account.Id;
        insert renewalContract2;

		Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract2.Original_Contract_Id__c ,'PROD-124','AKAM-124');
		contractProduct2.Average_Renewal_Commit_MRR__c = 400;
        contractProduct2.Average_Renewal_Usage_MRR__c = 400;
        contractProduct2.UnitPrice__c = 1;
        contractProduct2.Original_Contract_id__c = renewalContract2.Id;
        contractProduct2.Forecast_Product_Id__c = 'Prod-21';
		contractProduct2.Effective_Start_Date__c = System.today()+ 10;
        contractProduct2.Effective_End_Date__c = System.today()+ 100;
		insert contractProduct2;


        Id pbId = Test.getStandardPricebookId();
        
        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;
        p.IsActive =true;
        Database.insert(p);


        Product2 p1 = new Product2();
        p1.Name     = 'TEST2';
        p1.Akam_Product_Id__c = contractProduct2.Forecast_Product_Id__c;
        p1.IsActive =true;
        Database.insert(p1);


        /* Create a pricebook entry. */
        List<PricebookEntry> lstpbe = new List<PricebookEntry>();

        PricebookEntry pbe10 = new PricebookEntry();
        pbe10.Pricebook2Id = pbId;
        pbe10.Product2Id   = p.id;
        pbe10.IsActive     = true;
        pbe10.UnitPrice    = 1;
        pbe10.CurrencyIsoCode = 'USD';
        lstpbe.add(pbe10);

        PricebookEntry pbe11 = new PricebookEntry();
        pbe11.Pricebook2Id = pbId;
        pbe11.Product2Id   = p.id;
        pbe11.IsActive     = true;
        pbe11.UnitPrice    = 1;
        pbe11.CurrencyIsoCode = 'INR';
        lstpbe.add(pbe11);

        PricebookEntry pbe12 = new PricebookEntry();
        pbe12.Pricebook2Id = pbId;
        pbe12.Product2Id   = p.id;
        pbe12.IsActive     = true;
        pbe12.UnitPrice    = 1;
        pbe12.CurrencyIsoCode = 'AUD';
        lstpbe.add(pbe12);

        PricebookEntry pbe20 = new PricebookEntry();
        pbe20.Pricebook2Id = pbId;
        pbe20.Product2Id   = p1.id;
        pbe20.IsActive     = true;
        pbe20.UnitPrice    = 1;
        pbe20.CurrencyIsoCode = 'USD';
        lstpbe.add(pbe20);

        PricebookEntry pbe21 = new PricebookEntry();
        pbe21.Pricebook2Id = pbId;
        pbe21.Product2Id   = p1.id;
        pbe21.IsActive     = true;
        pbe21.UnitPrice    = 1;
        pbe21.CurrencyIsoCode = 'AUD';
        lstpbe.add(pbe21);

        PricebookEntry pbe22 = new PricebookEntry();
        pbe22.Pricebook2Id = pbId;
        pbe22.Product2Id   = p1.id;
        pbe22.IsActive     = true;
        pbe22.UnitPrice    = 1;
        pbe22.CurrencyIsoCode = 'INR';
        lstpbe.add(pbe22);

        Database.insert(lstpbe);


		Opportunity oppty = utilTestClass.CreateOpportunity('Test_Opportunity', '1-Create');
		oppty.AccountId	  = account.Id;
        oppty.type='Renewal';
		oppty.CurrencyIsoCode = 'INR'; 
		oppty.CloseDate   = System.today(); 
		insert oppty;

		//Create Renewal Opptys
		List<Opportunity> renewalOpptyList = new List<Opportunity>();
		for(Integer i=1;i<9;i++)
		{
			Opportunity opptyRec = utilTestClass.CreateOpportunity('Test_Oppty'+i, '1-Create');
			opptyRec.AccountId	  = account.Id;
			opptyRec.CurrencyIsoCode = 'INR'; 
			opptyRec.CloseDate   = System.today(); 
			renewalOpptyList.add(opptyRec);
		}
		
		insert renewalOpptyList;

		// boilerplate data creation code end...


		// Call your code here...
		List<String> contractIds = new String[]{renewalContract1.Id};
		System.debug('contractIDs=' + contractIds);
		List<String> contractProductIds = new String[]{contractProduct2.Id};
	
		//SF1_CreateNewOpportunityFlowController.createRenewalOpportunityFromContracts(String[] selectedContractIds, String selectedCurrency, Boolean isContractCurrencyMismatch);
		Opportunity oppRenewed = SF1_CreateNewOpportunityFlowController.createRenewalOpportunityFromContracts(contractIds, 'AUD', false,'');

		List<Merge_Contract_Header__c> mchList = SF1_ListContractsController.getActiveContractsWithProductsByAccId(account);
		System.debug('mchList=' + JSON.serialize(mchList));
		//System.assertNotEquals(mchList.size(), 0);

	}
	
	static testmethod void onlyForCodeCoverege() {
        Account acc = utilTestClass.CreateAccount('Test_Account_POC');
		acc.BillingStreet = '#31,9th Cross'; 
		acc.BillingCity	  = 'LA';
		acc.BillingState = 'CA';
		acc.BillingPostalCode = '98729';
		acc.BillingCountry = 'USA';
        acc.Type='Lead';
		insert acc; 

		Merge_Contract_Header__c contractHeader = CreateContractHeader('C-YPQEX12', acc.Id, 'USD');
        insert contractHeader;
        
        Test.startTest();
        SF1_CreateNewOpportunityFlowController.AmgWrapper obj = new SF1_CreateNewOpportunityFlowController.AmgWrapper();
        SF1_CreateNewOpportunityFlowController.skipIntermediatePageForOpptyCreation();
        SF1_CreateNewOpportunityFlowController.getOpptyTypesBasedOnContractBaseline();
        SF1_CreateNewOpportunityFlowController.createPaperPOC(contractHeader.Id,acc.Id);
        Test.stopTest();
    }


	static testmethod void newOpportunityFromRenewalContractProductsTest() {  


		// boilerplate data creation code start...

		Account account = utilTestClass.CreateAccount('Test_Account');
        account.Name ='Test_Account';
		account.BillingStreet = '#39,7th Cross'; 
		account.BillingCity	  = 'LA';
		account.BillingState = 'CA';
		account.BillingPostalCode = '98789';
		account.BillingCountry = 'USA';
        account.Type='Lead';
		insert account; 

		Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C-YJSEX11', account.Id+'','USD'  );
		renewalContract1.Account_Name__c = account.Id;
        insert renewalContract1;

        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;
        contractProduct1.Forecast_Product_Id__c = 'Prod-13';
        contractProduct1.Effective_Start_Date__c = System.today()+ 10;
        contractProduct1.Effective_End_Date__c = System.today()+ 100;

		insert contractProduct1;

		Merge_Contract_Header__c renewalContract2 = CreateContractHeader('C-YJSEX10', account.Id ,'SGD' );
		renewalContract2.Account_Name__c = account.Id;
        insert renewalContract2;

		Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract2.Original_Contract_Id__c ,'PROD-124','AKAM-124');
		contractProduct2.Average_Renewal_Commit_MRR__c = 400;
        contractProduct2.Average_Renewal_Usage_MRR__c = 400;
        contractProduct2.UnitPrice__c = 1;
        contractProduct2.Original_Contract_id__c = renewalContract2.Id;
        contractProduct2.Forecast_Product_Id__c = 'Prod-22';
		contractProduct2.Effective_Start_Date__c = System.today()+ 10;
        contractProduct2.Effective_End_Date__c = System.today()+ 100;
		insert contractProduct2;

        /*
        Pricebook2 pb = new Pricebook2();
        pb.name = 'Standard Price Book 2009';
        pb.Description = 'Price Book 2009 Products';
        pb.isactive = true;
        insert pb;*/

        Id pbId = Test.getStandardPricebookId();
        
        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;
        p.IsActive =true;
        Database.insert(p);


        Product2 p1 = new Product2();
        p1.Name     = 'TEST2';
        p1.Akam_Product_Id__c = contractProduct2.Forecast_Product_Id__c;
        p1.IsActive =true;
        Database.insert(p1);


        /* Create a pricebook entry. */
        List<PricebookEntry> lstpbe = new List<PricebookEntry>();


        PricebookEntry pbe10 = new PricebookEntry();
        pbe10.Pricebook2Id = pbId;
        pbe10.Product2Id   = p.id;
        pbe10.IsActive     = true;
        pbe10.UnitPrice    = 1;
        pbe10.CurrencyIsoCode = 'USD';
        lstpbe.add(pbe10);

        PricebookEntry pbe11 = new PricebookEntry();
        pbe11.Pricebook2Id = pbId;
        pbe11.Product2Id   = p.id;
        pbe11.IsActive     = true;
        pbe11.UnitPrice    = 1;
        pbe11.CurrencyIsoCode = 'INR';
        lstpbe.add(pbe11);


        PricebookEntry pbe12 = new PricebookEntry();
        pbe12.Pricebook2Id = pbId;
        pbe12.Product2Id   = p.id;
        pbe12.IsActive     = true;
        pbe12.UnitPrice    = 1;
        pbe12.CurrencyIsoCode = 'AUD';
        lstpbe.add(pbe12);


        PricebookEntry pbe20 = new PricebookEntry();
        pbe20.Pricebook2Id = pbId;
        pbe20.Product2Id   = p1.id;
        pbe20.IsActive     = true;
        pbe20.UnitPrice    = 1;
        pbe20.CurrencyIsoCode = 'USD';
        lstpbe.add(pbe20);

        PricebookEntry pbe21 = new PricebookEntry();
        pbe21.Pricebook2Id = pbId;
        pbe21.Product2Id   = p1.id;
        pbe21.IsActive     = true;
        pbe21.UnitPrice    = 1;
        pbe21.CurrencyIsoCode = 'AUD';
        lstpbe.add(pbe21);

        PricebookEntry pbe22 = new PricebookEntry();
        pbe22.Pricebook2Id = pbId;
        pbe22.Product2Id   = p1.id;
        pbe22.IsActive     = true;
        pbe22.UnitPrice    = 1;
        pbe22.CurrencyIsoCode = 'INR';
        lstpbe.add(pbe22);

        Database.insert(lstpbe);


		List<String> contractProductIds = new String[]{contractProduct2.Id};
		
		Opportunity oppRenewed2 = SF1_CreateNewOpportunityFlowController.createRenewalOpportunityWithProducts(contractProductIds, 'AUD', 'Auto-Renewal');

        Test.startTest();

        Opportunity oppty = SF1_ChangeCurrencyController.fetchOpportunity(oppRenewed2.id);
        system.assert(oppty!= null, 'fetchOpportunity failed');

        oppty.CurrencyISOCode = 'INR';
        String Message = SF1_ChangeCurrencyController.convertCurrency(oppty);
        system.assert(Message== 'success', 'convertCurrency failed');
        Test.stopTest();

	}


	static testmethod void newOpportunityFromRenewalRefeshBaseline() {  


		// boilerplate data creation code start...

		Account account = utilTestClass.CreateAccount('Test_Account');
        account.Name ='Test_Account';
		account.BillingStreet = '#39,7th Cross'; 
		account.BillingCity	  = 'LA';
		account.BillingState = 'CA';
		account.BillingPostalCode = '98789';
		account.BillingCountry = 'USA';
        account.Type='Lead';
		insert account; 

		Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C-YJSEX11', account.Id+'','USD'  );
		renewalContract1.Account_Name__c = account.Id;
        insert renewalContract1;

        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;
        contractProduct1.Forecast_Product_Id__c = 'Prod-13';
        contractProduct1.Effective_Start_Date__c = System.today()+ 10;
        contractProduct1.Effective_End_Date__c = System.today()+ 100;
		insert contractProduct1;


		Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c ,'PROD-124','AKAM-124');
		contractProduct2.Average_Renewal_Commit_MRR__c = 400;
        contractProduct2.Average_Renewal_Usage_MRR__c = 400;
        contractProduct2.UnitPrice__c = 1;
        contractProduct2.Original_Contract_id__c = renewalContract1.Id;
        contractProduct2.Forecast_Product_Id__c = 'Prod-22';
		contractProduct2.Effective_Start_Date__c = System.today()+ 10;
        contractProduct2.Effective_End_Date__c = System.today()+ 100;
		insert contractProduct2;

        /*
        Pricebook2 pb = new Pricebook2();
        pb.name = 'Standard Price Book 2009';
        pb.Description = 'Price Book 2009 Products';
        pb.isactive = true;
        insert pb;*/

        Id pbId = Test.getStandardPricebookId();
        
        Product2 p = new Product2();
        p.Name     = 'TEST';
        p.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;
        p.IsActive =true;
        Database.insert(p);


        Product2 p1 = new Product2();
        p1.Name     = 'TEST2';
        p1.Akam_Product_Id__c = contractProduct2.Forecast_Product_Id__c;
        p1.IsActive =true;
        Database.insert(p1);


        /* Create a pricebook entry. */
        List<PricebookEntry> lstpbe = new List<PricebookEntry>();


        PricebookEntry pbe10 = new PricebookEntry();
        pbe10.Pricebook2Id = pbId;
        pbe10.Product2Id   = p.id;
        pbe10.IsActive     = true;
        pbe10.UnitPrice    = 1;
        pbe10.CurrencyIsoCode = 'USD';
        lstpbe.add(pbe10);

        PricebookEntry pbe20 = new PricebookEntry();
        pbe20.Pricebook2Id = pbId;
        pbe20.Product2Id   = p1.id;
        pbe20.IsActive     = true;
        pbe20.UnitPrice    = 1;
        pbe20.CurrencyIsoCode = 'USD';
        lstpbe.add(pbe20);


        Database.insert(lstpbe);

		List<String> contractProductIds = new String[]{contractProduct2.Id};
		
		Opportunity oppRenewed2 = SF1_CreateNewOpportunityFlowController.createRenewalOpportunityWithProducts(contractProductIds, 'USD', 'Auto-Renewal');

        Test.startTest();

        Boolean valid = l2qManageProductController.validateRefreshBaseline(oppRenewed2.id);

        String message = l2qManageProductController.refreshContractBaseline(oppRenewed2.id);

        Boolean warning = l2qManageProductController.checkRefreshBaselineWarning(oppRenewed2.id);

        Opportunity oppty = utilTestClass.CreateOpportunity('Test_Opportunity', '1-Create');
		oppty.AccountId	  = account.Id;
		oppty.CurrencyIsoCode = 'INR'; 
		oppty.CloseDate   = System.today(); 
        oppty.Validation_Override__c = true;
		insert oppty;

        try{
        valid = l2qManageProductController.validateRefreshBaseline(oppty.id);
        }
        catch(AuraHandledException e){
            System.debug('exception handled');
        }


        Opportunity oppty1 = utilTestClass.CreateOpportunity('Test_Opportunity', '1-Create');
		oppty1.AccountId	  = account.Id;
		oppty1.CurrencyIsoCode = 'INR'; 
		oppty1.CloseDate   = System.today(); 
        oppty1.Validation_Override__c = true;
        oppty1.StageName= 'Closed Won';
        insert oppty1;
        try{
            valid = l2qManageProductController.validateRefreshBaseline(oppty1.id);
            }
            catch(AuraHandledException e){
                System.debug('exception handled');
            }
         Test.stopTest();
	}
}