@isTest(seeAllData = false)
private class MarketPlaceContactRoleControllerTest {

    static User dmlUser = new User(id=UserInfo.getUserId());
    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(dmlUser)
        {
            utilTestClass.insertCustomSettings();

            Account acc =  (Account)new SobjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Type,'Lead')
                .put(Account.BillingCountry,'United Kingdom')
                .put(Account.BillingStreet,'TBD')
                .put(Account.BillingCity,'TBD')
                .create()
                .getRecord();

            Contact cnt = (Contact)new SobjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, acc.Id)
                .create()
                .getRecord();

            Opportunity oppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                .eagerPopulate()
                .put(Opportunity.AccountId, acc.Id)
                .put(Opportunity.Deal_Type__c, 'Direct')
                .create()
                .getRecord();
            Sales_Approved_Country__c sac = new Sales_Approved_Country__c(Name='USA' ,Order_Region__c='North America',Order_Currency__c='USD',Sub_Region__c='Americas',Region__c='Americas',Is_Direct_Allowed__c=true);
            insert sac;

            Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
                  String autoConvertQId = GSMSettings.getValue('LeadAutoConvert_QueueId');
                  List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                      .eagerPopulate()
                      .put(Account.Vertical__c, 'Gaming')
                      .put(Account.Sub_Vertical__c, 'Gaming')
                      .put(Account.Type, 'Lead')
                      .put(Account.BillingCountry,'United Kingdom')
                        .put(Account.BillingStreet,'TBD')
                        .put(Account.BillingCity,'TBD')                      
                      .count(2)
                      .create()
                      .getRecords();
                  List<Contact> listOfTestContacts = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
                      .eagerPopulate()
                      .put(Contact.AccountId, listOfTestAccounts)
                      .count(2)
                      .create()
                      .getRecords();

            Profile pr = [select id from profile where name='Marketing Operations'][0];
            User marketingOpsUser = new User(alias = 'rsdnica',
            email='rsdnica@akamai.com',emailencodingkey='UTF-8', lastname='rsdnic',
            languagelocalekey='en_US',localesidkey='en_US',
            timezonesidkey='America/Los_Angeles', isactive = true, Title = 'Marketing Director',
            username='rsdnica@akamai.com',profileid = pr.Id);
            insert marketingOpsUser;
            /*
            User marketingOpsUser = (User) new SObjectBuilder(User.sObjectType)
                .eagerPopulate()
                .put(User.Username, 'acttrgr@akamai.com')
                .put(User.Email, 'rsddd@akamai.com')
                .put(User.CommunityNickname, 'rsdnic')
                .put(User.ProfileId, SobjectRepository.getProfileId('Marketing Operations'))
                .create()
                .getRecord();
            */

            System.runAs(marketingOpsUser)
            {

                  new SObjectBuilder(Lead.SObjectType)
                      .eagerPopulate()
                      .count(2)
                      .put(Lead.RecordTypeId, akamaiLeadRecordTypeId)
                      .put(Lead.OwnerId, marketingOpsUser.Id)//.put(Lead.OwnerId, autoConvertQId)
                      .put(Lead.Associated_Contact__c, listOfTestContacts)
                      .put(Lead.Associated_Account__c, listOfTestAccounts)
                      .put(Lead.Country,'United Kingdom')

                      .create();
            }

            String returnVal = MarketPlaceContactRoleController.createAdminOpportunityForManualTrial(oppty.Id);
            Map<String, String> returnMap = MarketPlaceContactRoleController.getBuyAkamaiSupportedProducts();

        }
    }

    private static Opportunity refresh(Id opptyId)
    {
        return [select id, AKAM_Opportunity_ID__c, CurrencyIsoCode, Deal_Type__c, Account_Status__c,MarketPlace_Product_Id__c, MarketPlace_Trial_Duration__c, Account_Primary_Country__c from Opportunity where Id= :opptyId];
    }

    private static Lead refreshLead(Id leadId)
    {
        return [select id, associated_account__r.type, owner.name,ownerid from lead where id=:leadId];
    }
    static testmethod void testLeadStartTrial()
    {
        Test.startTest();
        List<Lead> leadList = SobjectRepository.getLeads(2);
        Lead l1 = leadList[0];
        Lead l2= leadList[1];

        system.debug('Lead 1 Status '+l1.Status);
                system.debug('Lead 2 Status '+l2.Status);


        PageReference pageRef = Page.MarketPlaceContactRolePage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',l1.Id);
        MarketPlaceContactRoleController controller = new MarketPlaceContactRoleController();
        system.debug('Lead 1 Status '+l1.Status);
                system.debug('Lead 2 Status '+l2.Status);
        controller.updateLeadStatus();
        l1.Status='Closed';
        update l1;
        controller = new MarketPlaceContactRoleController();

        l1.OwnerId = GSMSettings.getValue('ONA_User_Id');
        l1.Validation_Override__c=true;
        update l1;
        controller = new MarketPlaceContactRoleController();


        Account acc = SobjectRepository.getAccount();
        acc.Type = 'Agency - Active';
        update acc;
        controller = new MarketPlaceContactRoleController();

        acc.OwnerId=GSMSettings.getValue('ONA_User_Id');
        acc.Validation_Override__c=true;
        update acc;
        controller = new MarketPlaceContactRoleController();

        acc.Is_Restricted_Country__c=true;
        acc.Validation_Override__c=true;
        update acc;
        controller = new MarketPlaceContactRoleController();

        pageRef.getParameters().put('id',l2.Id);
        controller = new MarketPlaceContactRoleController();
       
        Test.stopTest();
        
    }

    static testmethod void testOpptyStartTrial()
    {
        Test.startTest();

        Opportunity oppty = SobjectRepository.getOpportunity();
        oppty = refresh(oppty.id);

        PageReference pageRef = Page.MarketPlaceContactRolePage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',oppty.Id);
        MarketPlaceContactRoleController controller = new MarketPlaceContactRoleController();

        Account acc = SobjectRepository.getAccount();
        acc.Type = 'Agency - Active';
        update acc;
        controller = new MarketPlaceContactRoleController();

        acc.OwnerId=GSMSettings.getValue('ONA_User_Id');
        acc.Validation_Override__c=true;
        update acc;
        controller = new MarketPlaceContactRoleController();

        acc.Is_Restricted_Country__c=true;
        acc.Validation_Override__c=true;
        update acc;
        controller = new MarketPlaceContactRoleController();
        pageRef.getParameters().put('id',oppty.Id);
        controller = new MarketPlaceContactRoleController();
        controller.decrementCounter();
        controller.getCount();
        MarketPlaceContactRoleController.checkPartnerredirect(oppty.id,'lightning');//added by Rajesh SFDC-6634
        Test.stopTest();
    }

    static testmethod void testContactStartTrial()
    {
        Test.startTest();
        Contact con = SobjectRepository.getContact();

        PageReference pageRef = Page.MarketPlaceContactRolePage;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id',con.Id);
        MarketPlaceContactRoleController controller = new MarketPlaceContactRoleController();
        controller.updateLeadStatus();

        controller = new MarketPlaceContactRoleController();

        Account acc = SobjectRepository.getAccount();
        acc.Type = 'Agency - Active';
        update acc;
        controller = new MarketPlaceContactRoleController();

        acc.OwnerId=GSMSettings.getValue('ONA_User_Id');
        acc.Validation_Override__c=true;
        update acc;
        controller = new MarketPlaceContactRoleController();

        acc.Is_Restricted_Country__c=true;
        acc.Validation_Override__c=true;
        update acc;
        controller = new MarketPlaceContactRoleController();

        pageRef.getParameters().put('id',con.Id);
        controller = new MarketPlaceContactRoleController();
        Test.stopTest();
    }

    static testmethod void testMPCalloutClass()
    {
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        String EndPoint = URL.getSalesforceBaseUrl().toExternalForm() +'/services/data/v34.0/connect/orders/';
        req.setEndpoint(EndPoint);
        req.setMethod('GET');

        new CalloutLog(req);
        CalloutDelegator cd = new CalloutDelegator();
        cd.executeAsync(req);
        cd.fetchResponse();

        PromiseErrorDebugger pe = new PromiseErrorDebugger();
        pe.error(new CustomException('test'));
    }

    static testmethod void startTrialButtonUsingGenericContactButton()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();

            Contact con=SobjectRepository.getContact();

            Test.setCurrentPage(Page.GsmLite_ContactButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','ManageOperationsPortalAccess');
            ApexPages.currentPage().getParameters().put('recordId',con.Id);
            ApexPages.currentPage().getParameters().put('firstname','Bhuvan');
            ApexPages.currentPage().getParameters().put('lastname','Bam');

            GsmLite_ContactButtonPageController abpc;
            PageReference pageRef;

            try
            {
                abpc = new GsmLite_ContactButtonPageController();
                pageRef = abpc.init();
            }
            catch(Exception exx)
            {
                System.Debug('Exception');
            }

            Test.setCurrentPage(Page.GsmLite_ContactButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','ManageOperationsPortalAccess');
            ApexPages.currentPage().getParameters().put('recordId',con.Id);
            ApexPages.currentPage().getParameters().put('firstname','Bhuv@n');
            ApexPages.currentPage().getParameters().put('lastname','Bam');

            try
            {
                abpc = new GsmLite_ContactButtonPageController();
                pageRef = abpc.init();
            }
            catch(Exception exx)
            {
                System.Debug('Exception');
            }

            Test.setCurrentPage(Page.GsmLite_ContactButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','UpdateAccess');
            ApexPages.currentPage().getParameters().put('recordId',con.Id);

            abpc = new GsmLite_ContactButtonPageController();

            pageRef = abpc.init();
            Test.stopTest();
        }
    }
}