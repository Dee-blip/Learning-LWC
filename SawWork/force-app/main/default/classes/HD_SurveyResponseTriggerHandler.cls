/*
*
* Object: HD_Survey_Response__c
* Details : Custom trigger handler which implements CPQ_ITriggerHandler.
*      Used to call the helper methods in appropriate trigger context method.
*      Allows unit tests (or other code) to disable this trigger for the transaction.
*      If you want to stop this trigger from firing in a unit test, add the following code to the test: HD_SurveyResponseTriggerHandler.TriggerDisabled = true
* 
* Developer      Date      Version    Update 
* kimishra      06/13/2020    1.0      Initial version
* shegade       03/16/2021    2.0      Method names updated to follow the PMD guidelines
*
*
*/
public class HD_SurveyResponseTriggerHandler implements CPQ_ITriggerHandler {   
    /*
        Checks to see if the trigger has been disabled either by custom setting or by running code
    */
    public Boolean isDisabled()
    {
        return CPQ_Trigger_Settings__c.getInstance().HD_Survey_Response_Disabled__c;
    }
 
    public void beforeInsert(List<SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Trigger Before Insert Method');
    }
 
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Trigger Before Update Method');
    }
 
    public void beforeDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Trigger Before Delete Method');
    }
 
    public void afterInsert(Map<Id, SObject> newItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Trigger After Insert Method');
        HD_SurveyResponseTriggerHelper.sendCustomNotification(newItems);
    }
 
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Trigger After Update Method');
    }
 
    public void afterDelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Trigger After Delete Method');
    }
 
    public void afterUndelete(Map<Id, SObject> oldItems) {
        System.debug(System.LoggingLevel.INFO, '==>Inside Trigger After Undelete Method');
    }
}