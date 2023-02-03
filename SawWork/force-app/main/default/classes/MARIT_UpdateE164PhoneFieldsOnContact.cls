//created as part of MARIT-1592 to update E164 phone field values for contact
//This code will pick the exisiting contacts in the system and will format the phone field to E.164 format 
//E164_Phone__c, Phone_Extension__c,E164_MobilePhone__c,MobilePhone_Extension__c,Phone_Formatting_error__c will be updated

global class MARIT_UpdateE164PhoneFieldsOnContact implements Database.Batchable<sObject>, Database.Stateful {
    global String successStr;
    global String errStr;
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String queryClause = '';
        if(datetime.now().format('E') == 'Sat') {
            queryClause = MarketingUtilClass.getMarketingSettingsValue('MARIT_E164PhoneFieldUpdateContactWeekend');
        } else {
            queryClause = MarketingUtilClass.getMarketingSettingsValue('MARIT_E164PhoneFieldUpdateContactWeekday');
        }    
        System.debug(logginglevel.DEBUG,datetime.now().format('E'));
        System.debug(logginglevel.DEBUG,'MARIT_UpdateE164PhoneFieldsOnContact batch job starts '+ DateTime.now());
        String query;
        query ='Select id, Phone, MobilePhone, MailingCountry  from Contact '+ queryClause; 
        System.debug(logginglevel.DEBUG,'e164 query: '+ query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc,List<Contact> scope) {
        MARIT_LeadContactUtils.e164PhoneNumberformatting(scope,'MailingCountry'); 
        Integer successCount = 0;
        Database.SaveResult[] srList = Database.update(scope, false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                System.debug(logginglevel.DEBUG,'Successfully updated Contact ID: ' + sr.getId());
                successStr +=  sr.getId();
                successCount += 1;
            }
            else {
                // Operation failed, so get all errors  
                errStr += sr.getId();
                for(Database.Error err : sr.getErrors()) {
                    System.debug(logginglevel.DEBUG,'The following error has occurred.');
                    System.debug(logginglevel.DEBUG,err.getStatusCode() + ': ' + err.getMessage());
                    System.debug(logginglevel.DEBUG,'Contact fields that affected this error: ' + err.getFields());
                }
            }
        }
        System.debug(logginglevel.DEBUG,'success batch records count for E.164 Update Phone Fields On Contact: '+ successCount);
    }
    global void finish(Database.BatchableContext bc) {
        System.debug(logginglevel.DEBUG,'MARIT_UpdateE164PhoneFieldsOnContact batch job ends '+ DateTime.now());
    }

}