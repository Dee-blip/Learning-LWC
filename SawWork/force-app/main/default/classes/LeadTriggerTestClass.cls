@isTest(seeAllData = false)
private class LeadTriggerTestClass 
{ 
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 10; 

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(dmlUser)
        {
            //utilTestClass.insertCustomSettings();

            MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
            settings.Name = 'LeadAsyncConversionFlagStatus';
            settings.Flag_Status__c = false;
            insert settings;

            List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .count(numberOfTestLeads)
                .create()
                .getRecords();


            List<Contact> listOfTestContacts = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, listOfTestAccounts)
                .count(numberOfTestLeads)
                .create()
                .getRecords();
            Test.startTest();

            Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
            String autoConvertQId = GSMSettings.getValue('LeadAutoConvert_QueueId');

            
            Profile pr = [select id from profile where name='Marketing Operations'][0];  
            User marketingOpsUser = new User(alias = 'rsdnica',
            email='rsdnica@akamai.com',emailencodingkey='UTF-8', lastname='rsdnic',
            languagelocalekey='en_US',localesidkey='en_US',
            timezonesidkey='America/Los_Angeles', isactive = true, Title = 'Marketing Director',
            username='rsdnica@akamai.com',profileid = pr.Id); 
            insert marketingOpsUser;
            /*User marketingOpsUser = (User) new SObjectBuilder(User.sObjectType)
                .eagerPopulate()
                .put(User.Username, 'acttrgr@akamai.com')
                .put(User.Email, 'rsddd@akamai.com')
                .put(User.CommunityNickname, 'rsdnic')
                .put(User.ProfileId, SobjectRepository.getProfileId('Marketing Operations'))
                .create()
                .getRecord();*/


            System.runAs(marketingOpsUser)
            {
                new SObjectBuilder(Lead.SObjectType)
                    .eagerPopulate()
                    .count(numberOfTestLeads)
                    .put(Lead.RecordTypeId, akamaiLeadRecordTypeId)
                    .put(Lead.OwnerId, autoConvertQId)
                    .put(Lead.Associated_Contact__c, listOfTestContacts)
                    .put(Lead.Associated_Account__c, listOfTestAccounts)
                    .put(Lead.Product_Line__c,'Enterprise')
                    .put(Lead.Country,'India')
                    .put(Lead.State,'Karnataka')
                    .create();
            }

            Order_Region_Reporting_Region_Mapping__c orRc = new Order_Region_Reporting_Region_Mapping__c();
            orRc.Order_Region__c = 'testOR';
            orRc.Reporting_Region__c = 'testRR';
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            /* Start Of Custom Setting Insertion */
          /*  Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');*/
            /* End Of Custom Setting Insertion */
            
        }

    }
    
    /*
    static testMethod void marketoConvertToContactAnnuitasFunctionality() {
        Test.startTest();
        LeadConversionHelper.hasAutoConversionRun = false;


        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
        List<Lead> pLeads = SobjectRepository.getLeads(numberOfTestLeads);
        for (Lead ithLead : pLeads) {
            ithLead.RecordTypeId = marketoRecordTypeId;
            ithLead.Validation_Override__c = true;
            ithLead.Convert_to_Opportunity__c = true;
            ithLead.OwnerId = marketingOpsUser.Id;
            ithLead.Email = 'manualConversionBulk@akamai.com';
            ithLead.adg_Lead_Qual_Stg_Growth__c = 'Qualified Lead - Warm';
        }   
        update pLeads;
        Test.stopTest();

    }

   static testMethod void testMarketoLeadToContactConversionBulk()
    {
        System.runAs(dmlUser)
        {

            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
            Test.startTest();

            User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
            Account acc = new Account();
            acc.Name = 'testAcc';
            acc.Website = 'www.testWeb.com';
            acc.Type = 'Lead';
            insert acc;
            // change all existing leads to  marketo leads
            for(Lead ithLead : nLeads)
            {
                ithLead.Associated_Contact__c=null;
                ithLead.Associated_Account__c = acc.Id;
                ithLead.RecordTypeId = marketoRecordTypeId;
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = marketingOpsUser.Id;
            }

            update nLeads;

            List<Contact> nContacts = SobjectRepository.getContacts(numberOfTestLeads);

            delete nContacts;

            List<Contact> mContacts = SobjectRepository.getContacts(numberOfTestLeads);

            // make sure there are no contacts in the system
            System.assert(mContacts.size()==0, 'Contacts havent been deleted');

            //List<Lead> pLeads = SobjectRepository.getLeads(numberOfTestLeads);

            
            for(Lead ithLead : nLeads)
            {
                ithLead.Convert_to_Opportunity__c = true;
                ithLead.Validation_Override__c = true;
            }


            update nLeads;
            Test.stopTest();
            //check the generated contact
            mContacts = SobjectRepository.getContacts(numberOfTestLeads);
            delete nLeads;
        }
    }

    static testmethod void insertMarketoLeadAndCreateC2A() {
        System.runAs(dmlUser) {
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
            List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
            for (Lead ithLead : nLeads) {
                ithLead.Associated_Contact__c=null;
                ithLead.RecordTypeId = marketoRecordTypeId;
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = marketingOpsUser.Id;
                ithLead.adg_Lead_Qual_Stg_Growth__c = 'Qualified Lead - Warm';
            }   
            update nLeads;
            
            List<Lead> pLeads = SobjectRepository.getLeads(numberOfTestLeads);
            for(Lead ithLead : pLeads) {
                ithLead.Associated_Contact__c=null;
                ithLead.RecordTypeId = marketoRecordTypeId;
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = marketingOpsUser.Id;
                ithLead.adg_Lead_Qual_Stg_Growth__c = 'Engaged';
                ithLead.Convert_to_Opportunity__c = false;
            }
            update pLeads;
            
            for(Lead ithLead : pLeads) {
                 ithLead.adg_Lead_Qual_Stg_Growth__c = 'Qualified Lead - Warm';
                 ithLead.Validation_Override__c = true;
            }
            
            update pLeads;
        }
    }

    static testmethod void BPPVisualizationControllerTest() {
         System.runAs(dmlUser) {
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
            List<Lead> nLeads = SobjectRepository.getLeads(1);
            //for (Lead ithLead : nLeads) {
                Lead ithLead  = nLeads[0];
                ithLead.Associated_Contact__c=null;
                ithLead.RecordTypeId = marketoRecordTypeId;
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = marketingOpsUser.Id;
                ithLead.adg_Lead_Qual_Stg_Growth__c = 'Qualified Lead - Warm';
                ithLead.adg_Lead_Qual_Stg_Cost__c = 'Engaged';
                //ithLead.adg_Lead_Qual_Stg_Performance__c = 'Turnback';
                ithLead.adg_Status_Growth__c = 'Qualified Engaged';
                ithLead.adg_Status_Cost__c = 'Engaged';
                //ithLead.adg_Status_Performance__c = 'Turnback';
                PageReference pageRef = Page.BPPVisualization;
                Test.setCurrentPage(pageRef);

                ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(ithLead);
                ApexPages.currentPage().getParameters().put('Id',ithLead.id);    
                BPPVisualizationController bpp = new BPPVisualizationController(sc);
            //}   
            update nLeads;
           
            ithLead.adg_Status_Growth__c = 'Closed - Duplicates';
            ithLead.Validation_Override__c = true;

            bpp.SaveLead();
            bpp.OnEdit();
            bpp.OnCancel();
            
        }
    }

    */

    /*static testMethod void addSDRUserMethodTest() 
    {
            List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
            Test.startTest();

            User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
            
            String uid = GSMUtilClass.getGSMSettingValue('LeadAssignmentSDRCatchAllQueue');
            List<String> uidList = uid.split(',');
            for(Lead ithLead : nLeads)
            {
                
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = uidList[0];
            }

            update nLeads;
            Test.stopTest();
    }
    */
     static testmethod void testRunReassignmentRules()
    {
        //List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
        Set<Id> leadIds = new Set<Id>();
        List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
        for(Lead ld : nLeads){
            leadIds.add(ld.Id);
        }
        List<Lead> leads = [Select id,Reassigned_By__c,Reassigned_Date__c,Validation_Override__c,Auto_Convert_Source__c from lead where id in : leadIds];
        Test.startTest();


        LeadTriggerClass.runLeadReassignmentRules(leads, null);

        PartnerLeadTriggerClass.hasPartnerLeadPermission(utilTestClass.getTestRunUser().Id);
    }

    static testmethod void testLeadClosure()
    {
        List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);

        Test.startTest();

        for(Lead ithLead : nLeads)
        {
            ithLead.Status='Closed';
        }

        update nLeads;
    }

    // ChatterEmailHandler needs to be deprecated, not being used
    // putting these tests here for now

    static testMethod void testChatterEmailHandler()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {

            // Create a new email and envelope object
            Messaging.InboundEmail email = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();

            User mUser = [select id, email, username from user where username='rsdnica@akamai.com' and profileid=:SobjectRepository.getProfileId('Marketing Operations')];
            // test with subject that matches the unsubscribe statement
            Contact mContact = SobjectRepository.getContact();
            email.subject = 'test #contact '+mContact.Email;
            GSM_Settings__mdt gsm = [select Value__c, Label from GSM_Settings__mdt where DeveloperName = 'E2Chatter_ecommerce_akamai_com'];
            string toAdd = gsm.Label.split(':')[1];

            email.fromAddress = mUser.email;
            email.toaddresses = new list<string>{toAdd + '@akamai.com'};
            email.ccAddresses = email.toaddresses;

            Messaging.Inboundemail.Binaryattachment binaryAttachment = new Messaging.Inboundemail.Binaryattachment();
            binaryAttachment.body = Blob.valueOf('UNIT TEST BINARY ATTACHMENT');
            binaryAttachment.fileName = 'A_UnitTest.gif';
            email.binaryAttachments = new List<Messaging.Inboundemail.Binaryattachment>{binaryAttachment};
            email.plainTextBody= '1234567889';
            email.htmlBody = '<b>akamai</b>';

            // call the class and test it with the data in the testMethod
            //ChatterEmailHandler ChatterEmailHandlerTest1 = new ChatterEmailHandler();

            Test.starttest();
            //ChatterEmailHandlerTest1.handleInboundEmail(email, env );


            email.subject = 'test2 #case 5436';
            email.fromAddress =mUser.Email;


            // call the class and test it with the data in the testMethod
            //ChatterEmailHandler ChatterEmailHandlerTest2 = new ChatterEmailHandler();

            //ChatterEmailHandlerTest2.handleInboundEmail(email, env );
            Account mAccount = SobjectRepository.getAccount();
            email.subject = 'test3 #opportunity '+mAccount.Name;

            email.binaryAttachments = null;
            email.htmlBody = null;
            // call the class and test it with the data in the testMethod
            //ChatterEmailHandler ChatterEmailHandlerTest3 = new ChatterEmailHandler();

            //ChatterEmailHandlerTest3.handleInboundEmail(email, env );

            email.subject = 'test4 #account TSTSRMAC00';

            // call the class and test it with the data in the testMethod
            //ChatterEmailHandler ChatterEmailHandlerTest4 = new ChatterEmailHandler();


            //ChatterEmailHandlerTest4.handleInboundEmail(email, env );
            email.subject = 'test4 ';
            email.plainTextBody= '1234567889';
            for(integer i=0;i<3205;i++)
                email.plainTextBody= email.plainTextBody+'01234567889';

            // call the class and test it with the data in the testMethod
            //ChatterEmailHandler ChatterEmailHandlerTest5 = new ChatterEmailHandler();


            //ChatterEmailHandlerTest5.handleInboundEmail(email, env );
            Test.stoptest();

        }
    }
    
   static testMethod Void testCloseCampaigns() {
        Set<Id> leadIds = new Set<Id>();
        List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
        for(Lead ld : nLeads){
            leadIds.add(ld.Id);
        }
        List<Lead> leads = [Select id,Reassigned_By__c,Reassigned_Date__c,Validation_Override__c,Lead_Owner__c,Auto_Convert_Source__c from lead where id in : leadIds];
        //LeadTriggerClass.createCampaignMemberbasedOnPrimaryCampaign(nLeads);
        LeadTriggerClassWithoutSharing.populateVerticalFieldsFromAccountForLead(nLeads);
        LeadTriggerClass.runLeadReassignmentRules(leads, null);
        //LeadTriggerClass.updateCampaignClosedDetails(leadIds);
        PartnerLeadTriggerClass.partnerLeadOwnerCheck(leads);
        User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
        PartnerLeadTriggerClass.hasPartnerLeadPermission(marketingOpsUser.Id);
    }

    static testMethod void testPartnerLeadPMAAssociation() 
    {
        
        System.runAs(utilTestClass.getTestRunUser())
        {
            List<Id> auList = new List<Id>();
            auList.addall(ConvertPartnerLeadTest.createAccountInfoVersion2(2));
            List<Account> accts = [select id, parentid,Partner_Type__c from account where id in :auList];
            for(Integer i=0; i<accts.size();i++){
                if(i>0){
                    accts[i].ParentId = accts[i-1].id;
                    accts[i].Partner_Type__c = 'ADS Partner';
                } 
            }
            update accts;
        
            User u1 = [select id,Contact.AccountId from User where contact.accountid = :accts[0].id];

            SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, u1.Contact.AccountId)
                .create()
                .getRecord();

            Partner_Marketing_Plan__c pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                .create()
                .getRecord();

            Partner_Marketing_Activity__c pma = (Partner_Marketing_Activity__c)new SobjectBuilder(Partner_Marketing_Activity__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Activity__c.Partner_Marketing_Plan__c, pmp.Id)
                .create()
                .getRecord();

            /*pmp.Plan_Status__c = 'Approved';
            update pmp;*/
            
            pma.Activity_status__c = 'In Progress';
            pma.Validation_Override__c = true;
            update pma;
        
            Lead l = createLead(u1.Id,pma.id);
            List<Lead> leadList = new List<Lead>();
             if (l.Primary_Campaign__c != null) {
                leadList.add(l);
             }
            LeadTriggerClassWithoutSharing.createCampaignMemberbasedOnPrimaryCampaign(leadList);
            
            Test.startTest();
        }
    }

    static testmethod void testDRAProcess()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        Test.startTest();
        new SObjectBuilder(DRASubprocessConfig__c.sObjectType)
            .eagerPopulate()
            .create();

       // Account acc= SObjectFactory.createPoolUserAccount();
       Account acc = new Account();
            acc.Name ='ZojhsFGT1';
            acc.OwnerId =GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
           acc.Vertical__c = 'Hotel & Travel';
            acc.Sub_Vertical__c ='Transportation';
          insert acc;

        System.assert(GsmUtilClass.getGSMSettingValue('ONAPoolOpsIdList').contains(acc.OwnerId)
                , 'Error: Account not owned by Pool user.'+acc.OwnerId);
        acc = [select Projected_Sales_Owner__c, Id,BillingCountry, Vertical__c from account where id=:acc.Id];

        //System.assert(acc.Projected_Sales_Owner__c!=null, 'Projected sales owner null for:'+acc);
        Test.stopTest();
    }

    static testmethod void testDRAJob()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        Test.startTest();

        new SObjectBuilder(DRASubprocessConfig__c.sObjectType)
            .eagerPopulate()
            .create();
       // Account poolUserAccount= SObjectFactory.createONAAccount();
        Account poolUserAccount = new Account();
            poolUserAccount.Name ='ZojhFGT1';
            poolUserAccount.OwnerId =GsmUtilClass.getGSMSettingValue('ONA_User_Id');
           poolUserAccount.Vertical__c = 'Hotel & Travel';
            poolUserAccount.Sub_Vertical__c ='Transportation';
          insert poolUserAccount;
        
        Database.executeBatch(new DRASubprocessAutomatedJob(), 10);

        Test.stopTest();
    }

    public static Lead createLead(Id ownerId, Id pmaId) {

        Id partnerRecordypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();

        Lead l = new Lead();
        l.recordTypeId = partnerRecordypeId;
        l.email = 'testemail@email.com';
        l.status = 'New';
        l.CurrencyIsoCode = 'USD';
        l.company = 'Test Company';
        l.firstname = 'Test';
        l.lastname = 'Lead';
        l.ownerId = ownerId;
        l.website = 'www.testwebsite.com';
        l.industry = 'Banking';
        l.street = 'Test street';
        l.city = 'Test City';
        l.state = 'Test state';
        l.PostalCode  = '201323';
        l.country = 'USA';
        l.Primary_Product__c = 'Enterprise Security - Enterprise App Access';
        l.Services_Hostname__c = 'testwebsite.com';
        l.description = 'Test Description';
        l.Partner_Marketing_Activity__c = pmaId;
        insert l;
        return l;
    }
}