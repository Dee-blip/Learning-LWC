/* History:
* =========================
* @author  Himanshu Verma,  27th Dec 2021
*/
@isTest(seeAllData=false)
public class MARIT_ContactOwnerUpdateBatchTest 
{
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        System.runAs(dmlUser) 
        {
            Profile pr = [select id from profile where name='Marketing Operations'][0];  
            String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
            String orgId = UserInfo.getOrganizationId();
            String usrName = orgId + dateString + '@akamai.com';
            User marketingOpsUser = new User(alias = 'rsdnhca',
                                             email='rsdnhcaTest123@akamai.com',emailencodingkey='UTF-8', lastname='rsdnhca',
                                             languagelocalekey='en_US',localesidkey='en_US',
                                             timezonesidkey='America/Los_Angeles', isactive = true, Title = 'Marketing Director',
                                             username = usrName, profileid = pr.Id); 
            insert marketingOpsUser;
            
            Account testAccount = utilTestClass.CreateAccount('Test Account2');
            insert testAccount;
            
            Contact testContact = utilTestClass.CreateContact('Test','Contact2');
            testContact.AccountId = testAccount.Id;
            testContact.OwnerId = marketingOpsUser.Id;
            insert testContact;
        }
    }
    
    public static testmethod void contactOwnerUpdate_InactiveAccount() 
    {
        Account testAccount = [select Id, name, OwnerId from Account where Name = 'Test Account2'];
        
        Test.startTest();
        MARIT_ContactOwnerUpdateBatchJob contactOwnerUpdate = new MARIT_ContactOwnerUpdateBatchJob();
        Database.executeBatch(contactOwnerUpdate,200);
        Test.stopTest();
        Contact testContactupdated = [Select Id, OwnerId from Contact where FirstName = 'Test' and LastName = 'Contact2'];
        System.assertEquals(testAccount.OwnerId, testContactupdated.OwnerId, 'Owner Ids must match');
    }
}