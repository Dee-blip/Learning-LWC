global without sharing class SF1_FundRequestService 
{
    public static Boolean accessAllowedToCurrentUserProfile()
    {   
        Set<String> validProfiles = new Set<String>();
        String profileName ='';
        Boolean accessAllowed = false;
        Profile profile = [SELECT Name from Profile where Id =:UserInfo.getProfileId()];
        validProfiles.addAll(Label.SF1_PrivateNoteVisibleToProfiles.split(','));
        profileName= profile.Name;
        if(validProfiles.contains(profileName))
        {   
            accessAllowed = true;
            return accessAllowed;
        }
        return accessAllowed;
    }
    
    //MOB - 154 : edit fund request
    public static Boolean hasEditingRights(Id fundRequestId)
    {   
        String currentUserProfileId = Userinfo.getProfileId();
        String profileName = [Select Name from Profile where Id=:currentUserProfileId][0].Name;
        for(String ithProfile : Label.FundRequestAllowedProfilesForEdit.split(','))
        {
            if(ithProfile.trim()==profileName)
                return true;
        }
        // If Fund request > 5k USD, then after first approval, the approval request goes to Fund Request Queue
        // They wont be able to edit
        
        
        //Check if user is the next approver
        List<ProcessInstanceWorkItem> processInstanceWorkItemList = [select id, actorid, originalactorid from ProcessInstanceWorkItem where ProcessInstance.TargetObjectId=:fundRequestId order by createddate desc];
        System.Debug('###processInstanceList p' + processInstanceWorkItemList);
        if(processInstanceWorkItemList!=null && processInstanceWorkItemList.size()>0)
        {
            
            String currentUserId = Userinfo.getUserId();
            for(ProcessInstanceWorkItem ithWorkItem : processInstanceWorkItemList)
            {
                if(ithWorkItem.actorid==currentUserId || ithWorkItem.originalactorid==currentUserId)
                {
                    return true;
                }
            }
        }
        return false;
    }
    
    public static SFDC_MDF__c getPageObject(Id recordID)
    {   
        SFDC_MDF__c pageObject = new SFDC_MDF__c();
        List<SFDC_MDF__c> listOfRecords= [select id,Name, Status__c,Private_Note__c from SFDC_MDF__c where id=:recordID];
        if(listOfRecords.size()>0)
        {   
            pageObject = listOfRecords[0];
        }
        return pageObject;
    }
    
    public static SFDC_MDF__c getPageObjectForEditFundRequest(Id recordID)
    {   
        SFDC_MDF__c pageObject = new SFDC_MDF__c();
        List<String> listOfStatusesWhichAllowEdit = Label.FundRequestAllowEditStatuses.split(', ');
        List<SFDC_MDF__c> listOfRecords= [select id,Name, Activity_Leader__c,Amount__c, Total_Activity_Event_Cost__c, 
                                          Fund_Request_Contact__c,Fund_Request_Campaign__c, Program_Type__c, 
                                          Activity_Date__c, Program_End_Date__c, Other_Program_Type__c, Plan_Activity__c, 
                                          Program_Location__c, Program_Description__c , Private_Note__c, 
                                          SOE_or_PubSec_Event__c,Spender_Confirmed__c  from SFDC_MDF__c 
                                          where id=:recordID and Status__c in :listOfStatusesWhichAllowEdit];
        if(listOfRecords.size()>0)
        {   pageObject = listOfRecords[0];
        }
        //else Error: Not a valid Fund Request ID.'
        return pageObject;
    }
    
    public static void saveNote(SFDC_MDF__c pageObject)
    {   
        update pageObject;
    }
}