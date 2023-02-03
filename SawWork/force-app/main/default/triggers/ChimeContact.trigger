trigger ChimeContact on CHIME_Contact__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(ByPassAndLimitUtils.isDisabled('ChimeContact'))
    {
        return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('CHIME_Contact__c');
}