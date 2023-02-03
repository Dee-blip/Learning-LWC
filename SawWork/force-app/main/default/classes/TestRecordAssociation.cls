public class TestRecordAssociation {
	//CR 2770464 - rsharma: Changing visibility
	public class accountUser{
		public Account a {get; private set;}
		public User u {get; private set;}
		
		accountUser(Account acc, User usr){
			this.a = acc;
			this.u = usr;
		}
	}
 
 //CR 2770464 - rsharma: Changing visibility
	public static accountUser createAccountInfo(Integer var){
		GroupSharingHelper.ISTEST = true;
		//Account a1 = new Account(name = 'Partner '+var ,billingcity = 'city'+var,billingstreet = 'street'+var, billingstate = 'CA',   
		//						billingcountry = 'USA', association_Account__c = true);
		Account a1 = utilTestClass.CreateAccount('Partner '+var);
        a1.BillingCity = 'city'+var;
        a1.BillingStreet = 'street'+var;
        a1.BillingState = 'CA';
        a1.BillingCountry = 'USA';
        a1.Association_Account__c = true;
		a1.Maximum_Licenses__c=3;
		//a1.isPartner=true;
		//a1.isPartnerCustom__c=true;
		insert a1;
		//enable the account as partner account
		String pQuery = 'select isPartner from account where id = \'' + a1.Id + '\'';
		List<Account> accs = Database.query(pQuery);
		Account a2 = accs[0];
		a2.put('isPartner',true);
		a2.put('isPartnerCustom__c',true);
		a2.Validation_Override__c=true;
/*		Account a2 = [select isPartner from account where id = :a1.id];
		a2.isPartner = true;*/
		update a2;
		//Contact c11 = new Contact(lastname = 'Contact'+var, accountid = a1.id);
		Contact c11 = utilTestClass.CreateContact('Test','Contact'+var);
		c11.AccountId = a1.Id;
		insert c11;
		//enable partner user
		Contact c1 = [select id, email from Contact where id = :c11.id];
		c1.email = '';
		update c1;
		Profile p ;
/*	Map<String, Default__c> accessSettingsMap = Default__c.getAll();
	Default__c settings ;
	if(accessSettingsMap.containsKey('Default')){
		settings = accessSettingsMap.get('Default');
	}
//	if(GroupSharingHelper.isPartnerEnabled()){
		Boolean isPartnerPortal = false;
		if(settings != null){
			isPartnerPortal = settings.is_Partner_Portal_Enabled__c;
		}
	if(isPartnerPortal){*/
//		if(GroupSharingHelper.isPartnerEnabled()){
			p = [select Id from Profile where usertype = 'PowerPartner' and name like '%Partner%' limit 1];
/*		}else{
			p = [select id from Profile limit 1];
		}*/
		
		User u11 = new User( lastname = 'User'+var, alias = 'user'+var, email = 'a@a.com', username = 'amtv@a.com.'+var, contactid = c11.id, localesidkey = 'en_US',
							languagelocalekey = 'en_US', timezoneSidKey = 'America/Los_Angeles', emailEncodingKey = 'UTF-8', profileId = p.id);
		insert u11;		
		accountUser AU = new accountUser(a1,u11);
		return AU;			
	}
	//CR 2770464 - rsharma: Changing visibility
	public static list<id> createAccountInfoVersion2(Integer limitvalue){
		integer var=0;
		//insert accounts
		list<account> acclist=new list<account>();
		for(var=0;var<limitvalue;var++)
		{
			Account a1 = utilTestClass.CreateAccount('Partner '+var);
	        a1.BillingCity = 'city'+var;
	        a1.BillingStreet = 'street'+var;
	        a1.BillingState = 'CA';
	        a1.BillingCountry = 'USA';
	        a1.Association_Account__c = true;
			a1.Maximum_Licenses__c=3;
			acclist.add(a1);
		}
		insert acclist;
		//update accounts
		list<account> acclist2=new list<account>();
		for(Account acc:acclist)
		{
			acc.isPartner=true;
			acc.IsPartnerCustom__c=true;
			acc.Validation_Override__c=true;
			acclist2.add(acc);
		}
		update acclist2;
		var=0;
		//insert contacts
		list<contact> conlist=new list<contact>();
		for(Account acc:acclist)
		{
			Contact c11 = utilTestClass.CreateContact('Test','Contact'+var);
			c11.AccountId = acc.Id;
			conlist.add(c11);
			var++;
		}
		insert conlist;
		//get profile
		Profile p ;
		p = [select Id from Profile where usertype = 'PowerPartner' and name like '%Partner%' limit 1];
		//insert users
		list<User> usrlist=new list<User>();
		var=0;
		for(Contact con:conlist)
		{
			User u11 = new User( lastname = 'User'+var, alias = 'user'+var, email = 'a@a.com', username = 'amtv@a.com.'+var, contactid = con.id, localesidkey = 'en_US',
							languagelocalekey = 'en_US', timezoneSidKey = 'America/Los_Angeles', emailEncodingKey = 'UTF-8', profileId = p.id);
			usrlist.add(u11);
			var++;
		}
		insert usrlist;
		list<id> idlist=new list<id>();
		for(Account acc:acclist)
		{
			idlist.add(acc.id);
		}
		return idlist;
	}

	//CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
//	static testmethod void testAccountAssociation(){
//		List<Id> auList = new List<Id>();
//		auList.addall(createAccountInfoVersion2(5));
//		/*for(Integer i=0;i<5;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
//		PageReference pageRef = Page.manageAccountAssociation;
//		Test.setCurrentPage(pageRef);
//		List<RecordAssociation__c> rList = new List<RecordAssociation__c>();
//		RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[1].id, associated_account__c = accts[2].id, Account_Role__c = 'Partner', primary__c=true);
//		RecordAssociation__c recAssoc2 = new RecordAssociation__c(Account__c = accts[3].id, associated_account__c = accts[2].id, Account_Role__c = 'End Customer');
//		RecordAssociation__c recAssoc3 = new RecordAssociation__c(Account__c = accts[3].id, associated_account__c = accts[4].id, Account_Role__c = 'Distributor/Var');
//		rList.add(recAssoc1);
//		rList.add(recAssoc2);
//		rList.add(recAssoc3);
//		test.startTest();
//		insert rList;
		
//		RecordAssociation__c ra = [Select id, Account_Role__c from RecordAssociation__c where id = :recAssoc3.id];
//		RecordAssociation__c ra1 = [Select id, Account_Role__c from RecordAssociation__c where id = :recAssoc1.id];
//		RecordAssociation__c ra2 = [Select id, Account_Role__c from RecordAssociation__c where id = :recAssoc2.id];
//		System.assertEquals('Distributor/VAR', ra.Account_Role__c);
		
//		ApexPages.StandardController controller = new ApexPages.StandardController(recAssoc1);
//		P2P_AccountAssociationController testAccAssController = new P2P_AccountAssociationController(controller);
//		testAccAssController.onLoad();
		
//		System.currentPageReference().getParameters().put('selectedId','0');
//		System.currentPageReference().getParameters().put('id',ra.Id);
				
//		testAccAssController.onAddCondition();		
//		System.currentPageReference().getParameters().put('selectedId','1');
//		System.currentPageReference().getParameters().put('id',ra1.Id);
			
//		testAccAssController.onSave();
		
//		testAccAssController.onLoad();
//		System.currentPageReference().getParameters().put('selectedId','2');
//		System.currentPageReference().getParameters().put('id',ra2.Id);		
//		testAccAssController.onSave();
//		System.assertEquals('Cannot add duplicate Account Associations', testAccAssController.errorMsg);
//		testAccAssController.onRemoveCondition();		
//		testAccAssController.onSave();		
//		testAccAssController.onCancel();
//		//testAccAssController.selectAccount();
//		test.stoptest();		
//	}
	
//	static testmethod void testRecordAssociation(){
//		try{
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<5;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(5));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
//		List<RecordAssociation__c> rList = new List<RecordAssociation__c>();
//		RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[1].id, associated_account__c = accts[2].id, Account_Role__c = 'Partner', primary__c=true);
//		rList.add(recAssoc1);
//		insert rList;		
//		RecordAssociation__c ra = [Select id, primary__c from RecordAssociation__c where id = :recAssoc1.id];
//		System.assertEquals(true, ra.primary__c);
		
//		User u1 = [select id from User where contact.accountid = :accts[2].id];
//		Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
//		//Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
//		Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
//		opp.CloseDate = Date.today();
//		System.runAs(u1){
//			Test.startTest();
//			insert l;
//			insert opp;
//			Test.stopTest();
//		} 
//		PageReference pageRef = Page.selectRecordAssociation;
//		Test.setCurrentPage(pageRef);
//		//test controller for account association with lead
//		System.currentPageReference().getParameters().put('leadId',l.id);
//		SelectAssociationOnRecordController testLeadAssocController = new  SelectAssociationOnRecordController();
//		testLeadAssocController.uncheckPrimaryIfChecked();
//		testLeadAssocController.getpreferredAccountWithSelects(); 
//		testLeadAssocController.Save();
//		testLeadAssocController.addPreferredAccountAssociation();
//		PageReference pageRef1 = Page.selectRecordAssociation;
//		Test.setCurrentPage(pageRef1);
//		SelectAssociationOnRecordController testRecordLeadCon = new  SelectAssociationOnRecordController();
//		testRecordLeadCon.getpreferredAccountWithSelects(); 
//		testRecordLeadCon.Cancel();
				
//		//test controller for account association with opportunity
//		System.currentPageReference().getParameters().put('oppId',opp.id);
//		SelectAssociationOnRecordController testRecordOppController = new  SelectAssociationOnRecordController();
//		testRecordOppController.uncheckPrimaryIfChecked();
//		testRecordOppController.getpreferredAccountWithSelects(); 
//		testRecordOppController.Save();
//		testRecordOppController.addPreferredAccountAssociation();
//		PageReference pageRef2 = Page.selectRecordAssociation;
//		Test.setCurrentPage(pageRef2);
//		SelectAssociationOnRecordController testRecordOppCon = new SelectAssociationOnRecordController();
//		testRecordOppCon.getpreferredAccountWithSelects();
//		testRecordOppCon.Cancel();
//		}catch(Exception e){
//			System.debug('Exception: ' + e.getMessage());
//		}				
//	}
	
//	static testmethod void testLookup(){ 
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
//		User u1 = [select id from User where contact.accountid = :accts[1].id];
//		User u2 = [select id from User where contact.accountid = :accts[0].id];
//		Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
//		l.Validation_Override__c=true;
//		PageReference pageRef = Page.ChangeOwner;
//		Test.setCurrentPage(pageRef);
//		Test.startTest();					
//		System.runAs(u1){
//			insert l;
//			System.currentPageReference().getParameters().put('id',l.id);
//			PartnerUserLookupController testCon = new PartnerUserLookupController();
//			testCon.initLookupPage();
//			System.assertEquals(false, testCon.error);
//			testCon.getHasResults();
//			testCon.getRenderResultSets();
//			testCon.getResults();
//			testCon.save();
//			testCon.cancel();
//			testCon.getOppId();
//			//PartnerUserLookupController testCon2 = new PartnerUserLookupController();
//			//testCon2.initLookupPage();
//		}
		
//		System.runAs(u1){
//			System.currentPageReference().getParameters().put('id',accts[1].id);
//			PartnerUserLookupController testCon = new PartnerUserLookupController();
//			testCon.initLookupPage();
//			testCon.getHasResults();
//			testCon.getRenderResultSets();
//			testCon.getResults();
//			testCon.setUserID(u2.Id);
//			testCon.save();
//			testCon.cancel();
//			testCon.getOppId();
//		}
//		Test.stopTest();
//	}

//	static testmethod void testCreateObjectAssociation(){
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
		
//		User u1 = [select id from User where contact.accountid = :accts[0].id];
		
//		Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
//		l.Validation_Override__c=true;
//		//Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
//		Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
//		opp.CloseDate = Date.today();
//		opp.Validation_Override__c=true;
//		System.runAs(u1){
//			insert l;
//			insert opp;
//		} 
//		Object_Association__c objAssoc1 = new Object_Association__c(associated_account__c = accts[1].id, leadId__c = l.id);
//		insert objAssoc1;
		
//		Object_Association__c oa1 = [Select Associated_Account__c, LeadId__c from Object_Association__c where id = :objAssoc1.Id];
//		System.assertEquals(l.id, oa1.LeadId__c);
//		System.assertEquals(accts[1].id, oa1.Associated_Account__c);
		
//		PageReference pageRef = Page.selectRecordAssociation;
//		Test.setCurrentPage(pageRef);
//		//test controller for account association with lead
//		System.currentPageReference().getParameters().put('leadId',l.id);
//		SelectAssociationOnRecordController testLeadAssocController = new  SelectAssociationOnRecordController();
//		testLeadAssocController.uncheckPrimaryIfChecked();
//		testLeadAssocController.getpreferredAccountWithSelects(); 
//		testLeadAssocController.Save();
//		testLeadAssocController.addPreferredAccountAssociation();		
//		testLeadAssocController.Cancel();
		
//		Object_Association__c objAssoc2 = new Object_Association__c(associated_account__c = accts[1].id, OpportunityId__c = opp.id);		
//		insert objAssoc2;
		
//		Object_Association__c oa2 = [Select Associated_Account__c, OpportunityId__c from Object_Association__c where id = :objAssoc2.Id];
//		System.assertEquals(opp.id, oa2.OpportunityId__c);
//		System.assertEquals(accts[1].id, oa2.Associated_Account__c);
//	}
	
//	static testmethod void testDeleteObjectAssociation(){
//		List<Id> auList = new List<Id>();
//		Set<Id> toDeleteIds = new Set<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
		
//		User u1 = [select id from User where contact.accountid = :accts[0].id];
		
//		Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
//		l.Validation_Override__c=true;
//		//Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
//		Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
//		opp.CloseDate = Date.today();
//		opp.Validation_Override__c=true;
//		System.runAs(u1){
//			insert l;
//			insert opp;
//		} 
//		Object_Association__c objAssoc1 = new Object_Association__c(associated_account__c = accts[1].id, leadId__c = l.id);
//		insert objAssoc1;
//		toDeleteIds.add(objAssoc1.Id);
		
//		Object_Association__c objAssoc2 = new Object_Association__c(associated_account__c = accts[1].id, OpportunityId__c = opp.id);
//		insert objAssoc2;
//		toDeleteIds.add(objAssoc2.Id);
		
//		List<Object_Association__c> toDeleteList = [Select id from Object_Association__c where id in :toDeleteIds];
//		System.Test.startTest();
//		delete toDeleteList;
//		System.Test.stopTest();
		
//		String pqry = 'Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like \'%Executive\' and PortalType = \'Partner\' and PortalAccountId = \'';
//		List<UserRole> roles1 = Database.query(pqry + accts[1].Id + '\' limit 1');
//		//UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :a1.id limit 1];
//		UserRole uRole1 = roles1[0];
//		//UserRole uRole1 = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :accts[1].id limit 1];
//		Group gr1 = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole1.Id and Type = 'RoleAndSubordinates'];
//		Integer lshare = [Select count() from LeadShare where LeadId = :l.Id and UserOrGroupId = :gr1.Id];
//		System.assertEquals(0,lshare);
		
//		List<UserRole> roles2 = Database.query(pqry + accts[1].Id + '\' limit 1');
//		UserRole uRole2 = roles2[0];
//		//UserRole uRole2 = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :accts[1].id limit 1];
//		Group gr2 = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole2.Id and Type = 'RoleAndSubordinates'];
//		Integer oshare = [Select count() from OpportunityShare where OpportunityId = :opp.Id and UserOrGroupId = :gr2.Id];
//		System.assertEquals(0,oshare);
//	}
	
//	static testmethod void testOppLookup(){ 
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
//		User u1 = [select id from User where contact.accountid = :accts[1].id];
//		User u2 = [select id from User where contact.accountid = :auList[0]];
//		//Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
//		Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
//		opp.CloseDate = Date.today();
//		opp.Validation_Override__c=true;
//		PageReference pageRef = Page.ChangeOwner;
//		Test.setCurrentPage(pageRef);
//		System.runAs(u1){
//			insert opp;
//			System.currentPageReference().getParameters().put('id',opp.id);
//			PartnerUserLookupController testCon = new PartnerUserLookupController();
//			testCon.initLookupPage();
//			System.assertEquals(false, testCon.error);
//			testCon.getHasResults();
//			testCon.getRenderResultSets();
//			testCon.getResults();
//			testCon.save();
//			testCon.cancel();
//			testCon.getOppId();
//			PartnerUserLookupController testCon1 = new PartnerUserLookupController();
//			testCon1.initLookupPage();
//		}
//	}
	
//	static testmethod void testRemoveAccountAssociation(){
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
//		RecordAssociation__c r = new RecordAssociation__c();
//		RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[0].id, associated_account__c = accts[1].id, Account_Role__c = 'Partner');
//		Id assocId;
//		insert recAssoc1;
//		assocId = recAssoc1.Id;
//		r = [Select id from RecordAssociation__c where id = :assocId];
//		System.Test.startTest();
//		delete r;
//		System.Test.stopTest();
		
//		String pqry = 'Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like \'%Executive\' and PortalType = \'Partner\' and PortalAccountId = \'';
//		List<UserRole> roles1 = Database.query(pqry + accts[0].Id + '\' limit 1');
//		//UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :a1.id limit 1];
//		UserRole uRole1 = roles1[0];
//		//UserRole uRole1 = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :accts[0].id limit 1];
//		Group gr1 = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole1.Id and Type = 'RoleAndSubordinates'];
//		Integer ashare1 = [Select count() from AccountShare where AccountId = :accts[0].Id and UserOrGroupId = :gr1.Id];
//		System.assertEquals(0,ashare1);
//	}	
	
//	static testmethod void testAccountChangeParent(){
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size()-1;i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;		
//		accountUser newau = createAccountInfo(10);
		
//		Test.startTest();
		
//		Account acc1 = [select id, parentid from account where id = :newau.a.id];
//		Account acc2 = [select ParentId from account where id = :accts[1].id];
//		acc2.ParentId = acc1.id;
//		update acc2;
//		List<Id> grpIds = new List<Id>();
//		String pqry = 'Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like \'%Executive\' and PortalType = \'Partner\' and PortalAccountId = \'';
//		List<UserRole> roles1 = Database.query(pqry + acc1.Id + '\' limit 1');
//		//UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :a1.id limit 1];
//		UserRole uRole = roles1[0];
////		UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :acc1.id limit 1];
//		Group gr = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole.Id and Type = 'RoleAndSubordinates'];
//		grpIds.add(gr.Id);
//		Integer ashare = [Select count() from AccountShare where AccountId = :acc2.Id and UserOrGroupId in :grpIds];
//		Test.stopTest();
//		System.assertEquals(0,ashare);
//	}
	
//	static testmethod void testUpdateAccountInverseAssociation(){
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		PageReference pageRef = Page.manageAccountAssociation;
//		Test.setCurrentPage(pageRef);
//		List<RecordAssociation__c> rList = new List<RecordAssociation__c>();
//		RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[0].id, associated_account__c = accts[1].id, Account_Role__c = '', primary__c=true);
//		rList.add(recAssoc1);
//		insert rList;
//		RecordAssociation__c ra = [Select id from RecordAssociation__c where Account__c = :accts[0].id and associated_account__c= :accts[1].id];
//		ra.Account_Role__c = 'Partner';
//		ra.Primary__c = false;
//		//test scenario to update association and its inverse
//		update ra;
		
//		RecordAssociation__c ra1 = [Select id, Account_Role__c, Primary__c, Associated_Account__c, Account__c from RecordAssociation__c where Account__c = :accts[1].id and associated_account__c= :accts[0].id];
//		System.assertEquals(recAssoc1.Account__c, ra1.Associated_Account__c);
//		System.assertEquals(recAssoc1.Associated_Account__c, ra1.Account__c);
//		System.assertEquals(ra.Account_Role__c, ra1.Account_Role__c);
//		System.assertEquals(ra.Primary__c, ra1.Primary__c);
//	}
	
//	static testmethod void testLeadChangeOwner(){
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
		
//		User u1 = [select id from User where contact.accountid = :accts[0].id];
//		User u2 = [select id from User where contact.accountid = :accts[1].id];
		
//		//Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
//		Lead l = utilTestClass.CreateLead();
//		l.LastName = 'Lead2';
//		l.Company = 'Company';
//		l.Validation_Override__c=true;
//		System.runAs(u1){
//			insert l;			
//		} 
//		Object_Association__c objAssoc1 = new Object_Association__c(associated_account__c = accts[1].id, leadId__c = l.id);
//		insert objAssoc1;
//		Lead l1 = [Select OwnerId from Lead where lastname = 'Lead2'];
//		l1.OwnerId = u2.Id;
//		//update l1;
//	}
	
//	static testmethod void testOppChangeOwner(){
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
		
//		User u1 = [select id from User where contact.accountid = :accts[0].id];
//		User u2 = [select id from User where contact.accountid = :accts[1].id];
		
//		//Opportunity opp = new Opportunity( Name = 'Test Opp1', stagename = 'Prospecting', closedate = Date.today() );
//		Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
//		opp.CloseDate = Date.today();
//		opp.Validation_Override__c=true;
//		System.runAs(u1){
//			insert opp;
//		} 
//		Object_Association__c objAssoc2 = new Object_Association__c(associated_account__c = accts[0].id, OpportunityId__c = opp.id);
//		insert objAssoc2;
//		Opportunity opp1 = [Select OwnerId from Opportunity where id = :opp.id];
//		opp1.OwnerId = u2.Id;
//		update opp1;
//	}
	
//	static testmethod void testAddPreferred(){
//		List<Id> auList = new List<Id>();
//		/*for(Integer i=0;i<2;i++){
//			accountUser au = createAccountInfo(i);
//			auList.add(au.a.id);
//		}*/
//		auList.addall(createAccountInfoVersion2(2));
//		List<Account> accts = [select id, parentid from account where id in :auList];
//		for(Integer i=0; i<accts.size();i++){
//			if(i>0){
//				accts[i].ParentId = accts[i-1].id;
//			} 
//		}
//		update accts;
//		RecordAssociation__c recAssoc = new RecordAssociation__c(Account__c = accts[0].id, associated_account__c = accts[1].id, Account_Role__c = '', primary__c=true);
		
//		User u1 = [select id from User where contact.accountid = :accts[0].id];
		
//		//Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
//		Lead l = utilTestClass.CreateLead();
//		l.LastName = 'Lead2';
//		l.Company = 'Company';
//		l.Validation_Override__c=true;
//		//Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
//		Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
//		opp.CloseDate = Date.today();
//		opp.Validation_Override__c=true;
//		System.runAs(u1){
//			insert l;
//			insert opp;
//		} 		
//		PageReference pageRef = Page.addPreferred;
//		Test.setCurrentPage(pageRef);
//		System.currentPageReference().getParameters().put('leadId',l.id);
//		SelectAssociationOnRecordController testLeadAddPref = new  SelectAssociationOnRecordController();
//		testLeadAddPref.addPreferredAccountAssociation();
		
//		System.currentPageReference().getParameters().put('oppId',opp.id);
//		SelectAssociationOnRecordController testOppAddPref = new  SelectAssociationOnRecordController();
//		testOppAddPref.addPreferredAccountAssociation();
	//}
}