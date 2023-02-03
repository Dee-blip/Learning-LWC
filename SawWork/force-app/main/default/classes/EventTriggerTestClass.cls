/**
    EventTriggerTestClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class implements the unit tests for EventTrigger.
    			   Use cases that are tested :   
    			   1. Single event update.
    			   2. Test if Oldest Campaign is selected.
    			   3. Test with no Associated Campaign.
    			   4. Bulk events update 
    			   
	@History
	
	Ali KM				  18/10/2010		CR 828372 Changes to Lead Field
											- Initializing Disposition to New when Leads are created.    			   
*/
@isTest(seeAlldata=true)
private class EventTriggerTestClass 
{
	/**
	   SingleEvent_PositiveTest()
	   - Single event update.
	*/
	static testmethod void SingleEvent_PositiveTest()
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		/*Account acc = new Account();
		acc.Name = '__Test Account 1';
		acc.BillingCountry = 'India';
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';*/
        Account acc = utilTestClass.CreateAccount('__ Test Account 1');
		acc.Vertical__c = 'Gaming';
		acc.Sub_Vertical__c = 'Console Mfs';			
		insert acc;
		
		Contact con = utilTestClass.CreateContact('__ Test First', '__Test Contact 1');
		con.AccountId = acc.Id;
		/*con.FirstName = '__ Test First';
		con.LastName = '__Test Contact 1';
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';
        con.Email ='__testContact@Testing.com';
        con.Phone = '999999';    
        con.Title = 'Tester';
        con.MailingCountry = 'India';*/       			
		insert con;
		/*Campaign cmpgn = new Campaign();
		cmpgn.Name = '__Test Campaign';*/
		Campaign cmpgn = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn;
				
		Lead lead = utilTestClass.CreateLead();
        //lead.Akamai_Vertical__c = 'Gaming';
        //lead.Sub_Vertical__c = 'Console Mfs';			
		lead.Associated_Contact__c = con.Id;
		//lead.Akamai_Vertical__c = 'Gaming';
		lead.Status = 'Qualifying';
		lead.Disposition__c = 'New';
		lead.LeadSource ='Live Chat';
		lead.Product_line__c='Aura';
		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		insert lead; 		
		/*CampaignMember cmpgn_member = new CampaignMember();
		cmpgn_member.CampaignId = cmpgn.Id;
		cmpgn_member.LeadId = lead.Id;*/
		CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
		cmpgn_member.ContactId = con.Id;
		insert cmpgn_member;	
		Event event = new Event();
		event.WhoId = lead.Id;
		event.Subject = '__Test Subject';
		event.StartDateTime = Datetime.now();
		event.EndDateTime = Datetime.now().addDays(10);
		insert event;
		// ---------------------- TEST INSERT
		//Refresh account, contact, campaign and event objects
		acc = [select Id,AKAM_Account_ID__c,OD_Account_ROW_ID__c from Account where Id=:acc.Id];
		cmpgn = [select ID,AKAM_Campaign_ID__c from Campaign where Id=:cmpgn.Id];
		con = [select Id,AKAM_Contact_ID__c,OD_Contact_ROW_ID__c from Contact where Id=:con.Id][0];
		event = [select Id,WhoId,Associated_AKAM_Contact_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_AKAM_Campaign_ID__c from Event where Id=:event.Id][0];
		system.assertEquals(event.WhoId,con.Id);
		system.assertEquals(event.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
		
		system.assertEquals(event.whatID,acc.Id);
		system.assertEquals(event.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
		system.assertEquals(event.Associated_AKAM_Campaign_ID__c,cmpgn.AKAM_Campaign_ID__c);
		//----------------------- TEST UPDATE
		
		
		/*Account accNew = new Account();
		accNew.Name = '__Test Account 2';
		accNew.BillingCountry = 'India';
		//Start Modified By Chandra For CR 693820
        accNew.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        accNew.Sub_Vertical__c = 'Console Mfs';*/
        Account accNew = utilTestClass.CreateAccount('__ Test Account 2');
		accNew.Vertical__c = 'Gaming';
		accNew.Sub_Vertical__c = 'Console Mfs';			
		insert accNew;

		Contact conNew = utilTestClass.CreateContact('__ Test First', '__Test Contact 1');
		conNew.AccountId = accNew.Id;
		/*conNew.FirstName = '__ Test First';
		conNew.LastName = '__Test Contact 1';
        conNew.Akamai_Vertical__c = 'Gaming';
        conNew.Sub_Vertical__c = 'Console Mfs';
        conNew.Phone = '99999';
        conNew.Title = 'Tester';
        conNew.Email = 'Testeer@Testing.com';
        conNew.MailingCountry = 'India';*/		
		insert conNew;
		/*Campaign cmpgnNew = new Campaign();
		cmpgnNew.Name = '__Test Campaign';*/
		Campaign cmpgnNew = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgnNew;		
		Lead leadNew = utilTestClass.CreateLead();
		leadNew.Associated_Contact__c = conNew.Id;
        //leadNew.Akamai_Vertical__c = 'Gaming';
        //leadNew.Sub_Vertical__c = 'Console Mfs';		
		leadNew.Status = 'Qualifying';
		leadNew.Disposition__c = 'New';
		leadNew.LeadSource ='Live Chat';
		leadNew.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		leadNew.Company = 'Use Contact Info';
		leadNew.LastName = 'Use Contact Info';
		leadNew.Product_line__c='Aura';
		insert leadNew; 		
		/*CampaignMember cmpgnNew_member = new CampaignMember();
		cmpgnNew_member.CampaignId = cmpgnNew.Id;
		cmpgnNew_member.LeadId = leadNew.Id;*/
		CampaignMember cmpgnNew_member = utilTestClass.CreateCampaignMember(leadNew.Id, cmpgnNew.Id);
		cmpgnNew_member.ContactId = conNew.Id;
		insert cmpgnNew_member;
		event.WhoId = leadNew.Id;
		update event;	
		accNew = [select Id,AKAM_Account_ID__c,OD_Account_ROW_ID__c from Account where Id=:accNew.Id];
		cmpgnNew = [select ID,AKAM_Campaign_ID__c from Campaign where Id=:cmpgnNew.Id];
		conNew = [select Id,AKAM_Contact_ID__c,OD_Contact_ROW_ID__c from Contact where Id=:conNew.Id][0];
		event = [select Id,WhoId,Associated_AKAM_Contact_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_AKAM_Campaign_ID__c from Event where Id=:event.Id][0];
		system.assertEquals(event.WhoId,conNew.Id);
		system.assertEquals(event.Associated_AKAM_Contact_ID__c,conNew.AKAM_Contact_ID__c);
	
		system.assertEquals(event.whatID,accNew.Id);
		system.assertEquals(event.Associated_AKAM_Account_ID__c,accNew.AKAM_Account_ID__c);
		system.assertEquals(event.Associated_AKAM_Campaign_ID__c,cmpgnNew.AKAM_Campaign_ID__c);		
	}
	/**
	   OldestCampaign_PositiveTest()
	   - Test if Oldest Campaign is selected.
	*/
	static testmethod void OldestCampaign_PositiveTest()
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		/*Account acc = new Account();
		acc.Name = '__Test Account';
		acc.BillingCountry = 'India';
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';*/
        Account acc = utilTestClass.CreateAccount('__ Test Account');
		acc.Vertical__c = 'Gaming';
		acc.Sub_Vertical__c = 'Console Mfs';			
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First', '__Test Contact 1');
		con.AccountId = acc.Id;
		/*con.FirstName = '__ Test First';
		con.LastName = '__Test Contact 1';
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';
        con.Email ='__testContact@Testing.com';
        con.Phone = '999999';     
		con.Title = 'Tester'; 
		con.MailingCountry = 'India';*/             			
		insert con;
		// Oldest Campaign
		/*Campaign cmpgn1 = new Campaign();
		cmpgn1.Name = '__Test Campaign';*/
		Campaign cmpgn1 = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn1;
		// Newer Campaign	
		/*Campaign cmpgn2 = new Campaign();
		cmpgn2.Name = '__Test Campaign';*/
		Campaign cmpgn2 = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn2;
			
		Lead lead = utilTestClass.CreateLead();
		lead.Associated_Contact__c = con.Id;
        //lead.Akamai_Vertical__c = 'Gaming';
        //lead.Sub_Vertical__c = 'Console Mfs';
		lead.Status = 'Qualifying';
		lead.Disposition__c = 'New';
		lead.LeadSource ='Live Chat';
		lead.Product_line__c='Aura';
		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		insert lead; 		
		/*CampaignMember cmpgn_member1 = new CampaignMember();
		cmpgn_member1.CampaignId = cmpgn1.Id;
		cmpgn_member1.LeadId = lead.Id;*/
		CampaignMember cmpgn_member1 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn1.Id);
		cmpgn_member1.ContactId = con.Id;
		insert cmpgn_member1;
		/*CampaignMember cmpgn_member2 = new CampaignMember();
		cmpgn_member2.CampaignId = cmpgn2.Id;
		cmpgn_member2.LeadId = lead.Id;*/
		CampaignMember cmpgn_member2 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn2.Id);
		cmpgn_member2.ContactId = con.Id;
		insert cmpgn_member2;
		Event event = new Event();
		event.WhoId = lead.Id;
		event.Subject = '__Test Subject';
		event.StartDateTime = Datetime.now();
		event.EndDateTime = Datetime.now().addDays(10);
		insert event;
		//Refresh account, contact, campaign and event objects
		acc = [select Id,AKAM_Account_ID__c,OD_Account_ROW_ID__c from Account where Id=:acc.Id];
		cmpgn1 = [select ID,AKAM_Campaign_ID__c from Campaign where Id=:cmpgn1.Id];
		cmpgn2 = [select ID,AKAM_Campaign_ID__c from Campaign where Id=:cmpgn2.Id];
		con = [select Id,AKAM_Contact_ID__c,OD_Contact_ROW_ID__c from Contact where Id=:con.Id][0];
		event = [select Id,WhoId,Associated_AKAM_Contact_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_AKAM_Campaign_ID__c from Event where Id=:event.Id][0];
		system.assertEquals(event.WhoId,con.Id);
		system.assertEquals(event.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
		
		system.assertEquals(event.whatID,acc.Id);
		system.assertEquals(event.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
		system.assert((event.Associated_AKAM_Campaign_ID__c == cmpgn1.AKAM_Campaign_ID__c) || (event.Associated_AKAM_Campaign_ID__c == cmpgn2.AKAM_Campaign_ID__c));
	}	
	/**
	   NoCampaign_PositiveTest()
	   - Test with no Associated Campaign.
	*/
	static testmethod void NoCampaign_PositiveTest()
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		/*Account acc = new Account();
		acc.Name = '__Test Account';
		acc.BillingCountry = 'India';
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';*/
        Account acc = utilTestClass.CreateAccount('__ Test Account');
		acc.Vertical__c = 'Gaming';
		acc.Sub_Vertical__c = 'Console Mfs';			
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First', '__Test Contact 1');
		con.AccountId = acc.Id;
		/*con.FirstName = '__ Test First';
		con.LastName = '__Test Contact 1';
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';
        con.Email ='__testContact@Testing.com';
        con.Phone = '999999';
		con.Title = 'Tester';
		con.MailingCountry = 'India';*/	        
		insert con;
		
		Lead lead = utilTestClass.CreateLead();
		lead.Associated_Contact__c = con.Id;
        //lead.Akamai_Vertical__c = 'Gaming';
        //lead.Sub_Vertical__c = 'Console Mfs';	
		lead.Status = 'Qualifying';
		lead.Disposition__c = 'New';
		lead.LeadSource ='Live Chat';
		lead.Product_line__c='Aura';
		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		insert lead;
		
		Event event = new Event();
		event.WhoId = lead.Id;
		event.Subject = '__Test Subject';
		event.StartDateTime = Datetime.now();
		event.EndDateTime = Datetime.now().addDays(10);
		insert event;
		//Refresh account, contact, campaign and event objects
		acc = [select Id,AKAM_Account_ID__c,OD_Account_ROW_ID__c from Account where Id=:acc.Id];
		con = [select Id,AKAM_Contact_ID__c,OD_Contact_ROW_ID__c from Contact where Id=:con.Id][0];
		event = [select Id,WhoId,Associated_AKAM_Contact_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_AKAM_Campaign_ID__c from Event where Id=:event.Id][0];
		system.assertEquals(event.WhoId,con.Id);
		system.assertEquals(event.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
		
		system.assertEquals(event.whatID,acc.Id);
		system.assertEquals(event.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
		system.assertEquals(event.Associated_AKAM_Campaign_ID__c,null);
	}		
	/**
	   BulkEvent_PositiveTest()
	   - Bulk events update 
	*/
	static testmethod void BulkEvent_PositiveTest()
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		/*Account acc = new Account();
		acc.Name = '__Test Account';
		acc.BillingCountry = 'India';
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';*/
        Account acc = utilTestClass.CreateAccount('__ Test Account 1');
		acc.Vertical__c = 'Gaming';
		acc.Sub_Vertical__c = 'Console Mfs';			
		insert acc;
		Contact con = utilTestClass.CreateContact('__ Test First', '__Test Contact 1');
		con.AccountId = acc.Id;
		/*con.FirstName = '__ Test First';
		con.LastName = '__Test Contact 1';
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';
        con.Email ='__testContact@Testing.com';
        con.Phone = '999999';           
		con.Title = 'Tester';
		con.MailingCountry = 'India';*/        			
		insert con;
		/*Campaign cmpgn = new Campaign();
		cmpgn.Name = '__Test Campaign';*/
		Campaign cmpgn = utilTestClass.CreateCampaign('__Test Campaign');
		insert cmpgn;
				
		Lead lead = utilTestClass.CreateLead();
		lead.Associated_Contact__c = con.Id;
        //lead.Akamai_Vertical__c = 'Gaming';
        //lead.Sub_Vertical__c = 'Console Mfs';	
		lead.Status = 'Qualifying';
		lead.Disposition__c = 'New';
		lead.LeadSource ='Live Chat';
		lead.Product_line__c='Aura';
		lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
		insert lead; 		
		/*CampaignMember cmpgn_member = new CampaignMember();
		cmpgn_member.CampaignId = cmpgn.Id;
		cmpgn_member.LeadId = lead.Id;*/
		CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
		cmpgn_member.ContactId = con.Id;
		insert cmpgn_member;	
		//Bulk Events
		Event[] BulkEvents = new Event[200];
		Integer i;
		for(i=0;i<200;i++)
		{
			BulkEvents[i] = new Event();
			BulkEvents[i].WhoId = lead.Id;
			BulkEvents[i].Subject = '__Test Subject ' + i;
			BulkEvents[i].StartDateTime = Datetime.now();
			BulkEvents[i].EndDateTime = Datetime.now().addDays(10);
		}
		Test.startTest();
		insert BulkEvents;
		Test.stopTest();
		//Refresh account, contact, campaign and event objects
		acc = [select Id,AKAM_Account_ID__c,OD_Account_ROW_ID__c from Account where Id=:acc.Id];
		cmpgn = [select ID,AKAM_Campaign_ID__c from Campaign where Id=:cmpgn.Id];
		con = [select Id,AKAM_Contact_ID__c,OD_Contact_ROW_ID__c from Contact where Id=:con.Id][0];
		BulkEvents = [select Id,WhoId,Associated_AKAM_Contact_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_AKAM_Campaign_ID__c from Event where Id IN :BulkEvents];
		for(i=0;i<200;i++)
		{
			system.assertEquals(BulkEvents[i].WhoId,con.Id);
			system.assertEquals(BulkEvents[i].Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
			system.assertEquals(BulkEvents[i].whatID,acc.Id);
			system.assertEquals(BulkEvents[i].Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
			system.assertEquals(BulkEvents[i].Associated_AKAM_Campaign_ID__c,cmpgn.AKAM_Campaign_ID__c);
		}
	}
}