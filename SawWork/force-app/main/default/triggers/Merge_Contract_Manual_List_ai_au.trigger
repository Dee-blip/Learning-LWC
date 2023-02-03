trigger Merge_Contract_Manual_List_ai_au on Merge_Contract_Manual_List__c (after insert, after update) 
{
	//CastIronClass.contractManualList_checkForActiveInActive(Trigger.new);	
	MergeContractManualListClass.contractManualList_checkForActiveInActive(Trigger.new);
}