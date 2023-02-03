@isTest(seeAllData = false)
public class UpdateContactOnAccountUpdateBatchTest {
    public static User dmlUser = utilTestClass.getTestRunUser();
    @isTest static void TestUpdateContactWithModifiedAccount(){
        System.runAs(dmlUser) {
            CDP_Config__c cdp_config_record = new CDP_Config__c(Name = 'UpdatedTimeForContact_AccountFormula', Last_Update_DateTime__c = System.now().addHours(-50));
            insert cdp_config_record;

            String emailAddress = 'CustomContactWorkflow@gmail.com';
            Account newAccount = new Account();
            newAccount.Name = 'CustomContactWorkflowAccount';
            newAccount.BillingCountry = 'India';
            newAccount.BillingState = 'DELHI';
            newAccount.Updated_Date_For_CDP__c = System.now().addDays(-10);
            insert newAccount;

            Contact c = new Contact();
            c.email = emailAddress;
            c.lastname = 'TestLead';
            c.AccountId = newAccount.id;
            insert c;

            List<Contact> contactList = new List<Contact>();
            contactList.add(c);

            Test.startTest();
            newAccount.TERR_HIER_1__c = 'APJ';
            update newAccount;

            UpdateContactOnAccountUpdate updateContact = new UpdateContactOnAccountUpdate();
            //Database.executeBatch(updateContact);
            Database.QueryLocator ql = updateContact.start(null);
            updateContact.execute(null,contactList);
            updateContact.Finish(null);

            Test.stopTest();
        }
    }
}