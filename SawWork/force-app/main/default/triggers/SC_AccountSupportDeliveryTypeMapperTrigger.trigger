/*
 * Vandhana Krishnamurthy 		18 Jun 2021  ESESP-5494 : Support Differentiation for AkaTec (Saturn)
 * Test Class : AccountTriggerTestClass
*/

trigger SC_AccountSupportDeliveryTypeMapperTrigger on Account_Support_Delivery_Type_Mapper__c (before insert, before update, after insert, after update) 
{
    if(Trigger.isAfter && Trigger.isUpdate)
    {
        // on updates to Support Delivery Mapper support level, update all impacted Accounts with corresponding Support Delivery Type
        SC_AccountSupportDeliveryTypeMappClass.updateAccountOnMapperChange(Trigger.newMap,Trigger.oldMap);
    }
}