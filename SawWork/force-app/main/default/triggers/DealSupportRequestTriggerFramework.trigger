/* Created By: Vivek Baidya
 * Created Date: 18-May-2018
 * Description: Trigger on Deal_Support_Request__c.
**/
trigger DealSupportRequestTriggerFramework on Deal_Support_Request__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(ByPassAndLimitUtils.isDisabled('DSRTrigger'))
    {
        return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('Deal_Support_Request__c');
}