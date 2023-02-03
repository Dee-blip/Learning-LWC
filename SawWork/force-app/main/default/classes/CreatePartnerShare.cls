public without sharing class CreatePartnerShare {

    public static Boolean run = true;
    
    public static Boolean runOnce() {
        if (run) {
            run = false;
            return true;
        } else {
            return run; 
        }
    }
    
    
    public static SObject addToShare(Id sobjectId, Id accountId, Map<Id, Id> accountIdUserRoleIdMap, Map<Id,Id> gMap, String identifier) {
        if (accountId == null) {
            return null;    
        }
        Id roleId = accountIdUserRoleIdMap.get(accountId);
        Id groupId = gMap.get(roleId);
        
        if (groupId == null) {
            return null;
        }
        
        if (identifier.equals('BUDGET')) {
            SFDC_Budget__Share budgetShare = new SFDC_Budget__Share(
                                    ParentId = sObjectId,
                                    userOrGroupId = groupId,
                                    AccessLevel = 'Read',
                                    RowCause = Schema.SFDC_Budget__Share.rowCause.Account__c);
            return budgetShare;
        }
        
        if (identifier.equals('FUND_REQUEST')) {
            SFDC_MDF__Share frShare = new SFDC_MDF__Share(
                                    ParentId = sObjectId,
                                    userOrGroupId = groupId,
                                    AccessLevel = 'Edit',
                                    RowCause = Schema.SFDC_MDF__Share.rowCause.Account__c);
            return frShare;
        }
        
        if (identifier.equals('FUND_CLAIM')) {
            SFDC_MDF_Claim__Share budgetShare = new SFDC_MDF_Claim__Share(
                                    ParentId = sObjectId,
                                    userOrGroupId = groupId,
                                    AccessLevel = 'Edit',
                                    RowCause = Schema.SFDC_MDF_Claim__Share.rowCause.Account__c);
            return budgetShare;
        }
        return null;        
    }

}