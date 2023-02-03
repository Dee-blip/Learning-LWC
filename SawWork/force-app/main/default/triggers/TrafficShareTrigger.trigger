trigger TrafficShareTrigger on Traffic_Share__c (before insert,before update,after insert) {
 
  ApexTriggerHandlerAbstractClass.createHandler('Traffic_Share');
   
}