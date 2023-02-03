@isTest
private class ContractProductTriggerHandlerTestClass {

	static
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        utilTestClass.insertCustomSettings();
      }
    }
	
	@isTest static void testResolve_ContractProduct_ContractHeaderForeignKeys() {


		Account account = utilTestClass.CreateAccount('Test_Account');
		insert account;
		Merge_Contract_Header__c contract = utilTestClass.CreateContractHeader('CONTRACT-ID-123',account.Id);
		insert contract;
		Contract_Product__c contractProduct = utilTestClass.CreateContractProduct('CONTRACT-ID-123','PROD-123','AKAM-123');
		insert contractProduct;

		contractProduct = [Select Original_Contract_Id__c from Contract_Product__c where Id =: contractProduct.Id];

		System.assertEquals(contractProduct.Original_Contract_Id__c,contract.Id);

	}
	

	
}