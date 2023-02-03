/***
    OpportunityTriggerTestClass
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This Class tests the CloseOldOpptyScheduleClass schedule job.
    
	@History
	--Developer		      --Date			--Change
	Ali KM				05/Jul/2012			CR 1762643 Re-schedule job to make opportunity 'Closed Admin'.
											-> Created this class.
												
*/

@isTest(SeeAllData = false)
private class CloseOldOpptyScheduleTestClass {
	
	//public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();	
	//private static Map<String,Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();
	
	private static List<Opportunity> RefreshOpportunity(Opportunity pOpp)
	{
		return RefreshOpportunity(new List<Opportunity> {pOpp});
	}
	/**
		RefreshOpportunity()
		- Overloaded to refresh bulk Opportunities
	*/
	private static List<Opportunity> RefreshOpportunity(List<Opportunity> pOppList)
	{
		return [select Id,
					   Name,
					   OwnerId,
					   CreatedById
				from Opportunity 
				where Id IN :pOppList];
	}	
	
	/** 
		getUserWithAccountReassignmentRule()
			- PDRA contd 2 fix...
			- Acc Reassignment Rule for acc.Owner
			- Generates a user with AccountReassignment Rule
			- Returns User			
	*/
	private static User getUserWithAccountReassignmentRule()
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
    	/*Profile pr = [select id from profile where name='Sales Operations'][0];
		UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];
		User accOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );*/
		
		User accOwnerUser = utilTestClass.CreateUser('newUser', GsmUtilClass.getGsmSettingValue('User_Role'), 'Sales Operations');
		insert accOwnerUser;		
		// Create a rule
		Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, GsmUtilClass.getGsmSettingValue('User_Role'));
		insert rule;
		//insert getAccountReassignmentRule(accOwnerUser, role);		
		return accOwnerUser;		
	}
	
	static testmethod void test() 
	{
		/*
		String cron_EXP = '0 0 0 3 9 ? 2022';
		Integer intNoOfMonthsOldSetting = 1+Integer.valueOf(GsmUtilClass.GetCustomSettingValue('SchOpptyClose', 'NoOfMonthsOld'));
   		List<User> newUsersList = new List<User>();
		//User usrSalesOp = new User(alias = 'SalesOp', email='usrSalesOp@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__salesop@akamai.com',profileid = prSalesOp.Id);
		User usrSalesOp = utilTestClass.CreateUser('SalesOp', 'Worldwide', 'Sales Operations');
		newUsersList.add(usrSalesOp);
    	//User usrSysAdmin = new User(alias = 'SysAdmin', email='prSysAdmin@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__prSysAdmin@akamai.com',profileid = prSysAdmin.Id);
    	User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
		newUsersList.add(usrSysAdmin);
		//User usrCrmIntg = new User(alias = 'CrmIntg', email='prCrmIntg@akamai.com',emailencodingkey='UTF-8', lastname='TmUser2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__prCrmIntg@akamai.com',profileid = prCrmIntg.Id);
		User usrCrmIntg = utilTestClass.CreateUser('CrmIntg', 'Worldwide', 'CRM Integration');
		newUsersList.add(usrCrmIntg);
		insert newUsersList;
		// Create Account	
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.OwnerId = getUserWithAccountReassignmentRule().Id;
		insert acc;
		// Create Opportunity
		Opportunity oppty = utilTestClass.CreateOpportunity('__Opportunity_Schedule_Test','1-Create');
		oppty.AccountId = acc.Id;
		oppty.CloseDate = Date.today().addMonths(-1*intNoOfMonthsOldSetting);
		insert oppty;
   
   		Test.startTest();      

	  		// Schedule the test job
	      	String jobId = System.schedule('testClosedOldOpptySchedule', cron_EXP, new CloseOldOpptyScheduleClass());
	      	
		   	// Get the information from the CronTrigger API object
	      	CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
	        	 NextFireTime
	         	FROM CronTrigger WHERE id = :jobId];
	
			// Verify the expressions are the same 
	    
			System.assertEquals(cron_EXP, 
		    	ct.CronExpression);
	
	   		// Verify the job has not run
	      	System.assertEquals(0, ct.TimesTriggered);
	
	   		// Verify the next time the job will run
	      	System.assertEquals('2022-09-03 00:00:00', 
	         	String.valueOf(ct.NextFireTime));
	      	System.assertNotEquals('Closed Admin',
	         	[SELECT id, name, StageName FROM opportunity WHERE id = :oppty.id].StageName);

   		Test.stopTest();

   		System.assertEquals('Closed Admin',
   		[SELECT Id, Name, StageName FROM Opportunity WHERE Id = :oppty.Id].StageName);
   		*/

   }

}