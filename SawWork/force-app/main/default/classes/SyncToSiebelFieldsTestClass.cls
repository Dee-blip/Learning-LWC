/***
    SyncToSiebelFieldsTestClass    
    @author : Kartikay Nagal
    @Description : This class is to test SyncToSiebelFields class
   
    @History
    --Developer           --Date            --Change
    Kartikay Nagal         27/05/2015        Created the class to test contact and account fields synced to Siebel.
***/
@isTest
public class SyncToSiebelFieldsTestClass 
{
     static
    {
        utilTestClass.insertCustomSettings();
    }
    private static Account newAcc;
    private static Contact newCon;
    private static List<Contact> contactList = new List<Contact>();

    private static User crmIntUser;

    private static void init()
    {
        newAcc = utilTestClass.CreateAccount('Test Sync Siebel Acc '+utilTestClass.getRandomString(4));
        newCon = utilTestClass.CreateContact('Test Sync Siebel', 'Test Contact 1');
        contactList.add(newCon);  

        newCon = utilTestClass.CreateContact('Test Sync Siebel', 'Test Contact 2');
        contactList.add(newCon);

        Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
        crmIntUser = [Select Id from User where Id = :CrmIntegration];      
    }
    static testMethod void checkContactInsertUpdate()
    {
        init();
        insert newAcc;
        for(Contact eachContact : contactList)
        {
            eachContact.AccountId = newAcc.id;
        }
        insert contactList;
        
        Test.startTest();
        Contact refreshedContact = [Select id, Sync_To_Siebel__c from Contact where id = :contactList[0].id];
        System.assertequals(refreshedContact.Sync_To_Siebel__c,true);
        refreshedContact.Sync_To_Siebel__c = false;
        refreshedContact.Assistant_Name__c = 'Test con';
        update refreshedContact;
        refreshedContact = [Select id, Sync_To_Siebel__c from Contact where id = :refreshedContact.id];
        System.assertequals(refreshedContact.Sync_To_Siebel__c,false);
        refreshedContact.FirstName = 'Siebel Update';
        update refreshedContact;
        refreshedContact = [Select id, Sync_To_Siebel__c,FirstName from Contact where id = :refreshedContact.id];
        System.debug('refreshedContact: '+refreshedContact);
        //System.assertequals(refreshedContact.Sync_To_Siebel__c,true);

        System.runAs(crmIntUser)
        {
            refreshedContact = [Select Id,Sync_To_Siebel__c from Contact where Id = :contactList[1].Id];
            refreshedContact.Sync_To_Siebel__c = false;
            update refreshedContact;

            refreshedContact.Active_Portal_Login__c = true;
            update refreshedContact;
        }

        Test.stopTest();  
    }
    static testMethod void checkAccountInsertUpdate()
    {
        init();
        insert newAcc;
        Test.startTest();
        Account refreshedAccount = [Select id, Sync_To_Siebel__c from account where id = :newAcc.id];
        System.assertequals(refreshedAccount.Sync_To_Siebel__c,true);
        refreshedAccount.Sync_To_Siebel__c = false;
        refreshedAccount.Carrier__c = true;
        update refreshedAccount;
        refreshedAccount = [Select id, Sync_To_Siebel__c from account where id = :refreshedAccount.id];
        System.assertequals(refreshedAccount.Sync_To_Siebel__c,false);
        refreshedAccount.Name = 'Test Akam Acc - update '+utilTestClass.getRandomString(4);
        update refreshedAccount;
        refreshedAccount = [Select id, Sync_To_Siebel__c,Name from account where id = :refreshedAccount.id];
        System.debug('refreshedAccount: '+refreshedAccount);
        //System.assertequals(refreshedAccount.Sync_To_Siebel__c,true);
        Test.stopTest();        
    }
}