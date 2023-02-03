@isTest
public class SF1_LocateAccAndOppServiceTest {
   
    static testmethod void getOpportunityTest(){
     
            Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
            Account acc = utilTestClass.CreateAccount('__Test Ackjgbvnunt');
            acc.OwnerId =u.Id; 
            acc.website='www.tesusert.com';      
            insert acc;                      
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty;
                Opportunity opp=SF1_LocateAccountController.getOpportunity(oppty.id);
                System.assertNotEquals(opp,Null);
       
                }
   
    static testmethod void accSearchTest(){
      
            Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
            Account acc = utilTestClass.CreateAccount('__Test Accomunt');
            acc.OwnerId =u.Id; 
            acc.website ='www.satem.com';     
            insert acc;                      
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty;  
           Integer off = 1;
                                List<Account> Accs=SF1_LocateAccountController.accSearch(acc.Name,acc.Website,acc.BillingCountry,acc.BillingState,off);
       
    }
   /* static testmethod void AddAccountTest(){
     
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId =u.Id;  
            acc.website='www.chrom.com';    
            insert acc;                      
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty;      
   String  opp=SF1_LocateAccountController.AddAccount(acc.id,oppty.id);
 
        
    }*/
   
    static testmethod void AddAccntTest(){
     
            Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
            Account acc = utilTestClass.CreateAccount('__Test Acjhg');
            acc.OwnerId =u.Id;
            acc.Website='www.TestOrg.com';
            acc.Vertical__c = 'Commerce';
            acc.Sub_Vertical__c = 'Commerce - Other'; 
            insert acc;

            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name =: roleName][0].Id;
            Account_Reassignment_Rule__c ownerRule = utilTestClass.CreateAccountReassignmentRule(u.username, u.Id, roleName);
            insert ownerRule;

            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty; 
            System.runAs(u) {
            String opp=SF1_LocateAccountController.AddAccnt(oppty.id,acc.name+'Test___AddAccnt',acc.Website,acc.BillingStreet,acc.BillingCity,acc.BillingState,acc.Zip_Postal_Code_Local__c,acc.BillingCountry, acc.Vertical__c, acc.Sub_Vertical__c);
       }     
        
    }
   
    static testmethod void getCurrentOpportunityAccountIdTest()
    {
                Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
         Account acc = utilTestClass.CreateAccount('__Test Accsw');
            acc.OwnerId =u.Id; 
            acc.website='www.testsam.com';     
            insert acc;                      
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty;
            String acctID = SF1_PRMSearchOppController.getCurrentOpportunityAccountId(oppty.id);
            //System.assertEquals(acctID+'',acc.Id+'');
    }
   
    static testmethod void getCreateAcceptAsNewTestClass()
    {
                Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
         Account acc = utilTestClass.CreateAccount('__Test Acct1');
            acc.OwnerId =u.Id; 
            acc.website='www.tessam.com';     
            insert acc;                       
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty;
            String acctID = SF1_PRMSearchOppController.getCreate(oppty.id);
    }
   
    static testmethod void getAddOpptyLinkToDRTest()
    {
                Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
            Account acc = utilTestClass.CreateAccount('__Tt Account');
            acc.OwnerId =u.Id; 
            acc.website='www.tesail.com';     
            insert acc;                      
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;
       
                Opportunity pendingOppty = utilTestClass.CreateOpportunity('__Test Oppty_Pending','1. Identify Need');
            pendingOppty.AccountId =acc.Id;
            pendingOppty.OwnerId = u.Id;
            pendingOppty.CloseDate = Date.today().addMonths(4);           
            insert pendingOppty;
       
            SF1_PRMSearchOppController.getAddOppty(pendingOppty.Id,oppty.Id);
    }
   
    static testmethod void getOpportunityListPaginationTest()
    {
                Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
             Account acc = utilTestClass.CreateAccount('__Test Acunt');
            acc.OwnerId =u.Id; 
            acc.website='www.usetest.com';     
            insert acc;                       
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty;
            SF1_PRMSearchOppController.getOpportunity(oppty.id,0,0,'');
    }
 
}