/**
 * Trigger adds the akam id based on a sequence because
 * there is no workflow for user unlike other objects
 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Dan Pejanovic    12/2009     Created Class
 * Karteek Kumar M  01/2010     Change approach
 * Vinayendra       01/2011     CR 919522 Developments related to PRM
                                - Added logic to check if the Current licences to Less than Max lincences for a particular set of accounts.
* Chandra Lohani    15/07/2011  - Added logic to update user Activated_On date when user gets activated for CR 1184251                              
* Vinayendra        02/2012     CR 1502425 PRM Need to allow Partner Support the capability to add sharing rules to Fund Budget
                                - Added logic to create sharing rules for budget when the partner for that particular is created
* Ali KM            27/Mar/2012 CR 1610815 Apex Error when creating External Chatter User - Unable to login
                                - Commenting out the code that calls UserTriggerClass.Set_AKAM_User_ID_After() method as this is getting called in UserTrigger_ai.trigger.                              
* Akhila            22/04/2015  - Adding logic to check Knowledge user checkbox when User is added to GSS profile.
*
* Jaya              19/01/2016  - Added Logic to Automate PSA License assignment for PSA Profiles.
* Vamsee S          30/03/2016      CR 3293511- Bypassing the code for connection user
* sharath           04/04/2016  - Added logic to Automate PSA License de-provisioning when the profile changes from PSA to non-PSA 
* Harshil			02/09/2020  - ESESP-4125 - Added logic to mark Is_DR_picked__c value when profile changes (for Employee DR Job)
* Vamsee			02/11/2020  - ACD2-275 - Set the Agent Id and MobileNumber
*/
trigger UserTrigger_bi_bu on User (before insert, before update) 
{
    //bypass logic for Connection User
    if(!UserInfo.getName().equalsIgnoreCase('Connection User')){
    Set<Id> GSSProfileIds = new Set<Id>();
    for( SC_KB_GSS_profiles__c rec : SC_KB_GSS_profiles__c.getAll().Values())
    {
        GSSProfileIds.add(rec.ProfileId__c);
    }
    for(User u: Trigger.New)
    {
        //if user is added to GSS profile check knowledge user checkbox.
        if((Trigger.isinsert || (Trigger.isupdate && Trigger.oldMap.get(u.Id).ProfileId!= u.ProfileId)) &&
        GSSProfileIds.contains(u.ProfileId)){
            u.UserPermissionsKnowledgeUser = true;
        }
        
    }

    /*Start of changes by Jaya to automate license assignment to Users*/
    Set<Id> PSAProfileIds = new Set<Id>();
    List<User> usersForAutomation = new List<User>();

    //Start of changes by sharath to de-provision PSA License       
    //creating a map of userID to the Old profile
    Map<String,String> userIdToOldProfile = new Map<String,String>();
    //End of changes by sharath

    for( PSA_Profiles_For_License_Automation__c csProfiles : PSA_Profiles_For_License_Automation__c.getAll().Values())
    {
        PSAProfileIds.add(csProfiles.Profile_Names__c);
    }

    for(User u: Trigger.New)
    {
        if( ( (Trigger.isupdate && Trigger.oldMap.get(u.Id).ProfileId!= u.ProfileId && !PSAProfileIds.contains(Trigger.oldMap.get(u.Id).ProfileId)) ) && PSAProfileIds.contains(u.ProfileId) )
        {
            usersForAutomation.add(u);
        }
        //changes by sharath: removed the Trigger.new check as its handled in the after insert trigger
        else if(( (Trigger.isupdate && Trigger.oldMap.get(u.Id).ProfileId!= u.ProfileId && PSAProfileIds.contains(Trigger.oldMap.get(u.Id).ProfileId)) ) && !PSAProfileIds.contains(u.ProfileId) )
        {
            userIdToOldProfile.put(u.id,Trigger.oldMap.get(u.Id).ProfileId);    
        }
        //changes by Harshil: ESESP-4125
        if(Trigger.isUpdate && Trigger.isBefore && Trigger.OldMap.get(u.Id).BMCServiceDesk__User_License__c == 'Salesforce' && u.BMCServiceDesk__User_License__c != 'Salesforce'){
            u.Is_DR_Picked__c = true;
        }
        
        else if(Trigger.isUpdate && Trigger.isBefore && Trigger.OldMap.get(u.Id).BMCServiceDesk__User_License__c != 'Salesforce' && u.BMCServiceDesk__User_License__c == 'Salesforce'){
            u.Is_DR_Picked__c = false;
        }
        //end of changes by Harshil
        
        //Changes by Vamsee : ACD2-275
        if(Trigger.isBefore && (Trigger.isinsert || (Trigger.isupdate && Trigger.OldMap.get(u.Id).MobilePhone != u.MobilePhone)))
            u.MobilePhoneText__c = u.MobilePhone;
        
        if(Trigger.isBefore && u.cnx__Agent_ID__c == null && u.alias != null)
            u.cnx__Agent_ID__c = String.valueOf(u.alias).toLowercase();
        //end of changes by Vamsee
            
    }
    if(usersForAutomation != null && usersForAutomation.size() > 0)
        PSA_AutomateLicenseAssignment.assignPSALicenseToUser(usersForAutomation);

     //Changes by sharath: calling the function that creates records in the object: PSA_License_DeProvisioned_User__c   
    if(userIdToOldProfile != null && userIdToOldProfile.size() > 0)
    {        
        PSA_AutomateLicenseAssignment.addRecordsToLicenseHistoryObject(userIdToOldProfile);
    }

    /*End of changes by Jaya to automate license assignment to Users*/
    /*
    UserTriggerClass.Set_AKAM_User_ID_Before(Trigger.new);
    list<User> UsrUpdateAdd = new list<User>();
    for(User u : Trigger.new)
        u.Alias = u.Alias.toUpperCase();
    String userTypeStr = null;
    if (Trigger.isInsert)
    {
        //UserTriggerClass.Set_AKAM_User_ID_After(Trigger.new);
        for(User u : Trigger.new)
        {
            userTypeStr = null;
            userTypeStr = u.UserType;
            //throw new CustomException('here0'+u.UserRoleId);
            //throw new CustomException('Size'+u.contactid);
            //check if User is a Partner User
            if((userTypeStr != null && userTypeStr.contains('Partner')) || u.contactid!=null)
            {
                UsrUpdateAdd.add(u);
                //Assuming that Partner Users are created only by UI and not by data loader
                //Check if partner Users`s role is null in other words check if this is the first user for the a/c
                //throw new CustomException('here'+u.UserRoleId);
                
                if(u.UserRoleId==null )
                {
                    //if role is null then it will be the first partner for that particular account
                    PRM_opportunity.FirstPartnerUserForAccount.put(u.Contactid,u);
                    //throw new CustomException('Here'+u.Contactid+':'+u.UserRoleId);
                    if(u.User_Profile_Name__c==PRM_Settings__c.getInstance('Partner Admin Profile').Value__c)
                        PRM_opportunity.FirstPartnerUser.put(u.Contactid,u);
                }//throw new CustomException('here1'+u.UserRoleId);
            }
        }
    }   
    if (!Trigger.isInsert)  
    {
        for(User u : Trigger.new)
        {
            userTypeStr = null;
            userTypeStr = u.UserType;
            //check if User is a Partner User
            if((userTypeStr != null && u.UserType.contains('Partner')) || u.contactid!=null)
            {
                if(Trigger.oldMap.get(u.id).IsActive == False && u.IsActive == True)
                    UsrUpdateAdd.add(u);
            }
        }
    }
    if(UsrUpdateAdd.size()>0)
    PRM_opportunity.LimitPartnerUserCreation(UsrUpdateAdd);
    
    if(Trigger.isUpdate)
    {
        List<User> activatedUserList=new List<User>();
        List<User> inactivatedUserList=new List<User>();
        for(User u : Trigger.new)
        {
                if((u.UserType.contains('Standard') && u.UserType != Trigger.oldMap.get(u.Id).UserType && u.IsActive) || (u.IsActive && u.IsActive!=Trigger.oldMap.get(u.Id).IsActive))
                    {
                        activatedUserList.add(u);
                    }
                if(!u.IsActive && u.IsActive!=Trigger.oldMap.get(u.Id).IsActive)
                {
                    inactivatedUserList.add(u);
                }
        }
        if(activatedUserList.size()>0)
        {
         UserTriggerClass.updateUserActivationInactivationDate(activatedUserList,True);
        }
        if(inactivatedUserList.size()>0)
        {
         UserTriggerClass.updateUserActivationInactivationDate(inactivatedUserList,false);
        }
        
        
    }
    */
    }
}