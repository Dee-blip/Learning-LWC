trigger DeleteObjectAssociationShares on Object_Association__c (after delete) {
	/**
	* Trigger to delete an Object (Lead or Opportunity) Association. This trigger also deletes shares for the deleted association.
	**/
	Map<string,Id> leadIds = new Map<string,Id>();
	Map<string,Id> oppIds = new Map<string,Id>();
    Map<string,Id> assocIds = new Map<string,Id>();
    Set<string> userGroupIds = new Set<string>();
    
    AccountAssociationHelper helper = new AccountAssociationHelper(Trigger.old);
    Map<String,String> groupIds = helper.getGroupIds();
    Map<String,String> acctParentMap = helper.getAcctParentMap();
    Boolean isLead = false;
    Boolean isOpp = false;
	
	for (Object_Association__c assoc : Trigger.old)
    {
    	String key = 'AssocAccount'+assoc.associated_account__c; 
        if(assoc.LeadId__c != null){
        	leadIds.put(key, assoc.LeadId__c);
        	isLead = true;
        }
        if(assoc.OpportunityId__c != null){
        	oppIds.put(key, assoc.OpportunityId__c);
        	isOpp = true;
        }
        if (assoc.associated_account__c != null && String.valueOf(assoc.Associated_Account__c) != '')
            assocIds.put(key, assoc.associated_account__c);
    	userGroupIds.add(assoc.associated_account__c+
        groupIds.get('AssocAccount'+assoc.Associated_Account__c));
    }
    if(isLead){
    	AccountAssociationHelper.removeLeadShares(leadIds, assocIds, groupIds, userGroupIds);
    }
    if(isOpp){
    	AccountAssociationHelper.removeOppShares(oppIds, assocIds, groupIds, userGroupIds);
    }    
}