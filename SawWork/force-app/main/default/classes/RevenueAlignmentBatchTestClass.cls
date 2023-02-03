@isTest
private class RevenueAlignmentBatchTestClass {
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
		Account acc = utilTestClass.CreateAccount('Energy inactive account');
		acc.Type = 'Direct Customer - Inactive';
		acc.Revenue_Alignment_Status__c = 'Waived';
		accList.add(acc);
		
		Account accActive = utilTestClass.CreateAccount('Energy Active account');
		accActive.Type = 'Lead';
		accActive.Revenue_Alignment_Status__c = 'Waived';
		accList.add(accActive);
		
		Account accinActive = utilTestClass.CreateAccount('Energy recently inActive account');
		accinActive.Type = 'Direct Customer - Inactive';
		accinActive.Revenue_Alignment_Status__c = 'Waived';
		accList.add(accinActive);
		
		insert accList;
		accMap.put('inActive',acc.id);
		accMap.put('Active',accActive.id);
		accMap.put('inActiveNtbp',accinActive.id);
		System.debug(LoggingLevel.ERROR,'accMap in test setup: '+accMap);
		Merge_Contract_Header__c mch = utilTestClass.CreateContractHeader('C-YJSEX7',acc.id);
		mch.Effective_End_Date__c = Date.today().addMonths(-13);
		mchList.add(mch);
		Merge_Contract_Header__c mch1 = utilTestClass.CreateContractHeader('C-YJSEX0',accinActive.id);
		mch1.Effective_End_Date__c = Date.today().addMonths(-13);
		mchList.add(mch1);
		Merge_Contract_Header__c mch2 = utilTestClass.CreateContractHeader('C-YJSEX1',accinActive.id);
		mch2.Effective_End_Date__c = Date.today().addMonths(-12);
		mchList.add(mch2);
		Merge_Contract_Header__c mch3 = utilTestClass.CreateContractHeader('C-YJSEX2',accActive.id);
		mch3.Effective_End_Date__c = Date.today().addMonths(2);
		mchList.add(mch3);
		insert mchList;
		System.debug(LoggingLevel.ERROR,'accMap in test setup after contract: '+accMap);
	}
	static testMethod void test_method() {
		// Implement test code
		createData();
		String RevenueAlignmentWaiverUnsetValue = GsmUtilClass.getGSMSettingValue('RevenueAlignmentWaiverUnsetValue');
		Test.startTest();
        RevenueAlignmentBatchClass bClass = new RevenueAlignmentBatchClass();
        Database.executeBatch(bClass);

        Test.stopTest();
        Map<Id,Account> revenueAlignmentAccounts = new Map<Id,Account>([select id,name, Revenue_Alignment_Status__c from account where id in :accList]);
        System.assertEquals(revenueAlignmentAccounts.get(accMap.get('inActive')).Revenue_Alignment_Status__c, RevenueAlignmentWaiverUnsetValue);
        System.assertNotEquals(revenueAlignmentAccounts.get(accMap.get('Active')).Revenue_Alignment_Status__c, RevenueAlignmentWaiverUnsetValue);
        System.assertNotEquals(revenueAlignmentAccounts.get(accMap.get('inActiveNtbp')).Revenue_Alignment_Status__c, RevenueAlignmentWaiverUnsetValue);

	}

	
}