@isTest(seeAllData = false)
public class MARIT_LeadTriggerTestClass {
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
                .put(Account.Type, 'Lead')
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

            Account acc = utilTestClass.CreateAccount('Test Account for Live Chat Transcript');
            insert acc;
            
            // Create contact
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = acc.Id;
            con.email = 'teste1264@akamai1.com.invalid';
            con.Description = 'test data';
            con.MailingCountry = 'USA';
            con.Phone = '3458761236';
            insert con; 
            
            Id akamaiRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            Lead l = new Lead();
            l.RecordTypeId = akamaiRecordTypeId;
            l.email = 'teste164Lead@akamai1.com.invalid';
            l.Status = 'New';
            l.firstname = 'Test';
            l.lastname = 'Test2';
            l.Associated_Account__c = acc.Id;
            l.Company = 'Test Company';
            l.Product_Line__c = 'Media';
            l.Country = 'USA';
            l.phone = '3458761236';
            insert l;
           
        }

    }
   /*static testMethod void testAutoConversionBatchJob()
    {
        List<CampaignMember> listOfTestCampaignMembers = new List<CampaignMember>();

        LeadConversionHelper.hasAutoConversionRun = true;


        LeadAutoConvertRule__c rule = new LeadAutoConvertRule__c();
        rule.TERR_HIER_4__c = 'Web';
        rule.Akamai_Top_50__c=true;
        insert rule;

        Account acc = new Account();
        acc.Name = 'testAcc';
        acc.Website = 'www.testWeb.com';
        acc.Type = 'Lead';
        acc.Parent_Division__c = 'Web EMEA_Web';
        acc.Akamai_Top_50__c=true;
        insert acc;

        Contact con = new Contact();
        con.lastname = 'testContact';
        con.Email = 'idkemail@akamai.com';
        con.AccountId = acc.Id;
        insert con;

        User marketingOpsUser = [select id from user where profile.name='Marketing Operations' and isactive=true and Title like '%Marketing%' and Title like '%Director%' limit 1];

        CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;
        Campaign autoConvertCampaign = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .eagerPopulate()
            .put(Campaign.Auto_Convert_Justification__c ,'TBD')
            .put(Campaign.Sales_Approval__c,marketingOpsUser.id)
            .put(Campaign.Marketing_Approval__c,marketingOpsUser.id)
            .put(Campaign.Validation_Override__c,true)
            .put(Campaign.Auto_Convert_Lead__c,true)
            .put(Campaign.Division__c,'Enterprise')
            .create()
            .getRecord();

        CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;
        List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);

        List<CampaignMember> cmpgnMember = (List<CampaignMember>) new SObjectBuilder(CampaignMember.sObjectType)
            .put(CampaignMember.CampaignId, autoConvertCampaign.Id)
            .put(CampaignMember.Status, 'Sent')
            .put(CampaignMember.LeadId, nLeads)
            .count(numberOfTestLeads)
            .create()
            .getRecords();
        CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;

        Test.startTest();

        Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        for(Lead ithLead : nLeads)
        {
            System.assert(ithLead.Status!='Converted', 'Lead has got autoconverted before running the batch job:'+ithLead);
            ithLead.Associated_Contact__c = con.Id;
            ithLead.RecordTypeId = akamaiLeadRecordTypeId;
            ithLead.Validation_Override__c=true;
            DecoratedLead dl = new DecoratedLead(ithLead);
            dl.setEnterpriseSalesRepEmail('test@akamai.com');
            List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();
            dl.generateOpptyLeaderMailingList(mailingList);
        }


        update nLeads;

        /*
        User marketingOpsUser = [select id from user where profile.name='Marketing Operations' and isactive=true and Title like '%Marketing%' and Title like '%Director%' limit 1];
        autoConvertCampaign.Auto_Convert_Lead__c = true;
        autoConvertCampaign.Auto_Convert_Justification__c = 'TBD';
        autoConvertCampaign.Sales_Approval__c = marketingOpsUser.id;
        autoConvertCampaign.Marketing_Approval__c = marketingOpsUser.id;
        autoConvertCampaign.Validation_Override__c = true;
        update autoConvertCampaign;
        */

        //Database.DMLOptions dmo = new Database.DMLOptions();
        //dmo.assignmentRuleHeader.useDefaultRule = true;
        //Database.update(nLeads, dmo);
/*
            nLeads =[select id,status,Associated_Opportunity__c,OwnerId,RecordTypeId,Associated_Contact__c,Associated_Contact__r.Account.Account_Owner_Alias__c, Associated_Contact__r.Account.Owner.IsActive from lead where id in :nLeads];
            for(Lead ithLead : nLeads)
            {
                System.assert((ithLead.Status=='New' || ithLead.Status=='In Process'),'ith lead was:'+ithLead);
                System.assert((ithLead.OwnerId==GSMSettings.getValue('LeadAutoConvert_QueueId')),'ith lead was:'+ithLead);
                System.assert(ithLead.Associated_Contact__c!=null,'ith lead was:'+ithLead);
                System.assert(ithLead.Associated_Contact__r.Account.Owner.IsActive,'ith lead was:'+ithLead);
                System.assert(ithLead.Associated_Contact__r.Account.Account_Owner_Alias__c!='ONA','ith lead was:'+ithLead);

            }

        try {
            LeadAutoConversionBatchClass lacb = new LeadAutoConversionBatchClass();
            Database.executeBatch(lacb,numberOfTestLeads);


            Test.stopTest();

            nLeads =[select id,status,Associated_Opportunity__c from lead where id in :nLeads];
            for(Lead ithLead : nLeads)
            {
                //System.assert(ithLead.Status=='Converted', 'Lead hasnt got converted automatically'+ ithLead + ' : ' + lacb.lcr.generateTextLog());
                //System.assert(ithLead.Associated_Opportunity__c!=null, 'Lead hasnt got converted automatically'+ ithLead + ' : ' +  lacb.lcr.generateTextLog());

            }
        }
        catch(Exception e) {
            System.debug('Error Occured : ' + e);
        }
    }*/

    
    static testmethod void testAutoConversionBatchJob()
    {
        //insert acc
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        //insert Contact
        List<Contact> conList = new List<Contact>();
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        con.email = 'test@akamai.com';
        insert con;
        //Creating cta
        con.Lead_Qualification_Stage__c = 'Qualified Lead - Hot';
        update con;
        Test.startTest();
        Lead al=[Select OwnerId,Status,RecordTypeId,Associated_Opportunity__c,Associated_Contact__r.Account.Account_Owner_Alias__c,
                 Associated_Contact__r.Account.Owner.IsActive,Associated_Contact__r.Account.Type,Associated_Contact__r.Account.AKAM_Account_ID__c from Lead where Associated_Contact__c = :con.Id];
        al.OwnerId = GSMSettings.getValue('LeadAutoConvert_QueueId');
        al.Convert_to_Opportunity__c = true;
        al.Donot_run_Trigger__c = true;
        al.validation_override__c = true;
        update al;
        System.assert((al.OwnerId==GSMSettings.getValue('LeadAutoConvert_QueueId')),'al lead was:'+al);
        List<Lead> fetchLead = [Select id, name, status, recordtype.Name, Donot_run_Trigger__c from lead where id  = :al.id];
        system.debug('Mayank, fetchLead:'+fetchLead);
        try {
            LeadAutoConversionBatchClass lacb = new LeadAutoConversionBatchClass();
            Database.executeBatch(lacb);
            Test.stopTest();
        }
        catch(Exception e) {
            System.debug('Error Occured : ' + e);
        }
    }
    
    static testmethod void testLeadConversionHelper() {
        List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        User marketingOpsUser = [select id from user where profile.name='Marketing Operations' and isactive=true and Title like '%Marketing%' and Title like '%Director%' limit 1];
        List<Lead> leads = [Select Id,Associated_Contact__c,Status,Associated_Opportunity__c,Associated_Account__c,RecordTypeId,OwnerId,Associated_Account__r.Type,Associated_Account__r.Owner.isActive,Associated_Account__r.AKAM_Account_ID__c,Associated_Account__r.Projected_Sales_Owner__c,Associated_Account__r.OwnerId from lead where id in :nLeads];
        for(Lead ithLead : leads) {
            ithLead.Status = 'Closed';
            ithLead.Associated_Contact__c = null;
            ithLead.Associated_Account__c = null;
            if(marketingOpsUser != null)
                ithLead.OwnerId = marketingOpsUser.Id;

            ithLead.RecordTypeId = marketoRecordTypeId;
            LeadConversionHelper.getDeficiencies(ithLead,false,false);
        }
        LeadConversionHelper.runConversion((new Map<Id,SObject>(leads)).keySet(),false);
    }
    
    static testMethod void autoConversionToLeadBulk() 
    {
       List<CampaignMember> listOfTestCampaignMembers = new List<CampaignMember>();

        Test.startTest();
        LeadConversionHelper.hasAutoConversionRun = false;
        CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;

        Campaign autoConvertCampaign = (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .eagerPopulate()
            .put(Campaign.Auto_Convert_Lead__c, false)
            .put(Campaign.Division__c,'Enterprise')
            .create()
            .getRecord();

        User marketingOpsUser = [select id from user where profile.name='Marketing Operations' and isactive=true and Title like '%Marketing%' and Title like '%Director%' limit 1];
        autoConvertCampaign.Auto_Convert_Lead__c = true;
        autoConvertCampaign.Auto_Convert_Justification__c = 'TBD';
        autoConvertCampaign.Sales_Approval__c = marketingOpsUser.id;
        autoConvertCampaign.Marketing_Approval__c = marketingOpsUser.id;
        autoConvertCampaign.Validation_Override__c = true;
        update autoConvertCampaign;

        List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);

        CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;
        List<CampaignMember> cmpgnMember = (List<CampaignMember>) new SObjectBuilder(CampaignMember.sObjectType)
            .put(CampaignMember.CampaignId, autoConvertCampaign.Id)
            .put(CampaignMember.Status, 'Sent')
            .put(CampaignMember.LeadId, nLeads)
            .count(numberOfTestLeads)
            .create()
            .getRecords();


        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        Database.update(nLeads, dmo);

        nLeads = SobjectRepository.getLeads(numberOfTestLeads);

        LeadAutoConvertRule__c rule = new LeadAutoConvertRule__c();
        rule.TERR_HIER_4__c = 'testDivision';
        insert rule;
        
         List<Opportunity> oppList = new List<Opportunity>();

        for(Lead ithLead : nLeads)
        {
            System.assert(ithLead.Status !='Converted', 'Lead hasnt got converted automatically'+ithLead);
            System.assert(ithLead.Associated_Opportunity__c == null, 'Lead hasnt got converted automatically'+ithLead);
            if(ithLead.Associated_Opportunity__c != null){
                oppList.add(new Opportunity(Id=ithLead.Associated_Opportunity__c, StageName='2-Qualify', Validation_Override__c=true));
             System.debug('priyanka opportunity: '+ ithLead.Associated_Opportunity__c);   
            }
            DecoratedLead dl = new DecoratedLead(ithLead);
            dl.setEnterpriseSalesRepEmail('test@akamai.com');
            List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();
            dl.generateOpptyLeaderMailingList(mailingList);
        }


        // accept all the opportunities
        DemandWaterfallStages.createDemandWaterfallStagesHasRun=false;
        DemandWaterfallStages.updateLeadDemandWaterfallStageHasRun=false;

        if(oppList.size() > 0)
            update oppList;

        // nLeads = SobjectRepository.getLeads(numberOfTestLeads);

        // for(Lead ithLead : nLeads)
        // {
        //     System.assert(ithLead.Demand_Waterfall_Stage__c=='SAL', 'Opportunity hasnt been accepted'+ithLead);
        // }


        Test.stopTest();

       
    }
    
    static testmethod void manualConversionBulk()
    {
        //System.runAs(dmlUser) {
            List<CampaignMember> listOfTestCampaignMembers = new List<CampaignMember>();

            Test.startTest();
            LeadConversionHelper.hasAutoConversionRun = false;

            Account acc = new Account();
            acc.Name = 'testAcc';
            acc.Website = 'www.testWeb.com';
            acc.Type = 'Lead';
            acc.Parent_Division__c = 'test1;test2';
            acc.Target_Lists__c = '2017 Media High Potential - Child;2017 Media High Potential - Parent';
            insert acc;

            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
            List<Lead> pLeads = SobjectRepository.getLeads(numberOfTestLeads);
            for (Lead ithLead : pLeads) {
                ithLead.Associated_Contact__c=null;
                ithLead.Associated_Account__c = acc.Id;
                ithLead.RecordTypeId = marketoRecordTypeId;
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = marketingOpsUser.Id;
                ithLead.Email = 'manualConversionBulk@akamai.com';
                ithLead.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
            }   
            update pLeads;

            /*Contact con = new Contact();
            con.lastname = 'testContact';
            con.Email = 'idkemail@akamai.com';
            con.AccountId = acc.Id;
            insert con;*/

            List<Contact> nContacts = SObjectRepository.getContacts(numberOfTestLeads);
            Integer value = 0;
            for(Contact ithContact : nContacts){
                ithContact.AccountId = acc.Id;
                ithContact.LastName = 'testContact'+ value;
                ithContact.Email = 'testemail' + value + '@akamai.com.invalid';
                value++;
            }
            update nContacts;


            LeadAutoConvertRule__c rule = new LeadAutoConvertRule__c();
            rule.TERR_HIER_4__c = 'testDivision';
            rule.Target_Lists__c = '2017 Media High Potential - Child;2017 Media High Potential - Parent';
            insert rule;

            List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
            Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();


            Integer count = 0;
            Integer countForContact = 0;

            Test.stopTest();


            for(Lead ithLead : nLeads)
            {
                ithLead.Parent_Lead__c = pLeads[count++].Id;
                ithLead.Associated_Account__c = acc.Id;
                //ithLead.Associated_Contact__c = con.Id;
                ithLead.Associated_Contact__c = nContacts[countForContact++].Id;
                //ithLead.Status = 'Converted';
                ithLead.Lead_Qualification_Status__c = 'Converted';
                ithLead.Disposition__c='Sent to MAE';
                ithLead.Validation_Override__c = true;
                ithLead.RecordTypeId = akamaiLeadRecordTypeId;
                // SFDC-3263 @Nagaraj Desai
                ithLead.Product_Line__c = 'Carrier';
                ithLead.Authority__c = 'Test Authority';
                ithLead.Need__c = 'Test Need';
                ithLead.Money__c = 'Test Urgency';
                ithLead.Urgency__c = 'Test Money';
                ithLead.ANUM_Description__c = 'Test ANUM';
                //END SFDC-3263
                DecoratedLead dl = new DecoratedLead(ithLead);
                dl.setEnterpriseSalesRepEmail('test@akamai.com');
                List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();
                dl.generateOpptyLeaderMailingList(mailingList);

            }
            LeadConversionHelper.hasManualConversionRun=false;

			update nLeads;
            nLeads = [select id,status,Associated_Opportunity__c from Lead where id in :nLeads];

            
            List<Opportunity> oppList = new List<Opportunity>();

            for(Lead ithLead : nLeads)
            {
                System.assert(ithLead.Status=='Converted', 'Lead hasnt got converted automatically'+ithLead);
                System.assert(ithLead.Associated_Opportunity__c!=null, 'Lead hasnt got converted automatically'+ithLead);
                if(ithLead.Associated_Opportunity__c != null)
                    oppList.add(new Opportunity(Id=ithLead.Associated_Opportunity__c, StageName='Closed Lost', CloseDate=Date.today().addDays(-4),Loss_Reason__c='Lost Budget', Opportunity_Category__c='Customer Focus Shifted',  Validation_Override__c=true));

            }

            // accept all the opportunities
            DemandWaterfallStages.createDemandWaterfallStagesHasRun=false;
            DemandWaterfallStages.updateLeadDemandWaterfallStageHasRun=false;
            if(oppList.size() > 0)
                update oppList;

            // nLeads = SobjectRepository.getLeads(numberOfTestLeads);

            // for(Lead ithLead : nLeads)
            // {
            //     System.assert(ithLead.Demand_Waterfall_Stage__c=='SRL', 'Opportunity hasnt been accepted'+ithLead.Demand_Waterfall_Stage__c);
            // }
        //}
    }

    static testMethod void autoConvertNegative() {
        Test.startTest();
        LeadConversionHelper.hasAutoConversionRun = false;

        Account acc = new Account();
        acc.Name = 'testAcc';
        acc.Website = 'www.testWeb.com';
        acc.Type = 'Lead';
        acc.OwnerId = [Select id from User where name like 'Inside Sales Public Sector Inside Sales' limit 1].id;
        insert acc;

        Contact con = new Contact();
        con.lastname = 'testContact';
        con.Email = 'idkemail@akamai.com';
        con.AccountId = acc.Id;
        insert con;

        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
        List<Lead> pLeads = SobjectRepository.getLeads(numberOfTestLeads);
        for (Lead ithLead : pLeads) {
            ithLead.Associated_Contact__c=null;
            ithLead.Associated_Account__c = acc.Id;
            ithLead.RecordTypeId = marketoRecordTypeId;
            ithLead.Validation_Override__c = true;
            ithLead.OwnerId = marketingOpsUser.Id;
            ithLead.Email = 'manualConversionBulk@akamai.com';
            ithLead.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        }   
        update pLeads;
        Test.stopTest();

        Integer count = 0;
        Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
        Set<String> marketoAkamAccountIdSet = new Set<String>();
        Map<Id,Lead> parentToChildMapping = new Map<Id,Lead>();

        for(Lead ithLead : nLeads)
        {
            ithLead.Parent_Lead__c = pLeads[count++].Id;
            ithLead.Associated_Account__c = acc.Id;
            ithLead.Associated_Contact__c = con.Id;
            ithLead.RecordTypeId = akamaiLeadRecordTypeId;
            marketoAkamAccountIdSet.add(acc.Id);
            ithLead.Lead_Qualification_Status__c = 'Engaged';
        }

        ByPassAndLimitUtils.disable('LeadTrigger');
        update nLeads;

         MARIT_LeadTriggerClass.setAssociatedAccountOnLead(pLeads,new List<String>(marketoAkamAccountIdSet));
        // PartnerLeadTriggerClass.updateCampaignOnLeads(pLeads);
        // PartnerLeadTriggerClass.hasPartnerLeadPermission(marketingOpsUser.Id);
        // LeadTriggerClass.addErrorOnLead(new List<Lead>(),new Map<Id,SObject>());
        //getOppContactRole
        //getAkamaiLeadForContact

        //setAssociatedAccountOnLead
        //updateContactAndConvertLeadFields
    }
    
    static testmethod void AnnuitasFunctionalityContactTest() {
        Map<Id, Id> contactIdtoOppIdMap = new  Map<Id, Id>();
        String openOppStageName = '1. Identify Need,2. Explore Options,3. Verify Options,4. Select Option,5. Negotiate';
        Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        List<Contact> nContacts = SobjectRepository.getContacts(numberOfTestLeads);
        for(Contact con : nContacts) {
            con.Lead_Qualification_Stage__c = 'Prospect';
            con.Convert_to_Opportunity__c = false;
        }
    }

    static testmethod void doNotCallContactTest() {
       Test.startTest();
       Contact con = [Select Id, E164_Phone__c, DoNotCall  from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
       System.assert(con.E164_Phone__c == '+13458761236');
       con.DoNotCall = true;
       update con;
       con = [Select Id, E164_Phone__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
       System.assert(con.E164_Phone__c == null);
       Test.stopTest();  
    }
    
    static testmethod void doNotCallLeadTest() {
       Test.startTest();
       Lead l = [Select Id, E164_Phone__c, DoNotCall  from Lead where email = 'teste164Lead@akamai1.com.invalid' limit 1];
       System.assert(l.E164_Phone__c == '+13458761236');
       l.DoNotCall = true;
       update l;
       l = [Select Id, E164_Phone__c from Lead where email = 'teste164Lead@akamai1.com.invalid' limit 1];
       System.assert(l.E164_Phone__c == null);
       Test.stopTest();  
    }
    
    static testmethod void duplicateContactEmailTest() {
       Test.startTest();
        Lead l = [Select Id, Associated_Account__c  from Lead where email = 'teste164Lead@akamai1.com.invalid' limit 1];
       Id akamaiRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        l.email = 'teste1264@akamai1.com.invalid';
        Database.SaveResult result = Database.update(l, false);
       Test.stopTest();  
        System.assert(result.isSuccess() == false);
    }
    
    static testmethod void duplicateEmailMLTest() {
       Test.startTest();
        Lead l1 = [Select Id, Associated_Account__c  from Lead where email = 'teste164Lead@akamai1.com.invalid' limit 1];
       Id akamaiRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        List<Lead> leads = new List<Lead>();
        Lead l = new Lead();
        l.RecordTypeId = akamaiRecordTypeId;
        l.email = 'teste164Lead@akamai1.com.invalid';
        l.Status = 'New';
        l.firstname = 'Test';
        l.lastname = 'Test2';
        l.Associated_Account__c = l1.Associated_Account__c;
        l.Company = 'Test Company';
        l.Product_Line__c = 'Media';
        l.Country = 'USA';
        leads.add(l);
        
        Lead l2 = new Lead();
        l2.RecordTypeId = akamaiRecordTypeId;
        l2.email = 'teste164Lead@akamai1.com.invalid';
        l2.Status = 'New2';
        l2.firstname = 'Test2';
        l2.lastname = 'Test22';
        l2.Associated_Account__c = l1.Associated_Account__c;
        l2.Company = 'Test Company2';
        l2.Product_Line__c = 'Media';
        l2.Country = 'USA';
        leads.add(l2);
        
        Database.SaveResult[] result = Database.insert(leads, false);
       Test.stopTest();  
        System.assert(result[1].isSuccess() == false);
    }
}