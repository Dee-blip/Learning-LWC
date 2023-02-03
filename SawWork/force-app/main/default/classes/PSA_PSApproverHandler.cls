public class PSA_PSApproverHandler extends ApexTriggerHandlerAbstractClass
{
    public PSA_PSApproverHandler()
    {
        
    }
    public override void beforeInsertBeforeUpdateTrigger()
    {
    }
 
    public override void afterInsertAfterUpdateTrigger()
    {
        	PSA_OverageController.validAutomatedUpsert = true;
        	PSA_OverageController.upsertOverageRecords(trigger.isInsert,(Map <Id, PS_Approved_Hours__c>) oldMap,  newList);       
    }
 
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
    }
 
    public override void afterDeleteAfterUndeleteTrigger()
    {
    }	

}