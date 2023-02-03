/* History:
 * =========================
 * @author  Ujjawal Somani, 3rd April 2020, MARIT-421
 * This Batch Job is to Update Contact's Updated_Date_For_CDP__c field so that latest updated contacts are pulled in by CDP System. 
 * This is done because Account Formula fields used in Contact are not getting reflected in CDP unless Contact are updated. 
 * Fact: Formula fields reflects the changes on other Object records without actually showing fields as updated/modified.
 */
global class UpdateContactOnAccountUpdate implements Database.Batchable<sObject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
    global Datetime currentTime = System.now();
    global Datetime currentTimeMinusSomeTime = currentTime.addHours(MarketingUtilClass.getInt('HourSizeRelatedToFormulaUpdateCDP'));
    global DateTime lastUpdateTime;
    global List<Id> getAcctList = new List<Id>();
    global Id cdp_config_Id;
    global DateTime Last_Update_DateTime;
    global Boolean contactupdated = false;

    global UpdateContactOnAccountUpdate()
    {
        CDP_Config__c[] cdp_config_record = [Select Id, Last_Update_DateTime__c from CDP_Config__c where Name = 'UpdatedTimeForContact_AccountFormula' limit 1];
        lastUpdateTime = cdp_config_record[0].Last_Update_DateTime__c;
        cdp_config_Id = cdp_config_record[0].Id;

        List<String> akamAccIdsWithHugeContacts = new List<String>();
        if(MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException') != null){
            akamAccIdsWithHugeContacts = MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException').replaceAll(' ', '').split(',');
        }
        Integer soqlLimit = MarketingUtilClass.getInt('SOQLLimitSizeForFormulaFieldsForCDP');
        for(Account eachAccount : [Select Id, Updated_Date_For_CDP__c from Account where SystemModStamp>:lastUpdateTime and Updated_Date_For_CDP__c >:lastUpdateTime and AKAM_Account_ID__c not in :akamAccIdsWithHugeContacts order by Updated_Date_For_CDP__c limit :soqlLimit]){
            getAcctList.add(eachAccount.Id);
            Last_Update_DateTime = eachAccount.Updated_Date_For_CDP__c;
        }
        query = 'Select Id, Updated_Date_For_CDP__c from Contact where Account.Id in :getAcctList and SystemModStamp <:currentTimeMinusSomeTime and LastModifiedDate <:currentTimeMinusSomeTime';
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
            List<Contact> getContacts = (List<Contact>)scope;
            List<Contact> UpdateContactList = new List<Contact>();

            for (Contact ithContact: getContacts) {
                ithContact.Updated_Date_For_CDP__c = currentTime;
                ithContact.Validation_Override__c = true;
                UpdateContactList.add(ithContact);
            }
            if(UpdateContactList.size() > 0) {
                results.add(Database.update(UpdateContactList,false),UpdateContactList);
            }
            contactupdated = true;
        }catch(Exception e){
            contactupdated = false;
            System.debug('Error occurred while running UpdateContactOnAccountUpdate. Message: '+ e.getMessage());
            Error_Log__c errtoSave = new Error_Log__c(Name='UpdateContactOnAccountUpdate', Class__c='UpdateContactOnAccountUpdate', Error_Message__c=e.getMessage());
            Database.insert(errtoSave, false);
        }
    }

    global void finish(Database.BatchableContext BC)
    {
        if(contactupdated){
            Last_Update_DateTime = (Last_Update_DateTime == null) ? currentTime : Last_Update_DateTime;
            CDP_Config__c cdp_config_record = new CDP_Config__c(Id = cdp_config_Id, Name = 'UpdatedTimeForContact_AccountFormula', Last_Update_DateTime__c = Last_Update_DateTime);
            Database.upsert(cdp_config_record);
            results.withClassName('UpdateContactOnAccountUpdate').insertRecordsInErrorLog();
        }
    }
}