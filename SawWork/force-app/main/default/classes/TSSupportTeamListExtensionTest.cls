@isTest(SeeAllData=false)
public with sharing class TSSupportTeamListExtensionTest {

	public static TS_Support_Team__c team1 = new TS_Support_Team__c();
	public static TS_Support_Team__c team2 = new TS_Support_Team__c();

	public static TS_TeamMember__c member1 = new TS_TeamMember__c();
	public static TS_TeamMember__c member2 = new TS_TeamMember__c();

	public static TS_TeamAccount__c acc1 = new TS_TeamAccount__c();
	public static TS_TeamAccount__c acc2 = new TS_TeamAccount__c();

	public static void initTeams()
	{
		team1.Team_Type__c = 'Premium Media';
		team1.Team_Name__c = 'Test Team 1';

		team2.Team_Type__c = 'Premium WebExp';
		team2.Team_Name__c = 'Test Team 2';

		insert team1;
		insert team2;
	}

	public static void initMembers()
	{
		User u1 = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1];
		member1.TS_Support_Team__c = team1.Id;
		member1.Team_Member__c = u1.Id;
		member1.Role__c = 'Technical Support - Primary';
		insert member1;
	}

	public static void initAccounts()
	{
		//Account a1 = [SELECT Id FROM Account WHERE Name='JPMorgan Chase & Co.' and Support_Level__c LIKE '%Premium%' LIMIT 1];
		Account a1 = new Account(Name='Test Account2',AKAM_Account_ID__c='Test-ABC-5678',Type='Brand - Active', Support_Level__c = 'Premium_2.0', AKERC__c = '2662');
		Insert a1;
        acc1.TS_Support_Team__c = team1.Id;
		acc1.Team_Account__c = a1.Id;
		insert acc1;
	}

	static testmethod void bulkInsertTeamAccounts()
	{
		initTeams();
        List<Account> accObjList = new List<Account>();
		//Account a1 = [SELECT Id FROM Account WHERE Name='JPMorgan Chase & Co.' and Support_Level__c LIKE '%Premium%' LIMIT 1];
		Account a1 = new Account(Name='Test Account3',AKAM_Account_ID__c='Test-ABC-0123',Type='Brand - Active', Support_Level__c = 'Premium_3.0', AKERC__c = '2442');
		accObjList.add(a1);
        //Account a2 = [SELECT Id FROM Account WHERE Name='CBS Interactive Inc.' LIMIT 1];
		Account a2 = new Account(Name='Test Account4',AKAM_Account_ID__c='Test-ABC-9101',Type='Brand - Active', Support_Level__c = 'Premium_2.0', AKERC__c = '2992');
        accObjList.add(a2);
        Insert accObjList;
        
		List<TS_TeamAccount__c> accList = new List<TS_TeamAccount__c>();
		TS_TeamAccount__c acct1 = new TS_TeamAccount__c();
		acct1.TS_Support_Team__c = team1.Id;
		acct1.Team_Account__c = a1.Id;
		accList.add(acct1);

		TS_TeamAccount__c acct2 = new TS_TeamAccount__c();
		acct2.TS_Support_Team__c = team2.Id;
		acct2.Team_Account__c = a2.Id;
		accList.add(acct2);

		test.startTest();
		insert accList;
		test.stopTest();
	}

	static testmethod void bulkInsertTeamMembers()
	{
		initTeams();
		User u1 = [SELECT Id FROM User WHERE alias='JACMACKE' LIMIT 1];

		List<TS_TeamMember__c> memList = new List<TS_TeamMember__c>();
		TS_TeamMember__c mem1 = new TS_TeamMember__c();
		mem1.TS_Support_Team__c = team1.Id;
		mem1.Team_Member__c = u1.Id;
		mem1.Role__c = 'Technical Support - Primary';
		memList.add(mem1);

		TS_TeamMember__c mem2 = new TS_TeamMember__c();
		mem2.TS_Support_Team__c = team2.Id;
		mem2.Team_Member__c = u1.Id;
		mem2.Role__c = 'Technical Support - Primary';
		memList.add(mem2);

		test.startTest();
		insert memList;
		test.stopTest();
	}

	static testmethod void testLinks()
	{
		PageReference pageRef = Page.TSSupportTeamsList;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('teamId', team1.id);
		Apexpages.StandardController stdController = new Apexpages.StandardController(team1);
		TSSupportTeamListExtension ext = new TSSupportTeamListExtension(stdController);
		ext.teamId = ApexPages.currentPage().getParameters().get('teamId');
		PageReference ref = ext.newTeam();
		System.assertEquals('/apex/TSSupportTeamCreate', ref.getUrl());
		ref = ext.newMember();
		System.assert(ref.getUrl().contains('/apex/TSTeamMemberCreate'));
		ref = ext.newAccount();
		System.assert(ref.getUrl().contains('/apex/TSTeamAccountCreate'));
	}

	static testmethod void testRefresh()
	{
		PageReference pageRef = new PageReference('/apex/TSTabset?sfdc.tabName=01rJ00000009RzP');
		Test.setCurrentPage(pageRef);
		Apexpages.StandardController stdController = new Apexpages.StandardController(team1);
		TSSupportTeamListExtension ext = new TSSupportTeamListExtension(stdController);
		PageReference ref = ext.refresh();
		System.assertEquals('/apex/TSTabset', ref.getUrl());
	}

	static testmethod void testGetTeamMembers()
	{
		initTeams();
		initMembers();
		PageReference pageRef = Page.TSSupportTeamsList;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('teamId', team1.id);
		Apexpages.StandardController stdController = new Apexpages.StandardController(team1);
		TSSupportTeamListExtension ext = new TSSupportTeamListExtension(stdController);

		initAccounts();
		ext.teamId = team1.Id;
		ext.getTeamMembersAndAccounts();
		System.assert(ext.accountList.size() > 0);
		System.assert(ext.userList.size() > 0);

		ext.getTeamMembers();
		System.assert(ext.userList.size() > 0);

		ext.updateTeamMembers();
		System.assert(ext.userList.size() > 0);

		ext.getTeamAccounts();
		System.assert(ext.accountList.size() > 0);

		ext.getTeamDetail();
		System.assert(ext.selectedTeamObjList != null);
		ext.toBeDelMember = member1.Id;
		ext.deleteMember();
		System.assert(ext.userList.size() == 0);

		ext.toBeDelAcc = acc1.Id;
		ext.deleteAcc();
		System.assert(ext.accountList.size() == 0);
	}

	static testmethod void testTSSupportSingleTeamExtension()
	{
		initTeams();
		initMembers();
		initAccounts();
		PageReference pageRef = Page.TS_Support_Team_Detail;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('teamId', team1.id);
		Apexpages.StandardController stdController = new Apexpages.StandardController(team1);
		TSSupportSingleTeamExtension ext = new TSSupportSingleTeamExtension(stdController);
		List<TS_Support_Team__c> support_teams = new List<TS_Support_Team__c>();
    Apexpages.StandardSetController stdSetController = new Apexpages.StandardSetController(support_teams);
		TSSupportTeamListExtension ext2 = new TSSupportTeamListExtension(stdSetController);

		PageReference ref = ext.newTeam();
		System.assertEquals('/apex/TSSupportTeamCreate', ref.getUrl());
		ref = ext.newMember();
		System.assert(ref.getUrl().contains('/apex/TSTeamMemberCreate'));
		ref = ext.newAccount();
		System.assert(ref.getUrl().contains('/apex/TSTeamAccountCreate'));
		System.assert(ext.accountList.size() > 0);
		System.assert(ext.userList.size() > 0);

		ext.toBeDelMember = member1.Id;
		ext.deleteMember();
		System.assert(ext.userList.size() == 0);

		ext.toBeDelAcc = acc1.Id;
		ext.deleteAcc();
		System.assert(ext.accountList.size() == 0);
	}

	static testmethod void testTeamMemberExtension() {
		PageReference pageRef = Page.TSTeamMemberCreate;
		Test.setCurrentPage(pageRef);
		User u = [SELECT Id, Name FROM User WHERE alias='JACMACKE' LIMIT 1];
		TS_TeamMember__c member = new TS_TeamMember__c();
		member.TS_Support_Team__c = team1.Name;
		member.Team_Member__c = u.Id;
		member.Role__c = 'Technical Support - Primary';
		Apexpages.StandardController stdController = new Apexpages.StandardController(member);
		TSTeamMemberExtension ext = new TSTeamMemberExtension(stdController);
		ext.save();
		List<PageMessages.PageMessage> msgList = PageMessages.getMessages();
		system.assert(msgList.size() < 1);

		pageRef = Page.TSTeamMemberCreate;
		Test.setCurrentPage(pageRef);
		ApexPages.currentPage().getParameters().put('act', 'New');
		TS_TeamMember__c testMem = new TS_TeamMember__c();
		testMem.TS_Support_Team__c = team1.Name;
		testMem.Team_Member__c = member.Team_Member__c;
		testMem.Role__c = 'Technical Support - Primary';
		Apexpages.StandardController stdController1 = new Apexpages.StandardController(testMem);
		TSTeamMemberExtension ext1 = new TSTeamMemberExtension(stdController1);
		ext1.save();
		msgList = PageMessages.getMessages();
		system.assertEquals(null, ext1.success);
		//system.assertEquals(1, msgList.size());
	}
}