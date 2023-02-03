/*
* File Name : HD_AnnouncementController
* Description : This class is used by the HD_Announcement component for fetching active announcement records 
* @author : Vaishnavi Sinha
* Modification Log ===============================================================
* Date 				 Author 			   Modification
* March 2nd, 2022    Vaishnavi Sinha       PRTORES-2354 - HD CMR Announcement module in LWC
*/

public without sharing class HD_AnnouncementController {

    public static List<Id> getUserAnnouncementIds() {
        List<HD_Announcement_User__c> seenUserAnnouncements = [SELECT HD_Announcement_Id__c FROM HD_Announcement_User__c 
                                                               WHERE User_Id__c = :UserInfo.getUserId() AND Hide_Announcement__c = TRUE];
        List<Id> idlst = new List<Id>();
        for(HD_Announcement_User__c u : seenUserAnnouncements) {
            idlst.add(u.HD_Announcement_Id__c);
        }
        return idlst;
    }

    public static String getActiveApplication(){
        if(Test.isRunningTest()) {
            return 'Akamai Helpdesk';
        }

        try {
            UserAppInfo userAppInfo = [SELECT Id, AppDefinitionId FROM UserAppInfo WHERE UserId = :UserInfo.getUserId() LIMIT 1];
            AppDefinition appDefinition = [SELECT DurableId, Label FROM AppDefinition WHERE DurableId = :userAppInfo.AppDefinitionId LIMIT 1];
            return appDefinition.Label;
        }
        catch (Exception e) {
            HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),null);
            return '';
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static HD_Announcement__c getGlobalActiveAnnouncement(List<Id> cookieAnnouncementIds){
        List<Id> seenAnnouncementIds = HD_AnnouncementController.getUserAnnouncementIds();
        seenAnnouncementIds.addAll(cookieAnnouncementIds);
        String appName = HD_AnnouncementController.getActiveApplication();
        List<HD_Announcement__c> globalAnnouncements = [SELECT Id, Name, Summary__c, Active__c, ToDate__c, Show_On_Page__c, App_Name__c, Object_Api_Name__c FROM HD_Announcement__c 
                                                        WHERE Active__c = TRUE AND ToDate__c > :Datetime.now() AND Id NOT IN :seenAnnouncementIds AND Show_On_Page__c = 'Global' 
                                                        AND (App_Name__c = :appName OR App_Name__c = '') AND FeatureChildren__c > 0 LIMIT 5];
        

        for(HD_Announcement__c globalAnnouncement : globalAnnouncements) {
            if(HD_AnnouncementController.getAnnouncementFeatures(globalAnnouncement.Id).size() > 0) {
                return globalAnnouncement;
            }
        }

        return null;
    }

    @AuraEnabled(cacheable=true)
    public static HD_Announcement__c getActiveAnnouncement(List<Id> cookieAnnouncementIds, String pageType, String objectName) {
        List<Id> seenAnnouncementIds = HD_AnnouncementController.getUserAnnouncementIds();
        seenAnnouncementIds.addAll(cookieAnnouncementIds);
        List<HD_Announcement__c> activeAnnouncements = new List<HD_Announcement__c>();

        if(pageType == 'standard__recordPage') {
            activeAnnouncements = [SELECT Id, Name, Summary__c, Active__c, ToDate__c, Show_On_Page__c, App_Name__c, Object_Api_Name__c FROM HD_Announcement__c 
                                   WHERE Active__c = TRUE AND ToDate__c > :Datetime.now() AND Id NOT IN :seenAnnouncementIds AND Show_On_Page__c = 'Record Page'
                                   AND Object_Api_Name__c = :objectName AND FeatureChildren__c > 0 LIMIT 5];
        }
        else if(pageType == 'standard__namedPage') {
            String appName = HD_AnnouncementController.getActiveApplication();
            activeAnnouncements = [SELECT Id, Name, Summary__c, Active__c, ToDate__c, Show_On_Page__c, App_Name__c, Object_Api_Name__c FROM HD_Announcement__c 
                                  WHERE Active__c = TRUE AND ToDate__c > :Datetime.now() AND Id NOT IN :seenAnnouncementIds AND Show_On_Page__c = 'Home Page'
                                  AND  App_Name__c = :appName AND FeatureChildren__c > 0 LIMIT 5];
        }

        for(HD_Announcement__c activeAnnouncement : activeAnnouncements) {
            if(HD_AnnouncementController.getAnnouncementFeatures(activeAnnouncement.Id).size() > 0) {
                return activeAnnouncement;
            }
        }

        return null;
    }

    @AuraEnabled(cacheable=true)
    public static List<HD_Announcement_Features__c> getAnnouncementFeatures(Id parentId) {
        return [SELECT Id, Name, Short_Description__c, Order__c, Details__c FROM HD_Announcement_Features__c WHERE HD_Announcement__c = :parentId AND Active__c = TRUE ORDER BY Order__c];
    }

    @AuraEnabled
    public static void saveUserAnnouncement(Id announcementId, Boolean hideAnnouncement) {
        try {
            Id uid= UserInfo.getUserId();
            List<HD_Announcement_User__c> re = [SELECT Id, HD_Announcement_Id__c, User_Id__c, Last_Seen__c, Hide_Announcement__c, No_of_Times_Seen__c 
                                                FROM HD_Announcement_User__c WHERE User_Id__c= :uid AND HD_Announcement_Id__c = :announcementId LIMIT 1];

            if(re.size() > 0) {
                re[0].Last_Seen__c = Date.today();
                if(!hideAnnouncement) {
                    re[0].No_of_Times_Seen__c += 1;
                }
                re[0].Hide_Announcement__c = hideAnnouncement;
                update re[0];
            }
            else {
                HD_Announcement_User__c userAnnouncement = new HD_Announcement_User__c();
                userAnnouncement.User_Id__c = uid;
                userAnnouncement.HD_Announcement_Id__c = announcementId;
                userAnnouncement.Last_Seen__c = Date.today();
                userAnnouncement.Hide_Announcement__c = hideAnnouncement;
                insert userAnnouncement; 
            }  
        } catch (Exception e) {
            HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),null);
        }
    }
}