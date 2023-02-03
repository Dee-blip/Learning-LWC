/*
*
* Object: sbaa__Approval__c
* Details : Custom trigger handler which implements CPQ_ITriggerHandler.
*			Used to call the helper methods in appropriate trigger context method.
*			Allows unit tests (or other code) to disable this trigger for the transaction.
*			If you want to stop this trigger from firing in a unit test, add the following code to the test: CPQ_ApprovalTriggerHandler.TriggerDisabled = true
* 
* Developer			Date			Version		Update 
* kimishra			08/09/2019		1.0			Initial version
* shegade           10/03/2021      2.0         Method names are updated to follow PMD guidelines
* 
*/
public class CPQ_ApprovalTriggerHandler implements CPQ_ITriggerHandler {

    public static Boolean triggerDisabled = false;
 
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean isDisabled()
    {
        if (CPQ_Trigger_Settings__c.getInstance().CPQ_Approval_Trigger_Disabled__c ){
            return true;
        }
        else{
            return triggerDisabled;
        }
    }
 
    public void beforeInsert(List<SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Approval Trigger Before Insert Method.');
    }
 
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Approval Trigger Before Update Method.');
        CPQ_ApprovalTriggerHelper.reassignCustomFilter(newItems, oldItems);
    }
 
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Approval Trigger Before Delete Method.');
    }
 
    public void afterInsert(Map<Id, SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Approval Trigger After Insert Method.');
        CPQ_ApprovalTriggerHelper helperClass = CPQ_ApprovalTriggerHelper.getInstance(newItems);
        helperClass.createCustomProductApprovals();
        //CPQ_ApprovalTriggerHelper.createCustomProductApprovals(newItems);
        //method to check if all reqd product approvals status is approved then make AA prod approval record approved
        CPQ_ApprovalTriggerHelper.updatePAStepStatus(newItems);
    }
 
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Approval Trigger After Update Method.');
    }
 
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Approval Trigger After Delete Method.');
    }
 
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Approval Trigger After Undelete Method.');
    }
}