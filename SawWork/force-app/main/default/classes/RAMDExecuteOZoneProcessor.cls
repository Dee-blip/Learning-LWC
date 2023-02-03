/**
 * Created by kusharma on 21/12/17.
 */

global class RAMDExecuteOZoneProcessor {
    private RAMD_Orange_Zone_Countries__c oZoneCountry;
    public RAMDExecuteOZoneProcessor(ApexPages.StandardController controller){
        oZoneCountry = (RAMD_Orange_Zone_Countries__c) controller.getRecord();
    }
    public PageReference executeOzoneBatch(){
        Database.executeBatch(new RAMDOZoneCountryProcessorBatch(), 300);
        return new PageReference('/'+oZoneCountry.Id);
    }

    webService static void executePendingRecBatch(){
        Database.executeBatch(new RAMDPendingRecordsProcessorBatch(), 300);
    }

    webService static void executeATMChangesBatch(){
        Database.executeBatch(new RAMDProcessATMChangesBatch(), 300);
    }
}