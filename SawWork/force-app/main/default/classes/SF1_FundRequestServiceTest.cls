@isTest()
public class SF1_FundRequestServiceTest {
    
    static
    {
        utilTestClass.insertCustomSettings();
    }     
    private static User createSCMUser(String username)
    {
        //SFDC-2572
        Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0];
        UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        User scmOwnerUser= new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='scnUser', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=username+'@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
        insert scmOwnerUser;
        return scmOwnerUser;
    }
    
    private static SFDC_MDF__c insertFundRequest(User scmOwnerUser,String status)
    {
        Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
        String profileName = 'Partner Support';
        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        
        User testUser = utilTestClass.CreateUser('TST_OUSR', roleName, profileName);
        insert testUser;
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
        Approval.ProcessResult result = Approval.process(req1);
        
        System.assertEquals('Pending', result.getInstanceStatus(), 'Instance Status'+result.getInstanceStatus());
        
        return fundRequest;
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
                SF1_FundRequestAddPrivateNoteController.getPageObject(fundRequest.Id);
                SF1_FundRequestService.getPageObject(fundRequest.Id);
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
}