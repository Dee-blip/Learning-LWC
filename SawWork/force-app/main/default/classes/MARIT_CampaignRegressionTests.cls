@isTest(seeAllData=false)
public class MARIT_CampaignRegressionTests {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = new User(id=UserInfo.getUserId());
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
        settings.Name = 'LeadAsyncConversionFlagStatus';
        settings.Flag_Status__c = false;
        insert settings;
        
        System.runAs(dmlUser) 
        {
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            Test.loadData(globalDescribe.get('LunaControlCenterSettings__c'), 'CS_LunaControlCenterSettings');
            /* End Of Custom Setting Insertion */
            
            Id campaignTacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic').getRecordTypeId();
            Id campaignProgramRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Program').getRecordTypeId();
            Id campaignNeedsBasedRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Needs-Based Campaign').getRecordTypeId();
            Id campaignCategoryRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Category Theme').getRecordTypeId();
            
            Account testAccount = utilTestClass.CreateAccount('Test Account2');
            insert testAccount;
            
            Contact testContact = utilTestClass.CreateContact('Test','Contact2');
            testContact.AccountId = testAccount.Id;
            insert testContact;
            
            List<Campaign> campaignRecs = new List<Campaign>();
            Campaign cmpgn = utilTestClass.CreateCampaign('__ TEST CMPGN');
            cmpgn.recordTypeId = campaignTacticRecordTypeId;
            cmpgn.AKAM_Campaign_ID__c = 'TC-1234';
            campaignRecs.add(cmpgn);
            Campaign cmpgn1 = utilTestClass.CreateCampaign('__ TEST CMPGN PRGM');
            cmpgn1.recordTypeId = campaignProgramRecordTypeId;
            campaignRecs.add(cmpgn1);
            Campaign cmpgn2 = utilTestClass.CreateCampaign('__ TEST CMPGN NEED');
            cmpgn2.recordTypeId = campaignNeedsBasedRecordTypeId;
            campaignRecs.add(cmpgn2);
            Campaign cmpgn3 = utilTestClass.CreateCampaign('__ TEST CMPGN CATE');
            cmpgn3.recordTypeId = campaignCategoryRecordTypeId;
            campaignRecs.add(cmpgn3);
            insert campaignRecs;
            
            campaignRecs.clear();
            cmpgn.ParentId = cmpgn1.Id;
            campaignRecs.add(cmpgn);
            cmpgn1.ParentId = cmpgn2.Id;
            campaignRecs.add(cmpgn1);
            cmpgn2.ParentId = cmpgn3.Id;
            campaignRecs.add(cmpgn2);
            update campaignRecs;
        }
    }
    
    public static testmethod void PersonLeadWithCampaignMember_CampAkamIDChange_PersonLeadALatestCampaignAkamChanges() {
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        Test.startTest();
        
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Integer numberOfLeads = 1;
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        List<Lead> leadList = Createleads(numberOfLeads, testAccount, marketoRecordTypeId);
        leadList[0].Country ='India';
        leadList[0].State = 'Karnataka';
        insert leadList;
        
        CampaignMember testLeadCM = new CampaignMember();
        testLeadCM.LeadId = leadList[0].Id;
        testLeadCM.CampaignId = cmpgn.Id;
        testLeadCM.Status = 'Sent';
        insert testLeadCM;
        
        CampaignMemberAuditTrail__c cmat = [Select Id,Campaign__c from CampaignMemberAuditTrail__c where Campaign__c = :cmpgn.Id];
        System.assert(cmat != null, 'Audit trail gets created after campaign member insertion');
        cmpgn.AKAM_Campaign_ID__c = 'Test-124';
        update cmpgn;
        
        Lead lObj = [Select Id, Latest_Campaign_AKAM_ID__c from Lead where Id =:leadList[0].Id];

        System.assert(lObj.Latest_Campaign_AKAM_ID__c == 'Test-124', 'Person lead akam id should be changed');
        
        cmpgn.AKAM_Campaign_ID__c = 'Test-126';
        update cmpgn;
        
        Test.stopTest();
    }
    public static testmethod void CreateTacticCampaign_SelectType_GroupSelectedBasedOnType() {
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c, ParentId from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        Test.startTest();
        List<Campaign> tacticCampaigns = createTacticCampaigns(5, cmpgn.ParentId);
        tacticCampaigns[0].Type = 'Content Syndication';
        tacticCampaigns[0].Event_Start_Date__c = System.Date.today();
        tacticCampaigns[1].Type = 'Direct Mail';
        tacticCampaigns[1].Event_Start_Date__c = System.Date.today();
        tacticCampaigns[2].Type = 'Event - 3rd Party';
        tacticCampaigns[2].Event_Start_Date__c = System.Date.today();
        tacticCampaigns[3].Type = 'Webinar - 3rd Party';
        tacticCampaigns[3].Event_Start_Date__c = System.Date.today();
        tacticCampaigns[4].Type = 'Event - Akamai-led';
        tacticCampaigns[4].Event_Start_Date__c = System.Date.today();
        insert tacticCampaigns;
        List<Id> idList = new List<Id>();
        for(Integer i =0 ;i < 5; i++) {
            idList.add(tacticCampaigns[i].id);
        }
        
        List<Campaign> finalList = [Select Id, Campaign_Group__c, Type from Campaign where id in :idList];
        System.assertEquals('Digital Content Marketing', finalList[0].Campaign_Group__c, 'Mapping is incorrect');
        System.assertEquals('Other', finalList[1].Campaign_Group__c, 'Mapping is incorrect');
        System.assertEquals('3rd Party Events', finalList[2].Campaign_Group__c, 'Mapping is incorrect');
        System.assertEquals('3rd Party Events', finalList[3].Campaign_Group__c, 'Mapping is incorrect');
        System.assertEquals('Akamai Led Events', finalList[4].Campaign_Group__c, 'Mapping is incorrect');
    }
    
    public static testmethod void PersonRecordsWithCTAs_ValidStatus_CampaignMemberAssigned() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        Integer conCount = 5;
        List<Id> idList = new List<Id>();
        List<Contact> conList = createContacts(conCount, testAccount.Id);
        insert conList;
        for (Integer i = 0; i < conCount ; i++) {
            conList[i].Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
            idList.add(conList[i].id);
        }
        update conList;
        for (Integer i = 0; i < conCount ; i++) {
            conList[i].Latest_Campaign_ID__c = cmpgn.Id;
        }
        update conList;
        
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        Test.stopTest();

        List<Lead> akamaiLeadList = [Select Id, Primary_Campaign__c from lead where Associated_Contact__c in :idList];
        for (Integer i = 0; i < conCount ; i++) {
            system.assertEquals(cmpgn.Id, akamaiLeadList[i].Primary_Campaign__c, 'Campaign Id Should be same on CTA primary');
        }
    }
    
    public static testmethod void PersonRecordsWithCTAs_ClosedAndConvertedStatus_CampaignMemberAssigned() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        Integer conCount = 2;
        List<Id> idList = new List<Id>();
        List<Contact> conList = CreateContacts(conCount, testAccount.Id);
        insert conList;
        for (Integer i = 0; i < conCount ; i++) {
            conList[i].Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
            idList.add(conList[i].id);
        }
        update conList;
        for (Integer i = 0; i < conCount ; i++) {
            conList[i].Latest_Campaign_ID__c = cmpgn.Id;
        }
        update conList;
        
        List<Lead> akamaiLeads = [Select Id, Primary_Campaign__c from lead where Associated_Contact__c in :idList];
        akamaiLeads[0].Validation_Override__c = true;
        akamaiLeads[0].Lead_Qualification_Status__c = 'Closed Competitor Account';
        
        akamaiLeads[1].Validation_Override__c = true;
        akamaiLeads[1].Product_Line__c = 'Enterprise';
        akamaiLeads[1].Authority__c = 'Test Authority';
        akamaiLeads[1].Need__c = 'Test Need';
        akamaiLeads[1].Money__c = 'Test Urgency';
        akamaiLeads[1].Urgency__c = 'Test Money';
        akamaiLeads[1].ANUM_Description__c = 'Test ANUM';
        akamaiLeads[1].Lead_Qualification_Status__c = 'Converted';
        
        update akamaiLeads;
        
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        Test.stopTest();

        List<Lead> akamaiLeadList = [Select Id, Primary_Campaign__c, Status from lead where Associated_Contact__c in :idList];
        for (Integer i = 0; i < conCount ; i++) {
            system.assertEquals(cmpgn.Id, akamaiLeadList[i].Primary_Campaign__c);
        }
    }
    
    
    public static testmethod void CTA_ValidAndInvalidDates_CampIdAssignedOnValidCTAs() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        Integer conCount = 5;
        List<Id> idList = new List<Id>();
        List<Contact> conList = createContacts(conCount, testAccount.Id);
        insert conList;
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        List<Lead> akamaiLeads = createLeads(conCount, testAccount, akamaiRecordTypeId);
        Integer i = 0;
        for(Lead akamaiLead : akamaiLeads) {
            akamaiLead.Associated_Contact__c = conList[i].Id;
            i++;
        }
        insert akamaiLeads;
        for(Lead akamaiLead : akamaiLeads) {
            Datetime oldDate = Datetime.now().addDays(-200);
            Test.setCreatedDate(akamaiLead.Id, oldDate);
            idList.add(akamaiLead.Id);
        }
        for (Integer j = 0;j < conCount ; j++) {
            conList[j].Latest_Campaign_ID__c = cmpgn.Id;
        }
        update conList;
        
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        Test.stopTest();
        List<Lead> akamaiLeadList = [Select Id, Primary_Campaign__c, CreatedDate from lead where Id in :idList];
        for (Integer k = 0; k < conCount ; k++) {
            system.assertEquals(null, akamaiLeadList[k].Primary_Campaign__c, 'CTA primary shlould not have any primary campaign');
        }
    }
    
    public static testmethod void CTALeadWithAssociatedOppty_LatestAkamIdPresent_C2AAndOpptyGetsCampaignId() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Contact testContact = [Select Id from Contact where FirstName = 'Test' and LastName = 'Contact2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c, ParentId from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        Id campaignTacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic').getRecordTypeId();

        Campaign cmpgn2 = utilTestClass.CreateCampaign('__ TEST CMPGN2');
        cmpgn2.recordTypeId = campaignTacticRecordTypeId;
        cmpgn2.AKAM_Campaign_ID__c = 'TC-1235';
        cmpgn2.ParentId = cmpgn.ParentId;
        insert cmpgn2;
        
        Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty2','1. Identify Need');
        testOppty.AccountId =testAccount.Id;
        testOppty.CloseDate = Date.today().addMonths(4);
        insert testOppty;
        
        testContact.Latest_Campaign_ID__c = cmpgn2.Id;
        update testContact;
            
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.Associated_Account__c = testAccount.Id;
        testLead.email = 'testmlcm2@akamai.com';
        testLead.status = 'New';
        testLead.CurrencyIsoCode = 'USD';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Test';
        testLead.lastname = 'Lead2';
        testLead.website = 'testwebsite.com';
        testLead.industry = 'Banking';
        testLead.street = 'Test street';
        testLead.city = 'Test City';
        testLead.state = 'Test state';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        testLead.description = 'Test Description';
        insert testLead;
        
        testLead.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update testLead;
        
        //System.debug('Contact value' + ConInfo);
        
        testLead.Latest_Campaign_AKAM_ID__c = cmpgn.AKAM_Campaign_ID__c;
        update testLead;
        
        Lead akamaiLead = [Select Id, Latest_campaign_Akam_id__c, Associated_Opportunity__c from lead where Parent_Lead__c = :testLead.Id];
        akamaiLead.Associated_Opportunity__c = testOppty.Id;
        akamaiLead.Associated_Contact__c = testContact.Id;
        update akamaiLead;
        
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        
        Test.stopTest();
        
        List<Opportunity> oppty = [Select Id, CampaignId from Opportunity limit 1];
        
        Lead C2ALead = [Select Id, Primary_Campaign__c from Lead where Id = :akamaiLead.Id];
        List<CampaignMember> cmList = [Select Id, LeadId, CampaignId from CampaignMember where LeadId = :akamaiLead.Id];
        
        // check that no Cmapiang member is created and akamai lead along with oppty is updated with campaing id
        system.assertEquals(cmList.size(), 0, 'No campaign member should be created');
        
        system.assertEquals(C2ALead.Primary_Campaign__c, cmpgn2.Id, 'CTA should have same primary campaign as that of contact');
        system.assertEquals(oppty[0].CampaignId, cmpgn2.Id, 'Opty should have same primary campaign as that of CTA');
    }
    
    private static List<Contact> createContacts(Integer conCount, Id AccId) {
        List<Contact> conList = new List<Contact>();
        Contact con = null;
        for(Integer i = 0; i<conCount ; i++) {
            con = utilTestClass.CreateContact('Test','Contact2' + i);
            con.AccountId = AccId;
            conList.add(con);
        }
        return conList;
    }
    
    private static List<Campaign> createTacticCampaigns(Integer campaignCount, Id programcampId) {
        Id campaignTacticRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Tactic').getRecordTypeId();
        List<Campaign> campaignRecs = new List<Campaign>();
        Campaign cmpgn = null;
        Integer i;
        for(i = 0 ; i < campaignCount ; i++) {
            cmpgn = utilTestClass.CreateCampaign('__ TEST CMPGN' + i);
            cmpgn.recordTypeId = campaignTacticRecordTypeId;
            cmpgn.AKAM_Campaign_ID__c = 'TC-1234' + i;
            cmpgn.ParentId = programcampId;
            campaignRecs.add(cmpgn);
        }
        return campaignRecs;
    }
    
    private static List<Lead> createLeads(Integer leadCount, Account testAccount,Id RecordTypeId ) {
        List<Lead> leadList = new List<Lead>();
        for(integer i =0 ; i< leadCount ; i++) {
            Lead lObj = new Lead();
            lObj.RecordTypeId = RecordTypeId;
            lObj.FirstName = 'Test';
            lObj.LastName = 'ML00' + (i+1);
            lObj.Email = lObj.FirstName + lObj.LastName + '@akamai.com';
            lObj.Associated_Account__c = testAccount.Id;
            lObj.Company = 'Test Company';
            leadList.add(lObj);
        }
        return leadList;
    }
}