@isTest(seeAllData = false)
private class LeadToContactConversionTests
{
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 5; 

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(dmlUser)
        {
            List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .put(Account.Type, 'Lead')
                .count(numberOfTestLeads)
                .create()
                .getRecords();


            List<Contact> listOfTestContacts = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, listOfTestAccounts)
                .put(Contact.Authorized_For_Marketplace__c, true)
                .count(numberOfTestLeads)
                .create()
                .getRecords();

            Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            Lead l = new Lead();
            l.RecordTypeId = akamaiRecordTypeId;
            l.email = 'test2@akamai.com.invalid';
            l.Status = 'New';
            l.firstname = 'Test';
            l.lastname = 'Test2';
            l.Associated_Account__c = listOfTestAccounts[0].Id;
            l.Company = 'Test Company';
            l.Product_Line__c = 'Media';
            insert l;

            Id akamaiRecordType= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
            Lead al = new Lead();
            al.RecordTypeId = akamaiRecordType;
            al.email = 'test3@akamai.com.invalid';
            al.Status = 'New';
            al.firstname = 'Test';
            al.lastname = 'Test2';
            al.Associated_Account__c = listOfTestAccounts[0].Id;
            al.Parent_Lead__c = l.Id;
            al.Company = 'Test Company';
            al.Product_Line__c = 'Media';
            al.Country = 'Brazil';
            insert al;

        }

    }


    static testmethod void verifyContactUpdatesSyncToC2A() 
    {
        System.runAs(dmlUser) 
        {

            List<Contact> nContacts = SobjectRepository.getContacts(numberOfTestLeads);
            Set<Id> contactIds = new Set<Id>();
            for (Contact ithContact : nContacts) 
            {
                contactIds.add(ithContact.Id);
            }   
            List<Lead> akamaiLeads = [select Associated_Opportunity__c,id,Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Lead where Associated_Contact__c in :contactIds];
            System.assert((akamaiLeads==null || akamaiLeads.size()==0), 'Akamai leads already exist for these contacts:'+akamaiLeads);

            for (Contact ithContact : nContacts) 
            {
                ithContact.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
                ithContact.Lead_Qualification_Status__c='Prospect';
            }
            Test.startTest();
            update nContacts;

            akamaiLeads = SobjectRepository.refresh(akamaiLeads);

            for(Lead ithLead: akamaiLeads)
            {
                System.assert(ithLead.Lead_Qualification_Stage__c=='Qualified Lead - Warm', 'ithlead was:'+ithLead);
                System.assert(ithLead.Lead_Qualification_Status__c=='Prospect', 'ithlead was:'+ithLead);
                }
            for (Contact ithContact : nContacts) 
            {
                ithContact.Lead_Qualification_Status__c='Engaged';
            }   
            LeadToContactConversionClass.updateC2ALeadFromPersonContactOrLeadFirstRunFlag=true;
            update nContacts;
            Test.stopTest();

            akamaiLeads = SobjectRepository.refresh(akamaiLeads);
            for(Lead ithLead: akamaiLeads)
            {
                System.assert(ithLead.Lead_Qualification_Status__c=='Engaged', 'ithlead was:'+ithLead);
            }
        }
    }


    static testmethod void verifyC2AClosesOnTurningBackAllWarmBPPStatuses() 
    {
        System.runAs(dmlUser) 
        {

            List<Contact> nContacts = SobjectRepository.getContacts(numberOfTestLeads);
            Set<Id> contactIds = new Set<Id>();
            for (Contact ithContact : nContacts) 
            {
                contactIds.add(ithContact.Id);
            }   
            List<Lead> akamaiLeads = [select Associated_Opportunity__c,id,Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Lead where Associated_Contact__c in :contactIds];

            System.assert((akamaiLeads==null || akamaiLeads.size()==0), 'Akamai leads already exist for these contacts:'+akamaiLeads);

            for (Contact ithContact : nContacts) 
            {
                ithContact.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
                ithContact.Lead_Qualification_Status__c ='Prospect';
            }   
            Test.startTest();
            update nContacts;

            akamaiLeads = SobjectRepository.refresh(akamaiLeads);

            for(Lead ithLead: akamaiLeads)
            {
                System.assert(ithLead.Lead_Qualification_Stage__c=='Qualified Lead - Warm', 'ithlead was:'+ithLead);
                System.assert(ithLead.Lead_Qualification_Status__c=='Prospect', 'ithlead was:'+ithLead);
            }
            for (Contact ithContact : nContacts) 
            {
                ithContact.Lead_Qualification_Status__c='Turnback Bad Phone Number';
            }   
            LeadToContactConversionClass.updateC2ALeadFromPersonContactOrLeadFirstRunFlag=true;
            update nContacts;
            Test.stopTest();

            akamaiLeads = SobjectRepository.refresh(akamaiLeads);
            for(Lead ithLead: akamaiLeads)
            {
                System.assert(ithLead.Status=='Closed', 'ithlead was:'+ithLead);
            }
        }
    }

    static testmethod void verifyAllQualifyingBPPStatusAreClosedOnClosingAnyQualifyingBPPStatus() 
    {
        System.runAs(dmlUser) 
        {

            LiveChatVisitor lcv = new LiveChatVisitor();
            insert lcv;
            
            LiveChatTranscript lct = new LiveChatTranscript();
            lct.LiveChatVisitorId = lcv.id;
            insert lct;

            List<Contact> nContacts = SobjectRepository.getContacts(numberOfTestLeads);
            Set<Id> contactIds = new Set<Id>();
            for (Contact ithContact : nContacts) 
            {
                contactIds.add(ithContact.Id);
            }   
            List<Lead> akamaiLeads = [select Status,Associated_Opportunity__c,id,Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Lead where Associated_Contact__c in :contactIds];

            System.assert((akamaiLeads==null || akamaiLeads.size()==0), 'Akamai leads already exist for these contacts:'+akamaiLeads);


            for (Contact ithContact : nContacts) 
            {
                ithContact.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
                ithContact.Lead_Qualification_Status__c='Prospect';
            }   
            Test.startTest();
            update nContacts;

            akamaiLeads = SobjectRepository.refresh(akamaiLeads);
            for(Lead ithLead: akamaiLeads)
            {
                System.assert(ithLead.Lead_Qualification_Stage__c=='Qualified Lead - Warm', 'ithlead was:'+ithLead);
                System.assert(ithLead.Lead_Qualification_Status__c=='Prospect', 'ithlead was:'+ithLead);
                ithLead.Lead_Qualification_Status__c='Closed - Bad Contact Info';
            }
            //ApexPages.StandardController sc1 = new ApexPages.StandardController(contact);
            GSM_CallToAction_CreateLeadController controller1 = new GSM_CallToAction_CreateLeadController();
            PageReference pageRef1 = Page.ConvertContactToLeadPage;
            Test.setCurrentPage(pageRef1);

            GSM_CallToAction_CreateLeadController.loadPicklistValues('Lead','Product_Line__c');
            GSM_CallToAction_CreateLeadController.getUIThemeDescription();
            GSM_CallToAction_CreateLeadController.isSDRUserCheck();
            GSM_CallToAction_CreateLeadController.callToActionLeadExists(nContacts[0].Id,True);
            GSM_CallToAction_CreateLeadController.callToActionLeadExists(nContacts[0].Id,False);
            GSM_CallToAction_CreateLeadController.callToActionLeadExists(lct.id,True);
            GSM_CallToAction_CreateLeadController.callToActionLeadExists(lct.Id,False);

            update akamaiLeads;
            Test.stopTest();
            akamaiLeads = SobjectRepository.refresh(akamaiLeads);

            for(Lead ithLead: akamaiLeads)
            {
                System.assert(ithLead.Lead_Qualification_Status__c.containsIgnoreCase('Closed'), 'ithlead was:'+ithLead);
                System.assert(ithLead.Status=='Closed', 'ithlead was:'+ithLead);
            }
        }
    }

    static testmethod void convertLeadMethodTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Contact contact = SobjectRepository.getContact();

            User salesUser = SobjectRepository.getSalesOpsUser();
            User gssUser= SobjectRepository.getGSSOpsUser();
            Test.startTest();
            system.runAs(salesUser)
            {
                GSM_Lite_ContactToLeadCreateController controller1 = new GSM_Lite_ContactToLeadCreateController();
                PageReference pageRef1 = Page.ConvertContactToLeadPage;
                Test.setCurrentPage(pageRef1);

                GSM_Lite_ContactToLeadCreateController.loadPicklistValues('Lead','Product_Line__c');
                GSM_Lite_ContactToLeadCreateController.getUIThemeDescription();
                GSM_Lite_ContactToLeadCreateController.isValidUserCheck();
                GSM_Lite_ContactToLeadCreateController.isSDRUserCheck();
                GSM_Lite_ContactToLeadCreateController.loadSDRLeadTypePicklistValues();
                GSM_Lite_ContactToLeadCreateController.insertNewLead('Enterprise','Test Lead',contact.Id,'Inbound Email');
            }

            system.runAs(gssUser)
            {
                GSM_Lite_ContactToLeadCreateController controller1 = new GSM_Lite_ContactToLeadCreateController();
                PageReference pageRef1 = Page.ConvertContactToLeadPage;
                Test.setCurrentPage(pageRef1);

                GSM_Lite_ContactToLeadCreateController.loadPicklistValues('Lead','Product_Line__c');
                GSM_Lite_ContactToLeadCreateController.getUIThemeDescription();
                GSM_Lite_ContactToLeadCreateController.isValidUserCheck();
                GSM_Lite_ContactToLeadCreateController.isSDRUserCheck();
                GSM_Lite_ContactToLeadCreateController.loadSDRLeadTypePicklistValues();
                GSM_Lite_ContactToLeadCreateController.insertNewLead('Enterprise','Test Lead',contact.Id,'Inbound Email');
            }


            Test.stopTest();

        }
    }
    static testmethod void doNotCreateC2aWhenOptedOut()
    {
        system.runAs(dmlUser){
            Test.startTest();
            Lead l = [Select Id,DoNotCall,HasOptedOutOfEmail from Lead where email = 'test2@akamai.com.invalid' limit 1];
            l.DoNotCall = true;
            l.HasOptedOutOfEmail = true;
            update l;
            String leadOutput = GSM_Lite_ContactToLeadCreateController.insertNewLead('Enterprise','Test Lead',l.Id,'Inbound Email');
            System.assertEquals('This person is both Email Opt Out and Do Not Call.', leadOutput);
            Contact contact = SobjectRepository.getContact();
            contact.DoNotCall = true;
            contact.HasOptedOutOfEmail = true;
            update contact;
            String contactOutput = GSM_Lite_ContactToLeadCreateController.insertNewLead('Enterprise','Test Lead',contact.Id,'Inbound Email');
            System.assertEquals('This person is both Email Opt Out and Do Not Call.', contactOutput);
            Test.stopTest();
        }
    }

    static testMethod void stageStatusCopyOverWhileInsertingCTAThroughDataLoader()
    {   
        //this method tests updateProspectCtaStageStatus method of LeadToContactConversionClass
        Test.startTest();
        Lead marketoLead = [Select Id, Associated_Account__c from Lead where email = 'test2@akamai.com.invalid' limit 1];
        marketoLead.Lead_Qualification_Stage__c = 'Prospect';
        marketoLead.Lead_Qualification_Status__c = 'Prospect';
        update marketoLead;
        Lead akamaiLead = new Lead();
        akamaiLead.firstname = 'Test';
        akamaiLead.lastname = 'Test2';
        akamaiLead.email = 'testinvalidtest010@testinvalid.com';
        akamaiLead.Associated_Account__c = marketoLead.Associated_Account__c;
        akamaiLead.Company = 'Test Company';
        akamaiLead.Parent_Lead__c = marketoLead.Id;
        insert akamaiLead;
        Lead reQueryAkamaiLead = [Select Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Lead where Id =: akamaiLead.Id limit 1];
        System.assertEquals('Prospect', reQueryAkamaiLead.Lead_Qualification_Stage__c,'Lead Qualification Stage value is not getting copied over from Person Record');
        System.assertEquals('Prospect', reQueryAkamaiLead.Lead_Qualification_Status__c,'Lead Qualification Status value is not getting copied over from Person Record');
        Contact contact = SobjectRepository.getContact();
        contact.Lead_Qualification_Stage__c = 'Prospect';
        contact.Lead_Qualification_Status__c = 'Prospect';
        update contact;
        Lead akamaiLeadForContact = new Lead();
        akamaiLeadForContact.firstname = 'Test';
        akamaiLeadForContact.lastname = 'Test2';
        akamaiLeadForContact.email='testinvalidtest020@testinvalid.com';
        akamaiLeadForContact.Associated_Account__c = marketoLead.Associated_Account__c;
        akamaiLeadForContact.Company = 'Test Company';
        akamaiLeadForContact.Associated_Contact__c = contact.Id;
        insert akamaiLeadForContact;
        Lead reQueryAkamaiLeadForContact = [Select Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Lead where Id =: akamaiLeadForContact.Id limit 1];
        System.assertEquals('Prospect', reQueryAkamaiLeadForContact.Lead_Qualification_Stage__c,'Lead Qualification Stage value is not getting copied over from Person Record');
        System.assertEquals('Prospect', reQueryAkamaiLeadForContact.Lead_Qualification_Status__c,'Lead Qualification Status value is not getting copied over from Person Record');
        Test.stopTest();
    }
    
    static testMethod void copyOverPlaybookFieldsToPersonRecord()
    {
        Test.startTest();
        Lead akamaiLead = [Select Id, Parent_Lead__c, Playbooks_Step_Number__c, Lead_Qualification_Stage__c, Lead_Qualification_Status__c from Lead where email = 'test3@akamai.com.invalid' limit 1];
        akamaiLead.Playbooks_Step_Number__c = 5;
        update akamaiLead;
        akamaiLead.Status = 'Closed';
        update akamaiLead;
        Lead marketoLead = [Select Playbooks_Step_Number__c,Associated_Account__c from Lead where Id =: akamaiLead.Parent_Lead__c limit 1];
        System.assertEquals(5, marketoLead.Playbooks_Step_Number__c,'Playbooks Step Number Field value is not getting copied over');
        Contact contact = SobjectRepository.getContact();
        Lead akamaiLeadForContact = new Lead();
        akamaiLeadForContact.firstname = 'Test';
        akamaiLeadForContact.lastname = 'Test2';
        akamaiLeadForContact.Associated_Account__c = marketoLead.Associated_Account__c;
        akamaiLeadForContact.Company = 'Test Company';
        akamaiLeadForContact.Associated_Contact__c = contact.Id;
        insert akamaiLeadForContact;
        akamaiLeadForContact.Playbooks_Step_Number__c = 5;
        update akamaiLeadForContact;
        akamaiLeadForContact.Status = 'Closed';
        update akamaiLeadForContact;
        Contact reQueryContact = [Select Playbooks_Step_Number__c from Contact where Id =: akamaiLeadForContact.Associated_Contact__c];
        System.assertEquals(5, reQueryContact.Playbooks_Step_Number__c,'Playbooks Step Number Field value is not getting copied over');
        Test.stopTest();
    }

    static testMethod void LeadAccWithLatticeRecommendation_CTAAndOpptyHasBISIsTrue() {
        Account testAccount = utilTestClass.CreateAccount('Test Account Has BIS');
        testAccount.LBI__NumberOfOpenInProgressRecommendations__c = 2;
        insert testAccount;
        
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.email = 'testHasBIS001@akamai.com';
        testLead.status = 'New';
        testLead.CurrencyIsoCode = 'USD';
        testLead.company = 'Test Company Has BIS';
        testLead.firstname = 'Test';
        testLead.lastname = 'LeadHasBIS';
        testLead.website = 'testwebsiteHasBIS.com';
        testLead.industry = 'Banking';
        testLead.street = 'Test street';
        testLead.city = 'Test City';
        testLead.state = 'Test state';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        testLead.description = 'Test Description Has BIS';
        insert testLead;
        
        testLead.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update testLead;
        
        Id akamaiRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        List<Lead> ctaLeadList = [Select Id, Has_BIS__c from Lead where Email = 'testHasBIS001@akamai.com' and RecordTypeId =:akamaiRecordTypeId];

        System.assert(ctaLeadList[0].Has_BIS__c == true, 'CTA Has BIS must be true');
        
        ctaLeadList[0].Authority__c = 'Test Authority';
        ctaLeadList[0].Need__c = 'Test Need';
        ctaLeadList[0].Money__c = 'Test Urgency';
        ctaLeadList[0].Urgency__c = 'Test Money';
        ctaLeadList[0].ANUM_Description__c = 'Test ANUM';
        ctaLeadList[0].Product_Line__c = 'Carrier';
        ctaLeadList[0].Lead_Qualification_Status__c='Converted';
        update ctaLeadList[0];
        
        ctaLeadList = [select Id, Associated_Opportunity__r.Has_BIS__c from lead where Id =:ctaLeadList[0].Id];

        System.assert(ctaLeadList[0].Associated_Opportunity__r.Has_BIS__c == true, 'Opportunity Has BIS must be true');      
    }
}