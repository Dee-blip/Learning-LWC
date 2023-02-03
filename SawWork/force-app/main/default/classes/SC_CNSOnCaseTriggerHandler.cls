/*******************************************************************************************************
Author       :   jrathod
Created Date :   Dec 29, 2021
JIRA         :   ESESP-5526
Description  :   Created this trigger handler to validate duplicate record creation
********************************************************************************************************
Jay         29-Dec-2021     ESESP-5526      Initial version
*/

public without sharing class SC_CNSOnCaseTriggerHandler extends SC_TriggerHandlerAbstract{

    public override void handleBeforeInsert() {
        performDuplicateCheck(Trigger.new);
    }

    public override void handleBeforeUpdate() {
        performDuplicateCheck(Trigger.new);
    }

    public static void performDuplicateCheck(List<SC_CNSOnCase__c> records){
        List<Id> caseIds = new List<Id>();
        List<Id> userIds = new List<Id>();
        Map<String,SC_CNSOnCase__c> keys = new Map<String, SC_CNSOnCase__c>();
        for (SC_CNSOnCase__c rec : records){
            caseIds.add(rec.Case__c);
            userIds.add(rec.User__c);
            keys.put(rec.Case__c+''+rec.User__c,rec);
        }
        for(SC_CNSOnCase__c rec : [SELECT Id,Case__c,User__c,User__r.Name FROM SC_CNSOnCase__c WHERE Case__c IN :caseIds AND User__c IN :userIds]){
            String key = rec.Case__c+''+rec.User__c;
            if (keys.containsKey(key)) {
                keys.get(key).addError('Subscription already exists for user '+rec.User__r.Name);
            }
        }
    }
}