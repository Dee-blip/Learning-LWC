trigger GSM_AccountMergeRequestTrigger on Account_Merge_Request__c (before insert, before update) 
{

	if( Trigger.isInsert && Trigger.isBefore)
	{
		List<Account_Merge_Request__c> accMergeRequestList = new List<Account_Merge_Request__c>();
		Set<Id> losingAccountIds = new Set<Id>();
		Set<Id> winningAccountIds = new Set<Id>();
		Set<Id> salesOpsIds = new Set<Id>();
		for(Account_Merge_Request__c newRequest : Trigger.new)
		{	
			if(newRequest.Approved_by_Operations__c == true)
			{
				accMergeRequestList.add(newRequest);
				losingAccountIds.add(newRequest.Losing_Account__c);
				winningAccountIds.add(newRequest.Winning_Account__c);
				salesOpsIds.add(newRequest.Sales_Ops_User__c);
			}
			
		}
		if(accMergeRequestList.size()>0)
		{
			gsm_AccountMergeFlowController.autoPopulateMergeRequestFields(accMergeRequestList, losingAccountIds, winningAccountIds, salesOpsIds);
		}

	}

	//SFDC-6590 Ability to auto approve Merge Request
	if(Trigger.isInsert && Trigger.isBefore){
    	gsm_AccountMergeFlowController.evaluateAutoApproval(Trigger.new);
    }

}