@isTest
private class WYWYNActivitiesControllerTestClass
{
    static
    {
        //utilTestClass.insertCustomSettings();
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
            'GSM_Custom_Settings__c'    => 'CS_GSM_Custom_Settings',
            'Features_Toggle__c' => 'CS_Features_Toggle',
            'Account_Reassignment_Settings__c' => 'CS_Account_Reassignment_Settings',
            'Account_Reassignment_Class_Settings__c' => 'CS_Account_Reassignment_Class_Settings',
            'Address_Validation_Class_Settings__c' => 'CS_Address_Validation_Class_Settings',
            'Environment_Setup__c' => 'CS_Environment_Setup',
            'Sync_To_Siebel_Fields_Settings__c' => 'CS_Sync_To_Siebel_Fields_Settings'
            };
        utilTestClass.insertCustomSettings(objectToCustomSettingResource);
        utilTestClass.insertCustomSettings(new List<String>{'WYWYNActivitiesSettings'});
    }
	//private static Map<String, Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();
	private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();

	private static Boolean initFlag = false;	
	private static Account testAccount;
	
	/**
		CreateAccount()
	*/
	/*
	private static Account CreateAccount(String pAccName, Id pOwnerId, String accountStatus)
	{
		Account newAccount = new Account();
		newAccount.Name = pAccName;
		newAccount.OwnerId = pOwnerId;
		newAccount.BillingCountry = 'India';
		newAccount.Type = accountStatus;
		return newAccount;
	}*/
	
	/**
		CreateContact()
	*/
	/*
	private static Contact CreateContact(String FirstName,String LastName)
	{
		Contact con = new Contact();
		con.FirstName = FirstName;
		con.LastName = LastName;
		con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';
        con.Phone = '99999';
        con.Email = 'Testing@Testing.com';
        con.Title = 'Tester';	
        con.MailingCountry = 'India';
        return con;
	}
	*/
	/**
		refreshContact()
	*/
	private static Contact refreshContact(Contact cntct)
	{
		return [SELECT Id, Email, AccountId, Account.Name, Name, Phone, FirstName, LastName  
        	    	FROM Contact WHERE Id = : cntct.Id];
	}
	
	/**
		Init()
		- Intialize the static variables for this Test Class
	*/
    private static void Init()
    {
    	ManagedPkgErrorClass.isFromManagedPackage = false;
    	if(initFlag)
    		return;
    	
    	//testAccount = CreateAccount('_AccReass_TestCase_', testcaseCustomSettings.get('ONA_User_Id').Value__c, 'Lead');
    	testAccount = utilTestClass.CreateAccount('_AccReass_TestCase_');
		testAccount.OwnerId = testcaseCustomSettings.get('ONA_User_Id').Value__c;
		testAccount.Type = 'Lead';
		insert testAccount;	
				
		initFlag = true;
    }
    
    /**
    	WYWYNActivitites_Positive1()
    	- Send Email Test
    */
	static testMethod void WYWYNActivitites_Positive1()
	{
		// Discontinue if feature is not Active.
		//SFDC-2686
		//if(featureToggleCustomSettings.get('WYWYNActivitiesPageToggle').Toggle__c != true)
		if(FeatureToggles.IS_WYWYN_ACTIVITIES_PAGE_TOGGLE != true)
			return;
		
		Init();
		
		// Create Contact
		Contact cntct = utilTestClass.CreateContact('__Test First','__Test Contact');
		cntct.AccountId = testAccount.Id;
		insert cntct;
		
		// refresh Contact
		cntct = refreshContact(cntct);
		
		// test
		PageReference pageRef = Page.WYWYNActivities;
        pageRef.getParameters().put('id', cntct.id);
        Test.setCurrentPageReference(pageRef);
        WYWYNActivitiesController pageController = new WYWYNActivitiesController();
        
        // assertions
        system.assertEquals(pageRef.getParameters().get('id'), String.valueOf(cntct.Id));        
        //system.assert(pageRef.getUrl().contains('/WYWYNActivities?'));
        
        PageReference returnUrl = pageController.sendEmail();
        system.assert(returnUrl.getUrl().contains('/003'));
	}
	
	/**
    	WYWYNActivitites_Positive2()
    	- Cancel Test
    */
	static testMethod void WYWYNActivitites_Positive2()
	{
		// Discontinue if feature is not Active.
		//SFDC-2686
		//if(featureToggleCustomSettings.get('WYWYNActivitiesPageToggle').Toggle__c != true)
		if(FeatureToggles.IS_WYWYN_ACTIVITIES_PAGE_TOGGLE != true)
			return;
		
		Init();
		
		// Create Contact
		Contact cntct = utilTestClass.CreateContact('__Test First','__Test Contact');
		cntct.AccountId = testAccount.Id;
		insert cntct;
		
		// refresh Contact
		cntct = refreshContact(cntct);
		
		// test
		PageReference pageRef = Page.WYWYNActivities;
        pageRef.getParameters().put('id', cntct.id);
        Test.setCurrentPageReference(pageRef);
        WYWYNActivitiesController pageController = new WYWYNActivitiesController();
        
        // assertions
        system.assertEquals(pageRef.getParameters().get('id'), String.valueOf(cntct.Id));        
        //system.assert(pageRef.getUrl().contains('/WYWYNActivities?'));
        
        PageReference returnUrl = pageController.cancel();
        system.assert(returnUrl.getUrl().contains('/003'));
	}

/**
    	WYWYNActivitites_Negative1()
    	- Empty Contact Id parameter test
    */
	static testMethod void WYWYNActivitites_Negative1()
	{
		// Discontinue if feature is not Active.
		//SFDC-2686
		//if(featureToggleCustomSettings.get('WYWYNActivitiesPageToggle').Toggle__c != true)
		if(FeatureToggles.IS_WYWYN_ACTIVITIES_PAGE_TOGGLE != true)
			return;
		
		Init();
		
		// Create Contact
		Contact cntct = utilTestClass.CreateContact('__Test First','__Test Contact');
		cntct.AccountId = testAccount.Id;		
		insert cntct;
		
		// refresh Contact
		cntct = refreshContact(cntct);
		
		// test
		PageReference pageRef = Page.WYWYNActivities;
        //pageRef.getParameters().put('id', cntct.id);
        Test.setCurrentPageReference(pageRef);
        WYWYNActivitiesController pageController = new WYWYNActivitiesController();        
        
        // assertions
        system.assertEquals(pageRef.getParameters().get('id'), null);
        
	}

	//SFDC-2686
	static testMethod void featureToggleIS_AWE_EXPOSED_TO_PARTNERS()
	{
		if(FeatureToggles.IS_AWE_EXPOSED_TO_PARTNERS != true)
			return;
        
	}
	//SFDC-2686
	static testMethod void featureToggleIsNewWorldConversion()
	{
		if(FeatureToggles.isNewWorldConversion() != true)
			return;
        
	}
	//SFDC-2686
	static testMethod void featureToggleIS_REAL_TIME_CONVERSION_ON()
	{
		if(FeatureToggles.IS_REAL_TIME_CONVERSION_ON != true)
			return;
        
	}
}