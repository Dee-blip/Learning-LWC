/*
* File Name: HD_Incident_TagFinder
* Description : Class which is invoked from flow to get the tags that correspond to the given Incident
* @author : Vaishnavi Sinha
* Modification Log ===============================================================
* Date 				Author 				Modification
* Dec 22nd, 2021    Aneesh Budnar       PRTORES-2377 - Add Tag Incidents field to email service
*/
public without sharing class HD_Incident_TagFinder {
    
    @InvocableMethod(label='Get Tag for Incident' description='Gets the appropriate tags for the incident')
    public static List<List<Id>> getIncidentTags(List<Id> incidentIds) {
        Id incId = incidentIds[0];
        String incidentTag = '';
        List<HD_Instance__mdt> customSettings;
        List<String> topics = new List<String>();
        List<List<Id>> ids = new List<List<Id>>();
        
        try {
            BMCServiceDesk__Incident__c inc = [SELECT BMCServiceDesk__FKCategory__r.Name, 
                                                      BMCServiceDesk__FKCategory__r.HD_Application__c, 
                                                      HD_Parent_Category__c, BMCServiceDesk__Type__c, HD_ServiceRequest_FInput__c ,
                                                      BMCServiceDesk__Client_Manager__r.Name 
                                                      FROM BMCServiceDesk__Incident__c WHERE Id = :incId LIMIT 1];
            String[] nameFilters = new String[]{'Application_available_for_Team_Tag', 
                								'Category_to_Team_Tag_Mapping%', 
                								'Client_Manager_to_Team_Tag_Mapping%',
                								'Email_Alert_To_Environment_Tag%'};
            Map<String, List<HD_Instance__mdt>> typeToMDTMap = new Map<String, List<HD_Instance__mdt>>();
            for(HD_Instance__mdt setting : [SELECT Id, DeveloperName, SettingValue__c FROM HD_Instance__mdt 
                                            WHERE  DeveloperName LIKE :nameFilters]) {
                if(!typeToMDTMap.containsKey(setting.DeveloperName)) {
                    typeToMDTMap.put(setting.DeveloperName, new List<HD_Instance__mdt>());
                }
                
                typeToMDTMap.get(setting.DeveloperName).add(setting);
            }
            
            List<String> appList = typeToMDTMap.get('Application_available_for_Team_Tag')[0].SettingValue__c.split(';');
            
            if(appList.contains(inc.BMCServiceDesk__FKCategory__r.HD_Application__c)) {
                incidentTag = getTagNameBasedOnCategory(inc,typeToMDTMap.get('Category_to_Team_Tag_Mapping_1'));
                
                if(incidentTag == '' && inc.BMCServiceDesk__Client_Manager__r.Name != null) {
                    incidentTag = getTagNameBasedOnClientName(inc,typeToMDTMap.get('Client_Manager_to_Team_Tag_Mapping_1'));
                }
            }
            
            if(!String.isEmpty(incidentTag)) {
                topics.add(incidentTag);
            }
            
            if(!String.isEmpty(inc?.HD_ServiceRequest_FInput__c)) {
                    topics.add(getTagNameBasedOnEnvironment(inc,typeToMDTMap.get('Email_Alert_To_Environment_Tag_1')));
                
            }
            if(!topics.isEmpty()) {
                Map<Id,Topic> t = new Map<Id, Topic>([SELECT Id from Topic WHERE Name IN : topics]);
                ids.add(new List<Id>(t.keySet()));
                return ids;
            }
            
            ids.add(new List<Id>());
            return ids;
        }
        catch(Exception e) {
            HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),incId);
            ids.add(new List<Id>());
            return ids;
        }
    }
    
    private static String getTagNameBasedOnCategory(BMCServiceDesk__Incident__c inc, List<HD_Instance__mdt> customSettings) {
        if(customSettings.size() > 0) {
            List<String> mappingValues = customSettings[0].SettingValue__c.split(';');
            for(Integer i = 0;i < mappingValues.size();i++) {
                List<String> mapping = mappingValues[i].split(':');
                if(inc.BMCServiceDesk__FKCategory__r.Name == mapping[0]  &&  inc.HD_Parent_Category__c == mapping[1]){
                    return mapping[2];
                }
            }
        }
        return '';
    }
    
    private static String getTagNameBasedOnClientName(BMCServiceDesk__Incident__c inc, List<HD_Instance__mdt> customSettings) {
        if(customSettings.size() > 0) {
            List<String> mappingValues = customSettings[0].SettingValue__c.split(';');
            for(Integer i = 0;i < mappingValues.size();i++) {
                List<String> mapping = mappingValues[i].split(':');
                if(mapping.contains(inc.BMCServiceDesk__Client_Manager__r.Name)) {
                    return mapping[mapping.size()-1];
                }
            }
        }
        return '';
    }
    
    private static String getTagNameBasedOnEnvironment(BMCServiceDesk__Incident__c inc, List<HD_Instance__mdt> customSettings) {
        for(HD_Instance__mdt instance: customSettings) {
            List<String> splitSettings = instance.SettingValue__c?.split(';');
            if(!splitSettings.isEmpty()) {
                for(String setting : splitSettings) {
                    List<String> fieldValues = setting.split(':');
                    if(inc.HD_ServiceRequest_FInput__c == fieldValues[0] && inc?.BMCServiceDesk__Type__c == fieldValues[1] ) {
                        return fieldValues[0];
                    }
                }
            }
        }
        return '';
    }
}