@isTest
public with sharing class PA_EscalationClassTestController {

    private static User CreateUser(String pUsrAlias, String pProfile, String pRole) {
        Profile pr = [select Id from Profile where Name = :pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name = :pRole][0];
        User newUser = new User(alias = pUsrAlias, email = pUsrAlias + '@akamai.com', emailencodingkey = 'UTF-8', lastname = 'NewOwner', languagelocalekey = 'en_US', localesidkey = 'en_US', timezonesidkey = 'America/Los_Angeles', username = pUsrAlias + '@akamai.com', profileid = pr.Id, UserRoleId = null);
        insert newUser;
        return newUser;
    }

    public static Account create_account() {
        Account acc_master = utilTestClass.CreateAccount('_AccMerge_TestCase_Master_');
        insert acc_master;
        return acc_master;

    }

    public static Product_Approvals__c create_PA() {
        Product_Approvals__c pac = new Product_Approvals__c();
        pac.Account__c = create_account().Id;
        pac.Status__c = 'PENDING-TECHNICAL';
        return pac;
    }

    public static PA_EscalationClass init1() {

        PA_EscalationClass pacc = new PA_EscalationClass();

        return pacc;
    }

    testmethod static void init_test() {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc_master = utilTestClass.CreateAccount('_AccMerge_TestCase_Master_');
        Product_Approvals__c pac = new Product_Approvals__c();
        pac.Account__c = acc_master.Id;
        PA_EscalationClass pacc = new PA_EscalationClass();
        PA_EscalationClass pal = new PA_EscalationClass();

        list < GSM_Custom_Settings__c > lstGSM = new list < GSM_Custom_Settings__c > ();

        GSM_Custom_Settings__c csGSMFields1 = new GSM_Custom_Settings__c();
        csGSMFields1.Name = 'CRM_Integration';
        csGSMFields1.Value__c = '005A0000001XPcD';
        lstGSM.add(csGSMFields1);

        insert lstGSM;

        Survey__c sc = new Survey__c();
        sc.Name = 'Sample survey';
        sc.Submit_Response__c = 'abc';
        insert sc;
        Approval_Workflow__c awc = new Approval_Workflow__c();
        awc.Name = 'Site Shield';
        awc.Survey__c = sc.Id;
        insert awc;
        pac.Approval_Workflow__c = awc.Id;
        pac.Escalation_Status__c = 'NEW';
        pac.Status__c = 'PENDING-APPROVAL';
        Insert pac;

        pac.Assigned_Time__c = System.Now().addHours(-500);
        Update pac;

        Test.startTest();
        String result = PA_EscalationClass.CronJobHandler();

        //changing assigned time and sending to second approval
        pac.Assigned_Time__c = System.Now().addHours(-400);
        pac.Escalation_Status__c = 'FIRST';
        Update pac;
        
        PA_EscalationClass.CronJobHandler();

        Test.stopTest();
    }

}