public without sharing class UserTriggerHandler extends ITrigger {
    
    private static List<User> usersForAutomationActions = new List<User>();

    private List<User> filterUsersForAutomation(List<User> newList, Map<Id, User> oldMap)
    {
        List<User> filteredUsers = new List<User>();
        for(User u : newList)
        {
            System.Debug(LoggingLevel.Error, 'AGH_ checking conditions'+oldMap.get(u.Id).isActive+' and '+u.IsActive);
            if(oldMap.get(u.Id).ProfileId!= u.ProfileId || oldMap.get(u.Id).UserRoleId!=u.UserRoleId || (oldMap.get(u.Id).isActive==false && u.IsActive==true))
            {
                filteredUsers.add(u);
            }
        }
        return filteredUsers;
    }

    
    public override void beforeInsert(List<SObject> so) {
        beforeInsertUpdate(true, null, (List<User>)so, null, null);
    }
    
    public override void beforeUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        beforeInsertUpdate(false, (List<User>)oldSo.values(), (List<User>)so.values(), (Map<Id, User>)oldSo, (Map<Id, User>)so);
    }
    public override void beforeDelete(Map<Id, SObject> so) {}
    
    public override void afterInsert(Map<Id, SObject> so) {
        afterInsertUpdate(true, null, (List<User>)so.values(), null, (Map<Id, User>)so);
    }
    public override void afterUpdate(Map<Id, SObject> oldSo, Map<Id, SObject> so) {
        afterInsertUpdate(false, (List<User>)oldSo.values(), (List<User>)so.values(), (Map<Id, User>)oldSo, (Map<Id, User>)so);
    }
    public override void afterDelete(Map<Id, SObject> so) {}
    
    public void beforeInsertUpdate(Boolean isInsert, User[] oldList, User[] newList, Map<Id, User> oldMap, Map<Id, User> newMap) {


        L2Q_UserTriggerClass.Set_AKAM_User_ID_Before(newList);
        for(User u : newList)
            u.Alias = u.Alias.toUpperCase();
        String userTypeStr = null;
        if(trigger.isInsert || trigger.isUpdate){
            L2Q_UserTriggerClass.contentLicenceupdate(newList); // SDFC -7428 
        }
        if (isInsert)
        {
        /**Begin Rajesh Kumar JIRA# > SFDC-5088  */
       //L2Q_UserTriggerClass.contentLicenceupdate(newList);
        /**End Rajesh Kumar JIRA# > SFDC-5088  */
            //UserTriggerClass.Set_AKAM_User_ID_After(newList);
            for(User u : newList)
            {
                //CR 2423559 - Need to set the UserPreferencesShowEmailToExternalUsers field (API access only) to true for all users being created in SF after community is enabled.
                u.UserPreferencesShowEmailToExternalUsers = true;
                userTypeStr = null;
                userTypeStr = u.UserType;
                //throw new CustomException('here0'+u.UserRoleId);
                //throw new CustomException('Size'+u.contactid);
                //check if User is a Partner User
                if((userTypeStr != null && userTypeStr.contains('Partner')) || u.contactid!=null)
                {
                    //Assuming that Partner Users are created only by UI and not by data loader
                    //Check if partner Users`s role is null in other words check if this is the first user for the a/c
                    //throw new CustomException('here'+u.UserRoleId);

                    if(u.UserRoleId==null )
                    {
                        //if role is null then it will be the first partner for that particular account
                        PRM_opportunity.FirstPartnerUserForAccount.put(u.Contactid,u);
                        //throw new CustomException('Here'+u.Contactid+':'+u.UserRoleId);
                        if(u.User_Profile_Name__c==GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile')) //SFDC-2304
                            PRM_opportunity.FirstPartnerUser.put(u.Contactid,u);
                    }//throw new CustomException('here1'+u.UserRoleId);
                }
            }
        }
        if (! isInsert)
        {
            //Changes by Vamsee - Update the User Chatter Email Settings(ESESP-1069)
            List<User> userChatterSettingsUpdate = new list<User>();

            //Changes by Pinkesh - ESESP-3613: Remove the KCS Coach value on the related Users in order to deactivate the user
            Set<Id> sInactiveUser = new Set<Id>();

            //Changes by Sharath for Delegated approval of timecards: FFPSA-142. Check id there is a change in the delegated approver of the user. If so, set a custom field with the delegated approver value and create a history record
            try
            {
                PSA_ProjectActions.updateCustomDelegatedApproverField(oldMap,newMap);
            }
            Catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Error in setting Delegated Approver',e.getMessage());
            }

            for(User u : newList)
            {
                userTypeStr = null;
                userTypeStr = u.UserType;
                if(oldMap.get(u.id).IsActive == True && u.IsActive == False)
                       //Shardul CR : 2037547
                        u.BMCSERVICEDESK__ISSTAFFUSER__C = False;
                        //Shardul
                String currentLoggedInUserType = UserInfo.getUserType();
                List<String> listOfFieldsToBeCheckedForChanges = Label.FieldsToBeDisallowedForUpdateByPartnerUser.split(',');
                Set<String> fieldsToBeCheckedForChanges = new Set<String>();
                fieldsToBeCheckedForChanges.addAll(listOfFieldsToBeCheckedForChanges);
               // Set<String> fieldsToBeCheckedForChanges = new Set<String>{ 'Username', 'CommunityNickname', 'FirstName', 'LastName', 'Title', 'Email', 'Phone', 'Extension', 'Fax', 'MobilePhone','Street', 'City' , 'State', 'PostalCode' , 'Country'};
                //if(!PartnerUserController.isEnablingNAPAccess && !PRM_opportunity.updateUserFutureFlag && currentLoggedInUserType=='PowerPartner' && Util.hasChanges(fieldsToBeCheckedForChanges, u, oldMap.get(u.Id)))
                //SFDC-5894
                if(!PRM_opportunity.updateUserFutureFlag && currentLoggedInUserType=='PowerPartner' && Util.hasChanges(fieldsToBeCheckedForChanges, u, oldMap.get(u.Id)))
                {
                    u.addError(Label.PartnerUserUpdateError);
                }
                //Changes by Vamsee - Update the User Chatter Email Settings(ESESP-1069)
                if(u.UserType == 'Standard' && u.Department != null && oldMap.get(u.Id).Department!= u.Department && u.Department.containsignorecase('AkaTec')){
                    userChatterSettingsUpdate.add(u);
                }

                //Changes by Pinkesh - ESESP-3613: Remove the KCS Coach value on the related Users in order to deactivate the user
                if(!u.IsActive && oldMap.get(u.Id).IsActive != u.IsActive){
                    sInactiveUser.add(u.Id);
                }
                
                //Added by Vivek - SFDC-5936 
                if(oldMap.get(u.id).ManagerId == null && u.ManagerId != null && u.Manager_Update_Timestamp__c == null){
                    u.Manager_Update_Timestamp__c = System.Now();
                }

            }
            //Changes by Vamsee - Update the User Chatter Email Settings(ESESP-1069)
            if(userChatterSettingsUpdate.size() > 0){
                SC_UserTriggerClass.updateUserChatterSettings(userChatterSettingsUpdate, False);
            }
            //Changes by Pinkesh - ESESP-3613: Remove the KCS Coach value on the related Users in order to deactivate the user
            if(sInactiveUser.size() > 0)
                SC_UserTriggerClass.updateChildusers(sInactiveUser);
        }

      List<User> activatedUserList=new List<User>();
            List<User> inactivatedUserList=new List<User>();
            //SFDC-8760 - Start
            List<User> inactivatedPartnerUserList = new List<User>();
            //SFDC-8760 - End
             for(User u : newList)
            {
                //Sonali Tandon CR 2720703 - Activate_on field not capturing the right information
                //on insert
                if(isInsert)
                {
                    if(u.IsActive)
                        activatedUserList.add(u);

                }
                //on update
                else
                {
                    if((u.UserType.contains('Standard') && u.UserType != oldMap.get(u.Id).UserType && u.IsActive) || (u.IsActive && u.IsActive != oldMap.get(u.Id).IsActive))
                            activatedUserList.add(u);

                    if(!u.IsActive && u.IsActive!=oldMap.get(u.Id).IsActive)
                    {
                        inactivatedUserList.add(u);
                        //Shardul CR : 2037547
                        u.BMCSERVICEDESK__ISSTAFFUSER__C = False;
                        //Shardul
                    }
                 }
                 //SFDC-8760 - Start
                if(Trigger.isUpdate && u.UserType.equalsIgnoreCase('PowerPartner') && !u.isActive && oldMap.get(u.Id).isActive != u.isActive) {
                    inactivatedPartnerUserList.add(u);
                }
                //SFDC-8760 - End
            }
            if(activatedUserList.size()>0)
            {
                L2Q_UserTriggerClass.updateUserActivationInactivationDate(activatedUserList,True);

            }
            if(inactivatedUserList.size()>0)
            {
             L2Q_UserTriggerClass.updateUserActivationInactivationDate(inactivatedUserList,false);
            }

            //SFDC-8760 - Start
            if(inactivatedPartnerUserList.size() > 0) {
                L2Q_ManagePartnerOperationsController.erasePermissionsAndRevokeAccess(inactivatedPartnerUserList);
            }
            //SFDC-8760 - End


            // Anand Hegde  - User automation SFDC-1030
            System.Debug(LoggingLevel.Error, 'AGH_ before update part');
            if(Trigger.isUpdate)
            {
                usersForAutomationActions = filterUsersForAutomation(newList, oldMap);
                System.Debug(LoggingLevel.Error, 'usersForAutomationActions size'+usersForAutomationActions.size());
                if(usersForAutomationActions.size()>0)
                    L2Q_UserTriggerClass.handleUserAutomationFieldUpdates(usersForAutomationActions);
            }
    }

    public void afterInsertUpdate(Boolean isInsert, User[] oldList, User[] newList, Map<Id, User> oldMap, Map<Id, User> newMap) {
        System.Debug('AGH_D UserTriggerClass afterInsertUpdate');
        List<UpdatedUser> partnerUsers = new List<UpdatedUser>();
        List<Id> managerChangedUsers = new List<Id>(); //SFDC-6258
        list<User> UsrEmailUpdate = new list<User>();
        list<User> FirstUsersList = new list<User>();
        list<User> AdminUsersList = new list<User>();
        //Changes by Vamsee - Update the User Chatter Email Settings(ESESP-1069)
        List<User> userChatterSettingsUpdate = new list<User>();
        set<id> FirstPartnerUsersAccountIds = new set<id>();
        list<String> PartnerAdminIdStrList = new list<String>();
        String userTypeStr = null;
        String userIdAccId = null;
        /*Begin Rajesh Kumar AKA JIRA# SFDC-5964 */
        String partneradminprofileId =  GsmUtilClass.getPRMSettingValue('Partner_Admin_Id');
        String partneruserprofileId =  GsmUtilClass.getPRMSettingValue('Partner_User_ID');
        /*End Rajesh Kumar AKA JIRA# SFDC-5964 */
        List<User> quipUserProvisionDeprovisionList = new List<User>();

        List<Id> usersAccountId = new List<Id>(); //SFDC-8975

        List<Id> addRpShareUsers = new List<Id>(); //SFDC-8975
        List<Id> deleteRpShareUsers = new List<id>(); //SFDC-8975


        if (isInsert)
        {
            SC_AddCommunityUserToGroups.findUserType(newList);
            L2Q_UserTriggerClass.Set_AKAM_User_ID_After(newList);
            for(User u : newList)
            {
                userTypeStr = null;
                userTypeStr = u.UserType;
                //check if User is a Partner User
                //SFDC-2741 Changing OR condition to AND
                if((userTypeStr != null && u.UserType.contains('Partner')) && u.contactid!=null)
                {
                    //AGH
                    partnerUsers.add(new UpdatedUser(u));
                    UsrEmailUpdate.add(u);
                    if(PRM_opportunity.FirstPartnerUser.get(u.Contactid)!=null)
                        FirstUsersList.add(u);
                    //Check if current user is first Partner User for that particular account
                    if(PRM_opportunity.FirstPartnerUserForAccount.get(u.Contactid)!=null)
                        FirstPartnerUsersAccountIds.add(u.AccountId__c);
                    if(u.User_Profile_Name__c==GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile')) //SFDC-2304
                    AdminUsersList.add(u);
                    if(u.IsActive && u.AccountId != null){ //SFDC-8975
                            usersAccountId.add(u.AccountId);
                            addRpShareUsers.add(u.id);
                        }
                }
                //Changes by Vamsee - Update the User Chatter Email Settings(ESESP-1069)
                if(u.UserType == 'Standard' && u.Department != null && u.Department.Contains('AkaTec')){
                    userChatterSettingsUpdate.add(u);
                }
            }
            if(userChatterSettingsUpdate.size() > 0){
                SC_UserTriggerClass.updateUserChatterSettings(userChatterSettingsUpdate, True);
            }
        }

        // Call only for Edits...
        if (!isInsert)
        {

            //SFDC-8975
            for(User newUser : newList){
                User oldUser = oldMap.get(newUser.id);
                if(oldUser.User_Profile_Name__c==GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile') && Util.hasChanges('User_Profile_Name__c', oldUser, newUser)){
                   deleteRpShareUsers.add(oldUser.id);
                   usersAccountId.add(oldUser.AccountId);

                }
                if(newUser.User_Profile_Name__c==GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile') && newUser.IsActive == false && oldUser.isActive ==true){
                    deleteRpShareUsers.add(oldUser.id);
                    usersAccountId.add(oldUser.AccountId);
                }
                if(newUser.User_Profile_Name__c==GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile') && Util.hasChanges('User_Profile_Name__c', oldUser, newUser)){
                    addRpShareUsers.add(oldUser.id);
                    usersAccountId.add(oldUser.AccountId);

                }
                if(newUser.User_Profile_Name__c==GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile') && newUser.IsActive == true && oldUser.isActive ==false){
                    addRpShareUsers.add(oldUser.id);
                    usersAccountId.add(oldUser.AccountId);
 
                }

            }
            //Changes by Sharath for CR:3593271
            UserTriggerClass.changeTimecardApprover(oldMap,newMap);
            //End of changes by Sharath

            //Features_Toggle__c customSettings = Features_Toggle__c.getInstance('UpdateContactOwnerForInActiveUsers'); //SFDC-2304
            //UserTriggerClassSettings__c userTriggerCustomSettings = UserTriggerClassSettings__c.getInstance('v1.0'); //SFDC-2304
            //if(customSettings.Toggle__c == true) //SFDC-2304
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UpdateContactOwnerForInActiveUsers') == true) //SFDC-2304
            {
                List<User> inActiveUserList = new List<User>();
                //String exemptedUserAlias = 'CINTEGRA, ONA, BTS-USER';
                //String exemptedUserAlias = userTriggerCustomSettings.exemptedUserAlias__c; //SFDC-2304
                String exemptedUserAlias = GsmUtilClass.getGSMSettingValue('UsrTrgrCls_ExemptedUserAlias'); //SFDC-2304
                for (User u : newList)
                {
                    //check if User is a Partner User
                    userTypeStr = null;
                    userTypeStr = u.UserType;
                    // Getting @future to @future exception; to avoid this updating Contacts only if isActive is switching between Active to InActive.
                    if (u.IsActive==false && (!exemptedUserAlias.contains(u.Alias)) && oldMap.get(u.Id).IsActive==true && !(u.UserType.contains('Partner')))
                        inActiveUserList.add(u);

                }
                if (inActiveUserList.size()>0)
                {
                    L2Q_UserTriggerClass usrTriggerClass = new L2Q_UserTriggerClass();
                    usrTriggerClass.resetContactOwnerForInActiveUsers(inActiveUserList);
                }
            }

            //SFDC-1332
            Map<String,String> userIdDelegatedApproverIdMap = new Map<String,String>();
            Map<String,String> userIdOldDelegatedApproveridMap = new Map<String,String>();

            for (User user : newList) {
                if(user.delegatedApproverId != oldMap.get(user.id).delegatedApproverId) {
                    userIdDelegatedApproverIdMap.put(user.id, user.DelegatedApproverId);
                    userIdOldDelegatedApproveridMap.put(user.id, oldMap.get(user.id).delegatedApproverId);
                }
            }
            /*for (User usr:oldList) {
                userIdOldDelegatedApproveridMap.put(usr.id, usr.delegatedApproverId);
            }*/
            if (userIdDelegatedApproverIdMap.size() > 0 && userIdOldDelegatedApproveridMap.size() > 0) {
                //UserTriggerClass.refreshDelegatedApproversInOpptys(user.id, user.delegatedApproverId, oldMap.get(user.id).delegatedApproverId);
                L2Q_UserTriggerClass.refreshDelegatedApproversInOpptys(userIdDelegatedApproverIdMap, userIdOldDelegatedApproveridMap);
            }
            //End of SFDC-1332

            // Merge Contract Header Share Code
            //Features_Toggle__c customSettings = Features_Toggle__c.getInstance('UpdateContactOwnerForInActiveUsers');
            //UserTriggerClassSettings__c userTriggerCustomSettings = UserTriggerClassSettings__c.getInstance('v1.0');
           // if(customSettings.Toggle__c == true)
            //{
                List<Id> activatedUserIdList = new List<Id>();
                //String exemptedUserAlias = 'CINTEGRA, ONA, BTS-USER';
                //String exemptedUserAlias = userTriggerCustomSettings.exemptedUserAlias__c; //SFDC-2304
                String exemptedUserAlias = GsmUtilClass.getGSMSettingValue('UsrTrgrCls_ExemptedUserAlias'); //SFDC-2304
                for (User u : newList)
                {
                    //check if User is a Partner User
                    userTypeStr = null;
                    userTypeStr = u.UserType;
                    if (u.IsActive && (!exemptedUserAlias.contains(u.Alias)) && oldMap.get(u.Id).IsActive==false && !(u.UserType.contains('Partner')))
                        activatedUserIdList.add(u.Id);
                }
                if (activatedUserIdList.size()>0 && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isContractShareEnabled')) // if toggle is off; dont do anything. //SFDC-2391
                {
                    L2Q_UserTriggerClass.updateMCHShare(activatedUserIdList);
                }
            //}



            for(User u : newList)
            {
                    //check if User is a Partner User
                    userTypeStr = null;
                    userTypeStr = u.UserType;
                    //SFDC-2741 Changing OR condition to AND
                    if((userTypeStr != null && u.UserType.contains('Partner')) && u.contactid!=null)
                    {
                        //check if the User is getting active , if yes update the current licences count
                        if((oldMap.get(u.id).IsActive!=u.IsActive) || (oldMap.get(u.Id).ProfileId!=u.ProfileId))
                        {
                            //AGH
                            partnerUsers.add(new UpdatedUser(oldMap.get(u.id), u));

                        }
                        if((oldMap.get(u.id).Email != u.Email))
                            UsrEmailUpdate.add(u);
                    }
                    //SFDC-6258
                    if(u.ManagerId != null && u.ManagerId != oldMap.get(u.id).ManagerId){
                        managerChangedUsers.add(u.Id);
                    }
                    if((u.Quip_Access__c != oldMap.get(u.id).Quip_Access__c) || (u.IsActive != oldMap.get(u.id).IsActive && !u.IsActive && u.Quip_Access__c && u.Quip_User_Id__c != null)){
                    	quipUserProvisionDeprovisionList.add(u);
                	}
            }
            RAMDProcessor instanceRamdProcessor = new RAMDProcessor();
            instanceRamdProcessor.userCountryChange(newList,oldMap,isInsert);
        }
        
        //SFDC-8975
        if(usersAccountId.size()>0 && (addRpShareUsers.size()>0 || deleteRpShareUsers.size() >0) )
            L2Q_UserTriggerClass.getRebatePayouts(usersAccountId,addRpShareUsers,deleteRpShareUsers);
        
        //SFDC-6258
        if(managerChangedUsers.size() > 0){
            DealSupportRequestTriggerClass.updateSEManagerOnDSR(managerChangedUsers);
        }
        
        if(!quipUserProvisionDeprovisionList.isEmpty()){
            System.enqueueJob(new QuipUserProvisioningDeprovisioning(quipUserProvisionDeprovisionList,null));
        }

        if(partnerUsers.size()>0 && !system.isFuture())
        {
            System.Debug(LoggingLevel.Error, 'AGH_D partnerUsers'+partnerUsers);
            L2Q_UserTriggerClass.updateAccountLicenses(JSON.serialize(partnerUsers));
        }

        //update the email of contact
        if(UsrEmailUpdate.size()>0 && !system.isFuture())
            PRM_opportunity.UpdateContactEmail(UsrEmailUpdate);
        if(FirstUsersList.size()>0)
            PRM_opportunity.UpdateRoleOfPartner(FirstUsersList);

        if(FirstPartnerUsersAccountIds.size()>0 && !system.isFuture())
        {

            //convert a set to a list
            list<id> SetIdsToList = new list<id>();
            for(id accid:FirstPartnerUsersAccountIds)
            SetIdsToList.add(accid);
            PRM_opportunity.UpdateFundBudgetShares(SetIdsToList);
        }

        //if(AdminUsersList.size()>0)
        //  PRM_opportunity.SendEmailToAdmin(AdminUsersList);
        //Features_Toggle__c userActivationSendMailCustomSettings = Features_Toggle__c.getInstance('UserActivationSendEmail'); //SFDC-2304
        if(! isInsert)
        {
            userTypeStr=null;
            //if(userActivationSendMailCustomSettings.Toggle__c==true) //SFDC-2304
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UserActivationSendEmail') == true) //SFDC-2304
            {
                List<User> newActiveUserList=new List<User>();
                for(User user: newList)
                {
                    userTypeStr=user.UserType;
                    if(!(userTypeStr != null && userTypeStr.contains('Partner')))
                    {
                        if(user.IsActive && user.IsActive!=oldMap.get(user.Id).IsActive)
                        {
                            newActiveUserList.add(user);
                        }
                    }
                }
                L2Q_UserTriggerClass.sendEmailToUsers(newActiveUserList);
            }
        }

        //CR 1268122: Enable Read/Write access to the Partner Admins.
        //if(UserTriggerClass.updateAccountShareSettingFirstRunFlag)
        //{
        Set<Id> setOfUsersToBeAddedToChannelUsersGroup = new Set<Id>();
        Set<Id> setOfUsersToBeRemovedFromChannelUsersGroup= new Set<Id>();

        //CR 3111491    NAP Portal -- Parent/Child Contact Management
        List<String> PartnerAdminIdChildStrList = new List<String>();
        List<Id> usersAccountsIds = new List<Id>();
        Map<Id,List<Id>> parentAccountChildAccountsMap = new Map<Id,List<id>>();
        for (User ur:newList) {
            if (ur.AccountId__c != null) {
                usersAccountsIds.add(ur.AccountId__c);
            }
        }
        if (usersAccountsIds != null && usersAccountsIds.size() > 0) {
            List<Account> childAccounts = [Select id,ParentId from Account where ParentId IN:usersAccountsIds];
            List<id> childAccountsList;
            if (childAccounts != null && childAccounts.size() > 0) {
                for (Account ac:childAccounts) {
                    if(parentAccountChildAccountsMap.get(ac.ParentId) == null) {
                        childAccountsList = new List<Id>();
                        childAccountsList.add(ac.id);
                        parentAccountChildAccountsMap.put(ac.ParentId, childAccountsList);
                    }else {
                        childAccountsList = parentAccountChildAccountsMap.get(ac.ParentId);
                        childAccountsList.add(ac.id);
                        parentAccountChildAccountsMap.put(ac.ParentId, childAccountsList);
                    }
                }
            }
        }
        System.debug('parentAccountChildAccountsMap is : '+parentAccountChildAccountsMap);
        List<Id> childAccountsForParent = new List<Id>();
        for (User u: newList)
        {
            /*Begin Rajesh Kumar AKA JIRA# SFDC-5964 */ // commented existing if condition and modified to accomdate for partner plan access
           // if (isInsert || (! isInsert && u.profileId != oldMap.get(u.Id).profileId))
            if (isInsert || (! isInsert && u.profileId != oldMap.get(u.Id).profileId) ||(!isInsert  && u.Has_PartnerPlans_Access__c && u.Has_PartnerPlans_Access__c != oldMap.get(u.Id).Has_PartnerPlans_Access__c))
            /*End Rajesh Kumar AKA JIRA# SFDC-5964 */
            {
                userTypeStr = null;
                userTypeStr = u.UserType;
                if (u.IsActive)
                {
                    //check if User is a Partner User
                    if((userTypeStr != null && u.UserType.contains('Partner')) || u.contactid!=null)
                    {
                        /*Begin Rajesh Kumar AKA JIRA# SFDC-5964 */ //commented existing if condition and modified to accomdate for partner plan access
                        //if ((u.ProfileId == GsmUtilClass.getPRMSettingValue('Partner_Admin_Id')))  //SFDC-2304
                        if ((u.ProfileId == partneradminprofileId) || ( !isInsert  && u.Has_PartnerPlans_Access__c && u.Has_PartnerPlans_Access__c != oldMap.get(u.Id).Has_PartnerPlans_Access__c))
                        /*End Rajesh Kumar AKA JIRA# SFDC-5964 */
                        {
                            userIdAccId = u.Id + '#' + u.AccountId__c;
                            PartnerAdminIdStrList.add(userIdAccId);

                            if (parentAccountChildAccountsMap != null) {
                                childAccountsForParent = parentAccountChildAccountsMap.get(u.AccountId__c);
                                if (childAccountsForParent != null && childAccountsForParent.size() > 0) {
                                    for(Id childId:childAccountsForParent) {
                                        userIdAccId = u.Id + '#' + childId;
                                        System.debug('Adding user');
                                        PartnerAdminIdStrList.add(userIdAccId);
                                    }
                                }
                            }
                        }
                    }
                    //Anand Hegde - Add 'partner' profile internal users to channel users public group

                    if(GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersProfiles').containsIgnoreCase(u.ProfileId)) //SFDC-2304
                    {
                        setOfUsersToBeAddedToChannelUsersGroup.add(u.Id);
                    }
                    if(!isInsert && GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersProfiles').containsIgnoreCase(oldMap.get(u.Id).profileId) && !GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersProfiles').containsIgnoreCase(u.ProfileId)) //SFDC-2304
                    {
                        setOfUsersToBeRemovedFromChannelUsersGroup.add(u.Id);
                    }


                }
            }

        }
        if (PartnerAdminIdStrList != null && PartnerAdminIdStrList.size()>0)
        {
            L2Q_UserTriggerClass.updateAccountShareSettingFuture(PartnerAdminIdStrList);
        }

        if(setOfUsersToBeAddedToChannelUsersGroup.size()>0)
        {
            L2Q_UserTriggerClass.addUsersToChannelUsersGroup(setOfUsersToBeAddedToChannelUsersGroup);
        }
        if(setOfUsersToBeRemovedFromChannelUsersGroup.size()>0)
        {
            L2Q_UserTriggerClass.removeUsersFromChannelUsersGroup(setOfUsersToBeRemovedFromChannelUsersGroup);
        }
      // UserTriggerClass.updateAccountShareSettingFirstRunFlag = false;
        //}
            // Anand Hegde  - User automation SFDC-1030
        System.Debug(LoggingLevel.Error, 'AGH_ after update part');
        if(Trigger.isUpdate)
        {
            System.Debug(LoggingLevel.Error, 'usersForAutomationActions size'+usersForAutomationActions.size());
            if(usersForAutomationActions.size()>0)
            {
                System.Debug(LoggingLevel.Error, 'AGH_ found some user for after');
                L2Q_UserTriggerClass.handleUserAutomationActions(usersForAutomationActions);
            }
        }
    }

}