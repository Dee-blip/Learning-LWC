/**
 * Created by kusharma on 13/12/17.
 */

global class RAMDOZoneCountryProcessorBatch implements Database.Batchable<SObject>, System.Schedulable {

    global final String queryCompletedRecs;

    public RAMDOZoneCountryProcessorBatch() {
        queryCompletedRecs = 'SELECT Id, Name, Account_Country__c, Account__c, Manually_Managed_Account__c, Processing_Status__c, ' +
                'Sales_Primary_Country__c, Sales_Primary__c, Transaction_Id__c, Event_Type__c, ' +
                'Account__r.BillingCountry, Sales_Primary__r.Country ' +
                'FROM RAMD_Processor__c ' +
                'WHERE Manually_Managed_Account__c = false ' +
                'AND Processing_Status__c = \'Completed\' ';
    }

    global Database.QueryLocator start(Database.BatchableContext scope) {
        return Database.getQueryLocator(queryCompletedRecs);

    }

    global void execute(Database.BatchableContext bc, List<SObject> lScope) {
        List<RAMD_Processor__c> lRAMDRecsToProcessor = (List<RAMD_Processor__c>) lScope;
        RAMDProcessor instanceRamdProcessor = new RAMDProcessor();
        instanceRamdProcessor.processNewOZoneCountry(lRAMDRecsToProcessor);
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('$$$$ Batch Job Execution Fininsh');
        List<RAMD_Orange_Zone_Countries__c> lOZoneCountriesProcessed = new List<RAMD_Orange_Zone_Countries__c>();
        lOZoneCountriesProcessed = [
                SELECT Id, Country_Code__c, Country_Name__c,Processed__c
                FROM RAMD_Orange_Zone_Countries__c
                WHERE Processed__c = false
        ];
        for (RAMD_Orange_Zone_Countries__c varRAMDOrangeZoneCountries : lOZoneCountriesProcessed) {
            varRAMDOrangeZoneCountries.Processed__c = true;
        }

        if (!lOZoneCountriesProcessed.isEmpty()) {
            Database.update(lOZoneCountriesProcessed);
        }
    }

    global void execute(SchedulableContext sc) {

    }
}