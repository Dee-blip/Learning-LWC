/**
  AccountTeamManagementTest
    @author : Vinayendra T N <vintara@akamai.com>
    @Description : This is the test class for the Account Team Management Page
    (positive) Account Team member Delete
    (Bulk positive) Account Team Member Delete
    (positive) Account Team Member Role Update   
    (Bulk positive) Account Team Member Role Update
    (Negative) Account Team Member Role Update  
    
  @History
  
  Ali KM                  20/10/10         CR 812208 PDRA Update part-2
                                            - Added logic to run ONA if Account.Owner does not have an AccountReassignmentRule
                                            - Implemented ONA Name using Custom Settings - Account_Reassignment_Class_Settings__c
                                            - Also added new field Account_Reassignment_Rule__c.User_Role__c to all AssignmentRules in new methods:
                                            - Following methods have been updated so that Account Owner new reassignment rule
                                                -) AccountTeamManagementTestInit()
 */
@isTest(seeAllData=false)
private class AccountTeamManagementTest {

    //static User
    static User dmlUser = utilTestClass.getTestRunUser();

    // Setup method to create test data.
    @testSetup
    static void setupMethod()
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User tmUser1,tmUser2,ONAUser;
            Account_Reassignment_Rule__c ONAReassignmentRule,rule2;

            ONAUser = [SELECT Id, Name FROM User WHERE ALIAS = 'ONA'][0];
            tmUser1 = utilTestClass.CreateUser('tmUser1', 'Sales Operations', 'Sales Operations');
            tmUser2 = utilTestClass.CreateUser('tmUser2', 'Sales Operations', 'Sales Operations');
            insert (new User[] {tmUser1, tmUser2});

            ONAReassignmentRule = utilTestClass.CreateAccountReassignmentRule('No Owner',ONAUser.Id, 'Owner Not Assigned');
            rule2 = utilTestClass.CreateAccountReassignmentRule('TestRule2', tmUser1.Id, 'Sales Operations');
            insert (new Account_Reassignment_Rule__c[] {ONAReassignmentRule, rule2});

        }
    }

    static testMethod void SingleAccountTeamDel_positive() {

        System.runAs(dmlUser)
        {
            User tmUser1,tmUser2;
            List<String> userAlias = new List<String>{'tmUser1','tmUser2'};
            for(User u : [Select Id, Alias from User where Alias IN : userAlias]){
                if(u.Alias == 'tmUser1')
                    tmUser1 = u;
                else 
                    tmUser2 = u;
            }

            Account acc = utilTestClass.CreateAccount('__Test Account');

            // User 1 will create the Account
            System.runAs(tmUser1)
            {
                insert acc;
            }
            AccountTeamMember atm= new AccountTeamMember();
            atm.AccountId=acc.id;
            atm.TeamMemberRole='Technical Sales - Primary';
            atm.UserId=tmUser2.Id;
            // user 2 will add himself to Account Team of user 1
            System.runAs(tmUser2)
            {
                insert atm;
            }
            // User 2 will use the page to delete himself.
            System.runAs(tmUser2)
            {
                /* Switch to runtime context */
                Test.startTest();
                PageReference pageRef = Page.AccountTeamManagement;
                Test.setCurrentPageReference(pageRef);
                /* Create an instance of the controller */
                AccountTeamManagement atmi = new AccountTeamManagement();
                atmi.AccTMember[0].getBUOptions();
                atmi.AccTMember[0].checked = true;
                atmi.deleteAcc();
                Test.stopTest();
            }
        }
    }

    static testMethod void BulkAccountTeamDelete_positive() {
        System.runAs(dmlUser)
        {
            User tmUser1,tmUser2;
            List<String> userAlias = new List<String>{'tmUser1','tmUser2'};
            for(User u : [Select Id, Alias from User where Alias IN : userAlias]){
                if(u.Alias == 'tmUser1')
                    tmUser1 = u;
                else 
                    tmUser2 = u;
            }

            Account[] BulkAccounts = new Account[20];
            Integer count;

            for(count=0;count<20;count++)
            {
                BulkAccounts[count] = utilTestClass.CreateAccount('__Test Account' + count);
            }   
            System.runAs(tmUser1)
            {
                insert BulkAccounts;
            }
            AccountTeamMember[] Bulkatm = new AccountTeamMember[20];
            for(count=0;count<20;count++)
            {
                Bulkatm[count] = new AccountTeamMember();
                Bulkatm[count].AccountId = BulkAccounts[count].id;
                Bulkatm[count].TeamMemberRole = 'Technical Sales - Primary';
                Bulkatm[count].UserId = tmUser2.id;
            }
            System.runAs(tmUser2)
            {
                insert Bulkatm;
            }
            System.runAs(tmUser2)
            {
                /* Switch to runtime context */
                Test.startTest();
                PageReference pageRef = Page.AccountTeamManagement;
                Test.setCurrentPageReference(pageRef);
                /* Create an instance of the controller */
                AccountTeamManagement atmi = new AccountTeamManagement();
                for(count=0;count<20;count++)
                {
                    atmi.AccTMember[count].checked = true;
                }
                atmi.deleteAcc();
                Test.stopTest();
            }
        }
    }

    static testMethod void SingleAccountTeamUpdate_positive() {
        System.runAs(dmlUser)
        {
            User tmUser1,tmUser2;
            List<String> userAlias = new List<String>{'tmUser1','tmUser2'};
            for(User u : [Select Id, Alias from User where Alias IN : userAlias]){
                if(u.Alias == 'tmUser1')
                    tmUser1 = u;
                else 
                    tmUser2 = u;
            }

            Account acc = utilTestClass.CreateAccount('__Test Account');

            System.runAs(tmUser1)
            {
                insert acc;
            }
            AccountTeamMember atm= new AccountTeamMember();
            atm.AccountId=acc.id;
            atm.TeamMemberRole='Technical Sales - Primary';
            atm.UserId=tmUser2.Id;
            System.runAs(tmUser2)
            {
                insert atm;
            }
            System.runAs(tmUser2)
            {
                /* Switch to runtime context */
                Test.startTest();
                PageReference pageRef = Page.AccountTeamManagement;
                Test.setCurrentPageReference(pageRef);
                /* Create an instance of the controller */
                AccountTeamManagement atmi = new AccountTeamManagement();
                //atmi.init();
                atmi.AccTMember[0].BUOpt = 'CMG - Analyst';
                atmi.SaveAcc();
            }
        }
    }

    static testMethod void BulkAccountTeamUpdate_positive() {
        System.runAs(dmlUser)
        {
            User tmUser1,tmUser2;
            List<String> userAlias = new List<String>{'tmUser1','tmUser2'};
            for(User u : [Select Id, Alias from User where Alias IN : userAlias]){
                if(u.Alias == 'tmUser1')
                    tmUser1 = u;
                else 
                    tmUser2 = u;
            }

            Account[] BulkAccounts = new Account[20];
            Integer count;

            for(count=0;count<20;count++)
            {
                BulkAccounts[count] = utilTestClass.CreateAccount('__Test Account' + count);
            }   
            System.runAs(tmUser1)
            {
                insert BulkAccounts;
            }
            AccountTeamMember[] Bulkatm = new AccountTeamMember[20];
            for(count=0;count<20;count++)
            {
                Bulkatm[count] = new AccountTeamMember();
                Bulkatm[count].AccountId = BulkAccounts[count].id;
                Bulkatm[count].TeamMemberRole = 'Technical Sales - Primary';
                Bulkatm[count].UserId = tmUser2.id;
            }
            System.runAs(tmUser2)
            {
                insert Bulkatm;
            }
            System.runAs(tmUser2)
            {
                /* Switch to runtime context */
                Test.startTest();
                PageReference pageRef = Page.AccountTeamManagement;
                Test.setCurrentPageReference(pageRef);
                /* Create an instance of the controller */
                AccountTeamManagement atmi = new AccountTeamManagement();
                for(count=0;count<20;count++)
                {
                    atmi.AccTMember[count].BUOpt = 'CMG - Analyst';
                }
                atmi.SaveAcc();
                Test.stopTest();
            }
        }
    }
    static testMethod void SingleAccountTeamUpdate_negative() {
        System.runAs(dmlUser)
        {
            User tmUser2 = [Select Id from User where Alias = 'tmUser2' limit 1][0];
            System.runAs(tmUser2)
            {
                /* Switch to runtime context */
                Test.startTest();
                PageReference pageRef = Page.AccountTeamManagement;
                Test.setCurrentPageReference(pageRef);
                /* Create an instance of the controller */
                AccountTeamManagement atmi = new AccountTeamManagement();
                atmi.SaveAcc();
            }
        }
    }
}