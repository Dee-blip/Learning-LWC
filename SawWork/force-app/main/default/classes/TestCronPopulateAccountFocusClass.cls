/** Sonali Tandon - 12/02/2016 
Test class for CronPopulateAccountFocusAttributeClass
**/


@isTest(seeAllData = false)
public class TestCronPopulateAccountFocusClass {


	static
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
      	utilTestClass.insertCustomSettings();
      }
		
	}

	static List<Account> createData()
	{
		List<String> listOfWebsites = new List<String>{'www.cjpowercast.co.kr', 'http://www.hitachi-hitec.com', 'http://www.dwamedia.com', 'www.mobage.com', 'www.nowebsite.com' };
		List<String> listOfCountries = new List<String>{'South Korea', 'Japan','USA', 'USA', 'India'};
		List<Account> listOfAccounts = new List<Account>();

		for(Integer i=0;i<4;i++)
		{
			 Account newAccount2 = new Account();
        	newAccount2.Name = 'Test'+i;
        	newAccount2.Website = listOfWebsites[i];
        	newAccount2.BillingCountry = listOfCountries[i];
            newAccount2.BillingPostalCode ='90876';
            if(listOfCountries[i] == 'India'){
            	newAccount2.BillingState = 'Delhi';
            }
        	newAccount2.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
            //newAccount2.Website = 'a@xyz.com';
        	listOfAccounts.add(newAccount2);
		}
         Account newAccount2 = new Account();
        newAccount2.Name = 'Test'+4;
        newAccount2.Website = 'www.nowebsite.com';
        newAccount2.BillingCountry ='India';
        newAccount2.BillingPostalCode ='90876';
        if(newAccount2.BillingCountry == 'India'){
            newAccount2.BillingState = 'Delhi';
        }
        newAccount2.Target_Category__c = GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic');
        newAccount2.domain__c = 'xyz';
        listOfAccounts.add(newAccount2);
         
		return listOfAccounts;
	}


	static testmethod void testBatchMethod()
	{
		List<Account> listOfAccounts = TestCronPopulateAccountFocusClass.createData();
		Integer  batchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Alexa_CronBatchSize')); //SFDC-2391

		Test.startTest();
		SYstem.debug('TestCronPopulateAccountFocusClass:: testPositiveMethod ::listOfAccounts' + listOfAccounts);
		insert listOfAccounts;
		CronPopulateAccountFocusAttributeClass tempBatchClass= new CronPopulateAccountFocusAttributeClass();
        Database.executeBatch(tempBatchClass,batchSize);
        Test.stopTest();

        // refresh accounts 
        listOfAccounts = [Select Id, Focus__c from Account where Id IN : listOfAccounts];

       	System.debug('TestCronPopulateAccountFocusClass:: testPositiveMethod :: after refresh'+ listOfAccounts);

        System.assertEquals(listOfAccounts[0].Focus__c, 'Not Available');
        System.assertEquals(listOfAccounts[1].Focus__c, 'Regional');
        System.assertEquals(listOfAccounts[2].Focus__c, 'Country');
        System.assertEquals(listOfAccounts[3].Focus__c, 'Global');
       // System.assertEquals(listOfAccounts[4].Focus__c, null);
        /*

        Error_log__c errorLog = [Select RecordId__c from Error_log__c where Class__c = 'CronPopulateAccountFocusAttributeClass'][0];

        System.assertEquals(listOfAccounts[4].Id, errorLog.RecordId__c);
        */
		       
	}
    
    static testmethod void testBatchMethod_ForCoverege(){
        List<Account> listOfAccounts = TestCronPopulateAccountFocusClass.createData();
		Integer  batchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Alexa_CronBatchSize')); //SFDC-2391

		Test.startTest();
		insert listOfAccounts;
		CronPopulateAccountFocusAttributeClass tempBatchClass= new CronPopulateAccountFocusAttributeClass();
        tempBatchClass.failedUpdates = 0;
        tempBatchClass.errorString = new List<String>();
        tempBatchClass.errorFlag = true;
        tempBatchClass.successFullCallOuts = 0;
        tempBatchClass.price = 0;
        tempBatchClass.alexaBatchSize = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Alexa_CronBatchSize'));
        tempBatchClass.sizeOfErrorLogRecords = 0;
        CronPopulateAccountFocusAttributeClass.DataWrapper wrap = new CronPopulateAccountFocusAttributeClass.DataWrapper();
        wrap.accountId = null;
        wrap.website = 'www.google.com';
        wrap.primaryCountry = 'India';
        wrap.focus = '';
        Database.executeBatch(tempBatchClass,batchSize);
        Test.stopTest();
    }

}