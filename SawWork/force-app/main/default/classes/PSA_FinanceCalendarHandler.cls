public with sharing class PSA_FinanceCalendarHandler  extends ApexTriggerHandlerAbstractClass 
{
	public PSA_FinanceCalendarHandler() 
	{
		
	}
    public override void beforeInsertBeforeUpdateTrigger()
    {
    }
 
    public override void afterInsertAfterUpdateTrigger()
    {
     	PSA_OverageController.resetSchedule(Trigger.isInsert,(Map <Id, Finance_Calendar__c>) oldMap,  newList);                      	
    }
 
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
    }
 
    public override void afterDeleteAfterUndeleteTrigger()
    {
    }			
}