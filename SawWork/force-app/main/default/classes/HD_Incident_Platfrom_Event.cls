/*
* @Developer : Hemant Barapatre
* purpose : TO fire platfrom evnt with subsequent Incident data
* wrapper class : HD_Inc_Platfrom_Event_SR_Wrapper_Class
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* 24th Aug 2020      Arihant Jain         PRTORES-1908-Code Scanner
* Sep 28th, 2020     Aneesh Budnar        1906-Create Events for ODI Load Trigger
* Nov 29th, 2021     Aneesh Budnar        PRTORES-2358 - HD Code Scanner 1 fixes
*/
public class HD_Incident_Platfrom_Event {
	private static Map<String, Set<String>> platformEventFilterConfig;
    @TestVisible private static List<Incident_Object__e> platformEvents = new List<Incident_Object__e>();
    /*
    //this method is used to retrive the service request details
    public static String getServiceRequestDetails(String incidentId){
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> srmReqDetInp = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
        List<HD_Inc_Platfrom_Event_SR_Wrapper_Class> HIPESWList = new List<HD_Inc_Platfrom_Event_SR_Wrapper_Class>();
        List<BMCServiceDesk__SRM_RequestDetail__c> srd = new List<BMCServiceDesk__SRM_RequestDetail__c>();
        srd = [select Id from BMCServiceDesk__SRM_RequestDetail__c where BMCServiceDesk__FKIncident__c =:incidentId];
        String Trimmed_ID = String.valueOf(incidentId).substring(0,15);
        srmReqDetInp = [select id, HD_Incident_id__c, BMCServiceDesk__Input__c, BMCServiceDesk__Response__c from BMCServiceDesk__SRM_RequestDetailInputs__c where HD_Incident_id__c=:incidentId  LIMIT 100];
        system.debug('Trimmed_ID --> '+Trimmed_ID);
        system.debug('--> '+srd);
        if(srmReqDetInp.size() > 0){
            for(BMCServiceDesk__SRM_RequestDetailInputs__c reqdes : srmReqDetInp){
                HD_Inc_Platfrom_Event_SR_Wrapper_Class HIPESW = new HD_Inc_Platfrom_Event_SR_Wrapper_Class();
            	HIPESW.inputprompt = reqdes.BMCServiceDesk__Input__c;
                HIPESW.Response = reqdes.BMCServiceDesk__Response__c;
                HIPESWList.add(HIPESW);
            }//for(BMCServiceDesk__SRM_RequestDetailInputs__c reqdes : srmReqDetInp)            
        }//id
        system.debug('--> '+JSON.serialize(srd));
        return JSON.serialize(HIPESWList);
    }//METHOD
    */
    private static Boolean isPlatformEventRequired(BMCServiceDesk__Incident__c inc) {
        platformEventFilterConfig = getPFFilterConfiguration();
        
        return (platformEventFilterConfig.containsKey('Category') && platformEventFilterConfig.get('Category').contains(inc.BMCServiceDesk__FKCategory__r.Name)) ||
            	(platformEventFilterConfig.containsKey('Service Request Title') &&
                 platformEventFilterConfig.get('Service Request Title').contains(inc.BMCServiceDesk__Service_Request_Title__c));
    }
    
    private static Map<String, Set<String>> getPFFilterConfiguration() {
        if(platformEventFilterConfig == null) {
            platformEventFilterConfig = new Map<String, Set<String>>();
            List<HD_Platform_Event_Filters__mdt> configs = [SELECT Id, DeveloperName, Type__c, Filter_Values__c FROM HD_Platform_Event_Filters__mdt LIMIT 100];
            for(HD_Platform_Event_Filters__mdt config : configs) {
                if(!platformEventFilterConfig.containsKey(config.Type__c)) {
                    platformEventFilterConfig.put(config.Type__c, new Set<String>());
                }
                String[] filterValues = config.Filter_Values__c.split('\n');
                Set<String> filteredValuesSet = new Set<String>();
                for(String filterValue : filterValues) {
                    filteredValuesSet.add(filterValue.trim());
                }
                platformEventFilterConfig.get(config.Type__c).addAll(filteredValuesSet);
            }
        }
        return platformEventFilterConfig;
    }
    
    @InvocableMethod
    public static void publish_Incident_Event(List<BMCServiceDesk__Incident__c> incList){
        List<BMCServiceDesk__Incident__c> inc_obj = new List<BMCServiceDesk__Incident__c>();
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> srmReqDetInp;
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> listReqDetInp = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
        Map<Id,List<BMCServiceDesk__SRM_RequestDetailInputs__c>> incToReqDetInp = new Map<Id,List<BMCServiceDesk__SRM_RequestDetailInputs__c>>();
        List<Id> requestDetailIDList = new List<Id>();
        inc_obj = incList;   

        for(BMCServiceDesk__Incident__c inc : inc_obj){
            requestDetailIDList.add(inc.BMCServiceDesk__FKRequestDetail__c);
        }
        listReqDetInp = [select id, HD_Incident_id__c, BMCServiceDesk__Input__c, BMCServiceDesk__Response__c, BMCServiceDesk__FKRequestDetail__c from BMCServiceDesk__SRM_RequestDetailInputs__c where BMCServiceDesk__FKRequestDetail__c IN :requestDetailIDList LIMIT 50000];

        for(BMCServiceDesk__SRM_RequestDetailInputs__c rdInput : listReqDetInp){
            if(!incToReqDetInp.containsKey(rdInput.BMCServiceDesk__FKRequestDetail__c)){
                incToReqDetInp.put(rdInput.BMCServiceDesk__FKRequestDetail__c, new List <BMCServiceDesk__SRM_RequestDetailInputs__c> ());
            }
            incToReqDetInp.get(rdInput.BMCServiceDesk__FKRequestDetail__c).add(rdInput);
        }

        for(BMCServiceDesk__Incident__c inc : inc_obj){
            if(isPlatformEventRequired(inc)) {
                srmReqDetInp = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
                if(incToReqDetInp.containsKey(inc.BMCServiceDesk__FKRequestDetail__c)){
                    srmReqDetInp = incToReqDetInp.get(inc.BMCServiceDesk__FKRequestDetail__c);
                }
    
                //srmReqDetInp = [select id, HD_Incident_id__c, BMCServiceDesk__Input__c, BMCServiceDesk__Response__c from BMCServiceDesk__SRM_RequestDetailInputs__c where BMCServiceDesk__FKRequestDetail__c =:inc.BMCServiceDesk__FKRequestDetail__c  LIMIT 100];
                String srDetails = JSON.serialize(srmReqDetInp);
                
                Incident_Object__e   incEvent  = new Incident_Object__e (
                    Category__c  = inc.BMCServiceDesk__Category_ID__c ,Category_Id__c = inc.BMCServiceDesk__FKCategory__c  ,Category_Type__c =inc.HD_IncidentGroup__c,
                    FKClientID__c = inc.BMCServiceDesk__FKClient__c ,clientId__c = inc.BMCServiceDesk__clientId__c,Client_ID_Email__c=inc.BMCServiceDesk__clientEmail__c,
                    Description__c  = inc.BMCServiceDesk__incidentDescription__c ,
                    incident__c=inc.Name,incident_id__c= inc.Id,
                    Owner__c=inc.Owner.name,Owner_Id__c =inc.OwnerId,
                    Service_Request_Details__c = srDetails,
                    Status__c=inc.BMCServiceDesk__Status_ID__c,Type__c=inc.BMCServiceDesk__Type__c );   
                platformEvents.add(incEvent);
                Database.SaveResult sr = EventBus.publish(incEvent);
                if( sr.isSuccess()){
                    System.debug( LoggingLevel.DEBUG, 'Successfully published event.');
                }else{
                    for(Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Error returned: ' +
                                     err.getStatusCode() +
                                     ' - ' +
                                     err.getMessage());
                    }//for(Database.Error err : sr.getErrors())
                }//else 
            }           
        }//for(BMCServiceDesk__Incident__c inc : inc_obj)
        
    }//
           
}//END CLASS