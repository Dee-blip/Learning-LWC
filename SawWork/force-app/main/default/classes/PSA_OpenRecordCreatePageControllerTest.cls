@isTest(SeeAllData=false)
private class PSA_OpenRecordCreatePageControllerTest
{
    static{
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
        createTestData();
   
    } 	
        Public static PSA_TestUtility testUtil;
        Public static pse__Region__c reg;
        Public static Account acct;
        Public static Contact resource;
        Public static Contact resource1;
        Public static pse__Project_Methodology__c  product1;
        Public static pse__Proj__c proj1;
        Public static pse__Practice__c pract;
        Public static Id practId;
        Public static pse__Milestone__c milestone;
        Public static pse__Assignment__c assign;
        Public static User usr;
        Public static User usr2;
    //The function which creates the test data: called from the static block
    Public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(false);
        acct.Name = 'PSA_OpenRecordCreatePageControllerTestAccount';
        insert acct;
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        insert usr;
        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        update resource;


        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        milestone = testUtil.newMilestone(false,proj1.Id,100,date.newInstance(2015, 08, 21));            
        milestone.Billable__c = true;
        insert milestone;
        
        Environment_Setup__c esSetting = new Environment_Setup__c();
        //esSetting.SetupOwnerId = '';
        esSetting.Active_Org__c = true;
        esSetting.Connection_Name__c = 'DR';
        esSetting.ConnectionId__c = '04PG0000000PDf9MAG';
        esSetting.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
        esSetting.Akam_Id_Start_String__c = 'F-';
        esSetting.Environment_Type__c = 'Primary';
        insert esSetting;

        GSM_Custom_Settings__c gsmSetting = new GSM_Custom_Settings__c();
        gsmSetting.Name = 'CastIronClass#AlertHourSetting';
        gsmSetting.Value__c = '1';
        insert gsmSetting;
        GSM_Custom_Settings__c gsmSetting1 = new GSM_Custom_Settings__c();
        gsmSetting1.Name = 'CastIronClass#AlertToAddress';
        gsmSetting1.Value__c = 'vparimi-gmail@noemail-akamai.com';
        insert gsmSetting1;
        GSM_Custom_Settings__c gsmSetting2 = new GSM_Custom_Settings__c();
        gsmSetting2.Name = 'CastIronClass#EmailTemplateName';
        gsmSetting2.Value__c = 'Castiron_Polling_Email_Template';
        insert gsmSetting2;
        GSM_Custom_Settings__c gsmSetting3 = new GSM_Custom_Settings__c();
        gsmSetting3.Name = 'CastIronClass#OrgWideAddressId';
        gsmSetting3.Value__c = '0D2G00000004D7S';
        insert gsmSetting3;
        GSM_Custom_Settings__c gsmSetting4 = new GSM_Custom_Settings__c();
        gsmSetting4.Name = 'CastIronClass#ReplyToAddress';
        gsmSetting4.Value__c = 'eaeblrops-gmail@noemail-akamai.com';
        insert gsmSetting4;



    }

	@isTest
	static void testMethod1()
	{
		test.startTest();
			PSA_OpenRecordCreatePageController.prepareDefaultJsonString(proj1.id,'Test__c');
			PSA_OpenRecordCreatePageController.prepareDefaultJsonString(proj1.id,'pse__Milestone__c');
			PSA_OpenRecordCreatePageController.prepareDefaultJsonString(proj1.id,'pse__Resource_Request__c');
		test.stopTest();	
	}

	@isTest
	static void checkTestClassTestMethod()
	{
		test.startTest();
			PSA_checkTestClass.checkValidity(proj1.Id);
			PSA_checkTestClass.checkValidity(milestone.Id);

			product1 = testUtil.newProjectProduct(false,proj1.Id,'CloudTest on Demand');
			product1.Product__c = 'CloudTest on Demand';
			insert product1;

			PSA_checkTestClass.checkValidity(proj1.Id);
			PSA_checkTestClass.checkValidity(milestone.Id);

		test.stopTest();	
	}

}