trigger MergedContractActivity_bi_bu on Merge_Contract_Activity__c (before insert, before update) 
{
	// Cast Iron Integration : Resolve the Opportunity Foreign Keys
	List<Merge_Contract_Activity__c> activityOppResolveList = new List<Merge_Contract_Activity__c>();
	
	for(Merge_Contract_Activity__c activity : Trigger.new)
	{
		if(activity.CI_Opportunity_Name__c != null && (Trigger.isInsert || (!Trigger.isInsert && activity.CI_Opportunity_Name__c != Trigger.oldMap.get(activity.ID).CI_Opportunity_Name__c)))		
			activityOppResolveList.add(activity);
		else if(activity.CI_Opportunity_Name__c == null && (!Trigger.isInsert && activity.CI_Opportunity_Name__c != Trigger.oldMap.get(activity.ID).CI_Opportunity_Name__c))
		    activity.Opportunity_Name__c=null;
	}
	if(activityOppResolveList.size() > 0)
		CastIronClass.Resolve_MergeContractActivity_OpportunityForeginKeys(activityOppResolveList);
			
	// Cast Iron Integration : Resolve the Contract Header Foreign Keys
	List<Merge_Contract_Activity__c> activityContractResolveList = new List<Merge_Contract_Activity__c>(); 
	for(Merge_Contract_Activity__c activity : Trigger.new)
	{
		if(Trigger.isInsert && activity.CI_Original_Contract_Id__c != null)	
			activityContractResolveList.add(activity);
		else if(!Trigger.isInsert && activity.CI_Original_Contract_Id__c != Trigger.oldMap.get(activity.ID).CI_Original_Contract_Id__c)
			activity.addError('Original Contract Id cannot be updated after insert.');
	}
	if(activityContractResolveList.size() > 0)
		CastIronClass.Resolve_MergeContractActivity_ContractHeaderForeginKeys(activityContractResolveList);		
}