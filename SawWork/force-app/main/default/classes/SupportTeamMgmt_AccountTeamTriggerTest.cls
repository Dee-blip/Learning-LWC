@isTest(SeeAllData=true)
private class SupportTeamMgmt_AccountTeamTriggerTest
{
    testmethod static void afterInsertSinglePositiveTest()
    {
        Test.startTest();
        
         // User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
         User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
        Account acc =  new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
          insert supportTeam;
      TS_TeamMember__c supportTeamMember = new TS_TeamMember__c(Team_Member__c  = user.Id, TS_Support_Team__c = supportTeam.Id, Role__c='Technical Support - Primary');
      insert acc;
      insert supportTeamMember;
        
        TS_TeamAccount__c teamAcc = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
        insert teamAcc;
        List<AccountTeamMember> accountTeamMember = [select id from AccountTeamMember where AccountId = :acc.Id and UserId 
                                              = :user.Id and TeamMemberRole = 'Technical Support - Primary'];
        
        System.assertNotEquals(null, accountTeamMember);
        Test.stopTest();
    }
    
    testmethod static void afterInsertSingleNegativeTest()
    {
        Test.startTest();
        
       // User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
        User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
        Account acc =  new Account(Name = '', Website = 'wwww.akamai.com');
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
        insert supportTeam;
        TS_TeamMember__c supportTeamMember = new TS_TeamMember__c(Team_Member__c  = user.Id, TS_Support_Team__c = supportTeam.Id, Role__c='Technical Support - Primary');         
        insert supportTeamMember;
        String exceptionMsg = '';
        try{
            insert acc;
            TS_TeamAccount__c teamAcc = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
            insert teamAcc;
            
        }    
        catch(Exception exe){
            exceptionMsg = 'Update Failed';
        }

        //List<AccountTeamMember> accountTeamMember = [select id from AccountTeamMember where AccountId = :acc.Id and UserId 
        //                                      = :user.Id and TeamMemberRole = 'Technical Support - Primary'];
        System.assertEquals(exceptionMsg, 'Update Failed');
        //System.assertEquals(0, accountTeamMember.size());
        Test.stopTest();

    }

    testmethod static void afterUpdateSingleUpdatePositiveTest(){
        Test.startTest();
        //User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
        User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
        Account acc = new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
        Account acc2 = new Account(Name = 'accountTwo test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
        insert supportTeam;
        TS_TeamMember__c supportTeamMember = new TS_TeamMember__c(Team_Member__c  = user.Id, TS_Support_Team__c = supportTeam.Id, Role__c='Technical Support - Primary');
        insert acc;
        insert acc2;
        
        insert supportTeamMember;
        
        TS_TeamAccount__c teamAcc = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
        insert teamAcc;
        List<AccountTeamMember> accountTeamMember = [select id from AccountTeamMember where AccountId = :acc.Id and UserId 
                                              = :user.Id and TeamMemberRole = 'Technical Support - Primary'];
        
        System.assertNotEquals(null, accountTeamMember);
        
        teamAcc.Team_Account__c = acc2.Id;
        update teamAcc;
        accountTeamMember = [select id from AccountTeamMember where AccountId = :acc2.Id and UserId 
                                              = :user.Id and TeamMemberRole = 'Technical Support - Primary'];
        System.assertNotEquals(null, accountTeamMember);
        Test.stopTest();
    }
    
    testmethod static void afterUpdateSingleUpdateNegativeTest(){
    Test.startTest();
        //User user = [select id, name, Owner_support_department__c from User where Owner_support_department__c = 'Technical Support' limit 1];
        User user = [select id, name, Owner_support_department__c,Department from User where Department like '%AkaTec%' AND isActive = true limit 1];
        Account acc = new Account(Name = 'account test insert', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0');
        Account acc2 = new Account(Name = '', Website = 'wwww.akamai.com');
        TS_Support_Team__c supportTeam = new TS_Support_Team__c(Team_Name__c = 'test support team', Team_Type__c  = 'Premium Media');
        insert supportTeam;
        TS_TeamMember__c supportTeamMember = new TS_TeamMember__c(Team_Member__c  = user.Id, TS_Support_Team__c = supportTeam.Id, Role__c='Technical Support - Primary');
        insert acc;
        
        insert supportTeamMember;
        
        TS_TeamAccount__c teamAcc = new TS_TeamAccount__c(Team_Account__c = acc.Id, TS_Support_Team__c = supportTeam.Id );
        insert teamAcc;
        List<AccountTeamMember> accountTeamMember = [select id from AccountTeamMember where AccountId = :acc.Id and UserId 
                                              = :user.Id and TeamMemberRole = 'Technical Support - Primary'];
        
        System.assertNotEquals(null, accountTeamMember);
        String exceptionMsg = '';
        try{
            insert acc2;
            teamAcc.Team_Account__c = acc2.Id;
            update teamAcc;
        }
        catch(Exception exe){
            exceptionMsg = 'Update Failed';
        }
            
        //accountTeamMember = [select id from AccountTeamMember where AccountId = :acc2.Id and UserId 
        //                                      = :user.Id and TeamMemberRole = 'Technical Support - Primary'];
        System.assertEquals(exceptionMsg, 'Update Failed');
        //System.assertEquals(0, accountTeamMember.size());
        Test.stopTest();
    }
}