/*
* File Name: HD_KA_Viewer_Controller
* Description : This class is used by Knowledge Article search component to handle operations related to Knowledge Articles
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 22nd, 2021    Aneesh Budnar       PRTORES-2123 - HD Create Knowledge article Search and view Panel in LWC for Lighting UI for staff Part 2
*/
public without sharing class HD_KA_Viewer_Controller {
    @AuraEnabled
    public static void linkKAToIncident(String knowledgeArticleId, String incidentId) {
        try {
            if(!BMCServiceDesk__KM_Knowledge_Incident_Link__c.SObjectType.getDescribe().isAccessible()) {
                   return;
            }
            
            List<BMCServiceDesk__KM_Knowledge_Incident_Link__c> link = [SELECT Id FROM BMCServiceDesk__KM_Knowledge_Incident_Link__c  
                                                                        WHERE BMCServiceDesk__Knowledge_Article__c = :knowledgeArticleId AND BMCServiceDesk__Incident__c  = :incidentId];
            if(link.size() == 0) {
                insert new BMCServiceDesk__KM_Knowledge_Incident_Link__c(
                    BMCServiceDesk__Knowledge_Article__c = knowledgeArticleId,
                    BMCServiceDesk__Incident__c = incidentId);
            }
        }
        catch(Exception ex) {
            String message = ex.getMessage();
            if(message.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                String[] splitErrorMessage = message.split(',');
                message = splitErrorMessage[1];
            }
            throw new AuraHandledException(message);
        }
    }
    
    @AuraEnabled
    public static void removeLinkBWKAAndIncident(String knowledgeArticleId, String incidentId) {
        try {
            if(!BMCServiceDesk__KM_Knowledge_Incident_Link__c.SObjectType.getDescribe().isAccessible()) {
                   return;
            }            
        	delete [SELECT Id FROM BMCServiceDesk__KM_Knowledge_Incident_Link__c  
                                                                        WHERE BMCServiceDesk__Knowledge_Article__c = :Id.valueOf(knowledgeArticleId) 
                                                                        AND BMCServiceDesk__Incident__c  = :Id.valueOf(incidentId)];
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static String getAllLinkedKnowledgeArticles(String incidentId) {
        try {
            if(!BMCServiceDesk__KM_Knowledge_Incident_Link__c.SObjectType.getDescribe().isAccessible() ||
               !BMCServiceDesk__KM_KnowledgeArticle__c.SObjectType.getDescribe().isAccessible()) {
                   return '';
               }
            List<BMCServiceDesk__KM_Knowledge_Incident_Link__c> links = [SELECT Id, BMCServiceDesk__Knowledge_Article__c  
                                                                         FROM BMCServiceDesk__KM_Knowledge_Incident_Link__c  
                                                                         WHERE BMCServiceDesk__Incident__c = :Id.valueOf(incidentId)];
            List<Id> kaIds = new List<Id>();
            for(BMCServiceDesk__KM_Knowledge_Incident_Link__c link : links) {
                kaIds.add(link.BMCServiceDesk__Knowledge_Article__c);
            }
            
            return JSON.serialize([SELECT Id, Name, BMCServiceDesk__Article_Type__c,BMCServiceDesk__Category__c,BMCServiceDesk__Status__c, BMCServiceDesk__Title__c
                                   FROM BMCServiceDesk__KM_KnowledgeArticle__c WHERE Id IN :kaIds]);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    
    @AuraEnabled(cacheable = true)
    public static String getFavouriteKAs() {
        try {
            return JSON.serialize([SELECT Id, Name, BMCServiceDesk__Article_Type__c,BMCServiceDesk__Category__c,BMCServiceDesk__Status__c, BMCServiceDesk__Title__c, BMCServiceDesk__Used_Count__c, BMCServiceDesk__Relevance__c 
                                   FROM BMCServiceDesk__KM_KnowledgeArticle__c WHERE BMCServiceDesk__Relevance__c > 0]);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}