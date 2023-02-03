trigger AccountStrategyTrigger on Account_Strategy__c (before insert,after insert, before update) {
    
   ApexTriggerHandlerAbstractClass.createHandler('Account_Strategy');
  
    }