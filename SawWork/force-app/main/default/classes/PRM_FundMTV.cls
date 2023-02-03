/***
    PRM_FundMTV
    @author Vinayendra T N <Vinatara@akamai.com>
    @Description : This is a class for creating MTV shares for FC,FR and FB
 * History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N	07/06/11	CR 1131499 PRM: Need to ensure MTV also works with FR, FC, FB, etc. Not only opportunities
 								
*/  
global class PRM_FundMTV {
	public static Boolean FundRequestCreateMTVFirstRunFlag = true;
	public static Boolean FundClaimCreateMTVRunFlag = true;
	public static Boolean FundBudgetCreateMTVRunFlag = true;
	public static Boolean FundRequestRemoveMTVFirstRunFlag = true;
	public static Boolean FundClaimRemoveMTVnFirstRunFlag = true;
	public static Boolean FundBudgetRemoveMTVFirstRunFlag = true;
	// Create MTV shares for Fund Requests
	public static void FundRequestCreateMTV(SFDC_MDF__c[] FundReq)
	{
		if(!FundRequestCreateMTVFirstRunFlag)
  		return;
		boolean shareWithThisAcc=false;
		list<id> AccIds=new list<id>();
		//Get all Fund record Ids
		for(SFDC_MDF__c fr:FundReq)
		{
			AccIds.add(fr.Account__c);
		}
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		//Get all parent account of the related account
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           list<id> parentaccidstemp = new list<id>();
           acc_parentIdlist_map.put(acc.id,new list<id>());
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
        // Get all roles of the parent accounts
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
       	// Get all groups of the parent accounts
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<SFDC_MDF__Share> newFRShares = new List<SFDC_MDF__Share>();
        //Create fund record shares for the parent accounts
        for(SFDC_MDF__c fr:FundReq)
		{
			//AccIds.add(fr.Account__c);
			for(id accid:acc_parentIdlist_map.get(fr.Account__c))
			{
				Id roleId = accountIdUserRoleIdMap.get(accid);
				Id groupId = gMap.get(roleId);	        	
				if (groupId == null) continue;      	
                newFRShares.add(
                	new SFDC_MDF__Share(
		                ParentId = fr.id,
		                userOrGroupId = groupId,
		                AccessLevel = 'EDIT')
		            );
			}
		}
		// insert the Shares
		if(newFRShares.size()>0)
			insert newFRShares;
		FundRequestCreateMTVFirstRunFlag=false;
	}
	// Create MTV shares for Fund Claims
	public static void FundClaimCreateMTV(SFDC_MDF_Claim__c[] FundRec)
	{
		
		if(!FundClaimCreateMTVRunFlag)
  		return;
		boolean shareWithThisAcc=false;
		list<id> AccIds=new list<id>();
		//Get all Fund record Ids
		for(SFDC_MDF_Claim__c fr:FundRec)
		{
			AccIds.add(fr.Account__c);
		}
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		//Get all parent account of the related account
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           list<id> parentaccidstemp = new list<id>();
           acc_parentIdlist_map.put(acc.id,new list<id>());
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
        // Get all roles of the parent accounts
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
        // Get all groups of the parent accounts
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<SFDC_MDF_Claim__Share> newFRShares = new List<SFDC_MDF_Claim__Share>();
        //Create fund record shares for the parent accounts
        for(SFDC_MDF_Claim__c fr:FundRec)
		{
			//AccIds.add(fr.Account__c);
			for(id accid:acc_parentIdlist_map.get(fr.Account__c))
			{
				Id roleId = accountIdUserRoleIdMap.get(accid);
				Id groupId = gMap.get(roleId);	        	
				if (groupId == null) continue;      	
                newFRShares.add(
                	new SFDC_MDF_Claim__Share(
		                ParentId = fr.id,
		                userOrGroupId = groupId,
		                AccessLevel = 'EDIT')
		            );
			}
		}
		// insert the Shares
		if(newFRShares.size()>0)
			insert newFRShares;
		FundClaimCreateMTVRunFlag = false;
	}
	// Create MTV shares for Fund Budget
	public static void FundBudgetCreateMTV(SFDC_Budget__c[] FundRec)
	{
		if(!FundBudgetCreateMTVRunFlag)
  		return;
		boolean shareWithThisAcc=false;
		list<id> AccIds=new list<id>();
		//Get all Fund record Ids
		for(SFDC_Budget__c fr:FundRec)
		{
			AccIds.add(fr.Account__c);
		}
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		//Get all parent account of the related account
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           list<id> parentaccidstemp = new list<id>();
           acc_parentIdlist_map.put(acc.id,new list<id>());
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
        // Get all roles of the parent accounts
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
        // Get all groups of the parent accounts
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<SFDC_Budget__Share> newFRShares = new List<SFDC_Budget__Share>();
        //Create fund record shares for the parent accounts
        for(SFDC_Budget__c fr:FundRec)
		{
			//AccIds.add(fr.Account__c);
			for(id accid:acc_parentIdlist_map.get(fr.Account__c))
			{
				Id roleId = accountIdUserRoleIdMap.get(accid);
				Id groupId = gMap.get(roleId);	        	
				if (groupId == null) continue;      	
                newFRShares.add(
                	new SFDC_Budget__Share(
		                ParentId = fr.id,
		                userOrGroupId = groupId,
		                AccessLevel = 'EDIT')
		            );
			}
		}
		// insert the Shares
		if(newFRShares.size()>0)
			insert newFRShares;
		FundBudgetCreateMTVRunFlag = false;
	}
	// delete MTV shares for Fund Requests
	public static void FundRequestRemoveMTV(SFDC_MDF__c[] FundReq,map<id,SFDC_MDF__c> TriggeroldMap)
	{
		if(!FundRequestRemoveMTVFirstRunFlag)
  		return;
		boolean shareWithThisAcc=false;
		list<id> AccIds=new list<id>();
		list<id> FrIds=new list<id>();
		//Get all Fund record Ids
		for(SFDC_MDF__c fr:FundReq)
		{
			//AccIds.add(fr.Account__c);
			FrIds.add(fr.id);
			AccIds.add(TriggeroldMap.get(fr.id).Account__c);
		}
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		//Get all parent account of the related account
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           list<id> parentaccidstemp = new list<id>();
           	acc_parentIdlist_map.put(acc.id,new list<id>());
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
        // Get all roles of the parent accounts
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
        // Get all groups of the parent accounts
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<SFDC_MDF__Share> newFRShares = new List<SFDC_MDF__Share>();
        list<id> gids = new list<id>();
        //delete fund record shares for the parent accounts
        for(SFDC_MDF__c fr:FundReq)
		{
			//AccIds.add(fr.Account__c);
			for(id accid:acc_parentIdlist_map.get(TriggeroldMap.get(fr.id).Account__c))
			{
				Id roleId = accountIdUserRoleIdMap.get(accid);
				Id groupId = gMap.get(roleId);	        	
				if (groupId == null) continue; 
				gids.add(groupId);     	
                /*newFRShares.add(
                	new SFDC_MDF__Share(
		                ParentId = fr.id,
		                userOrGroupId = groupId,
		                AccessLevel = 'EDIT')
		            );*/
			}
		}
		// Get all fund record shares for the old account
		for(SFDC_MDF__Share frs : [select id from SFDC_MDF__Share where ParentId in :FrIds and rowCause = 'Manual' and UserOrgroupId in :gids and IsDeleted=false ]){
		 newFRShares.add(frs);
		}
		// delete old account record shares
		if(newFRShares.size()>0)
			delete newFRShares;
		FundRequestRemoveMTVFirstRunFlag = false;
	}
	
	// delete MTV shares for Fund Claims
	public static void FundClaimRemoveMTV(SFDC_MDF_Claim__c[] FundRec,map<id,SFDC_MDF_Claim__c> TriggeroldMap)
	{
		if(!FundClaimRemoveMTVnFirstRunFlag)
  		return;
		boolean shareWithThisAcc=false;
		list<id> AccIds=new list<id>();
		list<id> FrIds=new list<id>();
		//Get all Fund record Ids
		for(SFDC_MDF_Claim__c fr:FundRec)
		{
			//AccIds.add(fr.Account__c);
			FrIds.add(fr.id);
			AccIds.add(TriggeroldMap.get(fr.id).Account__c);
		}
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		//Get all parent account of the related account
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           list<id> parentaccidstemp = new list<id>();
           	acc_parentIdlist_map.put(acc.id,new list<id>());
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
        // Get all roles of the parent accounts
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
        // Get all groups of the parent accounts
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<SFDC_MDF_Claim__Share> newFRShares = new List<SFDC_MDF_Claim__Share>();
        list<id> gids = new list<id>();
        //delete fund record shares for the parent accounts
        for(SFDC_MDF_Claim__c fr:FundRec)
		{
			//AccIds.add(fr.Account__c);
			for(id accid:acc_parentIdlist_map.get(TriggeroldMap.get(fr.id).Account__c))
			{
				Id roleId = accountIdUserRoleIdMap.get(accid);
				Id groupId = gMap.get(roleId);	        	
				if (groupId == null) continue; 
				gids.add(groupId);     	
                /*newFRShares.add(
                	new SFDC_MDF__Share(
		                ParentId = fr.id,
		                userOrGroupId = groupId,
		                AccessLevel = 'EDIT')
		            );*/
			}
		}
		// Get all fund record shares for the old account
		for(SFDC_MDF_Claim__Share frs : [select id from SFDC_MDF_Claim__Share where ParentId in :FrIds and rowCause = 'Manual' and UserOrgroupId in :gids and IsDeleted=false ]){
		 newFRShares.add(frs);
		}
		// delete old account record shares
		if(newFRShares.size()>0)
			delete newFRShares;
		FundClaimRemoveMTVnFirstRunFlag = false;
	}
	// delete MTV shares for Fund budgets
	public static void FundBudgetRemoveMTV(SFDC_Budget__c[] FundRec,map<id,SFDC_Budget__c> TriggeroldMap)
	{
		if(!FundBudgetRemoveMTVFirstRunFlag)
  		return;
		boolean shareWithThisAcc=false;
		list<id> AccIds=new list<id>();
		list<id> FrIds=new list<id>();
		//Get all Fund record Ids
		for(SFDC_Budget__c fr:FundRec)
		{
			//AccIds.add(fr.Account__c);
			FrIds.add(fr.id);
			AccIds.add(TriggeroldMap.get(fr.id).Account__c);
		}
		map<id,list<id>> acc_parentIdlist_map = new map<id,list<id>>();
		list<id> parentaccids = new list<id>();
		//Get all parent account of the related account
		for(Account acc:[select id,ParentId, Parent.ParentId, Parent.Parent.ParentId, Parent.Parent.Parent.ParentId, 
                                                    Parent.Parent.Parent.parent.ParentId, Parent.Parent.Parent.parent.Parent.ParentId
                                                    from Account where Id in :accIds])
        {
           list<id> parentaccidstemp = new list<id>();
           	acc_parentIdlist_map.put(acc.id,new list<id>());
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
        // Get all roles of the parent accounts
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(parentaccids, 'Partner');
        // Get all groups of the parent accounts
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<SFDC_Budget__Share> newFRShares = new List<SFDC_Budget__Share>();
        list<id> gids = new list<id>();
        //delete fund record shares for the parent accounts
        for(SFDC_Budget__c fr:FundRec)
		{
			//AccIds.add(fr.Account__c);
			for(id accid:acc_parentIdlist_map.get(TriggeroldMap.get(fr.id).Account__c))
			{
				Id roleId = accountIdUserRoleIdMap.get(accid);
				Id groupId = gMap.get(roleId);	        	
				if (groupId == null) continue; 
				gids.add(groupId);     	
                /*newFRShares.add(
                	new SFDC_MDF__Share(
		                ParentId = fr.id,
		                userOrGroupId = groupId,
		                AccessLevel = 'EDIT')
		            );*/
			}
		}
		// Get all fund record shares for the old account
		for(SFDC_Budget__Share frs : [select id from SFDC_Budget__Share where ParentId in :FrIds and rowCause = 'Manual' and UserOrgroupId in :gids and IsDeleted=false ]){
		 newFRShares.add(frs);
		}
		// delete old account record shares
		if(newFRShares.size()>0)
			delete newFRShares;
		FundBudgetRemoveMTVFirstRunFlag = false;
	}
}