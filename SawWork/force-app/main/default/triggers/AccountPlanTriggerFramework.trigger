/* Created By: Vivek Baidya
 * Created Date: 04-Sep-2019
 * Description: Trigger on Account_Plan__c.
**/
trigger AccountPlanTriggerFramework on Account_Plan__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    ApexTriggerHandlerAbstractClass.createHandler('Account_Plan__c');
}