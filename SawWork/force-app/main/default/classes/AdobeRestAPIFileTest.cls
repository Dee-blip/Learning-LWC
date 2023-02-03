@isTest(seeAllData = false)
public class AdobeRestAPIFileTest {
    
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 3; 
    
    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(dmlUser)
        {
            User accOwnerUser = utilTestClass.CreateUser('newUser', GsmUtilClass.getGSMSettingValue('User_Role'), 'Sales Operations');
            insert accOwnerUser;
            
            List<Account> accList = new List<Account>();
            
            Account acc1 = utilTestClass.CreateAccount('TestAcc1');
            acc1.Vertical__c = 'Gaming';
            acc1.Type = 'Lead'; // Geo
            acc1.Sub_Vertical__c = 'Gaming'; // Area
            acc1.OwnerId = accOwnerUser.Id;
            acc1.website = 'Akamai.com';
            accList.add(acc1);
            
            Account acc2 = utilTestClass.CreateAccount('TestAcc2');
            acc2.Vertical__c = 'Gaming';
            acc2.Type = 'Lead'; // Geo
            acc2.Sub_Vertical__c = 'Gaming'; // Area
            acc2.OwnerId = accOwnerUser.Id;
            acc2.website = 'Adobe.com';
            accList.add(acc2);
            
            Account acc3 = utilTestClass.CreateAccount('TestAcc3');
            acc3.Vertical__c = 'Gaming';
            acc3.Type = 'Lead'; // Geo
            acc3.Sub_Vertical__c = 'Gaming'; // Area
            acc3.OwnerId = accOwnerUser.Id;
            acc3.website = 'Cisco.com';
            accList.add(acc3);
            
            Account acc4 = utilTestClass.CreateAccount('TestAcc4');
            acc4.Vertical__c = 'Gaming';
            acc4.Type = 'Lead'; // Geo
            acc4.Sub_Vertical__c = 'Gaming'; // Area
            acc4.OwnerId = accOwnerUser.Id;
            acc4.website = 'Google.com';
            accList.add(acc4);
            
            insert accList;
        }
    }
    
    static testmethod void testAdobeRestAPI()
    {
        
        Test.startTest();
        String paramString = 'Akamai.com,Adobe.com,Cisco.com,Google.com';
        String str = AdobeRestAPIFile.fetchAccountDetails(paramString);
        
        Account googleAcc = [Select id, website, AKAM_Account_ID__c from Account where website = 'Google.com' limit 1];

        List<String> siteList = str.split(',');
        String akamId = null;
        for(String site: siteList){
            List<String> siteToId = site.split(':');
            String website = siteToId[0].remove('"');
            if(website.contains('Google.com')){
                akamId = siteToId[1].remove('"');
            }
        }
        if(akamId != googleAcc.AKAM_Account_ID__c){
            System.assert(FALSE, 'Adobe API not working as expected');
        }
        
        Test.stopTest();
    }

}