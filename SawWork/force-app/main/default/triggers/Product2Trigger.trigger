trigger Product2Trigger on Product2 (before insert,before update,after insert,after update,before delete,after delete,after undelete) {
  ApexTriggerHandlerAbstractClass.createHandler('Product2');
}