trigger MergedContractPO_bi_bu on Merge_Contract_PO__c (before insert, before update) 
{
	// Cast Iron Integration : Resolve the Contract Header Foreign Keys
	List<Merge_Contract_PO__c> orderContractResolveList = new List<Merge_Contract_PO__c>(); 
	for(Merge_Contract_PO__c order : Trigger.new)
	{
		if(Trigger.isInsert && order.CI_Original_Contract_Id__c != null)	
			orderContractResolveList.add(order);
		else if(!Trigger.isInsert && order.CI_Original_Contract_Id__c != Trigger.oldMap.get(order.ID).CI_Original_Contract_Id__c)
			order.addError('Original Contract Id cannot be updated after insert.');
	}
	if(orderContractResolveList.size() > 0)
		CastIronClass.Resolve_MergeContractPO_ContractHeaderForeginKeys(orderContractResolveList);
}