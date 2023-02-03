@isTest
public with sharing class TSSupportTeamExtensionTest {
	
	public static TS_Support_Team__c team1 = new TS_Support_Team__c();
	
	static testmethod void AddSupportTeam()
	{
		PageReference pageRef = Page.TSSupportTeamCreate;
		Test.setCurrentPage(pageRef);
		String teamName = 'Test Team1';
		team1.Team_Name__c = teamName;
		team1.Team_Type__c = 'Reseller';
		
		Apexpages.StandardController stdController = new Apexpages.StandardController(team1);	
		TSSupportTeamExtension stExt = new TSSupportTeamExtension(stdController);
		PageReference ref = stExt.save();
		TS_Support_Team__c[] teams = [select id, Name, Team_Name__c from TS_Support_Team__c];
		system.assertEquals(true, stExt.success);		
	}
	
	static testmethod void bulkInsert()
	{
		List<TS_Support_Team__c> teamList = new List<TS_Support_Team__c>();
		for(Integer i=0;i<2;i++)
		{
			TS_Support_Team__c team = new TS_Support_Team__c();
			team.Team_Name__c = 'Team ' + i;
			team.Team_Type__c = 'Premium Media';
			
			teamList.add(team);
		}
		test.startTest();
		//insert teamList;
		test.stopTest();
	}
}