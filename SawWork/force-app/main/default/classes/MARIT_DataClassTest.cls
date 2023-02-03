@isTest(seeAllData = false)
private class MARIT_DataClassTest {
    
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static integer numberOfTestLeads= 4; 

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(dmlUser)
        {
            List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .put(Account.Type, 'Lead')
                .count(numberOfTestLeads)
                .create()
                .getRecords();
        }
    }
    
    static testmethod void queryDatausingCache() 
    {
        String query = 'Select id, name, vertical__c from Account';
        MARIT_DataClass.getTransactionalData(query, true, 'MARIT_DataClassTest.queryDatausingCache');
        MARIT_DataClass.getNonTransactionalData(query, 'TestAccounts', true, 'MARIT_DataClassTest.queryDatausingCache');
        MARIT_DataClass.clearCache(query, 'TestAccounts', 'MARIT_DataClassTest.queryDatausingCache');
    }

}