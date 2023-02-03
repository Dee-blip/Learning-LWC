@isTest(seeAllData=false)
public class L2Q_UpdateLeadAndContactCountTest {
    @testSetup
    static void setupMethod() {
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
            .eagerPopulate()
            .put(Account.Vertical__c, 'Gaming')
            .put(Account.Sub_Vertical__c, 'Gaming')
            .count(1)
            .create()
            .getRecords();
        List<Contact> listOfTestContacts = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
            .eagerPopulate()
            .put(Contact.AccountId, listOfTestAccounts)
            .count(1)
            .create()
            .getRecords();
        Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        new SObjectBuilder(Lead.SObjectType)
            .eagerPopulate()
            .count(1)
            .put(Lead.RecordTypeId, akamaiLeadRecordTypeId)
            .put(Lead.Associated_Contact__c, listOfTestContacts)
            .put(Lead.Associated_Account__c, listOfTestAccounts)
            .put(Lead.Product_Line__c,'Enterprise')
            .put(Lead.Country,'India')
            .put(Lead.State,'Karnataka')
            .create();
    }
    

    @isTest static void negitiveTestUpdateLeadAndContactCountOnAccount(){
        test.startTest();
        Account a = new Account(Name='TestAcc',Website='www.test.test.com');
        a.Number_of_Associated_Contacts__c = 0;
        a.Number_of_Associated_Leads__c = 0;
        insert a;
        Count_Leads_And_Contacts_On_Acc_Helper__c ah = new Count_Leads_And_Contacts_On_Acc_Helper__c();
        ah.Account_Id__c = a.Id;
        ah.isProcessed__c = false;
        ah.Error_Message__c = '';
        insert ah;
        System.enqueueJob(new L2Q_UpdateLeadAndContactCountOnAccount());
        test.stopTest();
    }

    @isTest static void testUpdateLeadAndContactCountOnAccount(){
        Test.startTest();
        String CRON_EXP = '0 0 0,12 * * ?';
        L2Q_UpdateLeadAndContactCountScheduler s = new L2Q_UpdateLeadAndContactCountScheduler(); 
        System.schedule('UpdateLeadAndContactCountOnAccountTest', CRON_EXP, s);
        Test.stopTest();
    }
}