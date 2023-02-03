/*

SFDC-5912
Class to handle all the operations around Manual Contract Sharing from
Account
Opportunity
Contract
*/

public class ContractSharing 

{	
	
	
	public static Boolean upsertOTMContractSharesFirstRunFlag = true;
	public static Boolean upsertATMContractSharesFirstRunFlag = true;
	public static Boolean addATMToContractShareFirstRunFlag = true;
	public static Boolean addOTMToContractShareFirstRunFlag = true;
	public static Boolean addMergeContractHeaderShareFirstRunFlag = true;
	public static Boolean removeMergeContractHeaderShareFirstRunFlag = true;

	public static Boolean removeATMOTMShareOnAccOpptyUpdateFirstRunFlag = true;

	public static Boolean deleteContractSharesFirstRunFlag = true;
	public static Boolean updateOpptyOwnerContractShareFirstRunFlag = true;
	public static Boolean updateAccountOwnerContractShareFirstRunFlag = true;

	


   
	
	public ContractSharing() {}

	//Method 1 - Called from AccountTeammember Trigger on Insert of ATM
	public static void upsertATMContractShares(Map<Id,List<AccountTeamMember>> accountIdToATMListMap)
    {
        System.Debug(Logginglevel.Error, 'HC_D before first run');
        if(!upsertATMContractSharesFirstRunFlag)
            return;
		Map<Id,List<Id>> acountIdToContractIdListMap = new Map<Id,List<Id>>();
		List<Contract_Share__c> contractSharesToBeUpserted= new List<Contract_Share__c>();
		DMLResults upsertContractShareResults = new DMLResults();

		//Get all the Contracts associated to Account,build map of Account to List of Contracts
		for( Merge_Contract_Header__c mchS : [Select Id, Account_Name__c FROM Merge_Contract_Header__c WHERE Account_Name__c IN :accountIdToATMListMap.keySet()])
		{
			if(!acountIdToContractIdListMap.containsKey(mchS.Account_Name__c))
			{
				List<Id> contractIdListTemp = new List<Id>();
				contractIdListTemp.add(mchS.Id);
				acountIdToContractIdListMap.put(mchS.Account_Name__c,contractIdListTemp);
			}
			else{
				List<Id> contractIdListTemp = acountIdToContractIdListMap.get(mchS.Account_Name__c);
				contractIdListTemp.add(mchS.Id);
				acountIdToContractIdListMap.put(mchS.Account_Name__c,contractIdListTemp);
			}
		}
	System.Debug(Logginglevel.Error, 'HC_D before first run Map 1 '+accountIdToATMListMap + 'map 2 '+acountIdToContractIdListMap);

	//Go through each Account,for each related Contract create new Contract Share 
	if(!acountIdToContractIdListMap.isEmpty())
		{
			for(Id accountId : acountIdToContractIdListMap.keySet())
			{
				if(!accountIdToATMListMap.isEmpty() && accountIdToATMListMap.containsKey(accountId))
				{
					for(AccountTeamMember atm : accountIdToATMListMap.get(accountId))
					{
						for(Id contractId : acountIdToContractIdListMap.get(accountId))
						{
							contractSharesToBeUpserted.add(new Contract_Share__c(
									Associated_User__c=atm.UserId, 
									Associated_Account__c=atm.AccountId, 
									Parent_Contract__c = contractId,
									ATM_OTM_SF_Id__c = contractId+':'+atm.Id,
									RowCause__c = 'ATM/OTM'));
						}
					}
				}
			}
		}

        if(contractSharesToBeUpserted.size()>0)
        {
            System.debug(Logginglevel.ERROR,'HC_D enteredd'+contractSharesToBeUpserted);
            upsertContractShareResults.add(Database.upsert(contractSharesToBeUpserted,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractSharesToBeUpserted);
            upsertContractShareResults.withClassName('ContractSharing').insertRecordsInErrorLog();
            
        }

        upsertATMContractSharesFirstRunFlag=false;
    }
	//Method 2 - Called from OpportunityTemMember Trigger on addition of new OTM
	public static void upsertOTMContractShares(Map<Id,List<OpportunityTeamMember>> opptyIdToOTMListMap)
    {
        System.Debug(Logginglevel.Error, 'HC_D before first run');
        if(!upsertOTMContractSharesFirstRunFlag)
            return;
		Map<Id,List<Id>> opptyIdToContractIdListMap = new Map<Id,List<Id>>();
		List<Contract_Share__c> contractSharesToBeUpserted= new List<Contract_Share__c>();
		DMLResults upsertContractShareResults = new DMLResults();

		//Get all the associated Contracts of the Opportunity and populate Map of Opportunity to List of Contract
		for( Merge_Contract_Header__c mchS : [Select Id, Opportunity_Name__c FROM Merge_Contract_Header__c WHERE Opportunity_Name__c IN :opptyIdToOTMListMap.keySet()])
		{
			if(!opptyIdToContractIdListMap.containsKey(mchS.Opportunity_Name__c))
			{
				List<Id> contractIdListTemp = new List<Id>();
				contractIdListTemp.add(mchS.Id);
				opptyIdToContractIdListMap.put(mchS.Opportunity_Name__c,contractIdListTemp);
			}
			else{
				List<Id> contractIdListTemp = opptyIdToContractIdListMap.get(mchS.Opportunity_Name__c);
				contractIdListTemp.add(mchS.Id);
				opptyIdToContractIdListMap.put(mchS.Opportunity_Name__c,contractIdListTemp);
			}
		}
	System.Debug(Logginglevel.Error, 'HC_D before first run Map 1 '+opptyIdToOTMListMap + 'map 2 '+opptyIdToContractIdListMap);

	//Go through each Opportunity and create a new share record for all new OTMs for associated Contracts
	if(!opptyIdToContractIdListMap.isEmpty())
		{
			for(Id opptyid : opptyIdToContractIdListMap.keySet())
			{
				if(!opptyIdToOTMListMap.isEmpty() && opptyIdToOTMListMap.containsKey(opptyid))
				{
					for(OpportunityTeamMember otm : opptyIdToOTMListMap.get(opptyid))
					{
						for(Id contractId : opptyIdToContractIdListMap.get(opptyid))
						{
							contractSharesToBeUpserted.add(new Contract_Share__c(
									Associated_User__c=otm.UserId, 
									Associated_Opportunity__c=otm.OpportunityId, 
									Parent_Contract__c = contractId,
									ATM_OTM_SF_Id__c = contractId+':'+otm.Id,
									RowCause__c = 'ATM/OTM'));
						}
					}
				}
			}
		}
		
		if(contractSharesToBeUpserted.size()>0)
        {
            System.debug(Logginglevel.ERROR,'HC_D enteredd');
            upsertContractShareResults.add(Database.upsert(contractSharesToBeUpserted,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractSharesToBeUpserted);
            upsertContractShareResults.withClassName('ContractSharing').insertRecordsInErrorLog();
            
        }
		upsertOTMContractSharesFirstRunFlag=false;
    }

// Method 3 - Called from Contract Trigger - Add all new Account's ATM and Account Owner
	public static void addATMToContractShare(Merge_Contract_Header__c[] pMergeContractHeaderList, Set<Id> mchAccIdSet,Map<Id, Merge_Contract_Header__c> pMCHNewMap) 
	{
	if(!addATMToContractShareFirstRunFlag)
	            return ;
	DMLResults upsertContractShareResults = new DMLResults();
	List<Contract_Share__c> contractSharesToBeUpserted= new List<Contract_Share__c>();
	List<Account> mchAccountList = new List<Account>();
	//String invalidAlias = GsmUtilClass.getGSMSettingValue('ATMOTMInvalidUserAlias');
	//Get all the Account details along with AccountTeamMembers -Standard Active User
	if(mchAccIdSet.size()>0)
	{
		mchAccountList = [Select Id, Owner.IsActive, OwnerId, 
									(Select Id, AccountId, UserId From AccountTeamMembers WHERE User.UserType = 'Standard' AND User.isActive=true AND IsDeleted=false) 
									From Account WHERE Id IN : mchAccIdSet];
	}
	
	Map<Id,List<AccountTeamMember>> accATMListMap = new Map<Id,List<AccountTeamMember>>();
	Map<Id,Id> atmAccOwnerIdMap = new Map<Id,Id>();
	//Populate Account to Owner and list of ATMs Map
	for (Account acc : mchAccountList)
	{
		if (acc.Owner.IsActive)// && !invalidAlias.contains(acc.Owner.Alias))
			atmAccOwnerIdMap.put(acc.Id, acc.OwnerId);
		if (acc.AccountTeamMembers.size()>0)
			accATMListMap.put(acc.Id, acc.AccountTeamMembers);
	}

	Set<Id> tempAccIdSet = new Set<Id>();
	// Create Contract Shares for all the ATMs of Account and it's Owner under associated Contracts
	for (Merge_Contract_Header__c mch : pMergeContractHeaderList)
	{
		if (!accATMListMap.isEmpty() && accATMListMap.containsKey(mch.Account_Name__c))
				{
					for (AccountTeamMember atm : accATMListMap.get(mch.Account_Name__c))
					{
						if (mch.OwnerId!=atm.UserId) //Do not Add multiple CShare records for same user who is in ATM/Owner & Contract Owner.
						{
							contractSharesToBeUpserted.add(new Contract_Share__c(
										Associated_User__c=atm.UserId, 
										Associated_Account__c=atm.AccountId, 
										Parent_Contract__c = mch.Id,
										ATM_OTM_SF_Id__c = mch.Id+':'+atm.Id,
										RowCause__c = 'ATM/OTM'));
						}
					}
				}
		

		if(!atmAccOwnerIdMap.isEmpty() && atmAccOwnerIdMap.containsKey(mch.Account_Name__c))
			{
				Id ownerID = atmAccOwnerIdMap.get(mch.Account_Name__c);
			
				if (mch.OwnerId!=ownerID) 
				{
					contractSharesToBeUpserted.add(new Contract_Share__c(
	                            Associated_User__c=ownerID, 
	                            Associated_Account__c= mch.Account_Name__c, 
	                            Parent_Contract__c = mch.Id,
								ATM_OTM_SF_Id__c = mch.Id+':'+mch.Account_Name__c+':'+ownerID,
								RowCause__c = 'Owner'));
				}
			}
		
	}
	if (contractSharesToBeUpserted.size()>0)
		{
			upsertContractShareResults.add(Database.upsert(contractSharesToBeUpserted,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractSharesToBeUpserted);
            upsertContractShareResults.withClassName('ContractSharing').insertRecordsInErrorLog();
		}
		addATMToContractShareFirstRunFlag = false;
	}

	// Method 4 - Called from Contract Trigger - Add all new Opportunity's OTM and Opportunity Owner

	public static void addOTMToContractShare(Merge_Contract_Header__c[] pMergeContractHeaderList, Set<Id> mchOpptyIdSet,Map<Id, Merge_Contract_Header__c> pMCHNewMap) 
	{
	if(!addOTMToContractShareFirstRunFlag)
	            return ;
	DMLResults upsertContractShareResults = new DMLResults();
	List<Contract_Share__c> contractSharesToBeUpserted= new List<Contract_Share__c>();
	List<Opportunity> mchOpptyList = new List<Opportunity>();
	//Get all the Opportunity details along with OpportunityTeamMembers -Standard Active User

	if(mchOpptyIdSet.size() > 0)
	{
		mchOpptyList = [Select Id, Owner.IsActive, OwnerId, 
									(Select Id, OpportunityId, UserId From OpportunityTeamMembers WHERE User.UserType = 'Standard' AND User.isActive=true AND IsDeleted=false) 
									From Opportunity WHERE Id IN : mchOpptyIdSet];
	
	}

	Map<Id,List<OpportunityTeamMember>> opptyOTMListMap = new Map<Id,List<OpportunityTeamMember>>();
	Map<Id,Id> otmOpptyOwnerIdMap = new Map<Id,Id>();
 	//Populate Account to Owner and list of ATMs Map

	for (Opportunity opp : mchOpptyList)
	{
		/*if (opp.Owner.IsActive)
			otmOpptyOwnerIdMap.put(opp.Id, opp.OwnerId);*/
		if (opp.OpportunityTeamMembers.size()>0)
			opptyOTMListMap.put(opp.Id, opp.OpportunityTeamMembers);
	}
	Set<Id> tempOppIdSet = new Set<Id>();
	// Create Contract Shares for all the OTMs of Oportunity and it's Owner under associated Contracts

	for (Merge_Contract_Header__c mch : pMergeContractHeaderList)
	{
		if (!opptyOTMListMap.isEmpty() && opptyOTMListMap.containsKey(mch.Opportunity_Name__c))
			{	
				for (OpportunityTeamMember otm : opptyOTMListMap.get(mch.Opportunity_Name__c))
				{
					if (mch.OwnerId!=otm.UserId) 
					{
						contractSharesToBeUpserted.add(new Contract_Share__c(
									Associated_User__c=otm.UserId, 
									Associated_Opportunity__c =otm.OpportunityId, 
									Parent_Contract__c = mch.Id,
									ATM_OTM_SF_Id__c = mch.Id+':'+otm.Id,
									RowCause__c = 'ATM/OTM'));
					}
				}
			}
		
		/*if(!otmOpptyOwnerIdMap.isEmpty() && otmOpptyOwnerIdMap.containsKey(mch.Opportunity_Name__c))
			{
				Id ownerID = otmOpptyOwnerIdMap.get(mch.Opportunity_Name__c);
			
				if (mch.OwnerId!=ownerID) 
				{
					contractSharesToBeUpserted.add(new Contract_Share__c(
	                            Associated_User__c=ownerID, 
	                            Associated_Opportunity__c = mch.Opportunity_Name__c, 
	                            Parent_Contract__c = mch.Id,
								ATM_OTM_SF_Id__c = mch.Id+':'+mch.Opportunity_Name__c+':'+ownerID,
								RowCause__c = 'Owner'));
				}
			}*/
		
	}
		

	if (contractSharesToBeUpserted.size()>0)
		{

	    	upsertContractShareResults.add(Database.upsert(contractSharesToBeUpserted,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractSharesToBeUpserted);
            upsertContractShareResults.withClassName('ContractSharing').insertRecordsInErrorLog();
		
		}
		addOTMToContractShareFirstRunFlag = false;
	}

	//Method 5 - Called from ContractShareChangeTrigger to add all the new Insert Contract Share to MergeContractShare 
	public static void addMergeContractHeaderShare(Set<id> contractShareIdList)

	{
		/*if(!addMergeContractHeaderShareFirstRunFlag)
            return;*/
		List<Merge_Contract_Header__Share> mchsToBeUpserted = new List<Merge_Contract_Header__Share>();
		DMLResults upsertMCHSResults = new DMLResults();

		List<Contract_Share__c> csRecList = [Select Id,Parent_Contract__c,Associated_Opportunity__c,Associated_Account__c,ATM_OTM_SF_Id__c,Associated_User__c From Contract_Share__c Where Id IN :contractShareIdList ];
		System.debug('Inserted Record ' +csRecList);
		for(Contract_Share__c csRec : csRecList)
		{
			mchsToBeUpserted.add(new Merge_Contract_Header__Share(
									AccessLevel = 'Read',
									ParentId = csRec.Parent_Contract__c,
									UserOrGroupId = csRec.Associated_User__c
	                            ));
		}
		system.debug('Inerted Records via Event  '+mchsToBeUpserted);
		if(mchsToBeUpserted.size()>0)
			{
				upsertMCHSResults.add(Database.upsert(mchsToBeUpserted,false), mchsToBeUpserted);
        		upsertMCHSResults.withClassName('ContractSharing').insertRecordsInErrorLog();
			}
		//addMergeContractHeaderShareFirstRunFlag = false;

	}
	//Method 6 - Called from ContractShareChangeTrigger to remove all the old Contract Share from MergeContractShare 

	public static void removeMergeContractHeaderShare(List<String> contractShareIdList)

	{
		/*if(!removeMergeContractHeaderShareFirstRunFlag)
            return;*/
		
		List<Merge_Contract_Header__Share> mchsToBeDeleted = new List<Merge_Contract_Header__Share>();
		DMLResults deleteMCHSResults = new DMLResults();
		Set<Id> parentContractIdSet = new Set<Id>();
		Map<Id,Set<Id>> parentContractToUserIdMap = new Map<Id,Set<Id>>();

		system.debug('To remove Share list '+contractShareIdList);
		//Get all the rows delted from Contract Share reocrd and populate map of Contratc to User List
		for(Contract_Share__c cs: [Select Id,Parent_Contract__c,Associated_Opportunity__c,Associated_Account__c,ATM_OTM_SF_Id__c,Associated_User__c From Contract_Share__c Where Id IN :contractShareIdList ALL ROWS ])
		{
			parentContractIdSet.add(cs.Parent_Contract__c);
			if(!parentContractToUserIdMap.containsKey(cs.Parent_Contract__c))
			{
				Set<Id> userTempId = new Set<Id>();
				userTempId.add(cs.Associated_User__c);
				parentContractToUserIdMap.put(cs.Parent_Contract__c,userTempId);
			}
			else {
				Set<Id> userTempId = parentContractToUserIdMap.get(cs.Parent_Contract__c);
				userTempId.add(cs.Associated_User__c);
				parentContractToUserIdMap.put(cs.Parent_Contract__c,userTempId);
			}
		}

		Map<Id,Set<Id>> removeParentContractToCSUserSetMap = new Map<Id,Set<Id>>();
		Set<Id> userIdToBeRemoved = new Set<Id>();
		//Get all existing Manual Contract Share for referenced Contracts and remove the ones which are still part of Share Records
		for(Contract_Share__c cs: [Select Id,Parent_Contract__c,Associated_User__c From Contract_Share__c Where Parent_Contract__c IN :parentContractIdSet ])
		{
			if(parentContractToUserIdMap.containsKey(cs.Parent_Contract__c) && parentContractToUserIdMap.get(cs.Parent_Contract__c).contains(cs.Associated_User__c))
			{
				
				Set<Id> updatedSet = parentContractToUserIdMap.get(cs.Parent_Contract__c);
				updatedSet.remove(cs.Associated_User__c);
				parentContractToUserIdMap.put(cs.Parent_Contract__c,updatedSet);

			}
			
		}
		system.debug('Parent to User map '+parentContractToUserIdMap);
		
		//Get All the Actual ContractShare records to be Deleted
		for(Merge_Contract_Header__Share mchs : [Select Id,UserOrGroupId,ParentId From Merge_Contract_Header__Share where ParentId IN :parentContractToUserIdMap.keySet()])
		{
			if(parentContractToUserIdMap.containsKey(mchs.ParentId) && parentContractToUserIdMap.get(mchs.ParentId).contains(mchs.UserOrGroupId))
				mchsToBeDeleted.add(mchs);
		}
		if(mchsToBeDeleted.size()>0)
			{
				deleteMCHSResults.add(Database.delete(mchsToBeDeleted,false), mchsToBeDeleted);
        		deleteMCHSResults.withClassName('ContractSharing').insertRecordsInErrorLog();
			}
		//removeMergeContractHeaderShareFirstRunFlag = false;

	}
	//Method 7 - Called from Account/OpportunityTeamMember Trigger 
	public static void deleteATMOTMContractShares(Map<Id,Id> accountIDtoATMIdMap,Map<Id,Id> opptyIDtoATMIdMap)
    {
        if(!deleteContractSharesFirstRunFlag)
            return;
		Set<String> atmOTMId = new Set<String>();
        DMLResults delContractShareResults = new DMLResults();
		List<Contract_Share__c> contractSharesToBeDeleted = new list<Contract_Share__c>();
		if(!accountIDtoATMIdMap.isEmpty() && accountIDtoATMIdMap.size()>0)
		{
			for( Merge_Contract_Header__c mchS : [Select Id, Account_Name__c FROM Merge_Contract_Header__c WHERE Account_Name__c IN :accountIDtoATMIdMap.keySet()])
			{
				atmOTMId.add(mchS.Id+':'+accountIDtoATMIdMap.get(mchS.Account_Name__c));
			}
		}
		if(!opptyIDtoATMIdMap.isEmpty() && opptyIDtoATMIdMap.size() > 0)
		{
			for( Merge_Contract_Header__c mchS : [Select Id, Opportunity_Name__c FROM Merge_Contract_Header__c WHERE Opportunity_Name__c IN :opptyIDtoATMIdMap.keySet()])
			{
				atmOTMId.add(mchS.Id+':'+opptyIDtoATMIdMap.get(mchS.Opportunity_Name__c));
			}
		}

		system.debug('Delete ATMs '+atmOTMId);
		if(!atmOTMId.isEmpty())
		{
			contractSharesToBeDeleted = [select id from Contract_Share__c where ATM_OTM_SF_Id__c in :atmOTMId];
		}
		system.debug('Delete ATMs  CS'+contractSharesToBeDeleted);

        if(contractSharesToBeDeleted.size()>0)
        {
            delContractShareResults.add(Database.delete(contractSharesToBeDeleted,false), contractSharesToBeDeleted);
            delContractShareResults.withClassName('ContractSharing').insertRecordsInErrorLog();
            
        }

        deleteContractSharesFirstRunFlag=false;
    }

	// Method 8 - Called from Account Trigger  when Account Owner is changed.
	@future
	public static void updateAccountOwnerContractShare(List<Id> ownerChangeRecordIds)
	{
		if(!updateAccountOwnerContractShareFirstRunFlag)
            return;
		Map<Id, Id> newAccOwnerMap = new Map<Id,Id>();
        //Map<Id, Id> oldAccOwnerMap = new Map<Id,Id>();
		//Set<String> oldAccOwnerSet = new Set<String>();
		DMLResults deleteResults = new DMLResults();
        
		Map<Id,List<Id>> acountIdToContractIdListMap = new Map<Id,List<Id>>();
		List<Contract_Share__c> contractSharesToBeUpserted= new List<Contract_Share__c>();
		DMLResults upsertContractShareResults = new DMLResults();
		Map<Id,List<AccountTeamMember>> accATMListMap = new Map<Id,List<AccountTeamMember>>();
		List<Id> contractListId = new List<Id>();
	    
		for (Account acc : [select Id, OwnerId, Old_Account_Owner__c, (Select Id, AccountId, UserId From AccountTeamMembers WHERE User.UserType = 'Standard' AND User.isActive=true AND IsDeleted=false) 
 from Account where Id IN : ownerChangeRecordIds])
		{	
			newAccOwnerMap.put(acc.Id, acc.OwnerId);
            //oldAccOwnerMap.put(acc.Id, acc.Old_Account_Owner__c);
            if (acc.AccountTeamMembers.size()>0)
				accATMListMap.put(acc.Id, acc.AccountTeamMembers);
		}
		system.debug('New Acc Map '+newAccOwnerMap);
		if(!newAccOwnerMap.isEmpty())
		{
			
			for(Merge_Contract_Header__c  mchS : [Select Id, Account_Name__c FROM Merge_Contract_Header__c WHERE Account_Name__c IN :newAccOwnerMap.keySet()])
			{
				//Formualte Key for removal of Owner Share 
				/*if(oldAccOwnerMap.containsKey(mchS.Account_Name__c))
					oldAccOwnerSet.add(mchS.Id+':'+mchS.Account_Name__c+':'+ oldAccOwnerMap.get(mchS.Account_Name__c));*/
				//system.debug('Old Acc Map '+oldAccOwnerSet);
				//Populate Map of account to Associated Contracts
				if(!acountIdToContractIdListMap.containsKey(mchS.Account_Name__c))
				{
					List<Id> contractIdListTemp = new List<Id>();
					contractIdListTemp.add(mchS.Id);
					acountIdToContractIdListMap.put(mchS.Account_Name__c,contractIdListTemp);
                    contractListId.add(mchS.Id);
				}
				else
				{
					List<Id> contractIdListTemp = acountIdToContractIdListMap.get(mchS.Account_Name__c);
					contractIdListTemp.add(mchS.Id);
					acountIdToContractIdListMap.put(mchS.Account_Name__c,contractIdListTemp);
                    contractListId.add(mchS.Id);
				}
			}
			system.debug('Acc to Contract '+acountIdToContractIdListMap);
			//For Each Associated Contract to Account, create  a Share record for Owner
			if(!acountIdToContractIdListMap.isEmpty())
				{
					for(Id accountId : acountIdToContractIdListMap.keySet())
					{
						if(!newAccOwnerMap.isEmpty() && newAccOwnerMap.containsKey(accountId))
						{
							for(Id contractId : acountIdToContractIdListMap.get(accountId))
							{
								contractSharesToBeUpserted.add(new Contract_Share__c(
										Associated_User__c=newAccOwnerMap.get(accountId), 
										Associated_Account__c=accountId, 
										Parent_Contract__c = contractId,
										ATM_OTM_SF_Id__c = contractId+':'+accountId+':'+newAccOwnerMap.get(accountId),
										RowCause__c = 'Owner'));
                                if(!accATMListMap.isEmpty() && accATMListMap.containsKey(accountId))
                                {
                                    for(AccountTeamMember atm : accATMListMap.get(accountId))
                                       {
                                           contractSharesToBeUpserted.add(new Contract_Share__c(
                                                Associated_User__c=atm.UserId, 
                                                Associated_Account__c=atm.AccountId, 
                                                Parent_Contract__c = contractId,
                                                ATM_OTM_SF_Id__c = contractId+':'+atm.Id,
                                                RowCause__c = 'ATM/OTM'));
                                       }
                                }
                            }
                        
						}
                        
					}
				}
		}

		List<Contract_Share__c> removeCShareList = new List<Contract_Share__c>();

		//Delete Share for older Account Owners
		//if (oldAccOwnerSet.size()>0)
		//{
			//System.debug('oldAccOwnerSet ACC=' + oldAccOwnerSet);
            if(!acountIdToContractIdListMap.isEmpty() && contractListId.size()>0)
            {
                for (Contract_Share__c cShare : [SELECT Id, ATM_OTM_SF_Id__c,Parent_Contract__c FROM Contract_Share__c WHERE Associated_Account__c IN :acountIdToContractIdListMap.keyset() AND Parent_Contract__c IN :contractListId ])
            	{
                    //if(oldAccOwnerSet.contains(cShare.ATM_OTM_SF_Id__c))
                    	//removeCShareList.add(cShare);
                    removeCShareList.add(cShare);  
                    }
            	}
            //}
			/*for (Contract_Share__c cShare : [SELECT Id, ATM_OTM_SF_Id__c FROM Contract_Share__c WHERE ATM_OTM_SF_Id__c IN :oldAccOwnerSet])
			{
				removeCShareList.add(cShare);	
			}*/
			System.debug('removeCShareList=' + removeCShareList);
			if(removeCShareList.size()>0)
	        {
	            deleteResults.add(Database.delete(removeCShareList, false), removeCShareList);
	            deleteResults.withClassName('ContractSharing').insertRecordsInErrorLog();
	        }
		
		
		
		

		if(contractSharesToBeUpserted.size()>0)
			{
				System.debug(Logginglevel.ERROR,'HC_D enteredd');
				upsertContractShareResults.add(Database.upsert(contractSharesToBeUpserted,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractSharesToBeUpserted);
				upsertContractShareResults.withClassName('ContractSharing').insertRecordsInErrorLog();
				
			}
		
		
		
		updateAccountOwnerContractShareFirstRunFlag = false;
	}

	//Method 9 -  Called from Opportunity Trigger when Opportunity Owner is changed.
	public static void updateOpptyOwnerContractShare(List<Opportunity> pToUpdateOppList, Map<Id,Opportunity> pOppOldMap)
	{ 
		/*if(!updateOpptyOwnerContractShareFirstRunFlag)
            return;
		Map<Id, Id> newOppOwnerMap = new Map<Id,Id>();
		Set<String> oldOppOwnerSet = new Set<String>();
		DMLResults deleteResults = new DMLResults();
		
		Map<Id,List<Id>> opptyIdToContractIdListMap = new Map<Id,List<Id>>();
		List<Contract_Share__c> contractSharesToBeUpserted= new List<Contract_Share__c>();
		DMLResults upsertContractShareResults = new DMLResults();
		
		
		for (Opportunity opp : pToUpdateOppList)
		{	
			if (opp.AccountId!=null)
				newOppOwnerMap.put(opp.Id, opp.OwnerId);
			
		}

		if(!newOppOwnerMap.isEmpty())
		{
			
			for(Merge_Contract_Header__c  mchS : [Select Id, Opportunity_Name__c FROM Merge_Contract_Header__c WHERE Opportunity_Name__c IN :newOppOwnerMap.keySet()])
			{
				//Formualte Key for removal of Owner Share 
				if(pOppOldMap.containsKey(mchS.Opportunity_Name__c))
					oldOppOwnerSet.add(mchS.Id+':'+mchS.Opportunity_Name__c+':'+ pOppOldMap.get(mchS.Opportunity_Name__c).OwnerId);
				
				//Populate Map of Opportunity to Associated Contracts
				if(!opptyIdToContractIdListMap.containsKey(mchS.Opportunity_Name__c))
				{
					List<Id> contractIdListTemp = new List<Id>();
					contractIdListTemp.add(mchS.Id);
					opptyIdToContractIdListMap.put(mchS.Opportunity_Name__c,contractIdListTemp);
				}
				else{
					List<Id> contractIdListTemp = opptyIdToContractIdListMap.get(mchS.Opportunity_Name__c);
					contractIdListTemp.add(mchS.Id);
					opptyIdToContractIdListMap.put(mchS.Opportunity_Name__c,contractIdListTemp);
				}
			}

			if(!opptyIdToContractIdListMap.isEmpty())
				{
					for(Id opptyid : opptyIdToContractIdListMap.keySet())
					{
						if(!newOppOwnerMap.isEmpty() && newOppOwnerMap.containsKey(opptyid))
						//for(Id ownerId : newOppOwnerMap.get(opptyid))
						{
							for(Id contractId : opptyIdToContractIdListMap.get(opptyid))
							{
								contractSharesToBeUpserted.add(new Contract_Share__c(
										Associated_User__c= newOppOwnerMap.get(opptyid), 
										Associated_Opportunity__c=opptyid, 
										Parent_Contract__c = contractId,
										ATM_OTM_SF_Id__c = contractId+':'+opptyid+':'+newOppOwnerMap.get(opptyid),
										RowCause__c = 'Owner'));
							}
						}
					}
				}
		}

		System.debug('newOppOwnerMap OPP=' + newOppOwnerMap);
		
		if (oldOppOwnerSet.size()>0)
		{
			System.debug('oldOppOwnerSet OPP=' + oldOppOwnerSet);
			List<Contract_Share__c> removeCShareList = new List<Contract_Share__c>();
			for (Contract_Share__c cShare : [SELECT Id, ATM_OTM_SF_Id__c FROM Contract_Share__c WHERE ATM_OTM_SF_Id__c IN :oldOppOwnerSet])
			{
				removeCShareList.add(cShare);	
			}
			System.debug('removeCShareList OPP=' + removeCShareList);
			
			if(removeCShareList.size()>0)
	        {
	            deleteResults.add(Database.delete(removeCShareList, false), removeCShareList);
	            deleteResults.withClassName('ContractSharing').insertRecordsInErrorLog();
	        }
		}
		
		if(contractSharesToBeUpserted.size()>0)
			{
				System.debug(Logginglevel.ERROR,'HC_D enteredd');
				upsertContractShareResults.add(Database.upsert(contractSharesToBeUpserted,Contract_Share__c.Fields.ATM_OTM_SF_Id__c,false), contractSharesToBeUpserted);
				upsertContractShareResults.withClassName('ContractSharing').insertRecordsInErrorLog();
				
			}
		
		updateOpptyOwnerContractShareFirstRunFlag = false;*/
	}
//Move the upsert/Delete to one common method

	//Method 10 - Remove Contract Share on Update of Account/Opportunity on Contract called from Contract Trigger
	public static void removeATMOTMShareOnAccOpptyUpdate(Map<Id,Id> mchIdToAccIdMap, Map<Id,Id> mchIdToOppIdMap  , Set<Id> mchIdSet)
		{
			if(!removeATMOTMShareOnAccOpptyUpdateFirstRunFlag)
	        	return ;
			
			Map<Id, List<Id>> accATMListMap = new Map<Id, List<Id>>();
			Set<Id> atmAccIdSet = new Set<Id>();
			Set<Id> atmMCHIdSet = new Set<Id>();
			Map<Id, List<Id>> oppOTMListMap = new Map<Id, List<Id>>();
			Set<Id> otmOppIdSet = new Set<Id>();
			Set<Id> otmMCHIdSet = new Set<Id>();

			List<Contract_Share__c> accountOpptyRelCShare = new List<Contract_Share__c>();
			system.debug('Maps for Delete '+mchIdToAccIdMap + 'O Map '+mchIdToOppIdMap +'MCHS '+mchIdSet);
			//Get all Contract Share Records of Contract Associated to Account/Oppty where Update occured
			for(Contract_Share__c csRec : [Select Id,Parent_Contract__c,Associated_Opportunity__c,Associated_Account__c,ATM_OTM_SF_Id__c,Associated_User__c From Contract_Share__c where Parent_Contract__c IN :mchIdSet ])
			{
				//Contract Shares Associated to Old Account and Oppty
				if(mchIdToAccIdMap.size() > 0 && mchIdToAccIdMap.containsKey(csRec.Parent_Contract__c) && csRec.Associated_Account__c == mchIdToAccIdMap.get(csRec.Parent_Contract__c) )
					accountOpptyRelCShare.add(csRec);
				if(mchIdToOppIdMap.size() > 0 && mchIdToOppIdMap.containsKey(csRec.Parent_Contract__c) && csRec.Associated_Opportunity__c == mchIdToOppIdMap.get(csRec.Parent_Contract__c))
					accountOpptyRelCShare.add(csRec);
			}

			system.debug('To Delete Records '+accountOpptyRelCShare);
			
			DMLResults deleteResults = new DMLResults();
			
			if (accountOpptyRelCShare.size()>0)
			{
				deleteResults.add(Database.delete(accountOpptyRelCShare,false),accountOpptyRelCShare);
		        deleteResults.withClassName('ContractSharing').insertRecordsInErrorLog();
			}
			removeATMOTMShareOnAccOpptyUpdateFirstRunFlag = false;		
			
		}

		public static void deleteContractShares(Set<Id> atmIdSet)
		{
			
		}
		public static void upsertContractShares(List<Account_Team__c> atmList)	
		{	
				
		}

}