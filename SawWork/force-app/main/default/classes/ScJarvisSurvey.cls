/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 02-25-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   12-09-2021   Vishnu Vardhan   Initial Version
**/
public without sharing class ScJarvisSurvey {
    /**
    * @description 
    * @author Vishnu Vardhan | 12-09-2021 
    * @param String surveyDeveloperName 
    * @param String feedbackCategory 
    * @param String pageName 
    * @return String 
    **/
    @auraEnabled
    public static String getSurveyInvitationLink(String surveyDeveloperName, String feedbackCategory, String pageName){
        
        String surveyInvName = getSurveyInvName(surveyDeveloperName, feedbackCategory, pageName);
        
        List<SurveyInvitation> svInvs = [select id, InvitationLink, ResponseStatus from SurveyInvitation 
                                   			where Survey.DeveloperName = :surveyDeveloperName 
                                                  and name = :surveyInvName
                                   				  and Feedback_Category__c = :feedbackCategory 
                                   				  and Page_Name__c = :pageName
                                                  and createdById = :UserInfo.getUserId()
                                            Order by createddate desc limit 1]; 
        if(svInvs.size() > 0) {
            if(svInvs[0].ResponseStatus == 'Completed') {
                throw new AuraHandledException('Survey Completed');
            }
            return svInvs[0].InvitationLink;
        }
        
        List<Survey> svList = [SELECT Id, DeveloperName, SurveyType, LatestVersionId, Description, Name, ActiveVersionId 
                                       FROM Survey 
                                       where DeveloperName = :surveyDeveloperName];
                                                                                      
        if(svList.isEmpty()) {
            throw new AuraHandledException('Invalid Survey Name');
        }     
        
        SurveyInvitation sInv =  getNewSurveyInvitation(surveyInvName, svList[0].Id, feedbackCategory, pageName);
        insert sInv;
        
        List<SurveyInvitation> queriedSvyInvs = [SELECT Id, Name, InvitationLink, Case__c FROM SurveyInvitation where id = :sInv.Id];
        
        return queriedSvyInvs[0].InvitationLink;

    }

    /**
    * @description 
    * @author Vishnu Vardhan | 02-25-2022 
    * @param String surveyInvName 
    * @param String surveyId 
    * @param String feedbackCategory 
    * @param String pageName 
    * @return SurveyInvitation 
    **/
    public static SurveyInvitation getNewSurveyInvitation(String surveyInvName, String surveyId, String feedbackCategory, String pageName) {
        SurveyInvitation sinv = new SurveyInvitation( Name = surveyInvName, 
                                       SurveyId = surveyId, 
                                       CommunityId = Network.getNetworkId(), 
                                       Feedback_Category__c = feedbackCategory, 
                                       Page_Name__c = pageName, 
                                       OptionsCollectAnonymousResponse = true, 
                                       OptionsAllowGuestUserResponse = false );
        return sinv;
    }

    /**
    * @description 
    * @author Vishnu Vardhan | 02-25-2022 
    * @param String surveyDeveloperName 
    * @param String feedbackCategory 
    * @param String pageName 
    * @return String 
    **/
    private static String getSurveyInvName(String surveyDeveloperName, String feedbackCategory, String pageName) {
        return system.hashCode(Userinfo.getSessionId()) + '-' + feedbackCategory + '-'+ pageName + '-'+ surveyDeveloperName;
    }
}