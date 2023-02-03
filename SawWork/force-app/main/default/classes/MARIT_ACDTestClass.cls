//created as part of ACD Implementation for MARIT-946 
//all test methods related to ACD2.0 are incorporated in this test class
@isTest
public class MARIT_ACDTestClass {
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 1; 
    @testSetUp static void testDataCreation(){
        System.runAs(dmlUser){
            Account testAccount = utilTestClass.CreateAccount('Test Account2');
            insert testAccount;
            Contact con = new Contact();
            con.LastName = 'Test Contact';
            con.AccountId = testAccount.Id;
            con.Email = 'test789@akamai.com.invalid';
            con.Phone = '9864573265';
            con.MobilePhone = '8764538290';
            con.Assistant_Phone__c = '6457837800';
            insert con;
            Lead ml = new Lead();
            ml.LastName='MarketoLead';
            ml.Company='Company';
            ml.Phone = '7869045600';
            ml.MobilePhone = '9876543467';
            ml.Email = 'test258@akamai.com.invalid';
            ml.Associated_Account__c = testAccount.Id;
            ml.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            insert ml;
        }
    }
    static testmethod void ACDUpdatePhoneFieldsOnLeadJob(){
        Test.startTest();
        ACDUpdatePhoneFieldsOnLead acdLeadPhoneUpdate = new ACDUpdatePhoneFieldsOnLead();
        database.executeBatch(acdLeadPhoneUpdate);
        Test.stopTest();
    }
    static testmethod void ACDUpdatePhoneFieldsOnContactJob(){
        Test.startTest();
        ACDUpdatePhoneFieldsOnContact acdContactPhoneUpdate = new ACDUpdatePhoneFieldsOnContact();
        database.executeBatch(acdContactPhoneUpdate);
        Test.stopTest();
    }
    static testMethod void acdClickToDialFunctionalityTest(){
        Account testAccount = utilTestClass.CreateAccount('Test Account3');
        insert testAccount;
        Contact con = new Contact();
        con.LastName = 'Test Contact';
        con.AccountId = testAccount.Id;
        con.Email = 'test123@akamai.com.invalid';
        con.Phone = '9864573265';
        con.MobilePhone = '8764538290';
        insert con;
        Lead ml = new Lead();
        ml.LastName='MarketoLead';
        ml.Company='Company';
        ml.Phone = '7869045600';
        ml.MobilePhone = '9876543467';
        ml.Email = 'test456@akamai.com.invalid';
        ml.Associated_Account__c = testAccount.Id;
        ml.RecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        insert ml;
        Contact con1 = [Select Id,Phone,Phone_Custom__c,MobilePhone,MobilePhone_Custom__c from Contact where email ='test123@akamai.com.invalid' limit 1];
        Lead ml1 = [Select Id,Phone,Phone_Custom__c,MobilePhone,MobilePhone_Custom__c from Lead where email ='test456@akamai.com.invalid' limit 1];
        //to test copy over from new to old fields
        con1.Phone_Custom__c = '8877665544';
        update con1;
        ml1.MobilePhone_Custom__c = '5566778899';
        update ml1;
        Contact con2 = [Select Id,Phone,Phone_Custom__c,MobilePhone,MobilePhone_Custom__c from Contact where email ='test123@akamai.com.invalid' limit 1];
        System.assert(con2.Phone == '8877665544');
        Lead ml2 = [Select Id,Phone,Phone_Custom__c,MobilePhone,MobilePhone_Custom__c from Lead where email ='test456@akamai.com.invalid' limit 1];
        System.assert(ml2.MobilePhone == '5566778899');
        //to test whether custom fields blank out when do not call flag is checked
        con.DoNotCall =true;
        update con;
        ml.DoNotCall = true;
        update ml;
        Contact con3 = [Select Id,Phone,Phone_Custom__c,MobilePhone,MobilePhone_Custom__c from Contact where email ='test123@akamai.com.invalid' limit 1];
        System.assert(con3.Phone_Custom__c == null);
        System.assert(con3.MobilePhone_Custom__c == null);
        Lead ml3 = [Select Id,Phone,Phone_Custom__c,MobilePhone,MobilePhone_Custom__c from Lead where email ='test456@akamai.com.invalid' limit 1];
        System.assert(ml3.Phone_Custom__c == null);
        System.assert(ml3.MobilePhone_Custom__c == null);
        //validation error when sdr updates phone field when dnc flag is checked
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        System.runAs(SDR){
            Lead ml4 = [Select Id,Phone_Custom__c,MobilePhone_Custom__c from Lead where email ='test456@akamai.com.invalid' limit 1];
            ml4.Phone_Custom__c = '887766';
            try{
                update ml4;
            }catch(Exception e){
                System.assert(e.getMessage().contains('Update to the field cannot be made as the Do Not Call Flag is checked'));
            }
        }
    }
}