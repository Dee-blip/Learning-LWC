//SFDC-3054 Added before delete
trigger TaskTriggerFramework on Task (after delete, after insert, after undelete, after update,before update, before insert, before delete) {
	
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('Task');
    }
}