@isTest
public class TSTeamAccountExtensionTest {
    public static TS_Support_Team__c team1 = new TS_Support_Team__c();
	public static TS_Support_Team__c team2 = new TS_Support_Team__c();
    
    public static void initTeams()
	{
		team1.Team_Type__c = 'Premium Media';
		team1.Team_Name__c = 'Test Team 1';

		team2.Team_Type__c = 'Premium WebExp';
		team2.Team_Name__c = 'Test Team 2';

		insert team1;
		insert team2;
	}
    
    static testmethod void testTeamAccountExtension()
	{
		initTeams();

		PageReference pageRef = Page.TSTeamAccountCreate;
		Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('teamId', team1.Id);
		//Account a = [SELECT Id FROM Account WHERE Name='Williams-Sonoma' LIMIT 1];
        Account a = new Account();
        a.Name = 'Test Account 1';
        a.Support_Level__c = 'Standard';
        insert a;
		TS_TeamAccount__c acc = new TS_TeamAccount__c();
		acc.TS_Support_Team__c = team1.Id;
		acc.Team_Account__c = a.Id;

		Apexpages.StandardController stdController = new Apexpages.StandardController(acc);
		TSTeamAccountExtension ext = new TSTeamAccountExtension(stdController);
		ext.save();
		List<Apexpages.Message> msgList = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgList){
	    	if (msg.getDetail().contains('You can only assign Premium accounts to a Premium Team')) b = true;
		}
		system.assert(b);

        PageReference pageRef1 = Page.TSTeamAccountCreate;
		Test.setCurrentPage(pageRef1);
        ApexPages.currentPage().getParameters().put('teamId', team1.Id);
		//Account ac = [SELECT Id FROM Account WHERE Name='JPMorgan Chase & Co.' and Support_Level__c LIKE '%Premium%' LIMIT 1];
		Account ac = new Account();
        ac.Name = 'Test Account 2';
        ac.Support_Level__c = 'Premium';
        insert ac;
        TS_TeamAccount__c ta = new TS_TeamAccount__c();
		ta.TS_Support_Team__c = team1.Id;
		ta.Team_Account__c = ac.Id;
        Apexpages.StandardController stdController1 = new Apexpages.StandardController(ta);
		TSTeamAccountExtension ext1 = new TSTeamAccountExtension(stdController1);
		ext1.save();
        system.assert(true, ext1.success);

        // Try to save again
        stdController1 = new Apexpages.StandardController(ta);
		ext1 = new TSTeamAccountExtension(stdController1);
        ext1.save();
        msgList = ApexPages.getMessages();
		b = false;
		for(Apexpages.Message msg:msgList){
	    	if (msg.getDetail().contains('This account is already associated with a support team')) b = true;
		}
		system.assert(b);

        // Test accounts with same ERC cannot be assigned to different support teams
        Account acc1 = new Account();
        acc1.Name = 'Test Account 3';
        acc1.AKERC__c = 'ABCD';
        acc1.Support_Level__c = 'Premium';
        insert acc1;
		TS_TeamAccount__c tacc = new TS_TeamAccount__c();
		tacc.TS_Support_Team__c = team1.Id;
		tacc.Team_Account__c = acc1.Id;
        Apexpages.StandardController stdController_tacc = new Apexpages.StandardController(tacc);
		TSTeamAccountExtension ext_tacc = new TSTeamAccountExtension(stdController_tacc);
        ext_tacc.save();
        system.assertEquals(true, ext_tacc.success);

        PageReference pageRef2 = Page.TSTeamAccountCreate;
		Test.setCurrentPage(pageRef2);
        ApexPages.currentPage().getParameters().put('teamId', team2.Id);
        Account acc2 = new Account();
        acc2.Name = 'Test Account 4';
        acc2.AKERC__c = 'BCCE';
        acc2.Support_Level__c = 'Premium';
        insert acc2;
        TS_TeamAccount__c tacc2 = new TS_TeamAccount__c();
		tacc2.TS_Support_Team__c = team2.Id;
		tacc2.Team_Account__c = acc2.Id;
        Apexpages.StandardController stdController_tacc2 = new Apexpages.StandardController(tacc2);
		TSTeamAccountExtension ext_tacc2 = new TSTeamAccountExtension(stdController_tacc2);
		ext_tacc2.save();
        List<Apexpages.Message> msgList3 = ApexPages.getMessages();
		boolean b2 = false;
		for(Apexpages.Message msg:msgList3){
	    	if (msg.getDetail().contains('Accounts that share an ERC must be assigned to the same support team.')) b2 = true;
		}
        // test error message is displayed
        system.assert(b2);
        system.assert(msgList3.size() > 0);
	}


}