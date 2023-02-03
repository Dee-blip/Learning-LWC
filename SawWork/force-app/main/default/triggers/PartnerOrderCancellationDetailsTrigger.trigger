/**
   @author: Nagaraj Desai
   SFDC-2587 : Formalize Partner Order Cancellation
 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj Desai    15/Apr/18        Added this class for SFDC-2587.
   =========================
   Related Test Class: PartnerOrderCancellationTriggerTestClass
 **/
 trigger PartnerOrderCancellationDetailsTrigger on Partner_Order_Cancellation_Details__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ApexTriggerHandlerAbstractClass.createHandler('Partner_Order_Cancellation_Details');
}