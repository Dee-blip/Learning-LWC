/***
    TaskTriggerTestClass
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class implements the unit tests for TaskTrigger.
    			   Use cases that are tested :
    			   1. Single event update, where who Id is a Lead.
    			   2. Test if Oldest Campaign is selected, where who Id is a Lead.
    			   3. Test with no Associated Campaign, where who Id is a Lead.
    			   4. Bulk events update, where who Id is a Lead.
    			   5. Use case where WhatId is null and WhoId is a Contact.	   
    			   6. WhoIdUpdate func
    			   
	History  :
		@History
	--Developer		      --Date			--Change
	Karteek Kumar M		  03/08/2010		CR 634816 Remove any data migration specific code in salesforce
											Removed the following functions : 
												- CrmIntegraion_PositiveTest_AccountTask
												- CrmIntegraion_PositiveTest_CampaignTask
												- CrmIntegraion_PositiveTest_OpportunityTask
	Ali KM				  21/10/10		   	CR 812208 PDRA Update part-2
												- Added logic to run ONA if Account.Owner does not have an AccountReassignmentRule
												- Also added new field Account_Reassignment_Rule__c.User_Role__c & new method:
													-) createAccountReassignmentRule()															
												- Updated following methods with PDRA Update part-2 changes.
													-) UpdateAssocFieldsTest_Opportunity()
													-) UpdateAssocFieldsTest_OrderApproval()

	Ruchika Sharma		  13/07/2015  CR 3081361 Reset credit check status if the existing task for credit check gets completed.
										- Added methods: -creditCheckFlagUpdate_BulkTask_PositiveTest()
														 -creditCheckFlagUpdate_SingleTask_NegatieTest()
														 -creditCheckFlagUpdate_SingleTask_PositiveTest()
														 -getAccount()
	Sonia Sawhney		  01/10/2015  CR 2985554 - Need to prevent case worker collision with activities on SOC cases
									- Added Method: markCaseRelatedTask_Test()                                                                                        																									
*/    			    
@isTest
private class TaskTriggerTestClass 
{
	//public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();
	//private static Map<String,Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();	
	//static User dmlUser = new User(id=UserInfo.getUserId());
	/**
	   SingleTask_PositiveTest()
	   - Single task update.
	*/
	// Create Account reuse function
	/*private static Account CreateAccount(String pAccName)
	{
		Account acc = new Account();
		acc.Name = pAccName;
		acc.BillingCountry = 'India';
      //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
       //End Modified By Chandra For CR 693820 		
		return acc;
	}*/
	
	/**
		createAccountReassignmentRule()
			- generates a new AccountReassignmentRule based on parameters
			- returns Account_Reassignment_Rule__c		
	*/
	/*public static Account_Reassignment_Rule__c  createAccountReassignmentRule(User user, String roleName)
	{
		Account_Reassignment_Rule__c  tempRule = new Account_Reassignment_Rule__c();
		temprule.Name = '__TestRule';
		temprule.Associated_User__c = user.Id;
		if(featureToggleCustomSettings.get('UserRoleUpdateThroughAssignmentRule').Toggle__c == true)
			temprule.User_Role__c = roleName;
		return tempRule;
	}*/
	// Create Contact reuse function
	/*private static Contact CreateContact(String FirstName,String LastName)
	{
		Contact con = new Contact();
		con.FirstName = FirstName;
		con.LastName = LastName;
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';		
        con.Email ='__testContact@Testing.com';
        con.Phone = '999999';        
		con.Title = 'Tester';  
		con.MailingCountry = 'India';
		return con;
	}*/
	// Create Campaign reuse function
	/*private static Campaign CreateCampaign(String camName)
	{
		Campaign cmpgn = new Campaign();
		cmpgn.Name = camName;
		return cmpgn;	
	}*/
	// Create Lead reuse function
	/*private static Lead CreateLead(String Status)
	{
		Lead lead = new Lead();
		lead.Akamai_Vertical__c = 'Gaming';
		lead.Sub_Vertical__c = 'Console Mfs';	
		lead.Status = Status;
		lead.LeadSource ='Live Chat';
		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
        lead.Akamai_Vertical__c = 'Gaming';
        lead.Sub_Vertical__c = 'Console Mfs';		
		return lead; 	
	}*/
	// Create Account Refresh function
	//CR 3081361 : added taskCreatedForCreditCheck__c in query
	/*private static Account RefreshAccount(string acc) //Moved to L2Q_TaskTriggerClassTest
	{
		return [select Id,Name,Division__c,Area__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Id=:acc];
	}*/
	 //Create Campaign Refresh function
	/*private static Campaign RefreshCampaign(string camp) //Moved to L2Q_TaskTriggerClassTest
	{
		return [select ID,AKAM_Campaign_ID__c from Campaign where Id=:camp];
	}*/
	// Create Contact Refresh function
	/*private static Contact RefreshContact(string con) //Moved to L2Q_TaskTriggerClassTest
	{
		return [select Id,AKAM_Contact_ID__c,OD_Contact_ROW_ID__c from Contact where Id=:con][0];
	}*/
	// Create Task Refresh function
	/*private static Task RefreshTask(string tsk) //Moved to L2Q_TaskTriggerClassTest
	{
		return [select Id,WhoId,Associated_Account__c,Associated_Opportunity__c,Account_Sales_Region__c,Associated_AKAM_Contact_ID__c,Associated_OD_Contact_ROW_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_OD_Account_ROW_ID__c,Associated_AKAM_Campaign_ID__c from Task where Id=:tsk][0];
	}*/
	/*static testmethod void SingleTask_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;	
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';	
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
		con.AccountId = acc.Id;
		insert con;
		//Campaign cmpgn = CreateCampaign('__Test Campaign');
		Campaign cmpgn = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn;		
		Lead lead = utilTestClass.CreateLead();
		
		lead.Status = 'Qualifying';

		lead.LeadSource ='Live Chat';

		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		lead.Associated_Contact__c = con.Id;	
		lead.Disposition__c='Existing Customer';
		lead.Product_line__c='Aura';
		insert lead; 

		CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
		cmpgn_member.ContactId = con.Id;		
		insert cmpgn_member;	
		Task tsk = new Task();
		tsk.WhoId = lead.Id;
		tsk.Subject = '__Test Subject';
		TaskTriggerClass.regularIdsMapFirstRunFlag = true;
		//TaskTriggerClass.isAfterUpdateCause = false;
		insert tsk;
		// ---------------------- ASSERT
		//Refresh account, contact, campaign and Task objects
		acc = RefreshAccount(acc.Id);
		cmpgn = RefreshCampaign(cmpgn.Id);
		con = RefreshContact(con.Id);
		tsk = RefreshTask(tsk.Id);
		system.assertEquals(tsk.WhoId,con.Id);
		system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
		system.assertEquals(tsk.whatID,acc.Id);
		system.assertEquals(tsk.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
		system.assertEquals(tsk.Associated_AKAM_Campaign_ID__c,cmpgn.AKAM_Campaign_ID__c);	
	}*/
	/**
	   OldestCampaign_PositiveTest()
	   - Test if Oldest Campaign is selected.
	*/
	/*static testmethod void OldestCampaign_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{  ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');	
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
		con.AccountId = acc.Id;
		insert con;
		// Oldest Campaign
		//Campaign cmpgn1 = CreateCampaign('__Test Campaign');
		Campaign cmpgn1 = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn1;
		// Newer Campaign	
		//Campaign cmpgn2 = CreateCampaign('__Test Campaign');
		Campaign cmpgn2 = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn2;	
		Lead lead = utilTestClass.CreateLead();
		
		lead.Status = 'Qualifying';

		lead.LeadSource ='Live Chat';

		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		lead.Associated_Contact__c = con.Id;
		lead.Disposition__c='Existing Customer';
		lead.Product_line__c='Aura';
		insert lead; 	
		CampaignMember cmpgn_member1 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn1.Id);
		cmpgn_member1.ContactId = con.Id;
		insert cmpgn_member1;
		
		CampaignMember cmpgn_member2 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn2.Id);
		cmpgn_member2.ContactId = con.Id;
		insert cmpgn_member2;
		Task tsk = new Task();
		tsk.WhoId = lead.Id;
		tsk.Subject = '__Test Subject';
		TaskTriggerClass.regularIdsMapFirstRunFlag = true;		
		//TaskTriggerClass.isAfterUpdateCause = false;		
		insert tsk;
		//Refresh account, contact, campaign and Task objects
		acc = RefreshAccount(acc.Id);
		cmpgn1 = RefreshCampaign(cmpgn1.Id);
		cmpgn2 = RefreshCampaign(cmpgn2.Id);
		con = RefreshContact(con.Id);
		tsk = RefreshTask(tsk.Id);
		system.assertEquals(tsk.WhoId,con.Id);
		system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
		system.assertEquals(tsk.whatID,acc.Id);
		system.assertEquals(tsk.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
		system.assert((tsk.Associated_AKAM_Campaign_ID__c == cmpgn1.AKAM_Campaign_ID__c) || (tsk.Associated_AKAM_Campaign_ID__c == cmpgn2.AKAM_Campaign_ID__c));
	}*/	
	/**
	   NoCampaign_PositiveTest()
	   - Test with no Associated Campaign.
	*/
	/*static testmethod void NoCampaign_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
		con.AccountId = acc.Id;
		insert con;
		Lead lead = utilTestClass.CreateLead();
		
		lead.Status = 'Qualifying';

		lead.LeadSource ='Live Chat';

		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		lead.Associated_Contact__c = con.Id;
		lead.Disposition__c='Existing Customer';
		lead.Product_line__c='Aura';
		insert lead; 		
		Task tsk = new Task();
		tsk.WhoId = lead.Id;
		tsk.Subject = '__Test Subject';
		TaskTriggerClass.regularIdsMapFirstRunFlag = true;	
		//TaskTriggerClass.isAfterUpdateCause = false;
		insert tsk;
		//Refresh account, contact, campaign and Task objects
		acc = RefreshAccount(acc.Id);
		con = RefreshContact(con.Id);
		tsk = RefreshTask(tsk.Id);
		system.assertEquals(tsk.WhoId,con.Id);
		system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
		system.assertEquals(tsk.whatID,acc.Id);
		system.assertEquals(tsk.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
		system.assertEquals(tsk.Associated_AKAM_Campaign_ID__c,null);
	}*/		
	/**
	   BulkTask_PositiveTest()
	   - Bulk tasks update 
	*/
	/*static testmethod void BulkTask_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
		con.AccountId = acc.Id;  	
		insert con;
		//Campaign cmpgn = CreateCampaign('__Test Campaign');
		Campaign cmpgn = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn;		
		Lead lead = utilTestClass.CreateLead();
		
		lead.Status = 'Qualifying';

		lead.LeadSource ='Live Chat';

		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		lead.Associated_Contact__c = con.Id;
		lead.Disposition__c='Existing Customer';
		lead.Product_line__c='Aura';
		insert lead; 	
		
		CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
		
		cmpgn_member.ContactId = con.Id;
		insert cmpgn_member;	
		//Bulk Tasks
		Task[] BulkTasks = new Task[200];
		Integer i;
		for(i=0;i<200;i++)
		{
			BulkTasks[i] = new Task();
			BulkTasks[i].WhoId = lead.Id;
			BulkTasks[i].Subject = '__Test Subject ' + i;
		}
		Test.startTest();
		TaskTriggerClass.regularIdsMapFirstRunFlag = true;	
		//TaskTriggerClass.isAfterUpdateCause = false;
		insert BulkTasks;
		Test.stopTest();
		//Refresh account, contact, campaign and Task objects
		acc = RefreshAccount(acc.Id);
		cmpgn = [select ID,AKAM_Campaign_ID__c from Campaign where Id=:cmpgn.Id];
		con =  RefreshContact(con.Id);
		BulkTasks = [select Id,WhoId,Associated_AKAM_Contact_ID__c,Associated_OD_Contact_ROW_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_OD_Account_ROW_ID__c,Associated_AKAM_Campaign_ID__c from Task where Id IN :BulkTasks];
		for(i=0;i<200;i++)
		{
			system.assertEquals(BulkTasks[i].WhoId,con.Id);
			system.assertEquals(BulkTasks[i].Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
			system.assertEquals(BulkTasks[i].whatID,acc.Id);
			system.assertEquals(BulkTasks[i].Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
			system.assertEquals(BulkTasks[i].Associated_AKAM_Campaign_ID__c,cmpgn.AKAM_Campaign_ID__c);
		}
	}*/
	/**
	   WhatIdNull_PositiveTest()
	   - Use case where WhatId is null and WhoId is a Contact.
	*/
	/*static testmethod void WhatIdNull_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
		con.AccountId = acc.Id;
		insert con;		
		Task tsk = new Task();
		tsk.WhoId = con.Id;
		tsk.Subject = '__Test Subject';
		insert tsk;		
		// Refresh Contact, Task and Account
		con = RefreshContact(con.Id);
		acc = RefreshAccount(acc.Id);
		tsk = RefreshTask(tsk.Id);
		system.assertEquals(tsk.whatId,acc.Id);
		system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
	}*/
	/*static testmethod void UpdateAssocFieldsTest_Account() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		// Create Account
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		acc.Division__c = 'A';
		acc.Area__c = 'B';		
		insert acc;
		// Create Task
		Task tsk = new Task();
		tsk.WhatId = acc.Id;
		tsk.Subject = '__Test Subject';
		insert tsk;	
		// Refresh Task and Account
		acc = RefreshAccount(acc.Id);
		tsk =RefreshTask(tsk.Id);
		system.assertEquals(tsk.Associated_Account__c, acc.Name);
		system.assertEquals(tsk.Account_Sales_Region__c, acc.Division__c + ' ' + acc.Area__c );	
	}*/	
	/*static testmethod void UpdateAssocFieldsTest_Opportunity() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		// Create Account
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		acc.Division__c = 'A';
		acc.Area__c = 'B';
		
				
		User accOwnerUser = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
		System.runAs(dmlUser)
		{
			insert accOwnerUser;
		}
		// create rule for acc owner
		//insert createAccountReassignmentRule(accOwnerUser, testcaseCustomSettings.get('User_Role').Value__c);
		Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__Test Rule', accOwnerUser.Id, testcaseCustomSettings.get('User_Role').Value__c);
		insert rule;
		
		acc.OwnerId = accOwnerUser.Id;
		insert acc;
		
		Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
		
		opp.AccountId = acc.Id;
		opp.CloseDate = Date.today().addDays(30);	
		insert opp;		
		// Create Task
		Task tsk = new Task();
		tsk.WhatId = opp.Id;
		tsk.Subject = '__Test Subject';
		insert tsk;	
		// Refresh Task, Oppty and Account
		acc = RefreshAccount(acc.Id);
		opp = [select Id, Name from Opportunity where Id=:opp.Id][0];		
		tsk = RefreshTask(tsk.Id);
		system.assertEquals(tsk.Associated_Opportunity__c, opp.Name);
		system.assertEquals(tsk.Associated_Account__c, acc.Name);
		system.assert((tsk.Account_Sales_Region__c == acc.Division__c + ' ' + acc.Area__c )|| (tsk.Account_Sales_Region__c == acc.Division__c));
	}*/		
	/*static testmethod void UpdateAssocFieldsTest_OrderApproval() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		// Create Account
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		acc.Division__c = 'A';
		acc.Area__c = 'B';		

				
		User accOwnerUser2 = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
		System.runAs(dmlUser)
		{
			insert accOwnerUser2;
		}
		// create rule for acc owner
		//insert createAccountReassignmentRule(accOwnerUser2, testcaseCustomSettings.get('User_Role').Value__c);
		Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__Test Rule', accOwnerUser2.Id, testcaseCustomSettings.get('User_Role').Value__c);
		insert rule;
		
		acc.OwnerId = accOwnerUser2.Id;
		insert acc;
		
		Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');

		opp.AccountId = acc.Id;
		opp.CloseDate = Date.today().addDays(30);	
		insert opp;		
		// Refresh Oppty and Acc
		acc = RefreshAccount(acc.Id);
		opp = [select Id, 
			   		  Name, 
			   		  RecordTypeId, 
			   		  StageName 
			   from Opportunity 
			   where Id=:opp.Id][0];				
		// Create Order Approval
        String returnMsg = OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);
        system.assert(returnMsg.contains('1:'));
        // Get Order Approval
        Order_Approval__c oa = [select Id, 
        							   Associated_Opportunity__c, 
        							   RecordTypeId, 
        							   Deal_Desk_Owner__c,
        							   Legal_Owner__c, CCG__c, 
        							   Deal_Desk__c, Legal__c 
        						from Order_Approval__c 
        						where Associated_Opportunity__c=:opp.Id][0];
        system.assertNotEquals(oa, null);			
		// Create Task
		Task tsk = new Task();
		tsk.WhatId = oa.Id;
		tsk.Subject = '__Test Subject';
		insert tsk;	
		// Refresh Task
		tsk = [select Id, 
					  WhatId, 
					  Associated_Opportunity__c, 
					  Associated_Account__c, 
					  Account_Sales_Region__c 
			   from Task 
			   where Id=:tsk.Id][0];
		system.assertEquals(tsk.Associated_Opportunity__c, opp.Name);
		system.assertEquals(tsk.Associated_Account__c, acc.Name);
		system.assert((tsk.Account_Sales_Region__c == acc.Division__c + ' ' + acc.Area__c )|| (tsk.Account_Sales_Region__c == acc.Division__c));
	}*/		
	/*static testmethod void WhoIdUpdate_SingleTask_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';			
		insert acc;
		Contact con1 = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
		con1.AccountId = acc.Id;        		
		insert con1;
		Contact con2 = utilTestClass.CreateContact('__ Test First','__Test Contact 2');
		con2.AccountId = acc.Id;         					
		insert con2;
		
		Campaign cmpgn = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn;		
		Lead lead = utilTestClass.CreateLead();
		
		lead.Status = 'Qualifying';

		lead.LeadSource ='Live Chat';

		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		lead.Associated_Contact__c = con1.Id;
		lead.Disposition__c='Existing Customer';
		lead.Product_line__c='Aura';
		insert lead;
		
		CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
		cmpgn_member.ContactId = con2.Id;
		insert cmpgn_member;		
		Task tsk = new Task();
		tsk.WhoId=lead.Id;
		tsk.Subject = '__Test Subject';
		insert tsk; 	
		// PUT IN ASSERTS
	}*/
	/*static testmethod void WhoIdUpdate_BulkTask_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');	
		Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.Vertical__c = 'Gaming';
		insert acc;
		Contact con1 = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
		con1.AccountId = acc.Id;      				
		insert con1;
		Contact con2 = utilTestClass.CreateContact('__ Test First','__Test Contact 2');
		con2.AccountId = acc.Id;       				
		insert con2;
		//Campaign cmpgn = CreateCampaign('__Test Campaign');
		Campaign cmpgn = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn;
		Lead lead1 = utilTestClass.CreateLead();
		
		lead1.Status = 'Qualifying';

		lead1.LeadSource ='Live Chat';

		lead1.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		lead1.Associated_Contact__c = con1.Id;
		lead1.Disposition__c='Existing Customer';
		lead1.Product_line__c='Aura';
		insert lead1; 
		
		CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(lead1.Id, cmpgn.Id);
		cmpgn_member.ContactId = con2.Id;
		insert cmpgn_member;		
		Integer i=0;
		Task[] BulkTasks = new Task[200];
		for(i=0;i<200;i++)
		{
			BulkTasks[i] = new Task();
			BulkTasks[i].WhoId=lead1.Id;
			BulkTasks[i].Subject = '__Test Subject ' + i;
		}
		insert BulkTasks;
		// PUT IN ASSERTS 	
	}*/

	/*static Account getAccount() //Moved to L2Q_TaskTriggerClassTest
    {
		Account acc = utilTestClass.CreateAccount('__Test Account'+utilTestClass.getRandomString(4));
		acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';	
        acc.taskCreatedForCreditCheck__c = true;
        return acc;
	}*/ 
	//CR 3081361
	/*static testmethod void creditCheckFlagUpdate_SingleTask_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');
		Account acc = getAccount();

        Test.startTest();
		insert acc;
		
		Task tsk = new Task();
		tsk.whatId=acc.Id;
		tsk.Subject = 'Credit Check Needed';
		tsk.Status = 'In Progress';
		insert tsk; 	
		
		tsk.Status = 'Completed';
		update tsk;

		Account refreshedAccount = RefreshAccount(acc.id);
		System.debug('tsk:: '+tsk.Status+' acc : '+refreshedAccount.taskCreatedForCreditCheck__c);
		System.assertEquals(refreshedAccount.taskCreatedForCreditCheck__c,false);

		Test.stopTest();


	}*/

	/*static testmethod void creditCheckFlagUpdate_SingleTask_NegatieTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');
		Account acc = getAccount();

        Test.startTest();
		insert acc;
		
		Task tsk = new Task();
		tsk.whatId=acc.Id;
		tsk.Subject = 'Send Letter';
		tsk.Status = 'In Progress';
		insert tsk; 	
		
		tsk.Status = 'Completed';
		update tsk;

		Account refreshedAccount = RefreshAccount(acc.id);
		Test.stopTest();
		System.assertEquals(refreshedAccount.taskCreatedForCreditCheck__c,true);

	}*/
	/*static testmethod void creditCheckFlagUpdate_BulkTask_PositiveTest() //Moved to L2Q_TaskTriggerClassTest
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		//Account acc = CreateAccount('__Test Account');
		List<Account> accList = new List<Account>();	
		Account acc = getAccount();
		accList.add(acc);

		Account acc1 =getAccount();
		accList.add(acc1);

		Test.startTest();
		insert accList;
				
		Integer i=0;
		List<Task> BulkTasks = new List<Task>();
		for(i=0;i<100;i++)
		{
			Task tsk = new Task();
			tsk.whatId=acc.Id;
			tsk.Subject = 'Credit Check Needed';
			tsk.Status = 'In Progress';
			BulkTasks.add(tsk);
			Task tsk1 = new Task();
			tsk1.whatId=acc1.Id;
			tsk1.Subject = 'Credit Check Needed';
			tsk1.Status = 'In Progress';
			BulkTasks.add(tsk1);
		}
		insert BulkTasks;

		//BulkTasks = [Select id,Status from Task where ]
		for(Task tsk: BulkTasks){
			tsk.Status = 'Completed';
		}

		update BulkTasks;

		Account refreshedAccount = RefreshAccount(acc.id);
		Account refreshedAccount1 = RefreshAccount(acc1.id);
		Test.stopTest();
		System.assertEquals(refreshedAccount.taskCreatedForCreditCheck__c,false);
		System.assertEquals(refreshedAccount1.taskCreatedForCreditCheck__c,false);


	}*/
	
	/**
		Added by Sonia Sawhney on 01/10/2015 for CR 2985554 
	    - Use cases for marking is case related checkbox which triggers streaming api updated for cases
	*/
	static testmethod void markCaseRelatedTask_Test()
	{
		Id usrId = Userinfo.getUserId();
		Account acc = utilTestClass.CreateAccount('test displayCaseTasks');
        insert acc;

        EB_AccountProductMap__c caseProduct = new EB_AccountProductMap__c(Name = 'test case product', EB_Account__c = acc.Id, EB_Account_RW__c = acc.Id, EB_Product__c ='product name');
        insert caseProduct ;

        Id rectypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        Case objCase = new Case(AccountId = acc.Id,subject='Test', description='test', Ownerid = usrId, AKAM_Case_ID__c='ehsdsg',RecordTypeId=rectypeId, Do_not_show_in_portal__c = true, Case_Product__c = caseProduct.Id,Validation_Override__c = true);
        insert objCase;

        Task tsk =  utilTestClass.CreateTask(usrId, 'Customer Meeting', 'In Progress', 'Meeting', objCase.Id);
        insert tsk; 

        Task tmpTask = [Select Is_Case_Related__c from Task where Id = :tsk.Id];
        System.assert(tmpTask.Is_Case_Related__c == true);
	}
}