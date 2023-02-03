@isTest(seeAllData = false)
private class C2ALeadTests
{
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 4; 

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(dmlUser)
        {
             new SObjectBuilder(Order_Region_Reporting_Region_Mapping__c.sObjectType)
                .eagerPopulate()
                .create();

            new SObjectBuilder(Sales_Approved_Country__c.SObjectType)
                .eagerPopulate()
                .create();


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
                
            Campaign c1= (Campaign) new SObjectBuilder(Campaign.sObjectType)
                .eagerPopulate()
                .put(Campaign.Division__c,'Enterprise')
                .create()
                .getRecord();

            MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
            settings.Name = 'LeadAsyncConversionFlagStatus';
            settings.Flag_Status__c = false;
            insert settings;
                
            Test.startTest();

            Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
            String autoConvertQId = GSMSettings.getValue('LeadAutoConvert_QueueId');


            Profile pr = [select id from profile where name='Marketing Operations'][0];  
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            String orgId = UserInfo.getOrganizationId();
            String usrName = orgId + dateString + '@akamai.com';
            
            User marketingOpsUser = new User(alias = 'rsdnhca',
            email='rsdnhca@akamai.com',emailencodingkey='UTF-8', lastname='rsdnhca',
            languagelocalekey='en_US',localesidkey='en_US',
            timezonesidkey='America/Los_Angeles', isactive = true, Title = 'Marketing Director',
            username = usrName, profileid = pr.Id); 
            insert marketingOpsUser;


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

        }

    }



    static testmethod void verifyANUMValidationShowsUpOnLeadToOpptyConversion() 
    {
        System.runAs(dmlUser) 
        {
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
            List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
            Campaign c1 = [select Id, AKAM_Campaign_ID__c from Campaign limit 1][0];
            Set<Id> leadIds = new Set<Id>();
            for (Lead ithLead : nLeads) 
            {
                ithLead.Associated_Contact__c=null;
                ithLead.RecordTypeId = marketoRecordTypeId;
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = marketingOpsUser.Id;
                ithLead.Primary_Campaign__c = c1.id;
                ithLead.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
                leadIds.add(ithLead.Id);
            }   
            update nLeads;
            //Method call to improve LeadTriggerClassWithoutSharing coverage
            LeadTriggerClassWithoutSharing.createCampaignMemberbasedOnPrimaryCampaign(nLeads);
            
            List<Lead> akamaiLeads = [select Associated_Opportunity__c,id,Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Lead where Parent_Lead__c=:leadIds];

            for(Lead ithLead: akamaiLeads)
            {
                    ithLead.Lead_Qualification_Status__c='Converted';
                    System.assert(ithLead.Lead_Qualification_Stage__c=='Qualified Lead - Warm', 'ithlead was:'+ithLead.Lead_Qualification_Stage__c);
            }
            String errMessage='';
            try
            {
                update akamaiLeads;
            }
            catch(Exception exx)
            {
               errMessage = exx.getMessage();
            }
            System.assert(!String.isBlank(errMessage) && errMessage.contains('You must complete ANUM qualification'), 'ANUM validation is not throwing up on');
        }
    }
    
    static testmethod void manualConversion(){
           System.runAs(dmlUser) 
            {
               Id akamRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId(); 
               String autoConvertQId = GSMSettings.getValue('LeadAutoConvert_QueueId');
               Lead akamLead = new Lead();
               akamLead.LastName = 'testLeadforManual';
               akamLead.RecordTypeId = akamRecordTypeId;
               akamLead.OwnerId = autoConvertQId;
               akamLead.Associated_Contact__c = [Select id from Contact limit 1].id;
               akamLead.Associated_Account__c = [Select id from Account limit 1].id;
               akamLead.Product_Line__c = 'Enterprise';
               insert akamLead;
               List<Lead> leadList = new List<Lead>();
               leadList.add(akamLead);
               LeadTriggerClass.setConverted(leadList);
            }
        }

    static testmethod void verifyANUMValidationDoesntComeWhenPopulated() 
    {
        System.runAs(dmlUser) 
        {
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            User marketingOpsUser = SobjectRepository.getMarketingOpsUser();
            List<Lead> nLeads = SobjectRepository.getLeads(numberOfTestLeads);
            Set<Id> leadIds = new Set<Id>();
            for (Lead ithLead : nLeads) 
            {
                ithLead.Associated_Contact__c=null;
                ithLead.RecordTypeId = marketoRecordTypeId;
                ithLead.Validation_Override__c = true;
                ithLead.OwnerId = marketingOpsUser.Id;
                ithLead.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
                leadIds.add(ithLead.Id);
            }   
            update nLeads;

            List<Lead> akamaiLeads = [select adg_Conversion_SLA__c,adg_Dispensation_SLA__c,Status,RecordTypeId,Parent_Lead__c,Lead_Qualification_Stage__c,Lead_Qualification_Status__c, Associated_Contact__c,Associated_Opportunity__c,id from Lead where Parent_Lead__c=:leadIds];
            Map<Id, Lead> parentLeadIdToAkamaiLeadMap=new Map<Id,Lead>();
            for(Lead ithLead:akamaiLeads)
            {
                parentLeadIdToAkamaiLeadMap.put(ithLead.Parent_Lead__c, ithLead);

            }
            //LeadToContactConversionClass.updateMarketoLeadForConversion(parentLeadIdToAkamaiLeadMap);

            for(Lead ithLead: akamaiLeads)
            {
                ithLead.Authority__c = 'Test Authority';
                ithLead.Need__c = 'Test Need';
                ithLead.Money__c = 'Test Urgency';
                ithLead.Urgency__c = 'Test Money';
                ithLead.ANUM_Description__c = 'Test ANUM';
                System.assert(ithLead.Lead_Qualification_Stage__c=='Qualified Lead - Warm', 'ithlead was:'+ithLead);
                ithLead.Lead_Qualification_Status__c='Converted';
            }
            String errMessage='';
            Test.startTest();
            List<String> metadataValue = MarketingUtilClass.getMarketingSettingValuePartialMatch('AkamaiLeadCreationFromMarketoLead'); // for code coverage
            try
            {
                update akamaiLeads;
            }
            catch(Exception exx)
            {
               errMessage = exx.getMessage();
            }
            Test.stopTest();
            System.assert(String.isBlank(errMessage), 'Lead conversion failed because:'+errMessage);
            nLeads = [select Associated_Contact__c, IsConverted, ConvertedContactId,Status,RecordTypeId from Lead where Id in :nLeads];
            for(Lead ithLead: nLeads)
            {
                System.assert(ithLead.IsConverted==true, 'ithlead was:'+ithLead);
                System.assert(ithLead.ConvertedContactId!=null, 'ithlead was:'+ithLead);
            }
            akamaiLeads = [select Associated_Contact__c,Status,Associated_Opportunity__c,id,Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Lead where Parent_Lead__c=:leadIds];

            //akamaiLeads = SobjectRepository.refresh(akamaiLeads);
            for(Lead ithLead: akamaiLeads)
            {
                // all the warm bpp statuses should have changed to converted
                System.assert(ithLead.Lead_Qualification_Status__c=='Converted', 'ithlead was:'+ithLead);
                System.assert(ithLead.Associated_Opportunity__c!=null , 'ithlead was:'+ithLead);
            }


        }
    }
}