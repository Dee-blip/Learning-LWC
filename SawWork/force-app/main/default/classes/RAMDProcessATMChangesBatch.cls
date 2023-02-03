/**
 * Created by kusharma on 12/12/17.
 */

global class RAMDProcessATMChangesBatch implements Database.Batchable<SObject>, Database.Stateful, System.Schedulable {

    global final String queryActiveAccountRecs;
    List<String> lActiveAccountPicklistValues = new List<String>();

    public RAMDProcessATMChangesBatch() {
        Schema.DescribeFieldResult fieldResult = Account.Type.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry varPicklistEntry : picklistEntries) {
            if (!String.isEmpty(varPicklistEntry.getValue()) && varPicklistEntry.getValue().containsIgnoreCase('Active')
                    && !varPicklistEntry.getValue().containsIgnoreCase('Inactive')) {
                lActiveAccountPicklistValues.add(varPicklistEntry.getValue().trim());
            }
        }
        queryActiveAccountRecs = 'SELECT Id, BillingCountry ' +
                'FROM Account ' +
                'WHERE ' +
                'Type IN : lActiveAccountPicklistValues';
    }

    global Database.QueryLocator start(Database.BatchableContext scope) {
        return Database.getQueryLocator(queryActiveAccountRecs);

    }

    global void execute(Database.BatchableContext bc, List<SObject> lScope) {
        List<Account> lAccountsToProcess = (List<Account>) lScope;
        RAMDProcessor instanceRamdProcessor = new RAMDProcessor();
        instanceRamdProcessor.processATMChanges(lAccountsToProcess);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('$$$$ Batch Job Execution Finish RAMDProcessATMChangesBatch ');
    }

    global void execute(SchedulableContext sc) {
        System.debug('Job scheduled : RAMDProcessATMChangesBatch ');
        Database.executeBatch(new RAMDProcessATMChangesBatch(), 400);
    }

}