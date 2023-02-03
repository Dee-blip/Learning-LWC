public without sharing class AccountReassignmentRuleTriggerHandler extends ApexTriggerHandlerAbstractClass {

	public override void beforeInsertBeforeUpdateTrigger(){
		List<Account_Reassignment_Rule__c> arrTriggerNew = (List<Account_Reassignment_Rule__c>)newList;
		ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, arrTriggerNew);
	}

	public override void afterInsertAfterUpdateTrigger(){
		List<Account_Reassignment_Rule__c> arrTriggerNew = (List<Account_Reassignment_Rule__c>)newList;
		Map<Id,Account_Reassignment_Rule__c> arrTriggerOldMap = (Map<Id,Account_Reassignment_Rule__c>)oldMap;

		AccountReassignmentRuleTriggerClass.TriggerCall(arrTriggerNew, arrTriggerOldMap);		
	}

	public override void beforeDeleteBeforeUndeleteTrigger(){

	}

	public override void afterDeleteAfterUndeleteTrigger(){

	}

}