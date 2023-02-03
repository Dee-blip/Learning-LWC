trigger CreateInverseAssociation on RecordAssociation__c (after insert, after update) 
{  
    /**
    * Trigger to create a corresponding Inverse Account Association on creation of a new Account Association. This trigger also creates shares for the associations.
    **/             
    // Avoid infinite looping
    if (AccountAssociationHelper.isReciprocal())
        return;

    AccountAssociationHelper helper = new AccountAssociationHelper(Trigger.new);
    List<RecordAssociation__c> toUpdateInv = new List<RecordAssociation__c>();
    List<RecordAssociation__c> newInv = new List<RecordAssociation__c>();
    List<Id> accIds = new List<Id>();
    List<Id> assAccs = new List<Id>();
    Map<Id,List<Id>> leadAccMap = new Map<Id,List<Id>>();
    Set<Id> accountIds = new Set<Id>(); 
    Set<Id> oldAssocIds = new Set<Id>();
    Map<id,Id> oppAccMap = new Map<Id,Id>();
    List<Id> l_accts = new List<Id>();
    List<Id> o_accts = new List<Id>();
    
    if(trigger.isAfter){       
        for(RecordAssociation__c assoc : Trigger.new){	       
        	if(trigger.isUpdate){ 
        		if(assoc.Associated_Account__c != trigger.oldMap.get(assoc.Id).Associated_Account__c){
        			oldAssocIds.add(trigger.oldMap.get(assoc.Id).Associated_Account__c);
        		}
        		toUpdateInv.add(assoc);
        	} 
        	if(trigger.isInsert){ 
        		newInv.add(assoc);
        	} 
        	accIds.add(assoc.Account__c);
        	assAccs.add(assoc.Associated_Account__c);	   
        }
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(assAccs, 'Partner');
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        AccountAssociationHelper.createShares(accIds,accountIdUserRoleIdMap, gMap, helper.getGroupIds(), helper.getAcctParentMap()); 
        if(!newInv.isEmpty()){
        	helper.createInverseRelation(newInv);
        }
        if(!toUpdateInv.isEmpty()){
        	helper.updateInverseRelation(toUpdateInv, oldAssocIds);     
        }                 
    }
}