public without sharing class MeddiccQuestionnaireTriggerHandler extends ApexTriggerHandlerAbstractClass {
    public override void beforeInsertBeforeUpdateTrigger(){
        List<MEDDICC_Questionnaire__c> meddiccQuestionnaireTriggerNew = (List<MEDDICC_Questionnaire__c>)newList;
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, meddiccQuestionnaireTriggerNew);
    }
    public override void afterInsertAfterUpdateTrigger(){
        
    }
    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }
    public override void afterDeleteAfterUndeleteTrigger(){
        
    }
}