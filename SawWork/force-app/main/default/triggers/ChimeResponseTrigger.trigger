trigger ChimeResponseTrigger on CHIME_Response__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
	ApexTriggerHandlerAbstractClass.createHandler('CHIME_Response__c');
}