trigger handleDivisionChanges on Division__c (before insert, before update) {
	// Below code comented because Now the user lookup removed form devision
	/*
	if(Trigger.isBefore) {
		if (Trigger.isInsert) 
		{
			DivisionManager.handleDivisionBeforeInsert(Trigger.new);
		} 
		else if (Trigger.isUpdate) 
		{
			DivisionManager.handleDivisionBeforeUpdate(Trigger.oldMap, Trigger.newMap);
		} 
	}
	*/
}