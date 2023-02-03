@isTest(seeAllData = false)
public class MARIT_AccountTriggerHandlerTest {
    public static User dmlUser = utilTestClass.getTestRunUser();
    @isTest static void TestProjectedAccountOwnerPopulation(){
        System.runAs(dmlUser) {
            //Creating owner for account
            Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name=:roleName][0].Id;
            User accOwner = CreateUser('ONA',salesRepProfileId,roleId);
            insert (new User[] {accOwner});
            Id ownerId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            
            //creating DRA
            DRASubprocessConfig__c dra = new DRASubprocessConfig__c();
            dra.Vertical__c = 'Commerce';
            dra.Country__c = 'Ghana';
            dra.Sub_Vertical__c = 'Manufacturing';
            dra.Region_or_State__c = '<All>';
            dra.SDR_Name__c = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            dra.Projected_SDR__c = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
        
            //creating Account Reassignment rule
            Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
            rule.Associated_User__c = ownerId;
            rule.Name = 'TestRulePAO';
            rule.User_Role__c = '2021_Carrier APJ';

            
            //NonPool account
            Account normalAcc = new Account();
            normalAcc.Name = 'testAcc';
            normalAcc.Website = 'www.testWeb.com';
            normalAcc.Vertical__c =  'Commerce';
            normalAcc.Sub_Vertical__c = 'Manufacturing';
            normalAcc.BillingCountry = 'Ghana';
            normalAcc.OwnerId = accOwner.Id;
            
            //ONA account
            String poolUserId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            Account onaAccount = new Account();
            onaAccount.Name = 'AKAMAI-TestdotTest';
            onaAccount.Vertical__c =  'Commerce';
            onaAccount.Sub_Vertical__c = 'Manufacturing';
            onaAccount.BillingCountry = 'Ghana';
            onaAccount.BillingState = 'XYZ';
            onaAccount.OwnerId = ownerId;
            onaAccount.Projected_Sales_Owner__c = null;
            onaAccount.Projected_SDR__c = null;
            
            //creating lead
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            Lead l = new Lead();
            l.RecordTypeId = marketoRecordTypeId;
            l.Status = 'New';
            l.Company = 'Test Company1000';
            l.FirstName = 'Test1';
            l.LastName = 'Lead1';
            l.Projected_SDR__c = null;
            //creating contact
            Contact c = new Contact();
            c.FirstName = 'Test1';
            c.LastName = 'contact1';
            c.Email = 'test1729Ramanujan@linkedin.com';
            c.Projected_SDR__c = null;
        
            Test.startTest();
            insert dra;
            insert rule;
            Account poolAcc= SObjectFactory.createPoolUserAccount();
            insert onaAccount;
            insert normalAcc;
            onaAccount.OwnerId = accOwner.Id;
            onaAccount.Vertical__c = 'Gaming';
            onaAccount.Sub_Vertical__c = 'Middleware';
            normalAcc.OwnerId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            normalAcc.Vertical__c = 'Gaming';
            normalAcc.Sub_Vertical__c = 'Middleware';
            l.Associated_Account__c = onaAccount.Id;
            c.AccountID = onaAccount.Id;
            insert l;
            insert c;
            update onaAccount;
            update normalAcc;
            l.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
            update l;
            onaAccount.Vertical__c = 'Commerce';
            onaAccount.Sub_Vertical__c = 'Manufacturing';
            onaAccount.Website = 'nosports.live.com';
            update onaAccount;
            onaAccount.Vertical__c = 'Gaming';
            onaAccount.Sub_Vertical__c = 'Middleware';
            onaAccount.Projected_SDR__c = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            update onaAccount;
            Test.stopTest();
        }
        
    }
    private static User CreateUser(String pUsrAlias, Id profileId, Id roleId)
    {
        User newUser = new User(alias = pUsrAlias,
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8',
                                lastname=pUsrAlias,
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles',
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = profileId,
                                UserRoleId = roleId );
        return newUser;
    }
    
    @isTest static void TestAccountFormulaFieldUpdatesForCDP(){
        System.runAs(dmlUser) {
            //geting owner id
            Id ownerId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
            //creating account
            Account acc = new Account();
            acc.Name = 'testAcc-CDP';
            acc.Website = 'www.test.com';
            Test.startTest();
            insert acc;
            //updating account
            acc.TERR_HIER_1__c = 'APJ';
            acc.OwnerId = ownerId;
            //acc.Target_Lists__c = '2020 Media Tops - Parent';
            update acc;
            Test.stopTest();
        }
    }

    @isTest static void testCreateReassignmentsForONAAcc() {
        Id ownerId = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
        //creating DRA
        DRASubprocessConfig__c dra = new DRASubprocessConfig__c();
        dra.Vertical__c = 'Commerce';
        dra.Country__c = 'Ghana';
        dra.Sub_Vertical__c = 'Manufacturing';
        dra.Region_or_State__c = '<All>';
        dra.SDR_Name__c = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
        dra.Projected_SDR__c = GSMSettings.getValue('ONAPoolOpsIdList').split(',').get(0);
        
        //creating Account Reassignment rule
        Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
        rule.Associated_User__c = ownerId;
        rule.Name = 'TestRulePAO';
        rule.User_Role__c = '2021_Carrier APJ';
        
        //ONA account
        Account onaAccount = new Account();
        onaAccount.Name = 'AKAMAI-TestdotTest';
        onaAccount.Vertical__c =  'Commerce';
        onaAccount.Sub_Vertical__c = 'Manufacturing';
        onaAccount.BillingCountry = 'Ghana';
        onaAccount.BillingState = 'XYZ';
        onaAccount.OwnerId = ownerId;
        onaAccount.Projected_Sales_Owner__c = null;
        onaAccount.Projected_SDR__c = null;
        
        //creating lead
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Lead l = new Lead();
        l.RecordTypeId = marketoRecordTypeId;
        l.Status = 'New';
        l.Company = 'Test Company1000';
        l.FirstName = 'Test1';
        l.LastName = 'Lead1';
        l.Email = 'onaEmail001@akamai.com';
        l.Projected_SDR__c = null;
        Test.startTest();
        insert dra;
        insert rule;
        insert onaAccount;
        l.Associated_Account__c = onaAccount.Id;
        insert l;
        l.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
        update l;
        Lead ctaLead = [Select Id, Company from Lead where Email = 'onaEmail001@akamai.com' and RecordTypeId =:akamaiRecordTypeId limit 1];
        System.assertEquals(true, ctaLead!=null, 'CTA should not be null');

        ctaLead.Validation_Override__c = true;
        ctaLead.Product_Line__c = 'Enterprise';
        ctaLead.Authority__c = 'Test Authority';
        ctaLead.Need__c = 'Test Need';
        ctaLead.Money__c = 'Test Urgency';
        ctaLead.Urgency__c = 'Test Money';
        ctaLead.ANUM_Description__c = 'Test ANUM';
        ctaLead.Lead_Qualification_Status__c = 'Converted';
        update ctaLead;
        Test.stopTest();
    }
}