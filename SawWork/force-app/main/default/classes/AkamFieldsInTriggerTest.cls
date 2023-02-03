/***
    AkamFieldsHandler
    @author : Ruchika Sharma <rsharma@akamai.com>
    @Description : This class is to test AkamFieldHandler class
   
    @History
    --Developer           --Date            --Change
    Ruchika Sharma          19/04/2015        Created the class to test contact and account akam fields
***/

@isTest(seeAllData = false)
private class AkamFieldsInTriggerTest {
     static
    {
        utilTestClass.insertCustomSettings();
    }
    static String akamAccountId;
    static Account newAcc;
    static User dmlUser = new User(id=UserInfo.getUserId());
    static User crmUser = new User(id=Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')));
    
    public static Account getAcc(Integer len){
            newAcc = utilTestClass.CreateAccount('Test Akam Acc '+utilTestClass.getRandomString(4));
            akamAccountId = 'F-AC-'+utilTestClass.getRandomString(len);
            System.debug('akamAccountId: '+akamAccountId+' and len: '+len);
            newAcc.AKAM_Account_ID__c = akamAccountId;
            newAcc.AKAM_System__c = 'MYAKAMAI';
            //insert newAcc;
            return newAcc;
    }

    public static Contact getConForAccount(Account conAcc){
            Contact newCon = utilTestClass.CreateContact('Test Akam', 'Test Contact');
            newCon.AccountId = conAcc.id;
            newCon.Associated_AKAM_Account_ID__c = akamAccountId;
            newCon.AKAM_System__c = 'MYAKAMAI';
            return newCon;
    }

    public static sObject getRefreshedObject(String sobjType, Id objId){
        String queryStr = 'Select id, AKAM_System__c, AKAM_Created_By__c,AKAM_Modified_By__c, AKAM_Modified_Date__c From '+sobjType+' where id = :objId';
        sObject refreshedObj = Database.query(queryStr);
        return refreshedObj;
    }
    public static testmethod void testContactAndAccount(){
        
        Contact newCon;
        Test.startTest();
        Account newAdminAcc = getAcc(6);
        newAdminAcc.website='www.akamfield.com';
        insert newAdminAcc;
        Contact newAdminCon = getConForAccount(newAdminAcc);
        insert newAdminCon;
        newAdminAcc = (Account) getRefreshedObject('Account', newAdminAcc.id);
        System.assertEquals(newAdminAcc.AKAM_System__c,'FORCE');


        newAdminCon = (Contact) getRefreshedObject('Contact', newAdminCon.id);
        System.assertEquals(newAdminCon.AKAM_System__c,'FORCE');

        System.runAs(crmUser){
            
            newAcc = getAcc(8);
            insert newAcc;
            newCon =  getConForAccount(newAcc);
            insert newCon;
            
        }
        Account refreshedAcc = new Account();
        refreshedAcc = (Account) getRefreshedObject('Account', newAcc.id);
        System.assertEquals(refreshedAcc.AKAM_System__c,'MYAKAMAI');

        Contact refreshedContact = new Contact();
        refreshedContact = (Contact) getRefreshedObject('Contact', newCon.id);
        System.assertEquals(refreshedContact.AKAM_System__c,'MYAKAMAI');    

        
        Test.stopTest();
    }
}