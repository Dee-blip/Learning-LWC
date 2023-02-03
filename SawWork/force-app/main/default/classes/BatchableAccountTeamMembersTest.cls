/*
Author: Sonia Sawhney
Description: Contains test cases for BatchableAccountTeamMembers
Created Date : 07/08/2013 
Modification History:
Modified by ssawhney on 20/03/2014 to Remove the see all data from test class 
Modified by prathore on 20/12/2016 added method testscheduledAccountteamBatch() to cover scheduledAccountteamBatch class
*/
@isTest
private class BatchableAccountTeamMembersTest 
{ 
    static {
        utilTestClass.createCustomSettings();
    }
    static List <Account> accns;
    static list<AccountTeamMember> accTeam;
    static testMethod void testCreateAccountTeam() 
    {
       LoadTestData();
       set<string> teamIds = new set<string>();
       for(AccountTeamMember member : accTeam)
       {
           teamIds.add(member.Id);
       }
       Test.StartTest();
       BatchableAccountTeamMembers createUpdateAccountTeams = new BatchableAccountTeamMembers();
       
       ID batchprocessid = Database.executeBatch(createUpdateAccountTeams,200);
       Test.StopTest();
    
   }
   
   static private void LoadTestData()
   {
      // Create 200 test accounts - this simulates one execute.  
      accns = new List<Account>();
      for(integer i = 0; i<200; i++){
         Account a = new Account(Name='testAccountteam'+i, 
                     BillingCountry= 'India',BillingState = 'Delhi'); 
         accns.add(a);
      }  
      insert accns;  
      
      Profile pr = [select id from profile where name='Sales Operations'][0];

      User tmUser = new User(alias = 'tmUser1', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member1@akamai.com',profileid = pr.Id);
      insert tmUser;
      
      accTeam = new list<AccountTeamMember>();
      for(Account acc : accns)
      {
          AccountTeamMember member = new AccountTeamMember();
          member.AccountId = acc.Id;
          member.UserId = tmUser.Id;   
          member.TeamMemberRole = 'Cloud Security Architect';     
          accTeam.add(member);
      }
      insert accTeam;
   }
    static testMethod void testscheduledAccountteamBatch()
    { 
        Test.StartTest();
      scheduledAccountteamBatch s = new scheduledAccountteamBatch();
    String sch = '20 30 8 10 2 ?';
    String jobID = system.schedule('testscheduledAccountteamBatch', sch, s);
        Test.StopTest();
    }
}