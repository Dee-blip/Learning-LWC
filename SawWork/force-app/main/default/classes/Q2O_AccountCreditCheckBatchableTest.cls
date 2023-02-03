@isTest (seeAllData=true)
private class Q2O_AccountCreditCheckBatchableTest 
{  
public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();  
private static User getUserWithAccountReassignmentRule()
  {  
    ManagedPkgErrorClass.isFromManagedPackage = false;
    User accOwnerUser = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
    insert accOwnerUser;    
   
    Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, testcaseCustomSettings.get('User_Role').Value__c);
    insert rule;
  
    return accOwnerUser;    
  }

static testmethod void test()
{
 User accOwnerUser = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
 insert accOwnerUser;  
 System.runas(accOwnerUser)
 {
Account acc = utilTestClass.CreateAccount('__Test Account');
 acc.Owner = accOwnerUser;
 acc.Credit_Check_Date__c = Date.newInstance(2013,1,1); 
 acc.Credit_Check_Status__c  = 'SEC DEP';
 acc.Vertical__c = 'Business Services';

 insert acc;

 List<Opportunity> bulkOpportunityList = new List<Opportunity>();  
    for(Integer i=0;i<10;i++)
    {  
      Opportunity oppty = utilTestClass.CreateOpportunity('OpptySchTest__'+i,'1-Create');
      //oppty. = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
      oppty.AccountId = acc.Id;
      oppty.StageName = '3-Develop';
      oppty.CloseDate = Date.today().addDays(1); //Date.today();
      oppty.Deal_Type__c = 'Direct';
      oppty.Override_Forecast_Category_With__c = 'Commit';
      bulkOpportunityList.add(oppty);
    }
    insert bulkOpportunityList;  
    
    
    Cron_Batch_Job__c batchJob = new Cron_Batch_Job__c();
        batchJob.Name = 'CreditCheck:Testcase';
        batchJob.Batch_Job_Type__c = 'Task Creation for Credit Check';
        batchJob.RecordTypeId = Schema.SObjectType.Cron_Batch_Job__c.getRecordTypeInfosByName().get('Custom Job').getRecordTypeId();
        batchJob.Run_Every__c = 1;
        batchJob.Period__c = 'Day';
        batchJob.Scheduled_to_Run__c = DateTime.now();
        batchJob.Validation_Override__c = true;
        insert batchJob;
   

   Test.startTest();
          // Create the BatchRun record.
          Cron_Batch_Run__c batchRun = new Cron_Batch_Run__c();
          batchRun.Trigger_Batch_Run__c = true;
          batchRun.Cron_Batch_Job__c = batchJob.Id; 
          batchRun.Scheduled_to_Run__c =  DateTime.now();
          batchRun.Validation_Override__c = true;   
          insert batchRun;
          
          Integer batchRunsSize_After = [select Id from Cron_Batch_Run__c where Cron_Batch_Job__c = :batchJob.Id].size();
          system.assertNotEquals(batchRunsSize_After, 0);
       Test.stopTest();

List<Task> tlist = [Select Id from Task where Subject  = 'Credit Check Needed' and WhatId = :acc.Id];
  //system.assertEquals(tList.size(), 1);   
}
}
}