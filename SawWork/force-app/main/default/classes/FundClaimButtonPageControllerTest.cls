@isTest(seeAllData=false)
public class FundClaimButtonPageControllerTest {

	//public static User dmlUser = utilTestClass.getTestRunUser();
	static User partner;
    static User dmlUser = new User(id=UserInfo.getUserId());

	public static testmethod void TestFundClaimButtonPageController() {

		System.runAs(dmlUser) {


			ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            //Add the User to the chanell mapping table

           

            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 
            insert fb;
            SFDC_MDF__c fundRequest = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fundRequest.Account__c = acc.Id;
            fundRequest.Status__c = 'Draft';
            insert fundRequest;

	        /*SFDC_MDF__c fundRequest=new SFDC_MDF__c();
            fundRequest.Name=' FR 1';
            fundRequest.Amount__c=1000;
            fundRequest.Status__c='Draft';
            fundRequest.Account__c = acc.Id;
            fundRequest.SOE_or_PubSec_Event__c = 'Yes';
            fundRequest.Program_End_Date__c = Date.today().addDays(1);
            insert fundRequest;*/

            Profile businessOperations = [Select Id From Profile Where Name = 'Business Operations' LIMIT 1]; // SDFC 7223

	        Test.setCurrentPage(Page.FundClaimButtonPage);
	        ApexPages.currentPage().getParameters().put('fromButton','Pay');
	        ApexPages.currentPage().getParameters().put('recordId',fundRequest.Id);
	        ApexPages.currentPage().getParameters().put('status',fundRequest.Status__c);
	        ApexPages.currentPage().getParameters().put('userProfileId',UserInfo.getProfileId());
	        FundClaimButtonPageController fcPage = new FundClaimButtonPageController();
	        fcPage.init();
	        ApexPages.currentPage().getParameters().put('fromButton','AddPrivateNote');
	        fcPage.init();
	        ApexPages.currentPage().getParameters().put('fromButton','SubmitForApproval');
	        fcPage.init();
	        fcPage.backToFundClaim();
            ApexPages.currentPage().getParameters().put('status','Paid');
            ApexPages.currentPage().getParameters().put('fromButton','Pay');
            fcPage.init();
            //ApexPages.currentPage().getParameters().put('userProfileId','00eA0000000QpRD');
            ApexPages.currentPage().getParameters().put('userProfileId',businessOperations.id); //SDFC 7223
            ApexPages.currentPage().getParameters().put('fromButton','AddPrivateNote');
            fcPage.init();
            fcPage.submitForApproval();
    	}

	}

}