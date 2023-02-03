public class PartnerCommunityFCMController {
    
    static Channel_Mapping__c rcmChannelMapping = null;
    
    @AuraEnabled
    public static Map<String,String> getFCMValues(String recordId) {
        
        //Map<id,id> fcm_Manager_map = new Map<id,id>();
        Map<String,String> response = new Map<String,String>();
        try {
            String sObjectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            System.debug('sObjectName :'+sObjectName);
            
            List<Channel_Mapping__c> cmList = [SELECT Id, Partner_Name__c, PAE_ID__c, VAR_Manager_Team_Role__c,
                                               Partner_Name__r.Name,PAE_ID__r.Name,PAE_ID__r.ManagerId,
                                               MDF_Approver__c,Global_Account_Manager6__c,
                                               Global_Account_Manager6__r.isActive 
                                               FROM Channel_Mapping__c 
                                               WHERE VAR_Manager_Status__c = 'Active' 
                                               AND Active__c=true 
                                               AND Temp_PAE__c=null 
                                               AND PAE_ID__c !=null 
                                               AND (Global_Account_Manager6__c = null 
                                                    OR (Global_Account_Manager6__c != null 
                                                        AND Global_Account_Manager6__r.isActive = true))
                                              ];
            String accountId;
            if (sObjectName == 'Opportunity') {
                accountId = [select Partner_Involved__c 
                             from Opportunity 
                             where id=:recordId].Partner_Involved__c;
            } else if (sObjectName == 'Fund Claim') { accountId = [select Account__c from SFDC_MDF__c where id=:recordId].Account__c;
            }
            
            List<Channel_Mapping__c> fcmIds = new List<Channel_Mapping__c>();
            for (Channel_Mapping__c cm : cmList) {
                if (cm.Partner_Name__c == accountId) {       
                    fcmIds.add(cm);
                }
            }
            
            for (Channel_Mapping__c fcm : fcmIds)
            {       
                if (fcm.PAE_ID__r.Name!=null)
                    response.put(fcm.PAE_ID__c,fcm.PAE_ID__r.Name);
            } 
            response.put('NONE','I don\'t know'); 
            return response;
        }catch(Exception e) { Error_log__c errorLog = new Error_log__c(Name = 'Get FCM values',Class__c = 'PartnerCommunityFCMController',Error_Message__c = e.getMessage() + ' #; ' + e.getStackTraceString());insert errorLog; PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('Get FCM values','Error getting FCM values.',500,e.getMessage(),true); throw new AuraHandledException(JSON.serialize(data));}
    }
    
    @AuraEnabled
    public static void updateRecord(String recordId, String selectedFCM) {
        if (selectedFCM == null || selectedFCM == '') { PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('Update Record','Invalid Value for FCM.',500, '',true); throw new AuraHandledException(JSON.serialize(data));}
        try {
            Opportunity oppty = [select id,
                                     FCM__c,
                                     isRebateTCToShow__c,
                                     Partner_Owner__r.AccountId 
                                 from Opportunity 
                                 where id=:recordId];
            if(oppty!=null)
            {
                if(selectedFCM!='NONE') { oppty.FCM__c = selectedFCM;}
                else
                {
                    // i dont know is selected, assign PAE of master channel mapping
                    String accountId = [select Partner_Involved__c 
                                        from Opportunity 
                                        where id=:recordId].Partner_Involved__c;
                    Channel_Mapping__c masterChannelMapping = getMasterChannelMapping(accountId);
                    
                    if(masterChannelMapping!=null) {oppty.FCM__c = masterChannelMapping.PAE_ID__c;}
                    
                    else if(RcmChannelMapping!=null) { oppty.FCM__c = RcmChannelMapping.Comp_Owner1__c;}
                   
                }
                oppty.Validation_Override__c=true;
                update oppty;
            }
        }catch(Exception e) {Error_log__c errorLog = new Error_log__c(Name = 'Update oppty',Class__c = 'PartnerCommunityFCMController',Error_Message__c = e.getMessage() + ' #; ' + e.getStackTraceString()); insert errorLog; PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('Update oppty','Error updating FCM value.',500,e.getMessage(),true); throw new AuraHandledException(JSON.serialize(data));}
    }
    
    public static Channel_Mapping__c getMasterChannelMapping(String accountId)
    {
        Channel_Mapping__c masterChannelMapping=null;
        for(Channel_Mapping__c cm :[SELECT Id, 
                                        Name, 
                                        Partner_Name__c, 
                                        PAE_ID__c, 
                                        VAR_Manager_Team_Role__c, 
                                        Partner_Name__r.Name, 
                                        PAE_ID__r.Name, 
                                        Comp_Owner1__r.IsActive,
                                        PAE_ID__r.ManagerId, 
                                        MDF_Approver__c, 
                                        Comp_Owner1__c, 
                                        Temp_PAE__c, 
                                        Master_Channel_Mapping__c, 
                                        PAE_ID__r.IsActive
                                    FROM Channel_Mapping__c 
                                    WHERE (
                                        Active__c = true
                                        AND Partner_Name__c =:accountId
                                        AND (PAE_ID__c !=null OR Comp_Owner1__c != null)
                                        AND (PAE_ID__r.IsActive = true OR Comp_Owner1__r.IsActive = true)
                                    ) ORDER BY LastModifiedDate DESC])
        {
            if(cm.Master_Channel_Mapping__c && cm.PAE_ID__c != null && cm.PAE_ID__r.IsActive && cm.Temp_PAE__c == null){
                MasterChannelMapping=cm; break;
            }
            else if(RcmChannelMapping == null){
                if(!cm.Master_Channel_Mapping__c && cm.Comp_Owner1__c != null && cm.Comp_Owner1__r.IsActive){
                    rcmChannelMapping=cm;
                }
            }
        }
        return masterChannelMapping;
    }
    
}