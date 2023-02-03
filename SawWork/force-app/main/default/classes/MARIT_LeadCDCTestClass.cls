@isTest(seeAllData = false)
public without sharing class MARIT_LeadCDCTestClass {
    public static final User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
    public static final User MARKETOINTEGRATION = [select id from user where profile.name='Marketo Integration' and isactive=true limit 1];
    //creating test data
    @testSetUp static void createTestData(){
        //creating account
        Test.enableChangeDataCapture();
        MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
        settings.Name = 'LeadAsyncConversionFlagStatus';
        settings.Flag_Status__c = true;
        insert settings;

        Account account = utilTestClass.CreateAccount('Test_Account');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '56005';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        account.Vertical__c = 'Business Services';
        account.Sub_Vertical__c = 'BPO';
        insert account;
        
        //creating leads
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        //create akamai lead
        List<Lead> mleads = new List<Lead>();
        Lead l = new Lead();
        l.RecordTypeId = marketoRecordTypeId;
        l.Email = 'integral1729Ramanujan@linkedin.com';
        l.Associated_Account__c = account.Id;
        l.Status = 'New';
        l.Company = 'Company Anonymous';
        l.FirstName = 'TestUnique';
        l.LastName = 'Optimal 1';
        l.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
        mleads.add(l);
        
        //creating contact
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
        con.AccountId = account.Id;
        con.email = 'testContact1@gmail.com';

        System.runAs(MARKETOINTEGRATION){
            insert mLeads;
            insert con;
        }
        
        Test.getEventBus().deliver();
    }
    //test class for manual lead async conversion
    @isTest static void testLeadAsynConversion() {
        List<Lead> c2aLeads = [SELECT Id,Parent_Lead__c,Associated_Opportunity__c,Associated_Contact__c,Lead_Qualification_Status__c,Product_Line__c,ANUM_Description__c,Authority__c,Need__c,Urgency__c,Money__c,QFA_Meeting_Date__c  FROM Lead WHERE Parent_Lead__c != null and Email = 'integral1729Ramanujan@linkedin.com'];
        System.debug(logginglevel.DEBUG,'Akamai Lead:'+c2aLeads.size());
        Test.enableChangeDataCapture();
        System.runAs(SDR){
            if(!c2aLeads.isEmpty()){
                convertC2ALead(c2aLeads);
            }
        }
        Test.getEventBus().deliver();
        c2aLeads = [SELECT Id,Parent_Lead__c,FirstName,LastName,Email,Phone,Associated_Account__c,Title,Associated_Opportunity__c,Associated_Contact__c  FROM Lead WHERE Parent_Lead__c != null and Email = 'integral1729Ramanujan@linkedin.com'];
        if(!c2aLeads.isEmpty()){
            checkSuccessfulConversions(c2aLeads);
        } 
    }
    //Test class for checking errors on leads while converting ineligible leads
    @isTest static void testNetworkContactError() {

        Account acc = [SELECT Id,name,Type,Network_Account__c,Sales_Account__c from account where name = 'Test_Account'];
        acc.Type = 'Akamai Internal';
        acc.Network_Account__c = true;
        acc.Sales_Account__c = false;
        update acc; //insert account of type Internal and Network account
        
        List<Lead> c2aLeads = [SELECT Id,Parent_Lead__c,Title,Associated_Opportunity__c,Associated_Contact__c,Lead_Qualification_Status__c,Product_Line__c,ANUM_Description__c,Authority__c,Need__c,Urgency__c,Money__c,QFA_Meeting_Date__c  FROM Lead WHERE Parent_Lead__c != null and Email = 'integral1729Ramanujan@linkedin.com'];
        System.debug(logginglevel.DEBUG,'Akamai Lead:'+c2aLeads.size());
        Test.enableChangeDataCapture();
        System.runAs(SDR){
            try{
                if(!c2aLeads.isEmpty()){
                    convertC2ALead(c2aLeads);
                }
            }
            catch(Exception ex){
                System.debug(logginglevel.DEBUG,'Ignore - '+ex.getMessage());
            } 
        }
        Test.getEventBus().deliver();
        c2aLeads = [SELECT Id,Parent_Lead__c,FirstName,LastName,Email,Phone,Associated_Account__c,Title,Associated_Opportunity__c,Associated_Contact__c  FROM Lead WHERE Parent_Lead__c != null and Email = 'integral1729Ramanujan@linkedin.com'];
        if(!c2aLeads.isEmpty()){
            checkFailedConversions(c2aLeads);
        } 
    }
    @isTest static void testEmailValidationError() {
        Contact con = [Select Id,name,email from Contact where email = 'testContact1@gmail.com' LIMIT 1];
        con.Email = 'integral1729Ramanujan@linkedin.com'; 
        update con;

        List<Lead> c2aLeads = [SELECT Id,Parent_Lead__c,Title,Associated_Opportunity__c,Associated_Contact__c,Lead_Qualification_Status__c,Product_Line__c,ANUM_Description__c,Authority__c,Need__c,Urgency__c,Money__c,QFA_Meeting_Date__c  FROM Lead WHERE Parent_Lead__c != null and Email = 'integral1729Ramanujan@linkedin.com'];
        System.debug(logginglevel.DEBUG,'Akamai Lead:'+c2aLeads.size());
        Test.enableChangeDataCapture();
        System.runAs(SDR){
            try{
                if(!c2aLeads.isEmpty()){
                    convertC2ALead(c2aLeads);
                }
            }
            catch(Exception ex){
                System.debug(logginglevel.DEBUG,'Ignore - '+ex.getMessage());
            } 
        }
        Test.getEventBus().deliver();
        c2aLeads = [SELECT Id,Parent_Lead__c,FirstName,LastName,Email,Phone,Associated_Account__c,Title,Associated_Opportunity__c,Associated_Contact__c  FROM Lead WHERE Parent_Lead__c != null and Email = 'integral1729Ramanujan@linkedin.com'];
        if(!c2aLeads.isEmpty()){
            checkFailedConversions(c2aLeads);
        } 
    }
    @isTest static void TestErrorLogInsertion() {
        List<String> ids = new List<String>();
        ids.add('ooA1');
        ids.add('ooA2');
        Exception ex = new CustomException('This is test exception');
        MARIT_LeadCDCEventHandler.insertErrorLogs(ex,'Test Error','MARIT_LeadCDCTestClass.TestErrorLogInsertion',ids);
        List<Error_Log__c> errorlogs = [Select id,Name from Error_Log__c where Name = 'Test Error'];
        System.assert(!errorlogs.isEmpty(), 'Error Log was not inserted');
    }
    public static void convertC2ALead(List<Lead> c2aLeads){
        for(Lead l : c2aLeads){
            l.Product_Line__c = 'Media';
            l.ANUM_Description__c = 'NA';
            l.Authority__c = 'NA';
            l.Need__c = 'NA';
            l.Urgency__c = 'NA';
            l.Money__c = 'NA';
            l.QFA_Meeting_Date__c = date.today();
            l.Lead_Qualification_Status__c = 'Converted';
        }
        update c2aLeads;
    }
    public static void checkSuccessfulConversions(List<Lead> c2aLeads){
        for(Lead l : c2aLeads){
            System.debug(logginglevel.DEBUG,'Oppt ID:'+l.Associated_Opportunity__c);
            System.debug(logginglevel.DEBUG,'Contact ID:'+l.Associated_Contact__c);
            System.assert(l.Associated_Opportunity__c != null, 'Opportunity was not created:'+l.Id);
            System.assert(l.Associated_Contact__c  != null, 'Contact was not created:'+l.Id);
        }
    }
    public static void checkFailedConversions(List<Lead> c2aLeads){
        for(Lead l : c2aLeads){
            System.debug(logginglevel.DEBUG,'Oppt ID:'+l.Associated_Opportunity__c);
            System.assert(l.Associated_Opportunity__c == null, 'Opportunity is created. Expected: Not to be created'+l.Id);
            System.assert(l.Associated_Contact__c == null, 'Contact is created. Expected: Not to be created'+l.Id);
        }
    }
}