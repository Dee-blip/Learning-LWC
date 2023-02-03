/*
Author: Sonia Sawhney
Description: Contains test cases for BatchablePushCreatedRecordsToProd
Created Date : 20/03/2014
*/
@isTest
private class BatchablePushCreatedRecordsToProd_Test
{ 
    static {
        utilTestClass.createCustomSettings();
    }
    static List<Case> lstCases;
    static testMethod void testInsertedRecords() 
    {
      
      User cUser = new User(Id = Userinfo.getUserId());
      User usr = utilTestClass.CreateUser('test', 'System Administrator', 'System Administrator');
      usr.AKAM_User_ID__c = 'TEST_USER_ID';
      System.runas(cUser) {
          insert usr;
          Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
          environmentSetup.Active_Org__c = true;
          environmentSetup.Environment_Type__c = 'DR';
          update environmentSetup;
      }
      
      // Create 200 cases   
      ExternalSharingHelper.RunFromtestClass = true;
      lstCases = utilTestClass.createCases(200, false, usr.Id, '1');
      insert lstCases;  
      
      set<Id> caseIds = new set<Id>();
      
      for(Case cs: lstCases)
      {
          caseIds.add(cs.Id);
      }
      list<Partner_Connection__c> partnerRecords = [Select Id from Partner_Connection__c where LocalrecordId__c in :caseIds and Synced__c = false and Operation__c = 'Insert'];
      
      system.assertEquals(partnerRecords.size(), 200);
     
      Test.StartTest();
      BatchablePushCreatedRecordsToProd pushCreatedRecords = new BatchablePushCreatedRecordsToProd();
       
      ID batchprocessid = Database.executeBatch(pushCreatedRecords,200);
      Test.StopTest();
           
      partnerRecords = [Select Id from Partner_Connection__c where LocalrecordId__c in :caseIds and Synced__c = true and Operation__c = 'Insert'];
      
      system.assertEquals(partnerRecords.size(), 200);
   }
   
   static testMethod void testSubmitJob() 
   {
      string result = ConnectionHelper.SubmitSyncJob();
      System.assertEquals(result,'You can only run this job from DR org when it is active');
      
      User cUser = new User(Id = Userinfo.getUserId());
      System.runas(cUser)
      {
          Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
          environmentSetup.Active_Org__c = true;
          environmentSetup.Environment_Type__c = 'DR';
          update environmentSetup;
      }
      
      result = ConnectionHelper.SubmitSyncJob();
      System.assertEquals(result,'Job Submitted Successfully');
   }
   
}