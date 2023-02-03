/* Author : rsharma
Created test class as part of 1481*/
@isTest
private class CurrentSalesChannelBatchTestClass {
	static List<Merge_Contract_Header__c> mchList;
	static List<Account> accList;
	static Map<String,String> accMap= new Map<String,String>();
	 static void createData(){
		System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
        }
		mchList = new List<Merge_Contract_Header__c>();
		accList = new List<Account>();
		Account acc = utilTestClass.CreateAccount('Energy Active account');
		acc.Type = 'Indirect Customer - Active';
		acc.Indirect_customer__c = true;
		accList.add(acc);
		
		Account accActive = utilTestClass.CreateAccount('Energy future Active account');
		accActive.Type = 'Indirect Customer - Active';
		accActive.Active_NAP_Master_Contract__c = true;
		accList.add(accActive);
		
		Account partnerAcc = utilTestClass.CreateAccount('Energy partner account');
		partnerAcc.Type = 'Partner - Active';
		partnerAcc.ispartnercustom__c = true;
		accList.add(partnerAcc);

		Account accTest = utilTestClass.CreateAccount('Dummy Account');
        accTest.Type = 'Partner - Active';
        accTest.Active_NAP_Master_Contract__c = true;
        accList.add(accTest);
		
		insert accList;
		Merge_Contract_Header__c mch1 = utilTestClass.CreateContractHeader('C-YJSEX0',partnerAcc.id);
		mch1.Effective_End_Date__c = Date.today().addMonths(13);
		mch1.Contract_Type__c='Reseller Tier1';
		mchList.add(mch1);
		Merge_Contract_Header__c mch = utilTestClass.CreateContractHeader('C-YJSEX7',acc.id);
		mch.Effective_End_Date__c = Date.today().addMonths(13);
		mch.Contract_Type__c='Indirect Customer';
		mch.Parent_Contract__c = mch1.id;
		mchList.add(mch);
		
		Merge_Contract_Header__c mch2 = utilTestClass.CreateContractHeader('C-YJSEX1',acc.id);
		mch2.Effective_End_Date__c = Date.today().addMonths(12);
		mch2.Contract_Type__c='Direct Customer';
		mchList.add(mch2);
		Merge_Contract_Header__c mch3 = utilTestClass.CreateContractHeader('C-YJSEX2',accActive.id);
		mch3.Effective_End_Date__c = Date.today().addMonths(2);
		mch3.Contract_Type__c='Indirect Customer';
		mch3.Parent_Contract__c = mch1.id;
		mchList.add(mch3);
		insert mchList;

		Profile pr = [select id from profile where name='Sales - Rep'][0];
        UserRole role = [select Id, name from UserRole where name='Worldwide'][0];
            
        User tmUser = new User(alias = utilTestClass.getRandomString(8), email=utilTestClass.getRandomString(8)+'@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=utilTestClass.getRandomString(8)+'@akamai.com',profileid = pr.Id, UserRoleId=role.Id);

            System.runAs(utilTestClass.getTestRunUser())
        {
            insert tmUser;
        }
		Partner_Client_Manager__c pcm1 = new Partner_Client_Manager__c(Partner_Account__c=partnerAcc.id,Indirect_Account__c=acc.id,Akamai_User__c=tmUser.id,Manager_Type__c='Akamai PAE');
		Partner_Client_Manager__c pcm2 = new Partner_Client_Manager__c(Partner_Account__c=partnerAcc.id,Indirect_Account__c=accActive.id,Manager_Type__c='Partner Led');

		List<Partner_Client_Manager__c> pcmList = new List<Partner_Client_Manager__c>();
		pcmList.add(pcm1);
		pcmList.add(pcm2);
		insert pcmList;
		
	}
	@isTest static void test_method_one() {
		// Implement test code
		createData();
		Test.startTest();
        CurrentSalesChannelBatchClass bClass = new CurrentSalesChannelBatchClass();
        Database.executeBatch(bClass);

        Test.stopTest();
	}
	
	@isTest static void test_method_two() {
		// Implement test code

	}
	
}