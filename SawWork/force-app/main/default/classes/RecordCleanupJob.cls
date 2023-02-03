/**
 * @Class Name : RecordCleanupJob
 * @Created By : Aayushi Agrawal 
 * @Created Date : 11 March - 2021
 * @purpose - SFORCE-56 (This class will be used to execute delete functionality on objects passed from ChainRecordCleanupJob)
 */
public  class RecordCleanupJob extends ChainedQueueable {
    public Bulk_Record_Deletion__mdt bulkRecordDeletion ;
    
    /**
     * This is a constructor which gets called from ChainRecordCleanupJob 
     */
    public RecordCleanupJob(QueueableJobChain chain, Bulk_Record_Deletion__mdt bulkRecordDeletion) {
        
        super(chain);
        this.bulkRecordDeletion = bulkRecordDeletion;
    }//end of constructor : RecordCleanupJob
    /**
     * This method will execute all required functionality
     */
    public override void execute(QueueableContext context) {
        /*  execute  stuff here */
        List<sObject> recordsToDelete = new List<sObject>();
        Date dateToConsider = System.today().addDays(-(Integer.valueOf(bulkRecordDeletion.Created_Before_N_days__c)));
        String date1 = String.valueOf(dateToConsider)+'T00:00:01.00Z';
        integer limitRecord  = integer.valueOf(bulkRecordDeletion.Record_Limit_Per_Job__c);
        String dynamicQuery;
        if(test.isRunningTest()){
            dynamicQuery = 'SELECT ID FROM '+bulkRecordDeletion.MasterLabel+ ' LIMIT  '+limitRecord;
            
        }else{
            dynamicQuery = 'SELECT ID FROM '+bulkRecordDeletion.MasterLabel+ ' WHERE CREATEDDATE <'+date1+' LIMIT  '+limitRecord;
            
        }
        
        system.debug(dynamicQuery);
        recordsToDelete.addAll(Database.query(DynamicQuery));
        if(!recordsToDelete.isEmpty()){
            Database.delete(recordsToDelete);
            super.chainOneMoreInstance(new RecordCleanupJob(chain, bulkRecordDeletion)); // adding one more instance of job in case there are more records
        }
        
        super.execute(context); // runs the next queueable in the chain.
    }//end of execute method
}//end of RecordCleanupJob class