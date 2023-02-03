@isTest(seeAllData=false)
private class MARIT_AccountReassignmentTriggerTest {
    private static User dmlUser = new User(id=UserInfo.getUserId());
    
    @testSetup static void setupMethod(){
        MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
        settings.Name = 'LeadAsyncConversionFlagStatus';
        settings.Flag_Status__c = false;
        insert settings;
        //creating account reassignment rule
        Account_Reassignment_Rule__c rule1 = utilTestClass.CreateAccountReassignmentRule('OLD_FirstRule',dmlUser.Id,'2021_Carrier APJ');
        insert rule1;
        Account_Reassignment_Rule__c rule2 = utilTestClass.CreateAccountReassignmentRule('SecondRule',dmlUser.Id,'2021_Carrier APJ');
        insert rule2;
        
        //creating account
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        
    }
    
    static testMethod void testAccountReassignment(){
        Test.startTest();
        //fetching the account
        Account a = [Select Id,OwnerId from Account where Name = '__Test Account' limit 1];
        
        //assigning the first account reassignment rule  
        Account_Reassignment_Rule__c arr1 = [Select Id,Name from Account_Reassignment_Rule__c where Name = 'OLD_FirstRule' limit 1];
        a.adg_Projected_Account_Owner__c = arr1.Id;
        update a;
        
        Account a1 = [Select Id, adg_Projected_Account_Owner__c from Account where Name = '__Test Account' limit 1];
        //assigning the second account reassignment rule   
        Account_Reassignment_Rule__c arr2 = [Select Id,Name,OwnerId from Account_Reassignment_Rule__c where Name = 'SecondRule' limit 1];
        String reassignAccount1 = SF1_AccountReassignment.reassignAccount(String.valueOf(a1.Id),String.valueOf(arr2.Id),'Other','test again',false);
        reassignAccount1 = SF1_AccountReassignment.reassignAccount(String.valueOf(a1.Id),String.valueOf(arr2.Id),'Other','test again',true);
        List<DRA_Process__e> eventList = new List<DRA_Process__e>();
          DRA_Process__e evnt = new DRA_Process__e();
                    evnt.AccountID__c  = a1.id;
                    evnt.AccountReassignRuleId__c = arr2.Id;
                    eventList.add(evnt);
        EventBus.publish(eventList);
        Test.getEventBus().deliver();
        Test.stopTest();
       //todo system.assert statement
    }
}