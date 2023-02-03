/***
    UserTrigger_ai
    @author Karteek Mekala <kmekala@akamai.com>
    @Description : This trigger is called on 'after insert'
                   Since during insert, the autoId is not generated -> fire the trigger again through a DML-SOQL.
	Test Class 	 : SC_SI_AllUseCases_TC
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N   21/01/11    CR 919522 Developments related to PRM
                                - Added logic to update Current lincences in Account level when user is Added or becomes Active
                                - Added logic to update Current lincences in Account level when user becomes InActive
   Vinayendra T N   18/5/11     CR 1107453 PRM: Sync partner contact record and partner user record
                                - Change in email or active should change email and Active Partner flag respectively
   Chandra Lohani   15/5/2011   CR 1136602:- Email Alert to User when it gets actiavted in Salesforce 
                                - Added logic to send email to user when its account gets activated, exception has been given to partner user
   Ali KM           17/082011   CR 1230484 PRM: When partner admin is intially set up, cc relevant akamai users  
                                - Commenting out the code that triggers Email to Partner Admin, now this is handled in PartnerUserController itself.
                                This avoids sending 2 emails to the Partner Admins.                                                                 
   Vinayendra       02/2012     CR 1502425 PRM Need to allow Partner Support the capability to add sharing rules to Fund Budget
                                - Added logic to create sharing rules for budget when the partner for that particular is created

   Vamsee			01/12/20	ESESP-3015 Service Incident Lightning Migration
   
*/   
trigger UserTrigger_ai on User (after insert, after update) 
{
    
    List<Id> iraptUserIdList = new List<Id>();
    List<Id> nonIraptUserIdList = new List<Id>();
        
    //When the new user record is created
    if(Trigger.isInsert){
        for(User eachUser : Trigger.new){
            if(eachUser.SC_SI_IRAPT_User__c == True){
                iraptUserIdList.add(eachUser.Id);
            }
            else{
                nonIraptUserIdList.add(eachUser.Id);
            }
    	}
        if(!Test.isRunningTest())
        	SC_SI_Utility.AssignPermissionSet(iraptUserIdList, nonIraptUserIdList, False);
    }
    
    //When the IRAPT User check box is changed (It is not possible to combine both because Update & Insert is handled differently)
    else if(Trigger.isUpdate){
        for(User eachUser : Trigger.new){
        	if(eachUser.SC_SI_IRAPT_User__c != Trigger.oldmap.get(eachUser.Id).SC_SI_IRAPT_User__c){
                if(eachUser.SC_SI_IRAPT_User__c == True){
                	iraptUserIdList.add(eachUser.Id);
            	}
            	else{
                	nonIraptUserIdList.add(eachUser.Id);
            	}
            }
        }
        if(iraptUserIdList.size() > 0 || nonIraptUserIdList.size() > 0){
            if(!Test.isRunningTest())
                SC_SI_Utility.AssignPermissionSet(iraptUserIdList, nonIraptUserIdList, True); 
        } 
       	
    }
    
   
    
    
    /*
    list<User> UsrUpdateAdd = new list<User>();
    list<User> UsrUpdateRemove = new list<User>();
    list<User> UsrEmailUpdate = new list<User>();
    list<User> FirstUsersList = new list<User>();
    list<User> AdminUsersList = new list<User>();
    set<id> FirstPartnerUsersAccountIds = new set<id>();
    list<String> PartnerAdminIdStrList = new list<String>();
    String userTypeStr = null;
    String userIdAccId = null;
    
    if (Trigger.isInsert)
    {
        UserTriggerClass.Set_AKAM_User_ID_After(Trigger.new);
        for(User u : Trigger.new)
        {
            userTypeStr = null;
            userTypeStr = u.UserType;
            //check if User is a Partner User
            if((userTypeStr != null && u.UserType.contains('Partner')) || u.contactid!=null)
            {
                UsrUpdateAdd.add(u);
                UsrEmailUpdate.add(u);
                if(PRM_opportunity.FirstPartnerUser.get(u.Contactid)!=null)
                    FirstUsersList.add(u);
                //Check if current user is first Partner User for that particular account
                if(PRM_opportunity.FirstPartnerUserForAccount.get(u.Contactid)!=null)
                    FirstPartnerUsersAccountIds.add(u.AccountId__c);
                if(u.User_Profile_Name__c==PRM_Settings__c.getInstance('Partner Admin Profile').Value__c)
                AdminUsersList.add(u);
            }
        }
    }
    
    // Call only for Edits...   
    if (!Trigger.isInsert)  
    {
        Features_Toggle__c customSettings = Features_Toggle__c.getInstance('UpdateContactOwnerForInActiveUsers');
        UserTriggerClassSettings__c userTriggerCustomSettings = UserTriggerClassSettings__c.getInstance('v1.0'); 
        if(customSettings.Toggle__c == true)
        {                   
            List<User> inActiveUserList = new List<User>();
            //String exemptedUserAlias = 'CINTEGRA, ONA, BTS-USER';
            String exemptedUserAlias = userTriggerCustomSettings.exemptedUserAlias__c;
            
            for (User u : Trigger.new)
            {
                //check if User is a Partner User
                userTypeStr = null;
                userTypeStr = u.UserType;               
                // Getting @future to @future exception; to avoid this updating Contacts only if isActive is switching between Active to InActive.
                if (u.IsActive==false && (!exemptedUserAlias.contains(u.Alias)) && Trigger.oldMap.get(u.Id).IsActive==true && !(u.UserType.contains('Partner')))                
                    inActiveUserList.add(u);
            }           
            if (inActiveUserList.size()>0)
            {
                UserTriggerClass usrTriggerClass = new UserTriggerClass();
                usrTriggerClass.resetContactOwnerForInActiveUsers(inActiveUserList);
            }
        }
        
        // Merge Contract Header Share Code
        //Features_Toggle__c customSettings = Features_Toggle__c.getInstance('UpdateContactOwnerForInActiveUsers');
        //UserTriggerClassSettings__c userTriggerCustomSettings = UserTriggerClassSettings__c.getInstance('v1.0'); 
       // if(customSettings.Toggle__c == true)
        //{                   
            List<Id> activatedUserIdList = new List<Id>();
            //String exemptedUserAlias = 'CINTEGRA, ONA, BTS-USER';
            String exemptedUserAlias = userTriggerCustomSettings.exemptedUserAlias__c;
            
            for (User u : Trigger.new)
            {
                //check if User is a Partner User
                userTypeStr = null;
                userTypeStr = u.UserType;
                if (u.IsActive && (!exemptedUserAlias.contains(u.Alias)) && Trigger.oldMap.get(u.Id).IsActive==false && !(u.UserType.contains('Partner')))                
                    activatedUserIdList.add(u.Id);
            }           
            if (activatedUserIdList.size()>0 && GsmUtilClass.isFeatureToggleEnabled('isContractShareEnabled')) // if toggle is off; dont do anything.
            {  
                UserTriggerClass.updateMCHShare(activatedUserIdList);
            }
        //}
        
        
    
        for(User u : Trigger.new)
        {       
                //check if User is a Partner User
                userTypeStr = null;
                userTypeStr = u.UserType;
                if((userTypeStr != null && u.UserType.contains('Partner')) || u.contactid!=null)
                {
                    //check if the User is getting active , if yes update the current licences count
                    if((Trigger.oldMap.get(u.id).IsActive == False) && (u.IsActive == True))
                        UsrUpdateAdd.add(u);
                    //check if the User is getting inactive , if yes update the current licences count
                    if((Trigger.oldMap.get(u.id).IsActive == True) && (u.IsActive == False))
                        UsrUpdateRemove.add(u);
                    if((Trigger.oldMap.get(u.id).Email != u.Email))
                        UsrEmailUpdate.add(u);
                }
        }
    }
    //Increase the Current licences(account) by 1 and set the Active Partner(contact) to true
    if(UsrUpdateAdd.size()>0)
        PRM_opportunity.LimitPartnerUserUpdate(UsrUpdateAdd,True);
    //Decrease the Current licences by 1 and set the Active Partner(contact) to false
    if(UsrUpdateRemove.size()>0)
        PRM_opportunity.LimitPartnerUserUpdate(UsrUpdateRemove,False);
    //update the email of contact
    if(UsrEmailUpdate.size()>0)
        PRM_opportunity.UpdateContactEmail(UsrEmailUpdate);
    if(FirstUsersList.size()>0)
        PRM_opportunity.UpdateRoleOfPartner(FirstUsersList);
        
    if(FirstPartnerUsersAccountIds.size()>0)
    {
        
        //convert a set to a list
        list<id> SetIdsToList = new list<id>();
        for(id accid:FirstPartnerUsersAccountIds)
        SetIdsToList.add(accid);
        PRM_opportunity.UpdateFundBudgetShares(SetIdsToList);
    }
        
    //if(AdminUsersList.size()>0)
    //  PRM_opportunity.SendEmailToAdmin(AdminUsersList);
    Features_Toggle__c userActivationSendMailCustomSettings = Features_Toggle__c.getInstance('UserActivationSendEmail');
    if(Trigger.isUpdate)
    {
        userTypeStr=null;
        if(userActivationSendMailCustomSettings.Toggle__c==true)
        {
            List<User> newActiveUserList=new List<User>();
            for(User user: Trigger.new)
            {
                userTypeStr=user.UserType;
                if(!(userTypeStr != null && userTypeStr.contains('Partner')))
                {
                    if(user.IsActive && user.IsActive!=Trigger.oldMap.get(user.Id).IsActive)
                    {
                        newActiveUserList.add(user);
                    }
                }
            }
            UserTriggerClass.sendEmailToUsers(newActiveUserList);
        }
    }
    
    //CR 1268122: Enable Read/Write access to the Partner Admins.
    //if(UserTriggerClass.updateAccountShareSettingFirstRunFlag)
    //{
        for (User u: Trigger.new)
        {
            if (trigger.isInsert || (trigger.isUpdate && u.profileId != trigger.oldMap.get(u.Id).profileId))
            {
            userTypeStr = null;
            userTypeStr = u.UserType;
            if (u.IsActive)
            {
                //check if User is a Partner User
                if((userTypeStr != null && u.UserType.contains('Partner')) || u.contactid!=null)
                {
                    if (u.ProfileId == PRM_Settings__c.getInstance('Partner Admin Id').Value__c)
                    {
                       userIdAccId = u.Id + '#' + u.AccountId__c;
                        PartnerAdminIdStrList.add(userIdAccId);
                    }
                if (PartnerAdminIdStrList.size()>0)
                {
                   
                    UserTriggerClass.updateAccountShareSettingFuture(PartnerAdminIdStrList);
                                      
                }
               }
            }
        }
    }
  // UserTriggerClass.updateAccountShareSettingFirstRunFlag = false;
    //}
    */
}