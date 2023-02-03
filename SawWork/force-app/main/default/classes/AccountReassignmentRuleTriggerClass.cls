/***
	AccountReassignmentRuleTriggerClass
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class houses business logic to be implemented on Contact DML triggers.
    				The following functionlatiy is achieved :
    				1. When AccountReassignmentRule.User_Role__c is updated, change the Role of the Associated User accordingly.
    				2. When AccountReassignmentRule.User_Role__c is updated, change the User_Role on all other rules that have the same Associated_User.
    
	@History
	--Developer		      --Date			--Change
	Karteek Kumar M		  21/10/10			CR 820353 Add Role to Account Reassignment Rule object
											Created the class 
	Sonali Tandon 		  2/3/2014			CR 2913906 - Account Reassignment Rule creation: User Role not updated
											-removed future annotation on UpdateOwnerRole()
											-Created schedule job to update user role on owner to avoid group membership lock.  
	Sonali Tandon			25/03/2015		CR 2941949 - Account Reassignment: Updating rules to change GDRAT on Accounts
											-updateGDRATOnAccounts() :Update GDRAT on all accounts owned by the changed rule's associated user.
*/
global class AccountReassignmentRuleTriggerClass 
{
	// Get all the picklist values for User_Role__c
	private static Schema.DescribeFieldResult fieldResult = Account_Reassignment_Rule__c.User_Role__c.getDescribe();
	private static List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();	
	private static Boolean updateGDRATOnAccountsFirstRunFlag = true;
	 

	/**
		UpdateOwnerRole()
		- When AccountReassignmentRule.User_Role__c is updated, change the Role of the Associated User accordingly.
		- This function runs Asynchronously to avoid the MIXED_DML_EXCEPTION, which does not allow an update to a setup object and a non-setup object in the same transaction.
	*/
	
	public static void UpdateOwnerRole(Set<Id> ruleIds)
	{
		List<Account_Reassignment_Rule__c> ownerRoleUpdateRequiredList = [select Id, 
											  Associated_User__c, 
											  User_Role__c 
									   from Account_Reassignment_Rule__c 
									   where Id IN :ruleIds];
		if(ownerRoleUpdateRequiredList.size() < 1)
			return;
		// Get the list of Users that need to be updated
		Set<Id> userIdSet = new Set<Id>();
		Set<String> roleNameSet = new Set<String>();
		for(Account_Reassignment_Rule__c rule : ownerRoleUpdateRequiredList)
		{
			userIdSet.add(rule.Associated_User__c);
			roleNameSet.add(rule.User_Role__c);
		}
		List<User> usersUpdateList = [select Id, 
									   User_Role_Name__c,
									   UserRoleId 
								from User 
								where Id IN :userIdSet];
		// Generate a map of RoleName -> RoleId
		Map<String, Id> roleNameIdMap = new Map<String, Id>();
		for(UserRole role : [select Id, Name
							 from UserRole
							 where Name IN :roleNameSet])
			roleNameIdMap.put(role.Name, role.Id);
		// Generate a map of UserId -> New Role
		Map<Id, Id> userRoleMap = new Map<Id, Id>();
		for(Account_Reassignment_Rule__c rule : ownerRoleUpdateRequiredList)
			userRoleMap.put(rule.Associated_User__c, roleNameIdMap.get(rule.User_Role__c));
		// Update the users
		for(User usr : usersUpdateList)
			usr.UserRoleId = userRoleMap.get(usr.Id);
		update usersUpdateList;
	}
	/**
		TriggerCall()
		- Function that is called from AccountReassignmentRuleTrigger
	*/
	 public static void TriggerCall(Account_Reassignment_Rule__c[] triggerNew, Map<Id, Account_Reassignment_Rule__c> triggerOldMap)
  {
    //Features_Toggle__c customSettings = Features_Toggle__c.getInstance('UserRoleUpdateThroughAssignmentRule'); //SFDC-2304
    Map<Id, Account_Reassignment_Rule__c> rulesToUpdateIdMap = new Map<Id, Account_Reassignment_Rule__c>();
    if(Trigger.isAfter)
    {
      // Check if the Feature is ON      
      //if(customSettings.Toggle__c == true) //SFDC-2304
      if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UserRoleUpdateThroughAssignmentRule') == true) //SFDC-2304
      {      
        for(Account_Reassignment_Rule__c rule : triggerNew)
        {
          if(Trigger.isInsert  || rule.User_Role__c != triggerOldMap.get(rule.Id).User_Role__c)
          {
            // User Role must match the values in the Picklist        
            if(AccountReassignmentRuleTriggerClass.IsUserRoleValid(rule.User_Role__c)) 
              rulesToUpdateIdMap.put(rule.Id, rule);
            else
              rule.User_Role__c.addError('Invalid User Role.');
          }                        
        }
        if(rulesToUpdateIdMap.keySet().size()>0)
        {
        		
                // Asyncronous task : Update the Role of the user  
                // Build chron expression
                //Integer seconds = Integer.valueOf(GSM_Custom_Settings__c.getInstance('AccountReassignment#TimeToSchedule').Value__c); //SFDC-2304
            	Integer seconds = Integer.valueOf(GsmUtilClass.getGSMSettingValue('AccountReassignment_TimeToSchedule')); //SFDC-2304
                Datetime sysTime = System.now().addSeconds(seconds);
                String chronExpression = '' + sysTime.second() + ' ' + sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
                System.debug('chronExpression: '+chronExpression);
                String jobName = 'Update Roles On Owner' + sysTime;
                System.debug('Before schedule');
                List<CronTrigger> jobs = [SELECT Id, CronJobDetail.Name, State, NextFireTime
                              FROM CronTrigger where CronJobDetail.Name=:jobName];
                //Schedule job if not scheduled earlier
                if(jobs.isEmpty())
                {
                    try{
                    System.schedule('Update Roles On Owner' + sysTime,chronExpression, new AccountReassignmentUpdateRolesClass(rulesToUpdateIdMap.keySet()));
                    }
                    catch(Exception e)
                    {
                        System.debug(e.getStackTraceString());
                    }
                }
                    
                 // Syncronous task : Update the User_role__c in other Rules.
                AccountReassignmentRuleTriggerClass.UpdateOtherRules(rulesToUpdateIdMap.values());
        }        
      }
      // If feature is OFF
      else
      {
        for(Account_Reassignment_Rule__c rule : triggerNew)
        {
          if((Trigger.isInsert && rule.User_Role__c != null)  || (!Trigger.isInsert && rule.User_Role__c != triggerOldMap.get(rule.Id).User_Role__c))
            rule.User_Role__c.addError('This feature is currently disabled.');
        }              
      }
        }    
        if(Trigger.isUpdate)
        {
            List<Account_Reassignment_Rule__c> listOfAccountReassignmentRule = new List<Account_Reassignment_Rule__c>();
            Set<Id> setOfChangedRuleIds= new Set<Id>();
            for(Account_Reassignment_Rule__c rule : triggerNew)
            {
              if(rule.Changed_GDRAT__c && (rule.Territory_ID__c!=triggerOldMap.get(rule.Id).Territory_ID__c || rule.SubTerritory__c!= triggerOldMap.get(rule.Id).SubTerritory__c))
              {
                setOfChangedRuleIds.add(rule.Id);
              }
                if(rule.Associated_User_RSM__c!=null && (rule.Associated_User_RSM__c!=triggerOldMap.get(rule.Id).Associated_User_RSM__c))
                {
                    listOfAccountReassignmentRule.add(rule);
                }
            }
            if(listOfAccountReassignmentRule.size()>0)
                updateRSMEmailsOnOrderApprovals(listOfAccountReassignmentRule);
            if(setOfChangedRuleIds.size()>0)
              updateGDRATOnAccounts(setOfChangedRuleIds,rulesToUpdateIdMap.keySet());
        }
  }
	/**
		IsUserRoleValid()
		- This function ensures the user choses a value that is a valid picklist value for User_role__c
	*/
	public static Boolean IsUserRoleValid(String pRole)
	{
		Boolean validFlag = false;
		// Check if the Role matches a piclist value
		for(Schema.PicklistEntry f : ple)
		{
			if(f.getValue() == pRole)
			{
				validFlag=true; 
				break;
			}
		}
		return validFlag;			
    }
    /**
    	updateGDRATOnAccounts()
    -Update GDRAT on all accounts owned by the changed rule's associated user.
    **/
	public static void updateGDRATOnAccounts(Set<Id> setOfChangedRuleIds,Set<Id> ruleIdsForUserRoleUpdate)
	{

		if(!updateGDRATOnAccountsFirstRunFlag)
			return;

		Set<Id> userIdSet = new Set<Id>();
		Map<Id,Account_Reassignment_Rule__c> userIdToRuleMap= new Map<Id,Account_Reassignment_Rule__c>();
		Map<Id,String> userIdToAKAMTerritoryIdMap= new Map<Id,String>();

		//Map<Id,List<Account>> userIdToAccountsMap = new Map<Id,List<Account>> ();
		//List<Account> listOfAccountsToUpdate = new List<Account>();
		//List<Account_Reassignment_Rule__c> resetGDRATOnRuleList = new List<Account_Reassignment_Rule__c>();
		
		for(Account_Reassignment_Rule__c rule :[Select Id, 
											  Associated_User__c,
											  /*Parent_Division__c,Division__c,Region__c,Area__c,*/
											  TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c,
											  Territory_ID__r.AKAM_Territory_Mapping_ID__c,SubTerritory__c
									   from Account_Reassignment_Rule__c 
									   where Id IN :setOfChangedRuleIds])
		{
			//create a set of user ids
			userIdSet.add(rule.Associated_User__c);
			//create a map of user->account reassignment rule
			userIdToRuleMap.put(rule.Associated_User__c,rule);
			//CR 2987156 
			//create a map of user-> AKAM Territory Mapping ID of Territory Mapping on Rule
			userIdToAKAMTerritoryIdMap.put(rule.Associated_User__c,rule.Territory_ID__r.AKAM_Territory_Mapping_ID__c);		
		}

	
		System.debug('list of users changed ' + userIdSet.size());
		System.debug('list of rules changed ' + setOfChangedRuleIds.size());

		// Sonali Tandon : Batching GDRAT updation on accounts for CR 2987156
		UpdateGDRATOnAccountsBatchClass batchObj = new UpdateGDRATOnAccountsBatchClass(userIdToRuleMap,userIdSet,userIdToAKAMTerritoryIdMap);
		database.executebatch(batchObj);

	//	if(ruleIdsForUserRoleUpdate.size()>0)
	//		UpdateOwnerRole(ruleIdsForUserRoleUpdate);			

		// create a map of user->user's accounts
		/*for(Account acc : [Select OwnerId,Id,Name,Parent_Division__c,Division__c,Region__c,Area__c FROM Account WHERE OwnerId IN : userIdSet])
		{
			if (!userIdToAccountsMap.containsKey(acc.OwnerId))
				userIdToAccountsMap.put(acc.OwnerId, new  List<Account>{acc});
			else
				userIdToAccountsMap.get(acc.OwnerId).add(acc);			
		}
		System.debug('userIdToAccountsMap' +userIdToAccountsMap.size());
		
		// populate each account's GDRAT with the rule's GDRAT
		for(Id userId : userIdToAccountsMap.keySet())
		{
			for(Account account : userIdToAccountsMap.get(userId))
			{
				System.debug('account ' + account.Name);
				account.Parent_Division__c = userIdToRuleMap.get(userId).Parent_Division__c;
				account.Division__c = userIdToRuleMap.get(userId).Division__c;
				account.Region__c = userIdToRuleMap.get(userId).Region__c;
				account.Area__c = userIdToRuleMap.get(userId).Area__c;
				account.Validation_Override__c = true;
				listOfAccountsToUpdate.add(account);
			}

			// reset Change Associated Account checkbox = false
			Account_Reassignment_Rule__c accReassignmentRule = new Account_Reassignment_Rule__c(Id = userIdToRuleMap.get(userId).Id);
			accReassignmentRule.Changed_GDRAT__c = false;
			resetGDRATOnRuleList.add(accReassignmentRule);
		}
		System.debug('listOfAccountsToUpdate size' +listOfAccountsToUpdate.size());

		if(listOfAccountsToUpdate!=null && listOfAccountsToUpdate.size()>0)
			update listOfAccountsToUpdate;
		if(resetGDRATOnRuleList!=null && resetGDRATOnRuleList.size()>0)
			update resetGDRATOnRuleList;*/

		updateGDRATOnAccountsFirstRunFlag = false;

	}

    public static void updateRSMEmailsOnOrderApprovals(List<Account_Reassignment_Rule__c> listOfAccountReassignmentRule)
    {
        //get ownerids from rules
        List<Id> listOfOwnerIds = new List<Id>();
        Map<Id, String> ownerIdToRSMUserIdMap = new Map<Id, String>();
        List<Id> listOfRSMIds = new List<Id>();
        for(Account_Reassignment_Rule__c rule : listOfAccountReassignmentRule)
        {
            listOfOwnerIds.add(rule.OwnerId);
            ownerIdToRSMUserIdMap.put(rule.OwnerId, rule.Associated_User_RSM__c);
            listOfRSMIds.add(rule.Associated_User_RSM__c);
        }
        // get the list of accounts from requests by matching Account_Owner__c
        Set<Id> setOfAccIds = new Set<Id>();
        Map<Id, String> accIdToRSMUserIdMap = new Map<Id, String>();
        for(Account_Reassignment__c acr : [select Id, Account__c, Account_Owner__c from Account_Reassignment__c where Account_Owner__c in :listOfOwnerIds])
        {
            if(!setOfAccIds.contains(acr.Account__c))
            {
                setOfAccIds.add(acr.Account__c);
                accIdToRSMUserIdMap.put(acr.Account__c, ownerIdToRSMUserIdMap.get(acr.Account_Owner__c));
            }
        }
        List<Id> listOfAccIds = new List<Id>();
        listOfAccIds.addAll(setOfAccIds);
        if(listOfAccIds!=null && listOfAccIds.size()>0)
        {
            Map<Id, String> userIdToEmailMap = new Map<Id, String>();
            for(User u : [select Id, Email from User where Id in :listOfRSMIds])
            {
                userIdToEmailMap.put(u.Id, u.Email);
            }
            List<Order_Approval__c> listOfOrderApprovals = new List<Order_Approval__c>();
            //SFDC-3831
            for( Order_Approval__c orderApproval : [select Id, Associated_Opportunity__r.AccountId from Order_Approval__c where Associated_Opportunity__r.AccountId in :listOfAccIds and (Associated_Opportunity__r.isClosed=false)])
            {
                orderApproval.RSM_Email__c = userIdToEmailMap.get(accIdToRSMUserIdMap.get(orderApproval.Associated_Opportunity__r.AccountId));
                orderApproval.Validation_Override__c = true;
                listOfOrderApprovals.add(orderApproval);
            }
            if(listOfOrderApprovals.size()>0)
                update(listOfOrderApprovals);
        }
    }
	/**
		UpdateOtherRules()
		- When AccountReassignmentRule.User_Role__c is updated, change the User_Role on all other rules that have the same Associated_User.
	*/	
	public static void UpdateOtherRules(Account_Reassignment_Rule__c[] pRulesList)
	{
		// Make a map of User -> Role
		Map<Id,String> usrRuleRoleMap = new Map<Id,String>();
		for(Account_Reassignment_Rule__c rule : pRulesList)
			usrRuleRoleMap.put(rule.Associated_User__c, rule.User_Role__c);
		// Get all the Rules that have same Associated User
		List<Account_Reassignment_Rule__c> rulesToUpdate = [select Id, 
																   User_Role__c,
																   Associated_User__c
															from Account_Reassignment_Rule__c
															where Associated_User__c IN :usrRuleRoleMap.keySet() and
																  Id NOT IN :pRulesList];
		// Update the User_Role for the selected rules
		for(Account_Reassignment_Rule__c rule : rulesToUpdate)
			rule.User_Role__c = usrRuleRoleMap.get(rule.Associated_User__c);
		if(rulesToUpdate.size()>0)
			update rulesToUpdate;
	}
}