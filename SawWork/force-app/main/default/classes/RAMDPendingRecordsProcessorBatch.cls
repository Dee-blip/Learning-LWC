/**
 * Created by kusharma on 12/12/17.
 */

global class RAMDPendingRecordsProcessorBatch implements Database.Batchable<SObject>, Database.Stateful, System.Schedulable {

    global final String queryPendingRecs;

    public RAMDPendingRecordsProcessorBatch() {
        queryPendingRecs = 'SELECT Id, OwnerId, IsDeleted, Name, CreatedDate, CreatedById, LastModifiedDate, LastModifiedById,Processing_Status__c,' +
                'Account_Country__c,Account__c, Manually_Managed_Account__c,Sales_Primary_Country__c, Sales_Primary__c, Transaction_Id__c,' +
                'Event_Type__c, Account__r.BillingCountry, Sales_Primary__r.Country,' +
                'Processing_Reason__c, Sales_Primary_Country_Old__c,Sales_Primary_Name_Old__c,Account__r.Orange_Zone__c ' +
                'FROM RAMD_Processor__c ' +
                'WHERE Manually_Managed_Account__c = false ' +
                'AND Processing_Status__c = \'Pending\'';
    }

    global Database.QueryLocator start(Database.BatchableContext scope) {
        return Database.getQueryLocator(queryPendingRecs);

    }

    global void execute(Database.BatchableContext bc, List<SObject> lScope) {
        List<RAMD_Processor__c> lRAMDRecsToProcessor = (List<RAMD_Processor__c>) lScope;
        RAMDProcessor instanceRamdProcessor = new RAMDProcessor();
        instanceRamdProcessor.pendingRecProcessor(lRAMDRecsToProcessor);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('$$$$ Batch Job Execution Fininsh');
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new RAMDPendingRecordsProcessorBatch(), 400);

    }

}