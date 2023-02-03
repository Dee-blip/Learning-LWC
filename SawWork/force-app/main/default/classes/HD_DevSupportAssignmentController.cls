/*
* File Name: HD_DevSupportAssignmentController
* Description : Apex Controller for the Technical Support assignment tool on the Incident detail page
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 				Modification
* Sep 09th, 2020    Aneesh Budnar       PRTORES-1915 - Incident details page - Technical tire support_disable Update Record button till the fields are loaded
*/
public class HD_DevSupportAssignmentController {
	@AuraEnabled(Cacheable=true)
    public static User getUser(Id  recordId) {
        return [Select Id, Email FROM USer WHERE ID = :recordId];
    }
    
	@AuraEnabled(Cacheable=true)
    public static Boolean shouldSendEmail(Id recordId) {
        BMCServiceDesk__Incident__c incident = [SELECT Id, BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c FROM BMCServiceDesk__Incident__c WHERE Id = :recordId];
        List<HD_Instance__mdt> hdDevSupportEmailSetting = [SELECT Id,DeveloperName, SettingValue__c  FROM HD_Instance__mdt WHERE DeveloperName = 'HD_Dev_Support_Email_Categories'];
        if(!hdDevSupportEmailSetting.isEmpty() && String.isNotBlank(hdDevSupportEmailSetting[0].SettingValue__c)) {
            Set<String> supportedCategories = new Set<String>(hdDevSupportEmailSetting[0].SettingValue__c.split(';'));
            return supportedCategories.contains(incident.BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c);
        }
        return false;
    }
}