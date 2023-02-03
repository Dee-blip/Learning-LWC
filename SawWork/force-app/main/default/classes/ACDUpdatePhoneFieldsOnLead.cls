//created by Priyanka Malhotra as part of MARIT-946 to update custom phone field values from oob phone fields for lead
//This code will pick the exisiting marketo leads in the system and will copy over the value of phone type fields to the new custom created fields like 
//Phone_Custom__c and MobilePhone_Custom__c

global class ACDUpdatePhoneFieldsOnLead implements Database.Batchable<sObject>, Database.Stateful {
    global String successStr;
    global String errStr;
    global Database.QueryLocator start(Database.BatchableContext bc){
        String whereClause = MarketingUtilClass.getMarketingSettingsValue('ACDUpdatePhoneFieldsOnLeadWhereClause');
        System.debug('ACDUpdatePhoneFieldsOnLead batch job starts '+ DateTime.now());
        String query;
        query ='Select id, Phone, Phone_Custom__c, MobilePhone, MobilePhone_Custom__c from Lead where '+ whereClause +' order by CreatedDate desc';
        System.debug('acd query: '+ query);
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc,List<Lead> scope){
        List<Lead> leadsToUpdate = new List<Lead>();
        Integer successCount = 0;
        Boolean runUpdateWhenTrue = false;
        for(Lead lead : scope){
            if(lead.Phone != lead.Phone_Custom__c){
                lead.Phone_Custom__c = lead.Phone;
                runUpdateWhenTrue = true;
            }
            if(lead.MobilePhone != lead.MobilePhone_Custom__c){
                lead.MobilePhone_Custom__c = lead.MobilePhone;
                runUpdateWhenTrue = true;
            }
            lead.Validation_Override__c = true;
            if(runUpdateWhenTrue)
            {
                leadsToUpdate.add(lead);
            }
        }
        if(leadsToUpdate.size() > 0){
            Database.SaveResult[] srList = Database.update(leadsToUpdate, false);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted Lead ID: ' + sr.getId());
                    successCount += 1;
                    successStr +=  sr.getId();
                }
                else {
                    // Operation failed, so get all errors  
                    errStr += sr.getId();
                    for(Database.Error err : sr.getErrors()) {
                        
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Lead fields that affected this error: ' + err.getFields());
                    }
                }
            }
        }
        System.debug('success batch records count for ACD Update Phone Fields On Lead: '+ successCount);
    }
    global void finish(Database.BatchableContext BC){   
        System.debug('ACDUpdatePhoneFieldsOnLead batch job ends '+ DateTime.now());
    }
    
}