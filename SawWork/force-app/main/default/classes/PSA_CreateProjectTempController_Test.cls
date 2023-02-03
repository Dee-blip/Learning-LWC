/***
    PSA_CreateProjectTempController_Test
    @Description : This Class tests the PSA_CreateProjectTempController. This is the controller to the 
    VF page that navigates to the project create page from the New button.
    @History
    --Developer           --Date            --Change
    Sharath               25 Sep 2018    Created the class
*/

@isTest(SeeAllData=false)
public class PSA_CreateProjectTempController_Test 
{
    Public static Account acct;
	Public static Opportunity opp;
	public static PSA_TestUtility testUtil; 
	public static User usr; 
	static
	{
		testUtil = new PSA_TestUtility();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
        //Map<String, Schema.SObjectType> globalDescribe1 = Schema.getGlobalDescribe();
        //Test.loadData(globalDescribe1.get('Email_to_Case__c'), 'Email_to_Case');        
        Environment_Setup__c esSetting = new Environment_Setup__c();
        //esSetting.SetupOwnerId = '';
        esSetting.Active_Org__c = true;
        esSetting.Connection_Name__c = 'DR';
        esSetting.ConnectionId__c = '04PG0000000PDf9MAG';
        esSetting.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
        esSetting.Akam_Id_Start_String__c = 'F-';
        esSetting.Environment_Type__c = 'Primary';
        insert esSetting;
        
        acct = testUtil.newAccount(true);
        opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());


	}
	public PSA_CreateProjectTempController_Test() 
	{

		
	}

    public static testMethod void test_method_One()
    {
        test.startTest();
        		ApexPages.StandardController sc = new ApexPages.StandardController(new pse__Proj__c());
				PSA_CreateProjectTempController tempController;
				tempController = new PSA_CreateProjectTempController(sc);        		                               
	            tempController = new PSA_CreateProjectTempController();
	            ApexPages.currentPage().getParameters().put('retURL','/'+acct.Id);
	            tempController.navigateToCreatePage();
	            ApexPages.currentPage().getParameters().put('retURL','/'+opp.Id);
	            tempController.navigateToCreatePage();
	            ApexPages.currentPage().getParameters().remove('retURL');
	            tempController.navigateToCreatePage();
	            ApexPages.currentPage().getParameters().put('CF00NG0000009zdnl_lkid',acct.Id);
	            tempController.navigateToCreatePage();
	            ApexPages.currentPage().getParameters().put('CF00NG0000009zdoi_lkid',opp.Id);
	            tempController.navigateToCreatePage();
    	    	PSA_CreateProjectTempController.getAccount(opp.Id);
        test.stopTest();
    }

}