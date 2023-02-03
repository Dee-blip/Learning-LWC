public with sharing class ViewContractProductPageController {

	public Id contractId {get;set;}
	public List<ContractProductWrapper> contractProductList {get;set;}
	public Boolean show {get;set;}
	public String contractName {get;set;}
	
	public ViewContractProductPageController() {

		contractId = ApexPages.currentPage().getParameters().get('contractId');
		contractName = ApexPages.currentPage().getParameters().get('contractName');
		if(contractId!=null)
			getProducts();
	}

	public class ContractProductWrapper {

		public String forecastProductName {get;set;}
		public Decimal averageRenewalCommit{get;set;}
		public Decimal averageRenewalUsage{get;set;}
		public String currencyCode{get;set;}
	}

	public void getProducts(){

  	    	show = true;
  	    	Map<Id,String> mapOfContractProductIdToForecastProductId = new Map<Id,String>();
			Map<Id,ContractProductWrapper> mapOfContractProductIdToContractProductWrapper = new Map<Id,ContractProductWrapper>();
			Map<String,String> mapOfForecastProductIdToForecastProductName = new Map<String,String>();

			for(Contract_Product__c contractProduct : [Select Id,CurrencyIsoCode,Average_Renewal_Commit_MRR__c,Average_Renewal_Usage_MRR__c,Forecast_Product_Id__c from Contract_Product__c where Original_Contract_Id__c =:contractId and Deleted_From_Source__c = false])
			{
				ContractProductWrapper contractWrapper = new ContractProductWrapper();
				contractWrapper.averageRenewalCommit = contractProduct.Average_Renewal_Commit_MRR__c;
				contractWrapper.averageRenewalUsage = contractProduct.Average_Renewal_Usage_MRR__c;
				contractWrapper.currencyCode = contractProduct.CurrencyIsoCode;
				mapOfContractProductIdToContractProductWrapper.put(contractProduct.Id,contractWrapper);
				mapOfContractProductIdToForecastProductId.put(contractProduct.Id,contractProduct.Forecast_Product_Id__c);
			}

			for(PricebookEntry pbe : [Select Name,product2.Akam_Product_Id__c from PricebookEntry where product2.Akam_Product_Id__c IN : mapOfContractProductIdToForecastProductId.values()])
			{
				mapOfForecastProductIdToForecastProductName.put(pbe.product2.Akam_Product_Id__c, pbe.Name);
			}

			for(Id contractProductId : mapOfContractProductIdToContractProductWrapper.keySet())
			{
				mapOfContractProductIdToContractProductWrapper.get(contractProductId).forecastProductName = 	mapOfForecastProductIdToForecastProductName.get(mapOfContractProductIdToForecastProductId.get(contractProductId));
			}
			if(mapOfContractProductIdToContractProductWrapper.size()>0)
			{
				contractProductList = new List<ContractProductWrapper>();
				contractProductList.addAll(mapOfContractProductIdToContractProductWrapper.values());

			}

			System.debug('contractProductList' + contractProductList);

	}

	

}