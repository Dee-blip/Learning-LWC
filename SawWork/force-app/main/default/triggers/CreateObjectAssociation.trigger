trigger CreateObjectAssociation on Object_Association__c (after insert) {
	/**
	* Trigger to create an Object (Lead or Opportunity) Association. This trigger also creates shares for the associations.
	**/ 
	//AccountAssociationHelper helper = new AccountAssociationHelper(Trigger.new);
	List<Id> leadIds = new List<Id>();
	List<Id> oppIds = new List<Id>();
	List<Id> assAccIds = new List<Id>();
	for(Object_Association__c oa : trigger.new){
		if(oa.LeadId__c != null){
			leadIds.add(oa.LeadId__c);
			assAccIds.add(oa.Associated_Account__c);			
		}
		
		if(oa.OpportunityId__c != null){
			oppIds.add(oa.OpportunityId__c);
			assAccIds.add(oa.Associated_Account__c);			
		}		
	}
	//Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(assAccIds, 'Partner');	
	//Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
	if(!leadIds.isEmpty()){
		//AccountAssociationHelper.createObjectShares(leadIds, accountIdUserRoleIdMap, gMap, helper.getGroupIds(), helper.getAcctParentMap());
		ObjectShares.createLeadShares(leadIds, assAccIds);
	}
	if(!oppIds.isEmpty()){
		//AccountAssociationHelper.createObjectShares(oppIds, accountIdUserRoleIdMap, gMap, helper.getGroupIds(), helper.getAcctParentMap());
		ObjectShares.createOpportunityShares(oppIds, assAccIds);
	}
}