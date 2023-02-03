trigger OpportunityTriggerGeneric on Opportunity (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{


	//SFORCE-146, dissable the trigger while running batch job
	if(!CronCurrencyToUsdConversionBatchClass.dissableTriggerFlag)
          return;
	//rsharma - SFDC-2130
	//it is getting called when there was an event (insert, update or delete)
	//We don't want to call other logic of opportunity on that event, but should update akam fields.
	if(ByPassAndLimitUtils.isDisabled('OpportunityTriggerGeneric')){
		//set akam field
		if(Trigger.isBefore)
		 	ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,trigger.new);
		return;
	}
	ApexTriggerHandlerAbstractClass.createHandler('Opportunity');
    
}