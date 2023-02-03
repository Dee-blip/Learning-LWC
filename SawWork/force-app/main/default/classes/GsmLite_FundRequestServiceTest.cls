@isTest()
public class GsmLite_FundRequestServiceTest {
    
    static
    {
        utilTestClass.insertCustomSettings();
    }
    private static User createSCMUser(String username)
    {
        //UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        //User scmOwnerUser= new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='scnUser', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=username+'@akamai.com',profileid = '00eA0000000QkKx', UserRoleId = roleDVA.Id );
        User scmOwnerUser = [SELECT UserRoleId, ProfileId, Id FROM User where UserRoleId = '00EA0000000DiLNMA0' and ProfileId = '00eA0000000QkKx' and IsActive = true][0];
        return scmOwnerUser;
    }
    
    private static SFDC_MDF__c insertFundRequest(User scmOwnerUser,String status)
    {
        Account account = utilTestClass.CreateAccount('__TST_ACC');
        account.BillingStreet = '417';
        account.BillingState = 'CA';
        account.BillingPostalCode = '94104';
        account.BillingCountry = 'USA';
        account.BillingCity = 'SanFrancisco';
        insert account;
        List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,account.id);
        User partner=PartnerUsers[0];
        
        SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
        fb.Account__c = account.Id;
        insert fb;
        
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', account.Id, scmOwnerUser.Id);
        cm.MDF_Approver__c = scmOwnerUser.Id;
        cm.Master_Channel_Mapping__c = true;
        insert cm;
        SFDC_MDF__c fundRequest = utilTestClass.CreateFundRequest('Quarter Fund',1000);
        fundRequest.Account__c=account.id;
        fundRequest.Status__c=status;
        fundRequest.Activity_Date__c=Date.today().addMonths(2);
        fundRequest.Program_End_Date__c = Date.today().addMonths(3);
        fundRequest.Total_Activity_Event_Cost__c=40;
        fundRequest.Partner_Account_Owner__c=scmOwnerUser.id;
        fundRequest.Funding_Approved__c=1000;
        
        System.runAs(utilTestClass.getTestRunUser())
        {
            insert fundRequest;
        }
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(fundRequest.id);
        // Submit the approval request for the fund request
        //Approval.ProcessResult result = Approval.process(req1);
        
        //System.assertEquals('Pending', result.getInstanceStatus(), 'Instance Status'+result.getInstanceStatus());
        
        return fundRequest;
    }
    
    private static testmethod void testHasEditingRights(){
        Test.startTest();
        Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
        User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
        u.isActive=true;
        insert u;
        SF1_EditFundRequestController.hasEditingRights(u.Id);
        Test.stopTest();
    }
    
    private static testmethod void testCheckIfStatusSubmitted(){
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            User scmOwnerUser = createSCMUser('frTest3');
            SFDC_MDF__c fundRequest = insertFundRequest(scmOwnerUser,'Draft');
            System.runAs(scmOwnerUser)
            {
                SF1_EditFundRequestController.checkIfStatusSubmitted(fundRequest.Id);
            }
            Test.stopTest();
        }
    }
    
    private static testmethod void testSaveObjIfSFDCSubmitted(){
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            User scmOwnerUser = createSCMUser('frTest3');
            SFDC_MDF__c fundRequest = insertFundRequest(scmOwnerUser,'Submitted');
            System.runAs(scmOwnerUser)
            {
                SF1_EditFundRequestController.saveObj(fundRequest);
            }
            Test.stopTest();
        }
    }
    
    private static testmethod void testSaveObjIfNotSFDCSubmitted(){
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            User scmOwnerUser = createSCMUser('frTest3');
            SFDC_MDF__c fundRequest = insertFundRequest(scmOwnerUser,'Draft');
            System.runAs(scmOwnerUser)
            {
                SF1_EditFundRequestController.saveObj(fundRequest);
            }
            Test.stopTest();
        }
    }
    
    private static testmethod void testGetPageObject(){
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            User scmOwnerUser = createSCMUser('frTest3');
            SFDC_MDF__c fundRequest = insertFundRequest(scmOwnerUser,'Draft');
            System.runAs(scmOwnerUser)
            {
                SF1_EditFundRequestController.getPageObject(fundRequest.Id);
                SF1_FundRequestAddPrivateNoteController.getPageObject(fundRequest.Id);
                SF1_FundRequestService.getPageObject(fundRequest.Id);
            }
            Test.stopTest();
        }
    }
    
    
    static testmethod void accessAllowedTo_CurrentUserProfileTest()
    {
        SF1_FundRequestAddPrivateNoteController.accessAllowedToCurrentUserProfile();
    }
    
    private static testmethod void getSaveNote(){
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            User scmOwnerUser = createSCMUser('frTest3');
            SFDC_MDF__c fundRequest = insertFundRequest(scmOwnerUser,'Draft');
            System.runAs(scmOwnerUser)
            {
                SF1_FundRequestAddPrivateNoteController.saveNote(fundRequest);
                SF1_FundRequestService.saveNote(fundRequest);
            }
            Test.stopTest();
        }
    }
    
    
    static testmethod void getPageObjectForEditFundRequestTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            User scmOwnerUser = createSCMUser('frTest3');
            SFDC_MDF__c fundRequest = insertFundRequest(scmOwnerUser,'Draft');
            System.runAs(scmOwnerUser)
            {
                
                SF1_FundRequestService.getPageObjectForEditFundRequest(fundRequest.Id);
            }
            Test.stopTest();
        }
        
    }
    
    static testmethod void hasEditingRightsTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            User scmOwnerUser = createSCMUser('frTest3');
            SFDC_MDF__c fundRequest = insertFundRequest(scmOwnerUser,'Draft');
            System.runAs(scmOwnerUser)
            {
                
                SF1_FundRequestService.hasEditingRights(fundRequest.Id);
            }
            Test.stopTest();
        }
    }
    
    private static testmethod void testLoadPickListValuesFromUtil(){
        SF1_EditFundRequestController.loadPickListValuesFromUtil('SFDC_MDF__c', 'SOE_or_PubSec_Event__c');
    }
}