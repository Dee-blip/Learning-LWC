trigger AkaNovaConceptTrigger on Concept__c  (after delete, after insert, after undelete, 
							       after update, before delete, before insert, before update) {

	ApexTriggerHandlerAbstractClass.createHandler('Concept__c');

}