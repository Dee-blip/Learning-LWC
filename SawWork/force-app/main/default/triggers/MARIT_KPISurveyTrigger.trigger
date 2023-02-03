trigger MARIT_KPISurveyTrigger on KPI_Survey__c (after delete, after insert, after undelete, 
                     after update, before delete, before insert, before update) {

  ApexTriggerHandlerAbstractClass.createHandler('KPI_Survey__c');

}