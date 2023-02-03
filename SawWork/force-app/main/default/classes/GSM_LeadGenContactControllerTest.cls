@isTest(seeAllData=false)
public class GSM_LeadGenContactControllerTest {
    
    
    static testmethod void oneTestToTestThemAll() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Account account =  (Account)new SobjectBuilder(Account.sObjectType)
                .eagerPopulate()                                               
                .create()
                .getRecord();
            Account account1 =  new Account();
            account1.name = 'test';
            insert account1;
            
            
            List<Contact> contacts = (List<Contact>) new SobjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, account.Id)
                .count(1)
                .create()
                .getRecords();
            
            GSM_LeadGenContactController.getLeadGenContacts('test', 1,'');
            GSM_LeadGenContactController.moveLeadGenContacts(contacts, account1.id);
        }
    }
}