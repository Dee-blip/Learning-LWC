public class AccountAssociationHelper {
    
    private static Id ACCOUNT_ASSOC_REC_TYPE = null;
	public static boolean run = true;                 //Specifies whether or not the functionality has been invoked before
    public static Boolean ACCOUNT_ASSOC_PROCESS_FLAG = false;
    public static List<List<AccountShare>> accountSharePlaceholder = null;
    
    private Map<Id, Id> contactIds = new Map<Id, Id>();
    private static Map<Id,User> partnerContactUsers = new Map<Id,User>();
    private static Map<String,String> grpIdMap = new Map<String,String>();
    private static Map<String,String> acctIdToParentIdMap = new Map<String,String>(); 
  
    public AccountAssociationHelper (List<Object_Association__c> associations) {
    	
    	boolean containsContactAssoc = false;
    	Set<Id> accountIds = new Set<Id>();
    	    	
    	for (Object_Association__c assoc : associations) {
    		if (assoc.Associated_Account__c != null && String.valueOf(assoc.Associated_Account__c) != '')
    			accountIds.add(assoc.Associated_Account__c);
    	}
	
   		for (Account acct: [select id, ParentId from Account where Id in :accountIds]) {
        	if (acct.ParentId != null)
        	{
        		accountIds.add(acct.ParentId);
        		acctIdToParentIdMap.put(acct.id, acct.ParentId);
        	}
        }
        
        Map<String, String> roleIdToAcctIdMap = new Map<String, String>();   
        for (UserRole role : [select Id, Name, PortalAccountId from UserRole where portalaccountid in 
        	:accountIds and Name like '%Partner Executive']) { 
        	roleIdToAcctIdMap.put(role.id, role.PortalAccountId);
		}
        
        Map<String, String> acctIdToGrpIdMap = new Map<String, String>();
      	for (Group g : [select RelatedId, Id from Group where RelatedId in :roleIdToAcctIdMap.keySet() 
      		and Type = 'RoleAndSubordinates']) {
        	acctIdToGrpIdMap.put(roleIdToAcctIdMap.get(g.relatedid), g.id);
        }      		
	   
        for (Object_Association__c assoc : associations) {
        			
        	if (acctIdToGrpIdMap.get(assoc.Associated_Account__c) != null)
    			grpIdMap.put('AssocAccount'+assoc.Associated_Account__c, 
    				acctIdToGrpIdMap.get(assoc.Associated_Account__c));
    				
    		if (acctIdToGrpIdMap.get(acctIdToParentIdMap.get(assoc.Associated_Account__c)) != null)
    			grpIdMap.put('AssocAccountParent'+assoc.Associated_Account__c, 
    				acctIdToGrpIdMap.get(acctIdToParentIdMap.get(assoc.Associated_Account__c)));
        }    	
    }
    
    public AccountAssociationHelper (List<RecordAssociation__c> associations) {
    	
    	boolean containsContactAssoc = false;
    	Set<Id> accountIds = new Set<Id>();
    	for (RecordAssociation__c assoc : associations) {
    		accountIds.add(assoc.Account__c);
    		if (assoc.Associated_Account__c != null && String.valueOf(assoc.Associated_Account__c) != '')
    			accountIds.add(assoc.Associated_Account__c);
    	}
	
   		for (Account acct: [select id, ParentId from Account where Id in :accountIds]) {
        	if (acct.ParentId != null)
        	{
        		accountIds.add(acct.ParentId);
        		acctIdToParentIdMap.put(acct.id, acct.ParentId);
        	}
        }
        
        Map<String, String> roleIdToAcctIdMap = new Map<String, String>();   
        for (UserRole role : [select Id, Name, PortalAccountId from UserRole where portalaccountid in 
        	:accountIds and Name like '%Partner Executive']) { 
        	roleIdToAcctIdMap.put(role.id, role.PortalAccountId);
		}
        
        Map<String, String> acctIdToGrpIdMap = new Map<String, String>();
      	for (Group g : [select RelatedId, Id from Group where RelatedId in :roleIdToAcctIdMap.keySet() 
      		and Type = 'RoleAndSubordinates']) {
        	acctIdToGrpIdMap.put(roleIdToAcctIdMap.get(g.relatedid), g.id);
        }      		
	   
        for (RecordAssociation__c assoc : associations) {
        	if (acctIdToGrpIdMap.get(assoc.Account__c) != null)
        		grpIdMap.put('Account'+assoc.Account__c+assoc.Associated_Account__c, 
        			acctIdToGrpIdMap.get(assoc.Account__c));
        		
        	if (acctIdToGrpIdMap.get(acctIdToParentIdMap.get(assoc.Account__c)) != null)
        		grpIdMap.put('AccountParent'+assoc.Account__c+assoc.Associated_Account__c, 
        			acctIdToGrpIdMap.get(acctIdToParentIdMap.get(assoc.Account__c)));
        			
        	if (acctIdToGrpIdMap.get(assoc.Associated_Account__c) != null)
    			grpIdMap.put('AssocAccount'+assoc.Account__c+assoc.Associated_Account__c, 
    				acctIdToGrpIdMap.get(assoc.Associated_Account__c));
    				
    		if (acctIdToGrpIdMap.get(acctIdToParentIdMap.get(assoc.Associated_Account__c)) != null)
    			grpIdMap.put('AssocAccountParent'+assoc.Account__c+assoc.Associated_Account__c, 
    				acctIdToGrpIdMap.get(acctIdToParentIdMap.get(assoc.Associated_Account__c)));
        }   	
    }
     
    public Map<String,String> getGroupIds() {
    	return grpIdMap;
    }
    
    public Map<String,String> getAcctParentMap() {
    	return acctIdToParentIdMap;
    }  	
    
  	public static boolean isReciprocal()
    {
    	// Static variables are static per thread in SFDC not app or session
		if (ACCOUNT_ASSOC_PROCESS_FLAG)
    	{
    		ACCOUNT_ASSOC_PROCESS_FLAG = false;
        	return true;
    	}
    	else
    	{
        	ACCOUNT_ASSOC_PROCESS_FLAG = true;
        	return false;
    	}
    }
    
	
	@future    
    public static void createShares(List<Id> assocList, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap, Map<String,String> groupIdMap, Map<String,String> acctIdParentIdMap){
	//moved from the trigger to make the sharing method future
	    List<AccountShare> newShares = new AccountShare[]{};	    

	    Configuration config = new Configuration();
	    String accountAccessLevel = config.getObjectAccessLevel(Configuration.ACCOUNT);
        
    	for (RecordAssociation__c assoc : [select id, associated_Account__c, account__c, Account_Role__c from RecordAssociation__c where Account__c in :assocList]) {			//, LeadId__c, OpportunityId__c  
	    	System.debug('assoc id = ' + assoc.id);		
	    	if (assoc.associated_account__c != null) 		
	    	{  
	            if (groupIdMap.containsKey('Account'+assoc.Account__c+assoc.Associated_Account__c))
	                {
	                    newShares.add(new AccountShare(
			                        AccountId = assoc.Associated_Account__c,
			                        userOrGroupId = groupIdMap.get('Account'+assoc.Account__c+assoc.Associated_Account__c),
			                        AccountAccessLevel = accountAccessLevel,
			                        OpportunityAccessLevel = 'None'));
	                }
	                if (groupIdMap.containsKey('AssocAccount'+assoc.Account__c+assoc.Associated_Account__c))
	                {
	                    newShares.add(new AccountShare(
	                    AccountId = assoc.Account__c,
	                    userOrGroupId = groupIdMap.get('AssocAccount'+assoc.Account__c+assoc.Associated_Account__c),
	                    AccountAccessLevel = accountAccessLevel,
	                    OpportunityAccessLevel = 'None'));
	                }	            
	        } 
	    }
		    if (newShares.size() > 0)
		    	insert newShares;
   	}
    
    @future
	public static void createObjectShares(List<Id> objList, Map<Id,Id> accountIdUserRoleIdMap, Map<Id,Id> gMap, Map<String,String> groupIdMap, Map<String,String> acctIdParentIdMap){
		List<LeadShare> newLeadShares = new List<LeadShare>();
	    List<OpportunityShare> newOppShares = new List<OpportunityShare>();
	    String obj = (String) objList[0];

	    //get the access level for leads
	    Configuration config = new Configuration();
	    String leadAccessLevel = config.getObjectAccessLevel(Configuration.LEAD);
	    String oppAccessLevel = config.getObjectAccessLevel(Configuration.OPPORTUNITY);
	    
	    if(obj.startsWith('00Q') && (! leadAccessLevel.equals(Configuration.ACCESS_NONE))){
			for (Object_Association__c objAssoc : [select id, LeadId__c, Associated_Account__c from Object_Association__c where LeadId__c in :objList]) {			//, LeadId__c, OpportunityId__c
				
		        if(objAssoc.associated_account__c != null){				        	
		        	
	        		if (groupIdMap.containsKey('AssocAccount'+objAssoc.Associated_Account__c))
	                {
	                    newLeadShares.add(new LeadShare(
	                    LeadId = objAssoc.LeadId__c,
	                    userOrGroupId = groupIdMap.get('AssocAccount'+objAssoc.Associated_Account__c),
	                    LeadAccessLevel = leadAccessLevel));
	                }	                	        		
				}
    		} 
		}
    	if(obj.startsWith('006') && (! oppAccessLevel.equals(Configuration.ACCESS_NONE))){
    		for (Object_Association__c objAssoc : [select id, OpportunityId__c,Associated_Account__c from Object_Association__c where OpportunityId__c in :objList]) {			//, LeadId__c, OpportunityId__c
				if (groupIdMap.containsKey('AssocAccount'+objAssoc.Associated_Account__c))
                {
                    newOppShares.add(new OpportunityShare(
                    OpportunityId = objAssoc.OpportunityId__c,
                    userOrGroupId = groupIdMap.get('AssocAccount'+objAssoc.Associated_Account__c),
                    OpportunityAccessLevel = oppAccessLevel));
                }					
        	}
        }	    
	    
	    if(newLeadShares.size() > 0)
	    	insert newLeadShares;
	    	
	    if(newOppShares.size()>0)
	    	insert newOppShares;	        
    }	
	
	
    public void createInverseRelation(List<RecordAssociation__c> assocList){
	//moved from the trigger to make the sharing method future
	    List<RecordAssociation__c> newAssocs = new RecordAssociation__c[]{}; 	    
	    Set<Id> assocIds = new Set<Id>();
	    for (RecordAssociation__c assoc : assocList) { 
	    	assocIds.add(assoc.Account__c);
	    }
	    Map<Id, Account> accMap = new Map<Id, Account>();
		List<Account> accList = [Select Id, Name from Account where Id in :assocIds];
		for(Account a : accList){
			accMap.put(a.Id, a);
		}
	    for (RecordAssociation__c assoc : assocList) {  	    	
            if (assoc.Account_Role__c == 'Partner') {    			
                if (grpIdMap.containsKey('AssocAccount'+assoc.Account__c+assoc.Associated_Account__c))
                {
                    newAssocs.add(new RecordAssociation__c(account__c=assoc.Associated_Account__c, associated_Account__c=assoc.Account__c, account_Role__c='Partner'));  // , recordTypeId=AccountAssociationHelper.getAccountAssocRecType()	                    						
                }
                else
                {                	
                    assoc.addError('Please choose accounts with active partners users. All accounts, including ' + accMap.get(assoc.Account__c).Name +', need to have active partner users in order to create an account association ');
                }
            }
            else if (assoc.Account_Role__c == 'End Customer')
            {
                if (grpIdMap.containsKey('Account'+assoc.Account__c+assoc.Associated_Account__c))
                {
                    newAssocs.add(new RecordAssociation__c(
                            Account__c = assoc.Associated_Account__c,
                            Associated_Account__c = assoc.Account__c,
                            Account_Role__c = 'End Customer'                            
                    		));
                }
                else
                {
                    assoc.addError('Please choose accounts with active partners users. All accounts, including ' + accMap.get(assoc.Account__c).Name +', need to have active partner users in order to create an account association ');
                }
            } 
            else if (assoc.Account_Role__c == 'Distributor/VAR')
            {
                if (grpIdMap.containsKey('Account'+assoc.Account__c+assoc.Associated_Account__c) && grpIdMap.containsKey('AssocAccount'+assoc.Account__c+assoc.Associated_Account__c))
                {
                    newAssocs.add(new RecordAssociation__c(
                        Account__c = assoc.Associated_Account__c,
                        Associated_Account__c = assoc.Account__c,
                        Account_Role__c = 'Distributor/VAR'
                       ));
                }
                else
                {
                    assoc.addError('Please choose accounts with active partners users. All accounts, including ' + accMap.get(assoc.Account__c).Name +', need to have active partner users in order to create an account association ');  
                }	                    
            }
            else if (assoc.Account_Role__c == null)
            {
                if (grpIdMap.containsKey('Account'+assoc.Account__c+assoc.Associated_Account__c) && grpIdMap.containsKey('AssocAccount'+assoc.Account__c+assoc.Associated_Account__c))
                {
                    newAssocs.add(new RecordAssociation__c(
                        Account__c = assoc.Associated_Account__c,
                        Associated_Account__c = assoc.Account__c,
                        Account_Role__c = null
                        ));
                }
                else
                {
                    assoc.addError('Please choose accounts with active partners users. All accounts, including ' + accMap.get(assoc.Account__c).Name +', need to have active partner users in order to create an account association ');
                }
            }  		    	        
	    }
	    if (newAssocs.size() > 0)
	        insert newAssocs;	 
    }
    
    public void updateInverseRelation(List<RecordAssociation__c> assocList, Set<Id> oldAssocIds){
    	List<RecordAssociation__c> newInvAssoc = new List<RecordAssociation__c>();
    	List<RecordAssociation__c> existingInvAssoc = new List<RecordAssociation__c>();
    	
    	Set<Id> assocAccIds = new Set<Id>();
    	Set<Id> accIds = new Set<Id>();
    	Map<Id,RecordAssociation__c> existingAssocMap = new Map<Id,RecordAssociation__c>();
    	Map<Id,RecordAssociation__c> existingInvAssocMap = new Map<Id,RecordAssociation__c>();
    	RecordAssociation__c ass;
    	for(RecordAssociation__c assoc : assocList){
    		accIds.add(assoc.Associated_Account__c);
    		assocAccIds.add(assoc.Account__c);
    	}
    	List<RecordAssociation__c> existingAssoc = [Select Id, Associated_Account__c, Account__c, Account_Role__c from RecordAssociation__c where Account__c in :accIds and Associated_Account__c in :assocAccIds];
    	if(!oldAssocIds.isEmpty()){
    		existingInvAssoc = [Select Id, Associated_Account__c, Account__c, Account_Role__c from RecordAssociation__c where Account__c in :oldAssocIds and Associated_Account__c in :assocAccIds];
    	}
    	for(RecordAssociation__c a1 : existingAssoc){
    		existingAssocMap.put(a1.Account__c, a1);
    	}
    	
    	if(!existingInvAssoc.isEmpty()){
    		for(RecordAssociation__c a3 : existingInvAssoc){
    			existingInvAssocMap.put(a3.Associated_Account__c, a3);
    		}
    	}
    	//Update Inverse Relation
    	for(RecordAssociation__c a2 : assocList){
    		if(existingAssocMap.containsKey(a2.Associated_Account__c)){    			
    			existingAssocMap.get(a2.Associated_Account__c).Account_Role__c = a2.Account_Role__c;    						
    		}    		
    	}   
    	if(!existingAssocMap.isEmpty()){
    		update existingAssocMap.values();
    	}    	
    }
    
    @future
    public static void removeShares(Map<string,Id> acctIds, Map<string,Id> assocIds, Map<String,String> groupIds, Set<string> userGroupIds, Set<String> acctIdToInverseRoleMapKeys ){

		List<AccountShare> accSharesToDelete = new List<AccountShare>();
	    for (List<AccountShare> existingShares : [select id, accountid, userorgroupid from AccountShare where (accountid in :acctIds.values() or 
	        accountid in :assocIds.values()) and userOrGroupId in :groupIds.values() and rowCause = 'Manual']) {
	            
	        List<AccountShare> sharesToDelete = new List<AccountShare>();   
	        for (AccountShare share : existingShares) {
	            if (userGroupIds.contains(share.accountid+''+share.userOrGroupId))
	                sharesToDelete.add(share);
	        }
	        accSharesToDelete.addAll(sharesToDelete);
	    }
		
        if (accSharesToDelete.size() > 0)
            delete accSharesToDelete;
    	
    }
    
    @future
    public static void removeLeadShares(Map<string,Id> leadIds, Map<string,Id> assocIds, Map<String,String> groupIds, Set<string> userGroupIds){

		List<LeadShare> leadSharesToDelete = new List<LeadShare>();
	    List<LeadShare> existingShares;
	    if(GroupSharingHelper.ISTEST){
	    	existingShares = [select id, LeadId, userorgroupid from LeadShare where LeadId in :leadIds.values() 
	   										   and userOrGroupId in :groupIds.values() and rowCause = 'Manual' limit 10];
	    }else{
	    	existingShares = [select id, LeadId, userorgroupid from LeadShare where LeadId in :leadIds.values() 
	   										   and userOrGroupId in :groupIds.values() and rowCause = 'Manual' ];
	    }
   		System.debug('existingShares: '+existingShares);	
   		List<Id> assocAccIds = assocIds.values();     
   		
        List<LeadShare> sharesToDelete = new List<LeadShare>();   
        for(Integer i=0;i<assocAccIds.size();i++){
	        for (LeadShare share : existingShares) {
	            if (userGroupIds.contains(assocAccIds.get(i)+''+share.userOrGroupId))
	                sharesToDelete.add(share);
	        }
        }
        leadSharesToDelete.addAll(sharesToDelete);
	    
		System.debug('leadSharesToDelete: ' + leadSharesToDelete);
        if (leadSharesToDelete.size() > 0)
            delete leadSharesToDelete;    	
    }
    
    @future
    public static void removeOppShares(Map<string,Id> oppIds, Map<string,Id> assocIds, Map<String,String> groupIds, Set<string> userGroupIds){

		List<OpportunityShare> oppSharesToDelete = new List<OpportunityShare>();
		
	    List<OpportunityShare> existingShares ;
	    if(GroupSharingHelper.ISTEST){
	    	existingShares = [select id, OpportunityId, userorgroupid from OpportunityShare where OpportunityId in :oppIds.values() 
	   										   and userOrGroupId in :groupIds.values() and rowCause = 'Manual' limit 10];
	    }else{
	    	existingShares = [select id, OpportunityId, userorgroupid from OpportunityShare where OpportunityId in :oppIds.values() 
	   										   and userOrGroupId in :groupIds.values() and rowCause = 'Manual'];
	    }
   		System.debug('existingShares: '+existingShares);	
   		List<Id> assocAccIds = assocIds.values();            
   		
        List<OpportunityShare> sharesToDelete = new List<OpportunityShare>();   
        for(Integer i=0;i<assocAccIds.size();i++){
	        for (OpportunityShare share : existingShares) {
	            if (userGroupIds.contains(assocAccIds.get(i)+''+share.userOrGroupId))
	                sharesToDelete.add(share);
	        }
        }
        oppSharesToDelete.addAll(sharesToDelete);	    
		
        if (oppSharesToDelete.size() > 0)
            delete oppSharesToDelete;    	
    }
}