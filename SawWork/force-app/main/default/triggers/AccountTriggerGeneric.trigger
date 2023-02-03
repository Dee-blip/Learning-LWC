//Added as part of SFDC-2851
trigger AccountTriggerGeneric on Account (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

	if(ByPassAndLimitUtils.isDisabled('AccountTriggerGeneric')){
        //set akam field
        if(Trigger.isBefore)
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, Trigger.New);
        return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('Account');
}