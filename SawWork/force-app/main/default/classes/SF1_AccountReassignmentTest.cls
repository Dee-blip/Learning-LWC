@isTest(seeAllData=false)
public class SF1_AccountReassignmentTest {

        static testmethod void getInitialValues() {
                Account acc = new Account();
                acc.Name = 'TestnhbhABC';
                acc.Vertical__c = 'Gaming';
                acc.Sub_Vertical__c = 'Console Mfs';
                insert acc;
                String returnVal = SF1_AccountReassignment.getInitialValues('Opportunity', 'Deal_Type__c', String.valueOf(acc.Id));

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

        public static Account_Reassignment_Rule__c CreateAccountReassignmentRule(String pName, Id pUserId, String pRoleName)
        {
                Map<String,Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();
                Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
                rule.Name = pName;
                rule.Associated_User__c = pUserId;
                if(featureToggleCustomSettings.get('UserRoleUpdateThroughAssignmentRule').Toggle__c == true)
                        rule.User_Role__c = pRoleName;
                return rule;
        }

        public static User getTestRunUser()
        {
                User testRunUser = new User(id=Userinfo.getUserId());
                return testRunUser;
        }


        static testmethod void getUIThemeDescription() {
                String returnData = SF1_AccountReassignment.getUIThemeDescription();
        }

        public static Account CreateAccount(String pAccName)
        {
                Account newAccount = new Account();
                newAccount.Name = pAccName;
                newAccount.BillingCountry = 'India';
                newAccount.BillingState = 'Delhi';
                return newAccount;
        }

        static testmethod void reassignAccount()
        {
                System.runAs(getTestRunUser())
                {
                        ManagedPkgErrorClass.isFromManagedPackage = false;

                        Map<String, GSM_Settings__mdt>  testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
                        Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
                        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
                        Id roleId = [select Id from UserRole where name=:roleName][0].Id;

                        User oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
                        User oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);

                        // Create Users
                        Profile pr = [select id from profile where name='Sales Operations'][0];
                        UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];


                        User accNewOwnerUser2 = new User(alias = 'newUse', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwne', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_use@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        insert accNewOwnerUser2;

                        User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_usr@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accNewOwnerUser.DelegatedApproverId = accNewOwnerUser2.Id;

                        insert accNewOwnerUser;

                        Test.startTest();

                        User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accOldOwnerUser.DelegatedApproverId = accNewOwnerUser.Id;
                        insert accOldOwnerUser;

                        Account_Reassignment_Rule__c rule = CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);
                        insert rule;

                        Account acc = CreateAccount('__Test Account45');
                        // acc.OwnerId = oldOwner.Id;
                        acc.Type = 'Lead';
                        acc.Website = 'www.test76.com';
                        system.runAs(accNewOwnerUser){
                                insert acc;
                        }
                        

                        String reassignAccount = SF1_AccountReassignment.reassignAccount(String.valueOf(acc.Id), String.valueOf(rule.Id), 'Workload Rebalancing', 'Test', false);
                        reassignAccount = SF1_AccountReassignment.reassignAccount(String.valueOf(acc.Id), String.valueOf(rule.Id), 'Workload Rebalancing', 'Test', true);

                }

                Map<String,String> mpObj = SF1_AccountReassignment.reassignableDataWrapper('Test', 'Test', 'Test');
                mpObj = SF1_AccountReassignment.reassignmentResults('Test', 'Test');
                Test.stopTest();

        }

        // static testmethod void overrideCutOffSF1() {
        //
        //         System.runAs(utilTestClass.getTestRunUser())
        //         {
        //                 ManagedPkgErrorClass.isFromManagedPackage = false;
        //
        //                 Map<String, GSM_Settings__mdt>  testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
        //                 Id salesRepProfileId = [select id from profile where name='Sales - Rep'][0].Id;
        //                 String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        //                 Id roleId = [select Id from UserRole where name=:roleName][0].Id;
        //
        //                 User oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
        //                 User oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);
        //
        //                 // Create Users
        //                 Profile pr = [select id from profile where name='Sales Operations'][0];
        //                 UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];
        //
        //
        //                 User accNewOwnerUser2 = new User(alias = 'newUse', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwne', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_use@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
        //                 insert accNewOwnerUser2;
        //
        //                 User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_usr@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
        //                 accNewOwnerUser.DelegatedApproverId = accNewOwnerUser2.Id;
        //
        //                 insert accNewOwnerUser;
        //
        //                 User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
        //                 accOldOwnerUser.DelegatedApproverId = accNewOwnerUser.Id;
        //                 insert accOldOwnerUser;
        //
        //                 Account acc = utilTestClass.CreateAccount('__Test Account');
        //                 // acc.OwnerId = oldOwner.Id;
        //                 acc.Type = 'Lead';
        //                 acc.Website = 'www.test.com';
        //                 insert acc;
        //
        //
        //                 Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);
        //                 insert rule;
        //                 //Reassign
        //                 Account_Reassignment__c accReassign2 = new Account_Reassignment__c();
        //                 accReassign2.Account__c = acc.Id;
        //                 accReassign2.Assign_To__c = rule.Id;
        //                 accReassign2.Reassign__c = false;
        //                 accReassign2.Reason_Code__c = 'Inside sales to ECG';
        //                 accReassign2.Approver_1__c = accNewOwnerUser.Id;
        //                 accReassign2.Approver_2__c = accNewOwnerUser.Id;
        //                 accReassign2.Account_Owner_RSM__c = oldOwnerRSM.Id;
        //                 accReassign2.Reassign_Status__c = 'Approval Pending';
        //                 insert accReassign2;
        //
        //                 String returnData = SF1_AccountReassignment.overrideCutOffSF1(accReassign2.Id);
        //         }
        // }

        static testmethod void getReassignableData() {
                String reassignableData = SF1_AccountReassignment.getReassignableData();
                System.DEBUG('reassignableData in getReassignableData : ' + reassignableData);
        }

        static testmethod void reassignMultipleApprovals() {

                System.runAs(utilTestClass.getTestRunUser())
                {
                        ManagedPkgErrorClass.isFromManagedPackage = false;

                        Map<String, GSM_Settings__mdt>  testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
                        Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
                        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
                        Id roleId = [select Id from UserRole where name=:roleName][0].Id;

                        User oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
                        User oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);

                        // Create Users
                        Profile pr = [select id from profile where name='Sales Operations'][0];
                        UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];


                        User accNewOwnerUser2 = new User(alias = 'newUse', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwne', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_use@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        insert accNewOwnerUser2;

                        User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_usr@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accNewOwnerUser.DelegatedApproverId = accNewOwnerUser2.Id;

                        insert accNewOwnerUser;

                        User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accOldOwnerUser.DelegatedApproverId = accNewOwnerUser.Id;
                        insert accOldOwnerUser;

                        Account acc = utilTestClass.CreateAccount('__Test Accounttt');
                        // acc.OwnerId = oldOwner.Id;
                        acc.Type = 'Lead';
                        acc.Website = 'www.test11.com';
                        insert acc;

                        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);

                        //Reassign
                        Account_Reassignment__c accReassign = new Account_Reassignment__c();
                        accReassign.Account__c = acc.Id;
                        accReassign.Assign_To__c = rule.Id;
                        accReassign.Reassign__c = false;
                        accReassign.Reason_Code__c = 'Workload Rebalancing';
                        accReassign.Approver_1__c = accNewOwnerUser.Id;
                        accReassign.Approver_2__c = accNewOwnerUser.Id;
                        // accReassign.Account_Owner_RSM__c = oldOwnerRSM.Id;
                        accReassign.Reassign_Status__c = 'Approval Pending';

                        List<String> selectedIds = new List<String>();
                        selectedIds.add(String.valueOf(accReassign.Id));

                        String returnData = SF1_AccountReassignment.reassignMultipleApprovals(selectedIds, accNewOwnerUser2.Id);
                        System.DEBUG('returnData in reassignMultipleApprovals : ' + returnData);
                }
        }

        static testmethod void approveMultipleApprovals() {

                System.runAs(utilTestClass.getTestRunUser())
                {
                        ManagedPkgErrorClass.isFromManagedPackage = false;

                        Map<String, GSM_Settings__mdt>  testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
                        Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
                        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
                        Id roleId = [select Id from UserRole where name=:roleName][0].Id;

                        User oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
                        User oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);

                        // Create Users
                        Profile pr = [select id from profile where name='Sales Operations'][0];
                        UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];


                        User accNewOwnerUser2 = new User(alias = 'newUse', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwne', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_use@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        insert accNewOwnerUser2;

                        User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_usr@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accNewOwnerUser.DelegatedApproverId = accNewOwnerUser2.Id;

                        insert accNewOwnerUser;

                        User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accOldOwnerUser.DelegatedApproverId = accNewOwnerUser.Id;
                        insert accOldOwnerUser;

                        Account acc = utilTestClass.CreateAccount('__Test Accountop');
                        // acc.OwnerId = oldOwner.Id;
                        acc.Type = 'Lead';
                        acc.Website = 'www.test456.com';
                        insert acc;


                        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);

                        //Reassign
                        Account_Reassignment__c accReassign = new Account_Reassignment__c();
                        accReassign.Account__c = acc.Id;
                        accReassign.Assign_To__c = rule.Id;
                        accReassign.Reassign__c = false;
                        accReassign.Reason_Code__c = 'Workload Rebalancing';
                        accReassign.Approver_1__c = accNewOwnerUser.Id;
                        accReassign.Approver_2__c = accNewOwnerUser.Id;
                        // accReassign.Account_Owner_RSM__c = oldOwnerRSM.Id;
                        accReassign.Reassign_Status__c = 'Approval Pending';

                        List<String> selectedIds = new List<String>();
                        selectedIds.add(String.valueOf(accReassign.Id));

                        String returnData = SF1_AccountReassignment.approveMultipleApprovals(selectedIds, 'Test');
                        System.DEBUG('returnData in reassignMultipleApprovals : ' + returnData);
                }
        }

        static testmethod void rejectMultipleApprovals() {

                System.runAs(utilTestClass.getTestRunUser())
                {
                        ManagedPkgErrorClass.isFromManagedPackage = false;

                        Map<String, GSM_Settings__mdt>  testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
                        Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
                        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
                        Id roleId = [select Id from UserRole where name=:roleName][0].Id;

                        User oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
                        User oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);

                        // Create Users
                        Profile pr = [select id from profile where name='Sales Operations'][0];
                        UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];


                        User accNewOwnerUser2 = new User(alias = 'newUse', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwne', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_use@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        insert accNewOwnerUser2;

                        User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_usr@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accNewOwnerUser.DelegatedApproverId = accNewOwnerUser2.Id;

                        insert accNewOwnerUser;

                        User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
                        accOldOwnerUser.DelegatedApproverId = accNewOwnerUser.Id;
                        insert accOldOwnerUser;

                        Account acc = utilTestClass.CreateAccount('__Test Acdfcount');
                        // acc.OwnerId = oldOwner.Id;
                        acc.Type = 'Lead';
                        acc.Website = 'www.sample.com';
                        insert acc;


                        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);

                        //Reassign
                        Account_Reassignment__c accReassign = new Account_Reassignment__c();
                        accReassign.Account__c = acc.Id;
                        accReassign.Assign_To__c = rule.Id;
                        accReassign.Reassign__c = false;
                        accReassign.Reason_Code__c = 'Workload Rebalancing';
                        accReassign.Approver_1__c = accNewOwnerUser.Id;
                        accReassign.Approver_2__c = accNewOwnerUser.Id;
                        // accReassign.Account_Owner_RSM__c = oldOwnerRSM.Id;
                        accReassign.Reassign_Status__c = 'Approval Pending';

                        List<String> selectedIds = new List<String>();
                        selectedIds.add(String.valueOf(accReassign.Id));

                        String returnData = SF1_AccountReassignment.rejectMultipleApprovals(selectedIds, 'Test');
                        System.DEBUG('returnData in reassignMultipleApprovals : ' + returnData);
                }
        }

}