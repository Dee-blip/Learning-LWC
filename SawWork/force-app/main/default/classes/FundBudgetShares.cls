/*
Class : FundBudgetShares
Author : Rohit Mehta, 02082010
Date : 03162010
Usage:  creates R/O share for the disti on the Fund Budget/Fund Request/ Fund Claim object
Config - Need Apex Sharing reason - 'Distributor' for FB, FR, FC
*/
public without sharing class FundBudgetShares {
	
	/*
	access given to distis on the different objects
	*/
	public static final String READ_ACCESS = 'Read';

	/*
	* Future Method. Create Shares for Fund Budget
	*/
	@future
	public static void createFBShare(Map<Id, Id> sObject_disty_map) {
	    List<SFDC_Budget__Share> newSObjectShares = new List<SFDC_Budget__Share>();
		createSObjectShare(sObject_disty_map, newSObjectShares, 'BUDGET');
	}

	/*
	* Future Method. Create Shares for Fund Request
	*/
	@future
	public static void createFRShare(Map<Id, Id> sObject_disty_map) {
	    List<SFDC_MDF__Share> newSObjectShares = new List<SFDC_MDF__Share>();
		createSObjectShare(sObject_disty_map, newSObjectShares, 'FUND_REQUEST');
	}

	/*
	* Future Method. Create Shares for Fund Claim
	*/
	@future
	public static void createFCShare(Map<Id, Id> sObject_disty_map) {
	    List<SFDC_MDF_Claim__Share> newSObjectShares = new List<SFDC_MDF_Claim__Share>();
		createSObjectShare(sObject_disty_map, newSObjectShares, 'FUND_CLAIM');
	}
	
	/*
	* Common Method which creates the Shares. 
	*/
	public static void createSObjectShare(Map<Id, Id> sObject_disty_map, 
		List<SObject> newSObjectShares, String identifier) 
	{

    	
		
		Set<Id> distiAccountIds = new Set<Id>();
		distiAccountIds.addAll(sObject_disty_map.values());
		
		
		
		Map<Id, Id> accountIdUserRoleIdMap = SharingUtil.getRoles(distiAccountIds);
		Map<Id,Id> gMap = SharingUtil.getGroups(accountIdUserRoleIdMap.values());
        Map<Id, Id> userAccountMap = new Map<Id, Id>();
        Map<Id, User> users = new Map<Id, User>([Select Id, Contact.AccountId from user where Contact.AccountId In :distiAccountIds]);
        for (User u : users.values()) {
        	userAccountMap.put(u.Id, u.Contact.AccountId);
        }
    	
    	for (Id sObjectId : sObject_disty_map.keySet()) { 
    		Id accountId  =  sObject_disty_map.get(sObjectId);
			SObject sobjectShare = CreatePartnerShare.addToShare(sobjectId, accountId, accountIdUserRoleIdMap, gMap, identifier);
			if (sobjectShare != null) {
				newSObjectShares.add(sobjectShare);
			}
        }
        
    	if(newSObjectShares.size() > 0)
    		insert newSObjectShares;
 
	}	

	/*
	* Remove Share code. This code should not be future as it scres up shares created.
	*/
	
	public static void removeFundBudgetShare(Map<Id, Id> sObject_oldPartner_map) {	
		delete [select Id from SFDC_Budget__Share where ParentId In :sObject_oldPartner_map.keySet() 
			And RowCause = 'Account__c'];
	}	
	
	public static void removeFundRequestShare(Map<Id, Id> sObject_oldPartner_map) {	
		delete [select Id from SFDC_MDF__Share where ParentId In :sObject_oldPartner_map.keySet() 
			And RowCause = 'Account__c'];
	}	
	
	public static void removeFundClaimShare(Map<Id, Id> sObject_oldPartner_map) {	
		delete [select Id from SFDC_MDF_Claim__Share where ParentId In :sObject_oldPartner_map.keySet() 
			And RowCause = 'Account__c'];
	}

}