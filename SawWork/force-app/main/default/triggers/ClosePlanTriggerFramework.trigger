/* Created By: Vivek Baidya
 * Created Date: 29-Nov-2018
 * Description: Trigger on Close_Plan__c.
**/
trigger ClosePlanTriggerFramework on Close_Plan__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ApexTriggerHandlerAbstractClass.createHandler('Close_Plan__c');
}