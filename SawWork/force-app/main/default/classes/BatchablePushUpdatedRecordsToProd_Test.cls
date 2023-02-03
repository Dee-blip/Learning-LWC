/*
Author: Sonia Sawhney
Description: Contains test cases for BatchablePushUpdatedRecordsToProd
Created Date : 21/03/2014
*/
@isTest
private class BatchablePushUpdatedRecordsToProd_Test
{ 
    static {
        utilTestClass.createCustomSettings();
    }
    
    static List<Case> lstCases;
    
    static testMethod void testUpdatedRecords() 
    {
      User cUser = new User(Id = Userinfo.getUserId());
      User usr = utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
      usr.AKAM_User_ID__c = 'TEST_USER_ID';
      
      System.runas(cUser) {
          insert usr;
      }
      
      // Create 200 cases   
      ExternalSharingHelper.RunFromtestClass = true;
      lstCases = utilTestClass.createCases(200, false, usr.Id, '1');
      insert lstCases;  
      
      System.runas(cUser) {
          Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
          environmentSetup.Active_Org__c = true;
          environmentSetup.Environment_Type__c = 'DR';
          update environmentSetup;
      }
           
      set<Id> caseIds = new set<Id>();
      
      for(Case cs: lstCases)
      {
          caseIds.add(cs.Id);
      }
      
      update lstCases;
      list<Partner_Connection__c> partnerRecords = [Select Id from Partner_Connection__c where LocalrecordId__c in :caseIds and Synced__c = false and Operation__c = 'Update'];
      
      system.assertEquals(partnerRecords.size(), 200);
     
      Test.StartTest();
      BatchablePushUpdatedRecordsToProd pushUpdatedRecords = new BatchablePushUpdatedRecordsToProd();
       
      ID batchprocessid = Database.executeBatch(pushUpdatedRecords,200);
      Test.StopTest();
           
      partnerRecords = [Select Id from Partner_Connection__c where LocalrecordId__c in :caseIds and Synced__c = true and Operation__c = 'Update'];
      
      system.assertEquals(partnerRecords.size(), 200);
   }
}