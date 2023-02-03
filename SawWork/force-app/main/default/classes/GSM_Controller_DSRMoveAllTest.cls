@isTest
public  class GSM_Controller_DSRMoveAllTest 
{
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup static void setupDataForTest() 
    {
        System.runAs(dmlUser) {
            
            Account acc = new Account();
            acc.Name = 'pAccName';
            acc.BillingCountry = 'India';
            acc.BillingState = 'DELHI';
            insert acc;
            
            List<Opportunity> opList = new List<Opportunity>();
            Opportunity oppty1 = new Opportunity();
            oppty1.Name = '__Test Oppty1';
            oppty1.StageName = '1-Create';
            oppty1.AccountId = acc.Id;
            oppty1.CloseDate = Date.today().addMonths(4);
            opList.add(oppty1);
            Opportunity oppty2 = new Opportunity();
            oppty2.Name = '__Test Oppty2';
            oppty2.StageName = '1-Create';
            oppty2.AccountId = acc.Id;
            oppty2.CloseDate = Date.today().addMonths(4);
            opList.add(oppty2);
            insert opList;
            
            //User Creation
            Profile p = [select Id from profile where name='Solutions Engineer' LIMIT 1][0];
            UserRole role = [select Id from UserRole where Name = 'Worldwide' LIMIT 1][0];
            List<User> userList = new List<User>();
            User seUser = new User(alias='newSE', email='newse@akamai.com',emailencodingkey='UTF-8', lastname='newSE', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_se@akamai.com',profileid = p.Id, UserRoleId = role.Id );
            userList.add(seUser);
            User managerSEUser = new User(alias='seMan', email='managerse@akamai.com',emailencodingkey='UTF-8', lastname='managerSE', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__manager_se@akamai.com',profileid = p.Id, UserRoleId = role.Id );
            userList.add(managerSEUser);
            insert userList;
            
            seUser.ManagerId = managerSEUser.Id;
            update seUser;
            
        }
    }
    @isTest static void oneTestToTestThemAll()
    {
        User seUser = [select Id from User where alias = 'newSE' LIMIT 1][0];
        List<Opportunity> oList = [select id from opportunity where Name like '__Test%'];
        Id opp1Id = oList[0].Id;
        Id opp2Id = oList[1].Id;
        GSM_Controller_DSRMoveAll.searchOpportunity('__Test',opp1Id );
        
        system.runAs(seUser){
            Deal_Support_Request__c dsr = new Deal_Support_Request__c();
            dsr.Opportunity__c = opp1Id;
            dsr.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByName().get('Pre-Sales Engagement').getRecordTypeId();
            dsr.Request_Type__c = 'POC';
            dsr.POC_Status__c = 'Planned';
            dsr.Start_Date__c = System.today();
            dsr.End_Date__c = System.today() + 5;
            dsr.Contract_Type__c = 'Out Clause';
            dsr.Success_Criteria__c = 'Success';
            dsr.Product__c = 'Adaptive Media Delivery';
            dsr.Validation_Override__c = true;
            insert dsr;
        }
        
        Test.startTest();
        GSM_Controller_DSRMoveAll.getDSRCount(opp1Id);
        GSM_Controller_DSRMoveAll.moveAllDSRbyOpportunity(opp1Id, opp2Id);
        GSM_Controller_DSRMoveAll.moveAllDSRbyOpportunity(null, opp2Id);
        Test.stopTest();
    }
}