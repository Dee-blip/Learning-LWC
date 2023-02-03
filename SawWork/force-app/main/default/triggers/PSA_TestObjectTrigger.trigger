/*
 * CR: FFPSA-238
 * Developer: Sharath Prasanna
 * Enhancement: After insert trigger for Test__c
 * Date: 8th August 2017
 * 
*/ 
trigger PSA_TestObjectTrigger on Test__c (after insert,before delete) 
{

		if (Trigger.isafter && Trigger.isInsert) 
		{
			PSA_ProjectActions.addTestResource(trigger.new);	    
		} 

		if (Trigger.isbefore && Trigger.isdelete) 
		{
			PSA_ProjectActions.checkInvalidTestDelete(trigger.old);	    
		} 


}