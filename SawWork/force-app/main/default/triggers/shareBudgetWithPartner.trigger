/*
* Rohit, 03132010 - refactored Code
*/

trigger shareBudgetWithPartner on SFDC_Budget__c (after insert, after update) {
    //PRMTriggerClass.FBShareBudgetWithPartnerTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);

    //map - FBId => PartnerId
    Map<Id, Id> sObject_partner_map = new Map<Id, Id>();
    //map - FBId => Old PartnerId
    Map<Id, Id> sObject_oldPartner_map = new Map<Id, Id>();

    
    for (SFDC_Budget__c budget : trigger.new) {

        Boolean partnerChanged = trigger.isUpdate && Util.hasChanges('Account__c', 
            trigger.oldMap.get(budget.Id), budget);
        if (partnerChanged) { 
            sObject_oldPartner_map.put(budget.Id, trigger.oldMap.get(budget.Id).Account__c);
        }
        if (trigger.isInsert || partnerChanged) {
            sObject_partner_map.put(budget.Id, budget.Account__c);
        }
    
    }
    
    if (! sObject_oldPartner_map.isEmpty()) {
        FundBudgetShares.removeFundBudgetShare(sObject_oldPartner_map);
    }

    if (! sObject_partner_map.isEmpty()) {
        FundBudgetShares.createFBShare(sObject_partner_map);
    }
   
}