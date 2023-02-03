/*
Author          :  Vikas
Description     :  Support Class for SC_SOCC_UserAccountMapping_Trigger
Test Class      :  

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
19 Mar 2020          Vikas     									SOCC CAR 2 - RunBooks 
22 Feb 2021          Vikas     					ESESP-4030		SOCC CAR 2 - RunBooks 2
------------------------------------------------------------------------------------------------------------------
*/
public without sharing class SC_SOCC_UserAccountMappingHelper {
    public static boolean recursiveCheck = false;
    public static void validateUAM(List<Id> internalUserList, List<SOCC_User_Account_Mapping__c> newUAMList){
        Map<Id,String> existingUserAccountMap = new Map<Id,String>();
        Map<Id,String> existingUserNameMap = new Map<Id,String>();
        Map<Id,List<Id>> existingUserAllAccountsMap = new Map<Id,List<Id>> ();
        //Map<Id,String> existingUserAllNameMap = new Map<Id,String>();
        for(SOCC_User_Account_Mapping__c existingMap : [Select id,Name,Internal_User__c,PD_Account__r.Name,Active__c from SOCC_User_Account_Mapping__c where Internal_User__c in:internalUserList])
        {
            if(existingMap.Active__c){
                existingUserAccountMap.put(existingMap.Internal_User__c,existingMap.PD_Account__r.Name);
            	existingUserNameMap.put(existingMap.Internal_User__c,existingMap.Name);
            }
            if(!existingUserAllAccountsMap.containsKey(existingMap.Internal_User__c)){
                existingUserAllAccountsMap.put(existingMap.Internal_User__c,new List<Id>());
            }
            existingUserAllAccountsMap.get(existingMap.Internal_User__c).add(existingMap.PD_Account__c);
            //existingUserAllNameMap.put(existingMap.Internal_User__c,existingMap.Name);
        }
        for(SOCC_User_Account_Mapping__c thisUAM : newUAMList){
            if(thisUAM.Active__c){
                if(!existingUserAccountMap.isEmpty() && !existingUserNameMap.isEmpty()){
                    if(existingUserAccountMap.get(thisUAM.Internal_User__c) != null && existingUserNameMap.get(thisUAM.Internal_User__c) != null)
                        thisUAM.addError('There already exists an active mapping for this internal user with '+existingUserAccountMap.get(thisUAM.Internal_User__c)+' Account. Deactivate or use '+existingUserNameMap.get(thisUAM.Internal_User__c)+' record.');
                }
            }
            else{
                if(!existingUserAllAccountsMap.isEmpty() && existingUserAllAccountsMap.get(thisUAM.Internal_User__c).contains(thisUAM.PD_Account__c)){
                    thisUAM.addError('A mapping already exists for the User with this Account.');
                }
            }
        }
    }
    public static void validateUAMUpdate(List<SOCC_User_Account_Mapping__c> newUAMList, Map<Id,SOCC_User_Account_Mapping__c> newUAMMap, Map<Id,SOCC_User_Account_Mapping__c> oldUAMMap, Boolean isShiftManager){
        Map<Id,Id> UAMUserIdMap = new Map<Id,Id>();
        List<SOCC_User_Account_Mapping__c> updateUAMList = new List<SOCC_User_Account_Mapping__c>();
        Set<Id> duplicateInternalUserSet = new Set<Id>();
        
        if(!recursiveCheck){
            for(SOCC_User_Account_Mapping__c thisUAM : newUAMList)
            {
                if(thisUAM.Internal_User__c == Userinfo.getUserId() || isShiftManager)
                {
                    if(oldUAMMap.get(thisUAM.id).Active__c != newUAMMap.get(thisUAM.id).Active__c){
                        UAMUserIdMap.put(thisUAM.id,thisUAM.Internal_User__c);
                    }
                }
                else
                {
                    thisUAM.addError('You are not allowed to update this record.');
                }
            }
            
            duplicateInternalUserSet.addAll(UAMUserIdMap.values());
            
            for(id UAMId : UAMUserIdMap.keySet()){
                if(UAMUserIdMap.values().size() != duplicateInternalUserSet.size() && newUAMMap.get(UAMId).Active__c == true){
                    newUAMMap.get(UAMId).addError('Activating multiple mappings for the same user is restricted');

                }
            }
            
            for(SOCC_User_Account_Mapping__c existingMap : [Select id,Name,Active__c,Internal_User__c,PD_Account__r.Name from SOCC_User_Account_Mapping__c where id in:UAMUserIdMap.keySet() or (Internal_User__c in:UAMUserIdMap.values() and Active__c =:true)])
            {
                if(UAMUserIdMap.get(existingMap.id) == null){
                    existingMap.Active__c = false;
                    updateUAMList.add(existingMap);
                }
            } 
            if(updateUAMList.size() > 0){
                recursiveCheck = true;
                update updateUAMList;
            }
        }
    }
    
    public static void filterInternalUser(List<Id> internalUserList, List<Id> PDAccountList, List<SOCC_User_Account_Mapping__c> newUAMList, Map<String,List<String>> metadataValueMap, User currentUser){
        Map<Id,String> userIdTitleMap = new Map<Id,String>();
        Map<Id,String> userIdProfileMap = new Map<Id,String>();
        Map<Id,Map<Id,String>> accountUserRoleMap = new Map<Id,Map<Id,String>>();
        system.debug(LoggingLevel.DEBUG,'internalUserList : '+internalUserList);
        system.debug(LoggingLevel.DEBUG,'PDAccountList : '+PDAccountList);
        for(User internalUser : [Select id,Title,Profile.name from user where id in:(internalUserList)]){
            userIdTitleMap.put(internalUser.id,internalUser.Title);
            userIdProfileMap.put(internalUser.id,internalUser.Profile.name);
        }
        for(AccountTeamMember thisTM :[SELECT Id, AccountId, UserId, User.Profile.Name, TeamMemberRole, Title FROM AccountTeamMember where AccountId in:(PDAccountList) /*and UserId in:(internalUserList)*/]){
            if(internalUserList.contains(thisTM.UserId) || (currentUser != null && currentUser.Id == thisTM.UserId)){
                if(!accountUserRoleMap.containsKey(thisTM.AccountId)){
                    accountUserRoleMap.put(thisTM.AccountId,new Map<Id,String>{thisTM.UserId => thisTM.TeamMemberRole});
                }
                else{
                    Map<Id,String> userRoleMap = new Map<Id,String>();
                    userRoleMap.put(thisTM.UserId,thisTM.TeamMemberRole);
                    accountUserRoleMap.get(thisTM.AccountId).putAll(userRoleMap);
                }
            }
        }
        system.debug(LoggingLevel.DEBUG,'userIdTitleMap : '+userIdTitleMap);
        system.debug(LoggingLevel.DEBUG,'userIdProfileMap : '+userIdProfileMap);
        system.debug(LoggingLevel.DEBUG,'accountUserRoleMap : '+accountUserRoleMap);
        for(SOCC_User_Account_Mapping__c thisUAM : newUAMList){
            system.debug(LoggingLevel.DEBUG,'PROFILE : '+userIdProfileMap.get(thisUAM.Internal_User__c));
            system.debug(LoggingLevel.DEBUG,'TITLE : '+userIdTitleMap.get(thisUAM.Internal_User__c));
            system.debug(LoggingLevel.DEBUG,'currentUser : '+currentUser);
            //check for insert by non shift manager
            if(currentUser != null){
                if((metadataValueMap.get('AMGProfileID').size() > 0 && metadataValueMap.get('AMGUserTitle').size() > 0
                    && metadataValueMap.get('AMGProfileID').contains(currentUser.Profile.Name) 
                    && !metadataValueMap.get('AMGUserTitle').contains(currentUser.Title))
                   ||
                   (metadataValueMap.get('PSProfileID').size() > 0 && metadataValueMap.get('PSAccountTeamRole').size() > 0
                    && metadataValueMap.get('PSProfileID').contains(currentUser.Profile.Name)
                    && accountUserRoleMap.size() > 0 && accountUserRoleMap.get(thisUAM.PD_Account__c) != null && accountUserRoleMap.get(thisUAM.PD_Account__c).size() > 0
                    && !metadataValueMap.get('PSAccountTeamRole').contains(accountUserRoleMap.get(thisUAM.PD_Account__c).get(currentUser.Id)))
                  )
                {
                    thisUAM.addError('You are not allowed to create this record, please contact shift manager');
                }
            }
            else{
                if(userIdProfileMap.get(thisUAM.Internal_User__c) != null && metadataValueMap.get('AMGProfileID').contains(userIdProfileMap.get(thisUAM.Internal_User__c)) &&
                   userIdTitleMap.get(thisUAM.Internal_User__c) != null && !metadataValueMap.get('AMGUserTitle').contains(userIdTitleMap.get(thisUAM.Internal_User__c)))
                {
                    thisUAM.addError('The user does not match the criteria');
                }
                
                system.debug(LoggingLevel.DEBUG,'ACCOUNT NAME: '+thisUAM.PD_Account__c);
                system.debug(LoggingLevel.DEBUG,'IS TEAM MEMBER: '+accountUserRoleMap.get(thisUAM.PD_Account__c));
                if(userIdProfileMap.get(thisUAM.Internal_User__c) != null && metadataValueMap.get('PSProfileID').contains(userIdProfileMap.get(thisUAM.Internal_User__c))){
                    if(accountUserRoleMap.size() > 0 && accountUserRoleMap.get(thisUAM.PD_Account__c) != null && accountUserRoleMap.get(thisUAM.PD_Account__c).size() > 0)
                    {
                        system.debug(LoggingLevel.DEBUG,'METADATA : '+metadataValueMap.get('PSAccountTeamRole'));
                        system.debug(LoggingLevel.DEBUG,'TEAM MEMBER ROLE: '+accountUserRoleMap.get(thisUAM.PD_Account__c).get(thisUAM.Internal_User__c));
                        system.debug(LoggingLevel.DEBUG,'CONDITION : '+metadataValueMap.get('PSAccountTeamRole').contains(accountUserRoleMap.get(thisUAM.PD_Account__c).get(thisUAM.Internal_User__c)));
                        if(!metadataValueMap.get('PSAccountTeamRole').contains(accountUserRoleMap.get(thisUAM.PD_Account__c).get(thisUAM.Internal_User__c))){
                            thisUAM.addError('Role of the selected user does not match the criteria');
                        }
                    }
                    else{
                        thisUAM.addError('User selected is not an Account Team Member');
                    }
                }
            }
        }
    } 
}