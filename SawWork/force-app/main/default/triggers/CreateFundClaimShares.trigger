trigger CreateFundClaimShares on SFDC_MDF_Claim__c (after insert, after update) {
    PRMTriggerClass.FCCreateFundClaimSharesTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
}