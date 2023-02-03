@isTest(SeeAllData=true)
private class SupportTeamTriggerTest
{
    testmethod static void beforeInsertSinglePositiveTest()
    {

        String teamName = 'testing support team insert';
        String teamType = 'Premium Media';
        Test.startTest();
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = teamName, Team_Type__c = teamType);
        insert supportTeam;
        System.assertNotEquals(supportTeam.Id, null);
        System.assertEquals(supportTeam.Team_Name__c,'testing support team insert');
        System.assertEquals(supportTeam.Team_Type__c,'Premium Media');
        Test.stopTest();

    }
    testmethod static void beforeUpdateSinglePositiveTest()
    {

        String teamName = 'testing support team insert';
        String teamType = 'Premium Media';
        Test.startTest();
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = teamName, Team_Type__c = teamType);
        insert supportTeam;
        System.assertNotEquals(supportTeam.Id, null);
        System.assertEquals(supportTeam.Team_Name__c,'testing support team insert');
        System.assertEquals(supportTeam.Team_Type__c,'Premium Media');

        teamType = 'Premium WebExp';
        supportTeam.Team_Type__c = teamType;
        update supportTeam;

        System.assertNotEquals(supportTeam.Id, null);
        System.assertEquals(supportTeam.Team_Name__c,'testing support team insert');
        System.assertEquals(supportTeam.Team_Type__c,'Premium WebExp');
        Test.stopTest();

    }
}