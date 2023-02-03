trigger DraftInvoiceTrigger on Draft_Invoice__c (after delete, after insert, after update, before delete, before insert, before update) 
{
    TriggerFactory.createHandler(Draft_Invoice__c.sObjectType);
}