@isTest(seeAllData = false)
public class WelinaPlaygroundJITHandlerTest {
    private static Profile communityCustomers = [select id from profile where name='SFCommunityCustomers'][0];
    @testSetUp static void createTestData(){
        //creating account
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
        
        //creating contact
        Contact con = utilTestClass.CreateContact('Test','JIT');
        con.AccountId = account.Id;
        con.Active_Portal_Login__c=true;
        insert con;
    }
    @isTest static void testCustomerUserCreationUpdation(){
        List<Contact> contact = [Select Id, Name, FirstName, LastName, Email, Akam_Contact_Id__c from contact where name = 'Test JIT'];
        jitProvisioning(contact, 'Customer');
    }
    @isTest static void testPartnerUserCreationUpdation(){
        List<Contact> contact = [Select Id, Name, FirstName, LastName, Email, Akam_Contact_Id__c from contact where name = 'Test JIT'];
        jitProvisioning(contact, 'Partner');
    }
    private static void jitProvisioning(List<Contact> contact, String userType){
        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First', contact.get(0).FirstName);
        attributes.put('Last', contact.get(0).LastName);
        attributes.put('email', contact.get(0).Email);
        attributes.put('Company', 'Akamai');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('federationIdentifier', contact.get(0).Akam_Contact_Id__c);
        attributes.put('UserType', userType);
        WelinaPlaygroundJITHandler jit = new WelinaPlaygroundJITHandler();
        //testing createUser interface method
        jit.createUser(null, null, null, contact.get(0).Akam_Contact_Id__c, attributes, null);
        List<User> users = [Select Id,IsActive from user where name =:contact.get(0).Name];
        System.AssertEquals(users.isEmpty(), false);
        users.get(0).IsActive = false;
        update users;
        jit.createUser(null, null, null, contact.get(0).Akam_Contact_Id__c, attributes, null);
        users = [Select Id,IsActive from user where name =:contact.get(0).Name];
        System.AssertEquals(users.get(0).IsActive, true);
        //testing updateUser interface method
        users = [Select Id,IsActive from user where name =:contact.get(0).Name];
        users.get(0).IsActive = false;
        update users;
        jit.updateUser(users.get(0).Id, null, null, null, contact.get(0).Akam_Contact_Id__c, attributes, null);
        users = [Select Id,IsActive from user where name =:contact.get(0).Name];
        System.AssertEquals(users.get(0).IsActive, true);
    }
}