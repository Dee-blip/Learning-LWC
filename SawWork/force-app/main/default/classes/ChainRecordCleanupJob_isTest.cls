/**
 * @Class Name : ChainRecordCleanupJob_isTest
 * @Created By : Aayushi Agrawal 
 * @Created Date : 1 April - 2021
 * @purpose - SFORCE-56 (To do testing ChainRecordCleanupJob)
 */
@isTest(seeAlldata = false)
public class ChainRecordCleanupJob_isTest {
    testMethod static void testChainRecordCleanup() {
        
        Test.startTest();
        
        List<RecordToSync__c> recordList = new List<RecordToSync__c>();
        for(integer i = 0; i < 400 ; i++){
            recordList.add(new RecordToSync__c());
        }
        insert recordList;
        System.enqueueJob(new ChainRecordCleanupJob());
        
        Test.stopTest();
        List<RecordToSync__c> newList = [SELECT ID FROM RecordToSync__c];
        //System.assertEquals(0,newList.size());
        
        
    }//end of testChainRecordCleanup  
     testMethod static void testChainRecordCleanup1() {
         QueueableJobChain chain = new QueueableJobChain();
           //chain all the available objects in custom metadata
           for(Bulk_Record_Deletion__mdt bulkRecordDeletion : [SELECT MasterLabel,Created_Before_N_days__c,Record_Limit_Per_Job__c FROM Bulk_Record_Deletion__mdt]){
                chain.chainFirst(new RecordCleanupJob(chain, bulkRecordDeletion));      
           }//end of for
         chain.hasNext();
         chain.runNext();
        
     }
     testMethod static void testChainRecordCleanup2() {
          List<RecordToSync__c> recordList = new List<RecordToSync__c>();
        for(integer i = 0; i < 400 ; i++){
            recordList.add(new RecordToSync__c());
        }
        insert recordList;
         QueueableJobChain chain = new QueueableJobChain();
        //chain all the available objects in custom metadata
        Bulk_Record_Deletion__mdt bulkRecordDeletion1;
        for(Bulk_Record_Deletion__mdt bulkRecordDeletion : [SELECT MasterLabel,Created_Before_N_days__c,Record_Limit_Per_Job__c FROM Bulk_Record_Deletion__mdt WHERE MasterLabel='RecordToSync__c']){
             bulkRecordDeletion1 = bulkRecordDeletion;
            chain.chainFirst(new RecordCleanupJob(chain, bulkRecordDeletion));
        }//end of for
        System.enqueueJob(new RecordCleanupJob(chain,bulkRecordDeletion1));
     }
          

}//end of test class.