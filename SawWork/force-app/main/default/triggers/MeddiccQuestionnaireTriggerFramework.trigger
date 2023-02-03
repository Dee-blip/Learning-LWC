trigger MeddiccQuestionnaireTriggerFramework on MEDDICC_Questionnaire__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
	ApexTriggerHandlerAbstractClass.createHandler('MEDDICC_Questionnaire__c');
}