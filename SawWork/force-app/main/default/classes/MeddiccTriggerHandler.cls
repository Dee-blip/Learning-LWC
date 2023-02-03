public without sharing class MeddiccTriggerHandler extends ApexTriggerHandlerAbstractClass {
    public override void beforeInsertBeforeUpdateTrigger(){
        List<MEDDICC__c> meddiccTriggerNew = (List<MEDDICC__c>)newList;
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, meddiccTriggerNew);
    }
    public override void afterInsertAfterUpdateTrigger(){
        List<MEDDICC__c> meddiccTriggerNew = (List<MEDDICC__c>)newList;
        Map<Id,MEDDICC__c> meddiccTriggerOldMap = (Map<Id,MEDDICC__c>)oldMap;
        Set<Id> opportunityIds = new Set<Id>();
        Set<String> sections = new Set<String>();
        
        for(MEDDICC__c newMeddicc : meddiccTriggerNew){
            MEDDICC__c oldMeddicc = null;
            if(Trigger.isUpdate)
                oldMeddicc = meddiccTriggerOldMap.get(newMeddicc.Id);
            //catch response updates
            if(Trigger.isUpdate && Util.hasChanges('Response__c', oldMeddicc, newMeddicc)){
                opportunityIds.add(newMeddicc.Opportunity__c);
                sections.add(newMeddicc.Section__c);
            }
        }
        
        if(opportunityIds.size()>0){
            MeddiccTriggerClass.calculateSectionCompletion(opportunityIds,sections);
        }
    }
    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }
    public override void afterDeleteAfterUndeleteTrigger(){
        
    }
}