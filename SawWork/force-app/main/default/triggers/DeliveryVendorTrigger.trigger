trigger DeliveryVendorTrigger on Delivery_Vendor__c (before insert,after insert,before update,after update) {

   ApexTriggerHandlerAbstractClass.createHandler('Delivery_Vendor');
   
}