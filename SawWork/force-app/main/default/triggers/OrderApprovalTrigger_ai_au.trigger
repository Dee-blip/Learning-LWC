/***
    OrderApprovalTrigger_ai_au
    @author Karteek Mekala <kmekala@akamai.com>
    @Description : This trigger is called on 'after insert, after update'
                   - The CCG#,Legal# and Deal Desk# are promoted to the Associtated Oppty. 
                  
*/   
trigger OrderApprovalTrigger_ai_au on Order_Approval__c (after insert, after update) 
{
	try
	{
		OrderApprovalClass.UpdateOppty(Trigger.new);
	}
	catch(DMLException e)
	{
		if(e.getMessage().contains('UNABLE_TO_LOCK_ROW'))
		{
			for(Order_Approval__c oa : Trigger.new)
				oa.addError('Unable to obtain exclusive access to this record. Please try again later or contact your system administrator if the issue persists.');
		}
		else
			throw e;
	}	
}