/*
*
* Object: SBQQ__Quote__c
* Details : Custom trigger handler which implements CPQ_ITriggerHandler.
*			Used to call the helper methods in appropriate trigger context method.
*			Allows unit tests (or other code) to disable this trigger for the transaction.
*			If you want to stop this trigger from firing in a unit test, add the following code to the test: CPQ_QuoteTriggerHandler.TriggerDisabled = true
* 
* Developer			Date			Version		Update 
* kimishra			08/06/2019		1.0			Initial version
* hbarapat          10/12/2019      1.1         added the "CPQ_QuoteTriggerHelper.AppendPrimaryQuote(newItems)" in the execution handler
* kimishra			10/12/2019		1.1			validateCurrency method added
* shegade           09/09/2020      1.2         CPQ-318: AfterInsert: CPQ_QuoteTriggerHelper.updateOpportunityAutonomyStatus method added
* shegade           10/03/2021      2.0         Method names are updated to follow the PMD guidelines
*/
public class CPQ_QuoteTriggerHandler implements CPQ_ITriggerHandler {
    
    public static Boolean triggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean isDisabled()
    {
        if (CPQ_Trigger_Settings__c.getInstance().CPQ_Quote_Trigger_Disabled__c){
            return true; 
        }
        else{
            return triggerDisabled;
        }
    }
 
    public void beforeInsert(List<SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Trigger Before Insert Method');
        CPQ_QuoteTriggerHelper.updateLegalEntity(newItems);
        CPQ_QuoteTriggerHelper.updateCurrencyPricebook(newItems);
        //CPQ_QuoteTriggerHelper.updateRSM(newItems);
        //CPQ_QuoteTriggerHelper.checkPrimaryQuote(newItems); by Shashank Hegade this logic has been addressed in CPQ_QuoteTriggerHelper.AppendPrimaryQuote method
        CPQ_QuoteTriggerHelper.updateOrderApproval(newItems);
        CPQ_QuoteTriggerHelper.appendPrimaryQuote(newItems);//added to sync/check the primary Quote during insert
    }
 
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Trigger Before Update Method');
        CPQ_QuoteTriggerHelper.updateRSM(newItems.values());
        CPQ_QuoteTriggerHelper.updateOrderApproval(newItems.values());
        CPQ_QuoteTriggerHelper.appendPrimaryQuote(newItems.values());//added to sync/check the primary Quote during update
        CPQ_QuoteTriggerHelper.validateCurrency(newItems, oldItems);
    }
 
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Trigger Before Delete Method');
    }
 
    public void afterInsert(Map<Id, SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Trigger After Insert Method');
        CPQ_QuoteTriggerHelper.insertAMapproverRecord(newItems);
        CPQ_QuoteTriggerHelper.updateOpportunityAutonomyStatus(newItems, 'In-Progress'); //cpq-318
    }
 
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Trigger After Update Method');
        CPQ_QuoteTriggerHelper.insertAMapproverRecord(newItems);
    }
 
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Trigger After Delete Method');
    }
 
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Trigger After Undelete Method');
    }
}