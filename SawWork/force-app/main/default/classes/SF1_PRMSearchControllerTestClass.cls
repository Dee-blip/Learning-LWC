@isTest(seeAllData=false)
public class SF1_PRMSearchControllerTestClass {
	static User dmlUser = utilTestClass.getTestRunUser();
    static testmethod void getCurrentOpportunityAccountIdTest()
    {
        System.runAs(dmlUser) {	
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id); 
            u.isActive=true;
            insert u;
			Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId =u.Id;       
            insert acc;                       
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);            
            insert oppty;
            String acctID = SF1_PRMSearchOppController.getCurrentOpportunityAccountId(oppty.id);
            //System.assertEquals(acctID,acc.Id+'');
        }
    }
    
    static testmethod void getCreateAcceptAsNewTestClass()
    {
        System.runAs(dmlUser) {	
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id); 
            u.isActive=true;
            insert u;
			Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId =u.Id;       
            insert acc;                       
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);            
            insert oppty;
            String acctID = SF1_PRMSearchOppController.getCreate(oppty.id);
        }
    }
    
    static testmethod void getAddOpptyLinkToDRTest()
    {
        System.runAs(dmlUser) {	
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id); 
            u.isActive=true;
            insert u;
			Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId =u.Id;       
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
    }
    
    static testmethod void getOpportunityListPaginationTest()
    {
        System.runAs(dmlUser) {	
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id); 
            u.isActive=true;
            insert u;
			Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId =u.Id;       
            insert acc;

            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);            
            insert oppty;
            SF1_PRMSearchOppController.getOpportunity(oppty.id,5,0,'Deal_Age__c');
        }
    }
}