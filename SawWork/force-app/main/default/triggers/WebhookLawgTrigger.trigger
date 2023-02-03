trigger WebhookLawgTrigger on WebhookLawg__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    ApexTriggerHandlerAbstractClass.createHandler('WebhookLawg');
}