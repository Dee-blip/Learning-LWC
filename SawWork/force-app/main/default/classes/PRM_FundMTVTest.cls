/***
PRM_FundMTVTest
@author Vinayendra T N <Vinatara@akamai.com>
@Description : This is a test class for creating MTV shares for FC,FR and FB
* History:
* =========================
* Developer			Date			Description
* --------------------------------------------------------------------------------------------------
* Vinayendra T N	07/06/11		CR 1131499 PRM: Need to ensure MTV also works with FR, FC, FB, etc. Not only opportunities
* Vivek Baidya		13-Feb-2018		Test Class Optimization (SFDC-2303)
*/ 
@isTest(seeAllData = false)
private class PRM_FundMTVTest {
    //static User partner;
    static User dmlUser = new User(id=UserInfo.getUserId());
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            
            //Custom Setting Insertion
            Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
            Test.loadData(globalDescribe.get('Features_Toggle__c'), 'CS_Features_Toggle');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            
            //Account Insertion
            List<Account> accList = new List<Account>();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Account parentacc2 = utilTestClass.CreateAccount('__ Test Account');
            accList.add(parentacc2);
            Account parentacc = utilTestClass.CreateAccount('__ Test Account New');
            accList.add(parentacc);
            Account acc = utilTestClass.CreateAccount('__ Test Account New1');
            accList.add(acc);
            
            insert accList;
            
            //Account Updation With IsPartner True
            for(integer i=0; i<accList.size(); i++){
                accList[i].Validation_Override__c=true;
                accList[i].IsPartner = true;
                accList[i].Partner_Type__c='Unknown';
                accList[i].Rebate_TC_Status__c='Accepted';
                accList[i].Rebate_TC_Accepted_At__c=DateTime.now();
                if(i>0)
                    accList[i].ParentId=accList[i-1].Id;
            }
            update accList;
            
            //Contact Insertion            
            List<Contact> conList = new List<Contact>();
            Contact c0 = utilTestClass.CreateContact('John0','Doe');
            c0.AccountId=parentacc2.id;
            c0.MailingStreet='123 Main';
            c0.MailingCity='Peoria';
            c0.MailingState='IL';
            c0.MailingPostalCode='33333';
            c0.MobilePhone='3213213211';
            c0.Fax='3213123211';
            c0.Email ='john0@akamai.com';
            c0.Active_Partner__c=True;
            conList.add(c0);
            
            Contact c1 = utilTestClass.CreateContact('John1','Doe');
            c1.AccountId=parentacc.id;
            c1.MailingStreet='123 Main';
            c1.MailingCity='Peoria';
            c1.MailingState='IL';
            c1.MailingPostalCode='33333';
            c1.MobilePhone='3213213211';
            c1.Fax='3213123211';
            c1.Email ='john1@akamai.com';
            c1.Active_Partner__c=True;
            conList.add(c1);
            
            Contact c2 = utilTestClass.CreateContact('John2','Doe');
            c2.AccountId=acc.id;
            c2.MailingStreet='123 Main';
            c2.MailingCity='Peoria';
            c2.MailingState='IL';
            c2.MailingPostalCode='33333';
            c2.MobilePhone='3213213211';
            c2.Fax='3213123211';
            c2.Email ='john2@akamai.com';
            c2.Active_Partner__c=True;
            conList.add(c2);
            
            Contact c3 = utilTestClass.CreateContact('John3','Doe');
            c3.AccountId=acc.id;
            c3.MailingStreet='123 Main';
            c3.MailingCity='Peoria';
            c3.MailingState='IL';
            c3.MailingPostalCode='33333';
            c3.MobilePhone='3213213211';
            c3.Fax='3213123211';
            c3.Email ='john3@akamai.com';
            c3.Active_Partner__c=True;
            conList.add(c3);
            
            insert conList;
            
            Id profileId = [select id from profile where Name='Partner Community User' limit 1].Id;
            
            //User Insertion
            List<User> userList = new List<User>();
            User u0 = new User(
                Username='usr0@akamai.com',
                Alias = 'usr0', 
                Email='usr0@akamai.com', 
                FirstName='usr0', 
                LastName='usr0', 
                ProfileId = profileId, 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', 
                TimeZoneSidKey='America/Los_Angeles',
                ContactId = c3.id,
                Can_Accept_POA__c=true
            );
            userList.add(u0);
            
            User u1 = new User(
                Username='usr1@akamai.com',
                Alias = 'usr1', 
                Email='usr1@akamai.com', 
                FirstName='usr1', 
                LastName='usr1', 
                ProfileId = profileId, 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', 
                TimeZoneSidKey='America/Los_Angeles',
                ContactId = c0.id,
                Can_Accept_POA__c=true
            );
            userList.add(u1);
            
            User u2 = new User(
                Username='usr2@akamai.com',
                Alias = 'usr2', 
                Email='usr2@akamai.com', 
                FirstName='usr2', 
                LastName='usr2', 
                ProfileId = profileId, 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', 
                TimeZoneSidKey='America/Los_Angeles',
                ContactId = c1.id,
                Can_Accept_POA__c=true
            );
            userList.add(u2);
            
            User u3 = new User(
                Username='usr3@akamai.com',
                Alias = 'usr3', 
                Email='usr3@akamai.com', 
                FirstName='usr3', 
                LastName='usr3', 
                ProfileId = profileId, 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', 
                TimeZoneSidKey='America/Los_Angeles',
                ContactId = c2.id,
                Can_Accept_POA__c=true
            );
            userList.add(u3);
            
            insert userList;
            
            //User Updation With Role
            List<User> userUpdateList = new List<User>();
            Id rId=[select id from UserRole where PortalAccountId =:acc.id and Name like '%Partner User'][0].id;
            u0.UserRoleId = rId;
            userUpdateList.add(u0);
            u3.UserRoleId = rId;
            userUpdateList.add(u1);
            update userUpdateList;
            
        }
    }
    
    static testMethod void PRM_MTV_FR_Positive() 
    {
        System.runAs(dmlUser) {
            Account parentacc2 = [select id from Account where Name = '__ Test Account'][0];
            Account parentacc = [select id from Account where Name = '__ Test Account New'][0];
            Account acc = [select id from Account where Name = '__ Test Account New1'][0];
            User Parentpartner = [select id from User where Contact.Account.Name = '__ Test Account New'][0];
            User Parentpartner2 = [select id from User where Contact.Account.Name = '__ Test Account'][0];
            List<User> usrList = [select id from User where Contact.Account.Name = '__ Test Account New1'];
            User partner2 = usrList[0];
            User partner = usrList[1];
            
            //SFDC_MDF__c fr= CreateFundRequest('__Test Fund Request__');
            Test.startTest();
            
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id; 
            
            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;
            
            system.runAs(Partner)
            {
                insert fb;
                insert fr;
            }
            //Check if parent account partner is able to edit the record
            system.runAs(Parentpartner)
            {
                SFDC_MDF__c fundRequest=null;
                for(SFDC_MDF__c fur:[select id from SFDC_MDF__c where id=:fr.id ])
                    fundRequest=fur;
                system.assertNotEquals(fundRequest, null);	
            }
            PRM_FundMTV.FundRequestCreateMTVFirstRunFlag=true;
            PRM_FundMTV.FundRequestRemoveMTVFirstRunFlag=true;
            for(SFDC_MDF__Share frs : [select id,UserOrgroupId from SFDC_MDF__Share where ParentId =:fr.Id and IsDeleted=false ]){
                system.debug('fr shares b4'+frs.UserOrgroupId);
            }
            fr.Account__c=parentacc.id;
            PRMTriggerClass.InitializeFlagVariables();
            update fr;
            for(SFDC_MDF__Share frs : [select id,UserOrgroupId from SFDC_MDF__Share where ParentId =:fr.Id and IsDeleted=false ]){
                system.debug('fr shares'+frs.UserOrgroupId);
            }
            system.runAs(partner2)
            {
                SFDC_MDF__c fundRequest=null;
                for(SFDC_MDF__c fur:[select id from SFDC_MDF__c where id=:fr.id ])
                    fundRequest=fur;
                system.assertEquals(fundRequest, null);	
            }
            system.runAs(Parentpartner2) 
            {
                SFDC_MDF__c fundRequest=null;
                for(SFDC_MDF__c fur:[select id from SFDC_MDF__c where id=:fr.id ])
                    fundRequest=fur;
                system.assertNotEquals(fundRequest, null);	
            }
            Test.stopTest();
        }
    }
    
    static testMethod void PRM_MTV_FB_Positive() 
    {
        System.runAs(dmlUser) {
            Account parentacc2 = [select id from Account where Name = '__ Test Account'][0];
            Account parentacc = [select id from Account where Name = '__ Test Account New'][0];
            Account acc = [select id from Account where Name = '__ Test Account New1'][0];
            User Parentpartner = [select id from User where Contact.Account.Name = '__ Test Account New'][0];
            User Parentpartner2 = [select id from User where Contact.Account.Name = '__ Test Account'][0];
            List<User> usrList = [select id from User where Contact.Account.Name = '__ Test Account New1'];
            User partner2 = usrList[0];
            User partner = usrList[1];
            
            test.startTest();
            //SFDC_Budget__c budget = new SFDC_Budget__c(	Account__c=acc.id,Active__c=true,Amount__c=10000);
            SFDC_Budget__c budget = utilTestClass.CreateFundBudget(10000);
            budget.Account__c = acc.Id;
            budget.Start_Earned_Date__c=Date.Today()-7;
            budget.End_Earned_Date__c=Date.Today()+14;
            budget.Fund_Request_Deadline__c=Date.today()+14;
            budget.Fund_Claim_Deadline__c=Date.today()+20;
            insert budget;
            //Check if parent account partner is able to edit the record
            system.runAs(Parentpartner)
            {
                SFDC_Budget__c fundBudget=null;
                for(SFDC_Budget__c fur:[select id from SFDC_Budget__c where id=:budget.id ])
                    fundBudget=fur;
                system.assertNotEquals(fundBudget, null);	
            }
            PRM_FundMTV.FundBudgetCreateMTVRunFlag=true;
            PRM_FundMTV.FundBudgetRemoveMTVFirstRunFlag=true;
            //Anand Hegde - create a new FB under parentacc instead of reparenting
            // reparenting an FB is not allowed as per the new validation rule
            //budget.Account__c=parentacc.id;
            SFDC_Budget__c parentBudget = utilTestClass.CreateFundBudget(10000);
            parentBudget.Account__c = parentacc.Id;
            parentBudget.Start_Earned_Date__c=Date.Today()-7;
            parentBudget.End_Earned_Date__c=Date.Today()+14;
            parentBudget.Fund_Request_Deadline__c=Date.today()+14;
            parentBudget.Fund_Claim_Deadline__c=Date.today()+20;
            insert parentBudget;
            
            system.runAs(partner2)
            {
                SFDC_Budget__c fundBudget=null;
                for(SFDC_Budget__c fur:[select id from SFDC_Budget__c where id=:parentBudget.id ])
                    fundBudget=fur;
                system.assertEquals(fundBudget, null);	
            }
            //Anand Hegde - Below check is redundunt since we have already checked if parent account can view the FB
            /* system.runAs(Parentpartner2) */ 
            /* { */
            /* 	SFDC_Budget__c fundBudget=null; */
            /* 	for(SFDC_Budget__c fur:[select id from SFDC_Budget__c where id=:parentBudget.id ]) */
            /* 	fundBudget=fur; */
            /* 	system.assertNotEquals(fundBudget, null); */	
            /* } */
            test.stopTest();
        }
    }
    
    static testMethod void PRM_MTV_FC_Positive() 
    {
        System.runAs(dmlUser) {
            Account parentacc2 = [select id from Account where Name = '__ Test Account'][0];
            Account parentacc = [select id from Account where Name = '__ Test Account New'][0];
            Account acc = [select id from Account where Name = '__ Test Account New1'][0];
            User Parentpartner = [select id from User where Contact.Account.Name = '__ Test Account New'][0];
            User Parentpartner2 = [select id from User where Contact.Account.Name = '__ Test Account'][0];
            List<User> usrList = [select id from User where Contact.Account.Name = '__ Test Account New1'];
            User partner2 = usrList[0];
            User partner = usrList[1];
            
            //SFDC_Budget__c budget = new SFDC_Budget__c(	Account__c=acc.id,Active__c=true,Amount__c=10000);
            SFDC_Budget__c budget = utilTestClass.CreateFundBudget(10000);
            budget.Account__c = acc.Id;
            budget.Start_Earned_Date__c=Date.Today()-7;
            budget.End_Earned_Date__c=Date.Today()+14;
            budget.Fund_Request_Deadline__c=Date.today()+60;
            budget.Fund_Claim_Deadline__c=Date.today()+70;
            insert budget;
            //SFDC_MDF__c fr= CreateFundRequest('__Test Fund Request__');
            //SFDC_MDF__c fr = utilTestClass.CreateFundRequest('__Test Fund Request__', 10000); 
            
            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',10000);
            fr.Account__c = acc.Id;
            Test.startTest();
            system.runAs(Partner)
            {
                
                insert fr;
                
                fr.Status__c='Submitted';
                PRMTriggerClass.InitializeFlagVariables();
                update fr;	
            }
            
            fr.Status__c='Approved';
            PRMTriggerClass.InitializeFlagVariables();
            update fr;
            //SFDC_MDF_Claim__c fc=new SFDC_MDF_Claim__c(Fund_Request__c=fr.id,Amount__c=500);
            SFDC_MDF_Claim__c fc = utilTestClass.CreateFundClaim(fr.Id, 500);
            fc.SOE_PubSec_Documentation__c = true;
            system.runAs(Partner)
            {
                insert fc;
            }
            //Check if parent account partner is able to edit the record
            system.runAs(Parentpartner)
            {
                SFDC_MDF_Claim__c fundClaim=null;
                for(SFDC_MDF_Claim__c fur:[select id from SFDC_MDF_Claim__c where id=:fc.id ])
                    fundClaim=fur;
                system.assertNotEquals(fundClaim, null);	
            }
            PRM_FundMTV.FundClaimCreateMTVRunFlag=true;
            PRM_FundMTV.FundClaimRemoveMTVnFirstRunFlag=true;
            fr.Account__c=parentacc.id;
            fc.Account__c=parentacc.id;
            PRMTriggerClass.InitializeFlagVariables();
            update fr;
            update fc;
            system.runAs(partner2)
            {
                SFDC_MDF_Claim__c fundClaim=null;
                for(SFDC_MDF_Claim__c fur:[select id from SFDC_MDF_Claim__c where id=:fc.id ])
                    fundClaim=fur;
                system.assertEquals(fundClaim, null);	
            }
            system.runAs(Parentpartner2) 
            {
                SFDC_MDF_Claim__c fundClaim=null;
                for(SFDC_MDF_Claim__c fur:[select id from SFDC_MDF_Claim__c where id=:fc.id ])
                    fundClaim=fur;
                system.assertNotEquals(fundClaim, null);	
            }
            Test.stopTest();
        }
    }
    
    static testMethod void PRM_MTV_FR_Negative() 
    {
        System.runAs(dmlUser) {
            Account parentacc2 = [select id from Account where Name = '__ Test Account'][0];
            Account parentacc = [select id from Account where Name = '__ Test Account New'][0];
            Account acc = [select id from Account where Name = '__ Test Account New1'][0];
            User Parentpartner = [select id from User where Contact.Account.Name = '__ Test Account New'][0];
            User Parentpartner2 = [select id from User where Contact.Account.Name = '__ Test Account'][0];
            List<User> usrList = [select id from User where Contact.Account.Name = '__ Test Account New1'];
            User partner2 = usrList[0];
            User partner = usrList[1];
            
            //SFDC_Budget__c budget = new SFDC_Budget__c(	Account__c=acc.id,Active__c=true,Amount__c=10000);
            SFDC_Budget__c budget = utilTestClass.CreateFundBudget(10000);
            budget.Account__c = acc.Id;
            budget.Start_Earned_Date__c=Date.Today()-7;
            budget.End_Earned_Date__c=Date.Today()+14;
            budget.Fund_Request_Deadline__c=Date.today()+60;
            budget.Fund_Claim_Deadline__c=Date.today()+70;
            insert budget;
            //SFDC_MDF__c fr= CreateFundRequest('__Test Fund Request__');
            //SFDC_MDF__c fr = utilTestClass.CreateFundRequest('__Test Fund Request__',1000); 
            
            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;
            
            system.runAs(Partner)
            {
                Test.startTest();
                insert fr;
                Test.stopTest();	
            }
            //Check if parent account partner is able to edit the record
            system.runAs(Parentpartner)
            {
                SFDC_MDF__c fundRequest=null;
                for(SFDC_MDF__c fur:[select id from SFDC_MDF__c where id=:fr.id ])
                    fundRequest=fur;
                system.assertNotEquals(fundRequest, null);	
            }
            system.runAs(Parentpartner)
            {
                SFDC_Budget__c fundBudget=null;
                for(SFDC_Budget__c fur:[select id from SFDC_Budget__c where id=:budget.id ])
                    fundBudget=fur;
                system.assertNotEquals(fundBudget, null);
            }
            
            List<SFDC_Budget__c> lstBudget = new List<SFDC_Budget__c>();
            lstBudget.add(budget);
            Map<Id, SFDC_Budget__c> mp = new Map<Id, SFDC_Budget__c>();
            mp.put(budget.Id, budget);
            PRM_FundMTV.FundBudgetRemoveMTV(lstBudget,mp);
        }
    }
}