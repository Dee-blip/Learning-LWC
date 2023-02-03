/**
 * Object: SBQQ__QuoteDocument__c
 * Details : Custom trigger handler which implements CPQ_ITriggerHandler.
 *              Used to call the helper methods in appropriate trigger context method.
 *              Allows unit tests (or other code) to disable this trigger for the transaction.
 *              If you want to stop this trigger from firing in a unit test, add the following code to the test: CPQ_QuoteDocumentTriggerHandler.TriggerDisabled = true
 * Developer        Date            Version     Update
 * kimishra         03-MAR-2021     1.0         Initial version CPQ-501 for converting QuoteDocs to Files
 * 
 */
public class CPQ_QuoteDocumentTriggerHandler implements CPQ_ITriggerHandler {
    public static Boolean triggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean isDisabled()
    {
        if (CPQ_Trigger_Settings__c.getInstance().CPQ_Quote_Document_Trigger_Disabled__c){
            return true;
        }
        else{
            return triggerDisabled;
        }
    }
 
    public void beforeInsert(List<SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Document Trigger Before Insert Method');
    }
 
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Document Trigger Before Update Method');
    }
 
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Document Trigger Before Delete Method');
    }
 
    public void afterInsert(Map<Id, SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Document Trigger After Insert Method');
        CPQ_QuoteDocumentTriggerHelper.migrateAttachmentToContentDocument(newItems);

    }
 
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Document Trigger After Update Method');
    }
 
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Document Trigger After Delete Method');
    }
 
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Quote Document Trigger After Undelete Method');
    }
}