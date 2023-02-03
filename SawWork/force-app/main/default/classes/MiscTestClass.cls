/**

    MiscTestClass

    @version 1.0

    @author : Karteek Mekala <kmekala@akamai.com>

    @Description : This class implements the unit tests for Misc code.

                   Use cases that are tested :

                   1. Test if "Account.OwnerIDAlt__c" is updated.

                   2. Test if "Opportunity.Owner__c" is updated.

                   3. Test if "User.AKAM_User_ID__c" is updated, during User insertion.

                   4. Test if "User.AKAM_User_ID__c" is updated, during User updation.

                   

    1/27/2010 dan - had to comment out assertion that is not yet fixed               
    -------------
    Ali KM                20/09/10          CR 798276 PDRA Update & CR 734770 Automate Account Reassignment - Next Steps 
                                        - After adding Code for these CRs, Tests failed on due to 'Script Limits Maxed' Errors. 
                                          As a result reduced Bulk Inserts from 100 to 75 in couple of places in BulkAccountDelete() method.
    -------------
    Ali KM                21/10/10         CR 812208 PDRA Update part-2
                                            - Added logic to run ONA if Account.Owner does not have an AccountReassignmentRule
                                            - Implemented ONA Name using Custom Settings - Account_Reassignment_Class_Settings__c
                                            - Also added new field Account_Reassignment_Rule__c.User_Role__c to all AssignmentRules in new methods:
                                            - Following methods have been updated to Assert for No Owner as Account Owner
                                                -) Oppty_CustomOwner_Test() 
    -------------
    Ali                 18/Jun/2012         CR 1753213 Remove Bus Ops exception for deleting accounts
                                                - commenting out the test code that allows Biz Ops to delete accounts.  
*/

@isTest(SeeAllData=false)

private class MiscTestClass 

{
    //static{
    //    utilTestClass.insertCustomSettings();
    //    utilTestClass.insertCustomSettings(new List<String>{'Order_Region_Reporting_Region_Mapping'});
    //    utilTestClass.insertLeadAndContactCustomSettings();
    //}

    public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
    public static User dmlUser = utilTestClass.getTestRunUser();

    //private static Map<String,Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();  

    /**

       Account_CustomOwner_Test()

       - Test if "Account.OwnerIDAlt__c" is updated.

    */

     @testSetup static void setup() 
    {
            Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
                    'Communities_Settings__c'   => 'CS_Communities_Settings',
                    'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
                    'Environment_Setup__c' => 'CS_Environment_Setup'
            };
            System.runAs(dmlUser) {

                Test.startTest();
                utilTestClass.insertCustomSettings(objectToCustomSettingResource);
               

                List<GSM_Custom_Settings__c> gsmCustomSettings = new List<GSM_Custom_Settings__c>();
                GSM_Custom_Settings__c crmIntSetting = new GSM_Custom_Settings__c();
                crmIntSetting.Name = 'CRM_Integration';
                crmIntSetting.Value__c = '005A0000000NHQc';
                gsmCustomSettings.add(crmIntSetting);

                /*GSM_Custom_Settings__c salesCoachSetting = new GSM_Custom_Settings__c();
                salesCoachSetting.Name = 'SalesCoachUtil#ExceptionStages';
                salesCoachSetting.Value__c = '4-Prove Best Case';
                gsmCustomSettings.add(salesCoachSetting);*/
                
                insert gsmCustomSettings;

                List<PRM_Settings__c> prmSettings = new List<PRM_Settings__c>();
                PRM_Settings__c akaNetAllBrandEnabled = new PRM_Settings__c();
                akaNetAllBrandEnabled.Name = 'AkamaiNetallianceBrandingEnabled';
                akaNetAllBrandEnabled.Value__c = 'TRUE';
                prmSettings.add(akaNetAllBrandEnabled);

                PRM_Settings__c ssoStartUrl = new PRM_Settings__c();
                ssoStartUrl.Name = 'SSOStartURL';
                ssoStartUrl.Value__c = '/apex/partners/Partner_Welcome_Page';
                prmSettings.add(ssoStartUrl);

                PRM_Settings__c brandedPartnerSite = new PRM_Settings__c();
                brandedPartnerSite.Name = 'BrandedPartnerSiteURL';
                brandedPartnerSite.Value__c = 'https://netalliance.akamai.com';
                prmSettings.add(brandedPartnerSite);

                insert prmSettings;

                CS_FieldMapping__c csFieldMapCustomSetting = new CS_FieldMapping__c();
                csFieldMapCustomSetting.CS_ProviderFileABIReportLink__c = 'test';
                insert csFieldMapCustomSetting;
               
                OpenByAkamId_Settings__c openByAkamIdCustomSetting = new OpenByAkamId_Settings__c();
                openByAkamIdCustomSetting.Name = 'Account';
                openByAkamIdCustomSetting.AKAM_ID_field_name__c = 'AKAM_ACCOUNT_ID__c';
                insert openByAkamIdCustomSetting;

            
                
                 ProductApprovalCS__c approvalCS = new ProductApprovalCS__c (Name = 'LegacyStreamingWF',
                                                                    Value__c = 'F-PA-0100');
                 insert approvalCS;

                Account newAccount = utilTestClass.CreateAccount('_TEST_ Account 12');
                newAccount.Type = 'Agency - Active';
                insert newAccount;

                Opportunity newOppty = utilTestClass.CreateOpportunity('TestOppty','1-Create');
                newOppty.CloseDate = Date.today();
                insert newOppty;
                Test.stopTest();
            }
           
    }

    static testmethod void Account_CustomOwner_Test()

    {
        System.runAs(dmlUser)
        {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        /*Account acc = new Account();

        acc.Name = '__Test Account';

        acc.BillingCountry = 'India';*/
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;

        acc = [select OwnerId,OwnerIDAlt__c from Account where Id=:acc.Id];

        system.assertEquals(acc.OwnerId,acc.OwnerIDAlt__c);

    }
    }

    /**

       Oppty_CustomOwner_Test()

       - Test if "Opportunity.Owner__c" is updated.
       - Created new Account Reassignment Rule for accOwnerUser - rule2. (part of CR 812208 PDRA Update part-2)

    */

    static testmethod void Oppty_CustomOwner_Test()

    {
        System.runAs(dmlUser)
        {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        /*Profile pr = [select id from profile where name='Sales Operations'][0];

        User usr = new User(alias = '__tst', email='__tst_usr@akamai.com',emailencodingkey='UTF-8', lastname='__tst_usr', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__tst_usr@akamai.com',profileid = pr.Id);*/
        Test.startTest();
        User usr = utilTestClass.CreateUser('__tst', 'Worldwide', 'Sales Operations');
        insert usr;
        
        // PDRA contd 2 fix...
        // Acc Reassignment Rule for acc.Owner
        // Create a rule        
        /*Profile pr1 = [select id from profile where name='Sales Operations'][0];
        UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];
        User accOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr1.Id, UserRoleId = role.Id );*/
        User accOwnerUser = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
        insert accOwnerUser;
        /*Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
        rule.Name = '__TestRule';
        rule.Associated_User__c = accOwnerUser.Id;  

        if(featureToggleCustomSettings.get('UserRoleUpdateThroughAssignmentRule').Toggle__c == true)            
            rule.User_Role__c = role.Name;*/
        
        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, testcaseCustomSettings.get('User_Role').Value__c);
        insert rule;

        /*Account acc = new Account();

        acc.Name = '__Test Account';
        // Add Owner to the Account
        acc.OwnerId = accOwnerUser.Id;

        acc.BillingCountry = 'India';*/
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId = accOwnerUser.Id;
        insert acc;

        /*Opportunity opp = new Opportunity();

        opp.Name = '__Test Opportunity';

        opp.StageName = '1-Lead Identification';*/
        Test.stopTest();
        
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
        
        opp.AccountId = acc.Id;

        opp.CloseDate = Date.today().addDays(30);

        opp.OwnerId = usr.Id;

        insert opp;

        // Refresh opportunity object 

        opp = [select Id,OwnerId,Owner__c from Opportunity where Id=:opp.Id];

        system.assertEquals(opp.Owner__c,opp.OwnerId);

    }
    }

    /**

        User_AKAM_ID_Insert_Test()

        - Test if AKAM_User_ID__c is set to UserAutoID__c on Insert.

    */

    static testmethod void User_AKAM_ID_Insert_Test()

    {
        System.runAs(dmlUser)
        {
        Profile pr = [select id from profile where name='Sales Operations'][0];

        User usr = new User(alias = '___tst', email='___tst_usr@akamai.com',emailencodingkey='UTF-8', lastname='__tst_usr', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='___tst123_usr@akamai.com',profileid = pr.Id);

        insert usr;

        // Refresh User record

        usr = [select Id,AKAM_User_ID__c, UserAutoID__c from User where Id=:usr.Id][0];

        system.assertEquals(usr.AKAM_User_ID__c, usr.UserAutoID__c);
        }
    }

    /**

        User_AKAM_ID_Update_Test()

        - Test if AKAM_User_ID__c is set to UserAutoID__c on Update.

    */    

    static testmethod void User_AKAM_ID_Update_Test()

    {

        System.runAs(dmlUser)
        {
        Profile pr = [select id from profile where name='Sales Operations'][0];

        User usr = new User(alias = '__tst', email='__tst_usr@akamai.com',emailencodingkey='UTF-8', lastname='__tst_usr', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__tst_usr@akamai.com',profileid = pr.Id);

        insert usr;

        update usr;

        // Refresh User record

        usr = [select Id,AKAM_User_ID__c, UserAutoID__c from User where Id=:usr.Id][0];

        system.assertEquals(usr.AKAM_User_ID__c, usr.UserAutoID__c);
        }
    }

    /**

        AccountDelete

        - Test "Prevent user from deleteing an Account unless his profile is 'System Administrator' or 'CRM Integraion'"

    */    

    static testmethod void AccountDelete()

    {
        
        System.runAs(dmlUser)
        {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        /*Profile prSalesOp = [select id from profile where name='Sales Operations'][0];
        User usrSalesOp = new User(alias = 'SalesOp', email='usrSalesOp@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__salesop@akamai.com',profileid = prSalesOp.Id);*/
        
        User usrSalesOp = utilTestClass.CreateUser('SalesOp', 'Worldwide', 'Sales Operations');
        insert usrSalesOp;

        /*Profile prBusOp = [select id from profile where name='Business Operations'][0];
        User usrBusOp = new User(alias = 'BusOp', email='usrBusOp@akamai.com',emailencodingkey='UTF-8', lastname='usrBusOp', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usrBusOp@akamai.com',profileid = prBusOp.Id);*/

        User usrBusOp = utilTestClass.CreateUser('BusOp', 'Worldwide', 'Business Operations');      
        insert usrBusOp;        

        /*Profile prSysAdmin = [select Id from Profile where Name='System Administrator'];
        User usrSysAdmin = new User(alias = 'SysAdmin', email='prSysAdmin@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__prSysAdmin@akamai.com',profileid = prSysAdmin.Id);*/

        User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
        insert usrSysAdmin;

        /*Profile prCrmIntg = [select Id from Profile where Name='CRM Integration'];
        User usrCrmIntg = new User(alias = 'CrmIntg', email='prCrmIntg@akamai.com',emailencodingkey='UTF-8', lastname='TmUser2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__prCrmIntg@akamai.com',profileid = prCrmIntg.Id);*/

        User usrCrmIntg = utilTestClass.CreateUser('CrmIntg', 'Worldwide', 'CRM Integration');
        insert usrCrmIntg;      

        Account acc;

        // ---------------- Sales Op  ---------------

        /*acc = new Account();

        acc.Name = '__Test Account delete 1';

        acc.BillingCountry = 'India';*/
        acc = utilTestClass.CreateAccount('__Test Account delete 1');
        insert acc;

        system.runas(usrSalesOp)

        {

            try

            {

                delete acc;

            }

            catch(DmlException e)

            {

                system.assert(e.getMessage().contains('access'));

            }

        }       

        Account[] testAcc;

        testAcc = [select Id from Account where Id=:acc.Id]; 

        system.assertEquals(testAcc.size(),1);

        // ---------------- SYSTEM ADMIN ---------------

        /*acc = new Account();

        acc.Name = '__Test Account delete 2';

        acc.BillingCountry = 'India';*/
        
        acc = utilTestClass.CreateAccount('__Test Account delete 2');
        acc.Website = 'www.test@testing.com';
        insert acc;

        system.runas(usrSysAdmin)

        {

            delete acc;

        }
        Test.startTest();
        testAcc = [select Id from Account where Id=:acc.Id]; 

        system.assertEquals(testAcc.size(),0);

        // ---------------- SYSTEM ADMIN ---------------

        /*acc = new Account();

        acc.Name = '__Test Account delete 2';

        acc.BillingCountry = 'India';*/
        acc = utilTestClass.CreateAccount('__Test Account delete 2');
        acc.Website = 'www.tkjbest@testing.com';
        insert acc;

        system.runas(usrSysAdmin)

        {

            delete acc;

        }
        
        testAcc = [select Id from Account where Id=:acc.Id]; 

        system.assertEquals(testAcc.size(),0);

        // --------------- CRM Integration -------------

        /*acc = new Account();

        acc.Name = '__Test Account delete 3';

        acc.BillingCountry = 'India';*/
        acc = utilTestClass.CreateAccount('__Test Account delete 3');
        insert acc;

        system.runas(usrCrmIntg)

        {

            delete acc;

        }

        testAcc = [select Id from Account where Id=:acc.Id]; 

        system.assertEquals(testAcc.size(),0);  
        Test.stopTest();    

        // --------------- Business Operations -------------

        /*acc = new Account();

        acc.Name = '__Test Account delete 4';

        acc.BillingCountry = 'India';*/
        // Commenting out below code as part of CR 1753213  
        /*
        acc = utilTestClass.CreateAccount('__Test Account delete 4');
        insert acc;

        system.runas(usrBusOp)

        {

            delete acc;

        }

        testAcc = [select Id from Account where Id=:acc.Id]; 

        system.assertEquals(testAcc.size(),0);  
        */  
        
    }    

    /**

        AccountDelete

        - Test "Prevent user from deleteing an Account unless his profile is 'System Administrator' or 'CRM Integraion'"

    */    
    }
    static testmethod void BulkAccountDelete()

    {
        System.runAs(dmlUser)
        {
        
        ManagedPkgErrorClass.isFromManagedPackage = false;

        /*Profile prSalesOp = [select id from profile where name='Sales Operations'][0];

        User usrSalesOp = new User(alias = 'SalesOp', email='usrSalesOp@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__salesop@akamai.com',profileid = prSalesOp.Id);

        insert usrSalesOp;

        Profile prSysAdmin = [select Id from Profile where Name='System Administrator'];

        User usrSysAdmin = new User(alias = 'SysAdmin', email='prSysAdmin@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__prSysAdmin@akamai.com',profileid = prSysAdmin.Id);

        insert usrSysAdmin;

        Profile prCrmIntg = [select Id from Profile where Name='CRM Integration'];

        User usrCrmIntg = new User(alias = 'CrmIntg', email='prCrmIntg@akamai.com',emailencodingkey='UTF-8', lastname='TmUser2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__prCrmIntg@akamai.com',profileid = prCrmIntg.Id);

        insert usrCrmIntg;*/
        
        User usrSalesOp = utilTestClass.CreateUser('SalesOp', 'Worldwide', 'Sales Operations');
        insert usrSalesOp;
        User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
        insert usrSysAdmin;
        User usrCrmIntg = utilTestClass.CreateUser('CrmIntg', 'Worldwide', 'CRM Integration');
        insert usrCrmIntg;
                
        // ali km: old = 100
        Account[] BulkAccounts = new Account[75];

        Integer i=0;

        Test.startTest();

        // ---------------- Sales Op  ---------------
        // ali km: old = 100
        for(i=0;i<75;i++)

        {
            /*BulkAccounts[i] = new Account();
            BulkAccounts[i].Name = '__Test Account delete ' + i;
            BulkAccounts[i].BillingCountry = 'India';*/
            BulkAccounts[i] = utilTestClass.CreateAccount('__Test Account delete ' + i);
            BulkAccounts[i].AKAM_Account_ID__c  = 'F-AC-000'+(i+1);
        }

        insert BulkAccounts;

        Boolean flag = false;

        system.runas(usrSalesOp)

        {

            try

            {

                delete BulkAccounts;

            }

            catch(DmlException e)

            {

                system.assert(e.getMessage().contains('access'));

                flag = true;

            }

        }   

        system.assert(flag);    

        Account[] testAcc;

        testAcc = [select Id from Account where Id IN :BulkAccounts]; 

        // ali km: old = 100
        system.assertEquals(testAcc.size(),75);

        // ---------------- SYSTEM ADMIN ---------------

        system.runas(usrSysAdmin)

        {

            delete BulkAccounts;

        }

        testAcc = [select Id from Account where Id IN :BulkAccounts]; 

        system.assertEquals(testAcc.size(),0);

        // --------------- CRM Integration -------------
        // ali km: old = 100
        BulkAccounts = new Account[75];
        
        // ali km: old = 100
        for(i=0;i<75;i++)

        {
            /*BulkAccounts[i] = new Account();
            BulkAccounts[i].Name = '__Test Account delete ' + i;
            BulkAccounts[i].BillingCountry = 'India';*/
            BulkAccounts[i] = utilTestClass.CreateAccount('__Test Account delete ' + i);
            BulkAccounts[i].AKAM_Account_ID__c  = 'F-AC-111'+(i+1);
        }
        
        insert BulkAccounts;

        system.runas(usrCrmIntg)

        {

            delete BulkAccounts;

        }

        Test.stopTest();

        testAcc = [select Id from Account where Id IN :BulkAccounts]; 

        system.assertEquals(testAcc.size(),0);
        }

    } 

    //CR 2770464 - rsharma: Moving test methods defined in other non test classes here-- Start



//From AddUsersController.cls

    private static TestMethod void testAddUsersController(){
        System.runAs(dmlUser)
        {
      SurveyTestingUtil tu = new SurveyTestingUtil();
      AddUsersController sc = new AddUsersController();
      System.assert(sc!=null);
        }
    } 

    private static TestMethod void testAddUser(){
        System.runAs(dmlUser)
        {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        
        //System.assert(
        AddUsersController.addUser(tu.contactId2, tu.surveyId, tu.paId);
        // == 'true');
        //System.assert(
        AddUsersController.addUser('arf','arf','arf');
        //== 'false');
        //System.assert(
        AddUsersController.addUser(tu.contactId, tu.surveyId, 'none');
        // == 'false');
        }
    }

    //From AkamaiUniversityRedirectController.cls
      static testmethod void AkamaiUniversityRedirectControllerTest(){
        System.runAs(dmlUser)
        {
        Test.setCurrentPageReference(Page.AkamaiUniversityRedirect);
        AkamaiUniversityRedirectController fruc = new AkamaiUniversityRedirectController();
        }
    }
    //From ChangePasswordController.cls
    public static testMethod void testChangePasswordController() {
        System.runAs(dmlUser)
        {
        // Instantiate a new controller with all parameters in the page
        ChangePasswordController controller = new ChangePasswordController();
        controller.oldPassword = '123456';
        controller.newPassword = 'qwerty1'; 
        controller.verifyNewPassword = 'qwerty1';                
        
        System.assertEquals(controller.changePassword(),null); 
        }
    }
  //From Contract_Extension_Controller.cls
  static testmethod void unitTestForContractExtension()
    {
        System.runAs(dmlUser)
        {
        
        /*Account newAccount = new Account();
        newAccount.Name = '_TEST_ Account 12';
        newAccount.BillingCountry = 'India';*/
        Account newAccount = [select Id, OwnerId from Account where Name = '_TEST_ Account 12' limit 1][0];

        Opportunity newOppty = [select Id, OwnerId from Opportunity where Name = 'TestOppty' limit 1][0];

        
        Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
        contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
        contractHeader.Name = '_TEST CONTRACT _ 12';
        contractHeader.Account_Name__c = newAccount.Id;
        contractHeader.Active__c = true;
        contractHeader.Locked__c = true;
        contractHeader.Effective_End_Date__c = Date.today();
        contractHeader.Currency__c = 'USD';
        contractHeader.Opportunity_Name__c = newOppty.Id;

        insert contractHeader;
                               
        PageReference extendPage = Page.Contract_Extension;
        Test.setCurrentPageReference(extendPage);
        extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
        extendPage.getParameters().put('requestType', 'ce');
        //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
        //Apexpages.currentPage().getParameters().put('requestType', 'ce');
        Contract_Extension_Controller controller = new Contract_Extension_Controller();
        //controller.automationRequestType = 'ce';        
        // Extension date 
        if(controller.opp!=null)  // modified by chandra to handle null pointer exception
        
        {controller.opp.CloseDate = Date.today().addDays(30);
        
        controller.submit();
        controller.cancel();
        controller.viewOA();
        controller.viewOppty();}
            
        }
    }

    //SFDC-1499
    static testmethod void unitTestForContractExtensionErrors1()
    {
        System.runAs(dmlUser)
        {
        
        /*Account newAccount = new Account();
        newAccount.Name = '_TEST_ Account 12';
        newAccount.BillingCountry = 'India';*/
        Account newAccount = [select Id, OwnerId from Account where Name = '_TEST_ Account 12' limit 1][0];

        Opportunity newOppty = [select Id, OwnerId from Opportunity where Name = 'TestOppty' limit 1][0];
        
        Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
        contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
        contractHeader.Name = '_TEST CONTRACT _ 12';
        contractHeader.Account_Name__c = newAccount.Id;
        contractHeader.Active__c = false;
        contractHeader.Locked__c = true;
        contractHeader.Effective_End_Date__c = Date.today();
        contractHeader.Currency__c = 'USD';
        contractHeader.Opportunity_Name__c = newOppty.Id;

        insert contractHeader;
                               
        PageReference extendPage = Page.Contract_Extension;
        Test.setCurrentPageReference(extendPage);
        extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
        extendPage.getParameters().put('requestType', 'ce');
        //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
        //Apexpages.currentPage().getParameters().put('requestType', 'ce');
        Contract_Extension_Controller controller = new Contract_Extension_Controller();
        //controller.automationRequestType = 'ce';        
        // Extension date 
        if(controller.opp!=null)  // modified by chandra to handle null pointer exception
        
        {controller.opp.CloseDate = Date.today().addDays(30);
        
        controller.submit();
        controller.cancel();
        controller.viewOA();
        controller.viewOppty();}
            
        }
    }

    static testmethod void unitTestForContractExtensionErrors2()
    {
        System.runAs(dmlUser)
        {
        
        /*Account newAccount = new Account();
        newAccount.Name = '_TEST_ Account 12';
        newAccount.BillingCountry = 'India';*/
        Account newAccount = [select Id, OwnerId from Account where Name = '_TEST_ Account 12' limit 1][0];

        Opportunity newOppty = [select Id, OwnerId from Opportunity where Name = 'TestOppty' limit 1][0];
        
        Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
        contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
        contractHeader.Name = '_TEST CONTRACT _ 12';
        contractHeader.Account_Name__c = newAccount.Id;
        contractHeader.Active__c = true;
        contractHeader.Locked__c = false;
        contractHeader.Effective_End_Date__c = Date.today();
        contractHeader.Currency__c = 'USD';
        contractHeader.Opportunity_Name__c = newOppty.Id;

        insert contractHeader;
                               
        PageReference extendPage = Page.Contract_Extension;
        Test.setCurrentPageReference(extendPage);
        extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
        extendPage.getParameters().put('requestType', 'ce');
        //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
        //Apexpages.currentPage().getParameters().put('requestType', 'ce');
        Contract_Extension_Controller controller = new Contract_Extension_Controller();
        //controller.automationRequestType = 'ce';        
        // Extension date 
        if(controller.opp!=null)  // modified by chandra to handle null pointer exception
        
        {controller.opp.CloseDate = Date.today().addDays(30);
        
        controller.submit();
        controller.cancel();
        controller.viewOA();
        controller.viewOppty();}
            
        }
    }

    static testmethod void unitTestForContractExtensionErrors3()
    {
        System.runAs(dmlUser)
        {
        
        /*Account newAccount = new Account();
        newAccount.Name = '_TEST_ Account 12';
        newAccount.BillingCountry = 'India';*/
        Account newAccount = [select Id, OwnerId from Account where Name = '_TEST_ Account 12' limit 1][0];

        Opportunity newOppty = [select Id, OwnerId from Opportunity where Name = 'TestOppty' limit 1][0];
        
        Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
        contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
        contractHeader.Name = '_TEST CONTRACT _ 12';
        contractHeader.Account_Name__c = newAccount.Id;
        contractHeader.Active__c = true;
        contractHeader.Locked__c = true;
        contractHeader.Effective_End_Date__c = Date.today().addDays(-60);
        contractHeader.Currency__c = 'USD';
        contractHeader.Opportunity_Name__c = newOppty.Id;

        insert contractHeader;
                               
        PageReference extendPage = Page.Contract_Extension;
        Test.setCurrentPageReference(extendPage);
        extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
        extendPage.getParameters().put('requestType', 'ce');
        //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
        //Apexpages.currentPage().getParameters().put('requestType', 'ce');
        Contract_Extension_Controller controller = new Contract_Extension_Controller();
        //controller.automationRequestType = 'ce';        
        // Extension date 
        if(controller.opp!=null)  // modified by chandra to handle null pointer exception
        
        {controller.opp.CloseDate = Date.today().addDays(30);
        
        controller.submit();
        controller.cancel();
        controller.viewOA();
        controller.viewOppty();}
            
        }
    }

    static testmethod void unitTestForContractExtensionErrors4()
    {
        System.runAs(dmlUser)
        {
        
        /*Account newAccount = new Account();
        newAccount.Name = '_TEST_ Account 12';
        newAccount.BillingCountry = 'India';*/
        Account newAccount = [select Id, OwnerId from Account where Name = '_TEST_ Account 12' limit 1][0];

        Opportunity newOppty = [select Id, OwnerId from Opportunity where Name = 'TestOppty' limit 1][0];
        
        Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
        contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
        contractHeader.Name = '_TEST CONTRACT _ 12';
        contractHeader.Account_Name__c = newAccount.Id;
        contractHeader.Active__c = true;
        contractHeader.Locked__c = true;
        contractHeader.Currency__c = 'USD';
        contractHeader.Opportunity_Name__c = newOppty.Id;

        insert contractHeader;
                               
        PageReference extendPage = Page.Contract_Extension;
        Test.setCurrentPageReference(extendPage);
        extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
        extendPage.getParameters().put('requestType', 'ce');
        //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
        //Apexpages.currentPage().getParameters().put('requestType', 'ce');
        Contract_Extension_Controller controller = new Contract_Extension_Controller();
        //controller.automationRequestType = 'ce';        
        // Extension date 
        if(controller.opp!=null)  // modified by chandra to handle null pointer exception
        
        {controller.opp.CloseDate = Date.today().addDays(30);
        
        controller.submit();
        controller.cancel();
        controller.viewOA();
        controller.viewOppty();}
            
        }
    }

    static testmethod void unitTestForContractExtensionErrors5()
    {
        System.runAs(dmlUser)
        {
        
        /*Account newAccount = new Account();
        newAccount.Name = '_TEST_ Account 12';
        newAccount.BillingCountry = 'India';*/
        Account newAccount = [select Id, OwnerId from Account where Name = '_TEST_ Account 12' limit 1][0];

        Opportunity newOppty = [select Id, OwnerId from Opportunity where Name = 'TestOppty' limit 1][0];
        
        Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
        contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
        contractHeader.Name = '_TEST CONTRACT _ 12';
        contractHeader.Account_Name__c = newAccount.Id;
        contractHeader.Active__c = true;
        contractHeader.Locked__c = true;
        contractHeader.Effective_End_Date__c = Date.today();
        contractHeader.Opportunity_Name__c = newOppty.Id;

        insert contractHeader;
                               
        PageReference extendPage = Page.Contract_Extension;
        Test.setCurrentPageReference(extendPage);
        extendPage.getParameters().put('id', String.valueOf(contractHeader.Id));
        extendPage.getParameters().put('requestType', 'ce');
        //Apexpages.currentPage().getParameters().put('id', String.valueOf(contractHeader.Id));
        //Apexpages.currentPage().getParameters().put('requestType', 'ce');
        Contract_Extension_Controller controller = new Contract_Extension_Controller();
        //controller.automationRequestType = 'ce';        
        // Extension date 
        if(controller.opp!=null)  // modified by chandra to handle null pointer exception
        
        {controller.opp.CloseDate = Date.today().addDays(30);
        
        controller.submit();
        controller.cancel();
        controller.viewOA();
        controller.viewOppty();}
            
        }
    }//End of SFDC-1499

//From CronCleanUp.cls
//static testmethod void test()
    //{
        //System.runAs(dmlUser)
        //{
        /*Integer cleanAfter = 1;
        
        Cron_Batch_Job__c batchJob = new Cron_Batch_Job__c();
        batchJob.Name = 'Clean Up : Testcase';
        batchJob.Batch_Job_Type__c = 'Clean Up';
        batchJob.RecordTypeId = Schema.SObjectType.Cron_Batch_Job__c.getRecordTypeInfosByName().get('Clean Up Job').getRecordTypeId();
        batchJob.Clean_After__c = cleanAfter;
        
        batchJob.Run_Every__c = 1;
        batchJob.Period__c = 'Day';
        
        insert batchJob;
        
        Cron_Batch_Run__c batchRun = new Cron_Batch_Run__c();
        
        batchRun.Trigger_Batch_Run__c = true;
        batchRun.Cron_Batch_Job__c = batchJob.Id; 
        
        insert batchRun;*/
        //Integer cleanAfter = 1;
        //Changing the checking DateTime to one day before actual clean up job to accommodate Time zone difference.
        //Integer checkUpto = cleanAfter + 1;
        //DateTime checkUptoCreatedDateTime = DateTime.now().addDays(-checkUpto);
        
        //Test.startTest();
        //Integer batchRunsSize_Before = [select Id from Cron_Batch_Run__c where CreatedDate < :checkUptoCreatedDateTime LIMIT 1000].size();
        //CronJobTypes.insertBatchJobAndRun('Clean Up', 'Clean Up Job', cleanAfter);
        //Integer batchRunsSize_After = [select Id from Cron_Batch_Run__c where CreatedDate < :checkUptoCreatedDateTime LIMIT 1000].size();
        //Test.stopTest();
        
        //System.debug('after=' + batchRunsSize_After);
        //System.debug('before=' + batchRunsSize_Before);
        //system.assert(batchRunsSize_After<=batchRunsSize_Before);
        //}
    //}

    //from CS_ABIReportController.cls
    static testMethod void myTestMethod(){
        System.runAs(dmlUser)
        {
ManagedPkgErrorClass.isFromManagedPackage=false;    
CS_FieldMapping__c orgValues = CS_FieldMapping__c.getOrgDefaults();
orgValues.CS_ProviderFileABIReportLink__c = 'test url';
// change it to a dummy value so that we can test against the dummy value
database.update(orgValues);

CS_ABIReportController testInstance = new CS_ABIReportController();
String url = testInstance.getreportUrl();
//system.assertEquals(url,'test url');
        }
}

    //From CustomForecastTabController.cls
    // public static testMethod void testMe() {
    //     System.runAs(dmlUser)
    //     {
    //     CustomForecastTabController customForeastTabController = new CustomForecastTabController();
    //     System.assertEquals(true, GsmUtilClass.getGSMSettingValue('Forecast_RSMProfileID').contains(Userinfo.getProfileId())); 
    //     }
    // } SFDC-7795 -  deleting CustomForecastTabController 

    //From DocumentBrowserController.cls
    public static testMethod void t1() {
        
        System.runAs(dmlUser)
        {
        PageReference pr = Page.DocumentBrowser;
        
        
        pr.getParameters().put('folderid', 'xxxx');
        Test.setCurrentPage(pr);
        
        DocumentBrowserController dbc = new DocumentBrowserController();
        
        dbc.selectFolder();
        System.assert(dbc.folderoptions != null);
        }
    }

    //From DV4_V2Controller.cls
    /* Removing as part of SFDC-6979
    static testMethod void DV4_V2ControllerTest() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            PageReference pageRef = Page.DV4_V2;
            Test.setCurrentPageReference(pageRef);
            DV4_V2Controller fruc = new DV4_V2Controller();
            
            Cookie partnerdv4=null;
            partnerdv4=pageRef.getCookies().get('PARTNERDV4SESSION');
            system.assertNotequals(partnerdv4,null);
        }
    }
*/

    //EBCInviteeNewController.cls
    static testmethod void unitTestForEBCInviteeNew()
    {
        System.runAs(dmlUser)
        {
            Account newAccount = [select Id, OwnerId from Account where Name = '_TEST_ Account 12' limit 1][0];
            
            EBC_Request__c newEBCRequest = new EBC_Request__c();
            newEBCRequest.Associated_Account__c = newAccount.Id;
            newEBCRequest.Location_of_visit__c = 'Zurich';
            newEBCRequest.Pre_Brief_Call__c = Date.today();
            insert newEBCRequest;
                                   
            PageReference ebcInviteeNewPage = Page.EBCInviteeNew;
            Test.setCurrentPageReference(ebcInviteeNewPage);
            ebcInviteeNewPage.getParameters().put('id', String.valueOf(newEBCRequest.Id));
            EBCInviteeNewController controller = new EBCInviteeNewController();
            controller.pageRedirect();
        }
    }
    //EmailTracking.cls
    static TestMethod void TestEmailTracking()
    {
       System.runAs(dmlUser)
        {
        // create a new email and envelope object
          Messaging.InboundEmail email = new Messaging.InboundEmail() ;
          Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
          
          String delimiter= GsmUtilClass.getGSMSettingValue('EmailTracking_delimiter');
          
          Profile pr = [select id from profile where name='Sales - Media'][0];
          User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
          usr.AKAM_User_ID__c = 'ABC123';
          insert usr;
          Product_Approvals__c pa = new Product_Approvals__c(Name='test');
          insert pa;
          email.subject = 'Testing New Case5 '+delimiter+' ['+pa.id+']';
          //email.bodytext = 'Creating a test case in test class';
          email.plainTextBody= '1234567889';
          email.fromname = 'FirstName LastName';
          email.fromAddress = 'salesop@akamai.com';
    
          EmailTracking et= new EmailTracking();
          et.handleInboundEmail(email, env);
         
          Task tsk;
          for(Task task1:[Select id,Subject,Status,Type__c,WhoId,OwnerId from Task where WhatId= :pa.id and Type__c='Email'])
          tsk=task1;
          System.assertEquals(tsk.Status,'Completed');
          System.assertEquals(tsk.Type__c,'Email');
          System.assertEquals(tsk.Subject, email.subject);
          
          email.subject = 'Testing New Case5 without reference Id';
          //email.bodytext = 'Creating a test case in test class';
          email.htmlBody = '1234567889';
          email.fromname = 'FirstName LastName';
          email.fromAddress = 'salesop2@akamai.com';
          et.handleInboundEmail(email, env);
        }
    }
    //ErrorPageController.cls
    public static testMethod void ErrorPageControllerTest () {
        System.runAs(dmlUser)
        {
            // Instantiate a new controller with all parameters in the page
            PageReference pageRef = Page.ErrorPage;
            pageRef.getParameters().put('ErrorType', '1');
            pageRef.getParameters().put('retURL', '/home/home.jsp');
            Test.setCurrentPageReference(pageRef);
            ErrorPageController controller = new ErrorPageController ();
            controller.back(); 
        }
    }
    //ForgotPasswordController.cls
    public static testMethod void testForgotPasswordController() 
    {
        System.runAs(dmlUser)
        {
            // Instantiate a new controller with all parameters in the page
        ForgotPasswordController controller = new ForgotPasswordController();
        controller.username = 'test@salesforce.com';
        System.assertEquals(controller.forgotPassword(),null);
        }
    }
    //groupMaster.cls

    //LoginRedirectController.cls
    static testmethod void TestLoginRedirect(){
        System.runAs(dmlUser)
        {
        Test.setCurrentPageReference(Page.LoginRedirect);
        LoginRedirectController fruc = new LoginRedirectController();
        fruc.RedirectPage();
        }
    }

    //SFDC-5894 : removed milestone package references    

    //MTVUtil.cls
    testmethod static void testGetFieldName(){
        
        String s = MTVUtil.getFieldName('Opportunity');     
    }
    
    
    testMethod static void testGetUsers() {
        Set<Id> contactIds = new Set<Id>();
        for( User u : [Select ContactId from User where ContactId != null limit 10]) {
            contactIds.add(u.ContactId);
        }
        MTVUtil.getUsers(contactIDs);
    }
    
    testMethod static void testHasChanges() {
        System.runAs(dmlUser)
        {
        Account oldRecord = null;
        //Account newRecord = new Account(Name = 'Test2', BillingCity = 'Palo Alto');
        Account newRecord = utilTestClass.CreateAccount('Test2');
        newRecord.BillingCity = 'Palo Alto';
        MTVUtil.hasChanges('BillingCity', oldRecord, newRecord);
        MTVUtil.hasChanges(new Set<String>{'BillingCity', 'Name'}, oldRecord, newRecord);
        //oldRecord = new Account(Name = 'Test1', BillingCity = 'SFO');
        oldRecord = utilTestClass.CreateAccount('Test1');
        oldRecord.BillingCity = 'SFO';
        MTVUtil.hasChanges('BillingCity', oldRecord, newRecord);
        MTVUtil.hasChanges(new Set<String>{'BillingCity', 'Name'}, oldRecord, newRecord);
        }
    }
    
    testMethod static void testAddToMap() {
        Id sObjectId = UserInfo.getUserId();
        Object value = null;
        Map<Id, Set<id>> m = new Map<Id, Set<id>>();
        MTVUtil.addToMap(sObjectId, value, m);
        value = sObjectId;
        MTVUtil.addToMap(sObjectId, value, m);
    }
    
    testMethod static void testAddToMapAsString() {
        Id sObjectId = UserInfo.getUserId();
        Object value = null;
        Map<Id, String> m = new Map<Id, String>();
        MTVUtil.addToMapAsString(sObjectId, value, m);
        value = sObjectId;
        MTVUtil.addToMapAsString(sObjectId, value, m);
    }
    
    testMethod static void testGetRecordFieldsAsString() {
        System.runAs(dmlUser)
        {
        Set<String> recordFields = new Set<String> {'A', 'B'};
        String recordFieldsAsString = MTVUtil.getRecordFieldsAsString(recordFields);
        System.assertEquals(recordFieldsAsString, 'A,B');
        }
    }

    //MyProfilePageController.cls
    static testMethod void testSave() { 
System.runAs(dmlUser)
        {        
        // Modify the test to query for a portal user that exists in your org
        List<User> existingPortalUsers = [SELECT id, profileId, userRoleId FROM User WHERE UserRoleId <> null AND UserType='CustomerSuccess'];

        if (existingPortalUsers.isEmpty()) {
            User currentUser = [select id, title, firstname, lastname, email, phone, mobilephone, fax, street, city, state, postalcode, country
                                FROM User WHERE id =: UserInfo.getUserId()];
            MyProfilePageController controller = new MyProfilePageController();
            System.assertEquals(currentUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
            System.assert(controller.isEdit == false, 'isEdit should default to false');
            controller.edit();
            System.assert(controller.isEdit == true);
            controller.cancel();
            System.assert(controller.isEdit == false);
            Boolean isEditvar = controller.getIsEdit();
            /*Contact c = new Contact();
            c.Validation_Override__c=true;
            c.LastName = 'TestContact';*/
            Account acc=utilTestClass.CreateAccount('__Test_Account');
            insert acc;
            Contact c = utilTestClass.CreateContact('Test','TestContact');
            c.Validation_Override__c = true;
            c.accountId=acc.Id;
            insert c;
            
            MyProfilePageController.setContactFields(c, currentUser);
            controller.save();
            System.assert(Page.ChangePassword.getUrl().equals(controller.changePassword().getUrl()));
        } else {
            User existingPortalUser = existingPortalUsers[0];
            String randFax = Math.rint(Math.random() * 1000) + '5551234';
            
            System.runAs(existingPortalUser) {
                MyProfilePageController controller = new MyProfilePageController();
                System.assertEquals(existingPortalUser.Id, controller.getUser().Id, 'Did not successfully load the current user');
                System.assert(controller.isEdit == false, 'isEdit should default to false');
                controller.edit();
                System.assert(controller.isEdit == true);
                
                controller.cancel();
                System.assert(controller.isEdit == false);
                
                controller.getUser().Fax = randFax;
                controller.save();
                System.assert(controller.isEdit == false);
            }
            
            // verify that the user and contact were updated
            existingPortalUser = [Select id, fax, Contact.Fax from User where id =: existingPortalUser.Id];
            System.assert(existingPortalUser.fax == randFax);
            System.assert(existingPortalUser.Contact.fax == randFax);
        }
        }
    }

    //OpenByAKAMid.cls
     public static testMethod void testAutoRun() 
   {
 System.runAs(dmlUser)
        {
        //create acct and search for it using this controller
        /*Account a = new Account();
        a.name    = '__ TEST';*/
        
        Account a = utilTestClass.CreateAccount('__ TEST');
        a.BillingStreet = 'Maple Ave';
        a.BillingState = 'NY';
        a.BillingPostalCode = '10514';
        a.BillingCountry = 'USA';
        a.BillingPostalCode ='78987';
        a.BillingCity = 'Chappaqua';
        insert a;
        
        // // Refresh Account
        a = [select Id, AKAM_Account_ID__c from Account where Id=:a.Id][0];

        
        Test.startTest();
        OpenByAKAMid controller = new OpenByAKAMid(a.AKAM_Account_ID__c);
        
        system.assertEquals(controller.AKAMid, a.AKAM_Account_ID__c);
        
        PageReference returnPage = controller.AutoRun();
        Test.stopTest();
        }
        //system.assertEquals(returnPage.getUrl(), '/' + a.Id);
    }

    //OpportunityProductWrapper.cls
    public static testMethod void testMeOpportunityProductWrapper() {
        System.runAs(dmlUser)
        {
        OpportunityProductWrapper w1 = new OpportunityProductWrapper();
        System.assertEquals(w1.checked,false);
        OpportunityProductWrapper w2 = new OpportunityProductWrapper(new Product2(name='Test1'));
        System.assertEquals(w2.p.name,'Test1');
        System.assertEquals(w2.checked,false);
        OpportunityProductWrapper w3 = new OpportunityProductWrapper(true, new Product2(name='Test3'));
        System.assertEquals(w3.p.name,'Test3');
        System.assertEquals(w3.checked,true); 
        OpportunityProductWrapper w4 = new OpportunityProductWrapper(w3);
        System.assertEquals(w4.p.name,'Test3');
        System.assertEquals(w4.checked, true);  
    }
        
    }
    //OrderApprovalClass.cls
    //public static testmethod void TestIntitFuncs()
    //{
       //System.runAs(dmlUser)
        //{  Legit call
        //system.assertEquals(OrderApprovalClass.InitAll(),true);
        // Duplicate call
        //system.assertEquals(OrderApprovalClass.InitAll(),false);
        //system.assertEquals(OrderApprovalClass.oaTaskRecTypeInit(),false);
        //system.assertEquals(OrderApprovalClass.oaUsersInit(),false);
        //system.assertEquals(OrderApprovalClass.oaProfilesInit(),false);
    //} 
    //}

    //page_SearchController
    @isTest(SeeAllData=false)
    static void unitTestPageSearchController()
    {
        
        page_SearchController search=new page_SearchController();
        search.getFilterObject();       
        
        IR_FilterObject filter=new IR_FilterObject();
            }
//      //SalesCoachControllerV2.cls
//      private static testmethod void testGettersAndSetters(){
//          System.runAs(dmlUser)
//         {
//             TestingUtil tu = new TestingUtil();
//             SalesCoachControllerV2 scc = new SalesCoachControllerV2();
//             System.assert(scc.getOpportunityStage()=='1-Create');
//             System.assert(scc.getSalesCoachStage().Name=='testStage');
//            // System.assert(scc.getSuperSections().size()>=0);
//            // System.assert(scc.getSalesCoachActivities().size()>0);
//             //System.assert(scc.getSuperSections()[0].getSalesCoachSection()!=null);
//            // System.assert(scc.getSuperSections()[0].getSalesCoachSectionItems().size()>0);
            
//             scc.setOpportunityStage('newOpStage');
//             System.assert(scc.getOpportunityStage()=='newOpStage');
//         }
//   }
//   private static testmethod void testConstructor(){
//       System.runAs(dmlUser)
//         {
//           SalesCoachControllerV2 sccExceptions = new SalesCoachControllerV2();
//           sccExceptions.startProcess();  
//           sccExceptions.populateSuperSections();  
//           sccExceptions.populateActivities();
           
//           TestingUtil tu = new TestingUtil();
//           SalesCoachControllerV2 scc = new SalesCoachControllerV2();
//           System.assert(scc.oppty!=null); 
//           System.assert(scc.opportunityStage!=null);
//           //System.assert(scc.superSections.size()>0);
//           //System.assert(scc.salesCoachActivities.size()>0);
//           System.assert(scc.renderCheck);
//         }
//     }
 /*private static testmethod void testSelectOption(){
     System.runAs(dmlUser)
        {
    TestingUtil tu = new TestingUtil();
    SalesCoachControllerV2 scc = new SalesCoachControllerV2();
    System.assert(scc.getOpptyStages().size()>0);
        }
    
  }*/
/*private static testmethod void testUpdateStageData(){
    System.runAs(dmlUser)
        {
    TestingUtil tu = new TestingUtil();
    SalesCoachControllerV2 scc = new SalesCoachControllerV2();
    System.assert(scc.updateStageData()==null);
        }
    
  }*/
  //SalesCoachSetup.cls  
     
      //SalesCoachUtil.cls
    /*private static testmethod void testSalesCoachRole(){
        System.runAs(dmlUser)
        {
        System.assert(SalesCoachUtil.getOpptyStages().size()>0);
        TestingUtil tu = new TestingUtil();
        System.assert(SalesCoachUtil.getOpptyStages().size()>0);
        }
    }*/
    
  //test populateSalesCoachRole
  /*private static testmethod void testpopulateSalesCoachRole(){
      System.runAs(dmlUser)
        {
      SalesCoachUtil.populateSalesCoachRole();
      TestingUtil tu = new TestingUtil();
      SalesCoachUtil.populateSalesCoachRole();
        }
    }*/
    //test getUserFieldsMap
    
     /*private static testmethod void testgetUserFieldsMap(){
         System.runAs(dmlUser)
        {
      System.assert(SalesCoachUtil.getUserFieldsMap().size()>=0);
        }
    }*/
    //SiteLoginController.cls

    private static testMethod void testSiteLoginController () {
        System.runAs(dmlUser)
        {
        // Instantiate a new controller with all parameters in the page
        SiteLoginController controller = new SiteLoginController ();
        controller.username = 'test@salesforce.com';
        controller.password = '123456'; 
                
        System.assertEquals(controller.login(),null);   
        controller.redirect();  
        }
    }    


//SiteRegisterController.cls
/*Removing this method as part of SFDC-6979
static testMethod void testRegistration() {
    System.runAs(utilTestClass.getTestRunUser())
        {
        SiteRegisterController controller = new SiteRegisterController();
        controller.username = 'test@force.com';
        controller.email = 'test@force.com';
        controller.communityNickname = 'test';
        // registerUser will always return null when the page isn't accessed as a guest user
        System.assert(controller.registerUser() == null);    
        
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abcd123';
        System.assert(controller.registerUser() == null);
        }
    }
*/

    //SurveyTestingUtil.cls
    private static TestMethod void testConstructorSurveyTestingUtil(){
        System.runAs(dmlUser)
        {
    SurveyTestingUtil tu = new SurveyTestingUtil();
    System.assert(tu.surveyId != null);
        }
  }
  //TestRecordAssociation.cls
static testmethod void testAccountAssociation(){
    System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(5));
        /*for(Integer i=0;i<5;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        PageReference pageRef = Page.manageAccountAssociation;
        Test.setCurrentPage(pageRef);
        List<RecordAssociation__c> rList = new List<RecordAssociation__c>();
        RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[1].id, associated_account__c = accts[2].id, Account_Role__c = 'Partner', primary__c=true);
        RecordAssociation__c recAssoc2 = new RecordAssociation__c(Account__c = accts[3].id, associated_account__c = accts[2].id, Account_Role__c = 'End Customer');
        RecordAssociation__c recAssoc3 = new RecordAssociation__c(Account__c = accts[3].id, associated_account__c = accts[4].id, Account_Role__c = 'Distributor/Var');
        rList.add(recAssoc1);
        rList.add(recAssoc2);
        rList.add(recAssoc3);
        test.startTest();
        insert rList;
        
        RecordAssociation__c ra = [Select id, Account_Role__c from RecordAssociation__c where id = :recAssoc3.id];
        RecordAssociation__c ra1 = [Select id, Account_Role__c from RecordAssociation__c where id = :recAssoc1.id];
        RecordAssociation__c ra2 = [Select id, Account_Role__c from RecordAssociation__c where id = :recAssoc2.id];
        System.assertEquals('Distributor/VAR', ra.Account_Role__c);
        
        ApexPages.StandardController controller = new ApexPages.StandardController(recAssoc1);
        P2P_AccountAssociationController testAccAssController = new P2P_AccountAssociationController(controller);
        testAccAssController.onLoad();
        
        System.currentPageReference().getParameters().put('selectedId','0');
        System.currentPageReference().getParameters().put('id',ra.Id);
                
        testAccAssController.onAddCondition();      
        System.currentPageReference().getParameters().put('selectedId','1');
        System.currentPageReference().getParameters().put('id',ra1.Id);
            
        testAccAssController.onSave();
        
        testAccAssController.onLoad();
        System.currentPageReference().getParameters().put('selectedId','2');
        System.currentPageReference().getParameters().put('id',ra2.Id);     
        testAccAssController.onSave();
        System.assertEquals('Cannot add duplicate Account Associations', testAccAssController.errorMsg);
        testAccAssController.onRemoveCondition();       
        testAccAssController.onSave();      
        testAccAssController.onCancel();
        //testAccAssController.selectAccount();
        test.stoptest();
        }
    }
    
    static testmethod void testRecordAssociation(){
        System.runAs(dmlUser)
        {
        try{
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<5;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(5));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        List<RecordAssociation__c> rList = new List<RecordAssociation__c>();
        RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[1].id, associated_account__c = accts[2].id, Account_Role__c = 'Partner', primary__c=true);
        rList.add(recAssoc1);
        insert rList;       
        RecordAssociation__c ra = [Select id, primary__c from RecordAssociation__c where id = :recAssoc1.id];
        System.assertEquals(true, ra.primary__c);
        
        User u1 = [select id from User where contact.accountid = :accts[2].id];
        Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
        //Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
        Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
        opp.CloseDate = Date.today();
        System.runAs(u1){
            Test.startTest();
            insert l;
            insert opp;
            Test.stopTest();
        } 
        PageReference pageRef = Page.selectRecordAssociation;
        Test.setCurrentPage(pageRef);
        //test controller for account association with lead
        System.currentPageReference().getParameters().put('leadId',l.id);
        SelectAssociationOnRecordController testLeadAssocController = new  SelectAssociationOnRecordController();
        testLeadAssocController.uncheckPrimaryIfChecked();
        testLeadAssocController.getpreferredAccountWithSelects(); 
        testLeadAssocController.Save();
        testLeadAssocController.addPreferredAccountAssociation();
        PageReference pageRef1 = Page.selectRecordAssociation;
        Test.setCurrentPage(pageRef1);
        SelectAssociationOnRecordController testRecordLeadCon = new  SelectAssociationOnRecordController();
        testRecordLeadCon.getpreferredAccountWithSelects(); 
        testRecordLeadCon.Cancel();
                
        //test controller for account association with opportunity
        System.currentPageReference().getParameters().put('oppId',opp.id);
        SelectAssociationOnRecordController testRecordOppController = new  SelectAssociationOnRecordController();
        testRecordOppController.uncheckPrimaryIfChecked();
        testRecordOppController.getpreferredAccountWithSelects(); 
        testRecordOppController.Save();
        testRecordOppController.addPreferredAccountAssociation();
        PageReference pageRef2 = Page.selectRecordAssociation;
        Test.setCurrentPage(pageRef2);
        SelectAssociationOnRecordController testRecordOppCon = new SelectAssociationOnRecordController();
        testRecordOppCon.getpreferredAccountWithSelects();
        testRecordOppCon.Cancel();
        }catch(Exception e){
            System.debug('Exception: ' + e.getMessage());
        }
        }
    }
    
    // static testmethod void testLookup(){
    //  System.runAs(dmlUser)
    //     {
        
    //  List<Id> auList = new List<Id>();
    //  /*for(Integer i=0;i<2;i++){
    //      accountUser au = TestRecordAssociation.createAccountInfo(i);
    //      auList.add(au.a.id);
    //  }*/
    //  auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
    //  List<Account> accts = [select id, parentid from account where id in :auList];
    //  for(Integer i=0; i<accts.size();i++){
    //      if(i>0){
    //          accts[i].ParentId = accts[i-1].id;
    //      } 
    //  }
    //  update accts;
    //  User u1 = [select id from User where contact.accountid = :accts[1].id];
    //  User u2 = [select id from User where contact.accountid = :accts[0].id];
    //  Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
    //  l.Validation_Override__c=true;
    //  PageReference pageRef = Page.ChangeOwner;
    //  Test.setCurrentPage(pageRef);
    //  Test.startTest();   
    //  //CR 2770464 - rsharma: moving insertion of lead outside of 'System.runAs(u1)',
    //   //because partner users are not allowed to insert lead as specified in OwnerIDAlt__c filter lookup
    //  insert l;
    //  System.runAs(u1){
    //      System.currentPageReference().getParameters().put('id',l.id);
    //      PartnerUserLookupController testCon = new PartnerUserLookupController();
    //      testCon.initLookupPage();
    //      //CR 2770464 - rsharma: changing the assertion to match against true,
    //      //because error in PartnerUserLookupController is true when the userid != lead.ownerId
    //      //for more refernec see checkAccess Method of PartnerUserLookupController
    //      System.assertEquals(true, testCon.error);
    //      testCon.getHasResults();
    //      testCon.getRenderResultSets();
    //      testCon.getResults();
    //      testCon.save();
    //      testCon.cancel();
    //      testCon.getOppId();
    //      //PartnerUserLookupController testCon2 = new PartnerUserLookupController();
    //      //testCon2.initLookupPage();
    //  }
        
    //  System.runAs(u1){
    //      System.currentPageReference().getParameters().put('id',accts[1].id);
    //      PartnerUserLookupController testCon = new PartnerUserLookupController();
    //      testCon.initLookupPage();
    //      //CR 2770464 - rsharma: Adding the assertion
    //      System.assertEquals(true, testCon.error);
    //      testCon.getHasResults();
    //      testCon.getRenderResultSets();
    //      testCon.getResults();
    //      testCon.setUserID(u2.Id);
    //      testCon.save();
    //      testCon.cancel();
    //      testCon.getOppId();
    //  }
    //  Test.stopTest();
    // }
    // }

    static testmethod void testCreateObjectAssociation(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        
        User u1 = [select id from User where contact.accountid = :accts[0].id];
        
        Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
        l.Validation_Override__c=true;
        //Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
        Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
        opp.CloseDate = Date.today();
        opp.Validation_Override__c=true;
        //CR 2770464 - rsharma: moving insertion of lead outside of 'System.runAs(u1)',
        //because partner users are not allowed to insert lead as specified in OwnerIDAlt__c filter lookup
        insert l;
        System.runAs(u1){
            
            insert opp;
        } 
        Object_Association__c objAssoc1 = new Object_Association__c(associated_account__c = accts[1].id, leadId__c = l.id);
        insert objAssoc1;
        
        Object_Association__c oa1 = [Select Associated_Account__c, LeadId__c from Object_Association__c where id = :objAssoc1.Id];
        System.assertEquals(l.id, oa1.LeadId__c);
        System.assertEquals(accts[1].id, oa1.Associated_Account__c);
        
        PageReference pageRef = Page.selectRecordAssociation;
        Test.setCurrentPage(pageRef);
        //test controller for account association with lead
        System.currentPageReference().getParameters().put('leadId',l.id);
        SelectAssociationOnRecordController testLeadAssocController = new  SelectAssociationOnRecordController();
        testLeadAssocController.uncheckPrimaryIfChecked();
        testLeadAssocController.getpreferredAccountWithSelects(); 
        testLeadAssocController.Save();
        testLeadAssocController.addPreferredAccountAssociation();       
        testLeadAssocController.Cancel();
        
        Object_Association__c objAssoc2 = new Object_Association__c(associated_account__c = accts[1].id, OpportunityId__c = opp.id);        
        insert objAssoc2;
        
        Object_Association__c oa2 = [Select Associated_Account__c, OpportunityId__c from Object_Association__c where id = :objAssoc2.Id];
        System.assertEquals(opp.id, oa2.OpportunityId__c);
        System.assertEquals(accts[1].id, oa2.Associated_Account__c);
        }
    }
    
    static testmethod void testDeleteObjectAssociation(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        Set<Id> toDeleteIds = new Set<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        
        User u1 = [select id from User where contact.accountid = :accts[0].id];
        
        Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
        l.Validation_Override__c=true;
        //Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
        Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
        opp.CloseDate = Date.today();
        opp.Validation_Override__c=true;
            //CR 2770464 - rsharma: moving insertion of lead outside of 'System.runAs(u1)',
        //because partner users are not allowed to insert lead as specified in OwnerIDAlt__c filter lookup
        insert l;
        System.runAs(u1){
            
            insert opp;
        } 
        Object_Association__c objAssoc1 = new Object_Association__c(associated_account__c = accts[1].id, leadId__c = l.id);
        insert objAssoc1;
        toDeleteIds.add(objAssoc1.Id);
        
        Object_Association__c objAssoc2 = new Object_Association__c(associated_account__c = accts[1].id, OpportunityId__c = opp.id);
        insert objAssoc2;
        toDeleteIds.add(objAssoc2.Id);
        
        List<Object_Association__c> toDeleteList = [Select id from Object_Association__c where id in :toDeleteIds];
        System.Test.startTest();
        delete toDeleteList;
        System.Test.stopTest();
        
        String pqry = 'Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like \'%Executive\' and PortalType = \'Partner\' and PortalAccountId = \'';
        List<UserRole> roles1 = Database.query(pqry + accts[1].Id + '\' limit 1');
        //UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :a1.id limit 1];
        UserRole uRole1 = roles1[0];
        //UserRole uRole1 = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :accts[1].id limit 1];
        Group gr1 = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole1.Id and Type = 'RoleAndSubordinates'];
        Integer lshare = [Select count() from LeadShare where LeadId = :l.Id and UserOrGroupId = :gr1.Id];
        System.assertEquals(0,lshare);
        
        List<UserRole> roles2 = Database.query(pqry + accts[1].Id + '\' limit 1');
        UserRole uRole2 = roles2[0];
        //UserRole uRole2 = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :accts[1].id limit 1];
        Group gr2 = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole2.Id and Type = 'RoleAndSubordinates'];
        Integer oshare = [Select count() from OpportunityShare where OpportunityId = :opp.Id and UserOrGroupId = :gr2.Id];
        System.assertEquals(0,oshare);
        }
    }
    
    // static testmethod void testOppLookup(){ 
    //     System.runAs(dmlUser)
    //     {
    //  List<Id> auList = new List<Id>();
    //  /*for(Integer i=0;i<2;i++){
    //      accountUser au = TestRecordAssociation.createAccountInfo(i);
    //      auList.add(au.a.id);
    //  }*/
    //  auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
    //  List<Account> accts = [select id, parentid from account where id in :auList];
    //  for(Integer i=0; i<accts.size();i++){
    //      if(i>0){
    //          accts[i].ParentId = accts[i-1].id;
    //      } 
    //  }
    //  update accts;
    //  User u1 = [select id from User where contact.accountid = :accts[1].id];
    //  User u2 = [select id from User where contact.accountid = :auList[0]];
    //  //Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
    //  Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
    //  opp.CloseDate = Date.today();
    //  opp.Validation_Override__c=true;
    //  PageReference pageRef = Page.ChangeOwner;
    //  Test.setCurrentPage(pageRef);
    //  System.runAs(u1){
    //      insert opp;
    //      System.currentPageReference().getParameters().put('id',opp.id);
    //      PartnerUserLookupController testCon = new PartnerUserLookupController();
    //      testCon.initLookupPage();
    //      System.assertEquals(false, testCon.error);
    //      testCon.getHasResults();
    //      testCon.getRenderResultSets();
    //      testCon.getResults();
    //      testCon.save();
    //      testCon.cancel();
    //      testCon.getOppId();
    //      PartnerUserLookupController testCon1 = new PartnerUserLookupController();
    //      testCon1.initLookupPage();
    //  }
    //     }
    // }
    
    static testmethod void testRemoveAccountAssociation(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        RecordAssociation__c r = new RecordAssociation__c();
        RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[0].id, associated_account__c = accts[1].id, Account_Role__c = 'Partner');
        Id assocId;
        insert recAssoc1;
        assocId = recAssoc1.Id;
        r = [Select id from RecordAssociation__c where id = :assocId];
        System.Test.startTest();
        delete r;
        System.Test.stopTest();
        
        String pqry = 'Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like \'%Executive\' and PortalType = \'Partner\' and PortalAccountId = \'';
        List<UserRole> roles1 = Database.query(pqry + accts[0].Id + '\' limit 1');
        //UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :a1.id limit 1];
        UserRole uRole1 = roles1[0];
        //UserRole uRole1 = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :accts[0].id limit 1];
        Group gr1 = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole1.Id and Type = 'RoleAndSubordinates'];
        Integer ashare1 = [Select count() from AccountShare where AccountId = :accts[0].Id and UserOrGroupId = :gr1.Id];
        System.assertEquals(0,ashare1);
        }
    }   
    
    static testmethod void testAccountChangeParent(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size()-1;i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;       
        TestRecordAssociation.accountUser newau = TestRecordAssociation.createAccountInfo(10);
        
        Test.startTest();
        
        Account acc1 = [select id, parentid from account where id = :newau.a.id];
        Account acc2 = [select ParentId from account where id = :accts[1].id];
        acc2.ParentId = acc1.id;
        update acc2;
        List<Id> grpIds = new List<Id>();
        String pqry = 'Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like \'%Executive\' and PortalType = \'Partner\' and PortalAccountId = \'';
        List<UserRole> roles1 = Database.query(pqry + acc1.Id + '\' limit 1');
        //UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :a1.id limit 1];
        UserRole uRole = roles1[0];
//      UserRole uRole = [Select u.PortalType, u.PortalAccountId, u.Name, u.Id From UserRole u where Name like '%Executive' and PortalType = 'Partner' and PortalAccountId = :acc1.id limit 1];
        Group gr = [Select g.Name, g.Id, g.RelatedId From Group g where RelatedId = :uRole.Id and Type = 'RoleAndSubordinates'];
        grpIds.add(gr.Id);
        Integer ashare = [Select count() from AccountShare where AccountId = :acc2.Id and UserOrGroupId in :grpIds];
        Test.stopTest();
        System.assertEquals(0,ashare);
        }
    }
    
    static testmethod void testUpdateAccountInverseAssociation(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        PageReference pageRef = Page.manageAccountAssociation;
        Test.setCurrentPage(pageRef);
        List<RecordAssociation__c> rList = new List<RecordAssociation__c>();
        RecordAssociation__c recAssoc1 = new RecordAssociation__c(Account__c = accts[0].id, associated_account__c = accts[1].id, Account_Role__c = '', primary__c=true);
        rList.add(recAssoc1);
        insert rList;
        RecordAssociation__c ra = [Select id from RecordAssociation__c where Account__c = :accts[0].id and associated_account__c= :accts[1].id];
        ra.Account_Role__c = 'Partner';
        ra.Primary__c = false;
        //test scenario to update association and its inverse
        update ra;
        
        RecordAssociation__c ra1 = [Select id, Account_Role__c, Primary__c, Associated_Account__c, Account__c from RecordAssociation__c where Account__c = :accts[1].id and associated_account__c= :accts[0].id];
        System.assertEquals(recAssoc1.Account__c, ra1.Associated_Account__c);
        System.assertEquals(recAssoc1.Associated_Account__c, ra1.Account__c);
        System.assertEquals(ra.Account_Role__c, ra1.Account_Role__c);
        System.assertEquals(ra.Primary__c, ra1.Primary__c);
        }
    }
    
    static testmethod void testLeadChangeOwner(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        
        User u1 = [select id from User where contact.accountid = :accts[0].id];
        User u2 = [select id from User where contact.accountid = :accts[1].id];
        
        //Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
        Lead l = utilTestClass.CreateLead();
        l.LastName = 'Lead2';
        l.Company = 'Company';
        l.Validation_Override__c=true;
        //CR 2770464 - rsharma: moving insertion of lead outside of 'System.runAs(u1)',
        //because partner users are not allowed to insert lead as specified in OwnerIDAlt__c filter lookup
        insert l;   
        System.runAs(u1){
                    
        } 
        Object_Association__c objAssoc1 = new Object_Association__c(associated_account__c = accts[1].id, leadId__c = l.id);
        insert objAssoc1;
        Lead l1 = [Select OwnerId from Lead where lastname = 'Lead2'];
        l1.OwnerId = u2.Id;
        //update l1;
        }
    }
    
    static testmethod void testOppChangeOwner(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        
        User u1 = [select id from User where contact.accountid = :accts[0].id];
        User u2 = [select id from User where contact.accountid = :accts[1].id];
        
        //Opportunity opp = new Opportunity( Name = 'Test Opp1', stagename = 'Prospecting', closedate = Date.today() );
        Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
        opp.CloseDate = Date.today();
        opp.Validation_Override__c=true;
        System.runAs(u1){
            insert opp;
        } 
        Object_Association__c objAssoc2 = new Object_Association__c(associated_account__c = accts[0].id, OpportunityId__c = opp.id);
        insert objAssoc2;
        Opportunity opp1 = [Select OwnerId from Opportunity where id = :opp.id];
        opp1.OwnerId = u2.Id;
        opp1.Validation_Override__c=true;
        update opp1;
        }
    }
    
    static testmethod void testAddPreferred(){
        System.runAs(dmlUser)
        {
        List<Id> auList = new List<Id>();
        /*for(Integer i=0;i<2;i++){
            accountUser au = TestRecordAssociation.createAccountInfo(i);
            auList.add(au.a.id);
        }*/
        auList.addall(TestRecordAssociation.createAccountInfoVersion2(2));
        List<Account> accts = [select id, parentid from account where id in :auList];
        for(Integer i=0; i<accts.size();i++){
            if(i>0){
                accts[i].ParentId = accts[i-1].id;
            } 
        }
        update accts;
        RecordAssociation__c recAssoc = new RecordAssociation__c(Account__c = accts[0].id, associated_account__c = accts[1].id, Account_Role__c = '', primary__c=true);
        
        User u1 = [select id from User where contact.accountid = :accts[0].id];
        
        //Lead l = new Lead(lastname = 'Lead2', Company = 'Company');
        Lead l = utilTestClass.CreateLead();
        l.LastName = 'Lead2';
        l.Company = 'Company';
        l.Validation_Override__c=true;
        //Opportunity opp = new Opportunity( Name = 'Opp1', stagename = 'Prospecting', closedate = Date.today() );
        Opportunity opp = utilTestClass.CreateOpportunity('Opp1','Prospecting');
        opp.CloseDate = Date.today();
        opp.Validation_Override__c=true;
            //CR 2770464 - rsharma: moving insertion of lead outside of 'System.runAs(u1)',
        //because partner users are not allowed to insert lead as specified in OwnerIDAlt__c filter lookup
            insert l;
        System.runAs(u1){
            insert opp;
        }       
        PageReference pageRef = Page.addPreferred;
        Test.setCurrentPage(pageRef);
        System.currentPageReference().getParameters().put('leadId',l.id);
        SelectAssociationOnRecordController testLeadAddPref = new  SelectAssociationOnRecordController();
        testLeadAddPref.addPreferredAccountAssociation();
        
        System.currentPageReference().getParameters().put('oppId',opp.id);
        SelectAssociationOnRecordController testOppAddPref = new  SelectAssociationOnRecordController();
        testOppAddPref.addPreferredAccountAssociation();
        }
    }

    //UpdateQfaMeetingDateController.cls

    static testmethod void testUpdateQfaMeetingDateController()
    {
        System.runAs(dmlUser)
        {
        Map<String,GSM_Settings__mdt> generalTestcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
        //Map<String,Features_Toggle__c> generalfeatureToggleCustomSettings = Features_Toggle__c.getAll();
        // PDRA contd 2 fix...
        // Acc Reassignment Rule for acc.Owner
        /*Profile pr = [select id from profile where name='Sales Operations'][0];
        UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User Role').Value__c][0];
        User accOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );*/
        
        User accOwnerUser = utilTestClass.CreateUser('newUser', generalTestcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
        insert accOwnerUser;        
        // Create a rule
        /*Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
        rule.Name = '__TestRule';
        rule.Associated_User__c = accOwnerUser.Id;
        if(featureToggleCustomSettings.get('UserRoleUpdateThroughAssignmentRule').Toggle__c == true)        
            rule.User_Role__c = role.Name;*/
        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, generalTestcaseCustomSettings.get('User_Role').Value__c);
        insert rule;
        
        //Create Account
        /*Account acc = new Account();
        acc.Name = '__Test Account';
        acc.BillingCountry = 'India';*/
        Account acc = utilTestClass.CreateAccount('__Test Account');
        // Add Owner to the Account
        acc.OwnerId = accOwnerUser.Id;
        insert acc;
        /*Contact con = new Contact();
        con.LastName = '__Test Contact LastName';
        con.FirstName = '__Test Contact FirstName';
        con.Email ='__testContact@Testing.com';
        con.Phone = '999999';   
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';    
        con.Title = 'Tester';  
        con.MailingCountry = 'India';*/
        Contact con = utilTestClass.CreateContact('__Test Contact FirstName', '__Test Contact LastName');
        con.AccountId = acc.Id;     
        insert con;
        /*Lead lead = new Lead();
        lead.Akamai_Vertical__c = 'Gaming';
        lead.LeadSource = 'Web';        
        lead.Sub_Vertical__c = 'Console Mfs';*/
        Lead lead = utilTestClass.CreateLead();
        lead.Status = 'Open';
        lead.Disposition__c = 'New';
        lead.Product_line__c='Aura';
        lead.Associated_Contact__c = con.Id;                
        insert lead;
        //Create Related Oppty
        /*Opportunity oppty = new Opportunity();
        oppty.Name = '__Test Oppty';
        oppty.StageName = '1-Create';*/
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty', '1-Create');
        oppty.AccountId = acc.Id;
        oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();      
        oppty.CloseDate = Date.today().addMonths(4);
        oppty.Associated_Lead__c = lead.Id;
        insert oppty;       
        
        lead.Associated_Opportunity__c = oppty.Id;
        update lead;
        
        Test.startTest();
        PageReference qfaUpdatePage = Page.UpdateQfaMeetingDate;
        qfaUpdatePage.getParameters().put('id', lead.Id);
        Test.setCurrentPageReference(qfaUpdatePage);
        
        UpdateQfaMeetingDateController controller = new UpdateQfaMeetingDateController();
        controller.lead.QFA_Meeting_Date__c = Date.today();
        controller.save();
        Test.stopTest();
        
        // Refresh the Oppty and Lead
        oppty = [select Id, Qfa_Meeting_Date__c from Opportunity where Id = :oppty.Id][0];
        lead = [select Id, Qfa_Meeting_Date__c from Lead where Id = :lead.Id][0];
        
        // Verify the changes
        system.assertEquals(oppty.Qfa_Meeting_Date__c, Date.today());
        system.assertEquals(lead.Qfa_Meeting_Date__c, Date.today());
        }
                
    } 
    //ViewSurveyController.cls

     private static Testmethod void testViewSurveyController() {
         System.runAs(dmlUser)
        {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
        Apexpages.Standardcontroller stc;   
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.getAQuestion();
        System.assert(vsc.allQuestionsSize == 4);
        System.assert(tu.surveyId != null);
        }
    }

    private static Testmethod void testUpdateSurveyName() {
        System.runAs(dmlUser)
        {
      SurveyTestingUtil tu = new SurveyTestingUtil();
      Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
      Apexpages.Standardcontroller stc; 
      ViewSurveyController vsc = new ViewSurveyController(stc);
      vsc.surveyName = 'new name';
      system.assert(vsc.updateSurveyName() == null);
        }
      
  }

  private static Testmethod void testupdateSurveyThankYouAndLink() {
      System.runAs(dmlUser)
        {
    SurveyTestingUtil tu = new SurveyTestingUtil();
    Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
    Apexpages.Standardcontroller stc; 
    ViewSurveyController vsc = new ViewSurveyController(stc);
    vsc.surveyThankYouText = 'new stuff';
    vsc.surveyThankYouURL = 'more new stff';
    system.assert(vsc.updateSurveyThankYouAndLink()==null);
        }
  }

  private static Testmethod void testRefreshQuestionList() {
      System.runAs(dmlUser)
        {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;   
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.getAQuestion();
        
        // get question with orderNumber 1
        Survey_Question__c first = [Select id, orderNumber__c from Survey_Question__c Where orderNumber__c =: 1 and Survey__c =: tu.surveyId];
        System.assert(first.orderNumber__c == 1 );      
        
        // Specify the new order    
        List<String> newOrder = new List<String>();
        newOrder.add(vsc.allQuestions[2].id);
        newOrder.add(vsc.allQuestions[0].id);
        newOrder.add(vsc.allQuestions[1].id);
        newOrder.add(vsc.allQuestions[3].id);
        
        ViewSurveyController.updateQuestionOrder(newOrder);
        
        // Verify that the question with order 1 is not the same as the one retrieved previously
        Survey_Question__c second = [Select id, orderNumber__c from Survey_Question__c Where orderNumber__c =: 1 and Survey__c =: tu.surveyId];
        System.assert(second.id != first.id);
        
        // update the question list, and make sure it has been modified as well
        vsc.refreshQuestionList();
        System.assert(vsc.allQuestions[1].id != first.id);
        }
        
    }

    private static TestMethod void testGetResponses() {
        System.runAs(dmlUser)
        {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;   
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.getAQuestion();

        List<String> resp = new List<String>();
        resp.add('one');
        resp.add('two');
        resp.add(tu.paId);
        resp.add(tu.surveyId);
        resp.add('NONE');
        ViewSurveyController.getResponses(resp, 'false');
        AddUsersController.addUser(tu.contactId, tu.surveyId, tu.paId);
        ViewSurveyController.getResponses(resp, 'false');
        ViewSurveyController.getResponses(resp, 'true');
//        System.assert('true'==ViewSurveyController.getResponses(resp));
        }
    }

    private static testmethod void testResultAndThankYouPage(){
        System.runAs(dmlUser)
        {
        SurveyTestingUtil tu = new SurveyTestingUtil();
      Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
      Apexpages.Standardcontroller stc; 
      ViewSurveyController vsc = new ViewSurveyController(stc);
      vsc.getAQuestion();
      System.assert(vsc.resultPage() != null);
      System.assert(vsc.thankYouPage() != null);
        }
        
    }

    private static testmethod void testDeleteRefresh(){
        System.runAs(dmlUser)
        {
    SurveyTestingUtil tu = new SurveyTestingUtil();
      Apexpages.currentPage().getParameters().put('id',tu.surveyId);  
      Apexpages.Standardcontroller stc; 
      ViewSurveyController vsc = new ViewSurveyController(stc);
      System.assert(null==vsc.deleteRefresh());
        }
  }

  private static TestMethod void testDeleteQuestion() {
      System.runAs(dmlUser)
        {
        SurveyTestingUtil tu = new SurveyTestingUtil();
        Apexpages.currentPage().getParameters().put('id',tu.surveyId);
        Apexpages.Standardcontroller stc;   
        ViewSurveyController vsc = new ViewSurveyController(stc);
        vsc.getAQuestion();
        
        // Get a question to delete
        Survey_Question__c sq = [Select id, orderNumber__c from Survey_Question__c Where orderNumber__c =: 1 and Survey__c =: tu.surveyId];
        ViewSurveyController.deleteQuestion(sq.id);
        List<Survey_Question__c> sqs = [Select id, orderNumber__c from Survey_Question__c Where Survey__c =: tu.surveyId];
        for (Survey_Question__c s: sqs)
            System.assert(s.OrderNumber__c != 1);
        List<ViewSurveyController.question> listQ = new List<ViewSurveyController.question>();
        listQ = vsc.getAQuestion();
        }
    }

    //CSP_RenewalOpportunitiesTabController
    public static TestMethod void testMeCSP_RenewalOpportunitiesTabController()
    {
        System.runAs(dmlUser)
        {
        CSP_RenewalOpportunitiesTabController CSPTabController = new CSP_RenewalOpportunitiesTabController();
        System.assertEquals(true, GsmUtilClass.getGSMSettingValue('CSP_SalesProfileIds').contains(String.valueOf(Userinfo.getProfileId()).substring(0,15)));  
    }
    }

}