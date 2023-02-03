/*
Author          :  Vikas
Description     :  Apex Trigger for SOCC User and Account Mapping object
Test Class      :  SC_SOCC_RunBooks_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
19 Mar 2020          Vikas     					SOCC CAR 2 - RunBooks 
22 Apr 2020			 Vikas						ESESP-3401
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_SOCC_UserAccountMapping_Trigger on SOCC_User_Account_Mapping__c (before insert, before update) 
{
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        List<Id> activeInternalUserList = new List<Id>();
        List<Id> allInternalUserList = new List<Id>();
        List<Id> PDAccountList = new List<Id>();
        Boolean isShiftManager = false;
        Boolean activeChecked = false;
        
        //SC_SOC_Passphrase_Access__mdt metadataRec = [SELECT Id, DeveloperName, User_Title__c, Profile_ID_Text__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName IN('Shift_Managers_for_User_Mapping','UAM_AMG',' UAM_PS' )];
        Set<String> sUserTitle = new Set<String>();
        Set<String> sProfile = new Set<String>();
        Map<String,List<String>> metadataValueMap = new Map<String,List<String>>();
        
        for(SC_SOC_Passphrase_Access__mdt metadataRec : [SELECT Id, DeveloperName, User_Title__c, Profile_ID_Text__c, Account_Team_Role__c FROM SC_SOC_Passphrase_Access__mdt WHERE DeveloperName IN('Shift_Managers_for_User_Mapping','UAM_AMG','UAM_PS')]){
            if(metadataRec.DeveloperName == 'Shift_Managers_for_User_Mapping'){
                if(!String.isBlank(metadataRec.User_Title__c))
                	metadataValueMap.put('ShiftManagerUserTitle',metadataRec.User_Title__c.split(','));
                if(!String.isBlank(metadataRec.Profile_ID_Text__c))
                	metadataValueMap.put('ShiftManagerProfileID',metadataRec.Profile_ID_Text__c.split(','));
            }
            if(metadataRec.DeveloperName == 'UAM_AMG'){
                if(!String.isBlank(metadataRec.User_Title__c))
                	metadataValueMap.put('AMGUserTitle',metadataRec.User_Title__c.split(','));
                if(!String.isBlank(metadataRec.Profile_ID_Text__c))
                	metadataValueMap.put('AMGProfileID',metadataRec.Profile_ID_Text__c.split(','));
            }
            if(metadataRec.DeveloperName == 'UAM_PS'){
                if(!String.isBlank(metadataRec.Account_Team_Role__c))
                	metadataValueMap.put('PSAccountTeamRole',metadataRec.Account_Team_Role__c.split(','));
                if(!String.isBlank(metadataRec.Profile_ID_Text__c))
                	metadataValueMap.put('PSProfileID',metadataRec.Profile_ID_Text__c.split(','));
            }
        }
        
        user currentUser = [SELECT Id, Title, Profile.Name FROM User where Id =:UserInfo.getUserId() limit 1];

        if(metadataValueMap.get('ShiftManagerUserTitle').size() > 0 
           && ((metadataValueMap.get('ShiftManagerUserTitle')).contains(currentUser.Title) || (metadataValueMap.get('ShiftManagerProfileID')).contains(currentUser.Profile.Name))){
            isShiftManager = true;
        }
        
        if(isShiftManager){
            for(SOCC_User_Account_Mapping__c thisUAM : Trigger.new)
            {
                if(Trigger.isInsert){
                    allInternalUserList.add(thisUAM.Internal_User__c);
                    if(thisUAM.Active__c == true){
                        activeInternalUserList.add(thisUAM.Internal_User__c);
                        PDAccountList.add(thisUAM.PD_Account__c);
                    }
                }
                if(Trigger.isUpdate){
                    if(Trigger.oldMap.get(thisUAM.id).Internal_User__c != Trigger.newMap.get(thisUAM.id).Internal_User__c 
                       || Trigger.oldMap.get(thisUAM.id).PD_Account__c != Trigger.newMap.get(thisUAM.id).PD_Account__c)
                    {
                        allInternalUserList.add(thisUAM.Internal_User__c);
                        if(Trigger.newMap.get(thisUAM.id).Active__c == true){
                        	activeInternalUserList.add(thisUAM.Internal_User__c);
                        	PDAccountList.add(thisUAM.PD_Account__c);
                        }
                    }
                    if(Trigger.oldMap.get(thisUAM.id).Active__c != Trigger.newMap.get(thisUAM.id).Active__c){
                        activeChecked = true;
                        if(Trigger.newMap.get(thisUAM.id).Active__c == true){
                            activeInternalUserList.add(thisUAM.Internal_User__c);
                            PDAccountList.add(thisUAM.PD_Account__c);
                        }
                    }
                }
            }
            
            if(allInternalUserList.size() > 0){
                SC_SOCC_UserAccountMappingHelper.validateUAM(allInternalUserList,Trigger.new);
            }
            if(activeInternalUserList.size() > 0 && PDAccountList.size() > 0){
                SC_SOCC_UserAccountMappingHelper.filterInternalUser(activeInternalUserList,PDAccountList,Trigger.new,metadataValueMap,null);
            }
            if(activeChecked)
                SC_SOCC_UserAccountMappingHelper.validateUAMUpdate(Trigger.new,Trigger.newMap,Trigger.oldMap,isShiftManager);
        }
        else{
            if(Trigger.isInsert){
                Map<Id,Map<Id,String>> accountUserRoleMap = new Map<Id,Map<Id,String>>();
                for(SOCC_User_Account_Mapping__c thisUAM : Trigger.new)
                {
                    if(thisUAM.Active__c == true){
                        activeInternalUserList.add(thisUAM.Internal_User__c);
                        PDAccountList.add(thisUAM.PD_Account__c);
                    }
                }
                
                if(activeInternalUserList.size() > 0 && PDAccountList.size() > 0){
                    SC_SOCC_UserAccountMappingHelper.filterInternalUser(activeInternalUserList,PDAccountList,Trigger.new,metadataValueMap,currentUser);
                }
                //Trigger.new[0].addError('Only Shift Managers are allowed to create this record. Please contact them.');
            }
            else if(Trigger.isUpdate){
                SC_SOCC_UserAccountMappingHelper.validateUAMUpdate(Trigger.new,Trigger.newMap,Trigger.oldMap,isShiftManager);
            }
        }
    }
}