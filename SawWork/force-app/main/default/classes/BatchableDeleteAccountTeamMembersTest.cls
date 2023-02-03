/*
Author: Sonia Sawhney
Description: Contains test cases for BatchableDeleteAccountTeamMembers 
Created Date : 12/08/2013
Modification History:
Modified by ssawhney on 20/03/2014 to Remove the see all data from test class  
Modified by prathore on 20/12/2016 added method testScheduledDeleteAccountteamBatch() to cover scheduledDeleteAccountteamBatch class
*/
@isTest
private class BatchableDeleteAccountTeamMembersTest 
{ 
    static {
        utilTestClass.createCustomSettings();
    }
    static List <Account> accns;
    static list<AccountTeamMember> accTeam;
    static list<Account_team__c> accountTeam;
    
    static testMethod void testDeleteAccountTeam() 
    {
       LoadTestData();
 
       list<AccountteamMember> lstTeam = new  list<AccountteamMember>();
       integer i;
       for(i=0;i<100;i++)
       {
           lstTeam.add(accTeam[i]);
       }
       delete lstTeam;
       Test.StartTest();
       BatchableDeleteAccountTeamMembers  deleteAccountTeams = new BatchableDeleteAccountTeamMembers ();
       
        ID batchprocessid = Database.executeBatch(deleteAccountTeams ,200);
       Test.StopTest();
       System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM Account_Team__c WHERE Id IN :accountTeam '),
           100);  
   }
   
   static private void LoadTestData()
   {
      // Create 200 test accounts - this simulates one execute.  
      accns = new List<Account>();
      for(integer i = 0; i<200; i++){
         Account a = new Account(Name='testAccount'+i, 
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
      
      accountTeam =  new list<Account_Team__c>();
      for(AccountTeamMember team : accTeam)
      {
          Account_Team__c member = new Account_Team__c();
          member.Account__c = team.AccountId;
          member.User__c = team.UserId;   
          member.TeamMemberRole__c = team.TeamMemberRole;    
          member.AccountTeamId__c = team.Id; 
          accountTeam.add(member);
      }
      insert accountTeam;
   }
    static testMethod void testScheduledDeleteAccountteamBatch()
    { 
        Test.StartTest();
      scheduledDeleteAccountteamBatch s = new scheduledDeleteAccountteamBatch();
    String sch = '20 30 8 10 2 ?';
    String jobID = system.schedule('testScheduledDeleteAccountteamBatch', sch, s);
        Test.StopTest();
    } 
}