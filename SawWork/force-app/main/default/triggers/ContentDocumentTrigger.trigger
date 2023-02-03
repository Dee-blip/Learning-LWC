/*
 * CR: FFPSA-647
 * Developer: Sharath Prasanna
 * Enhancement: trigger for Content Document
 * Date: 21th August 2018
 * 
*/ 

trigger ContentDocumentTrigger on ContentDocument (
	before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) 
{

	if(trigger.isDelete && trigger.isBefore)
	{
		//CXM Activity Task files deletion handler
		SC_CreateCXMActivityController.updateIsFileAttachedOnTask(trigger.old);
	}

	//system.assertEquals(1,2);
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('ContentDocument');
    }
}