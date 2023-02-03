trigger MeddiccTriggerFramework on MEDDICC__c (before insert, before update, after insert, after update, before delete, after delete, after undelete) {
    if(ByPassAndLimitUtils.isDisabled('MeddiccTriggerFramework')){
        if(Trigger.isBefore)
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,trigger.new);
        return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('MEDDICC__c');
}