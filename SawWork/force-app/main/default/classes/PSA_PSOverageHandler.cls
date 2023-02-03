public class PSA_PSOverageHandler extends ApexTriggerHandlerAbstractClass
{
    public PSA_PSOverageHandler()
    {
        
    }
    public override void beforeInsertBeforeUpdateTrigger()
    {
        if(!PSA_OverageController.checkRecursion)
        {
            PSA_OverageController.checkRecursion = true;
            if(Trigger.isUpdate)
            {
                PSA_OverageController.submitSignOff((Map <Id, PS_Overage_Hours__c>)oldMap,newList);    
            }
            if(Trigger.isInsert)
            {
                PSA_OverageController.getOverageLinkedToProject(Trigger.isInsert,(Map <Id, PS_Overage_Hours__c>) oldMap,newList);    
            }
            //postUpdateActions handler is made to work in preInsert/update
            PSA_OverageController.postUpdateActions(Trigger.isInsert,(Map <Id, PS_Overage_Hours__c>)oldMap,newList);       
        }
        
    }
 
    public override void afterInsertAfterUpdateTrigger()
    {
        if(!PSA_OverageController.checkRecursionPost)
        {
            PSA_OverageController.checkRecursionPost = true;
            //PSA_OverageController.postUpdateActions(trigger.isInsert,(Map <Id, PS_Overage_Hours__c>)oldMap,newList);       
        }
            
    }
 
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
    }
 
    public override void afterDeleteAfterUndeleteTrigger()
    {
    }   

}