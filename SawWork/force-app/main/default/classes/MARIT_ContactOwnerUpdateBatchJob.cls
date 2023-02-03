/* History:
* =========================
* @author  Himanshu Verma,  6th Dec 2021
*/
global class MARIT_ContactOwnerUpdateBatchJob implements Database.Batchable<sObject>, Database.Stateful {
    //global DMLResults results;
    global string query;
    global String successStr;
    global String errStr;
    global Id onaUserId;
    global List<Id> accIds;
    
    global MARIT_ContactOwnerUpdateBatchJob() 
    {
        onaUserId = GsmUtilClass.getGSMSettingValue('ONA_User_Id');
        /** 
         There are three ids: WWW lead Gen, WWW bad data and Unknown Accounts:Bad Data 2020
         Now this third type - Unknown Accounts:Bad Data will be added each year and 
         we need to make changes to this ContactOwnerAccountIds every year a new unknown account for that year is added
        */
        accIds = MarketingUtilClass.getMarketingSettingsValue('ContactOwnerAccountIds').split(',');
        
        Integer batchSize = MarketingUtilClass.getInt('ContactOwnerUpdateBatchSize');
        query = 'Select id, Owner.Name, Owner.IsActive,Account.Id, Account.Owner.Name, Account.Owner.IsActive, Account.OwnerId from Contact'; 
        if (!Test.isRunningTest()) {
            query+=' WHERE Owner.isActive = false';
            query+=' Order by LastModifiedDate asc limit '+ batchSize;
        } else {
            query+=' limit 1';
        }
        
        System.debug(LoggingLevel.INFO,'query Contact update : ' + query);
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Contact> contactList) {
        List<Contact> contactUpdatedList =  new List<Contact>();
        for(Contact con : contactList) {
            if (!con.Account.Owner.Isactive || accIds.contains(con.Account.Id) ) {
                con.OwnerId = onaUserId;
            } else {
                con.OwnerId = con.Account.OwnerId;
            }
            contactUpdatedList.add(con);
        }
        if (!contactUpdatedList.isEmpty()) {
            List<Contact> conFinalList = new List<Contact>();
            conFinalList.addAll(contactUpdatedList);
            Database.SaveResult[] srList = Database.update(conFinalList, false);
            
            //update c2aLeadList;
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(LoggingLevel.INFO,'Successfully updated Contact ID: ' + sr.getId());
                    successStr +=  sr.getId();
                }
                else {
                    // Operation failed, so get all errors  
                    errStr += sr.getId();
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,'The following error has occurred.');                    
                        System.debug(LoggingLevel.ERROR,err.getStatusCode() + ': ' + err.getMessage());
                        System.debug(LoggingLevel.INFO,'Contact fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        
    }
    
    global void finish(Database.BatchableContext bc) {
    }
}