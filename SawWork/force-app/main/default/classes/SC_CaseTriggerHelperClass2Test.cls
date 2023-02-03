/*
 * JIRA: ESESP-2467
 * Developer: Sharath Prasanna
 * Enhancement: SC_CaseTriggerHelperClass2Test test class
 * Date: 18th December 2019
 * 
 
*/ 
@isTest(SeeAllData=false)
public class SC_CaseTriggerHelperClass2Test
{
    public static PSA_TestUtility testUtil;
    public static Account acct;
    
    
    public static User usr;
    public static Contact resource;

    static
    {

        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(false);
        acct.Direct_Customer__c = true;
        insert acct;
		
		utilTestClass.createCustomSettings();
        //SC_BOCC_Setup__c scBOCCSetup = new SC_BOCC_Setup__c();
        //scBOCCSetup.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        //scBOCCSetup.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        //scBOCCSetup.Product_Id__c = 'M-LC-160618';
        //scBOCCSetup.Name = 'BOCC';
        //insert scBOCCSetup;

        usr = testUtil.newUserSysAdmin(true); 
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.HasOptedOutOfEmail = false;
        resource.Contact_Type__c = 'Tech Secondary - 24X7;Technical Primary - 24X7';
        insert resource;

    }
	@isTest
	static void subdomainTakeoverToolNotificationTest()
	{
		Case caseRec;

		Test.startTest();

			caseRec =new Case();
			caseRec.subject= 'subject for case';
			caseRec.description= 'Case Description';
			caseRec.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
			caseRec.accountId = acct.Id;
			caseRec.recordTypeId =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical').getRecordTypeId();
			caseRec.origin='Autogen';
			caseRec.Severity__c	= '3';
			caseRec.Work_Type__c = 'Proactive';
			caseRec.Sub_Type__c  = 'Subdomain Takeover';
			caseRec.Case_Assignment_Using_Active_Rules__c = true;
			//caseRec.status = 'Closed';
			//caseRec.Validation_Override__c = true;
			insert caseRec;

			List<Id> caseIds = new List <Id>();
			caseIds.add(caseRec.Id);

			SC_CaseTriggerHelperClass2 helperClass = new SC_CaseTriggerHelperClass2();
			SC_CaseTriggerHelperClass2.sendSubdomainTakeoverToolNotification(caseIds);

		Test.stopTest();
	}
}