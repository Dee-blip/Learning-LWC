/*
Author: Sonia Sawhney
Description: Contains test cases for BatchableDeleteRecords 
Created Date : 13/08/2013 
Modification History:
Modified by ssawhney on 20/03/2014 to Remove the see all data from test class 
Modified by prathore on 20/12/2016 added method TestScheduleDeleteRecords() to cover ScheduleDeleteRecords class 
*/
@isTest
private class BatchableDeleteRecordsTest 
{ 
   
    static {
        utilTestClass.createCustomSettings();
    }
    
    static List <EB_NotificationType__c> templateTypes;
    static List<PartnerNetworkRecordConnection> connections;
    static testMethod void testRecordDeletion() 
    {
       LoadTestData();
       
       Test.StartTest();
       BatchableDeleteRecords  deleteRecords = new BatchableDeleteRecords();
       
       ID batchprocessid = Database.executeBatch(deleteRecords,200);
       Test.StopTest();
    
       System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM PartnerNetworkRecordConnection WHERE Id IN :connections'),
           200);  
           
       System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM EB_NotificationType__c WHERE Id IN :templateTypes'),
           200);  
       ExternalSharingHelper.DeletesObjects(connections);
       System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM EB_NotificationType__c WHERE Id IN :templateTypes'),
           0);
   }
   
   static private void LoadTestData()
   {
      // Create 200 test accounts - this simulates one execute.  
      templateTypes = new List<EB_NotificationType__c>();
      for(integer i = 0; i<200; i++){
          EB_NotificationType__c template = new EB_NotificationType__c(Name = 'Test Type' + i, Folder_Name__c = 'test folder'+i);
          templateTypes.add(template);
      }  
      insert templateTypes; 
 
      //Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
      Id networkId = ConnectionHelper.getConnectionId(); 
    
      connections =  new  List<PartnerNetworkRecordConnection>(); 
                
      for (EB_NotificationType__c type: templateTypes) {         
                PartnerNetworkRecordConnection newConnection = 
                  new PartnerNetworkRecordConnection( 
                      ConnectionId = networkId, 
                      LocalRecordId = type.Id, 
                      SendClosedTasks = false, 
                      SendOpenTasks = false, 
                      SendEmails = false );                     
                 connections.add(newConnection);                     
        } 
    
      if (connections.size() > 0 ) 
      { 
           database.insert(connections); 
      }
      
   }
    static testMethod void TestScheduleDeleteRecords()
    { 
        Test.StartTest();
      ScheduleDeleteRecords s = new ScheduleDeleteRecords();
    String sch = '20 30 8 10 2 ?';
    String jobID = system.schedule('TestScheduleDeleteRecords', sch, s);
        Test.StopTest();
    } 
}