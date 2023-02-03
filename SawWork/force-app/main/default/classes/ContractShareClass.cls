public class ContractShareClass   
{
	public static Boolean delContractShareFirstRunFlag = true;
	
	public ContractShareClass()
	{
		//delContractShareFirstRunFlag=false;
		// init();
	}
	public static List<Opportunity> fetchOpportunityOTMList(Set<Id> pOppAccIds, Set<Id> pUserIds)
	{
		return [SELECT o.OwnerId, o.Id, o.Owner.isActive, o.AccountId, (SELECT Id, OpportunityId, UserId, User.isActive, User.UserType, 
			TeamMemberRole, OpportunityAccessLevel, IsDeleted FROM OpportunityTeamMembers WHERE User.isActive = true 
				AND User.UserType='Standard' AND UserId IN :pUserIds) FROM Opportunity o WHERE o.AccountId IN: pOppAccIds];
	}
	
	public static List<Account> fetchAccountATMList(Set<Id> pAccIds, Set<Id> pUserIds)
	{
		return [SELECT a.OwnerId, a.Owner.isActive, a.Id, (Select Id, AccountId, OwnerId From Opportunities), 
			(SELECT Id, AccountId, UserId, User.isActive, User.UserType, TeamMemberRole FROM AccountTeamMembers 
				WHERE User.isActive = true AND User.UserType='Standard' AND UserId IN :pUserIds) FROM Account a WHERE a.Id IN: pAccIds];
	}
	
	public static List<Merge_Contract_Header__Share> fetchMCHShareList(Set<Id> pCShareAccIdSet, Set<Id> pCShareOpptyIdSet, Set<Id> pCShareUserSet)
	{
		return [SELECT UserOrGroupId, Parent.Opportunity_Name__c, Parent.Opportunity_Name__r.AccountId, Parent.Account_Name__c, ParentId, Id, AccessLevel FROM 
			Merge_Contract_Header__Share WHERE  RowCause = 'Manual' AND UserOrGroupId IN : pCShareUserSet AND (Parent.Account_Name__c IN : pCShareAccIdSet
				OR (Parent.Opportunity_Name__c!=null AND Parent.Opportunity_Name__c IN : pCShareOpptyIdSet))];
	}
	
	public static List<Id> getOTMIds(List<OpportunityTeamMember> pOTMList)
	{
		List<Id> otmIdList = new List<Id>(); 
		for (OpportunityTeamMember otm : pOTMList)	
		{	
			otmIdList.add(otm.UserId);
		}
		return otmIdList;
	}
	
	public static List<Id> getATMIds(List<AccountTeamMember> pATMList)
	{
		List<Id> atmIdList = new List<Id>(); 
		for (AccountTeamMember atm : pATMList)	
		{	
			atmIdList.add(atm.UserId);
		}
		return atmIdList;
	}
	
	public static Boolean checkOccurence(List<Id> tobeTraversedList, Id searchForId)
	{
		Boolean found = false;
    	for (Id identity: tobeTraversedList)
    	{
    		if (searchForId==identity)
    		{
    			found=true;
    			break;
    		}
    	}
        return found;
	}
	
	public void delContractShare(List<Contract_Share__c> delContractShareList)
	{
		// dont do anything if flag=false.
		if(!delContractShareFirstRunFlag)
            return;
		
		List<Contract_Share__c> cShareRemoveList = new List<Contract_Share__c>(); 
		//List<Contract_Share__c> cShareATMList = new List<Contract_Share__c>();
		//List<Contract_Share__c> cShareOTMList = new List<Contract_Share__c>();
		List<Contract_Share__c> cShareToCompareList = new List<Contract_Share__c>();
		List<Contract_Share__c> cShareToDeleteList = new List<Contract_Share__c>();
		Set<Id> atmAccIdToSearchSet = new Set<Id>();
		Set<Id> atmUserIdToSearchSet = new Set<Id>();
		Set<Id> otmAccIdToSearchSet = new Set<Id>();
		Set<Id> otmUserIdToSearchSet = new Set<Id>();
		//Map<Id,Account> otmAccMap = new Map<Id,Account>();
		//Map<Id,Opportunity> atmOppMap = new Map<Id,Opportunity>();
		Set<Id> inActiveUserSet = new Set<Id>();
        //HC:Based on RowCause/Associtaed User - formulate list of OTM Account List,ATM Account List,and ATM/OTM User Set
		for (Contract_Share__c cShare : delContractShareList)
		{	
			if (cShare.Associated_User_Status__c=='Inactive') // remove ContractShare without any checks for Inactive Users.
			{	
				inActiveUserSet.add(cShare.Associated_User__c);
				cShareToDeleteList.add(cShare);
			}
			else if (cShare.RowCause__c=='ATM/OTM')
			{	
				if (cShare.Associated_Opportunity__c!=null && cShare.Associated_Opportunity_Owner__c!=cShare.Associated_User__c)
				// dont delete // search ATM
				{
					//cShareToCompareList.add(cShare);
					cShareToDeleteList.add(cShare);
					//cShareOTMList.add(cShare);
					otmAccIdToSearchSet.add(cShare.Associated_Opportunity_AccountId__c);
					otmUserIdToSearchSet.add(cShare.Associated_User__c);
				}
				else if (cShare.Associated_Account__c!=null & cShare.Associated_Account_Owner__c!=cShare.Associated_User__c)
				//dont delete // search OTM
				{
					//cShareToCompareList.add(cShare);
					cShareToDeleteList.add(cShare);
					//cShareATMList.add(cShare);
					atmAccIdToSearchSet.add(cShare.Associated_Account__c);
					atmUserIdToSearchSet.add(cShare.Associated_User__c);
				}
			}
			//else if ((cShare.RowCause__c=='Owner' || cShare.RowCause__c=='')  && cShare.RowCause__c!='Contract')
			else
			{		
				//cShareToCompareList.add(cShare);
				cShareToDeleteList.add(cShare);
				if (cShare.Associated_Opportunity__c!=null)
				// search OTM / Acc Owner & ATM
				{
					//cShareOTMList.add(cShare);
					atmAccIdToSearchSet.add(cShare.Associated_Opportunity_AccountId__c);
					otmAccIdToSearchSet.add(cShare.Associated_Opportunity_AccountId__c);
					//atmUserIdToSearchSet.add(cShare.Associated_User__c);
					//otmUserIdToSearchSet.add(cShare.Associated_User__c);
				}
				else if (cShare.Associated_Account__c!=null)
				// search ATM / Opp Owner & OTM
				{
					//cShareATMList.add(cShare);
					atmAccIdToSearchSet.add(cShare.Associated_Account__c);
					otmAccIdToSearchSet.add(cShare.Associated_Account__c);
				}
				atmUserIdToSearchSet.add(cShare.Associated_User__c);
				otmUserIdToSearchSet.add(cShare.Associated_User__c);
			}	
		}
		//System.debug('System.debug: cShareToCompareList=' + cShareToCompareList);
		System.debug('System.debug: cShareToDeleteList=' + cShareToDeleteList);
		System.debug('System.debug: atmAccIdToSearchSet=' + atmAccIdToSearchSet);
		System.debug('System.debug: atmUserIdToSearchSet=' + atmUserIdToSearchSet);
		
		// pull up set/map of toDeleteCShare records.
		Set<Id> cShareAccIdSet = new Set<Id>();
		Set<Id> cShareOppIdSet = new Set<Id>();
		Set<Id> cShareUsrIdSet = new Set<Id>();
		Map<Id,List<Id>> userAccMap = new Map<Id,List<Id>>();
		Map<Id,List<Id>> userOppMap = new Map<Id,List<Id>>();
		
		// if no records to delete return.
		if (cShareToDeleteList.size()<1)
			return;
			
		//HC: For Account formulate Associated User to Associated Account Map -same for Oppty 	
		for (Contract_Share__c cShare : cShareToDeleteList)
		{
		// Set of cShare Users
			cShareUsrIdSet.add(cShare.Associated_User__c);
			if (cShare.Associated_Account__c!=null)
			{
				// Set of cShare Accounts	
				cShareAccIdSet.add(cShare.Associated_Account__c);
				
				if (userAccMap.containsKey(cShare.Associated_User__c))
					userAccMap.get(cShare.Associated_User__c).add(cShare.Associated_Account__c);
				else
					userAccMap.put(cShare.Associated_User__c, new List<Id>{cShare.Associated_Account__c});
				
			}
			else if (cShare.Associated_Opportunity__c!=null)
			{
				// Set of cShare Opptys
				cShareOppIdSet.add(cShare.Associated_Opportunity__c);
				
				if(userOppMap.containsKey(cShare.Associated_User__c))
					userOppMap.get(cShare.Associated_User__c).add(cShare.Associated_Opportunity__c);
				else
					userOppMap.put(cShare.Associated_User__c, new List<Id>{cShare.Associated_Opportunity__c});	
			}
		}
		System.debug('System.debug: cShareAccIdSet=' + cShareAccIdSet);
		System.debug('System.debug: cShareOppIdSet=' + cShareOppIdSet);
		System.debug('System.debug: cShareUsrIdSet=' + cShareUsrIdSet);
		System.debug('System.debug: userAccMap=' + userAccMap);
		System.debug('System.debug: userOppMap=' + userOppMap);
		
		
		//Map of Acc : Opp
		Map<Id,List<Id>> atmAccOppMap = new Map<Id, List<Id>>();
		// Map of Oppty : OTM
		Map<Id, List<Id>> atmOppOTMMap = new Map<Id, List<Id>>();
		// Map of Oppty : Owner
		Map<Id, Id> atmOppOwnerMap = new Map<Id, Id>();
		
		// Fetch the Opportunity Owner/OTM for Account Owner/OTM user
		if (atmAccIdToSearchSet.size()>0)
		{	
			//HC: Get all the Opportunities for ATM Assoictaed Accounts and OTM for ATM Associated User
			for (Opportunity oppty : fetchOpportunityOTMList(atmAccIdToSearchSet, atmUserIdToSearchSet))
			{
				// Add to Oppty Map
				//atmOppMap.put(oppty.Id, oppty);
				// Add to Acc:Opp Map
				if (atmAccOppMap.containsKey(oppty.AccountId))
					atmAccOppMap.get(oppty.AccountId).add(oppty.Id);
				else
					atmAccOppMap.put(oppty.AccountId, new List<Id>{oppty.Id});
				// Add to OPP:OTM Map
				if (oppty.OpportunityTeamMembers.size()>0)
					atmOppOTMMap.put(oppty.Id,getOTMIds(oppty.OpportunityTeamMembers));
				// Add to OPP:Owner Map
				atmOppOwnerMap.put(oppty.Id, oppty.OwnerId);	
					
			} 
			//System.debug('System.debug: atmOppMap=' + atmOppMap);
			System.debug('System.debug: atmAccOppMap=' + atmAccOppMap);
			System.debug('System.debug: atmOppOTMMap=' + atmOppOTMMap);
			System.debug('System.debug: atmOppOwnerMap=' + atmOppOwnerMap);
		}

		// Map of Acc : ATM
		Map<Id, List<Id>> otmAccATMMap = new Map<Id, List<Id>>();
		// Map of Oppty : Owner
		Map<Id, Id> otmAccOwnerMap = new Map<Id, Id>();

		// Fetch the Account Owner/ATM for Opportunity Owner/OTM user
		if (otmAccIdToSearchSet.size()>0)
		{			// fetch the Acc Owner / OTMs
			for (Account acc: fetchAccountATMList(otmAccIdToSearchSet, otmUserIdToSearchSet))
			{
				// Add to Acc Map
				//otmAccMap.put(acc.Id, acc);
				// Add to Acc:ATM Map
				if (acc.AccountTeamMembers.size()>0)
					otmAccATMMap.put(acc.Id,getATMIds(acc.AccountTeamMembers));
				// Add to Acc:Owner Map
				otmAccOwnerMap.put(acc.Id, acc.OwnerId);
			}
			//System.debug('System.debug: otmAccMap=' + otmAccMap);
			System.debug('System.debug: otmAccATMMap=' + otmAccATMMap);
			System.debug('System.debug: otmAccOwnerMap=' + otmAccOwnerMap);
		}
		
		List<Merge_Contract_Header__Share> removeMCHShareList = new List<Merge_Contract_Header__Share>();
		Boolean foundShare;
		for (Merge_Contract_Header__Share mchShare : fetchMCHShareList(cShareAccIdSet, cShareOppIdSet, cShareUsrIdSet))
		{	
			foundShare=false;
			
			// check if user is InActive
			if (inActiveUserSet.contains(mchShare.UserOrGroupId))
			{
				removeMCHShareList.add(mchShare);
				continue;
			}
			// Check for Acc Contract Share match		
			if (userAccMap.containsKey(mchShare.UserOrGroupId) && checkOccurence(userAccMap.get(mchShare.UserOrGroupId), mchShare.Parent.Account_Name__c))
			{// Check if part of Associated_Oppty.OTM
				if (mchShare.Parent.Opportunity_Name__c!=null && atmOppOTMMap.size()>0 && atmOppOTMMap.containsKey(mchShare.Parent.Opportunity_Name__c))
				{ 
					for (Id otmId : atmOppOTMMap.get(mchShare.Parent.Opportunity_Name__c))
					{	
						if (mchShare.UserOrGroupId==otmId)
						{
							foundShare=true;
							break;
						}
					}
				}
				// Check if Associated_Oppty.Owner 
				if (!foundShare && mchShare.Parent.Opportunity_Name__c!=null && atmOppOwnerMap.size()>0 && atmOppOwnerMap.containsKey(mchShare.Parent.Opportunity_Name__c) && mchShare.UserOrGroupId==atmOppOwnerMap.get(mchShare.Parent.Opportunity_Name__c))
					foundShare=true;
				
			} 
			// Check for Opp Contract Share match
			if (!foundShare && userOppMap.containsKey(mchShare.UserOrGroupId) && mchShare.Parent.Opportunity_Name__c!=null && 
				checkOccurence(userOppMap.get(mchShare.UserOrGroupId), mchShare.Parent.Opportunity_Name__c))
				{// Check if part of Associated Acc.ATM
					if(otmAccATMMap.size()>0 && otmAccATMMap.containsKey(mchShare.Parent.Account_Name__c)) // checks if Oppty matches and part of mchShare.Accout.ATM
					{
						for (Id atmId : otmAccATMMap.get(mchShare.Parent.Account_Name__c))
						{
							if (mchShare.UserOrGroupId==atmId)
							{
								foundShare=true;
								break;
							}
						}
					}
					// Check if Associated_Acc.Owner
					if (!foundShare && otmAccOwnerMap.size()>0 && otmAccOwnerMap.containsKey(mchShare.Parent.Account_Name__c) && mchShare.UserOrGroupId==otmAccOwnerMap.get(mchShare.Parent.Account_Name__c))
						foundShare=true;
					
						
					// Check if he is also part of OTM if Owner	
					if(!foundShare && atmOppOTMMap.size()>0 && atmOppOTMMap.containsKey(mchShare.Parent.Opportunity_Name__c))
					{
						for (Id otmId : atmOppOTMMap.get(mchShare.Parent.Opportunity_Name__c))
						{	
							if (mchShare.UserOrGroupId==otmId)
							{
								foundShare=true;
								break;
							}
						}
					}
				}
			
			
			// If associated user not part of any exception set remove Contract Access. 	
			if (!foundShare)
				removeMCHShareList.add(mchShare);
		}
		DMLResults deleteResults = new DMLResults();

		System.debug('System.debug: removeMCHShareList=' + removeMCHShareList);
		/*if (removeMCHShareList.size()>0)
			delete removeMCHShareList;*/

		//SFDC-2103 Hitesh:Adding Error Logging
			if(removeMCHShareList.size()>0)
	        {
	            deleteResults.add(Database.delete(removeMCHShareList,false),removeMCHShareList);
	            deleteResults.withClassName('ContractShareClass').insertRecordsInErrorLog();
	        }
		
		
		delContractShareFirstRunFlag=false;			
	}
}