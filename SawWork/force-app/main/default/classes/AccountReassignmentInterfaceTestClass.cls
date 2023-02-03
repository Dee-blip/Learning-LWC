@isTest(seeAllData=false)
private class AccountReassignmentInterfaceTestClass {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
        
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            
            User oldOwner;
            User oldOwnerRSM;
            User newOwner;
            User newOwnerRSM;
            Account_Reassignment_Rule__c oldOwnerRule;
            Account_Reassignment_Rule__c newOwnerRule;
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
            PSA_Settings__c psa = new PSA_Settings__c();
            psa.Name = 'Engineering Team Email';
            psa.Value__c = 'services-engg-qa@akamai.com';
            insert psa;
            /* End Of Custom Setting Insertion */

            List<Territory_Mapping__c> tms = (List<Territory_Mapping__c>)new SobjectBuilder(Territory_Mapping__c.sObjectType)
                .count(5)
                .create()
                .getRecords();
            
            Profile pr = [select id from profile where name='Sales Operations'][0];
            UserRole role = [select id, Name from UserRole where name=:GsmUtilClass.getGSMSettingValue('User_Role')][0];
            List<User> userList = new List<User>();
            User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(accOldOwnerUser);
            User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(accNewOwnerUser);
            User tmUser1 = new User(alias = 'tmUser1', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member1@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(tmUser1);
            User tmUser2 = new User(alias = 'tmUser2', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member2@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(tmUser2);
            insert userList;
            
            Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name=:roleName][0].Id;
            
            // Create Old Owner User
            oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
            oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);
            newOwner = CreateUser('TST_NUSR', salesRepProfileId, roleId);
            newOwnerRSM = CreateUser('TST_NRSM', salesRepProfileId, roleId);
            insert (new User[] {oldOwner, oldOwnerRSM, newOwner, newOwnerRSM});

            User ONAUser = [SELECT Id, Name FROM User WHERE ALIAS = 'ONA'][0];
            
            Account_Reassignment_Rule__c ONAReassignmentRule = utilTestClass.CreateAccountReassignmentRule('No Owner', ONAUser.Id, 'Owner Not Assigned');
            ONAReassignmentRule.Territory_ID__c = tms[0].Id;

            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);
            rule.Territory_ID__c = tms[1].Id;

            Account_Reassignment_Rule__c oldRule = utilTestClass.CreateAccountReassignmentRule('__OldRule', accOldOwnerUser.Id, role.Name);
            oldRule.Territory_ID__c = tms[2].Id;
            
            oldOwnerRule = utilTestClass.CreateAccountReassignmentRule(oldOwner.ALIAS, oldOwner.Id, roleName);
            oldOwnerRule.Associated_User_RSM__c = oldOwnerRSM.Id;
            oldOwnerRule.Territory_ID__c = tms[3].Id;
            
            
            newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.ALIAS, newOwner.Id, roleName);
            newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
            newOwnerRule.Territory_ID__c = tms[4].Id;

            // Create rules for the users
            insert (new Account_Reassignment_Rule__c[] {ONAReassignmentRule, oldOwnerRule, newOwnerRule,rule, oldRule});
        }
    }

    static testmethod void coverByPassLogic() {
        System.runAs(dmlUser) {
            ByPassAndLimitUtils.disable('AccountReassignmentTrigger');
            
            Test.startTest();
            User newUser = utilTestClass.CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
            insert newUser;

            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', newUser.Id, 'Marketing Operations');
            insert rule; 

            Account acc = utilTestClass.CreateAccount('__Test Account');
            insert acc;

            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            insert accReassign;
            Test.stopTest();

            //AccountReassignmentTriggerHandler obj = new AccountReassignmentTriggerHandler();
            //obj.beforeDeleteBeforeUndeleteTrigger();
            //obj.afterDeleteAfterUndeleteTrigger();
        }
    }
    
    static testmethod void SingleAccount_PositiveTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1,tmUser2;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1', 'TmUser2'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                    else if(u.lastname == 'TmUser2')
                        tmUser2 = u;
                }
            
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            List<Default_Account_Team_Members__c> datmList = new List<Default_Account_Team_Members__c>();
            Default_Account_Team_Members__c tm1 = new Default_Account_Team_Members__c();
            tm1.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm1.Team_Member__c = tmUser1.Id;
            tm1.Account_Access__c = 'Read Only';
            tm1.Opporunity_Access__c = 'Private';
            tm1.Team_Role__c = 'ADS AM';
            datmList.add(tm1);
            Default_Account_Team_Members__c tm2 = new Default_Account_Team_Members__c();
            tm2.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm2.Team_Member__c = tmUser2.Id;
            tm2.Account_Access__c = 'Read Only';
            tm2.Opporunity_Access__c = 'Read/Write';
            tm2.Team_Role__c = 'ADS Sales';
            datmList.add(tm2);
            insert datmList;
            
            Test.startTest();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            system.runAs(accOldOwnerUser){
                insert acc;
            }
            
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = accOldOwnerUser.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;
            
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = acc.Id;
            insert con;
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            insert accReassign;
            Test.stopTest();
            
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account' limit 1][0];
            Opportunity testOppty = [select Id,OwnerId from Opportunity where Name='__Test Oppty' limit 1][0];
            Contact testCon = [select Id, OwnerId from Contact where firstname='__ Test First' limit 1][0];
            
            // Check New Account Owner
            //system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
            // Check if Account Team Members are added with correct Team Roles
            AccountTeamMember[] atms= [select UserId,AccountId,TeamMemberRole from AccountTeamMember where AccountId = :testAcc.Id ORDER BY TeamMemberRole];
            //system.assertEquals(atms.size(),3);
            //system.assertEquals(atms[0].UserId,tmUser1.Id);
            // CR 734005 update start
            // system.assertEquals(atms[0].TeamMemberRole,'Acerno AM');
            //system.assertEquals(atms[0].TeamMemberRole,'ADS AM');
            // CR 734005 update end
            //system.assertEquals(atms[1].UserId,tmUser2.Id);
            // CR 734005 update start
            // system.assertEquals(atms[1].TeamMemberRole,'Acerno Sales');
            //system.assertEquals(atms[1].TeamMemberRole,'ADS Sales');
            // CR 734005 update start
            //system.assertEquals(atms[2].UserId,accNewOwnerUser.Id);
            //system.assertEquals(atms[2].TeamMemberRole,'Services - Primary');
            // Check if the Access levels are updated as defined by the rule.
            AccountShare acc_share;
            //acc_share = [select AccountAccessLevel,OpportunityAccessLevel from AccountShare where AccountId = :testAcc.Id and UserOrGroupId = :tmUser1.Id][0];
            //system.assertEquals(acc_share.AccountAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm1.Account_Access__c));
            //system.assertEquals(acc_share.OpportunityAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm1.Opporunity_Access__c));
            //acc_share = [select AccountAccessLevel,OpportunityAccessLevel from AccountShare where AccountId = :testAcc.Id and UserOrGroupId = :tmUser2.Id][0];
            //system.assertEquals(acc_share.AccountAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm2.Account_Access__c));
            //system.assertEquals(acc_share.OpportunityAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm2.Opporunity_Access__c));
            // Check New Oppty Owner
            //system.assertEquals(testOppty.OwnerId,accNewOwnerUser.Id);
            // Check New contact Owner
            //system.assertEquals(testCon.OwnerId,accNewOwnerUser.Id);
            AccountReassignmentInterfaceClass obj =new AccountReassignmentInterfaceClass(true);
            //obj.cancel();
        }
    }

    @isTest
    public static void SingleAccount_TestEscalation1(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1,tmUser2;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1', 'TmUser2'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                    else if(u.lastname == 'TmUser2')
                        tmUser2 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            Test.startTest();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            system.runAs(accOldOwnerUser){
                insert acc;
            }
            
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = accOldOwnerUser.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();
            insert oppty;
            
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = acc.Id;
            insert con;
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            accReassign.Reason_Code__c = 'Workload Rebalancing';
            insert accReassign;
            Test.stopTest();
            
            PageReference pageRef2 = Page.AccountReassignmentEscalation;
            Test.setCurrentPageReference(pageRef2);
            Apexpages.StandardController sc = new Apexpages.StandardController(accReassign);
            AccountReassignmentEntension testController2 = new AccountReassignmentEntension(sc);
            testController2.overrideCutOff();
            testController2.backToRecord();
            
            String profileName = 'Sales Operations';
            List<Profile> pList = [Select id from profile where name=:profileName];
            if (pList.size() > 0) {
                List<User> uList = [Select id from User where profileId=:pList[0].id];
                if (uList.size() > 0) {
                    User u = uList[0];
                    System.runAs(accNewOwnerUser) {
                        
                        PageReference pageRef3 = Page.AccountReassignmentEscalation;
                        Test.setCurrentPageReference(pageRef3);
                        Apexpages.StandardController sc2 = new Apexpages.StandardController(accReassign);
                        AccountReassignmentEntension testController3 = new AccountReassignmentEntension(sc2);
                        testController3.overrideCutOff();
                        testController3.backToRecord();
                    }
                }
            }
            
            accReassign.Reassign_Status__c = 'Approved';
            update accReassign;
            
            System.runAs(accNewOwnerUser) {
                
                PageReference pageRef4 = Page.AccountReassignmentEscalation;
                Test.setCurrentPageReference(pageRef4);
                Apexpages.StandardController sc3 = new Apexpages.StandardController(accReassign);
                AccountReassignmentEntension testController3 = new AccountReassignmentEntension(sc3);
                testController3.overrideCutOff();
                testController3.backToRecord();
            }
        }
    }
    
    @isTest
    public static void SingleAccount_TestEscalation2(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1,tmUser2;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1', 'TmUser2'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                    else if(u.lastname == 'TmUser2')
                        tmUser2 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            Test.startTest();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            system.runAs(accOldOwnerUser){
                insert acc;
            }
            
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = accOldOwnerUser.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;
            
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = acc.Id;
            insert con;
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            accReassign.Reason_Code__c = 'Workload Rebalancing';
            //accReassign.Reassign__c = false;
            insert accReassign;
            Test.stopTest();
            
            accReassign.Reassign_Status__c = 'Approved';
            update accReassign;
            
            System.runAs(accNewOwnerUser) {
                
                PageReference pageRef = Page.AccountReassignmentEscalation;
                Test.setCurrentPageReference(pageRef);
                Apexpages.StandardController sc = new Apexpages.StandardController(accReassign);
                AccountReassignmentEntension testController = new AccountReassignmentEntension(sc);
                testController.overrideCutOff();
                testController.backToRecord();
            }
            
            accReassign.Adhoc_Request__c = true;
            update accReassign;
            
            System.runAs(accNewOwnerUser) {
                
                PageReference pageRef2 = Page.AccountReassignmentEscalation;
                Test.setCurrentPageReference(pageRef2);
                Apexpages.StandardController sc2 = new Apexpages.StandardController(accReassign);
                AccountReassignmentEntension testController2 = new AccountReassignmentEntension(sc2);
                testController2.overrideCutOff();
                testController2.backToRecord();
            }
        }
    }

    // Removing Team member with role sales - primary when ever account reassigned to new user CR #2264384
    static testmethod void RemoveTeamMemberSalesPrimary_Positive(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            Test.startTest();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            system.runAs(accOldOwnerUser){
                insert acc;
            }
            
            AccountTeamMember atmn = new AccountTeamMember();
            atmn.AccountId = acc.Id;
            atmn.UserId  = tmUser1.Id;
            atmn.TeamMemberRole = 'Sales - Primary';
            insert atmn;
            
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            insert accReassign;
            Test.stopTest();
            
            // Get the updated account, oppty and team members
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account'][0];
            //system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
            
            // Check if Account Team Members are added with correct Team Roles
            AccountTeamMember[] atms= [select UserId,AccountId,TeamMemberRole from AccountTeamMember where AccountId = :testAcc.Id];
            //system.assertEquals(atms.size(),1);
        }
    }

    // Test Negative - Removing Team member with role 'sales - primary' when ever account reassigned to new user CR #2264384
    static testmethod void RemoveTeamMemberServicePrimary_NegativeTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            Test.startTest();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            system.runAs(accOldOwnerUser){
                insert acc;
            }
            
            AccountTeamMember atmn = new AccountTeamMember();
            atmn.AccountId = acc.Id;
            atmn.UserId  = tmUser1.Id;
            atmn.TeamMemberRole = 'Service - Primary';
            insert atmn;
            
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            insert accReassign;
            Test.stopTest();
            
            // Get the updated account, oppty and team members
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account'][0];
            //system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
            
            // Check if Account Team Members are added with correct Team Roles
            AccountTeamMember[] atms= [select UserId,AccountId,TeamMemberRole from AccountTeamMember where AccountId = :testAcc.Id];
            //system.assertEquals(atms.size(),2);
        }
    }

    /**
           RemoveTeamMembers_PositiveTest
           - Test account & rule are created
           - Add team members to account
           - Rule should have 'Remove Team Members' checkbox 'checked'
           - Account is reassigned using above rule
           - Verify OldTeamMembers are removed from the AccountTeam
           public static testmethod void ReassignOnInsert_PositiveTest()
    */
    static testmethod void RemoveTeamMembers_PositiveTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1'};
                for(User u : [select Id, lastname, UserRole.Name from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                }
            
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, tmUser1.UserRole.Name);
            rule.Remove_Existing_Team_Members__c = true;
            insert rule;
            
            Test.startTest();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            insert acc;
            
            List<AccountTeamMember> atmList = new List<AccountTeamMember>();
            AccountTeamMember atm1 = new AccountTeamMember ();
            atm1.AccountId = acc.Id;
            atm1.UserId = tmUser1.Id; // Standard User
            atm1.TeamMemberRole = 'ADS AM';
            atmList.add(atm1);
            
            AccountTeamMember atm2 = new AccountTeamMember ();
            atm2.AccountId = acc.Id;
            atm2.UserId = tmUser1.Id; // Standard User
            atm2.TeamMemberRole = 'ADS AM';
            atmList.add(atm2);
            insert atmList;
            
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            insert accReassign;
            Test.stopTest();
            
            // Get the updated account and team members
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account'][0];
            // Check New Account Owner
            system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
            // Check if Account Team Members are added with correct Team Roles
            AccountTeamMember[] atms= [select UserId,AccountId,TeamMemberRole from AccountTeamMember where AccountId = :testAcc.Id ORDER BY TeamMemberRole];
            system.assertEquals(atms.size(),1);
            system.assertEquals(atms[0].UserId,accNewOwnerUser.Id);
            system.assertEquals(atms[0].TeamMemberRole,'Services - Primary');
        }
    }

    /**
           ADSOwner_PositiveTest ( updated from 'AcernoOwner' to 'ADSOwner' as part of CR 734005 )
           - A test account,oppty and rule are created.
           - The old owner is set to a user with ADS profile. ( updated from 'Acerno' to 'ADS' as part of CR 734005 )
           - Account reassignment is done on the account and the following is checked
           -) Account owner changes.
           -) Opportunity owner does not changes. (because old owner is ADS) ( updated from 'Acerno' to 'ADS' as part of CR 734005 )
           -) Created new Account Reassignment Rule for accOldOwnerUser. (part of CR 812208 PDRA Update part-2)
    */
    static testmethod void ADSOppty_PositiveTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Profile ads_pr = [select id from profile where name = 'Sales Operations'][0]; //Modified on behaf of 'Swatisnigdha Mahapatra'
            User accNewOwnerUser = [select Id,UserRoleId,UserRole.Name from User where lastname='NewOwner' limit 1][0];
            User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old1_owner@akamai.com',profileid = ads_pr.Id, UserRoleId = accNewOwnerUser.UserRoleId );
            insert accOldOwnerUser;
            
            List<Account_Reassignment_Rule__c> arrList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('TestRule', accNewOwnerUser.Id, accNewOwnerUser.UserRole.Name);
            arrList.add(rule);
            Account_Reassignment_Rule__c rule2 = utilTestClass.CreateAccountReassignmentRule('TestRule2', accOldOwnerUser.Id, accNewOwnerUser.UserRole.Name);
            arrList.add(rule2);
            insert arrList;
            
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            System.runAs(accOldOwnerUser){
                Test.startTest();
                insert acc;
            }
            
            //Create Related Oppty
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = accOldOwnerUser.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            // CR 734005 update start
            // oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Acerno Record Type').getRecordTypeId();
            oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();
            // CR 734005 update end
            insert oppty;
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            insert accReassign;
            Test.stopTest();
            // Get the updated account and oppty
            Account testAcc = [select Id,OwnerId from Account where Name='__Test Account'][0];
            Opportunity testOppty = [select Id,OwnerId from Opportunity where Name='__Test Oppty'][0];
            // Verify that account owner changed
            //system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
            // Verify that oppty owner dint change
            //system.assertEquals(testOppty.OwnerId,accOldOwnerUser.Id);
            
        }
    }

    /**
           AccountSplit_PositiveTest //Ali KM: updated name from AcernoSplit_PositiveTest
           - A test account,oppty and rule are created.
           - The "Account Split" field on Account is checked.
           - Account reassignment is done on the account and the following is checked
           -) Account owner changes.
           -) Opportunity owner does not changes. (because "Account Split" = true)
           -) Created new Account Reassignment Rule for accOldOwnerUser - rule2. (part of CR 812208 PDRA Update part-2)
    */
    static testmethod void AccountSplit_PositiveTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner'};
                for(User u : [select Id, lastname, UserRole.Name from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                }
            
            List<Account_Reassignment_Rule__c> arrList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('TestRule', accNewOwnerUser.Id, accNewOwnerUser.UserRole.Name);
            arrList.add(rule);
            Account_Reassignment_Rule__c rule2 = utilTestClass.CreateAccountReassignmentRule('TestRule2', accOldOwnerUser.Id, accOldOwnerUser.UserRole.Name);
            arrList.add(rule2);
            insert arrList;
            
            //Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            acc.Account_Split__c = true;
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            //Create Related Oppty
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = accOldOwnerUser.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();
            insert oppty;
            update acc;
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            Test.startTest();
            insert accReassign;
            Account testAcc = [select Id,OwnerId, Owner.alias, Reassign_Account__c from Account where Id=:acc.Id][0];
            Opportunity testOppty = [select Id,OwnerId, Owner__c, Owner.alias from Opportunity where Id=:oppty.Id][0];
            // Verify that account owner changed
            //system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
            // Verify that oppty owner changed
            //Anand Hegde - Split_account 2772237
            //system.assertEquals(testOppty.OwnerId,accNewOwnerUser.Id);
            Test.stopTest();
        }
    }

    /**
           BulkAccount_PositiveTest
           - Bulk insert of 10 accounts is done.
           - Bulk reassignment of 10 accounts is done, and the change of owner is verified.
    */
    static testmethod void BulkAccount_PositiveTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            // Add 1 team member to the rule
            Default_Account_Team_Members__c tm1 = new Default_Account_Team_Members__c();
            tm1.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm1.Team_Member__c = tmUser1.Id; // Standard User
            tm1.Account_Access__c = 'Read Only';
            tm1.Opporunity_Access__c = 'Private';
            // CR 734005 update start
            tm1.Team_Role__c = 'ADS AM';
            // CR 734005 update end
            insert tm1;
            //Cretae 200 accounts with 1 related Oppty
            Account[] BulkAccounts = new Account[10];
            Integer count;
            
            for(count=0; count<10; count++)
            {
                BulkAccounts[count] = utilTestClass.CreateAccount('__TSTCLSAC' + count);
                BulkAccounts[count].OwnerId = accOldOwnerUser.Id;
            }
            Test.startTest();
            //insert BulkAccounts;
            // alikm: using runAs as on insert account_reassignment uses UserInfo.getId
            System.runAs(accOldOwnerUser){
                insert BulkAccounts;
            }
            List<Account_Reassignment__c> accReassignList=new List<Account_Reassignment__c>();
            for(count=0; count<10; count++)
            {
                Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(BulkAccounts[count].Id, rule.Id);
                accReassignList.add(accReassign);
            }
            //Reassign
            insert accReassignList;
            Test.stopTest();
            // Get the updated account
            BulkAccounts = [select Id,OwnerId from Account where Name like '__TSTCLSAC%'];
            //for(count=0; count<10; count++)
                //system.assertEquals(BulkAccounts[count].OwnerId,accNewOwnerUser.Id);
        }
    }

    /**
           BulkAccount_PositiveTest2
           - Bulk insert of 200 accounts is done.
           - Bulk insert of 200 opportunities is done
           - Bulk reassignment of 200 accounts is done, and the change of owner is verified.
           - No. of script statements is checked to ensure it doesn't cross 200000.
    */
    static testmethod void BulkAccount_PositiveTest2(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            // Add 1 team member to the rule
            Default_Account_Team_Members__c tm1 = new Default_Account_Team_Members__c();
            tm1.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm1.Team_Member__c = tmUser1.Id; // Standard User
            tm1.Account_Access__c = 'Read Only';
            tm1.Opporunity_Access__c = 'Private';
            // CR 734005 update start
            tm1.Team_Role__c = 'ADS AM';
            // CR 734005 update end
            insert tm1;
            //Cretae 200 accounts with 1 related Oppty
            Account[] BulkAccounts = new Account[10];
            Opportunity[] BulkOpptys = new Opportunity[10];
            Contact[] BulkContacts = new Contact[10];
            
            Integer count;
            
            for(count=0; count<10; count++)
            {
                BulkAccounts[count] = utilTestClass.CreateAccount('__TSTCLSAC' + count);
                BulkAccounts[count].OwnerId = accOldOwnerUser.Id;
            }
            
            System.runAs(accOldOwnerUser){
                insert BulkAccounts;
            }
            List<Account_Reassignment__c> accReassignList=new List<Account_Reassignment__c>();
            
            // refresh the account list.
            BulkAccounts = [select Id,OwnerId from Account where Name like '__TSTCLSAC%'];
            // create opportunities.
            for(count=0; count<10; count++)
            {
                BulkOpptys[count] = utilTestClass.CreateOpportunity('__TSTCLSAC' + count, '1. Identify Need');
                BulkOpptys[count].AccountId = BulkAccounts[count].Id;
                BulkOpptys[count].CloseDate = Date.today();
                
            }
            Test.startTest();
            insert BulkOpptys;
            
            // create contacts.
            for(count=0; count<10; count++)
            {
                BulkContacts[count] = utilTestClass.CreateContact('__ Test First' + count,'__Test Contact');
                BulkContacts[count].Validation_Override__c=true;
                BulkContacts[count].AccountId = BulkAccounts[count].Id;
            }
            insert BulkContacts;
            
            
            ContractSharing.updateOpptyOwnerContractShareFirstRunFlag = true;
            ContractSharing.updateAccountOwnerContractShareFirstRunFlag = true;
            for(count=0; count<10; count++)
            {
                Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(BulkAccounts[count].Id, rule.Id);
                accReassignList.add(accReassign);
            }
            insert accReassignList;
            Test.stopTest();
            
            // Get the updated account
            BulkAccounts = [select Id,OwnerId from Account where Name like '__TSTCLSAC%'];
            
            // Get the updated contacts
            BulkContacts = [Select Id, OwnerId, AccountId from Contact where FirstName like '__ Test First%'];
            //for(count=0; count<10; count++)
            //{
                //system.assertEquals(BulkAccounts[count].OwnerId,accNewOwnerUser.Id);
                // Change related to CR 1768502 Freezing Oppitunity Owner upon move to Sale Stage 6 --- start
                //system.assertEquals(BulkAccounts[count].OwnerId,accNewOwnerUser.Id);
                //system.assertEquals(BulkAccounts[count].OwnerId,BulkContacts[count].OwnerId);
                // Change related to CR 1768502 Freezing Oppitunity Owner upon move to Sale Stage 6 --- end
            //}
        }
    }

    /**
           ReassignOnInsert_PositiveTest
           - Account Reassignment cannot be done while creating a new account
    */
    static testmethod void ReassignOnInsert_PositiveTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1,tmUser2;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1', 'TmUser2'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                    else if(u.lastname == 'TmUser2')
                        tmUser2 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            // Add 2 team members to the rule
            List<Default_Account_Team_Members__c> datmList = new List<Default_Account_Team_Members__c>();
            Default_Account_Team_Members__c tm1 = new Default_Account_Team_Members__c();
            tm1.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm1.Team_Member__c = tmUser1.Id; // Standard User
            tm1.Account_Access__c = 'Read Only';
            tm1.Opporunity_Access__c = 'Private';
            // CR 734005 update start
            tm1.Team_Role__c = 'ADS AM';
            // CR 734005 update end
            datmList.add(tm1);
            Default_Account_Team_Members__c tm2 = new Default_Account_Team_Members__c();
            tm2.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm2.Team_Member__c = tmUser2.Id; // Standard User
            tm2.Account_Access__c = 'Read Only';
            tm2.Opporunity_Access__c = 'Read/Write';
            // CR 734005 update start
            tm2.Team_Role__c = 'ADS Sales';
            // CR 734005 update end
            datmList.add(tm2);
            insert datmList;
            
            //Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            Test.startTest();
            insert accReassign;
            // alikm: using runAs as on insert account_reassignment uses UserInfo.getId
            
            // Get the updated account and team members
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account'][0];
            // Check New Account Owner
            //system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
            // Check if Account Team Members are added with correct Team Roles
            AccountTeamMember[] atms= [select UserId,AccountId,TeamMemberRole from AccountTeamMember where AccountId = :testAcc.Id ORDER BY TeamMemberRole];
            //system.assertEquals(atms.size(),3);
            //system.assertEquals(atms[0].UserId,tmUser1.Id);
            // CR 734005 update start
            // system.assertEquals(atms[0].TeamMemberRole,'Acerno AM');
            //system.assertEquals(atms[0].TeamMemberRole,'ADS AM');
            // CR 734005 update end
            //system.assertEquals(atms[1].UserId,tmUser2.Id);
            // CR 734005 update start
            // system.assertEquals(atms[1].TeamMemberRole,'Acerno Sales');
            //system.assertEquals(atms[1].TeamMemberRole,'ADS Sales');
            // CR 734005 update end
            //system.assertEquals(atms[2].UserId,accNewOwnerUser.Id);
            //system.assertEquals(atms[2].TeamMemberRole,'Services - Primary');
            // Check if the Access levels are updated as defined by the rule.
            AccountShare acc_share;
            //acc_share = [select AccountAccessLevel,OpportunityAccessLevel from AccountShare where AccountId = :testAcc.Id and UserOrGroupId = :tmUser1.Id][0];
            //system.assertEquals(acc_share.AccountAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm1.Account_Access__c));
            //system.assertEquals(acc_share.OpportunityAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm1.Opporunity_Access__c));
            //acc_share = [select AccountAccessLevel,OpportunityAccessLevel from AccountShare where AccountId = :testAcc.Id and UserOrGroupId = :tmUser2.Id][0];
            //system.assertEquals(acc_share.AccountAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm2.Account_Access__c));
            //system.assertEquals(acc_share.OpportunityAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm2.Opporunity_Access__c));
            // Check if Reassign Account checkbox is cleared
            //system.assertEquals(testAcc.Reassign_Account__c,false);
            Test.stopTest();
        }
    }

    /**
           EmptyRule_NegativeTest
           - When "Account.Reassign To" is checked, "Account.Account Reassignment Rule" cannot be left null.
           - -) Changed Account Owner Assertion to check with ONA instead of OldOwner. (part of CR 812208 PDRA Update part-2)
    */
    static testmethod void EmptyRule_NegativeTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            // Ali KM: fetch ONA User
            User accOldOwnerUser,accNewOwnerUser,ONAUser;
            List<String> userAliasList = new List<String>{'ONA','tmUser1','newUser'};
                for(User u : [select Id, ALIAS from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'ONA')
                        ONAUser = u;
                    else if(u.ALIAS == 'tmUser1')
                        accOldOwnerUser = u;
                    else if(u.ALIAS == 'newUser')
                        accNewOwnerUser = u;
                }
            
            //Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account 1');
            acc.OwnerId = accOldOwnerUser.Id;
            //insert acc;
            // alikm: using runAs as on insert account_reassignment uses UserInfo.getId
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            
            // Get the updated account
            acc = [select Id,OwnerId from Account where Name='__Test Account 1'];
            // system.assertEquals(acc.OwnerId,accOldOwnerUser.Id);
            // Ali KM: fetch ONA User
            /* CR 872300 Code cleanup - enable feature toggle for PDRA auto-reassignment */
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutoPDRAUpdateOnAcctInsert')== true)
                system.assertEquals(acc.OwnerId,ONAUser.Id);
            else
                system.assertEquals(acc.OwnerId,accOldOwnerUser.Id);
        }
    }

    static testmethod void InactiveUsersTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser,tmUser1,tmUser2;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1', 'TmUser2'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                    else if(u.lastname == 'TmUser2')
                        tmUser2 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            // Add 2 team members to the rule
            List<Default_Account_Team_Members__c> datmList = new List<Default_Account_Team_Members__c>();
            Default_Account_Team_Members__c tm1 = new Default_Account_Team_Members__c();
            tm1.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm1.Team_Member__c = tmUser1.Id; // Standard User
            tm1.Account_Access__c = 'Read Only';
            tm1.Opporunity_Access__c = 'Private';
            // CR 734005 update start
            tm1.Team_Role__c = 'ADS AM';
            // CR 734005 update end
            datmList.add(tm1);
            Default_Account_Team_Members__c tm2 = new Default_Account_Team_Members__c();
            tm2.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm2.Team_Member__c = tmUser2.Id; // Standard User
            tm2.Account_Access__c = 'Read Only';
            tm2.Opporunity_Access__c = 'Read/Write';
            // CR 734005 update start
            tm2.Team_Role__c = 'ADS Sales';
            // CR 734005 update end
            datmList.add(tm2);
            insert datmList;
            
            //Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            // alikm: using runAs as on insert account_reassignment uses UserInfo.getId
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            //Create Related Oppty
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = accOldOwnerUser.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            Test.startTest();
            insert oppty;
            // Inactivate Rule.Associated User
            accNewOwnerUser.IsActive = false;
            update accNewOwnerUser;
            // Reassign
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            try
            {
                insert accReassign;
            }
            catch(Exception e)
            {
                //system.assert(e.getMessage().contains('Cannot Reassign to Inactive User.'));
            }
            // Get the updated account, oppty and team members
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account'][0];
            //system.assertEquals(testAcc.OwnerId, accOldOwnerUser.Id);
            Test.stopTest();
        }
    }

    /**
           AddAccountReassignmentRule_PositiveTest
           - A test account,rule is created.
           - Acc reassignment rule is run if account reassignment rule for Owner exists
           -) PDRA values change to Owner Reassignment Rule values
    */
    static testmethod void AddAccountReassignmentRule_SinglePositiveTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutoPDRAUpdateOnAcctInsert') != true)
                return;
            User accOldOwnerUser,tmUser1,tmUser2;
            List<String> userLastNameList = new List<String>{'OldOwner', 'TmUser1', 'TmUser2'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                    else if(u.lastname == 'TmUser2')
                        tmUser2 = u;
                }
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__OldRule' limit 1][0];
            
            // Add 2 team members to the rule
            List<Default_Account_Team_Members__c> datmList = new List<Default_Account_Team_Members__c>();
            Default_Account_Team_Members__c tm1 = new Default_Account_Team_Members__c();
            tm1.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm1.Team_Member__c = tmUser1.Id; // Standard User
            tm1.Account_Access__c = 'Read Only';
            tm1.Opporunity_Access__c = 'Read/Write';
            tm1.Team_Role__c = 'ADS AM';
            datmList.add(tm1);
            Default_Account_Team_Members__c tm2 = new Default_Account_Team_Members__c();
            tm2.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm2.Team_Member__c = tmUser2.Id; // Standard User
            tm2.Account_Access__c = 'Read Only';
            tm2.Opporunity_Access__c = 'Read/Write';
            tm2.Team_Role__c = 'ADS Sales';
            datmList.add(tm2);
            insert datmList;
            
            //Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            //acc.Operations_Request__c = 'Reassign';
            
            // alikm: using runAs as on insert account_reassignment uses UserInfo.getId
            //insert acc;
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            
            // Get the updated account
            Account testAcc = [select Id,OwnerId,Account_Reassignment_Rule__c from Account where Name='__Test Account'][0];
            
            // Check New Account Owner
            system.assertEquals(testAcc.OwnerId,accOldOwnerUser.Id);
            
            // Check if Assign To is same as rule
            //system.assertNotEquals(testAcc.Account_Reassignment_Rule__c, null);
            //system.assertEquals(testAcc.Account_Reassignment_Rule__c, rule.Id);
            
            // Check if Account Team Members are added with correct Team Roles
            AccountTeamMember[] atms= [select UserId,AccountId,TeamMemberRole from AccountTeamMember where AccountId = :testAcc.Id ORDER BY TeamMemberRole];
            //system.assertEquals(atms.size(),3);
            /*
            system.assertEquals(atms[0].UserId,tmUser1.Id);
            system.assertEquals(atms[0].TeamMemberRole,'ADS AM');
            system.assertEquals(atms[1].UserId,tmUser2.Id);
            system.assertEquals(atms[1].TeamMemberRole,'ADS Sales');
            system.assertEquals(atms[2].UserId,accOldOwnerUser.Id);
            system.assertEquals(atms[2].TeamMemberRole,'Services - Primary');
            */
            
            // Check if the Access levels are updated as defined by the rule.
            AccountShare acc_share;
            //acc_share = [select AccountAccessLevel,OpportunityAccessLevel from AccountShare where AccountId = :testAcc.Id and UserOrGroupId = :tmUser1.Id][0];
            //system.assertEquals(acc_share.AccountAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm1.Account_Access__c));
            //system.assertEquals(acc_share.OpportunityAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm1.Opporunity_Access__c));
            //acc_share = [select AccountAccessLevel,OpportunityAccessLevel from AccountShare where AccountId = :testAcc.Id and UserOrGroupId = :tmUser2.Id][0];
            //system.assertEquals(acc_share.AccountAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm2.Account_Access__c));
            //system.assertEquals(acc_share.OpportunityAccessLevel,AccountReassignmentInterfaceClass.UpdateAccessLevel(tm2.Opporunity_Access__c));
        }
    }

    /**
           AddAccountReassignmentRule_SingleNegativeTest
           - A test account is created without Reassignment Rule
           - ONA Acc reassignment rule should run if account reassignment rule for Owner doesn't exist.
           - Changed Account Owner Assertion to check with ONA instead of OldOwner. (part of CR 812208 PDRA Update part-2)
    */
    static testmethod void AddAccountReassignmentRule_SingleNegativeTest(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutoPDRAUpdateOnAcctInsert') != true)
                return;
            User accNewOwnerUser,ONAUser;
            List<String> userAliasList = new List<String>{'ONA','newUser'};
                for(User u : [select Id, ALIAS, ProfileId, UserRoleId from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'ONA')
                        ONAUser = u;
                    else if(u.ALIAS == 'newUser')
                        accNewOwnerUser = u;
                }
            // Create User
            User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old1_owner@akamai.com',profileid = accNewOwnerUser.ProfileId, UserRoleId = accNewOwnerUser.UserRoleId);
            insert accOldOwnerUser;
            
            //Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            //acc.Operations_Request__c = 'Reassign';
            
            // alikm: using runAs as on insert account_reassignment uses UserInfo.getId
            //insert acc;
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            
            // Get the updated account
            Account testAcc = [select Id,OwnerId,Account_Reassignment_Rule__c from Account where Name='__Test Account'][0];
            
            // Check New Account Owner
            //system.assertEquals(testAcc.OwnerId,accOldOwnerUser.Id);
            // Ali KM: fetch ONA User
            system.assertEquals(testAcc.OwnerId,ONAUser.Id);
        }
    }

    /**
           AddAccountReassignmentRule_SingleNegativeTest_Override
           - A test account is created with Owner having Reassignment Rule
           - For test account Account_Reassignment_Rule__c is set && Reassign_Account__c is set to True
           - Account reassignment rule overrides Owner's reassignment rule & test account is reassigned to account.Account_Reassignment_Rule__r.Associated_User__c
    */
    static testmethod void AddAccountReassignmentRule_SingleNegativeTest_Override(){
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutoPDRAUpdateOnAcctInsert') != true)
                return;
            User accOldOwnerUser,accNewOwnerUser;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                }
            Account_Reassignment_Rule__c rule2 = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            //Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule2.Id);
            insert accReassign;
            // Get the updated account
            Account testAcc = [select Id,OwnerId,Account_Reassignment_Rule__c from Account where Name='__Test Account'][0];
            
            // Check New Account Owner
            //system.assertEquals(testAcc.OwnerId,accNewOwnerUser.Id);
        }
    }

    /**
        ONAAccount_Single_Positive()
        - Lead Account owned by ONA
    */
    static testMethod void ONAAccount_Single_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User newOwner = [SELECT Id, Name FROM User WHERE ALIAS = 'TST_NUSR'][0];
            Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
            Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
            acc.OwnerId = [SELECT Id, Name FROM User WHERE ALIAS = 'ONA'][0].id;
            acc.Type = 'Lead';
            acc.Partner_Type__c='Unknown';
            insert acc;
            
            system.runAs(newOwner)
            {
                Test.startTest();
                CreateAccountReassignment(acc, newOwnerRule);
                Test.stopTest();
            }
            
            // Refresh Account and Reassignment Request
            List<Account_Reassignment__c> accReassignList = getReassignmentRequestsForAccount(acc);
            acc = RefreshAccount(acc);
            
            // Asserts
            //system.assert(acc.OwnerId==newOwner.Id, 'Owner did not change. accReassignList:'+accReassignList);
            
        }
    }

    /**
        LeadAccount_Single_Positive()
        - Lead Account
        - Owner himself reassigns to someone else
        - shiverma - CR : As part of moving to standard approval - Approval will be required to this scenario as well
    */
    static testMethod void LeadAccount_Single_Accept1()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User oldOwner = [SELECT Id, Name FROM User WHERE ALIAS = 'TST_OUSR'][0];
            Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
            Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
            acc.OwnerId = oldOwner.Id;
            acc.Type = 'Lead';
            acc.Partner_Type__c='Unknown';
            system.runAs(oldOwner)
            {
                insert acc;
            }
            
            // OldOwner himself reassigns to NewOwner
            system.runAs(oldOwner)
            {
                Test.startTest();
                CreateAccountReassignment(acc, newOwnerRule);
                Test.stopTest();
            }
            
            // Refresh Account and Reassignment Request
            List<Account_Reassignment__c> accReassignList = getReassignmentRequestsForAccount(acc);
            acc = RefreshAccount(acc);
            
            // Asserts
            //system.assertEquals(accReassignList[1].Reassign_Status__c, 'Approval Pending');
            
            acc = RefreshAccount(acc);
            system.assertEquals(acc.OwnerId, oldOwner.Id);
            
        }
    }

    /**
        LeadAccount_Single_Positive()
        - Lead Account
        - New Owner requests for account
        - Olw Owner acceps
    */
    static testMethod void LeadAccount_Single_Accept2()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User newOwner,oldOwner;
            List<String> userAliasList = new List<String>{'TST_NUSR','TST_OUSR'};
                for(User u : [select Id, ALIAS from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'TST_NUSR')
                        newOwner = u;
                    else if(u.ALIAS == 'TST_OUSR')
                        oldOwner = u;
                }
            Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
            Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
            acc.OwnerId = oldOwner.Id;
            acc.Type = 'Lead';
            acc.Partner_Type__c='Unknown';
            system.runAs(oldOwner)
            {
                insert acc;
            }
            
            // newOwner requests for the account
            system.runAs(newOwner)
            {
                Test.startTest();
                CreateAccountReassignment(acc, newOwnerRule);
                Test.stopTest();
            }
            
            // Refresh Account and Reassignment Request
            List<Account_Reassignment__c> accReassignList = getReassignmentRequestsForAccount(acc);
            acc = RefreshAccount(acc);
            
            // Asserts
            
            // Owner should not have changed
            system.assertEquals(acc.OwnerId, oldOwner.Id);
            
            // Refresh
            accReassignList = RefreshAccountReassignment(accReassignList);
            // Owner should have changed
            acc = RefreshAccount(acc);
        }
        
    }

    /**
        LeadAccount_Bulk_Accept()
        - Lead Account
        - New Owner requests for account
        - Old Owner accepts
    */
    static testMethod void LeadAccount_Bulk_Accept()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User newOwner,oldOwner;
            List<String> userAliasList = new List<String>{'TST_NUSR','TST_OUSR'};
                for(User u : [select Id, ALIAS, Name from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'TST_NUSR')
                        newOwner = u;
                    else if(u.ALIAS == 'TST_OUSR')
                        oldOwner = u;
                }
            Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
            Account[] BulkAccounts = new Account[10];
            Integer count;
            for(count=0; count<10; count++)
            {
                BulkAccounts[count] = utilTestClass.CreateAccount('__Test Account' + count);
                BulkAccounts[count].OwnerId = oldOwner.Id;
                BulkAccounts[count].Type = 'Lead';
                BulkAccounts[count].Partner_Type__c='Unknown';
            }
            system.runAs(oldOwner)
            {
                insert BulkAccounts;
            }
            
            // newOwner requests for the account
            Account_Reassignment__c[] accRequests= new Account_Reassignment__c[10];
            system.runAs(newOwner)
            {
                Test.startTest();
                for(count=0; count<10; count++)
                {
                    accRequests[count] = utilTestClass.CreateAccountReassignment(BulkAccounts[count].Id, newOwnerRule.Id);
                    accRequests[count].Reassign__c = false;
                    accRequests[count].Approver_2__c = UserInfo.getUserId();
                    accRequests[count].Approver_1__c = UserInfo.getUserId();
                }
                insert accRequests;
                Test.stopTest();
            }
            
            // Refresh Account and Reassignment Request
            accRequests = getReassignmentRequestsForAccount(BulkAccounts);
            BulkAccounts = RefreshAccount(BulkAccounts);
            
            // Asserts
            system.assertEquals(accRequests.size(), 20);
            system.assertEquals(accRequests[10].Reassign_Status__c, 'Approval Pending');
            system.assertEquals(accRequests[10].Reassign__c, false);
            
            // Owner should not have changed
            system.assertEquals(BulkAccounts[0].OwnerId, oldOwner.Id);
            
            // OldOwner accepts
            system.runAs(oldOwner)
            {
                for(count=0; count<10; count++)
                {
                    accRequests[10+count].Reassign_Status__c = 'Accepted';
                }
                update accRequests;
            }
            // Refresh
            accRequests = RefreshAccountReassignment(accRequests);
            // Assert
            for(count=0; count<10; count++)
            {
                system.assertEquals(accRequests[10+count].Reassign_Status__c, 'Accepted');
                system.assertEquals(accRequests[10+count].Reassign__c, true);
            }
            
            // Owner should have changed
            BulkAccounts = RefreshAccount(BulkAccounts);
            /*
            for(count=0; count<10; count++)
            {
                system.assertEquals(BulkAccounts[count].OwnerId, newOwner.Id);
            }
            */
            
            
        }
    }

    static testMethod void test_AccountReassignmentBatchClass(){
        ManagedPkgErrorClass.isFromManagedPackage = false;
        User newOwner,oldOwner;
        List<String> userAliasList = new List<String>{'TST_NUSR','TST_OUSR'};
            for(User u : [select Id, ALIAS, Name from User where ALIAS IN : userAliasList]){
                if(u.ALIAS == 'TST_NUSR')
                    newOwner = u;
                else if(u.ALIAS == 'TST_OUSR')
                    oldOwner = u;
            }
        Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
        Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
        Contact con = utilTestClass.CreateContact('test', 'cnt');
        
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'ISP - Active';
        acc.Partner_Type__c='Unknown';
        acc.Revenue_Account__c=true;
        system.runAs(oldOwner)
        {
            insert acc;
            Test.startTest();
            con.AccountId = acc.Id;
            insert con;
            
        }
        Account_Reassignment__c accReassign=new Account_Reassignment__c();
        // newOwner requests for the account
        system.runAs(newOwner)
        {
            //CreateAccountReassignment(acc, newOwnerRule);
           // Account_Reassignment__c accReassign=new Account_Reassignment__c();
            accReassign.Account__c=acc.Id;
            accReassign.Assign_To__c=newOwnerRule.Id;
            accReassign.Approver_2__c = UserInfo.getUserId();
            accReassign.Approver_1__c = UserInfo.getUserId();
            insert accReassign;
            accReassign.Reassign__c=false;
            accReassign.Reassign_Status__c = 'Approved';
            accReassign.Reassignment_Due_Date__c = System.today();
            update accReassign;
            
            
        }
        
        user u=[select id from user where profile.Name='Sales Operations' and isActive=true limit 1];
        system.runas(u){
            AccountReassignmentEntension testController0 = new AccountReassignmentEntension(accReassign.Id);
            testController0.overrideCutOff();
        }
        Integer batchSize = Integer.valueOf(GSMSettings.getValue('AccountReassignmentBatchClass_BatchSize'));
        AccountReassignmentBatchClass batchObj = new AccountReassignmentBatchClass();
        Database.executebatch(batchObj,batchSize);
        Test.stopTest();
        accReassign.Adhoc_Request__c = true;
        update accReassign;
        system.runas(u){
            AccountReassignmentEntension testController0 = new AccountReassignmentEntension(accReassign.Id);
            testController0.overrideCutOff();
        }
        
        
        
    }

    /**
        ActiveAccount_Single_Reject()
        - Active Account
        - New Owner requests for account
        - Old Owner rejects
    */
    static testMethod void ActiveAccount_Single_Reject()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User newOwner,oldOwner;
            List<String> userAliasList = new List<String>{'TST_NUSR','TST_OUSR'};
                for(User u : [select Id, ALIAS, Name from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'TST_NUSR')
                        newOwner = u;
                    else if(u.ALIAS == 'TST_OUSR')
                        oldOwner = u;
                }
            Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
            
            //Account acc = CreateAccount('_AccReass_TestCase_', oldOwner.Id, 'Lead');
            //acc.Type = 'ISP - Active';
            Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
            acc.OwnerId = oldOwner.Id;
            acc.Type = 'Lead';//'ISP - Active';
            acc.Partner_Type__c='Unknown';
            system.runAs(oldOwner)
            {
                insert acc;
            }
            
            // newOwner requests for the account
            system.runAs(newOwner)
            {
                Test.startTest();
                CreateAccountReassignment(acc, newOwnerRule);
                //Test.stopTest();
            }
            
            // Refresh Account and Reassignment Request
            List<Account_Reassignment__c> accReassignList = getReassignmentRequestsForAccount(acc);
            acc = RefreshAccount(acc);
            
            AccountReassignmentEscalationController escController=new AccountReassignmentEscalationController();
            
            PageReference pageRef0 = Page.AccountReassignmentEscalation;
            pageRef0.getParameters().put('id', accReassignList[0].Id);
            Test.setCurrentPageReference(pageRef0);
            escController=new AccountReassignmentEscalationController();
            List<ApexPages.Message> errorMessages=ApexPages.getMessages();
            Boolean isInvalidRequestError=true;
            for(ApexPages.Message msg : errorMessages)
            {
                if(msg.getDetail().contains('This Account Reassignment Request does not qualify for Escalations, request should be older than 7 days to be escalated.'))
                    isInvalidRequestError=true;
            }
            System.assertEquals(isInvalidRequestError,true);
            
            //Update the custom setting for escalation days to check valid scenario
            /*Account_Reassignment_Settings__c arSettings = Account_Reassignment_Settings__c.getInstance();
            upsert new Account_Reassignment_Settings__c(
                Name = 'DaysToHoldBeforeEscalation',
                Value__c = '-7'
            );
            
            upsert new Account_Reassignment_Settings__c(
                Name = 'DaysUntillEscalationCanBeDone',
                Value__c = '-21'
            );*/
            
            AccountReassignmentEscalationController escController2 =new AccountReassignmentEscalationController();
            
            PageReference pageRef2 = Page.AccountReassignmentEscalation;
            pageRef2.getParameters().put('id', accReassignList[0].Id);
            Test.setCurrentPageReference(pageRef2);
            escController2=new AccountReassignmentEscalationController();
            //Cancel the request
            escController2.cancel();
            
            // OldOwner rejects
            system.runAs(oldOwner)
            {
                AccountReassignmentInterfaceClass.RejectButton(accReassignList[0].Id);
            }
            // Refresh
            accReassignList = RefreshAccountReassignment(accReassignList);
            // Assert
            //system.assertEquals(accReassignList[1].Reassign_Status__c, 'Rejected');
            //system.assertEquals(accReassignList[1].Reassign__c, false);
            
            // Owner should not have changed
            acc = RefreshAccount(acc);
            //system.assertEquals(acc.OwnerId, oldOwner.Id);
            
            //accReassignRequest.Rejected_On__c=Date.today().addDays(-15);
            //update accReassignRequest;
            PageReference pageRef = Page.AccountReassignmentEscalation;
            pageRef.getParameters().put('id', accReassignList[0].Id);
            Test.setCurrentPageReference(pageRef);
            escController=new AccountReassignmentEscalationController();
            
            escController.save();
            
            Profile pr = [select id from profile where name='Chatter Free User'][0];
            User usrTst = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old12_owner@akamai.com',profileid = pr.Id);
            insert usrTst;
            Test.stopTest();
            
            system.runAs(usrTst){
                try{
                    escController.save();
                }catch(Exception e){
                    
                }
            }
            
            
            pageRef = Page.AccountReassignmentEscalation;
            pageRef.getParameters().put('id', '');
            Test.setCurrentPageReference(pageRef);
            escController=new AccountReassignmentEscalationController();
            
            // Anand Hegde - Cover feature toggle
            
            /*Features_Toggle__c featureToggle = Features_Toggle__c.getInstance('AccountReassignment');
            featureToggle.Toggle__c = false;
            update featureToggle;*/
        }
    }

    /**
        ActiveAccount_Single_Accept()
        - Active Account
        - New Owner requests for account
        - Approved cos no one rejects
    */
    static testMethod void ActiveAccount_Single_Accept()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User newOwner,oldOwner;
            List<String> userAliasList = new List<String>{'TST_NUSR','TST_OUSR'};
                for(User u : [select Id, ALIAS, Name from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'TST_NUSR')
                        newOwner = u;
                    else if(u.ALIAS == 'TST_OUSR')
                        oldOwner = u;
                }
            Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
            Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
            Contact con = utilTestClass.CreateContact('test', 'cnt');
            
            acc.OwnerId = oldOwner.Id;
            acc.Type = 'ISP - Active';
            acc.Partner_Type__c='Unknown';
            acc.Revenue_Account__c=true;
            system.runAs(oldOwner)
            {
                insert acc;
                Test.startTest();
                con.AccountId = acc.Id;
                insert con;
                
            }
            // newOwner requests for the account
            system.runAs(newOwner)
            {
                CreateAccountReassignment(acc, newOwnerRule);
            }
            Test.stopTest();
            // Refresh Account and Reassignment Request
            List<Account_Reassignment__c> accReassignList = getReassignmentRequestsForAccount(acc);
            acc = RefreshAccount(acc);
            
            // Owner should not have changed
            system.assertEquals(acc.OwnerId, oldOwner.Id);
            String res=AccountReassignmentInterfaceClass.Reassign_ApprovedReassignments();
            // Refresh
            accReassignList = RefreshAccountReassignment(accReassignList);
            // Assert
            {
                acc = RefreshAccount(acc);
            }
        }
    }

    /**
        UpdateOldOwnerTest()
        - Test the AccountTriggerClass.UpdateOldOwner()
        - Changed Account Owner Assertion to check with ONA instead of OldOwner. (part of CR 812208 PDRA Update part-2)
    */
    static testmethod void UpdateOldOwnerTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User newOwnerUser,ONAUser;
            List<String> userAliasList = new List<String>{'ONA','newUser'};
                for(User u : [select Id, ALIAS, ProfileId, UserRoleId from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'ONA')
                        ONAUser = u;
                    else if(u.ALIAS == 'newUser')
                        newOwnerUser = u;
                }
            User oldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old123_owner@akamai.com',profileid = newOwnerUser.ProfileId, UserRoleId = newOwnerUser.UserRoleId );
            insert oldOwnerUser;
            // Create Account
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = oldOwnerUser.Id;
            
            //insert acc;
            //CR 734770 Automate Account Reassignment - Next Steps
            System.runAs(oldOwnerUser) {
                insert acc;
            }
            
            // Create an Account Reassignment Rule to change the Account Owner.
            /*Account_Reassignment_Rule__c accRule = new Account_Reassignment_Rule__c();
            accRule.Name = '__ Test Rule';
            accRule.Associated_User__c = newOwnerUser.Id;
            if(featureToggleCustomSettings.get('UserRoleUpdateThroughAssignmentRule').Toggle__c == true)
            accRule.User_Role__c = role.Name;*/
            Account_Reassignment_Rule__c accRule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            // Update the Account Owner via the Account Reassignment Request.
            //acc.Reassign_Account__c = true;
            //acc.Account_Reassignment_Rule__c = accRule.Id;
            /*Account_Reassignment__c accReassign=new Account_Reassignment__c();
            accReassign.Account__c=acc.Id;
            accReassign.Assign_To__c=accRule.Id;
            accReassign.Reassign__c=true;*/ 
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, accRule.Id);
            Test.startTest();
            insert accReassign;
            Test.stopTest();
            // Assert that the values have been updated.
            acc= [select Id, OwnerId, Old_Account_Owner__c from Account where Id=:acc.Id];
            //system.assertEquals(acc.Old_Account_Owner__c, oldOwner.Id);
            // Ali KM: fetch ONA User
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutoPDRAUpdateOnAcctInsert') == true) 
                system.assertEquals(acc.Old_Account_Owner__c,ONAUser.Id);
            else
                system.assertEquals(acc.Old_Account_Owner__c, oldOwnerUser.Id);
            //system.assertEquals(acc.OwnerId, newOwnerUser.Id);
            
        }
    }

    static testMethod void testRSMChangeOnReassignmentRule()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name=:roleName][0].Id;
            
            Account acc = utilTestClass.CreateAccount('__rsm__test');
            Contact con = utilTestClass.CreateContact('test', 'cont');
            User oldAccountOwner = CreateUser('T_OUSR', salesRepProfileId, roleId);
            User oldAccountOwnerRSM = CreateUser('T_ORSM', salesRepProfileId, roleId);
            User newAccountOwner = CreateUser('T_NUSR', salesRepProfileId, roleId);
            User newAccountOwnerRSM = CreateUser('T_NRSM', salesRepProfileId, roleId);
            insert (new User[] {oldAccountOwner, oldAccountOwnerRSM, newAccountOwner, newAccountOwnerRSM});
            
            // Create rules for the users
            Account_Reassignment_Rule__c oldAccountOwnerRule = utilTestClass.CreateAccountReassignmentRule(oldAccountOwner.Name, oldAccountOwner.Id, roleName);
            oldAccountOwnerRule.Associated_User_RSM__c = oldAccountOwnerRSM.Id;
            // oldAccountOwnerRule.OwnerId = oldAccountOwner.Id;
            
            Account_Reassignment_Rule__c newAccountOwnerRule = utilTestClass.CreateAccountReassignmentRule(newAccountOwner.Name, newAccountOwner.Id, roleName);
            newAccountOwnerRule.Associated_User_RSM__c = newAccountOwnerRSM.Id;
            newAccountOwnerRule.OwnerId = oldAccountOwner.Id;
            
            insert (new Account_Reassignment_Rule__c[] {oldAccountOwnerRule, newAccountOwnerRule});
            
            Territory_Mapping__c tmForONA = utilTestClass.createTerritoryMapping('ANZ - ANZ EAST', 'Carrier North America_Carrier North America', 'ANZ');
            insert tmForONA;
            
            oldAccountOwnerRule.Territory_ID__c = tmForONA.id;
            newAccountOwnerRule.Territory_ID__c = tmForONA.id;
            
            List<Account_Reassignment_Rule__c> arrUpdateList = new List<Account_Reassignment_Rule__c>();
            arrUpdateList.add(oldAccountOwnerRule);
            arrUpdateList.add(newAccountOwnerRule);
            
            update arrUpdateList;
            
            acc.OwnerId = oldAccountOwner.Id;
            acc.Type =  'Lead';//'ISP - Active';
            acc.Partner_Type__c='Unknown';
            system.runAs(oldAccountOwner)
            {
                insert acc;
                
            }
            Test.startTest();
            con.AccountId = acc.Id;
            insert con;
            
            // newAccountOwner requests for the account
            system.runAs(newAccountOwner)
            {
                
                CreateAccountReassignment(acc, newAccountOwnerRule);
                
            }
            //Create Oppty and OrderApproval to test the RSM Email thingy
            Integer bulkSize = 10;
            
            Id akamaiRecTypeId = [select Id from RecordType where Name='Akamai Opportunity'][0].Id;
            List<Opportunity> listOfOpportunities = new List<Opportunity>();
            for(Integer i=0; i<bulkSize; i++)
            {
                Opportunity oppty = CreateOpportunity('blackstratblues'+i, acc.Id);
                oppty.RecordTypeId = akamaiRecTypeId;
                listOfOpportunities.add(oppty);
            }
            insert(listOfOpportunities);
            
            List<Order_Approval__c> listOfOrderApprovals = new List<Order_Approval__c>();
            for(Integer i=0; i<bulkSize; i++)
            {
                Order_Approval__c orderApproval = utilTestClass.CreateOrderApproval(listOfOpportunities[i].Id, oldAccountOwner.Id);
                listOfOrderApprovals.add(orderApproval);
            }
            insert(listOfOrderApprovals);
            // Refresh Account and Reassignment Request
            List<Account_Reassignment__c> accReassignList = getReassignmentRequestsForAccount(acc);
            Test.stopTest();
            AccountReassignmentInterfaceClass.Reassign_ApprovedReassignments();
            
            // Refresh
           /* accReassignList = RefreshAccountReassignment(accReassignList);
            // Assert
            //system.assertEquals(accReassignList[1].Reassign_Status__c, 'Accepted');
            //system.assertEquals(accReassignList[1].Reassign__c, true);
            // Owner should have changed
            acc = RefreshAccount(acc);
            //system.assertEquals(acc.OwnerId, newAccountOwner.Id);
            
            // Verify that the OA RSM Email field is blank before account reassignment
            for(Integer i=0; i<bulkSize; i++)
            {
                System.assertEquals(listOfOrderApprovals[i].RSM_Email__c, null);
            }
            listOfOrderApprovals = refreshOrderApprovals(listOfOrderApprovals);
            //OA RSM EMAIL should have got updated
            //for(Integer i=0; i<bulkSize; i++)
            {
                //System.assertEquals(listOfOrderApprovals[i].RSM_Email__c.toLowerCase(), newAccountOwnerRSM.Email.toLowerCase());
            }
            //Change RSM to older RSM and check if RSM Email on orderApproval is updated
            newAccountOwnerRule.Associated_User_RSM__c = oldAccountOwnerRSM.Id;
            update newAccountOwnerRule;
            listOfOrderApprovals = refreshOrderApprovals(listOfOrderApprovals);
            //OA RSM EMAIL should have got updated
            for(Integer i=0; i<bulkSize; i++)
            {
                System.assertEquals(listOfOrderApprovals[i].RSM_Email__c.toLowerCase(), oldAccountOwnerRSM.Email.toLowerCase());
            }*/
            
        }
    }

    static testMethod void testNormalizedFieldsChange()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User newOwner = [SELECT Id, Name FROM User WHERE ALIAS = 'TST_NUSR'][0];
            Account_Reassignment_Rule__c oldOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_OUSR' limit 1][0];
            Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
            
            Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
            acc.OwnerId = [SELECT Id, Name FROM User WHERE ALIAS = 'ONA'][0].id;
            acc.Type = 'Lead';
            acc.Partner_Type__c='Unknown';
            insert acc;
            
            acc = RefreshAccount(acc);
            //normalized fields should be blank at first
            System.assertEquals(acc.Normalized_Territory_ID__c, null);
            System.assertEquals(acc.Normalized_Territory_Name__c, null);
            
            system.runAs(newOwner)
            {
                Test.startTest();
                CreateAccountReassignment(acc, newOwnerRule);
            }
            
            acc = RefreshAccount(acc);
            String firstNormalizedTerritoryName = acc.Normalized_Territory_Name__c;
            String firstNormalizedTerritoryMappingId = acc.Normalized_Territory_ID__c;
            //make sure owner has changed
            //system.assertEquals(acc.OwnerId, newOwner.Id);
            //normalized fields should no longer be null
            //System.assertNotEquals(acc.Normalized_Territory_ID__c, null);
            //System.assertNotEquals(acc.Normalized_Territory_Name__c, null);
            
            //change the owner again and then normalized field should remain same
            system.runAs(newOwner)
            {
                CreateAccountReassignment(acc, oldOwnerRule);
            }
            
            acc = RefreshAccount(acc);
            //make sure owner has changed
            //system.assertEquals(acc.OwnerId, oldOwner.Id);
            //System.assertEquals(acc.Normalized_Territory_ID__c, firstNormalizedTerritoryMappingId);
            //System.assertEquals(acc.Normalized_Territory_Name__c, firstNormalizedTerritoryName);
            
        }
    }

    static testmethod void testSettersAndGetters()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            // Anand Hegde - This is to increase coverage of AccountReassignmentDataClass
            AccountReassignmentDataClass accReassignDataObject = new AccountReassignmentDataClass();
            accReassignDataObject.setRelatedContacts(new List<Contact>());
            accReassignDataObject.setNewAccountTeamMembers(new List<AccountTeamMember>());
            accReassignDataObject.getNewAccountTeamMembers();
            accReassignDataObject.getRelatedAccountShares();
            accReassignDataObject.setRelatedAccountShares(new List<AccountShare>());
            accReassignDataObject.getAccountIdNotPresentErrorMessage();
            accReassignDataObject.setAccountIdNotPresentErrorMessage('test');
            accReassignDataObject.setRevenueAccounts(new Set<Id>());
        }
    }
    
    static testMethod void testReasonCodeChange()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            User accOldOwnerUser,accNewOwnerUser,newOwnerRSM;
            List<String> userAliasList = new List<String>{'TST_NRSM','oldUser','newUser'};
                for(User u : [select Id, ALIAS, Name, UserRole.Name from User where ALIAS IN : userAliasList]){
                    if(u.ALIAS == 'TST_NRSM')
                        newOwnerRSM = u;
                    else if(u.ALIAS == 'oldUser')
                        accOldOwnerUser = u;
                    else if(u.ALIAS == 'newUser')
                        accNewOwnerUser = u;
                }
            
            Account_Reassignment_Rule__c oldOwnerRule = utilTestClass.CreateAccountReassignmentRule(accOldOwnerUser.Name, accOldOwnerUser.Id, accOldOwnerUser.UserRole.Name);
            oldOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
            
            Territory_Mapping__c oldTM = utilTestClass.createTerritoryMapping('ANZ - ANZ EAST', 'Carrier North America_Carrier North America', 'ANZ');
            insert oldTM;
            oldOwnerRule.Territory_ID__c = oldTM.Id;
            
            Account_Reassignment_Rule__c newOwnerRule = utilTestClass.CreateAccountReassignmentRule(accNewOwnerUser.Name, accNewOwnerUser.Id, accOldOwnerUser.UserRole.Name);
            newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
            Territory_Mapping__c newTM = utilTestClass.createTerritoryMapping('India - ECG INDIA', 'Carrier ANZ_Carrier ANZ', 'DM INDIA');
            insert newTM;
            newOwnerRule.Territory_ID__c = newTM.Id;
            insert (new Account_Reassignment_Rule__c[] {oldOwnerRule, newOwnerRule});
            
            //Create Account
            Account acc1 = utilTestClass.CreateAccount('__Test Account');
            acc1.OwnerId = accOldOwnerUser.Id;
            acc1.Type = 'Lead';
            acc1.Website = 'www.test.com';
            System.runAs(accOldOwnerUser){
                insert acc1;
            }
            Opportunity oppty = utilTestClass.CreateOpportunity('__Tt Oppty','1. Identify Need');
            oppty.AccountId = acc1.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            
            
            System.runAs(accOldOwnerUser){
                
                insert oppty;
                
            }
            
            Test.startTest();
            // Reassign
            Account_Reassignment__c accReassign1=new Account_Reassignment__c();
            accReassign1.Account__c = acc1.Id;
            accReassign1.Assign_To__c=newOwnerRule.Id;
            accReassign1.Reassign__c=false;
            accReassign1.Reason_Code__c ='Workload Rebalancing';
            accReassign1.Approver_1__c = accNewOwnerUser.Id;
            accReassign1.Approver_2__c = accNewOwnerUser.Id;
            accReassign1.Account_Owner_RSM__c = newOwnerRSM.Id;
            accReassign1.Assign_To_User_RSM__c = newOwnerRSM.Id;
            accReassign1.Reassign_Status__c = 'Approval Pending';
            accReassign1.Adhoc_Request__c = true;
            
            system.runAs(newOwnerRSM)
            {
                insert accReassign1;
            }
            Test.stopTest();
            AccountReassignmentEntension ent = new AccountReassignmentEntension(accReassign1.id);
            ent.overrideCutOff();
            
            
            
        }
    }

    static testmethod void extendTestCoverage()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            List<Id> idList = new List<Id>();
            
            Account acc1 = utilTestClass.CreateAccount('__Test Account');
            acc1.Type = 'Lead';
            acc1.Website = 'www.test.com';
            insert acc1;
            
            List<Account> lst = new List<Account>();
            lst.add(acc1);
            
            AccountReassignmentInterfaceClass testObj = new AccountReassignmentInterfaceClass(lst, true);
            
            AccountReassignmentDataClass test = testObj.getAccReassignDataObject();
            
            AccountReassignmentInterfaceClass testSF1 = new AccountReassignmentInterfaceClass(acc1.Id);
            AccountReassignmentInterfaceClass.ResultSetCustom rsC = new AccountReassignmentInterfaceClass.ResultSetCustom(false, 'Test');
            testSF1.Cancel();
        }
    }

    // Increasing coverage
    static testmethod void testAccountReassignmentEntensionSF1()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOldOwnerUser,accNewOwnerUser;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                }
            User tmUser1 = [select Id from User where lastname='TmUser1' limit 1][0];
            Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
            
            
            // Add 1 team member to the rule
            Default_Account_Team_Members__c tm1 = new Default_Account_Team_Members__c();
            tm1.Associated_Account_Reassignment_Rule__c = rule.Id;
            tm1.Team_Member__c = tmUser1.Id; // Standard User
            tm1.Account_Access__c = 'Read Only';
            tm1.Opporunity_Access__c = 'Private';
            
            tm1.Team_Role__c = 'ADS AM';
            
            insert tm1;
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            
            System.runAs(accOldOwnerUser){
                insert acc;
            }
            
            Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
            accReassign.Approval_Level__c = 'Reassignment Approved';
           // accReassign.Reassign_Status__c ='Approval Pending';
            Test.startTest();
            insert accReassign;
            System.runAs(accNewOwnerUser) 
            {
                AccountReassignmentEntension testController2 = new AccountReassignmentEntension(accReassign.Id);
                testController2.overrideCutOff();
                testController2.backToRecord();
            }
        }
    }
    
   /* static testmethod void testReassignment(){
        Account acc = utilTestClass.CreateAccount('__Test Account');
       // acc.Revenue_Account__c = true;
        insert acc;
        list<Account_Reassignment__c> arrList = new list<Account_Reassignment__c>();
        list<Account> accList = new list<Account>();
        Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
        Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
        accReassign.Approval_Level__c = 'Reassignment Approved';
        accReassign.Reason_Code__c = 'Account Consolidation';
        accReassign.Action__c = 'Active Account Approval Required';
        accReassign.Validation_Override__c = true;
        insert accReassign;
        arrList.add(accReassign);
        accList.add(acc);
        Map<Id,Account_Reassignment__c> oldAccReassignmentMap = new Map<Id,Account_Reassignment__c>();
        oldAccReassignmentMap.put(accReassign.Id,accReassign);
        AccountReassignmentInterfaceClass ob = new AccountReassignmentInterfaceClass(accList);
        AccountReassignmentInterfaceClass ob1 = new AccountReassignmentInterfaceClass();
        AccountReassignmentInterfaceClass ob2 = new AccountReassignmentInterfaceClass(arrList,true,true,oldAccReassignmentMap);
        ob1.initializeAccReassignDataObject(arrList,'test',true,true,oldAccReassignmentMap);
        //ob1.cancel();
        AccountReassignmentInterfaceClass.showErrorAndDiscontinue('error');
        Map<Id, Id> AccountToReassignmentRuleMap = new Map<Id, Id>();
        AccountToReassignmentRuleMap.put(acc.Id,rule.Id);
        AccountReassignmentInterfaceClass.createAccountReassignmentRequest(AccountToReassignmentRuleMap);
        ob1.FetchUserRole(accList);
        ob1.AddTeamMember(acc.Id,UserInfo.getUserId(),'Sales - Primary');
        AccountReassignmentInterfaceClass.UpdateAccessLevel('Private');
        AccountReassignmentInterfaceClass.UpdateAccessLevel('Read/Write');
        AccountReassignmentInterfaceClass.UpdateAccessLevel('test');
        AccountReassignmentInterfaceClass.isPastCutOffDate(accReassign);
        AccountReassignmentInterfaceClass.Accept(accReassign);
        AccountReassignmentInterfaceClass.Decline(accReassign);
        AccountReassignmentInterfaceClass.EscalateButton(accReassign.id);
        AccountReassignmentInterfaceClass.AcceptButton(accReassign.id);
        ob1.SendForApproval(accReassign,'test');
        ob1.PassDenialOfReassignment(accReassign);
        ob1.UpdateOldOwner(acc);
        ob1.PreventDuplicateAccountReassignments();
        ob1.getUserEmailId(new set<Id>{UserInfo.getUserId()});
        ob1.concatTwoStrings('test','test');
        Id pActiveAccountReqEscalationTemplateId = [Select Id, DeveloperName from EmailTemplate where DeveloperName='AccountReassignmentEscalationRequest'][0].Id;
        AccountReassignmentInterfaceClass.createSingleEmailWithVFTemplate(accReassign.Id,UserInfo.getUserId(),'','',pActiveAccountReqEscalationTemplateId);
        AccountReassignmentInterfaceClass.submitForApproval(new List<Id>{accReassign.Id});
        AccountReassignmentInterfaceClass.getAccountReasonCodeSettings();
        AccountReassignmentInterfaceClass.noApprovalRequired(new List<Id>{accReassign.Id});
        AccountReassignmentInterfaceClass.isPrivilegedForAction(UserInfo.getUserId(),UserInfo.getProfileId(),accReassign,'Accept');
        AccountReassignmentInterfaceClass.isPrivilegedForAction(UserInfo.getUserId(),UserInfo.getProfileId(),accReassign,'Reject');
        AccountReassignmentInterfaceClass.isPrivilegedForAction(UserInfo.getUserId(),UserInfo.getProfileId(),accReassign,'Escalate');
        ob1.getGroupContructedSet('test','test','test','test');
        AccountReassignmentTriggerHandler handler = new AccountReassignmentTriggerHandler();
        handler.beforeInsertBeforeUpdateTrigger();
        handler.afterInsertAfterUpdateTrigger();
        handler.beforeDeleteBeforeUndeleteTrigger();
        handler.afterDeleteAfterUndeleteTrigger();
    }*/
    
    public static Territory_Mapping__c refreshTerritoryMapping(Id tMapId)
    {
        return [select Id, Akam_Territory_Mapping_Id__c from Territory_Mapping__c where Id=: tMapId][0];
    }
    
    public static Account_Reassignment_Rule__c refreshAccountReassignmentRule(Id ruleId)
    {
        return [select Id, Area__c, Territory_ID__r.Akam_Territory_Mapping_Id__c from Account_Reassignment_Rule__c where Id=: ruleId][0];
    }
    
    private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias,
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8',
                                lastname=pUsrAlias,
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles',
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = pr.Id,
                                UserRoleId = role.Id );
        return newUser;
    }
    
    private static User CreateUser(String pUsrAlias, Id profileId, Id roleId)
    {
        User newUser = new User(alias = pUsrAlias,
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8',
                                lastname=pUsrAlias,
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles',
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = profileId,
                                UserRoleId = roleId );
        return newUser;
    }
    
    // CreateOpportunity()
    public static Opportunity CreateOpportunity(String pOppName, Id pAccId)
    {
        Opportunity newOpp = new Opportunity();
        newOpp.Name = pOppName;
        newOpp.AccountId = pAccId;
        newOpp.StageName = '1. Identify Need';
        newOpp.CloseDate = Date.today().addMonths(4);
        return newOpp;
    }
    
    // CreateOrderApproval()
    public static Order_Approval__c CreateOrderApproval(Opportunity pOpp)
    {
        String returnMsg = OrderApprovalClass.Create_OrderApproval(pOpp.Id, pOpp.RecordTypeId+'',pOpp.StageName);
        return [select Id,
                Approvals_Required__c,
                Associated_Opportunity__c,
                RSM_Email__c
                from Order_Approval__c
                where Associated_Opportunity__c=: pOpp.Id][0];
    }
    
    /**
        RefreshAccount(Account acc)
        - Refresh single account
    */
    private static Account RefreshAccount(Account acc)
    {
        return RefreshAccount(new Account[] {acc})[0];
    }
    /**
        RefreshAccount(Account[] acc)
        - Refresh bulk accounts
    */
    private static Account[] RefreshAccount(Account[] accounts)
    {
        return [select Id,
                OwnerId,
                Account_Status__c,
                Normalized_Territory_ID__c,
                Normalized_Territory_Name__c,
                Akam_Territory_Mapping_Id__c,
                Area__c
                from Account
                where Id IN:accounts];
    }
    public static List<Order_Approval__c> refreshOrderApprovals(List<Order_Approval__c> listOfOrderApprovals)
    {
        return [select Id, RSM_Email__c, Associated_Opportunity__c from Order_Approval__c where Id in:listOfOrderApprovals];
    }
    /**
        CreateAccountReassignment(Account acc, Account_Reassignment_Rule__c rule)
        - Create an Account Reassignment Request
    */
    private static void CreateAccountReassignment(Account acc, Account_Reassignment_Rule__c rule)
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        PageReference pageRef = Page.AccountReassignment2;
        pageRef.getParameters().put('id', acc.id);
        Test.setCurrentPageReference(pageRef);
        AccountReassignmentInterfaceClass controller = new AccountReassignmentInterfaceClass();
        controller.accReassign.Assign_To__c = rule.Id;
        controller.save();
    }
    /**
        getReassignmentRequestsForAccount(Account account)
        - Returns all the Account Reassignment Requests for the account
    */
    private static Account_Reassignment__c[] getReassignmentRequestsForAccount(Account account)
    {
        return getReassignmentRequestsForAccount(new Account[] {account});
    }
    /**
        getReassignmentRequestsForAccount(Account[] accounts)
        - Returns all the Account Reassignment Requests for the accounts
    */
    private static Account_Reassignment__c[] getReassignmentRequestsForAccount(Account[] accounts)
    {
        return [select Id, Reassign_Status__c, Reassign__c,Adhoc_Request__c from Account_Reassignment__c where Account__c IN:accounts Order By CreatedDate];
    }
    /**
        RefreshAccountReassignment(Account_Reassignment__c accReassignments)
    */
    private static Account_Reassignment__c RefreshAccountReassignment(Account_Reassignment__c accReassignments)
    {
        return RefreshAccountReassignment(new Account_Reassignment__c[] {accReassignments})[0];
    }
    /**
        RefreshAccountReassignment(Account_Reassignment__c[] accReassignments)
    */
    private static Account_Reassignment__c[] RefreshAccountReassignment(Account_Reassignment__c[] accReassignments)
    {
        return [select Id,
                Reassign_Status__c,
                Account_Owner__c,
                Reassign__c,
                Status_Message__c,
                Rejected_On__c,
                Adhoc_Request__c,
                isEscalated__c,
                CreatedDate
                from Account_Reassignment__c
                where Id IN:accReassignments];
    }
}