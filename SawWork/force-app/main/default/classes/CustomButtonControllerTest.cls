@isTest(seeAllData=false)
public class CustomButtonControllerTest
{
	static User dmlUser = new User(id=UserInfo.getUserId());

	static
    {
      utilTestClass.insertCustomSettings();
    }

    public static testmethod void testButtons()
    {
    	System.runAs(dmlUser)
    	{
    		Test.startTest();

	    	Account testAccount = utilTestClass.CreateAccount('Test Account');
	    	insert testAccount;

	    	Merge_Contract_Header__c testMCH = utilTestClass.CreateContractHeader('1-3F23H',testAccount.Id);
	    	testMCH.Currency__c = 'USD';
	    	insert testMCH;

	    	Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
	    	testOppty.AccountId = testAccount.Id;
			testOppty.CloseDate = Date.today();
			testOppty.CurrencyISOCode = 'USD';
			testOppty.Renew_Contract_Id_Text__c = '1-3F23H';
			insert testOppty;

	    	Renewal_Contract_Object__c renewalContract    = new Renewal_Contract_Object__c();
	        renewalContract.Name              = testMCH.Original_Contract_Id__c;
	        renewalContract.Contract__c           = testMCH.Id;
	        renewalContract.Opportunity__c                = testOppty.Id;
	        renewalContract.Contract_Id_Text__c       = testMCH.Original_Contract_Id__c;
	        insert renewalContract;

	    	Test.setCurrentPage(Page.OpportunityRefreshBaseLine);
			ApexPages.currentPage().getParameters().put('returnUrl',testOppty.Id);
			ApexPages.currentPage().getParameters().put('processName','refreshBaseLine');
			ApexPages.currentPage().getParameters().put('contractID',testOppty.Renew_Contract_Id_Text__c);
			ApexPages.currentPage().getParameters().put('opportunityID',testOppty.Id);
			ApexPages.currentPage().getParameters().put('opptyCurrency',testOppty.CurrencyISOCode);
			ApexPages.currentPage().getParameters().put('opptyCloseDate',testOppty.CloseDate.format());

			CustomButtonController cbc = new CustomButtonController();
			cbc.execute();

			PageReference pageRef = cbc.executeBackToOpportunity();

			cbc.executeRefreshBaseline();

			Test.stopTest();
		}
    }
}