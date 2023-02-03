/**

 * Trigger populates the default profile and Default Role for user

 * Whenever a user gets inserted or updated it will gets the default role and profile for an user
   from a lookup object(User_Role_Profile_Map_c) based on following user fields: 
   Division__c
   Department__c
   Cost_Center__c
   Business_Unit_Name__c
   Business_Unit_Number__c
   Title__c

 *

* History:

 * =========================

 * Developer		Date		Description

 * --------------------------------------------------------------------------------------------------

 * Chandra Lohani	2/11/2010		Created Class 
   Chandra Lohani   17/01/2011      Commented code

 
*/

trigger UserAutoRoleProfileMappingTrigger_bi_bu on User (before insert, before update) {
	/*
	private Features_Toggle__c featureToggle = Features_Toggle__c.getInstance('UserAutomationClass');
	if(!featureToggle.Toggle__c)
	{
		List<User> userList=new List<User>();
		for(User user : Trigger.new)
		{
			Boolean isNotNull=user.Business_Unit_Name__c!=null && user.Title !=null && user.Business_Unit_Number__c!=null && user.Division!=null && user.Department!=null && user.Cost_Center__c!=null;
			Boolean isChanged=Trigger.isUpdate &&(user.Business_Unit_Name__c!=Trigger.oldMap.get(user.Id).Business_Unit_Name__c || user.Title!=Trigger.oldMap.get(user.Id).Title || user.Business_Unit_Number__c!=Trigger.oldMap.get(user.Id).Business_Unit_Number__c
			                 || user.Division!=Trigger.oldMap.get(user.Id).Division || user.Department!=Trigger.oldMap.get(user.Id).Department || user.Cost_Center__c!=Trigger.oldMap.get(user.Id).Cost_Center__c);
			
			if(isNotNull && (Trigger.isInsert || isChanged))
			{
				userList.add(user);
			}
		}
	     if(userList.size()>0)
	     {
	     	UserAutomationClass userAutomation=new UserAutomationClass();
	     	userAutomation.assignProfileAndRole(userList); 
	     }
	}
    //*/ 
}