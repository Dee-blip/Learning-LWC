@isTest(seeAllData=false)
private class AccountReassignmentRuleTriggerTestClass 
{
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            User newUser = utilTestClass.CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
            insert newUser;
        }
    }

    static testmethod void coverByPassLogic() {
        System.runAs(dmlUser) {
            ByPassAndLimitUtils.disable('AccountReassignmentRuleTrigger');

            User newUser = [Select Id, Alias from User where Alias = 'TST_USR' limit 1][0];

            Account_Reassignment_Rule__c newRule1 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', newUser.Id, 'Marketing Operations');
            insert newRule1; 
        }
    }   
    
    private static User RefreshUser(Id pUsrId)
    {
        return [select Id, User_Role_Name__c from User where Id=:pUsrId][0];
    }
    /**
      RefreshRule()
      - Refresh the Rule record with a SOQL
     */ 
    private static Account_Reassignment_Rule__c RefreshRule(Id pRuleId)
    {
        return [select Id, User_Role__c from Account_Reassignment_Rule__c where Id = :pRuleId][0];
    }
    /**
      RefreshRule()
      - Refresh the Rule record with a SOQL
     */ 
    private static Account_Reassignment_Rule__c[] RefreshRule(Account_Reassignment_Rule__c[] pRules)
    {
        return [select Id, User_Role__c from Account_Reassignment_Rule__c where Id IN :pRules];
    } 
   
    /**
      MultipleRules_PositiveTest()
      - When AccountReassignmentRule.User_Role__c is updated, change the User_Role on all other rules that have the same Associated_User.
     */
    public static testmethod void TwoRules_PositiveTest()
    {
        System.runAs(dmlUser)
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;

            // Feature is OFF
            if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UserRoleUpdateThroughAssignmentRule') == true) 
                return;
            User newUser = [Select Id, Alias from User where Alias = 'TST_USR' limit 1][0];
            Account_Reassignment_Rule__c newRule1 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', newUser.Id, 'Marketing Operations');
            insert newRule1;
            Account_Reassignment_Rule__c newRule2 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', newUser.Id, 'Worldwide');
            Test.startTest();
            insert newRule2;
            Test.stopTest();
            // Assert that the User Role of the first Rules was also changed to Business Operations     
            newRule1 = RefreshRule(newRule1.Id);
            system.assertEquals(newRule1.User_Role__c, 'Worldwide'); 
            delete newRule2;
        } 
    }
    /**
      MultipleRules_PositiveTest()
      - When AccountReassignmentRule.User_Role__c is updated, change the User_Role on all other rules that have the same Associated_User.
     */
    public static testmethod void BulkRules_PositiveTest()
    {
        System.runAs(dmlUser)
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            // Feature is OFF
            if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UserRoleUpdateThroughAssignmentRule') == true)
                return;   
            User newUser = [Select Id, Alias from User where Alias = 'TST_USR' limit 1][0];
            Account_Reassignment_Rule__c[] oldRules = new Account_Reassignment_Rule__c[20];
            for(Integer i=0;i<20;i++)
            {
                oldRules[i] = utilTestClass.CreateAccountReassignmentRule('___TEST RULE_'+i, newUser.Id, 'Marketing Operations');
            }
            insert oldRules;  
            Account_Reassignment_Rule__c newRule2 = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', newUser.Id, 'Worldwide');
            Test.startTest();
            AccountReassignmentRuleTriggerClass.updateRSMEmailsOnOrderApprovals(oldRules);
            insert newRule2;
            Test.stopTest();
            // Assert that the User Role of the first Rule was also changed to Business Operations      
            oldRules = RefreshRule(oldRules);
            for(Integer i=0;i<20;i++)   
                system.assertEquals(oldRules[i].User_Role__c, 'Worldwide');   
        }   
    }
    /**
      MultipleRules_PositiveTest()
      - When AccountReassignmentRule.User_Role__c is updated, change the User_Role on all other rules that have the same Associated_User.
     */
    public static testmethod void SingleRule_NegativeTest()
    {
        System.runAs(dmlUser)
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            // Feature is OFF
            if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UserRoleUpdateThroughAssignmentRule') == true)
                return;   
            User newUser = [Select Id, Alias from User where Alias = 'TST_USR' limit 1][0];
            Account_Reassignment_Rule__c newRule = utilTestClass.CreateAccountReassignmentRule('___TEST RULE', newUser.Id, 'Wrong Role');
            Boolean errorFlag = false; 
            Test.startTest();
            try
            {
                insert newRule;
            }
            catch(DmlException e)
            {
                errorFlag = true;
                // Assert that expected errors were thrown
                system.assert(e.getMessage().contains('Invalid User Role'));
            }
            Test.stopTest();
            // Assert that Error occured    
            system.assertEquals(errorFlag, true);
        }     
    }

    public static testmethod void UpdateGDRATTest()
    {
        
        system.runAs(dmlUser){
            User newUser = [Select Id, Alias, Name from User where Alias = 'TST_USR' limit 1][0];
            
            Territory_Mapping__c territoryMapping1 = utilTestClass.createTerritoryMapping('APJ Carrier & Channels - Carrier ANZ', 'APJ', 'APJ Adjust');
            Territory_Mapping__c territoryMapping2 = utilTestClass.createTerritoryMapping('APJ Adjust - Japan Channels', 'APJ', 'Korea Media');
            insert (new Territory_Mapping__c[] {territoryMapping1, territoryMapping2});
            
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule(newUser.Name, newUser.Id, 'Sales Operations');
            rule.Territory_ID__c = territoryMapping1.Id;
            insert rule;
            
            List<Account> accountList = new List<Account>();
            for(Integer i = 0; i<5; i++)
            {
                Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_'+i);
                acc.OwnerId = newUser.Id;
                acc.website='www.reasign.com';
                accountList.add(acc);
            }
            insert accountList;
            
            rule.Territory_ID__c = territoryMapping2.Id;
            rule.Changed_GDRAT__c = true;
            
            
            Test.startTest();
            update rule;
            Merged_Account__c mm = new Merged_Account__c();
            mm.name = 'TestAccount';
            insert mm;
            Test.stopTest();
            /*
            for(Account acc : [Select Parent_Division__c,Region__c,Division__c,Area__c from Account where Id IN : accountList])
            {
                System.assertEquals(acc.Parent_Division__c,'APJ_India');
                System.assertEquals(acc.Region__c,'DM INDIA');
                System.assertEquals(acc.Division__c,'India');
                System.assertEquals(acc.Area__c,'ECG INDIA');
            }
            */
        }
    }

}