trigger OrderApprovalTriggerFramework on Order_Approval__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(ByPassAndLimitUtils.isDisabled('OrderApprovalTriggerFramework')){
        //set akam field
        if(Trigger.isBefore)
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, Trigger.New);
        return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('OrderApproval');
}