/*
* Developer  : Bhavesh Kumar
* Purpose    : Handler class of trigger QualityCoachingTrigger
* Date       : 4 Jan 2021
* Test Class : 
* Handler Name:SC_QualityCoachingTriggerHandler
* Date                 Developer           JIRA                            Changes
* 4-Jan-2021          Bhavesh         ESESP-3590                 RCA:restrict users to delete quality coaching record.
*   

*/ 

public with sharing class SC_QualityCoachingTriggerHandler {
    public SC_QualityCoachingTriggerHandler() {
        
    }

    //only admin user can delete the quality coaching.
    public static void restrictRcaQualityDelete( List<SC_KCS_Scorecard__c> newList ){
        String userProfileName = [select Name from profile where id =: userinfo.getProfileId()].Name;
        Boolean allowDelete = (userProfileName == 'System Administrator')?true:false;
        if(!allowDelete){
            for( SC_KCS_Scorecard__c score : newList ){
                score.addError('You cannot delete Quality Coaching.');
            }
        }
    }
    public static void qualityCoachingOccuredValidation( List<SC_KCS_Scorecard__c> newList ){
        Boolean isIraptAdmin = false;
        List<PermissionSetAssignment> psa = new List<PermissionSetAssignment>([SELECT  Id FROM PermissionSetAssignment WHERE 
                                                AssigneeId =: UserInfo.getuserId() and PermissionSet.Name = 'SC_SI_Service_Incidents_IRAPT_Admin_User']);
        if( psa.size()>0 ){
            isIraptAdmin = true;
        }  
        if(!isIraptAdmin){
            for( SC_KCS_Scorecard__c score : newList ){
                score.addError('Only IRAPT Admin users can submit Quality Coaching occurred.');
            }
        }                                  
    }

}