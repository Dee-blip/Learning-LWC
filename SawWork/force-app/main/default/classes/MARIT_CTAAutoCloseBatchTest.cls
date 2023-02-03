/* History:
* =========================
* @author  Himanshu Verma,  27th October 2020 
*/
@isTest(seeAllData=false)
public class MARIT_CTAAutoCloseBatchTest 
{
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        System.runAs(dmlUser) 
        {
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            Test.loadData(globalDescribe.get('LunaControlCenterSettings__c'), 'CS_LunaControlCenterSettings');
            /* End Of Custom Setting Insertion */
            
            Account testAccount = utilTestClass.CreateAccount('Test Account2');
            insert testAccount;
            
            Contact testContact = utilTestClass.CreateContact('Test','Contact2');
            testContact.AccountId = testAccount.Id;
            insert testContact;
        }
    }
    
    public static testmethod void CTA_OldLastModifiedDate_AutoCloseOnBatchrun() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Contact testContact = [Select Id from Contact where FirstName = 'Test' and LastName = 'Contact2'];
        Datetime oldDate = Datetime.now().addDays(-22);
        Datetime oldLastModifiedDate = Datetime.now().addDays(-22);
        Id akamaiRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Contact__c = testContact.Id;
        testLead.recordTypeId = akamaiRecordTypeId;
        testLead.email = 'testmlcm2@akamai.com';
        testLead.status = 'New';
        testLead.CurrencyIsoCode = 'USD';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Test';
        testLead.lastname = 'Lead2';
        testLead.website = 'testwebsite.com';
        testLead.industry = 'Banking';
        testLead.street = 'Test street';
        testLead.city = 'Test City';
        testLead.state = 'Test state';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        testLead.description = 'Test Description';
        insert testLead;
        System.debug('Test Lead insrterd : ' + testLead);
        
        Test.startTest();
        MARIT_CTAAutoCloseBatch autoCloseBatch = new MARIT_CTAAutoCloseBatch();
        Database.executeBatch(autoCloseBatch,200);
        Test.stopTest();
        Lead resLead = [Select Id, Lead_Qualification_Status__c from Lead where Id =:testLead.Id];
        System.assertEquals('Turnback Auto Close for Nurture', resLead.Lead_Qualification_Status__c, 'Lead Qual status should be turnback');
    }
}