/**
Developer: ALI KM
CR 1259743 Make Contracts: a parent-child with accounts?
- This class to add ATM/OTM members to MCHShare visibility table.
@History
    --Developer           --Date            --Change
    Ali KM                13/05/2013	CR 2210168 - ContractShare - Exception on bulk Updates to Merge_contract_Header object.
    -> Added check to ensure skipping of OTM processing if Oppty.OTM doesn't exist.        
*/
public global class MergeContractHeaderClass
{
	public static Boolean removeContractShareFirstRunFlag = true;
	public static Boolean removeMergeContractHeaderShareFirstRunFlag = true;
	public static Boolean addATMToContractShareFirstRunFlag = true;
	public static Boolean addOTMToContractShareFirstRunFlag = true;
	private static Map<Id,List<Id>> accATMUserMap = new Map<Id,List<Id>>();
	private static Map<Id,List<Id>> oppOTMUserMap = new Map<Id,List<Id>>();
	private static Set<Id> atmUserIdSet = new Set<Id>();
	private static Set<Id> otmUserIdSet = new Set<Id>();
	
	private static List<Id> removeMCHShareATMOTMUserList = new List<Id>(); 
	
	public static Contract_Share__c getATMCShareRecord(AccountTeamMember pATM)
	{
		Contract_Share__c tempATMCS = new Contract_Share__c();
		tempATMCS.Associated_Account__c = pATM.AccountId;
		tempATMCS.Associated_User__c = pATM.UserId;
		tempATMCS.ATM_OTM_SF_Id__c = pATM.Id;
		tempATMCS.RowCause__c = 'ATM/OTM';
	
	return tempATMCS;
	}
	// create ATM Contract_Share__c record from Account & User Ids & Return it.
	//Test
	public static Contract_Share__c getOwnerCShareRecord(Id pAccOpptyId, Id pOwnerId)
	{   
	   String tempStr = pAccOpptyId;
	   Contract_Share__c tempATMCS = new Contract_Share__c();
	   // check if attachment parent is Opportunity (006) or Order Approval (a0I) 
	        if (tempStr.startsWith(Schema.Sobjecttype.Opportunity.getKeyPrefix()))
	        {
		        tempATMCS.Associated_Opportunity__c = pAccOpptyId;
		        tempATMCS.RowCause__c = 'Owner';
	        }   
	        else if (tempStr.startsWith(Schema.Sobjecttype.Account.getKeyPrefix()))
	        {
		        tempATMCS.Associated_Account__c = pAccOpptyId;
		        tempATMCS.RowCause__c = 'Owner';
	        }
		tempATMCS.Associated_User__c = pOwnerId;
		// In case of Acc/Oppty owner concatenating accId - accOwnerId for ATM_OTM_SF_Id unique externalId. 
		tempATMCS.ATM_OTM_SF_Id__c = pAccOpptyId+':'+pOwnerId;
		
		return tempATMCS;
	}
	// create OTM Contract_Share__c record & return it
	//Test
	public static Contract_Share__c getOTMCShareRecord(OpportunityTeamMember pOTM)
	{
		Contract_Share__c tempOTMCS = new Contract_Share__c();
		tempOTMCS.Associated_Opportunity__c = pOTM.OpportunityId;
		tempOTMCS.Associated_User__c = pOTM.UserId;
		tempOTMCS.ATM_OTM_SF_Id__c = pOTM.Id;
		tempOTMCS.RowCause__c = 'ATM/OTM';
		
		return tempOTMCS;
	}
	// create Merge_Contract_Header__Share record & return it.
	//Test
	public static Merge_Contract_Header__Share getMCHShareRecord(Id pUserId, Id pContractId)
	{ 
		Merge_Contract_Header__Share tempMCHShare = new Merge_Contract_Header__Share();
		tempMCHShare.AccessLevel = 'Read';
		tempMCHShare.ParentId = pContractId;
		tempMCHShare.UserOrGroupId = pUserId;
		return tempMCHShare;
	}
	// remove atm/otm contract_share
	// if either acc or oppty is changing; remove all the entries in mchshare & cshare (RowCuase=Contract)
	// and add share again.
	//Test 
	public static String removeContractShare(Set<Id> pAccountIds, Set<Id> pOpportunityIds)
	{
		if(!removeContractShareFirstRunFlag)
		            return null;
		List<Contract_Share__c> toBeRemovedCShareList = new List<Contract_Share__c>();
		for (Contract_Share__c cShare : [SELECT Id, isContractTriggered__c, Associated_Account__c, Associated_Opportunity__c, Associated_User__c FROM Contract_Share__c 
		WHERE Associated_Account__c IN :pAccountIds OR Associated_Opportunity__c IN :pOpportunityIds])
		{
			cShare.isContractTriggered__c=true;
			toBeRemovedCShareList.add(cShare);
		}
		System.debug('toBeRemovedCShareList=' + toBeRemovedCShareList);
		if (toBeRemovedCShareList.size()>0)
		{
			delete toBeRemovedCShareList;
		}
		removeContractShareFirstRunFlag = false;
		return 'Successfully removed Contract_Share__c records, size=' + toBeRemovedCShareList;
	}
	//HC:Not being used any where so commenting

	
	/**
	@Name: removeMergeContractHeaderShare
	@Param1: Map<Id,Id> pMCHIdAccIdMap
	@Param2: Map<Id,Id> pMCHIdOppIdMap
	@comments: Chain of events in this method are below:
	a. Select Account, Account TeamMember active ones.
	map Acc, ATMList
	b. Loop thru contract - pMCHIDAccIdMap
	getAcc.ATMLIT
	mchATMToremoveMap.put(mch,ATM)
	c. Repeat same for Oppty, Oppty TeamMember active ones
	map Opp, OTMList
	d. Loop thru contract - ppMCHIDOppIdMap 
	getoppt.OTMList 
	mchOTMToremoveMap.put(mch,OTM)
	e. Merge it into one (mch, otm/atm)
	f. Pull all the MCHSHare records that qualify - Manual Share
	  > ParentID IN : mch.Keys()
	  -> UserORGroupid IN : mch.values()
	g. Check and delete MCHShare
	*/
	public static String removeMergeContractHeaderShare(Map<Id,Id> pMCHIdAccIdMap, Map<Id,Id> pMCHIdOppIdMap)
		{
			if(!removeMergeContractHeaderShareFirstRunFlag)
	        	return null;
			
			Map<Id, List<Id>> accATMListMap = new Map<Id, List<Id>>();
			Set<Id> atmAccIdSet = new Set<Id>();
			Set<Id> atmMCHIdSet = new Set<Id>();
			Map<Id, List<Id>> oppOTMListMap = new Map<Id, List<Id>>();
			Set<Id> otmOppIdSet = new Set<Id>();
			Set<Id> otmMCHIdSet = new Set<Id>();
			
			System.debug('pMCHIdAccIdMap=' + pMCHIdAccIdMap);	
			System.debug('pMCHIdOppIdMap=' + pMCHIdOppIdMap);			
					
			for (Account acc : [Select Id, Owner.IsActive, OwnerId, (Select Id, AccountId, UserId, TeamMemberRole, AccountAccessLevel, CreatedDate, CreatedById, 
				LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted From AccountTeamMembers WHERE User.UserType = 'Standard') //AND User.isActive=true AND IsDeleted=false 
					From Account WHERE Id IN : pMCHIdAccIdMap.values()])
					{	
						if (acc.AccountTeamMembers.size()>0)
							accATMListMap.put(acc.Id, getATMIds(acc.AccountTeamMembers));
						if (accATMListMap.containsKey(acc.Id))
							accATMListMap.get(acc.Id).add(acc.OwnerId);
						else
							accATMListMap.put(acc.Id, new List<Id> {acc.OwnerId});
							
							removeMCHShareATMOTMUserList.add(acc.OwnerId);	
						
					}
			System.debug('accATMListMap=' + accATMListMap);		
					
			for (Opportunity opp : [Select Id, Owner.IsActive, OwnerId, Account.OwnerId, Account.Owner.isActive, (Select Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel, CreatedDate, CreatedById,
				LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted From OpportunityTeamMembers WHERE User.UserType = 'Standard') //AND User.isActive=true AND IsDeleted=false
					From Opportunity WHERE Id IN : pMCHIdOppIdMap.values()])
					{
						if (opp.OpportunityTeamMembers.size()>0)
							oppOTMListMap.put(opp.Id, getOTMIds(opp.OpportunityTeamMembers, opp.Account.OwnerId));
							
						if (opp.OwnerId!=opp.Account.OwnerId) // check if ATM/Oppty Owner is also the Account Owner & Account Name = 
						{
							if (oppOTMListMap.containsKey(opp.Id))
								oppOTMListMap.get(opp.Id).add(opp.OwnerId);	
							else
								oppOTMListMap.put(opp.Id, new List<Id> {opp.OwnerId});
							removeMCHShareATMOTMUserList.add(opp.OwnerId);	
						}
							
					}
					
			System.debug('oppOTMListMap=' + oppOTMListMap);
			Map<Id, List<Id>> mchATMOTMMap = new Map<Id, List<Id>>(); 
			
			// merge it into one map (mch, otm/atm)
			//HC: Check for empty map
			
			if(!accATMListMap.isEmpty())
			{
				for (Id mchId : pMCHIdAccIdMap.keySet())
				{
					if (accATMListMap.containsKey(pMCHIdAccIdMap.get(mchId)))
					{
						if (mchATMOTMMap.containsKey(mchId))
						{
							mchATMOTMMap.get(mchId).addAll(accATMListMap.get(pMCHIdAccIdMap.get(mchId)));
						}
						else
							mchATMOTMMap.put(mchId, accATMListMap.get(pMCHIdAccIdMap.get(mchId)));
					}	
				}
			}
			if(!oppOTMListMap.isEmpty())
			{
				for (Id mchId : pMCHIdOppIdMap.keySet())
				{
					if(oppOTMListMap.containsKey(pMCHIdOppIdMap.get(mchId)))
					{
						if (mchATMOTMMap.containsKey(mchId))
						{
							mchATMOTMMap.get(mchId).addAll(oppOTMListMap.get(pMCHIdOppIdMap.get(mchId)));
						}
						else
							mchATMOTMMap.put(mchId,oppOTMListMap.get(pMCHIdOppIdMap.get(mchId))); 
					}
				}
			}
			
			if (mchATMOTMMap.isEmpty())
				return 'No ATM / OTM records found for removed Account / Opportunities on the Contract.';
				
			System.debug('removeMCHShareATMOTMUserList=' + removeMCHShareATMOTMUserList+'mchATMOTMMap=' + mchATMOTMMap+'mchATMOTMMap Keys MCH=' + mchATMOTMMap.keySet()+'mchATMOTMMap Values ATMOTM=' + mchATMOTMMap.values());
			
			
			List<Merge_Contract_Header__Share> removeMCHShareList = new List<Merge_Contract_Header__Share>(); 	
			
			for (Merge_Contract_Header__Share mchShare : [SELECT UserOrGroupId, ParentId, Id, AccessLevel, RowCause FROM Merge_Contract_Header__Share 
				WHERE  RowCause = 'Manual' AND UserOrGroupId IN :removeMCHShareATMOTMUserList AND ParentID IN :mchATMOTMMap.keySet()])
				{
					if (mchATMOTMMap.containsKey(mchShare.ParentId))
					{
						for (Id atmOTMId : mchATMOTMMap.get(mchShare.ParentId))
						{
							if (mchShare.UserOrGroupId == atmOTMId)
							{
								removeMCHShareList.add(mchShare);
								break;
							}	
						}
					}
				}
				
			System.debug('removeMCHShareList=' + removeMCHShareList);
			removeMergeContractHeaderShareFirstRunFlag = false;	
			
			DMLResults deleteResults = new DMLResults();


			if (removeMCHShareList.size()>0)
			{
				//delete removeMCHShareList;
				//HC: Should we consider deleting custom share record ??
				deleteResults.add(Database.delete(removeMCHShareList,false),removeMCHShareList);
		        deleteResults.withClassName('MergeContractHeaderClass').insertRecordsInErrorLog();
				return 'Successfully removed Merge Contract Header Share, size=' + removeMCHShareList;
			}		
			else
				return 'No Merge Contract Header Share records to remove.';	
		}

	//Test
	public static List<Id> getATMIds(List<AccountTeamMember> pATMList)
	{
			List<Id> atmIdList = new List<Id>(); 
			for (AccountTeamMember atm : pAtmList)
				{
					removeMCHShareATMOTMUserList.add(atm.UserId);
					atmIdList.add(atm.UserId);
				}
		return atmIdList;
	}
	//Test
	public static List<Id> getOTMIds(List<OpportunityTeamMember> pOTMList, Id pOpptyAccOwnerId)
	{
		List<Id> otmIdList = new List<Id>(); 
		for (OpportunityTeamMember otm : pOTMList)
		{
			if (otm.UserId!=pOpptyAccOwnerId)
			{
				removeMCHShareATMOTMUserList.add(otm.UserId);
				otmIdList.add(otm.UserId);
			}
		}
		return otmIdList;
	}
	public static void testMethod1(List<String> pIds)
	{
	 if (pIds.size()>0)
	   System.debug('pIds=' + pIds);
	}
	// entry for Merge_Contract_Header__c.Associated_Account_Id__c change.
	public static String addATMToContractShare(Merge_Contract_Header__c[] pMergeContractHeaderList, Set<Id> mchAccIdSet,Map<Id, Merge_Contract_Header__c> pMCHNewMap) 
	{
	if(!addATMToContractShareFirstRunFlag)
	            return null;
	   DMLResults upsertMCHShareResults = new DMLResults();
	   DMLResults upsertContractShareResults = new DMLResults();


	List<Contract_Share__c> createContractShareList = new List<Contract_Share__c>();
	
	if (mchAccIdSet.size()<1)
		return 'No qualifying MCH records';

	List<Account> mchAccountList = [Select Id, Owner.IsActive, OwnerId, (Select Id, AccountId, UserId, TeamMemberRole, AccountAccessLevel, CreatedDate, CreatedById, 
									LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted From AccountTeamMembers WHERE User.UserType = 'Standard' AND User.isActive=true AND IsDeleted=false) 
									From Account WHERE Id IN : mchAccIdSet];
	if (mchAccountList.size()<1)
		return '';
	List<Merge_Contract_Header__Share> mchShareList = new List<Merge_Contract_Header__Share>();
	List<Contract_Share__c> contractShareList = new List<Contract_Share__c>();
	Map<Id,Merge_Contract_Header__c> mchMap = pMCHNewMap;
	Map<Id,List<AccountTeamMember>> accATMListMap = new Map<Id,List<AccountTeamMember>>();
	Map<Id, AccountTeamMember> atmMap = new Map<Id, AccountTeamMember>();
	Map<Id,Id> atmAccOwnerIdMap = new Map<Id,Id>();
	for (Account acc : mchAccountList)
	{
		if (acc.Owner.IsActive)
			atmAccOwnerIdMap.put(acc.Id, acc.OwnerId);
		if (acc.AccountTeamMembers.size()>0)
			accATMListMap.put(acc.Id, acc.AccountTeamMembers);
	}
	// to ensure there are no duplicate Acc/Owner records are added to the Contract_Share storing using AccIdSet.
	Set<Id> tempAccIdSet = new Set<Id>();
	// create merge_contract_header__Share & Contract_Share__c records
	for (Merge_Contract_Header__c mch : pMergeContractHeaderList)
	{
		if (accATMListMap.size()>0)
		{
			if (!accATMListMap.containsKey(mch.Account_Name__c))
				continue;
			for (AccountTeamMember atm : accATMListMap.get(mch.Account_Name__c))
			{
				if (mch.OwnerId!=atm.UserId) //Add multiple CShare records for same user who is in ATM & Acct Owner.
				{
					mchShareList.add(getMCHShareRecord(atm.UserId,mch.Id));	// .get(atmId).AccountId
					contractShareList.add(getATMCShareRecord(atm));
				}
			}
		}
		// add Account Owner to the MCH & Contract Share
		if (atmAccOwnerIdMap.containsKey(mch.Account_Name__c) && mch.OwnerId!=atmAccOwnerIdMap.get(mch.Account_Name__c)) //&& !tempAccIdSet.contains(mch.Account_Name__c))
		{
			mchShareList.add(getMCHShareRecord(atmAccOwnerIdMap.get(mch.Account_Name__c),mch.Id));	// .get(atmId).AccountId
			if (!tempAccIdSet.contains(mch.Account_Name__c))
					contractShareList.add(getOwnerCShareRecord(mch.Account_Name__c,atmAccOwnerIdMap.get(mch.Account_Name__c)));
			tempAccIdSet.add(mch.Account_Name__c);
		}
	}
	System.debug('tempAccIdSet=' + tempAccIdSet +'mchShareList Size=' + contractShareList.size() + 'mchShareList=' + contractShareList+'contractShareList Size=' + contractShareList.size()+'contractShareList=' + contractShareList);
	
	String strReturnMessage = 'No MCH rows qualified for sharing.';

	if (mchShareList.size()>0)
	{
	//HC:Added error logging 
	//upsert mchShareList;
	           upsertMCHShareResults.add(Database.upsert(mchShareList,false), mchShareList);
	           upsertMCHShareResults.withClassName('MergeContractHeaderClass').insertRecordsInErrorLog();
	       
				strReturnMessage = 'mchShare was successfully updated for following records: ' + mchShareList + '/n';
	}

	if (contractShareList.size()>0)
		{

			//Set<Contract_Share__c> contractShareSet = new Set<Contract_Share__c>();
			Set<Contract_Share__c> contractShareSet = new Set<Contract_Share__c>(contractShareList);
			System.debug('strSet=' + contractShareSet);

			contractShareList.clear();
			System.debug('strList=' + contractShareList);
			contractShareList.addAll(contractShareSet);
			System.debug('strList=' + contractShareList);
			//HC:Error logging-commenting upsert
			//upsert contractShareList ATM_OTM_SF_Id__c;
			upsertContractShareResults.add(Database.upsert(contractShareList,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractShareList);
			upsertContractShareResults.withClassName('MergeContractHeaderClass').insertRecordsInErrorLog();
			strReturnMessage += 'contractShare was successfully updated for following records: ' + contractShareList + '/n';
			
		}
		System.debug('strReturnMessage=' + strReturnMessage);
		addATMToContractShareFirstRunFlag = false;
		return strReturnMessage;
	}
	// entry for Merge_Contract_Header__c.Associated_Opportunity_Id__c change.
	public static String addOTMToContractShare(Merge_Contract_Header__c[] pMergeContractHeaderList, Set<Id> mchOpptyIdSet,Map<Id, Merge_Contract_Header__c> pMCHNewMap) 
	{
		if(!addOTMToContractShareFirstRunFlag)
		            return null;
		    DMLResults upsertMCHShareResults = new DMLResults();
		    DMLResults upsertContractShareResults = new DMLResults();

		List<Contract_Share__c> createContractShareList = new List<Contract_Share__c>();
		
		if (mchOpptyIdSet.size()<1)
			return 'No qualifying MCH records';
		//mchAccountList
		List<Opportunity> mchOpportunityList =  [Select Id, Owner.IsActive, OwnerId, (Select Id, OpportunityId, UserId, TeamMemberRole, OpportunityAccessLevel, CreatedDate, CreatedById,
												 LastModifiedDate, LastModifiedById, SystemModstamp, IsDeleted From OpportunityTeamMembers WHERE User.UserType = 'Standard' AND User.isActive=true AND IsDeleted=false)
		  										 From Opportunity WHERE Id IN : mchOpptyIdSet];
		if (mchOpportunityList.size()<1)
			return '';
		List<Merge_Contract_Header__Share> mchShareList = new List<Merge_Contract_Header__Share>();
		List<Contract_Share__c> contractShareList = new List<Contract_Share__c>();
		Map<Id,Merge_Contract_Header__c> mchMap = pMCHNewMap;
		Map<Id,List<OpportunityTeamMember>> oppOTMListMap = new Map<Id,List<OpportunityTeamMember>>();
		Map<Id, OpportunityTeamMember> otmMap = new Map<Id, OpportunityTeamMember>();
		Map<Id,Id> otmOppOwnerIdMap = new Map<Id,Id>();
		for (Opportunity opp : mchOpportunityList)
		{
			if (opp.Owner.IsActive)
				otmOppOwnerIdMap.put(opp.Id, opp.OwnerId);
			if (opp.OpportunityTeamMembers.size()>0)
				oppOTMListMap.put(opp.Id, opp.OpportunityTeamMembers);
		}
		Set<Id> tempOppIdSet = new Set<Id>();
		// create merge_contract_header__Share & Contract_Share__c records
		for (Merge_Contract_Header__c mch : pMergeContractHeaderList)
		{
			if (oppOTMListMap.size()>0)
			{
				if (!oppOTMListMap.containsKey(mch.Opportunity_Name__c))
					continue;
				for (OpportunityTeamMember otm : oppOTMListMap.get(mch.Opportunity_Name__c))
				{
					//if (mch.OwnerId!=otm.UserId && otmOppOwnerIdMap.get(mch.Opportunity_Name__c)!=otm.UserId)
					if (mch.OwnerId!=otm.UserId) //Add multiple CShare records for same user who is in ATM & Acct Owner.
					{
						mchShareList.add(getMCHShareRecord(otm.UserId,mch.Id));
						contractShareList.add(getOTMCShareRecord(otm));
					}
				}
			}
			// add Account Owner to the MCH & Contract Share
			if (otmOppOwnerIdMap.containsKey(mch.Opportunity_Name__c) && mch.OwnerId!=otmOppOwnerIdMap.get(mch.Opportunity_Name__c) && !tempOppIdSet.contains(mch.Opportunity_Name__c))
			{
				tempOppIdSet.add(mch.Opportunity_Name__c);
				mchShareList.add(getMCHShareRecord(otmOppOwnerIdMap.get(mch.Opportunity_Name__c),mch.Id));	// .get(atmId).AccountId
				contractShareList.add(getOwnerCShareRecord(mch.Opportunity_Name__c,otmOppOwnerIdMap.get(mch.Opportunity_Name__c)));
			}
		}

		System.debug('tempOppIdSet=' + tempOppIdSet);
		System.debug('contractShareList=' + contractShareList);

		String strReturnMessage = 'No MCH rows qualified for sharing.';
		if (mchShareList.size()>0)
			{
			//upsert mchShareList;
				upsertMCHShareResults.add(Database.upsert(mchShareList,false), mchShareList);
				upsertMCHShareResults.withClassName('MergeContractHeaderClass').insertRecordsInErrorLog();
				strReturnMessage = 'mchShare was successfully updated for following records: ' + mchShareList + '/n';
		}
		if (contractShareList.size()>0)
		{

			Set<Contract_Share__c> contractShareSet = new Set<Contract_Share__c>(contractShareList);
			
			contractShareList.clear();
			contractShareList.addAll(contractShareSet);
			
			upsertContractShareResults.add(Database.upsert(contractShareList,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractShareList);
			upsertContractShareResults.withClassName('MergeContractHeaderClass').insertRecordsInErrorLog();
			strReturnMessage += 'contractShare was successfully updated for following records: ' + contractShareList + '/n';
		}
			System.debug('strReturnMessage=' + strReturnMessage);
			addOTMToContractShareFirstRunFlag = false;
			return strReturnMessage;
		}
}