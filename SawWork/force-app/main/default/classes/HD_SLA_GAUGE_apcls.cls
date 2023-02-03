public class HD_SLA_GAUGE_apcls {
    
    @AuraEnabled
    public List<BMCServiceDesk__Incident_Service_Target__c> sla_details {get;set;}
    @AuraEnabled
    public HD_Default_Custom_Setting__c RF_Default_Custom_Setting{get;set;}
    
    
    @AuraEnabled
    public static List<BMCServiceDesk__Incident_Service_Target__c> getSLADetails(Id incidentId)
    {
        List<BMCServiceDesk__Incident_Service_Target__c> istList = [Select Id,
                                                                    lastmodifieddate,
                                                                    BMCServiceDesk__Status__c,
                                                                    BMCServiceDesk__StateValue__c,
                                                                    BMCServiceDesk__ClockState__c ,
                                                                    BMCServiceDesk__TargetType__c,
                                                                    BMCServiceDesk__TimeRemaining__c,
                                                                    BMCServiceDesk__StartDate__c,
                                                                    BMCServiceDesk__EndDate__c,
                                                                    BMCServiceDesk__SLAName__c,
                                                                    BMCServiceDesk__TargetEndDate__c,
                                                                    BMCServiceDesk__ServiceTargetName__c,
                                                                    BMCServiceDesk__TargetTypeValue__c ,
                                                                    BMCServiceDesk__FKIncident__c,
                                                                    BMCServiceDesk__ElapsedTime__c, 
                                                                    BMCServiceDesk__IsCanceled__c from BMCServiceDesk__Incident_Service_Target__c Where BMCServiceDesk__FKIncident__c =: incidentId];
        return istList;
    }
    
     @AuraEnabled
     public static HD_SLA_GAUGE_apcls ClassObject(Id incidentId)
     {
         HD_SLA_GAUGE_apcls obj = new HD_SLA_GAUGE_apcls();
         List<BMCServiceDesk__Incident_Service_Target__c> istList = [Select Id,
                                                                    lastmodifieddate,
                                                                    BMCServiceDesk__Status__c,
                                                                    BMCServiceDesk__StateValue__c,
                                                                    BMCServiceDesk__ClockState__c ,
                                                                    BMCServiceDesk__TargetType__c,
                                                                    BMCServiceDesk__TimeRemaining__c,
                                                                    BMCServiceDesk__StartDate__c,
                                                                    BMCServiceDesk__EndDate__c,
                                                                    BMCServiceDesk__SLAName__c,
                                                                    BMCServiceDesk__TargetEndDate__c,
                                                                    BMCServiceDesk__ServiceTargetName__c,
                                                                    BMCServiceDesk__TargetTypeValue__c ,
                                                                    BMCServiceDesk__FKIncident__c,
                                                                    BMCServiceDesk__ElapsedTime__c, 
                                                                    BMCServiceDesk__IsCanceled__c from BMCServiceDesk__Incident_Service_Target__c Where BMCServiceDesk__FKIncident__c =: incidentId];
        
         obj.sla_details =  istList; 
         
         //Logic for custom settings
         obj.RF_Default_Custom_Setting = HD_Default_Custom_Setting__c.getInstance('SLA_GAUGE_THRESHOLD');
         return obj;
     }

}