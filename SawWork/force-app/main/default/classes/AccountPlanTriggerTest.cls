/* Created By: Vivek Baidya
* Created Date: 09-Sep-2019
* Description: Test class for AccountPlanTriggerFramework. 
*/
@isTest(seeAllData=false)
private class AccountPlanTriggerTest {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        User quipAccessUser = [Select Id, IsActive from User where Name  = 'Simone Stewart' AND IsActive = TRUE LIMIT 1][0];
        User anyUser = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
        System.runAs(dmlUser) {
            anyUser.Email = 'test@akamai.com';
            insert anyUser;
        }
        System.runAs(quipAccessUser) {
            //Account Creation
            Account acc = new Account();
            acc.Name = 'TestAccountPlan';
            acc.BillingCountry = 'India';
            acc.BillingState = 'DELHI';
            acc.website = 'www.AccountPlanWebsite.com';
            insert acc;
            //AccountTeamMember Creation
            AccountTeamMember atm = new AccountTeamMember();
            atm.AccountId = acc.Id;
            atm.UserId = anyUser.Id;
            atm.TeamMemberRole = 'Sales - Global Account Manager';
            insert atm;
            //Account Plan Template Mapping Creation
            Account_Plan_Template_Mapping__c  mapping = new Account_Plan_Template_Mapping__c ();
            mapping.Name = 'Media & Carrier';
            mapping.Template_URL__c = 'https://www.google.com';
            mapping.Language__c = 'English';
            insert mapping;
        }
    }
    
    @isTest static void accountPlanCreationTest(){
        User quipAccessUser = [Select Id, IsActive from User where Name  = 'Simone Stewart' AND IsActive = TRUE LIMIT 1][0];
        System.runAs(quipAccessUser) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
            Account_Plan__c plan1 = new Account_Plan__c ();
            plan1.Name = 'TestAccountPlan Plan 1';
            plan1.Account__c = acc.Id;
            plan1.Language__c = 'English';
            plan1.Plan_Start_Date__c = System.today() - 30;
            plan1.Plan_End_Date__c = System.today() + 120;
            Account_Plan__c plan2 = new Account_Plan__c ();
            plan2.Name = 'TestAccountPlan Plan 2';
            plan2.Account__c = acc.Id;
            plan2.Language__c = 'English';
            plan2.Plan_Start_Date__c = System.today() + 125;
            plan2.Plan_End_Date__c = System.today() + 150;
            Test.startTest();
            insert plan1;
            insert plan2;
            Account_Plan__c plan3 = plan1.clone(false, false, false, false);
            plan3.Plan_Start_Date__c = System.today() + 151;
            plan3.Plan_End_Date__c = System.today() + 200;
            insert plan3;
            Test.stopTest();
        }
    }
    
    @isTest static void syncToAccountTest(){
        User quipAccessUser = [Select Id, IsActive from User where Name  = 'Simone Stewart' AND IsActive = TRUE LIMIT 1][0];
        System.runAs(quipAccessUser) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
            Account_Plan__c plan1 = new Account_Plan__c ();
            plan1.Name = 'TestAccountPlan Plan 1';
            plan1.Account__c = acc.Id;
            plan1.Language__c = 'English';
            plan1.Plan_Start_Date__c = System.today() - 30;
            plan1.Plan_End_Date__c = System.today() + 120;
            Test.startTest();
            insert plan1;
            plan1.Account_Health__c = 'Red';
            update plan1;
            Test.stopTest();
        }
    }
    
    @isTest static void syncToAccountPlanTest(){
        User quipAccessUser = [Select Id, IsActive from User where Name  = 'Simone Stewart' AND IsActive = TRUE LIMIT 1][0];
        Account_Plan__c plan1 = new Account_Plan__c ();
        System.runAs(quipAccessUser) {
            Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
            plan1.Name = 'TestAccountPlan Plan 1';
            plan1.Account__c = acc.Id;
            plan1.Language__c = 'English';
            plan1.Plan_Start_Date__c = System.today() - 30;
            plan1.Plan_End_Date__c = System.today() + 120;
            Test.startTest();
            insert plan1;
            acc.Account_Health__c = 'Green';
            acc.Validation_Override__c = True;
            update acc;
            Test.stopTest();
        }
        System.runAs(dmlUser) {
            delete plan1;
        }
    }
    
    // provides coverage to AccountHealthDashboardRedirect
    @isTest static void AccountHealthDashboardRedirect(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
        PageReference pageRef = Page.AccountHealthDashboardRedirectPage;
        Test.setCurrentPageReference(pageRef);
        ApexPages.currentPage().getParameters().put('recordId',acc.Id);
        AccountHealthDashboardRedirect AccountHealthDashboard = new AccountHealthDashboardRedirect();
        AccountHealthDashboard.recordId = acc.Id;
        AccountHealthDashboard.init();
    }
    
    @isTest static void removeAccountPlanAccessTest(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = acc.Id;
        atm.UserId = UserInfo.getUserId();
        atm.TeamMemberRole = 'Sales - Global Account Manager';
        insert atm;
        Account_Plan__c plan = new Account_Plan__c ();
        plan.Name = 'TestAccountPlan Plan 1';
        plan.Account__c = acc.Id;
        plan.Language__c = 'English';
        plan.Plan_Start_Date__c = System.today() - 30;
        plan.Plan_End_Date__c = System.today() + 120;
        plan.Quip_New_Document_URL__c='www.google.com';
        Test.startTest();
        insert plan;
        delete atm;
        RemoveAccountPlanAccessBatch obj = new RemoveAccountPlanAccessBatch();
        Database.executeBatch(obj);
        Test.stopTest();
    }

    @isTest static void quipWeblinkRedirectionControllerTest(){
        Test.startTest();
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccountPlan' LIMIT 1][0];
        PageReference pageRef = Page.QuipWeblinkRedirection;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('recordId',acc.Id);
        pageRef.getParameters().put('dashboard','Account_Health_Dashboard');
        QuipWeblinkRedirectionController q = new QuipWeblinkRedirectionController();
        q.init();
        Test.stopTest();
    }
}