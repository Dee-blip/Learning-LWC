/***
    CaseTriggerTestClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : The following functionality is tested :
                   - Update the Case.ContactId with the Case.CreatedById when Case.ContactId = null

    @History
    --Developer           --Date            --Change
    Karteek Kumar M       19/03/2010        Created the class.
    Karteek Kumar M       12/04/2010        Testing "Add CreatedBy User to Case Team on creation."
    Vinayendra T N        23/12/2010        Added Momentum Case test method
    Vinayendra T N        28/12/2010        Added Product Management Test method
    Vamsee Surya S        28/12/2016        Added SC_CaseTriggerHelperClass Test Methods
    Vandhana Krishnamurthy 7/07/2017        Added test_PreSalesCases method
    Vandhana Krishnamurthy 5/11/2017        Added test_PS_S2ET method
    Sumanth Naik           20/03/2018       Added test_Carrierproductclass method
    Sumanth Naik           5/30/2018        Added test_sendEmailPreSales
    Vandhana Krishnamurthy 25/09/2018       Added test_UpdateAccountsProductsonSI method
    Aditya                  18-Jan-2019     Added test_addAMPCaseProduct for addAMPCaseProduct
    Vishnu                  02-Jul-2019     Added test for ESESP-758   AMG Case Mgmt Improvement: AMG SLA improvements
    Jay                    30-Jun-2021      Added test case for new support level Plus_EnhancedSLA added as per ESESP-5340
    Jay                    11-Nov-2021      ESESP-2264
*/
@isTest
private class CaseTriggerTestClass
{
    private static Email_to_Case__c CustomSettingsMomentum = Email_to_Case__c.getInstance('Momentum');
    private static Email_to_Case__c CustomSettingsProdMgmt = Email_to_Case__c.getInstance('ProdMgmt');
    private static Email_to_Case__c CustomSettingsCollections = Email_to_Case__c.getInstance('CollectionsEmailToCase');

    @testSetup static void setup()
    {
        //SCUtilTestClass.createCustomSettingsForCase();
        utilTestClass.createCustomSettings();
        utilTestClass.createData_SC_SupportEmail();
        /*
        List<SCUserIdCustomSetting__c> lSCUserIds = new List<SCUserIdCustomSetting__c>();
        SCUserIdCustomSetting__c portalUserId = new SCUserIdCustomSetting__c();
        portalUserId.Name = 'LunaPortalIntegration';
        portalUserId.UserId__c = '005G0000003dnrRIAQ';
        lSCUserIds.add(portalUserId);

        SCUserIdCustomSetting__c psQueueId = new SCUserIdCustomSetting__c();
        psQueueId.Name = 'Primary/SecondaryAssignmentQueue';
        psQueueId.UserId__c = '00GG0000002igPLMAY';
        lSCUserIds.add(psQueueId);

        SCUserIdCustomSetting__c lunaUserID = new SCUserIdCustomSetting__c();
        lunaUserID.Name = 'LunaCaseMgmtUserID';
        lunaUserID.UserId__c = '005G0000003dnrRIAQ';
        lSCUserIds.add(lunaUserID);

        SCUserIdCustomSetting__c pulsarUserID = new SCUserIdCustomSetting__c();
        pulsarUserID.Name = 'PulsarCaseMgmtUserID';
        pulsarUserID.UserId__c = '005m0000002HWFa';
        lSCUserIds.add(pulsarUserID);

        SCUserIdCustomSetting__c billingQueueId = new SCUserIdCustomSetting__c();
        billingQueueId.Name = 'Billing Queue';
        billingQueueId.UserId__c = '00GG0000002igOuMAI';
        lSCUserIds.add(billingQueueId);

        SCUserIdCustomSetting__c scUserIdcs = new SCUserIdCustomSetting__c();
        scUserIdcs.Name = 'NOCC/Network Agent';
        scUserIdcs.UserId__c = Userinfo.getUserId();
        lSCUserIds.add(scUserIdcs);
        */

        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('Test Account1');
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        accList.add(acc);

        acc = utilTestClass.CreateAccount('Test Account2');
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        accList.add(acc);
        
        Account plusESLAAccount = utilTestClass.CreateAccount('Salesforce');
        plusESLAAccount.Support_Level__c = 'Plus_EnhancedSLA';
        plusESLAAccount.Support_Advocate__c = true;
        accList.add(plusESLAAccount);
        
        Account acc123 = utilTestClass.CreateAccount('__ Test Account213');
        accList.add(acc123);


        insert accList;

        Contact con = utilTestClass.CreateContact('__Test1FirstName','__Test1LastName');
        con.AKAM_Contact_ID__c = 'ABC123';
        con.AccountId = acc.Id;
        con.email='abc@123.com';
        con.Primary_Contact_Method__c = 'Phone';
        insert con;


        SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c scBocc = new SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c();
        scBocc.Account__c = acc.Id;
        scBocc.Area__c = 'Professional_Services';
        scBocc.Marketing_Product_Name__c = 'Kona';
        scBocc.Unique_Key__c = 'BOCC123';
        insert scBocc;

        /*
        BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest' );
        insert ctype;

        BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c();
        cat.Name='TempCategory';
        cat.SI_Applies_to_Service_Incident__c = true;
        cat.BMCServiceDesk__AvailableForServiceCatalog__c = true;
        cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;
        insert cat;

        BMCServiceDesk__Impact__c ima = new BMCServiceDesk__Impact__c();
        ima.Name='tempImpact';
        ima.SI_Applies_to_Service_Incident__c = true;
        insert ima;

        BMCServiceDesk__Urgency__c  urg = new BMCServiceDesk__Urgency__c();
        urg.Name='tempUrgency1';
        urg.SI_Applies_to_Service_Incident__c = true;
        insert urg;
        
        List<BMCServiceDesk__Incident__c> lstIncident = new List<BMCServiceDesk__Incident__c>();
        
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        
        incident.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKUrgency__c = urg.id;
        incident.BMCServiceDesk__FKImpact__c = ima.Id;
        incident.BMCServiceDesk__shortDescription__c = 'Inc1';
        incident.how_was_the_issue_detected__c = 'others';
        lstIncident.add(incident);

        incident = new BMCServiceDesk__Incident__c();
        incident.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKUrgency__c = urg.id;
        incident.BMCServiceDesk__FKImpact__c = ima.Id;
        incident.BMCServiceDesk__shortDescription__c = 'Inc2';
        incident.how_was_the_issue_detected__c = 'others';
        lstIncident.add(incident);
        //insert lstIncident;
        */
        
        List<Case> lstCase = new List<Case>();

        Case cs1 = new Case();
        cs1.Description = 'testPS1';
        cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        cs1.Subject = 'testS2ET1';
        cs1.Service__c = 'Managed Integration';
        cs1.Validation_Override__c = true;
        cs1.AccountId = acc.Id;
        lstCase.add(cs1);

        Case irCase = new Case();
        irCase.Description = 'testPS1';
        irCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Invoice Review Case').getRecordTypeId();
        irCase.Subject = 'IRTestCase';
        irCase.Validation_Override__c = true;
        irCase.IR_Escal_Owner__c = acc.CreatedById;
        irCase.AccountId = acc.Id;
        lstCase.add(irCase);

        Case c = new Case();
        c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //c.Case_Product__c = eb_product.Id;
        c.Do_Not_Show_in_Portal__c = false;
        c.Sub_Type__c = 'Product Support';
        c.Status = 'Assigned';
        //c.Service_Incident__c = siRecord.Id;
        c.Severity__c = '1';
        c.Origin = 'Email';
        c.AccountId = acc.Id;
        c.Level_of_Impact__c = 'Low';
        c.Customer_Temperature__c = 'Low';
        c.Subject = 'Tech Case 1';
        c.Validation_Override__c = true;
        lstCase.add(c);

        Case cp = new Case();
        cp.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        cp.AccountId= acc.id;
        cp.Subject= 'Test AMG autogen';
        cp.Description ='Test AMG autogen';
        cp.Origin='Autogen';
        cp.Status = 'Assigned';
        cp.Autogen_UseCase__c = 'ECOB';
        cp.Validation_Override__c = true;
        lstCase.add(cp);
        
        
        Case c10 = new Case();
        c10.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //c.Case_Product__c = eb_product.Id;
        c10.Do_Not_Show_in_Portal__c = false;
        c10.Sub_Type__c = 'Product Support';
        c10.Status = 'Assigned';
        c10.Severity__c = '1';
        c10.Origin = 'Email';
        c10.AccountId = accList[0].Id;
        c10.Subject = 'New Tech Case 1';
        c10.Level_of_Impact__c = 'Low';
        c10.Customer_Temperature__c = 'Low';
        c10.Validation_Override__c = true;

        lstCase.add(c10);

        Case c11 = new Case();
        c11.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //c.Case_Product__c = eb_product.Id;
        c11.Do_Not_Show_in_Portal__c = false;
        c11.Sub_Type__c = 'Product Support';
        c11.Status = 'Assigned';
        c11.Severity__c = '1';
        c11.Origin = 'Email';
        c11.Subject = 'New Tech Case 2';
        c11.AccountId = accList[0].Id;
        c11.Level_of_Impact__c = 'Low';
        c11.Customer_Temperature__c = 'Low';
        c11.Validation_Override__c = true;
        lstCase.add(c11);

        insert lstCase;

        User u = [SELECT Id FROM User where IsActive = TRUE AND Profile.Name = 'GSS Professional Services' LIMIT 1];
        
        Id psEscTeamId = [SELECT Id, Name FROM Group where Type = 'Queue' and Name = 'PS_Security_Escalation_Team' limit 1].Id;
        cs1 = [Select Id,OwnerId from Case where Subject = 'testS2ET1' limit 1];
        cs1.AccountId = acc.Id;
        cs1.OwnerId = psEscTeamId;
        System.runAs(u)
        {
            update cs1;
        }
    }

    static testmethod void UpdateContactNameTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        //Profile pr = [select id from profile where name='Sales - Media'][0];
        //User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        //insert usr;
        
        User usr = [SELECT Id FROM User WHERE IsActive = true AND Profile.Name = 'Sales - Media' LIMIT 1];
        
        //Account acc = [SELECT Id from Account where Name = 'Test Account1' limit 1];

        Contact con = [SELECT Id from Contact where FirstName = '__Test1FirstName' limit 1];

        Test.startTest();
        // Create Case
        Case cs = new Case();
        System.runAs(usr)
        {
            // Run as 'usr' to stamp Case.CreatedById
            cs.Subject = '__ Test Subject';
            cs.origin = 'Others';
            insert cs;
        }
        Case[] testCs = [select Id, ContactId from Case where Id=:cs.Id];
        system.assertEquals(testCs.size(), 1);
        cs = testCs[0];
        //system.assertEquals(cs.ContactId, con.Id);
        Test.stopTest();
    }
    /**
       UpdateContactNameTest()
        - Tests "Update the Case.ContactId with the Case.CreatedById when Case.ContactId = null"
        - Bulk Case, bulk size = 100
        -Changed Bulk size to 10
    */

    /*
    static testmethod void UpdateContactNameTest_Bulk()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Profile pr = [select id from profile where name='Sales - Media'][0];
        User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        // Create Account
        Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;
        // Create Contact
        Contact con = [SELECT Id from Contact where FirstName = '__Test1FirstName' limit 1];

        Test.startTest();
        // Create Cases
        List<Case> csList = new List<Case>();
        Case tempCs;
        for(Integer i=0;i<10;i++)
        {
            tempCs = new Case();
            tempCs.Subject = '__ Test Subject';
            tempCs.origin = 'Others';
            csList.add(tempCs);
        }
        System.runAs(usr)
        {
            // Run as 'usr' to stamp Case.CreatedById
            insert csList;
        }
        Set<Id> csIds = new Set<Id>();
        for(Case cs:csList)
            csIds.add(cs.Id);
        Case[] testCsList = [select Id,ContactId from Case where Id IN :csIds];
        system.assertEquals(testCsList.size(), 10);
        for(Case cs:testCsList)
            system.assertEquals(cs.ContactId, con.Id);

        Test.stopTest();
    }*/

    /**
        AddCreatedByToCaseTeamTest()
        - Test : Add the Case.Created By User to the Case Team with Role = 'Reporter'
    */
    static testmethod void AddCreatedByToCaseTeamTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        //User usr = [SELECT Id from User WHERE Profile.Name = 'Sales - Media' AND IsActive = true LIMIT 1];
        
        Test.startTest();
        // Create Case
        Case cs = [SELECT Id from Case WHERE RecordType.Name = 'Technical' LIMIT 1];
        // Assert that the Created By User was added to the Case Team.
        Set<Id> caseTeamMemberIds = new Set<Id>();
        for(CaseTeamMember ctm : [select MemberId, TeamRoleId from CaseTeamMember where ParentId = :cs.Id])
            caseTeamMemberIds.add(ctm.MemberId);
        system.assertEquals(caseTeamMemberIds.size(), 1);
        //system.assert(caseTeamMemberIds.contains(usr.Id));
        Test.stopTest();
    }
    

    static testmethod void MomentumCaseCreationTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        
        //Profile pr = [select id from profile where name='Sales - Media'][0];
        //User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        //insert usr;
        
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'Sales - Media' AND IsActive = true LIMIT 1];
        
        // Create Account
        //Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //acc.Vertical__c = 'Gaming';
        //acc.Sub_Vertical__c = 'Console Mfs';
        //insert acc;
        
        // Create Contact
        //Contact con = utilTestClass.CreateContact('__Test Contact FirstName','__Test Contact LastName');
        //con.AKAM_Contact_ID__c = 'ABC123';
        //con.AccountId = acc.Id;
        //insert con;

        Test.startTest();
        Case cs = new Case();
        System.runAs(usr)
        {
            // Run as 'usr' to stamp Case.CreatedById
            cs.RecordTypeId=CustomSettingsMomentum.CaseRecord__c;
            cs.Subject = '_____ Test Subject';
            cs.origin = 'Others';
            insert cs;
        }
        // Assert that the Created By User was added to the Case Team.
        Case[] testCs = [select Id, ContactId,Email_to_case__c from Case where Id=:cs.Id];
        system.assertEquals(testCs.size(), 1);
        cs = testCs[0];
        system.assertEquals( cs.Email_to_case__c,False);
        Test.stopTest();
    }
    
    static testmethod void ProdMgmtCaseCreationTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        /*
        Profile pr = [select id from profile where name='Sales - Media'][0];
        User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        // Create Account
        Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;*/
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'Sales - Media' AND IsActive = true LIMIT 1];
        
        // Create Contact
        //Contact con = utilTestClass.CreateContact('__Test Contact FirstName','__Test Contact LastName');
        //con.AKAM_Contact_ID__c = 'ABC123';
        //con.AccountId = acc.Id;
        //insert con;

        Test.startTest();
        // Create Case
        Case cs = new Case();
        System.runAs(usr)
        {
            // Run as 'usr' to stamp Case.CreatedById
            cs.RecordTypeId = CustomSettingsProdMgmt.CaseRecord__c;
            cs.Subject = '_____ Test Subject';
            cs.origin = 'Others';
            insert cs;
        }
        //Case cs = [SELECT Id from Case WHERE RecordType.Name = 'Technical' LIMIT 1];
        // Assert that the Created By User was added to the Case Team.
        //Case[] testCs = [select Id, ContactId,Email_to_case__c from Case where Id=:cs.Id];
        //system.assertEquals(testCs.size(), 1);
        //cs = testCs[0];
        //system.assertEquals( cs.Email_to_case__c,False);

        Test.stopTest();
    }
    

    static testmethod void AddCreatedByToCaseTeamTest_Bulk()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        /*
        Profile pr = [select id from profile where name='Sales - Media'][0];
        User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        // Create Account
        Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //end Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;*/
        // Create Contact

        //Contact con = utilTestClass.CreateContact('__Test Contact FirstName','__Test Contact LastName');
        //con.AKAM_Contact_ID__c = 'ABC123';
        //con.AccountId = acc.Id;
        //insert con;
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'Sales - Media' AND IsActive = true LIMIT 1];
        Test.startTest();
        // Create Cases
        List<Case> csList = new List<Case>();
        Case tempCs;
        for(Integer i=0;i<10;i++)
        {
            tempCs = new Case();
            tempCs.Subject = '__ Test Subject';
            tempCs.origin = 'Others';
            csList.add(tempCs);
        }
        System.runAs(usr)
        {
            // Run as 'usr' to stamp Case.CreatedById
            insert csList;
        }
        // Assert that the Created By User was added to the Case Team.
        // Get a set of the Case Ids
        Set<Id> caseIds = new Set<Id>();
        for(Case c:csList)
            caseIds.add(c.Id);
        Map<Id, Id> caseTeamMemberMap = new Map<Id, Id>();
        // Get a map of the Case Team members
        for(CaseTeamMember ctm : [select ParentId, MemberId, TeamRoleId from CaseTeamMember where ParentId IN :caseIds])
            caseTeamMemberMap.put(ctm.ParentId, ctm.MemberId);
        // Assert
        system.assertEquals(caseTeamMemberMap.keySet().size(), 10);

        Test.stopTest();
    }

    static testmethod void addCaseInvoiceTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        /*
        Profile pr = [select id from profile where name='Sales - Media'][0];
        User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        // Create Account
        Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //Start Modified By Chandra For CR 693820
        acc.Vertical__c = 'Gaming';
        //end Modified By Chandra For CR 693820
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;
        // Create Contact
        Contact con = [SELECT Id from Contact where FirstName = '__Test1FirstName' limit 1];
        */
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'Sales - Media' AND IsActive = true LIMIT 1];
        Test.startTest();
        // Create Cases
        List<Case> csList = new List<Case>();
        Case tempCs;
        for(Integer i=0;i<10;i++)
        {
            tempCs = new Case();
            tempCs.Subject = '__ Test Subject';
            tempCs.origin = 'Others';
            csList.add(tempCs);
        }
        System.runAs(usr)
        {
            // Run as 'usr' to stamp Case.CreatedById
            insert csList;
        }
        Account acc = [SELECT Id from Account LIMIT 1];
        Case_Invoice__c caseInvoice=new Case_Invoice__c(Account__c=acc.Id,Case_Id__c=csList[0].id);
        try
        {
            insert caseInvoice;
        }
        Catch(Exception e)
        {
            Boolean errorMatch=e.getMessage().contains('Case Account and Related Invoice account should match.');
            System.assert(errorMatch,true);
        }

        Test.stopTest();
    }
    
    static testmethod void testCollectionEmailHandlerFunctionality()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        //Profile pr = [select id from profile where name='Sales - Media'][0];
        //User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='859247__usr2505@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        //insert usr;
        // Create Account
        //Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //Start Modified By Chandra For CR 693820
        //acc.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        //acc.Sub_Vertical__c = 'Console Mfs';
        //insert acc;
        
        User usr = [SELECT Id FROM User WHERE Profile.Name = 'Sales - Media' AND IsActive = true LIMIT 1];
        // Create Contact
        Contact con = [SELECT Id,Email from CONTACT where FirstName = '__Test1FirstName' limit 1];
        Test.startTest();
        Account acc = [SELECT Id from Account LIMIT 1];
        // Create Case
        Case cs = new Case();
        System.runAs(usr)
        {
            cs.Collection_Account__c=acc.Id;
            cs.RecordTypeId=CustomSettingsCollections.CaseRecord__c;
            cs.origin = 'Others';
            insert cs;
        }
        cs=[select Id,CaseNumber From Case where id=:cs.id];

        Messaging.InboundEmail email= new Messaging.InboundEmail();
        email.fromAddress=con.email;
        email.Subject='Case # '+cs.CaseNumber+' : This is a test subject';
        email.toAddresses=new String[]{'someUserEmail@akamai.com'};
            email.htmlBody='This is a test body';

        Messaging.InboundEnvelope envelope=new Messaging.InboundEnvelope();
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfileone.txt';
        attachment.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
            // add an Text atatchment
            Messaging.InboundEmail.TextAttachment attachmenttext = new Messaging.InboundEmail.TextAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfiletwo.txt';
        attachment.mimeTypeSubType = 'texttwo/plain';
        email.textAttachments =   new Messaging.inboundEmail.TextAttachment[] { attachmenttext };

        CollectionsInboundEmailHandler cinh=new CollectionsInboundEmailHandler();
        cinh.handleInboundEmail(email, envelope);

        List<EmailMessage> emailMessageList=[select Id,parentId from EmailMessage where parentId= :cs.id];
        system.assertNotEquals(emailMessageList,null);
        system.assertEquals(emailMessageList.size(),1);
        Test.stopTest();
    }

    static testmethod void caseDelete_PositiveTest()
    {
        //User sysAdmin = utilTestClass.CreateUser('SYS_USER', 'System Administrator', 'System Administrator');
        //insert (new User[] {sysAdmin});
        User sysAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];
        System.runAs(sysAdmin)
        {
            Case cs = new Case();
            cs.Description = 'this is test';
            cs.origin = 'Others';
            Test.startTest();
            insert cs;
            delete cs;
            Test.stopTest();
        }
    }

    static testmethod void caseDelete_NegativeTest()
    {
        //User cmgUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');
        //User sysAdmin = utilTestClass.CreateUser('SYS_USER', 'System Administrator', 'System Administrator');
        //insert (new User[] {cmgUser, sysAdmin});
        User cmgUser = [SELECT Id FROM User WHERE Profile.Name = 'CMG' AND IsActive = true LIMIT 1];
        
        System.runAs(cmgUser)
        {
            Case cs = new Case();
            cs.Description = 'this is test';
            cs.origin = 'Others';
            cs.Case_Origin_Department__c = 'AMG';
            Test.startTest();
            insert cs;
            try
            {
                delete cs;
            }
            catch (Exception ex)
            {
                System.assert(ex.getMessage().containsIgnoreCase('Insufficient'));
            }
            Test.stopTest();
        }
    }

    //Test method for Managed Security methods in SC_CaseTriggerHelperClass
    static testmethod void test_AuthorisedContacts()
    {
        Contact con = [Select Id from Contact limit 1];
        Case cs = new Case();
        cs.Description = 'test';
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        cs.Subject = 'test';
        cs.ContactId = con.Id;
        cs.AuthorizedContacts__c = 'abc@xyz.com';
        cs.Attack_Report_Link__c = 'www.newlink.com';
        cs.Alternate_Contact_Email__c = 'hi@abc.com';
        insert cs;
        test.startTest();
            cs.AuthorizedContacts__c = 'test@test.com';
            cs.status = 'Closed-Auto';
            //Changes by Vandhana
            cs.Living_Summary_Next_Steps__c = '<super>New</super> Updated Living Summary : <img src="http://google.com"></img>';
            //End of changes by Vandhana
            update cs;
        test.stopTest();
    }
    
    static testmethod void test_ManagedSoccLivingSummary()
    {
        Test.startTest();
        Case cs = new Case();
        cs.Description = 'test';
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        cs.Subject = 'test';
        cs.Attack_Report_Link__c = 'www.newlink.com';
        cs.Alternate_Contact_Email__c = 'hi@abc.com';
        cs.Living_Summary_Next_Steps__c = '<super>New</super> Updated Living Summary : <img src="http://google.com"></img>';
        insert cs;
        test.stopTest();
    }

    //Test method for Verivue methods in SC_CaseTriggerHelperClass
    static testmethod void test_VerivueUpdate()
    {
        //Account acc = utilTestClass.CreateAccount('Test1Account');
        //insert acc;
        Account acc = [SELECT Id from Account LIMIT 1];
        Contact con = [SELECT Id from Contact where FirstName = '__Test1FirstName' limit 1];
        test.startTest();
        List<Case> lstCase = new List<Case>();

        Case cs = new Case();
        cs.Description = 'test';
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs.Sub_Type__c = 'Carrier';
        cs.Subject = 'test';
        cs.Validation_Override__c = true;
        lstCase.add(cs);

        Case cs1 = new Case();
        cs1.Description = 'testStabEngg';
        cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stability Engineering').getRecordTypeId();
        cs1.Subject = 'testStabEngg';
        cs1.Validation_Override__c = true;
        lstCase.add(cs1);

        Case cs2 = new Case();
        cs2.Description = 'testEmerEngg';
        cs2.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Emerging Products Engineering').getRecordTypeId();
        cs2.Subject = 'testEmerEngg';
        cs2.Validation_Override__c = true;
        lstCase.add(cs2);

        Group g = [Select Id, Name From Group Where Type = 'Queue' And Name = 'Primary/Secondary Assignment Queue' limit 1];

        EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c(Name='mPulse',EB_MarkedForDeletion__c = false,EB_Product__c='Test-456',EB_Account__c=acc.id);

        EB_AccountProductMap__c eb_product1 = new EB_AccountProductMap__c(Name='Octoshape',EB_MarkedForDeletion__c = false,EB_Product__c='Octoshape',EB_Account__c=acc.id);

        insert new List<EB_AccountProductMap__c>{
            eb_product,eb_product1
        };

        Case cs3 = new Case();
        cs3.AccountId = acc.Id;
        cs3.Description = 'testTech';
        cs3.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs3.Subject = 'testTech';
        cs3.Sub_Type__c = 'SSL Support';
        cs3.OwnerId = g.Id;
        cs3.Associated_Email__c = 'abc@xyz.com';
        cs3.Case_Product__c  = eb_product.Id;
        cs3.Origin = 'Phone';
        cs3.Validation_Override__c = true;
        lstCase.add(cs3);

        cs3 = new Case();
        cs3.AccountId = acc.Id;
        cs3.Description = 'testTechOcto';
        cs3.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs3.Subject = 'testTechOcto';
        cs3.Sub_Type__c = 'SSL Support';
        cs3.OwnerId = g.Id;
        cs3.Associated_Email__c = 'abc1@xyz.com';
        cs3.Case_Product__c  = eb_product1.Id;
        cs3.Origin = 'Phone';
        cs3.Severity__c = '1';
        cs3.Do_Not_Show_in_Portal__c = false;
        cs3.Validation_Override__c = true;
        lstCase.add(cs3);

        insert lstCase;
        lstCase.clear();
        test.stopTest();

        List<Case> csL = new List<Case>();

        cs.ContactId = con.Id;
        cs.Do_Not_Show_in_Portal__c = False;
        cs.NextStepsExternal__c = 'Test';
        csL.add(cs);

        update csL;
        //cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        //cs1.Validation_Override__c = true;
        //update cs1;
        CaseTriggerClass.EmailToCaseSendEmail(new Case[] {cs3},Email_to_Case__c.getInstance('Momentum'),new String[]{'"abc@xyz.com"<abc@xyz.com>'});


    }

    static testMethod void test_changeCaseOwner()
    {
        Group g = [Select Id, Name From Group Where Type = 'Queue' And Name = 'Primary/Secondary Assignment Queue' limit 1];
        test.startTest();
        Case cs4 = [SELECT Id,OwnerId FROM Case where RecordType.Name = 'AMG' order by CreatedDate desc limit 1];
        cs4.OwnerId = g.id;
        update cs4;
        cs4.OwnerId = UserInfo.getUserId();
        update cs4;
        test.stopTest();
    }

    static testmethod void test_PreSalesCases()
    {
       /*
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account1' limit 1];
        //insert acc;

        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp = utilTestClass.CreateOpportunity('OppTest1','1-Create');
        opp.AccountId = acc.Id;
        opp.CloseDate = System.today().addDays(100);
        opp.Deal_Type__c='Direct';
        oppList.add(opp);

        Opportunity opp1 = utilTestClass.CreateOpportunity('OppTest2','1-Create');
        opp1.AccountId = acc.Id;
        opp1.CloseDate = System.today().addDays(100);
        opp1.Deal_Type__c='Direct';
        oppList.add(opp1);

        insert oppList;

        User currentusr = [Select id,Manager.Name,Office_Location__c,Shift__c,Support_Role__c,Team__c,Owner_Support_Department__c from User where Id = :UserInfo.getUserId()];

        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = opp.id;
        otm.TeamMemberRole = 'Technical Sales - Primary';
        //otm.UserId = currentusr.id;
        otm.UserId = UserInfo.getUserId();
        insert otm;

        List<Case> lstCase = new List<Case>();
        Case cs1 = new Case();
        cs1.Description = 'testPreSales1';
        cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Pre-Sales').getRecordTypeId();
        cs1.Subject = 'testPreSalesSub1';
        cs1.AccountId = acc.Id;
        cs1.Opportunity__c = opp1.Id;
        lstCase.add(cs1);

        Case cs = new Case();
        cs.Description = 'testPreSales';
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Pre-Sales').getRecordTypeId();
        cs.Subject = 'testPreSalesSub';
        cs.AccountId = acc.Id;
        cs.Opportunity__c = opp.Id;
        lstCase.add(cs);

        List<Case> lstCases = new List<Case>();
        test.startTest();
            insert lstCase;
            //cs.OwnerId = usr.Id;
            cs.OwnerId = UserInfo.getUserId();
            lstCases.add(cs);
            cs1.OwnerId = UserInfo.getUserId();
            lstCases.add(cs1);
            update lstCases;
            //update cs;
            //update cs1;
            //CaseTriggerClass.setCaseOwnerWithStatus(cs.Id,UserInfo.getUserId(),new List<Case>{cs},new Map<Id,User>{UserInfo.getUserId() => currentusr});
        test.stopTest();  */
    }

    // changes by Vandhana to cover CaseTrigger_bi_bu and CaseTrigger_ai changes for ESESP-595
    static testmethod void test_PSCaseS2ET()
    {
        List<Case> cl = new List<Case>();
        Case c1 = [Select Id,OwnerId from Case where Subject = 'testS2ET1' limit 1];

        Test.startTest();
        c1.Severity__c = '2';
        c1.Service__c = 'Kona DDoS Defender';
        cl.add(c1);
        try
        {
            update cl;
        }
        catch (Exception e)
        {}
        Test.stopTest();
    }

    // changes by Vandhana to cover IR related Case on CaseTriggerClass
    static testmethod void test_IRCaseTriggerClass()
    {
        Id userId = [Select Id from User where Profile.Name = 'GSS Professional Services' AND isActive = true limit 1].Id;
        Case irCase = [Select IR_Escal_Owner__c from Case where RecordType.Name = 'Invoice Review Case' limit 1];
        Test.startTest();
        irCase.IR_Escal_Owner__c = userId;
        update irCase;
        Test.stopTest();
    }

    // changes by Sumanth to cover ESESP-1004 on CaseTriggerClass
    static testmethod void test_Carrierproductclass()
    {
        //Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //insert acc;
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account1' limit 1];

        Case cp = new Case();
        cp.Description = 'Test Nominum';
        cp.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cp.Sub_Type__c = 'Carrier';
        cp.Subject = 'Test Nominum';
        cp.AccountId = acc.id;
        cp.Sub_Type__c = 'Proactive';
        cp.Severity__c = '3';
        cp.Status = 'unassigned';
        cp.Origin = 'Email';
        cp.PS_Product__c = 'Aura LCDN';
        cp.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
        cp.Solution_Code__c = 'Configuration Error';
        cp.Software_Version__c = '3.1';
        cp.Validation_Override__c = false;

        Test.startTest();
        insert cp;
        External_Dependency__c ed = new External_Dependency__c();
        ed.Type__c ='JIRA';
        ed.Case__c = cp.id;
        insert ed;
        //Case cp1 = [Select Id,Solution_code__c,Validation_Override__c from Case where id = :cp.id];
        cp.Solution_Code__c = 'New Software Failure';
        update cp;
        Test.stopTest();
    }

    static testMethod void testAMGUseCase(){
        Account acc = utilTestClass.CreateAccount('__ Test Account213');
        insert acc;

        List<Case> lstCase = new List<Case>();

        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = 'Support - AMG Agent' AND IsActive = TRUE LIMIT 2];

        List<Case> csList = new List<Case>();
        Case cp2 = new Case();
        cp2.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        cp2.AccountId= acc.id;
        cp2.Subject= 'Test AMG autogen';
        cp2.Description ='Test AMG autogen';
        cp2.Origin='Autogen';
        cp2.Status = 'Assigned';
        cp2.Autogen_UseCase__c = 'ECOB';
        cp2.Validation_Override__c = true;
        cp2.OwnerId = userList[0].Id;
        csList.add(cp2);


        Test.startTest();
        insert csList;

        cp2.Status = 'Closed';
        cp2.Validation_Override__c = true;
        update cp2;
        test.stopTest();
    }

    //Changes by Sumanth for ESESP-934
    static testmethod void test_ManagedSecurityRouting()
    {
        //Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //insert acc;

        Account acc = [SELECT Id,Name,BillingCountry,BillingState FROM Account WHERE Name = '__ Test Account213' LIMIT 1];

        List<Case> lstCase = new List<Case>();

        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = 'Support - Tech Support Manager' AND IsActive = TRUE LIMIT 2];

        List<Case> csList = new List<Case>();
        Case cp1 = new Case();
        cp1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        cp1.AccountId= acc.id;
        cp1.Subject= 'Test Managed Security Routing';
        cp1.Description ='Test Managed Security Routing';
        cp1.origin='Email';
        cp1.OwnerId = userList[0].Id;
        csList.add(cp1);

        insert csList;

        Test.startTest();

        cp1.OwnerId = userList[1].Id;
        lstCase.add(cp1);

        try{
            update lstCase;
        }
        catch(Exception e){
            System.debug('Exeption caught');
        }
        test.stopTest();
    }

     //Changes by Sumanth for ESESP-1204
    static testmethod void test_sendEmailPreSales()
    {
        //Account acc = utilTestClass.CreateAccount('__ Test Account213');
        //insert acc;
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //69
        Account acc = [SELECT Id FROM Account WHERE Name = 'Test Account1' limit 1];
        List<User> userList = [SELECT Id FROM User WHERE Profile.Name = 'Support - Tech Support Manager' AND IsActive = TRUE LIMIT 2];

        Test.startTest();

        Case cp = new Case();
        cp.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Pre-Sales').getRecordTypeId();
        cp.AccountId= acc.id;
        Cp.Subject= 'Test Managed Security Routing';
        Cp.Description ='Test Managed Security Routing';
        Cp.Request_Type__c='Web Performance Architect';
        //Cp.Opportunity__c = opp1.id;
        Cp.origin='Email';
        insert cp;

        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //24

        cp.OwnerId = userList[0].id;
        update cp;
        System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
        //41
        Test.stopTest();
    }

    static testMethod void test_ERMgmtTechEsc()
    {
        Account acc = [Select Id from Account where Name = 'Test Account1' limit 1];

        //EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c(Name='Enterprise Application Access',EB_MarkedForDeletion__c = false,EB_Product__c='EAA-123',EB_Account__c=acc.id);
        //insert eb_product;

        List<Technical_Escalation_Config_Interface__c> tchList = new List<Technical_Escalation_Config_Interface__c>();
        for(Integer i=0;i<3;i++)
        {
            Technical_Escalation_Config_Interface__c tch = new Technical_Escalation_Config_Interface__c();
            tch.Include_Weekend__c = false;
            tch.Severity__c = i+1;
            tch.Support_Level__c = 'Premier';
            tch.Time_Hours__c = i+1;
            tch.Support_Advocacy__c = true;
            tchList.add(tch);
        }
        insert tchList;
        
        List<Case> caseLst = new List<Case>();

        Test.startTest();
        List<Case> caseLst1 = [Select Escalate_Technical_Case__c,Escalate_Technical_Mgmt_Case__c,Subject from Case
                               WHere Subject like '%New Tech Case%'];
        for(Case c1 : caseLst1)
        {
            if(c1.Subject == 'New Tech Case 1')
                c1.Escalate_Technical_Case__c = true;
            else
                c1.Escalate_Technical_Mgmt_Case__c = true;
            caseLst.add(c1);
        }
        update caseLst;
        Test.stopTest();
    }

    static testMethod void test_UpdateAccountsProductsonSI()
    {
        Case c = [Select Incident__c,AccountId from Case where Subject = 'Tech Case 1' limit 1];
        
        Test.startTest();
        List<SC_SI_Service_Incident__c> lstIncident = new List<SC_SI_Service_Incident__c>();
        SC_SI_Service_Incident__c siRecord = new SC_SI_Service_Incident__c();
        siRecord.Status__c = 'Incident Request';
        siRecord.Severity__c ='Severity 1';
        siRecord.Title__c = 'Test Incident 1';
        siRecord.Summary__c ='Test Summary';
        siRecord.Symptoms__c ='Test Symptoms';
        siRecord.What_Incident_Criteria_is_Met__c='Test Criteria';
        siRecord.Customer_Temperature__c ='High';
        siRecord.How_was_the_issue_detected__c = 'Customer';
        siRecord.Customer_Advisory__c = 'Test Advisory';
        lstIncident.add(siRecord);
        insert lstIncident;
        //SC_SI_Service_Incident__c inc = [Select Id from SC_SI_Service_Incident__c limit 1];
        
        c.Service_Incident__c = siRecord.Id;
        Account a = [Select Id from Account where name = 'Test Account2' limit 1];
        c.AccountId = a.Id;
        c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        c.Validation_Override__c = true;
        update c;
        Test.stopTest();
    }

    static testMethod void test_addAMPCaseProduct()
    {
        Account acc = [Select Id from Account where Name = 'Test Account1' limit 1];

        EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c(Name='Adaptive Media Player',EB_Product__c='Adaptive Media Player',EB_MarkedForDeletion__c = false,
                                                                         EB_Account__c=acc.id);
        insert eb_product;

        List<Case> caseLst = new List<Case>();

        Case c = new Case();
        c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //c.Case_Product__c = eb_product.Id;
        c.Do_Not_Show_in_Portal__c = false;
        c.Sub_Type__c = 'Product Support';
        c.Status = 'Assigned';
        c.Severity__c = '1';
        c.Origin = 'Email';
        c.AccountId = acc.Id;
        c.Subject = 'AMP Tech Case 1';
        c.Level_of_Impact__c = 'Low';
        c.Customer_Temperature__c = 'Low';
        c.Service_Category__c = 'Media-AMP';
        c.Validation_Override__c = true;

        caseLst.add(c);

        c = new Case();
        c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //c.Case_Product__c = eb_product.Id;
        c.Do_Not_Show_in_Portal__c = false;
        c.Sub_Type__c = 'Product Support';
        c.Status = 'Assigned';
        c.Severity__c = '1';
        c.Origin = 'Email';
        c.Subject = 'AMP Tech Case 2';
        c.AccountId = acc.Id;
        c.Level_of_Impact__c = 'Low';
        c.Customer_Temperature__c = 'Low';
        c.Validation_Override__c = true;
        c.Service_Category__c = 'Media-AMP';
        caseLst.add(c);


            Merge_Contract_Header__c merge_contract = new Merge_Contract_Header__c();
            merge_contract.Name                       ='2Test Merge Contract-19';
            merge_contract.Contract_Id__c             ='2Test-123-19';
            merge_contract.Original_Contract_Id__c    ='2Test-123-19';
            merge_contract.Account_Name__c            = acc.Id;
            merge_contract.Locked__c                  = true;
            merge_contract.Cancellation_Date__c       = Null;
            merge_contract.Contract_Transferred_To__c = Null;
            merge_contract.Is_COB_Created__c          = False;
            merge_contract.Effective_Start_Date__c    = system.Today().addDays(-14);
            merge_contract.Effective_End_Date__c      = system.Today().addMonths(6);
            merge_contract.AKAM_Created_Date__c       = system.Today();
            merge_contract.Active__c                  = true;
            insert merge_contract;

        Merge_Contract_Detail__c mcd        = new Merge_Contract_Detail__c();
        mcd.Original_Contract_Id__c         =  merge_contract.Id;
        mcd.Effective_Start_Date__c         =   system.Today().addDays(-14);
        mcd.Effective_End_Date__c           =   system.Today().addMonths(6);
        mcd.Product_Id__c                   =   'M-LC-125821';
        mcd.Units_Low__c                    =   12;
        mcd.Units_High__c                   =   12;
        mcd.Unit_of_Measure__c              =   'Reviews';
        mcd.Product__c                      =   'M-LC-125821';
        mcd.AKAM_Created_Date__c            = system.Today();
        mcd.Original_Detail_Id__c           =  'UniqueId-1119';
        insert mcd;

        Test.startTest();
        insert caseLst;
        caseLst.clear();
        Test.stopTest();

    }

    //Test class for 1916
    static testmethod void test_checkAMGAttachments1()
    {
          Account acc = [Select Id from Account where Name = 'Test Account1' limit 1];
          Case cup = [SELECT Id from Case WHERE RecordType.Name = 'AMG' limit 1];

          try
          {
              cup.Status = 'Closed';
              Test.startTest();
              update Cup;
              Test.stopTest();
          }
          catch(Exception e)
          {
             Boolean ExpectedError = e.getMessage().contains('Cases cannot be closed without a peer review file')?true:false;
             system.debug('Error '+ExpectedError);
             //System.AssertEquals(ExpectedError,true);
          }

    }

    //Test class for 1916
    static testmethod void test_checkAMGAttachments2()
    {
        Account acc = [Select Id from Account where Name = 'Test Account1' limit 1];
        Case c2 = [SELECT Id from Case WHERE RecordType.Name = 'AMG' limit 1];

        Test.startTest();

        String myString = 'StringToBlob';
        Blob myBlob = Blob.valueof(myString);
        Attachment a = new Attachment(ParentId = c2.id, Name = 'xyz.txt', Body = myBlob);
        insert a;
        try
        {
            Case c3 = [Select status,OwnerId from Case where id = :c2.id];
            c3.Status = 'Closed';
            update c3;
        }
        catch(Exception e)
        {
            Boolean ExpectedError = e.getMessage().contains('Cases cannot be closed without a peer review file')?true:false;
            system.debug('Error '+ExpectedError);
            //System.AssertEquals(ExpectedError,true);
        }
        Test.StopTest();
    }

    testMethod static void testAmgTransition()
    {
        insert new SC_RiverbedCaseProductRestriction__c(SetupOwnerId=UserInfo.getOrganizationId(), CaseProductName__c ='Riverbed SAAS OEM', RecordTypeName__c  = 'Emerging Products Engineering');
        Case c = [SELECT Id,AccountId,RecordTypeId,Case_Product__c from CASE where RecordType.Name = 'Technical' limit 1];

        Test.startTest();
        SlaProcess amgEntProcess = [SELECT Id, description, name, VersionNumber From SlaProcess Where Name='AMG' Order By VersionNumber DESC][0];
        Entitlement amgEntitlement = new Entitlement();
        amgEntitlement.Name = 'AMG Entitlement';
        amgEntitlement.AccountId = c.AccountId;
        amgEntitlement.slaProcessId = amgEntProcess.Id;
        amgEntitlement.StartDate = System.today() - 1;
        amgEntitlement.EndDate = System.today() + 1;
        insert amgEntitlement;

        EntitlementID__c amgEntId = new EntitlementID__c();
        amgEntId.Name = 'AMG';
        amgEntId.Case_Record_Type__c = 'AMG';
        amgEntId.EntitlementID__c = amgEntitlement.Id;
        insert amgEntId;

        // Trasitioning to AMG
        c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        //aCase.entitlementId = amgEntitlement.Id;
        c.Case_Product__c = null;
        c.OwnerId = [SELECT Id from User WHERE Profile.Name = 'Support - AMG Agent' and IsActive = TRUE LIMIT 1].Id;
        c.Validation_Override__c = true;
        //c.Case_Assignment_Using_Active_Rules__c = TRUE;
        update c;

        c.Status = 'Closed';
        c.Resolved_Date__c  = System.now();
        c.Resolution_Field__c  = 'N/A - Not Applicable';
        c.Solution_Summary__c  = 'Test';
        c.ResolvableByPartner__c = 'N/A';
        c.Service__c = 'Accounts Audits';
        c.Request_Type__c = 'Information Request';
        c.LOE_Hours__c  = 1;
        c.LOE_Minutes__c = 0;
        c.Request_Sub_Type__c = 'N/A - Not Applicable';
        c.Validation_Override__c = true;

        try
        {
            update c;
        }
        catch(Exception ex)
        {
            //System.assert(ex.getMessage().Contains('Please send out "AMG Post Transition Initial Response" to the customer before closing the case'));
        }
        Test.stopTest();
    }

    /********* Test Classes for SOCC Related Changes ***********/
    static testmethod void test_populatepriorityandInstructflag()
    {
        Contact con = [SELECT Id,AccountId from Contact where FirstName = '__Test1FirstName' limit 1];

        //Create Case Product
        EB_AccountProductMap__c cproduct = new EB_AccountProductMap__c();
        cproduct.Name ='Test Product SOCC';
        cproduct.EB_Product__c = 'Test Product SOCC';
        cproduct.EB_Account__c = con.AccountId;

        Policy_Domain__c Pd = new Policy_Domain__c();
        Pd.Name = 'Test PD SOCC';
        Pd.Product__c = 'Test Product SOCC';
        Pd.Account_Name__c = con.AccountId;
        Pd.Policy_Domain_State__c='Active';

        //Create Authorized Contact
        Authorized_Contact__c authcont = new Authorized_Contact__c();
        authcont.Contact_Name__c = con.Id;
        authcont.Policy_Domain__c = Pd.Id;
        authcont.Instruct__c = true;

        //Create Managed Security Case
        Case cs = new Case();
        cs.Description = 'test socc case';
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        cs.Subject = 'test';
        cs.ContactId = con.Id;
        cs.AccountId = con.AccountId;
        cs.Case_Product__c = cproduct.Id;

        //Create a new Task Open
        Task t = new Task();
        t.Subject = 'Referral SOCC Test';
        t.Type__c = 'Customer Follow-Up';
        t.WhatId = cs.Id;

        Test.startTest();

        insert cproduct;
        insert Pd;
        insert authcont;
        insert cs;
        insert t;

        //Update Case record
        try
        {
           CaseTriggerClass.avoidRecursionSOCCLogic = true;
           cs.Status ='Closed';
           cs.Policy_Domain__c = Pd.Id;
           update cs;
        }
        catch(Exception e)
        {
            Boolean ExpectedError = e.getMessage().contains('You cannot close a Managed Security Case with one or more Open Tasks')?true:false;
            system.debug('Error '+ExpectedError);
            //System.AssertEquals(ExpectedError,true);
        }
        Test.stopTest();
    }
    
    //ESESP-5340
    @IsTest
    static void testPlusEnhancedSLA(){
        Map<String,Account> accounts = new Map<String, Account>();
        for (Account acc :  [SELECT Id,Name FROM Account WHERE  Name IN :new List<String>{'Salesforce','Test Account2'}]){
            accounts.put(acc.Name,acc);
        }
        SlaProcess entitlementProcess = [SELECT Id From SlaProcess Where Name='Technical_Extension' AND IsVersionDefault = TRUE];
        Entitlement technicalExt = new Entitlement();
        technicalExt.Name = 'Technical_Ext';
        technicalExt.AccountId = accounts.get('Test Account2').Id;
        technicalExt.SlaProcessId = entitlementProcess.Id;
        insert technicalExt;
        EntitlementID__c entitlementID = new EntitlementID__c();
        entitlementID.EntitlementID__c = technicalExt.Id;
        entitlementID.Name = 'Technical_Ext';
        entitlementID.Support_Level__c = 'Plus_EnhancedSLA';
        entitlementID.Case_Record_Type__c = 'TechnicalAll_Ext';
        insert entitlementID;
        Test.startTest();
        Case technicalCase = new Case();
        technicalCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        technicalCase.AccountId = accounts.get('Salesforce').Id;
        technicalCase.Support_Level__c = 'Plus_EnhancedSLA';
        technicalCase.Subject = 'Test Subject';
        technicalCase.Origin = 'Web';
        technicalCase.Do_Not_Show_in_Portal__c = false;
        technicalCase.Do_Not_Show_In_Portal_Picklist__c = 'Customer';
        technicalCase.Description = 'Test Description';
        insert technicalCase;
        Test.stopTest();
        System.debug('CaseId: '+technicalCase.Id);
        Case c = [SELECT Id,EntitlementId,Entitlement.Name FROM Case WHERE Id = :technicalCase.Id];
        System.debug(c.EntitlementId);
        System.debug(c.Entitlement.Name);
        System.assert(c.EntitlementId == technicalExt.Id);

    }
    
}