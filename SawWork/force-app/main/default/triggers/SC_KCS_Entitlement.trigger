/*=======================================================================================+
    Trigger name        :   SC_KCS_Entitlement
    Author              :   Vandhana Krishnamurthy
    Created             :   05 April 2017
    Purpose             :   CR 3696732 : Change the KBAR on Home Page 2.0 to KCS Level
------------------------------------------------------------------------------------------
Date		|	Developer	|	JIRA		|	Comments
23/05/2017		Vamsee S		ESESP-550		AkaTec KCS Enhancement Requests – Phase II
+=======================================================================================*/

trigger SC_KCS_Entitlement on KCS_Entitlement__c (before insert, before update, after insert, after update, after delete) 
{
	// ensure Trigger.new does not have duplicate entries for same User
	public static Map<Id,KCS_Entitlement__c> userKCSETrigMap = new Map<Id,KCS_Entitlement__c>();

	if(Trigger.isInsert || Trigger.isUpdate)
	{
		for(KCS_Entitlement__c eachKCSE : Trigger.new)
		{
			if(!userKCSETrigMap.containsKey(eachKCSE.User__c))
			{
				userKCSETrigMap.put(eachKCSE.User__c, eachKCSE);
			}
			else
			{
				eachKCSE.addError('Duplicate entries found for the same User.');
			}
		}
	}
	
	List<KCS_Entitlement__c> lstKCSE = new List<KCS_Entitlement__c>();

	Set<Id> errorIDs = new Set<ID>();

	if(Trigger.isInsert && Trigger.isBefore)
	{
		errorIDs = new Set<ID>();
		lstKCSE = [Select User__c,KCS_Level__c from KCS_Entitlement__c where User__c in :userKCSETrigMap.keySet()];
		if(lstKCSE.size() > 0)
		{
			for(KCS_Entitlement__c kcseItem : lstKCSE)
			{
				if(userKCSETrigMap.containsKey(kcseItem.User__c))
				{
					errorIDs.add(kcseItem.User__c);
				}
			}

			for(KCS_Entitlement__c eachKCSEItem : Trigger.new)
			{
				if(errorIDs.contains(eachKCSEItem.User__c))
				{
					eachKCSEItem.addError('User with KCS Level already exists');
				}
			}
		}
		// add error to insert record
	}	
   	else 
   	if(Trigger.isUpdate && Trigger.isBefore)
	{
		errorIDs = new Set<ID>();
		// updates
		lstKCSE = [Select User__c,KCS_Level__c from KCS_Entitlement__c where User__c in :userKCSETrigMap.keySet() AND Id NOT IN :Trigger.newMap.keySet()];
		if(lstKCSE.size() > 0)
		{
			for(KCS_Entitlement__c kcseItem : lstKCSE)
			{
				if(userKCSETrigMap.containsKey(kcseItem.User__c))
				{
					errorIDs.add(userKCSETrigMap.get(kcseItem.User__c).Id);
				}
			}

			for(Id eachId : errorIDs)
			{
				Trigger.newMap.get(eachId).addError('User with KCS Level already exists');
			}
		}
	}	

	List<User> updateUserList = new List<User>();
	if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter)
	{
		Map<Id,User> userMap = new Map<Id,User>([Select KCS_Level__c, SC_KCS_Coach__c from User where Id in :userKCSETrigMap.keySet()]);

		for(Id userId : userMap.keySet())
	    {
	        userMap.get(userId).KCS_Level__c = userKCSETrigMap.get(userId).KCS_Level__c;
			userMap.get(userId).SC_KCS_Coach__c = userKCSETrigMap.get(userId).KCS_Coach__c;
	        updateUserList.add(userMap.get(userId));
	    }
	}
	
	if(Trigger.isDelete)
	{
		List<Id> userIds = new List<Id>();
		for(KCS_Entitlement__c eachKCSE : Trigger.old)
		{
			userIds.add(eachKCSE.User__c);
		}
		List<User> userList = [Select KCS_Level__c, SC_KCS_Coach__c from User where Id in :userIds];
		for(User eachUser : userList)
		{
			eachUser.KCS_Level__c = '';
            eachUser.SC_KCS_Coach__c = null;
			updateUserList.add(eachUser);
		}
	}

	update updateUserList;
}