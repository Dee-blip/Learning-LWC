/*
Author          : Sheena
Description     : Trigger on SC_SI_Mailer_Filter_Trigger
Test Class		: SC_SI_INT_Tool_Test

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
14 Aug 2020       	Sheena               ESESP-5392           Restricting users to delete filters manually
------------------------------------------------------------------------------------------------------------------
*/

trigger SC_SI_Mailer_Filter_Trigger on CMC_Mailer_Filter__c (before delete) {
    
    // Restriction of manual Mailer Filter record deletion
    if(Trigger.isBefore && Trigger.isDelete ){
        if(!SC_SI_INT_Tool_Controller.byPassFilterDeletion){
            // Profile Names having Modify All permission
            List<PermissionSet> permProfileIds = [SELECT ProfileId FROM PermissionSet WHERE IsOwnedByProfile = true AND Id IN (SELECT ParentId FROM ObjectPermissions WHERE PermissionsDelete = true AND SObjectType = 'CMC_Mailer_Filter__c')];
            
            List<String> profileIds = new List<String>();
            for(PermissionSet profileId: permProfileIds){
                profileIds.add(profileId.ProfileId);
            }
            
            if(!profileIds.contains(UserInfo.getProfileId())){
                for(CMC_Mailer_Filter__c filter: Trigger.Old){
                    filter.addError('You are not authorized to delete this record');
                }
            }
        }
    }
    
}