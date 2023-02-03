//created by Priyanka Malhotra as part of MARIT-946 to update custom phone field values from oob phone fields for contact
//This code will pick the exisiting contacts in the system and will copy over the value of phone type fields to the new custom created fields like 
//Phone_Custom__c and MobilePhone_Custom__c and Assistant_Phone_Custom__c

global class ACDUpdatePhoneFieldsOnContact implements Database.Batchable<sObject>, Database.Stateful {
    global String successStr;
    global String errStr;
    global Database.QueryLocator start(Database.BatchableContext bc){
        String whereClause = MarketingUtilClass.getMarketingSettingsValue('ACDUpdatePhoneFieldsOnContactWhereClause');
        System.debug('ACDUpdatePhoneFieldsOnContact batch job starts '+ DateTime.now());
        String query;
        query ='Select id, Phone, Phone_Custom__c, MobilePhone, MobilePhone_Custom__c, Assistant_Phone__c, Assistant_Phone_Custom__c from Contact where '+ whereClause +' order by CreatedDate desc'; 
        System.debug('acd query: '+ query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc,List<Contact> scope){
        List<Contact> contactsToUpdate = new List<Contact>();
        Integer successCount = 0;
        Boolean runUpdateWhenTrue = false;
        for(Contact con : scope){
            if(con.Phone != con.Phone_Custom__c){
                con.Phone_Custom__c = con.Phone;
                runUpdateWhenTrue = true;
            }
            if(con.MobilePhone != con.MobilePhone_Custom__c){
                con.MobilePhone_Custom__c = con.MobilePhone;
                runUpdateWhenTrue = true;
            }
            if(con.Assistant_Phone__c != con.Assistant_Phone_Custom__c){
                con.Assistant_Phone_Custom__c = con.Assistant_Phone__c;
                runUpdateWhenTrue = true;
            }
            con.Validation_Override__c = true;
            if(runUpdateWhenTrue){
                contactsToUpdate.add(con);
            }    
        }
        if(contactsToUpdate.size() > 0){
            
            Database.SaveResult[] srList = Database.update(contactsToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted Contact ID: ' + sr.getId());
                    successStr +=  sr.getId();
                    successCount += 1;
                }
                else {
                    // Operation failed, so get all errors  
                    errStr += sr.getId();
                    for(Database.Error err : sr.getErrors()) {
                        
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Contact fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        System.debug('success batch records count for ACD Update Phone Fields On Contact: '+ successCount);
    }
    global void finish(Database.BatchableContext BC){ 
        System.debug('ACDUpdatePhoneFieldsOnContact batch job ends '+ DateTime.now());  
    }
    
}