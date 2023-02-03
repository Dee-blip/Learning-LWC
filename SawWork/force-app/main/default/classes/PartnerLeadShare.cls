/*
Class : PartnerLeadShares
Author : Shivam Verma
Date : Aug 2018
Usage:  creates R/O share for the disti on the Lead object
Config - Need Apex Sharing reason - 'Distributor' for Lead
*/
public class PartnerLeadShare {
    
    @future
	public static void CreatePartnerShares(Map<Id,Id> objIdToPartnerInvolvedAccId)
	{
		list<id> AccIdsList=objIdToPartnerInvolvedAccId.values();
		//Remove duplicates
		Set<Id> AccIds = new Set<Id>(AccIdsList);

		
		/*for(Lead l:leads)
		{
			AccIds.add(l.partner_involved__c);
		}*/
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           System.debug('Inside adding account loop');
           list<id> parentaccidstemp = new list<id>();
           acc_parentIdlist_map.put(acc.id,new list<id>());
           parentaccidstemp.add(acc.id);
           if(acc.ParentId!=null)
           	parentaccidstemp.add(acc.ParentId); 
           if(acc.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.ParentId);
           if(acc.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.ParentId);
           if(acc.Parent.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.Parent.ParentId); 
           if(acc.Parent.Parent.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.Parent.Parent.ParentId); 
           if(acc.Parent.Parent.Parent.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.Parent.Parent.Parent.ParentId);
		   if(parentaccidstemp.size()>0)
		   {
		   		acc_parentIdlist_map.get(acc.id).addAll(parentaccidstemp);
		   		parentaccids.addAll(parentaccidstemp);
		   } 
		   System.debug('parentaccids : '+parentaccids);   
		   System.debug('acc_parentIdlist_map :'+acc_parentIdlist_map);                             	
        }
        // Get all roles of the parent accounts
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
        System.debug('accountIdUserRoleIdMap :'+accountIdUserRoleIdMap);
       	// Get all groups of the parent accounts
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        System.debug('gMap :'+gMap);
        List<LeadShare> newLeadShares = new List<LeadShare>();
        List<CampaignShare> newCampaignShare = new List<CampaignShare>();
        
        for(Id l:objIdToPartnerInvolvedAccId.keySet())
		{
			String sobjectType = l.getSObjectType().getDescribe().getName();

			if (acc_parentIdlist_map != null && acc_parentIdlist_map.size() > 0) {
				for(id accid:acc_parentIdlist_map.get(objIdToPartnerInvolvedAccId.get(l)))
				{
					Id roleId = accountIdUserRoleIdMap.get(accid);
					Id groupId = gMap.get(roleId);	        	
					if (groupId == null) continue;   

					if (sobjectType == 'Lead') {
						newLeadShares.add(
						new LeadShare(
							LeadId = l,
							rowCause = 'Manual',
							userOrGroupId = groupId,
							LeadAccessLevel = 'EDIT')
						);
						} else {
							newCampaignShare.add(
						new CampaignShare(
							CampaignId = l,
							rowCause = 'Manual',
							userOrGroupId = groupId,
							CampaignAccessLevel = 'EDIT')
						);
						}
					
				}
			}
		}
		System.debug('newLeadShares :'+newLeadShares);
		System.debug('newCampaignShare :'+newCampaignShare);
		if(newLeadShares.size()>0)
			insert newLeadShares;

		if(newCampaignShare.size()>0)
			insert newCampaignShare;
			
	}

	public static void DeletePartnerShares(List<Lead> leads,map<id,sObject> TriggeroldMap)
	{
		list<id> AccIds=new list<id>();
		list<id> leadIds=new list<id>();
		
		for(Lead l:leads)
		{
			
			leadIds.add(l.id);
			AccIds.add(((Lead)TriggeroldMap.get(l.id)).partner_involved__c);
		}
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           list<id> parentaccidstemp = new list<id>();
           	acc_parentIdlist_map.put(acc.id,new list<id>());
           parentaccidstemp.add(acc.id);
           if(acc.ParentId!=null)
           	parentaccidstemp.add(acc.ParentId); 
           if(acc.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.ParentId);
           if(acc.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.ParentId);
           if(acc.Parent.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.Parent.ParentId); 
           if(acc.Parent.Parent.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.Parent.Parent.ParentId); 
           if(acc.Parent.Parent.Parent.Parent.Parent.ParentId!=null)
           	parentaccidstemp.add(acc.Parent.Parent.Parent.Parent.Parent.ParentId);
		   if(parentaccidstemp.size()>0)
		   {
		   		acc_parentIdlist_map.get(acc.id).addAll(parentaccidstemp);
		   		parentaccids.addAll(parentaccidstemp);
		   } 
		   system.debug('Parents ids:'+acc.id+':'+parentaccidstemp);                                 	
        }
        
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
       
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<LeadShare> oldLeadShares = new List<LeadShare>();
        list<id> gids = new list<id>();
        
        for(Lead ld:leads)
		{
			if (acc_parentIdlist_map.get(((Lead)TriggeroldMap.get(ld.id)).partner_involved__c) != null) {
				for(id accid:acc_parentIdlist_map.get(((Lead)TriggeroldMap.get(ld.id)).partner_involved__c))
				{
					Id roleId = accountIdUserRoleIdMap.get(accid);
					Id groupId = gMap.get(roleId);	        	
					if (groupId == null) continue; 
					gids.add(groupId);
				}
			}
			
		}
		// Get all fund record shares for the old account
		for(LeadShare ls : [select id from LeadShare where LeadId in :leadIds and rowCause = 'Manual' and UserOrgroupId in :gids and IsDeleted=false ]){
		 oldLeadShares.add(ls);
		}
		// delete old account record shares
		if(oldLeadShares.size()>0)
			delete oldLeadShares;
	}
}