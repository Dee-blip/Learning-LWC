@isTest(seeAllData=false)
private class RebatePayoutButtonPageControllerTest 
{
	static User dmlUser = new User(id=UserInfo.getUserId());
    @testSetup
    static void createTestData()
    {
        System.runAs(dmlUser)
        {
            utilTestClass.insertCustomSettings(new List<String>{'GSM_Custom_Settings'});
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.Vertical__c = 'Gaming';
            acc.Sub_Vertical__c = 'Console Mfs';
            acc.Type='Indirect Customer - Active';
            acc.Invoice_Currency__c = 'USD';
            insert acc;

            string retmsg=PRM_opportunity.makePartnerAccount(acc.id);

            Rebate_Payout__c rp=new Rebate_Payout__c();
            rp.Name='Test Rebate Payout';
            rp.Associated_Partner__c=acc.Id;
            rp.Description__c='Test rebate for partners';
            rp.Start_Date__c=Date.today();
            rp.End_Date__C=Date.today().addDays(4);
            rp.CurrencyIsoCode = acc.Invoice_Currency__c;
            rp.Rebate_Payout_Amount__c=125.00;

            User psUser=utilTestClass.CreateUser('Test_PS','Worldwide','Partner Support');
            insert psUser;

            System.runAs(psUser)
            {
            	insert rp;
            }
        }
    }
	
	@isTest static void testSendToCMG()
	{
		Test.startTest();

		Rebate_Payout__c testRB = [Select Id from Rebate_Payout__c where Name = 'Test Rebate Payout'];
		Account testAcc = [Select Id from Account where Name = '__Test Account'];

		Test.setCurrentPage(Page.RebatePayoutButtonPage);
		ApexPages.currentPage().getParameters().put('fromButton','SendToCMG');
        ApexPages.currentPage().getParameters().put('recordId',testRB.Id);
        ApexPages.currentPage().getParameters().put('associatedPartner',testAcc.Id);

        RebatePayoutButtonPageController rpbpc = new RebatePayoutButtonPageController();
        PageReference pr = rpbpc.init();

        pr = rpbpc.backToRebatePayout();
	}	
}