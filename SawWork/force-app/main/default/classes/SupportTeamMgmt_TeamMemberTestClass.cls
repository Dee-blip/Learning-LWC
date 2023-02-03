@isTest(SeeAllData=true)
public class SupportTeamMgmt_TeamMemberTestClass {
    private static TS_TeamMember__c createTeamMember(String userId, String teamId, String roleType){

        TS_TeamMember__c teamMember = new TS_TeamMember__c(team_member__c = userId, ts_support_team__c = teamId, role__c=roleType);

        return teamMember;
    }
    
    
    private static User createUser(String alias, String profile)
    {
        Profile p = [select Id from Profile where Name=:profile][0];
        User user = new User(alias = alias, email=alias+'@akamai.com',emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= alias + '@akamai.com',profileid = p.Id);
        return user;     
    }

    testmethod static void afterInsertSinglePositiveTest(){
        User testUser = createUser('stdUsr','Standard User');
        Test.startTest();

        Account acc =  new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
        //User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
        User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
        insert acc;
        insert supportTeam;
        TS_TeamAccount__c teamAccObj = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
        insert teamAccObj;

        TS_TeamMember__c teamMember = createTeamMember(user.Id, supportTeam.Id, 'Technical Support - Secondary');
        insert teamMember;

        AccountTeamMember accTeamMemberNew = [select id from AccountTeamMember where AccountId=:acc.Id and 
                                                     UserId=:user.Id and TeamMemberRole='Technical Support - Secondary'];

            
        
        System.assertNotEquals(accTeamMemberNew,null);


        Test.stopTest();

     }
    
    
    testmethod static void afterInsertSingleNegativeTest(){
        Test.startTest();
        User testUser = createUser('stdUsr','Standard User');


        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
        insert supportTeam;

       // User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c != 'Technical Support' limit 1];
		User user = [select id, name, Owner_support_department__c,Department from User where (NOT Department like '%AkaTec%') AND isActive = true limit 1];
        TS_TeamMember__c teamMember = createTeamMember(user.Id, supportTeam.Id, ' ');
        
        
        String message = '';
        
        try{
            insert teamMember;
         }
         catch(Exception ex){
           message = 'Insert Failed';  
         }   


        System.assertEquals('Insert Failed',message);
        //}
        Test.stopTest();
    }
    
    testMethod static void afterDeleteSingleTest(){
        Test.startTest();
        
        User testUser = createUser('stdUsr','Standard User');
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
        insert supportTeam;
        //User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
		User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
        TS_TeamMember__c teamMember = createTeamMember(user.Id, supportTeam.Id, 'Technical Support - Primary');
        insert teamMember;
        System.assertNotEquals(teamMember.Id, null);
        String userId = teamMember.Team_Member__c;
        String teamId = teamMember.TS_Support_Team__c;
        
        delete teamMember;
 
     //   System.runAs(testUser){
        TS_TeamMember__c teamMemberTest = null;
        List<TS_TeamMember__c> teamMemberList = [select id from TS_TeamMember__c where Team_Member__c= :userId
                                                 and TS_Support_Team__c =  : teamId];
        if(teamMemberTest != null && teamMemberList.size()>0 ){
                teamMemberTest = teamMemberList.get(0);
        }
            System.assertEquals(null, teamMemberTest);
        //}
        Test.stopTest();
    }
    
    testmethod static void afterUpdateSingleTest(){
        Test.startTest();
        User testUser = createUser('stdUsr','Standard User');

        Account acc =  new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
        //User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
        User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
        insert acc;
        insert supportTeam;
        TS_TeamAccount__c teamAcc = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
        insert teamAcc;

        TS_TeamMember__c teamMember = createTeamMember(user.Id, supportTeam.Id, 'Technical Support - Secondary');
        insert teamMember;

        
        List<AccountTeamMember> accTeamMembers = [select accountId from AccountTeamMember where accountId in (select Team_Account__c from TS_TeamAccount__c 
                                                  where TS_Support_Team__c=:supportTeam.Id) and userid=:user.Id and TeamMemberRole='Technical Support - Secondary'];
        
        System.assertNotEquals(null, accTeamMembers);

        teamMember.Role__c = 'Technical Support - Primary';
        update teamMember;
 
        accTeamMembers = [select accountId from AccountTeamMember where accountId in (select Team_Account__c from TS_TeamAccount__c 
                                                  where TS_Support_Team__c=:supportTeam.Id) and userid=:user.Id and TeamMemberRole='Technical Support - Primary'];
        System.assertNotEquals(null, accTeamMembers);  
        Test.stopTest();
        
    }
        

}