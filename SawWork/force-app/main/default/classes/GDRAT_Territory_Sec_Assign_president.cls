/*
* developer@Hemant Barapatre
* class : uses the GDRAT_Territory_Sec_Assign_ambassador
* Pattern used : Tigger factory
*/

public without sharing class GDRAT_Territory_Sec_Assign_president {

/**
* Public static method to create and execute a trigger handler
*
* Arguments: Schema.sObjectType soType - Object type to process (SObject.sObjectType)
*
* Throws a TriggerException if no handler has been coded.
*/
public static void createHandler(Schema.sObjectType soType){
// Get a handler appropriate to the object being processed
GDRAT_CoreTriggerInterface handler = getHandler(soType);
// Make sure we have a handler registered, new handlers must be registered in the getHandler method.
if (handler == null)
{
    system.debug('No Trigger Handler registered for Object Type: ' + soType);
//throw new TriggerException('No Trigger Handler registered for Object Type: ' + soType);
}
// Execute the handler to fulfil the trigger
execute(handler);
}//

/**
* private static method to control the execution of the handler
*
* Arguments: ITrigger handler - A Trigger Handler to execute
*/
private static void execute(GDRAT_CoreTriggerInterface handler)
{
// Before Trigger
if (Trigger.isBefore)
{
if (Trigger.isInsert) {
handler.beforeInsert(trigger.new);
}
// Iterate through the records to be updated passing them to the handler.
else if (Trigger.isUpdate)
{
handler.beforeUpdate(trigger.new,trigger.old,trigger.newMap,trigger.oldMap);
}
}

// Perform any post processing
handler.andFinally();
}

/**
* private static method to get the appropriate handler for the object type.
* Modify this method to add any additional handlers.
*
* Arguments: Schema.sObjectType soType - Object type tolocate (SObject.sObjectType)
*
* Returns: ITrigger - A trigger handler if one exists or null.
*/
private static GDRAT_CoreTriggerInterface getHandler(Schema.sObjectType soType)
{
if (soType == Territory_Security_Assignment__c.sObjectType){
return new GDRAT_Territory_Sec_Assign_ambassador();
}
return null;
}


}//END