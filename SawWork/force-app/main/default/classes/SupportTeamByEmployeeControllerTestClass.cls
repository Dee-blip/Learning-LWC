@isTest(SeeAllData=true)
private class SupportTeamByEmployeeControllerTestClass {
    
    
    
    private static User CreateUser(String alias, String profile)
    {
        Profile p = [select Id from Profile where Name=:profile][0];
        User user = new User(alias = alias, email=alias+'@akamai.com',emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= alias + '@akamai.com',profileid = p.Id,Department = 'AkaTec - Mgmt');
        return user;     
    }    
    private static TS_TeamMember__c createTeamMember(String userName, String team, String roleType){
        
        System.debug('support team Name '+team);
        User user = [select id from User where Name = :userName][0];
        TS_Support_Team__c supportTeam = [select id from TS_Support_Team__c where name=:team][0];
        TS_TeamMember__c teamMember = new TS_TeamMember__c(team_member__c = user.id, ts_support_team__c = supportTeam.id, role__c=roleType);
        
        return teamMember;  
    }
    
    private static User getUser(String username){
        User user = [select id,username, firstname, lastname, email, alias from User where Name = :username][0];
        return User;
    }
    
    testmethod static void getUserListTest(){
        Test.startTest();
        integer noSupportTeamsPrimary = 0; integer noSupportTeamsSecondary = 0; integer noSupportTeamsOthers = 0;
        integer noAccsPrimary = 0; integer noAccsSecondary;
        
        // User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
         User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
      Account acc =  new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
      TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
      insert acc;
      insert supportTeam;    
      TS_TeamAccount__c teamAccObj = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
      insert teamAccObj;

      TS_TeamMember__c supportTeamMember = new TS_TeamMember__c(Team_Member__c  = user.Id, TS_Support_Team__c = supportTeam.Id, Role__c='Technical Support - Primary');  
      insert supportTeamMember;

        List<AggregateResult> teamMembers = [SELECT count(team_member__c) teamCount, role__C from TS_TeamMember__c where team_member__c = :user.Id group by role__c];
        for(AggregateResult teamMember : teamMembers){
            String role = (String)teamMember.get('Role__c');
            integer teamCount = (integer)teamMember.get('teamCount');
            if(role.equals('Technical Support - Primary')){
                noSupportTeamsPrimary = noSupportTeamsPrimary + teamCount;
            }
            if(role.equals('Technical Support - Secondary')){
                noSupportTeamsSecondary = noSupportTeamsSecondary + teamCount;
            }
            if(role.equals('Technical Support - Other')){
                noSupportTeamsOthers = noSupportTeamsOthers + teamCount;
            }
        }  
        List<String> primarySupportIds = new List<String>();
        List<String> secondarySupportIds = new List<String>();
        
        List<TS_TeamMember__c> teamMemberList = [select TS_Support_team__c,Role__c from TS_TeamMember__c where Role__c in ('Technical Support - Primary','Technical Support - Secondary') and  Team_Member__c = :user.Id
                                                ];
        for(TS_TeamMember__c teamMember : teamMemberList){
           String role = teamMember.Role__c;
           String teamId = teamMember.TS_Support_team__c;
           if(role.equals('Technical Support - Primary')){
               primarySupportIds.add(teamId);
            }
            if(role.equals('Technical Support - Secondary')){
                secondarySupportIds.add(teamId);
            }
        }
        AggregateResult result = [SELECT COUNT(Team_Account__c) accCount from TS_TeamAccount__c where TS_Support_Team__c in :primarySupportIds];
        noAccsPrimary = (integer)result.get('accCount');
        
        AggregateResult result2 = [SELECT COUNT(Team_Account__c) accCount from TS_TeamAccount__c where TS_Support_Team__c in :secondarySupportIds];
        noAccsSecondary = (integer)result2.get('accCount');
        
        
        SupportTeamByEmployeeController supportTeamController = new SupportTeamByEmployeeController();
        supportTeamController.getUserList();
        Map<String,SupportEmployee>  userMap = supportTeamController.userMap;
        SupportEmployee supportEmployeeTest= userMap.get(user.Id);
        System.assertEquals(noAccsPrimary,supportEmployeeTest.getPrimaryAccCount());
        System.assertEquals(noAccsSecondary,supportEmployeeTest.getSecondaryAccCount());
        System.assertEquals(noSupportTeamsPrimary,supportEmployeeTest.getPrimarySupport());
        System.assertEquals(noSupportTeamsSecondary,supportEmployeeTest.getSecondarySupport());
        System.assertEquals(noSupportTeamsOthers,supportEmployeeTest.getOtherSupport());
        
        Test.stopTest();
        
    }   
}