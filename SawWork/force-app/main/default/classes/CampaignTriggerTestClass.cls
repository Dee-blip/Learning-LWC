/***
  History
  --Developer           --Date            --Change
  Karteek Kumar M       14/01/2011        Created the class.
  Chandra Lohani        07/10/2011        Added createCamapaignMemberAuditTrailTest test method.
 */
@isTest(seeAllData=false)
private class CampaignTriggerTestClass 
{
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 4; 

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
                .count(numberOfTestLeads)
                .create()
                .getRecords();
            Test.startTest();

            Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();


            Profile pr = [select id from profile where name='Marketing Operations'][0];  
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            String orgId = UserInfo.getOrganizationId();
            String usrName = orgId + dateString + '@akamai.com';
            
            User marketingOpsUser = new User(alias = 'rsdnhca',
            email=usrName,emailencodingkey='UTF-8', lastname='rsdnhca',
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
                    .put(Lead.Associated_Contact__c, listOfTestContacts)
                    .put(Lead.Associated_Account__c, listOfTestAccounts)
                    .put(Lead.Product_Line__c,'Enterprise')
                    .put(Lead.Country,'India')
                    .put(Lead.State,'Karnataka')
                    .create();
            }

        }

    }

    static testmethod void UpdateLatestCampaignOnLeadTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Campaign c1= (Campaign) new SObjectBuilder(Campaign.sObjectType)
                .eagerPopulate()
                .put(Campaign.Division__c,'Enterprise')
                .create()
                .getRecord();

            CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;
            Lead ithLead = SobjectRepository.getLead();

            List<CampaignMember> cmpgnMember = (List<CampaignMember>) new SObjectBuilder(CampaignMember.sObjectType)
                .put(CampaignMember.CampaignId, c1.Id)
                .put(CampaignMember.Status, 'Sent')
                .put(CampaignMember.LeadId, ithLead.Id)
                .create()
                .getRecords();

            Test.startTest();

            // Refresh lead & campaign
            ithLead = [select Id, Latest_Campaign_AKAM_Id__c from Lead where Id = :ithLead.Id][0];
            c1 = [select Id, AKAM_Campaign_ID__c from Campaign where Id=:c1.Id][0];

            // Assert
            system.assertNotEquals(ithLead.Latest_Campaign_AKAM_Id__c, c1.AKAM_Campaign_ID__c, 'Lead should not be populated with akam id');
            ithLead.Latest_Campaign_AKAM_Id__c = c1.AKAM_Campaign_ID__c;
            update ithLead;
            CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;

            // Sonali Tandon -- Latest Campaign Id on Leads -- CR 3126721

            // Refresh campaign with new AKAM Campaign Id
            c1.AKAM_Campaign_ID__c = 'M-24192';
            update c1;

            // Refresh lead & campaign
            ithLead = [select Id, Latest_Campaign_AKAM_Id__c from Lead where Id = :ithLead.Id][0];
            c1 = [select Id, AKAM_Campaign_ID__c from Campaign where Id=:c1.Id][0];

            CampaignTriggerClass.createCampaignMemberAuditTrailFirstRunFlag=true;
            system.assertEquals(ithLead.Latest_Campaign_AKAM_Id__c, c1.AKAM_Campaign_ID__c);
            List<CampaignMemberAuditTrail__c> camMemberAuditTrailList=[select Id,Name,Campaign__c from CampaignMemberAuditTrail__c where Campaign__c=:c1.Id];
            // Assert
            system.assertEquals(camMemberAuditTrailList.size(), 1);
            String msg='';
            User newUser = SobjectRepository.getSalesOpsUser();
            System.runAs(newUser)
            {
                try
                {
                    delete cmpgnMember[0];
                }
                catch(Exception e)
                {
                    msg=e.getMessage();
                }
                //system.assert(msg.contains(GsmUtilClass.getGSMSettingValue('CmpgnMmbrTrgr_RemoveErrMsg')));
            }
            newUser = SobjectRepository.getMarketingOpsUser();
            CampaignTriggerClass.createCampaignMemberAuditTrailFirstRunFlag=true;
            msg='';

            System.runAs(newUser)
            {
                try
                {
                    delete cmpgnMember[0];
                }
                catch(Exception e)
                {
                    msg=e.getMessage();
                }
                //system.assert(String.isBlank(msg), 'Campaign could not be deleted by marketing ops:'+msg);
            }
            msg='';
            System.runAs(dmlUser)
            {
                try
                {
                    delete cmpgnMember[0];
                }
                catch(Exception e)
                {
                    msg=e.getMessage();
                }
            }
            camMemberAuditTrailList=[select Id,Name,Campaign__c from CampaignMemberAuditTrail__c where Campaign__c=:c1.Id];
            system.assert(camMemberAuditTrailList.size() != 0);
        }
    }

    static testmethod void createCampaignMemberOnContact() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Campaign c1= (Campaign) new SObjectBuilder(Campaign.sObjectType)
                .eagerPopulate()
                .put(Campaign.Division__c,'Enterprise')
                .create()
                .getRecord();

            CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;
            Contact ithContact = SobjectRepository.getContact();

            List<CampaignMember> cmpgnMember = (List<CampaignMember>) new SObjectBuilder(CampaignMember.sObjectType)
                .put(CampaignMember.CampaignId, c1.Id)
                .put(CampaignMember.Status, 'Sent')
                .put(CampaignMember.ContactId, ithContact.Id)
                .create()
                .getRecords();
            List<CampaignMember> finalCmpgnMember = [Select Id, Account_Status__c, AccountId__c from CampaignMember where ContactId = :ithContact.Id limit 1];
            System.assert(finalCmpgnMember.size() > 0, 'campaignMember must not be empty');
            System.assert(finalCmpgnMember[0].Account_Status__c != null, 'campaignMember acc status must not be empty');
            System.assert(finalCmpgnMember[0].AccountId__c != null, 'campaignMember acc Id must not be empty');
        }
    }

    static testmethod void disableCampaignMemberTrigger() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            string trg1 = 'CampaignMemberTrigger';
            ByPassAndLimitUtils.disable(trg1);
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Campaign c1= (Campaign) new SObjectBuilder(Campaign.sObjectType)
                .eagerPopulate()
                .put(Campaign.Division__c,'Enterprise')
                .create()
                .getRecord();

            CampaignTriggerClass.UpdateLatestCampaignOnLeadFirstRunFlag=true;
            Contact ithContact = SobjectRepository.getContact();

            List<CampaignMember> cmpgnMember = (List<CampaignMember>) new SObjectBuilder(CampaignMember.sObjectType)
                .put(CampaignMember.CampaignId, c1.Id)
                .put(CampaignMember.Status, 'Sent')
                .put(CampaignMember.ContactId, ithContact.Id)
                .create()
                .getRecords();
            List<CampaignMember> finalCmpgnMember = [Select Id, Account_Status__c, AccountId__c from CampaignMember where ContactId = :ithContact.Id limit 1];
            System.assert(finalCmpgnMember.size() > 0, 'campaignMember must not be empty');
            System.assert(finalCmpgnMember[0].Account_Status__c == null, 'campaignMember acc status must be empty as trigger is disabled');
            System.assert(finalCmpgnMember[0].AccountId__c == null, 'campaignMember acc Id must be empty as trigger is disable');
        }
    }

    static testmethod void coverByPassLogic(){
        System.runAs(utilTestClass.getTestRunUser()) {
            ByPassAndLimitUtils.disable('CampaignTriggerFramework');
            Campaign cmpgn = utilTestClass.CreateCampaign('__ Test Cmpgn');
            cmpgn.AKAM_System__c = '';
            cmpgn.AKAM_Created_By__c = '';
            cmpgn.AKAM_Created_Date__c = null;
            insert cmpgn;
        }
    }
}