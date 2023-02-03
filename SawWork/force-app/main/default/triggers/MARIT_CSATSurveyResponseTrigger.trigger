trigger MARIT_CSATSurveyResponseTrigger on CSAT_Survey_Response__c (after delete, after insert, after undelete, 
							       after update, before delete, before insert, before update) {

	ApexTriggerHandlerAbstractClass.createHandler('CSAT_Survey_Response__c');

}