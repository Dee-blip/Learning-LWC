/* History:
* =========================
* @author Himanshu Verma,  28th Sep, 2020  
MARIT-776
*/
@isTest(seeAllData=false)
public class MARIT_CTAPathComponentTest {
    private static User dmlUser = new User(id=UserInfo.getUserId());
    @testSetup
    static void setupMethod() 
    {
        System.runAs(dmlUser) {
            Account acc = utilTestClass.CreateAccount('Test Account2');
            insert acc;
            
            // Create contact
            List<Contact> conList = new List<Contact>();
            Contact con = utilTestClass.CreateContact('Test First','Test Contact');
            con.AccountId = acc.Id;
            con.email = 'testContact001@akamai.com';
            insert con;
        }
    }
    public static testmethod void CTALead_CTAShouldBeReturned() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2']; 
        Contact testContact = [select Id from Contact where Email = 'testContact001@akamai.com']; 
        Id akamaiLeadTypeRecordId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.Associated_Contact__c = testContact.Id;
        testLead.recordTypeId = akamaiLeadTypeRecordId;
        testLead.email = 'testGteLeadId@akamai.com';
        testLead.status = 'New';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        testLead.street = 'Test street';
        testLead.city = 'Test City';
        testLead.state = 'TX';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        insert testLead;

        string res = MARIT_CTAPathComponent.getLeadObj(testLead.Id);
        System.assert(res.contains(testLead.Id), 'We must get a lead object');
    }
    public static testmethod void CTALead_OnConversionWithAllFieldsPopulated_ConversionSuccessfull() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2']; 
        Contact testContact = [select Id from Contact where Email = 'testContact001@akamai.com']; 
        Id akamaiLeadTypeRecordId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.Associated_Contact__c = testContact.Id;
        testLead.recordTypeId = akamaiLeadTypeRecordId;
        testLead.email = 'testGteLeadId@akamai.com';
        testLead.status = 'New';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        testLead.state = 'TX';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        insert testLead;
        
        testLead.Product_Line__c = 'Enterprise';
        testLead.Authority__c = 'Test Authority';
        testLead.Need__c = 'Test Need';
        testLead.Money__c = 'Test Urgency';
        testLead.Urgency__c = 'Test Money';
        testLead.ANUM_Description__c = 'Test ANUM';
        update testLead;
        
        testLead.Lead_Qualification_Status__c = 'Converted';
        
        String res = MARIT_CTAPathComponent.updateLeadStatus(testLead);
        System.assert(res.contains('Success'), 'Lead should have been successfully converted');
    }
    
    public static testmethod void CTALead_OnConversionWithNoANUMFields_ConversionUnSuccessful() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2']; 
        Contact testContact = [select Id from Contact where Email = 'testContact001@akamai.com']; 
        Id akamaiLeadTypeRecordId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.Associated_Contact__c = testContact.Id;
        testLead.recordTypeId = akamaiLeadTypeRecordId;
        testLead.email = 'testGteLeadId@akamai.com';
        testLead.status = 'New';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        testLead.state = 'TX';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        insert testLead;
        
        testLead.Lead_Qualification_Status__c = 'Converted';
        
        String res = MARIT_CTAPathComponent.updateLeadStatus(testLead);
        System.assert(res.contains('complete ANUM qualification'), 'Lead should have Anum fields');
    }
}