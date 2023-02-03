/* History:
 * =========================
 * @author  Ujjawal Somani, 1st April 2020, MARIT-421
 * This Batch Job is to Update Marketo Lead's Updated_Date_For_CDP__c field so that latest updated leads are pulled in by CDP System. 
 * This is done because Account Formula fields used in Lead are not getting reflected in CDP unless Lead are updated. 
 * Fact: Formula fields reflects the changes on other Object records without actually showing fields as updated/modified.
 */
global class UpdateLeadOnAccountUpdate implements Database.Batchable<sObject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
    global Datetime currentTime = System.now();
    global Datetime currentTimeMinusSomeTime = currentTime.addHours(MarketingUtilClass.getInt('HourSizeRelatedToFormulaUpdateCDP'));
    global DateTime lastUpdateTime;
    global List<Id> getAcctList = new List<Id>();
    global Id cdp_config_Id;
    global DateTime Last_Update_DateTime;
    global Boolean leadupdated = false;

    global UpdateLeadOnAccountUpdate()
    {
        CDP_Config__c[] cdp_config_record = [Select Id, Last_Update_DateTime__c from CDP_Config__c where Name = 'UpdatedTimeForLead_AccountFormula' limit 1];
        lastUpdateTime = cdp_config_record[0].Last_Update_DateTime__c;
        cdp_config_Id = cdp_config_record[0].Id;

        List<String> akamAccIdsWithHugeLeads = new List<String>();
        if(MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException') != null){
            akamAccIdsWithHugeLeads = MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException').replaceAll(' ', '').split(',');
        }
        Integer soqlLimit = MarketingUtilClass.getInt('SOQLLimitSizeForFormulaFieldsForCDP');
        for(Account eachAccount : [Select Id, Updated_Date_For_CDP__c from Account where SystemModStamp>:lastUpdateTime and Updated_Date_For_CDP__c >:lastUpdateTime and AKAM_Account_ID__c not in :akamAccIdsWithHugeLeads order by Updated_Date_For_CDP__c limit :soqlLimit]){
            getAcctList.add(eachAccount.Id);
            Last_Update_DateTime = eachAccount.Updated_Date_For_CDP__c;
        }
        query = 'Select Id, Updated_Date_For_CDP__c from Lead where RecordType.Name=\'Marketo Lead\' and Associated_Account__r.Id in :getAcctList and SystemModStamp <:currentTimeMinusSomeTime and LastModifiedDate <:currentTimeMinusSomeTime';
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
            List<Lead> getLeads = (List<Lead>)scope;
            List<Lead> UpdateLeadList = new List<Lead>();

            for (Lead ithLead: getLeads) {
                ithLead.Updated_Date_For_CDP__c = currentTime;
                ithLead.Validation_Override__c = true;
                UpdateLeadList.add(ithLead);
            }
            if(UpdateLeadList.size() > 0) {
                results.add(Database.update(UpdateLeadList,false),UpdateLeadList);
            }
            leadupdated = true;
        }catch(Exception e){
            leadupdated = false;
            System.debug('Error occurred while running UpdateLeadOnAccountUpdate. Message: '+ e.getMessage());
            Error_Log__c errtoSave = new Error_Log__c(Name='UpdateLeadOnAccountUpdate', Class__c='UpdateLeadOnAccountUpdate', Error_Message__c=e.getMessage());
            Database.insert(errtoSave, false);
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        if(leadupdated){
            Last_Update_DateTime = (Last_Update_DateTime == null) ? currentTime : Last_Update_DateTime;
            CDP_Config__c cdp_config_record = new CDP_Config__c(Id = cdp_config_Id, Name = 'UpdatedTimeForLead_AccountFormula', Last_Update_DateTime__c = Last_Update_DateTime);
            Database.update(cdp_config_record);
            results.withClassName('UpdateLeadOnAccountUpdate').insertRecordsInErrorLog();            
        }
    }
}