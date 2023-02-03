global class PartnerUserAccessUtilityBatchClass extends GenericBatchClass {
	
    //global DMLResults results;

    global PartnerUserAccessUtilityBatchClass() {

        super();
		operationType = 'Insert';
		className = 'PartnerUserAccessUtilityBatchClass';
        String whereClause = GsmUtilClass.getPRMSettingValue('PartnerAccessUtil_FilterCriteria');
        query = 'SELECT id, AccountId__c From User where '+ whereClause;
        if (Test.isRunningTest())
            query += ' Limit 10';
        //chec for ispartner on user
        //Make query configurable
    }
    
    global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<User> usersList= (List<User>)scope;
        List<Id> userIds = new List<Id>();
        List<Id> accIds = new List<Id>();
        List<AccountShare> newSharesToBeCreated = new List<AccountShare>();
        Map<Id,AccountShare> mapOfUserIdToShare = new Map<Id,AccountShare>();
        String accountAccessLevel = GsmUtilClass.getPRMSettingValue('PartnerAccessUtil_AccountAccessLevel');
        
        /*
         * Create set of user ids and set of account ids
         */
        for (User u:usersList) {
            userIds.add(u.id);
            accIds.add(u.AccountId__c);
        }
        
        /*
         * For sharing Partner MDF related records Account share is created for the users
         * Get all the accountshares where userorgroupid in userIds and Account ids in accIdss
         */
        //Get roles for the list of account ids
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(accIds, 'Partner');
        // Get all groups of the accounts 
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        List<AccountShare> accountSharesList = [Select AccountId , UserOrGroupId , RowCause, AccountAccessLevel 
                                                 From AccountShare 
                                                 where (UserOrGroupId IN:userIds OR UserOrGroupId IN:gMap.values())
                                                 	and AccountId IN:accIds
                                                	and RowCause = 'Manual'
                                                	and AccountAccessLevel = 'Edit'];
		
        /*
         * Create a Map of UserId to AccountShare
         * - Check if account share exists for the user, 
         *   if not, create AccountShare for the user
         */
        for(AccountShare a:accountSharesList){
			mapOfUserIdToShare.put(a.UserOrGroupId, a);
        }
        
        for (User u:usersList) {
            //Check if user id existing in mapOfUserIdToShare, if yes continue
            if (mapOfUserIdToShare.containsKey(u.Id)) 
                continue;
            
            //Get the groupId of for the user's account and check if group id exists in mapOfUserIdToShare
            if (accountIdUserRoleIdMap.get(u.AccountId__c) != null) {
            	Id roleIdBasedOnAcc = accountIdUserRoleIdMap.get(u.AccountId__c);
                //Get group based on account id
                if (gMap.get(roleIdBasedOnAcc) != null) {
                	Id groupId = gMap.get(roleIdBasedOnAcc);
                	if (mapOfUserIdToShare.containsKey(groupId)) 
                        continue;
                }
            }
            System.debug('SH debug : AccountId :'+u.AccountId__c);
            AccountShare share = new AccountShare();
            share.AccountId = u.AccountId__c;
            share.UserOrGroupId = u.id;
            share.AccountAccessLevel = accountAccessLevel;
            share.OpportunityAccessLevel = 'None';
            share.RowCause = 'Manual';
                
            System.debug('SH debug : Creating partner share');
            newSharesToBeCreated.add(share);
        }
        
        if(newSharesToBeCreated.size()>0)
                super.execute(BC, newSharesToBeCreated);

    }

    global override void finish(Database.BatchableContext BC)
    {
        super.finish(BC);
    }
}