trigger CreateFundRequestShares on SFDC_MDF__c (after insert, after update) {
    PRMTriggerClass.FRCreateFundRequestSharesTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
}