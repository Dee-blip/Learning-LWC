/*
Author: Sonia Sawhney
Description: Contains test cases for CleanUpOrgData
Created Date : 09/04/2014
*/
@isTest
private class CleanUpOrgData_Test
{ 
    static {
        utilTestClass.createCustomSettings();
    }
    
    static testMethod void testCleanUpJobPositive() 
    {
        User cUser = new User(Id = Userinfo.getUserId());
        User usr = utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
        usr.AKAM_User_ID__c = 'TEST_USER_ID';
        System.runas(cUser) {
              insert usr;
              Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
              environmentSetup.Environment_Type__c = 'DR';
              update environmentSetup;
        }
        System.runas(usr) {
              List<Account> lstAccounts;
              List<Contact> lstContacts;
              lstAccounts = new list<Account>();
              lstContacts = new List<Contact>();
              
              // Create 200 accounts
              for(integer i = 0;i>200;i++)
              {
                  Account acc = utilTestClass.CreateAccount('test account'+i);
                  lstAccounts.add(acc);
              }
              insert lstAccounts;  
              
              // Create 200 contacts
              for(integer i = 0;i>200;i++)
              {
                  Contact cnt = utilTestClass.CreateContact('test' , 'contact'+i);
                  cnt.AccountId = lstAccounts[i].Id;
                  lstContacts.add(cnt);
              }
              insert lstContacts;  
              
              set<Id> accountIds = new set<Id>();
              
              for(Account acc: lstAccounts)
              {
                  accountIds.add(acc.Id);
              }
              
              set<Id> cntIds = new set<Id>();
              
              for(Contact cnt: lstContacts)
              {
                  cntIds.add(cnt.Id);
              }
                   
              Test.StartTest();
              CleanUpOrgData cleanUp = new CleanUpOrgData('Account,Contact');
               
              ID batchprocessid = Database.executeBatch(cleanUp,200);
              Test.StopTest();
                   
              list<Account> lstAcc = [Select Id from Account where Id in :accountIds];
              list<Contact> lstCnt = [Select Id from Contact where Id in :cntIds];
              system.assertEquals(lstAcc.size(), 0);
              system.assertEquals(lstCnt.size(), 0);
           }
    }
    static testMethod void testCleanUpJobNegative() 
    {
        User cUser = new User(Id = Userinfo.getUserId());
        User usr = utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
        usr.AKAM_User_ID__c = 'TEST_USER_ID';
        System.runas(cUser) {
              insert usr;
              Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
              environmentSetup.Environment_Type__c = 'Primary';
              update environmentSetup;
        }
        System.runas(usr) {
                                
              Test.StartTest();
              try
              {
                  CleanUpOrgData cleanUp = new CleanUpOrgData('Account,Contact');
              }
              catch(Exception e)
              {
                  system.assert(e.getMessage() != null);
              }
           }
       }
}