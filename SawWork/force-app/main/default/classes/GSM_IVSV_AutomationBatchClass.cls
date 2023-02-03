/*
    Author : Saket More
    Ticket : SFDC-7358
*/
global class GSM_IVSV_AutomationBatchClass implements Database.Batchable<Sobject>, Database.Stateful{

    global final string query;
    global DMLResults results;
    
    global GSM_IVSV_AutomationBatchClass()
    {
        query = 'select Id, Name, vertical__c, sub_vertical__c, Industry__c from account where IVSV_Automation__c = True and vertical__c NOT IN (\'\',\'Not Defined\') and vertical__c != null '; //Put vertical check
    }

    global Database.QueryLocator start(Database.BatchableContext bc)
    { 
         results = new DMLResults();
         return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<sObject> scope){
        List<Account> accList = (List<Account>)scope;
        Set<String> verticalList = new Set<String>();

        Map<String, String> verticalSubVerticalIndustryMap = new Map<String, String>();

        for(Account acc : accList){
            verticalList.add(acc.vertical__c);
        }

        if(verticalList.size() > 0){
            verticalSubVerticalIndustryMap = L2Q_AccountTriggerClass.initializeIndustryVerticalSubVerticalMapping(new List<String>(verticalList));

            for(Account acc : accList){
                String key = (String.isNotBlank(acc.Vertical__c) ? acc.Vertical__c.trim() : acc.Vertical__c) + (String.isNotBlank(acc.Sub_Vertical__c) ? acc.Sub_Vertical__c.trim() : acc.Sub_Vertical__c); 
                if(acc.Industry__c != verticalSubVerticalIndustryMap.get(key)){
                    acc.Industry__c = verticalSubVerticalIndustryMap.get(key);
                }
                acc.IVSV_Automation__c = false;
            }

            if(accList.size() > 0){
                results.add(Database.update(accList,false),accList);
            }
        }

    }

    global void finish(Database.BatchableContext bc){
        
        results.withJobName('\'IVSV automation batch class\'').toAddress(GsmUtilClass.getGSMSettingValue('PreSalesValueBatchClass_EmailId')).sendLogMail();
        results.withClassName('GSM_IVSV_AutomationBatchClass').insertRecordsInErrorLog();
    
    }
}