/**Ruchika Sharma  20/11/17       Updated class to accomodate new logic.
                    SFDC-2130 : PSOR -- Refresh Job that links Contract to Account Header.
**/
@isTest(seeAllData = false)

private class NAPContractPSORBatchTestClass
{	
 	static
    {
        utilTestClass.insertCustomSettings();
    }
	static testmethod void testNAPContractPSORMethod()
	{
		ManagedPkgErrorClass.isFromManagedPackage		= false;
		Integer count;
		Integer i;
		List<Account> listOfAccounts					= new List<Account>();
		List<Merge_Contract_Header__c> listOfResellers	= new List<Merge_Contract_Header__c>();
		List<Merge_Contract_Header__c> listOfNAPMAsters	= new List<Merge_Contract_Header__c>();
		
		for(i=0;i<50;i++)
		{
			Account accountObj = utilTestClass.CreateAccount('Test_AccountName'+i);
			accountObj.website = 'www.test'+i +'.com';
			listOfAccounts.add(accountObj);
		}

		

		insert listOfAccounts;
		Test.startTest();
		for(i=0;i<50;i++)
		{
				Merge_Contract_Header__c contractObj = utilTestClass.CreateContractHeader('Test_MasterContractId'+i, listOfAccounts[i].Id);
				contractObj.Active__c 					= TRUE;
			    contractObj.Contract_Type__c 			= 'NAP Master Agreement';
			    contractObj.Partner_Tier__c  			= 'Test Tier'+ i;
			    contractObj.Partner_Type__c  			= 'Test Type'+i;
			    contractObj.Partner_Reach__c 			= 'Test Reach'+i;
			  	contractObj.Partner_Custom_Pricing__c 	= TRUE;
				contractObj.Effective_End_Date__c 		= Date.today();
			    contractObj.Effective_Start_Date__c 	= Date.today();
			    ContractObj.Account_Name__c = listOfAccounts.get(i).id;
			    listOfNAPMAsters.add(contractObj);
		}

		insert listOfNAPMAsters;

		for(i=0;i<20;i++)
		{
			
				Merge_Contract_Header__c contractObj = utilTestClass.CreateContractHeader('Test_ResellerContractId'+i, listOfAccounts[i].Id);
				contractObj.Contract_Type__c 			= 'Tier 1 Reseller';
			    contractObj.Active__c 					= TRUE;
			    contractObj.NAP_Master_Contract__c 		= listOfNAPMAsters[i].Id;
			    contractObj.Partner_Tier__c  			= 'Test Tier'+ i;
			    contractObj.Partner_Type__c  			= 'Test Type'+i;
			    contractObj.Partner_Reach__c 			= 'Test Reach'+i;
			  	contractObj.Partner_Custom_Pricing__c 	= TRUE;
				contractObj.Effective_End_Date__c 		= Date.today();
			    contractObj.Effective_Start_Date__c 	= Date.today();
			    ContractObj.Account_Name__c = listOfAccounts.get(i).id;
			    listOfResellers.add(contractObj);
			

		}

		insert listOfResellers;
		CronJobTypes.insertBatchJobAndRun('Update Account With NAP PSOR values from Contract');
		NAPContractPSORBatchClass batchInstance = new NAPContractPSORBatchClass();
		Database.executeBatch(batchInstance,100);

		Test.stopTest();
		String NAPPSORMapping = GSMSettings.getVerbose('NAP_PSOR_Mapping');
		List<PSORMappingClass> psorList = PSORMappingClass.parse(NAPPSORMapping);
		String query = 'Select Id,Contract_Type__c,'+PSORMappingClass.allFieldsToQuery(psorList)+ 'Account_Name__c, Account_Name__r.Name from Merge_Contract_Header__c where Id IN : listOfNAPMAsters';
		List<Merge_Contract_Header__c> listOfContractsRefreshed = Database.query(query);   

		for(Merge_Contract_Header__c contractObj : listOfContractsRefreshed)
		{
			for(PSORMappingClass psor: psorList){
				if(!psor.accField.equalsIgnoreCase('NAP_Master_Contract__c'))
					System.assertEquals(contractObj.get(psor.contractField), contractObj.getSobject('Account_Name__r').get(psor.accField));
			}
		}  


	}
}