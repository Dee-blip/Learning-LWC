trigger AccountReassignmentTrigger on Account_Reassignment__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    if(ByPassAndLimitUtils.isDisabled('AccountReassignmentTrigger')){
    	return;
    }
    ApexTriggerHandlerAbstractClass.createHandler('AccountReassignmentRequest');
}