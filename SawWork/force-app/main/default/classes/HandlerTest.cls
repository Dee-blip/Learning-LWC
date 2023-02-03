@isTest
private with sharing class HandlerTest {

    @isTest
    private static void createHandler() {
        Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
        String profileName = 'Sales - Media';
        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        String alias = 'TST_OUSR';
        User testUser = utilTestClass.CreateUser(alias, roleName, profileName);
        
        // Add user
        insert testUser;
        
        // Test Result
        List<User> userList = [SELECT alias FROM User WHERE Id = :testUser.Id];
        System.assertEquals(userList.size(), 1);
        
        User userAdded = userList.get(0);
        System.assert(alias.equalsIgnoreCase(userAdded.Alias));
        
        // Update user
        alias = 'NewAlias';
        userAdded.Alias = alias;
        update userAdded;
        
        // Test Result
        userList = [SELECT alias FROM User WHERE Id = :testUser.Id];
        System.assertEquals(userList.size(), 1);
        
        userAdded = userList.get(0);
        System.assert(alias.equalsIgnoreCase(userAdded.Alias));
        
        // Delete User not allowed
        /*
        delete testUser;
        
        // Test Result
        userList = [SELECT alias FROM User WHERE Id = :testUser.Id];
        System.assertEquals(userList.size(), 0);
        */
    }
    

}