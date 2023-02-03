trigger ChimeTrigger on CHIME__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    ApexTriggerHandlerAbstractClass.createHandler('CHIME__c');
    
    // IF LOE changed or Oppty Change on Chime, Update Case + Send Email
    if(Trigger.isUpdate && Trigger.isAfter){
    
        L2Q_PAC_Prod_FeatureTriggerController.actionOnChimeUpdate(Trigger.New, Trigger.OldMap);
    }

    // When Chime form's emergency status is changed , update Chime form review
    if(Trigger.isUpdate && Trigger.isBefore){
    
        L2Q_ChimeProductAssociationController.updateChimeLOEReviewStatusOnEmergency(Trigger.New, Trigger.OldMap);
    }
}