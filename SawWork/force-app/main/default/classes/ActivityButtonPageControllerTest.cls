@isTest(seeAllData=false)
public class ActivityButtonPageControllerTest
{
	static User dmlUser = new User(id=UserInfo.getUserId());

	// Setup method to create test data.
    @testSetup
    static void setupMethod()
    {
        System.runAs(dmlUser) {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
        }
    }

    public static testmethod void createOATask()
    {
    	System.runAs(dmlUser)
        {
			Test.startTest();

			Account testAccount = utilTestClass.CreateAccount('Test Account');
			testAccount.website='www.abpcon.com';
			insert testAccount;

			Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
			testOppty.AccountId = testAccount.Id;
			testOppty.CloseDate = Date.today();
			insert testOppty;

			Profile pr = [select id from profile where name like '%SA - Analyst%'][0];
			User ccgOwner1 = new User(alias = '__CCG1', email='ccg1@akamai.com',emailencodingkey='UTF-8', lastname='ccg1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__ccg1@akamai.com',profileid = pr.Id);
	        User ccgOwner2 = new User(alias = '__CCG2', email='ccg2@akamai.com',emailencodingkey='UTF-8', lastname='ccg2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__ccg2@akamai.com',profileid = pr.Id);
	        insert (new User[] {ccgOwner1, ccgOwner2});

		    Order_Approval__c newOA = new Order_Approval__c();
            newOA.Associated_Opportunity__c = testOppty.Id;
            newOA.Approvals_Required__c = 'Deal Desk; Legal';
            newOA.Type__c = 'CDN';
            insert newOA;

			Test.setCurrentPage(Page.ActivityButtonPage);
			ApexPages.currentPage().getParameters().put('fromButton','CreateOATask');
			ApexPages.currentPage().getParameters().put('recordId',newOA.Id);
			ApexPages.currentPage().getParameters().put('TaskType','OA');

			ActivityButtonPageController abpc = new ActivityButtonPageController();

			PageReference pageRef = abpc.init();
			abpc.backToAccountPage();
			abpc.backToOrderApprovalPage();
			Test.stopTest();
		}
    }
}