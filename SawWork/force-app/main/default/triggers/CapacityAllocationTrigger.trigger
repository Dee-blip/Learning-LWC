trigger CapacityAllocationTrigger on Capacity_Allocation__c (before insert,before update,before delete ,after insert ,after update,after delete ,after undelete) {
    ApexTriggerHandlerAbstractClass.createHandler('Capacity_Allocation__c');
}