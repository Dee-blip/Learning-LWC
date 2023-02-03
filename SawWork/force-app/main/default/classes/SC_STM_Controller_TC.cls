/*=====================================================================================================+
Class name          :   SC_STM_HomePageController
Author              :   Harshil Soni
Created             :   21-Jan-21
Purpose             :   This is the Test class for Support Team Management Controller

Last Modified Developer     			Purpose
============= ========================  =======
21-Jan-21     Harshil Soni 				ACD2-61
07-Jun-21	  Harshil Soni				ACD2-363 - Changing references to team types
+=====================================================================================================*/

@isTest
public class SC_STM_Controller_TC {
    
    //For Test Data Setup
    @testSetup static void datasetup(){
        
        //Creating all custom settings
        utilTestClass.createCustomSettings();
        
        Profile pr = [select id from profile where name='Support - Tech Support Agent'][0];
        
        //Creating Users
        List<User> userList = new List<User>();
        
        User usr1 = new User(alias = 'user1', email='member1@akamai.com',emailencodingkey='UTF-8', lastname='mem1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr1@akamai.com',profileid = pr.Id, ACD2_Support_Team_Skill__c = 'Enterprise', Owner_Support_Department__c = 'Technical Support',Department = 'AkaTec - Mgmt');
        userList.add(usr1);
        
        User usr2 = new User(alias = 'user2', email='member2@akamai.com',emailencodingkey='UTF-8', lastname='mem2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr2@akamai.com',profileid = pr.Id, ACD2_Support_Team_Skill__c = 'Media', Owner_Support_Department__c = 'Technical Support',Department = 'AkaTec - Mgmt');
        userList.add(usr2);
        
        Insert userList;
        
        //Inserting Account
        List<Account> accList = new List<Account>();
        Account accRec1 = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-ABC-1234',Type='Brand - Active', Support_Level__c = 'Plus', AKERC__c = '1234');
        accList.add(accRec1);
        Account accRec2 = new Account(Name='Test Account2',AKAM_Account_ID__c='Test-ABC-5678',Type='Brand - Active', Support_Level__c = 'Premium Enterprise', AKERC__c = '2468');
        accList.add(accRec2);
        Account accRec3 = new Account(Name='Test Account3',AKAM_Account_ID__c='Test-ABC-0123',Type='Brand - Active', Support_Level__c = 'Plus', AKERC__c = '3579');
        accList.add(accRec3);
        Account accRec4 = new Account(Name='Test Account4',AKAM_Account_ID__c='Test-ABC-9101',Type='Brand - Active', Support_Level__c = 'Plus', AKERC__c = '1234');
        accList.add(accRec4);
        Insert accList;
        
        //Inserting Support Team
        List<TS_Support_Team__c> teamList = new List<TS_Support_Team__c>();
        //ACD-363 - Changes by Harshil
        TS_Support_Team__c team1 = new TS_Support_Team__c(Team_Name__c = 'Test_Team', Team_Type__c = 'Geo-M WebExp');
        teamList.add(team1);
        TS_Support_Team__c team2 = new TS_Support_Team__c(Team_Name__c = 'Test_Team2', Team_Type__c = 'Reseller');
        teamList.add(team2);
		Insert teamList;
        
        //Inserting Team Account
        List<TS_TeamAccount__c> teamAccList = new List<TS_TeamAccount__c>();
        TS_TeamAccount__c acc1 = new TS_TeamAccount__c(TS_Support_Team__c = team1.id, Team_Account__c = accRec1.Id);
        teamAccList.add(acc1);
        TS_TeamAccount__c acc3 = new TS_TeamAccount__c(TS_Support_Team__c = team2.id, Team_Account__c = accRec3.id);
        teamAccList.add(acc3);
        Insert teamAccList;
        
        SC_STM_TriggerUtility.InsAccTeamMembers(New List<Id>{acc1.id});
        
        //Inserting Team Member
        List<TS_TeamMember__c> teamMemList = new List<TS_TeamMember__c>();
        TS_TeamMember__c mem1 = new TS_TeamMember__c(TS_Support_Team__c = team1.id, Team_Member__c = userList[0].id, Role__c = 'Technical Support - Primary');
        teamMemList.add(mem1);
        TS_TeamMember__c mem2 = new TS_TeamMember__c(TS_Support_Team__c = team1.id, Team_Member__c = userList[1].id, Role__c = 'Technical Support - Secondary');
        teamMemList.add(mem2);
        Insert teamMemList;
        SC_STM_TriggerUtility.InsAccTeamMembers(New List<Id>{mem1.id});
        
        mem2.TS_Support_Team__c = team2.id;
        
        Update mem2;
        
        Delete mem2;
        SC_STM_TriggerUtility.InsAccTeamMembers(New List<Id>{team2.id});
        
        try{
            TS_TeamAccount__c acc4 = new TS_TeamAccount__c(TS_Support_Team__c = team2.id, Team_Account__c = accRec4.id);
            Insert acc4;
        } catch (Exception e){
            System.Assert(e.getMessage().contains('Accounts that share an ERC must be assigned to the same support team'));
        }
        
        try{
            //ACD-363 - Changes by Harshil
            team2.team_type__c = 'Geo-P Enterprise';
            Update team2;
        } catch (Exception e){
            System.Assert(e.getMessage().contains('Team Type cannot be changed to Premium (Geo-P) because Support Team contains one OR more Non-Premium Accounts!'));
        }
        
        //Inserting Team Account after Team Member for coverage
        TS_TeamAccount__c acc2 = new TS_TeamAccount__c(TS_Support_Team__c = team1.id, Team_Account__c = accRec2.Id);
        Insert acc2;
        
    }
    
    @isTest
    static void Test_Lightning(){
        //Querying manager user
        User managerRec = [select id from user where isactive=true and profile.name='Support - Tech Support Manager' LIMIT 1][0];
        
        //Querying Test Users
        User userRec = [select id from user where username = '__usr1@akamai.com'][0];
        
        //Querying Support Team
        TS_Support_Team__c supportTeam= [select id from ts_support_team__c where team_name__c = 'Test_Team' LIMIT 1][0];
        
        //Querying Support Team Member
        TS_TeamMember__c teamMem = [select id, Role__c from ts_teammember__c where team_member__c = :userRec.id LIMIT 1][0];
        
        //Querying Support Team Account
        TS_TeamAccount__c teamAcc = [select id, TS_Support_Team__c, team_account_erc__c from ts_teamaccount__c where team_account_erc__c != '' limit 1][0];
        
        /*List<Account> accList1 = new List<Account>();
        Account accRec1 = new Account(Name='Test Account3',AKAM_Account_ID__c='Test-ABC-9101',Type='Brand - Active', Support_Level__c = 'Plus', AKERC__c = '1234');
        accList1.add(accRec1);
        Insert accList1;
        
        TS_Support_Team__c supportTeam2 = [select id, team_type__c from ts_support_team__c where team_name__c = 'Test_Team2' LIMIT 1][0];
        
        TS_TeamAccount__c acc3 = new TS_TeamAccount__c(TS_Support_Team__c = supportTeam2.id, Team_Account__c = accRec1.id);

        try{
            Insert acc3;
        } catch (Exception e){
            System.Assert(e.getMessage().contains('Accounts that share an ERC must be assigned to the same support team'));
        }
        
        try{
            supportTeam2.team_type__c = 'Premium Enterprise';
            Update supportTeam2;
        } catch (Exception e){
            System.Assert(e.getMessage().contains('Team Type cannot be changed to Premium because Support Team contains one OR more Premium Accounts!'));
        }*/
        
        
        Test.startTest();
            
        system.runAs(managerRec){
            String STMEmpList = SC_STM_HomePageController.getSupportTeamByEmployeeList();
        }
        
        String supportTeams = SC_STM_HomePageController.getSupportTeams(userRec.id);
        
        String getAccounts = SC_STM_HomePageController.getAssociatedAccounts(supportTeam.id);
        
        String updateSkill = SC_STM_HomePageController.saveSupportTeamSkill(userRec.id,'Media');
        
        String updateSkillErr = SC_STM_HomePageController.saveSupportTeamSkill(userRec.id,'Webex');
        
        String stmHome = SC_STM_HomePageController.getSupportTeamsHome();
        
        String teamDetails = SC_STM_HomePageController.getSupportTeamAccountsAndMembersHome(supportTeam.id);
        
        String modalDetails = SC_STM_HomePageController.getModalDetails('TS_TeamMember__c');
        
        String detailsByERC = SC_STM_HomePageController.getDetailsFromERC('1234');
        
        String deleteRecord = SC_STM_HomePageController.deleteSelectedRecord(teamAcc.id);
        
        SC_STM_TriggerUtility.InsAccTeamMembers(New List<Id>{teamAcc.TS_Support_Team__c});
        
        String deleteRecordErr = SC_STM_HomePageController.deleteSelectedRecord(supportTeam.id);
        
            
        Test.stopTest();
    }
}