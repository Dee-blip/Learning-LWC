@isTest(seeAllData = false)
public class MARIT_LeadContactUtilsTest {
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        Account acc = utilTestClass.CreateAccount('Test Account for Live Chat Transcript');
        insert acc;
        
        // Create contact
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        con.email = 'teste1264@akamai1.com.invalid';
        con.Description = 'test data';
        con.MailingCountry = 'USA';
        insert con; 

        // Create contact
        Contact conBatch = utilTestClass.CreateContact('__ Test Second','__Test Contact');
        conBatch.AccountId = acc.Id;
        conBatch.email = 'teste164Contact@akamai1.com.invalid';
        conBatch.Description = 'test data';
        conBatch.MailingCountry = 'USA';
        conBatch.phone = '3458761236';
        insert conBatch;  

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
    
    static testMethod void testE164PhoneFormatting() {
        Test.startTest();
        Contact con = [Select Id, E164_Phone__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
        con.phone = '3458761236 ext 1234';
        con.Mobilephone = '3458761889';
        update con;
        con = [Select Id, E164_Phone__c, E164_MobilePhone__c,Phone_Extension__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
        System.assert(con.E164_Phone__c == '+13458761236');
        System.assert(con.E164_MobilePhone__c == '+13458761889');
        System.assert(con.Phone_Extension__c == '1234');
        Test.stopTest();    
    } 
    
    static testMethod void testE164PhoneFormattingError() {
        Test.startTest();
        Contact con = [Select Id, E164_Phone__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
        con.phone = '345876123615';
        con.Mobilephone = '345876188914';
        update con;
        con = [Select Id, Phone_Formatting_error__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
        System.assert(con.Phone_Formatting_error__c == 'Phone : Doesnt meet number count requirement or Country code doesnt match with assigned country. MobilePhone : Doesnt meet number count requirement or Country code doesnt match with assigned country.');
        Test.stopTest();    
    }
    
    static testMethod void testE164PhoneFormattingErrorDueToCountry() {
        Test.startTest();
        Contact con = [Select Id, E164_Phone__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
        con.MailingCountry = 'TBD';
        update con;
        con = [Select Id, Phone_Formatting_error__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
        System.assert(con.Phone_Formatting_error__c == 'Country is TBD');
        con.MailingCountry = 'Ascension Island';
        update con;
        con = [Select Id, Phone_Formatting_error__c from Contact where email = 'teste1264@akamai1.com.invalid' limit 1];
        System.assert(con.Phone_Formatting_error__c == 'Country doesnt have a subcriber number count updated');                    
        Test.stopTest();    
    }

    static testmethod void e164PhoneFormattingOnLeadJob(){
        Test.startTest();
        Lead l = [Select Id, E164_Phone__c from Lead where email = 'teste164Lead@akamai1.com.invalid' limit 1];
        l.E164_Phone__c = null;
        update l;
        l = [Select Id, E164_Phone__c from Lead where email = 'teste164Lead@akamai1.com.invalid' limit 1];
        System.assert(l.E164_Phone__c == null);
        MARIT_UpdateE164PhoneFieldsOnLead e164LeadPhoneUpdate = new MARIT_UpdateE164PhoneFieldsOnLead();
        database.executeBatch(e164LeadPhoneUpdate);
        Test.stopTest();
    }
    
    static testmethod void e164PhoneFormattingOnContactJob(){
        Test.startTest();
        Contact con = [Select Id, E164_Phone__c from Contact where email = 'teste164Contact@akamai1.com.invalid' limit 1];
        con.E164_Phone__c = null;
        update con;
        con = [Select Id, E164_Phone__c from Contact where email = 'teste164Contact@akamai1.com.invalid' limit 1];
        System.assert(con.E164_Phone__c == null);
        MARIT_UpdateE164PhoneFieldsOnContact e164ContactPhoneUpdate = new MARIT_UpdateE164PhoneFieldsOnContact();
        database.executeBatch(e164ContactPhoneUpdate);
        Test.stopTest();
    }

}