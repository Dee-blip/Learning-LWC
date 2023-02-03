public class PSA_PSOverageScheduleHandler extends ApexTriggerHandlerAbstractClass
{
	public PSA_PSOverageScheduleHandler() 
	{
		
	}
    public override void beforeInsertBeforeUpdateTrigger()
    {
        if(Trigger.isUpdate)
        {
        	PSA_OverageController.sendReminderEmailAfterChecks((Map <Id, PS_Overage_Schedule__c>) oldMap,  newList);                   
        }
		
    }
 
    public override void afterInsertAfterUpdateTrigger()
    {
        	
    }
 
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
    }
 
    public override void afterDeleteAfterUndeleteTrigger()
    {
    }		
}