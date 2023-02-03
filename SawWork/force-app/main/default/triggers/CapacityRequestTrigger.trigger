trigger CapacityRequestTrigger on Capacity_Request__c (before insert,before update,after insert,after update,before delete,after delete,after undelete) {
  ApexTriggerHandlerAbstractClass.createHandler('Capacity_Request__c');
}