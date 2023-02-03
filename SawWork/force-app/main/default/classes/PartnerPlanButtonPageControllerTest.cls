@isTest(seeAllData=false)
public class PartnerPlanButtonPageControllerTest {
    
	public static testmethod void TestPartnerPlanButtonPageController() {
        Account newAccount = new Account();
        PageReference pageRef;
        newAccount.Name = 'AccountworkFlowCreationPartnerBtn';
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'Delhi';
        newAccount.Default_MDF_Currency__c ='USD';
        newAccount.CurrencyIsoCode ='USD';
        insert newAccount;

        SFDC_Channel_Account_Plan__c pp  = new SFDC_Channel_Account_Plan__c();
    	pp.name = 'TestPlan';
   	    pp.Partner_Account__c = newAccount.Id;
   		insert pp;

    	Test.setCurrentPage(Page.PartnerPlanButtonPage);	
        ApexPages.currentPage().getParameters().put('fromButton','PrintPartnerPlans');
        ApexPages.currentPage().getParameters().put('recordId',pp.Id);
        ApexPages.currentPage().getParameters().put('profileName','Akamai Partner Administrator');
        PartnerPlanButtonPageController p = new PartnerPlanButtonPageController();
        pageRef = p.backToPartnerPlan();
        pageRef = p.init();
    }
}