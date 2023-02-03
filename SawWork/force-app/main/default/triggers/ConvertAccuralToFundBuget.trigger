trigger ConvertAccuralToFundBuget on SFDC_Fund_Accural__c (after insert,after update) {
    PRMTriggerClass.FundAccrualTriggerMethod(Trigger.new,Trigger.oldMap,Trigger.newMap);
}