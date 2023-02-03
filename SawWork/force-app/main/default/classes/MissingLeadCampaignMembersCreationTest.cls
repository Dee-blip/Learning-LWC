/* History:
* =========================
* @author  Shiva Ganesan,  24th April 2018  
SFDC-2596 
*/
@isTest(seeAllData=false)
public class MissingLeadCampaignMembersCreationTest 
{
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
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
            testContact.Email = 'testMissingCampCon001@akamai.com';
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
    
    public static testmethod void Test_MLCMJobExecution() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Contact testContact = [Select Id from Contact where FirstName = 'Test' and LastName = 'Contact2'];
        
        Lead testLead = utilTestClass.CreateLead();
        testLead.Associated_Contact__c = testContact.Id;
        insert testLead;
        
        Campaign testCampaign = utilTestClass.CreateCampaign('Test Campaign');
        insert testCampaign;
        
        CampaignMember testContactCM = new CampaignMember();
        testContactCM.ContactId = testContact.Id;
        testContactCM.CampaignId = testCampaign.Id;
        testContactCM.Status = 'Sent';
        insert testContactCM;
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
    }
    
    public static testmethod void TestLeadWithAssociatedOppty_LatestAkamIdPresent_C2AAndOpptyGetsCampaignId() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        
        Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty2','1. Identify Need');
        testOppty.AccountId =testAccount.Id;
        testOppty.CloseDate = Date.today().addMonths(4);
        insert testOppty;
        
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
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
        
        testLead.Latest_Campaign_AKAM_ID__c = cmpgn.AKAM_Campaign_ID__c;
        update testLead;
        
        Lead akamaiLead = [Select Id, Latest_campaign_Akam_id__c, Associated_Opportunity__c from lead where Parent_Lead__c = :testLead.Id];
        akamaiLead.Associated_Opportunity__c = testOppty.Id;
        update akamaiLead;
        
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        
        Test.stopTest();
        
        List<Opportunity> oppty = [Select Id, CampaignId from Opportunity limit 1];
        
        Lead C2ALead = [Select Id, Primary_Campaign__c from Lead where Id = :akamaiLead.Id];
        List<CampaignMember> cmList = [Select Id, LeadId, CampaignId from CampaignMember where LeadId = :akamaiLead.Id];
        
        // check that no Cmapiang member is created and akamai lead along with oppty is updated with campaing id
        system.assertEquals(cmList.size(), 0);  
        system.assertEquals(C2ALead.Primary_Campaign__c, cmpgn.Id);
        system.assertEquals(oppty[0].CampaignId, cmpgn.Id);
    }
    
    public static testmethod void TestContact_LatestCampIdPresent_C2AGetsCampaignId() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        
        Contact testContact = new Contact();
        testContact.AccountId = testAccount.Id;
        testContact.FirstName = 'Test';
        testContact.LastName = 'ContactWithCampaignJob';
        testContact.email = 'testmclm3@akamai.com';
        insert testContact;
        
        testContact.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update testContact;
        
        testContact.Latest_Campaign_ID__c = cmpgn.Id;
        update testContact;
        
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        Test.stopTest();

        Lead akamaiLead = [Select Id, Primary_Campaign__c from lead where Associated_Contact__c = :testContact.Id];
        //system.assertEquals('test', cmpgn.Id);
        system.assertEquals(akamaiLead.Primary_Campaign__c, cmpgn.Id);
    }
    
    public static testmethod void TestLead_CampaignMemberWithValidStatus_C2AGetsCampaignId() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        // insert marketo lead
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
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
        // create its c2a
        testLead.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update testLead;
        // create a cmapgin member with lead id as this 
        CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(testLead.Id, cmpgn.Id);
        cmpgn_member.Status = 'Responded';
        insert cmpgn_member;
        
        // run the job
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        
        Test.stopTest();
        
        Lead akamaiLead = [Select Id, Primary_Campaign__c from lead where Parent_Lead__c = :testLead.Id];
        System.assertEquals(akamaiLead.Primary_Campaign__c, cmpgn.Id);
    }
    
    public static testmethod void TestLead_CampaignMemberWithInvalidStatus_C2AGetsCampaignId() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Campaign cmpgn = [Select Id, AKAM_Campaign_ID__c from Campaign where Name = '__ TEST CMPGN' and AKAM_Campaign_ID__c = 'TC-1234'];
        // insert marketo lead
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
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
        // create its c2a
        testLead.Lead_Qualification_Stage__c = 'Qualified Lead - Warm';
        update testLead;
        // create a cmapgin member with lead id as this 
        CampaignMember cmpgn_member = utilTestClass.CreateCampaignMember(testLead.Id, cmpgn.Id);
        cmpgn_member.Status = 'Sent';
        insert cmpgn_member;
        
        // run the job
        Test.startTest();
        
        MissingLeadCampaignMembersCreationJob mlcm = new MissingLeadCampaignMembersCreationJob();
        Database.executeBatch(mlcm);
        
        Test.stopTest();
        
        Lead akamaiLead = [Select Id, Primary_Campaign__c from lead where Parent_Lead__c = :testLead.Id];
        System.assertEquals(akamaiLead.Primary_Campaign__c, null);
    } 
}