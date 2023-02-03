public class ObjectShares {

    @future
	public static void createLeadShares(List<Id> leadIds, List<Id> assAccIds)
	{
		List<LeadShare> newLeadShares = new List<LeadShare>();

		Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(assAccIds, 'Partner');	
		Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());

	    //get the access level for leads
	    Configuration config = Configuration.getInstance();
	    String leadAccessLevel = config.getObjectAccessLevel(Configuration.LEAD);

		for (Object_Association__c objAssoc : [select id, LeadId__c, Associated_Account__c from Object_Association__c where LeadId__c in :leadIds])
		{
	        if(objAssoc.associated_account__c != null && accountIdUserRoleIdMap.containsKey(objAssoc.associated_account__c)){				        	
				Id roleId = accountIdUserRoleIdMap.get(objAssoc.associated_account__c);
				Id groupId = gMap.get(roleId);	  
				if (groupId == null) continue;      	
                newLeadShares.add(
                	new LeadShare(
	                    LeadId = objAssoc.LeadId__c,
	                    userOrGroupId = groupId,
	                    LeadAccessLevel = leadAccessLevel)
            	);
			}
		} 	    
	    
	    if(newLeadShares.size() > 0)
	    	insert newLeadShares;
		
	}

    
    @future
	public static void createOpportunityShares(List<Id> objList, List<Id> assAccIds)
	{
	    List<OpportunityShare> newOppShares = new List<OpportunityShare>();

		Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(assAccIds, 'Partner');	
		Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());

	    Configuration config = Configuration.getInstance();
	    String oppAccessLevel = config.getObjectAccessLevel(Configuration.OPPORTUNITY);
	    
		for (Object_Association__c objAssoc : [select id, OpportunityId__c,Associated_Account__c from Object_Association__c where OpportunityId__c in :objList]) {			//, LeadId__c, OpportunityId__c
	        if(objAssoc.associated_account__c != null && accountIdUserRoleIdMap.containsKey(objAssoc.associated_account__c)){				        	
				Id roleId = accountIdUserRoleIdMap.get(objAssoc.associated_account__c);
				Id groupId = gMap.get(roleId);	        	
				if (groupId == null) continue;      	
                newOppShares.add(
                	new OpportunityShare(
		                OpportunityId = objAssoc.OpportunityId__c,
		                userOrGroupId = groupId,
		                OpportunityAccessLevel = oppAccessLevel)
		            );
            }					
    	}
	    	
	    if(newOppShares.size()>0)
	    	insert newOppShares;	        
    }		
}