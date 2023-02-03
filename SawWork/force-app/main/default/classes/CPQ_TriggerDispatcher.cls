/*
* 
* Details : Call the Run method from your trigger, passing in an instance of a trigger handler which implements CPQ_ITriggerHandler.
*			This method will fire the appropriate methods on the handler depending on the trigger context. 
* 
* Developer			Date			Version		Update 
* kimishra			08/06/2019		1.0			Initial version
* shegade           10/03/2021      2.0         the function names are changed to follow the PMD guidelines
*/
public class CPQ_TriggerDispatcher {
    
    public static void run(CPQ_ITriggerHandler handler)
    {
        // Check to see if the trigger has been disabled. If it has, return
        if (handler.isDisabled()){
            return;
        }
        
        // Detect the current trigger context and fire the relevant methods on the trigger handler:
        
        // Before trigger logic
        if (Trigger.IsBefore )
        {
            if (Trigger.IsInsert){
                handler.beforeInsert(trigger.new);
            }
            
            if (Trigger.IsUpdate){
                handler.beforeUpdate(trigger.newMap, trigger.oldMap);
            }
            
            if (Trigger.IsDelete){
                handler.beforeDelete(trigger.oldMap);
            }
        }
        
        // After trigger logic
        if (Trigger.IsAfter)
        {
            if (Trigger.IsInsert){
                handler.afterInsert(Trigger.newMap);
            }
            
            if (Trigger.IsUpdate){
                handler.afterUpdate(trigger.newMap, trigger.oldMap);
            }
            
            if (trigger.IsDelete){
                handler.afterDelete(trigger.oldMap);
            }
            
            if (trigger.isUndelete){
                handler.afterUndelete(trigger.oldMap);
            }
        }
    }
}