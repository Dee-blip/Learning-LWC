trigger CampaignTriggerFramework on Campaign (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(ByPassAndLimitUtils.isDisabled('CampaignTriggerFramework')){
        //set akam field
        if(Trigger.isBefore)
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, Trigger.New);
        return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('Campaign');
}