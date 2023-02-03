trigger AfterDeleteAssocDeleteInverseAssocAndShares on RecordAssociation__c (after delete) {
	/**
	* Trigger to delete a corresponding Inverse Account Association on deletion of an Account Association. This trigger also deletes shares for deleted associations.
	**/ 
	// Avoid infinite looping
    if (AccountAssociationHelper.isReciprocal())
    	return;

    Map<string,Id> acctIds = new Map<string,Id>();
    Map<string,Id> assocIds = new Map<string,Id>();
    Set<string> userGroupIds = new Set<string>();    
    Map<string,Set<string>> acctIdToInverseRoleMap = new Map<string,Set<string>>();
        
    AccountAssociationHelper helper = new AccountAssociationHelper(Trigger.old);
    Map<String,String> groupIds = helper.getGroupIds();
    Map<String,String> acctParentMap = helper.getAcctParentMap();
    
    for (RecordAssociation__c assoc : Trigger.old)
    {
        String key = 'AssocAccount'+assoc.account__c+assoc.associated_account__c; 
        acctIds.put(key, assoc.account__c);
        if (assoc.associated_account__c != null && String.valueOf(assoc.Associated_Account__c) != '')
            assocIds.put(key, assoc.associated_account__c);
            
        if (assoc.account_role__c == 'Partner')
        {
            acctIdToInverseRoleMap.put(key, new Set<string>{'Partner'});
        }
        else if (assoc.account_role__c == 'End Customer')
        {
            acctIdToInverseRoleMap.put(key, new Set<String>{'End Customer'});  
        } 
        else if (assoc.account_role__c == 'Distributor/VAR'){
        	acctIdToInverseRoleMap.put(key, new Set<String>{'Distributor/VAR'});
        }
        else if (assoc.account_role__c == ''){
        	acctIdToInverseRoleMap.put(key, new Set<String>{''});
        }
        
        userGroupIds.add(assoc.associated_account__c+
            groupIds.get('Account'+assoc.Account__c+assoc.Associated_Account__c));
        userGroupIds.add(assoc.associated_account__c+       
            groupIds.get('AccountParent'+assoc.Account__c+assoc.Associated_Account__c));
        userGroupIds.add(assoc.account__c+
            groupIds.get('AssocAccount'+assoc.Account__c+assoc.Associated_Account__c)); 
        userGroupIds.add(assoc.account__c+  
            groupIds.get('AssocAccountParent'+assoc.Account__c+assoc.Associated_Account__c)); 
    }
    Set<String> keys = new Set<String>(acctIdToInverseRoleMap.keySet());
	AccountAssociationHelper.removeShares(acctIds, assocIds, groupIds, userGroupIds, keys);
    
    for (List<RecordAssociation__c> inverseAssocs : [select account__c, associated_account__c, account_role__c
        from RecordAssociation__c where account__c in :assocIds.values()]) 
    {
        List<RecordAssociation__c> assocsToDelete = new List<RecordAssociation__c>();
        for (RecordAssociation__c inverseAssoc : inverseAssocs) {
            String key = 'AssocAccount'+inverseAssoc.associated_account__c+inverseAssoc.account__c;
            /*if(acctIdToInverseRoleMap.get(key) != null){
	            if (acctIds.get(key) == inverseAssoc.associated_account__c && 
	                acctIdToInverseRoleMap.get(key).contains(inverseAssoc.account_role__c)) {
	                    assocsToDelete.add(inverseAssoc);
	            }
            }else if(acctIdToInverseRoleMap.get(key) == null){
            	assocsToDelete.add(inverseAssoc);
            }*/
            if (acctIds.get(key) == inverseAssoc.associated_account__c) {
	                    assocsToDelete.add(inverseAssoc);
            }
        }    
        if (assocsToDelete.size() > 0)  
            delete assocsToDelete;
    }

}