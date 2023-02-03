trigger CPQ_QuoteTrigger on SBQQ__Quote__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    CPQ_TriggerDispatcher.run(new CPQ_QuoteTriggerHandler());
}