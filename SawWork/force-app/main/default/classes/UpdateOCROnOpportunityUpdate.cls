/* History:
 * =========================
 * @author  Ujjawal Somani, 3rd April 2020, MARIT-421
 * This Batch Job is to Update OCR's Updated_Date_For_CDP__c field so that latest updated OCRs are pulled in by CDP System. 
 * This is done because Opportunity Formula fields used in OCR are not getting reflected in CDP unless OCR are updated. 
 * Fact: Formula fields reflects the changes on other Object records without actually showing fields as updated/modified.
 */
global class UpdateOCROnOpportunityUpdate implements Database.Batchable<sObject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
    global Datetime currentTime = System.now();
    global Datetime currentTimeMinusSomeTime = currentTime.addHours(MarketingUtilClass.getInt('HourSizeRelatedToFormulaUpdateCDP'));
    global DateTime lastUpdateTime;
    global List<Id> getOpptyList = new List<Id>();
    global Id cdp_config_Id;
    global DateTime Last_Update_DateTime;
    global Boolean ocrupdated = false;

    global UpdateOCROnOpportunityUpdate()
    {
        CDP_Config__c[] cdp_config_record = [Select Id, Last_Update_DateTime__c from CDP_Config__c where Name = 'UpdatedTimeForOCR_OpportunityFormula' limit 1];
        lastUpdateTime = cdp_config_record[0].Last_Update_DateTime__c;
        cdp_config_Id = cdp_config_record[0].Id;

        Integer soqlLimit = MarketingUtilClass.getInt('SOQLLimitSizeForFormulaFieldsForCDP');
        for(Opportunity eachOpportunity : [Select Id, Updated_Date_For_CDP__c from Opportunity where SystemModStamp >:lastUpdateTime and Updated_Date_For_CDP__c >:lastUpdateTime and lastmodifieddate >:lastUpdateTime order by Updated_Date_For_CDP__c limit :soqlLimit]){
            getOpptyList.add(eachOpportunity.Id);
            Last_Update_DateTime = eachOpportunity.Updated_Date_For_CDP__c;
        }
        query = 'Select Id, Updated_Date_For_CDP__c from OpportunityContactRole where OpportunityId in :getOpptyList and SystemModStamp <:currentTimeMinusSomeTime and LastModifiedDate <:currentTimeMinusSomeTime';
    }

    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        results= new DMLResults(); 
        results.storeObjectState();
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        try{
            List<OpportunityContactRole> getOCRs = (List<OpportunityContactRole>)scope;
            List<OpportunityContactRole> UpdateOCRList = new List<OpportunityContactRole>();
            
            for (OpportunityContactRole ithOCR: getOCRs) {
                ithOCR.Updated_Date_For_CDP__c = currentTime;
                UpdateOCRList.add(ithOCR);
            }
            if(UpdateOCRList.size() > 0) {
                results.add(Database.update(UpdateOCRList,false),UpdateOCRList);
            }
            ocrupdated = true;
        }catch(Exception e){
            ocrupdated = false;
            System.debug('Error occurred while running UpdateOCROnOpportunityUpdate. Message: '+ e.getMessage());
            Error_Log__c errtoSave = new Error_Log__c(Name='UpdateOCROnOpportunityUpdate', Class__c='UpdateOCROnOpportunityUpdate', Error_Message__c=e.getMessage());
            Database.insert(errtoSave, false);
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        if(ocrupdated){
            Last_Update_DateTime = (Last_Update_DateTime == null) ? currentTime : Last_Update_DateTime;
            CDP_Config__c cdp_config_record = new CDP_Config__c(Id = cdp_config_Id, Name = 'UpdatedTimeForOCR_OpportunityFormula', Last_Update_DateTime__c = Last_Update_DateTime);
            Database.upsert(cdp_config_record);
            results.withClassName('UpdateOCROnOpportunityUpdate').insertRecordsInErrorLog();   
        }
    }
}