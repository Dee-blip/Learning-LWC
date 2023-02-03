//Created by mayank Bansal as part of MARIT-418
@isTest(seeAllData = false)
private class LeanDataUpdateForMatchedAccTest {
    
	private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 1; 
    private static string accountIdForContact = [Select Id,Value__c from LeanData__mdt where DeveloperName = 'WWWLeadGenAccountId'].value__c;

    @testSetUp static void testDataCreation()
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
                .put(Contact.LeanData_Reporting_Matched_Account__c, listOfTestAccounts)
                .put(Contact.Validation_Override__c, True)
                .put(Contact.AccountId, accountIdForContact)
                .count(numberOfTestLeads)
                .create()
                .getRecords();

            List<Account> listOfTestAccounts1 = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .put(Account.Type, 'Lead')
                .put(Account.Type,'Lead')
                .count(numberOfTestLeads)
                .create()
                .getRecords();
            
            List<Contact> listOfTestContacts1 = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.LeanData_Reporting_Matched_Account__c, listOfTestAccounts1)
                .put(Contact.Validation_Override__c, True)
                .put(Contact.AccountId, accountIdForContact)
                .count(numberOfTestLeads)
                .create()
                .getRecords();
            
            List<Account> listOfTestAccounts2 = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .put(Account.Type, 'Lead')
                .put(Account.Type,'Inactive')
                .count(numberOfTestLeads)
                .create()
                .getRecords();
            
            List<Contact> listOfTestContacts2 = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.LeanData_Reporting_Matched_Account__c, listOfTestAccounts2)
                .put(Contact.Validation_Override__c, True)
                .put(Contact.AccountId, accountIdForContact)
                .count(numberOfTestLeads)
                .create()
                .getRecords();
            
       		Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
       		
            Lead l = new Lead();
            l.RecordTypeId = marketoRecordTypeId;
            l.email = 'abdfTesting@email.com';
            l.Associated_Account__c = listOfTestAccounts[0].id;
            l.status = 'New';
            l.CurrencyIsoCode = 'USD';
            l.company = 'Test Company34';
            l.firstname = 'Test1';
            l.lastname = 'Lead1';
            l.LeanData__Reporting_Matched_Account__c = listOfTestAccounts[0].id;
            l.website = 'testwebsite1re.com';
            l.industry = 'Banking';
            l.street = 'Test street';
            l.city = 'Test City';
            l.state = 'Test state';
            l.PostalCode  = '201323';
            l.country = 'USA';
            l.description = 'Test Description';
            insert l;
            
            l.Associated_Account__c = null;
            l.Validation_Override__c = true;
            update l;

        }
    }
    
    static testmethod void LeanDataUpdateContactWithMatchedAcc(){
        
        Test.startTest();
        LeanDataUpdateContactWithMatchedAcc ldatua = new LeanDataUpdateContactWithMatchedAcc();
        database.executeBatch(ldatua);
        Test.stopTest();
    }
    
    static testmethod void LeanDataUpdateLeadWithMatchedAcc(){
        
        Test.startTest();
        LeanDataUpdateLeadWithMatchedAcc ldatua = new LeanDataUpdateLeadWithMatchedAcc();
        database.executeBatch(ldatua);
        Test.stopTest();
    }
}