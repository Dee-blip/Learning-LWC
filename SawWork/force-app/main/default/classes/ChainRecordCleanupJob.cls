/**
 * @Class Name : ChainRecordCleanupJob
 * @Created By : Aayushi Agrawal 
 * @Created Date : 11 March - 2021
 * @purpose - SFORCE-56 (This class will be used to chain all the available jobs for execution from Bulk_Record_Deletion__mdt)
 */
public class ChainRecordCleanupJob implements Queueable {
    /**
     * This is the main execute method which will chain all the available jobs for execution.
     */
    public void execute(QueueableContext context) {
           
           QueueableJobChain chain = new QueueableJobChain();
           //chain all the available objects in custom metadata
           for(Bulk_Record_Deletion__mdt bulkRecordDeletion : [SELECT MasterLabel,Created_Before_N_days__c,Record_Limit_Per_Job__c FROM Bulk_Record_Deletion__mdt]){
                chain.chainFirst(new RecordCleanupJob(chain, bulkRecordDeletion));      
           }//end of for
           
           chain.runNext();  
    }//end of method execute
}// end of class ChainRecordCleanupJob