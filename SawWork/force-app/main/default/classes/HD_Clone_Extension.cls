global with sharing class HD_Clone_Extension {
    @AuraEnabled
    @RemoteAction
    webservice static String cloneIncident(String currentIncidentId)
    {
        try
        {
         System.debug('Current Incident id in class: '+currentIncidentId);
         
         //Get the incident object to be cloned
         BMCServiceDesk__Incident__c currentIncident=new BMCServiceDesk__Incident__c();
         currentIncident=[Select BMCServiceDesk__FKUrgency__c,BMCServiceDesk__FKImpact__c,BMCServiceDesk__Client_Manager__c,BMCServiceDesk__Client_Name__c,BMCServiceDesk__Client_Phone__c,BMCServiceDesk__FKClient__c, BMCServiceDesk__FKCategory__c, CCText__c, Approver__c, HD_Routing_Settings__c, BMCServiceDesk__FKTemplate__c, BMCServiceDesk__shortDescription__c,BMCServiceDesk__incidentDescription__c, BMCServiceDesk__FKRequestDefinition__c,BMCServiceDesk__FKRequestDetail__c,Same_Region_Ticket__c,HD_High_Customer_Impact__c,HD_Ticket_Priority__c,HD_WhiteHat_Incident__c,HD_Approval_Status__c,Effort_Estimation__c,BMCServiceDesk__FKCategory__r.BMCServiceDesk__AvailableForIncidents__c,BMCServiceDesk__FKCategory__r.BMCServiceDesk__AvailableForServiceCatalog__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Incident__c.Id=:currentIncidentId];
         System.debug('Got the current incident');
         System.debug('Urgency for current incident: '+currentIncident.BMCServiceDesk__FKUrgency__c);
            if(currentIncident.BMCServiceDesk__FKCategory__r.BMCServiceDesk__AvailableForIncidents__c == false && currentIncident.BMCServiceDesk__FKCategory__r.BMCServiceDesk__AvailableForServiceCatalog__c == false){
				return 'Category Unavailable';
            }   
         BMCServiceDesk__Incident__c newIncident=new BMCServiceDesk__Incident__c();
        
         //Get the list of fields to be copied from custom setting 
         List<Incident_CloneFields__c> fields=Incident_CloneFields__c.getAll().values();
         for(Incident_CloneFields__c cloneField:fields)
         {
             System.debug('Inside For loop');
             String field=cloneField.APIName__c;
             System.debug('Field: '+field);
             newIncident.put(field,currentIncident.get(field));
         }
         
         //System.debug('Setting Urgency and Impact');
         //newIncident.BMCServiceDesk__FKUrgency__c=currentIncident.BMCServiceDesk__FKUrgency__c;
         //newIncident.BMCServiceDesk__FKImpact__c=currentIncident.BMCServiceDesk__FKImpact__c;
         
         newIncident.BMCServiceDesk__incidentResolution__c='';
         newIncident.BMCServiceDesk__dueDateTime__c=null;
         newIncident.BMCServiceDesk__closeDateTime__c=null;
         
         //Insert new incident
         System.debug('Inserting new incident');
         insert newIncident;
        
         String newIncidentId=newIncident.Id;    
         System.debug('Cloned incident id in class: '+newIncidentId);
         return newIncidentId;
     }// try block
     
     catch(Exception e)
     {
         System.debug('Throwing exception from here: '+e.getMessage());
         //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,e.getMessage()));
         return null;
     }//catch block
   
    } //function to clone an incident
    
    @RemoteAction
    webservice static String getIncidentNum(String incidentId)
    {
        BMCServiceDesk__Incident__c currentIncident=new BMCServiceDesk__Incident__c();
        currentIncident= [Select Incident_No__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Incident__c.Id=:incidentId];
        String newIncidentNum=currentIncident.Incident_No__c;
        return newIncidentNum;
    } // function to get incident number from incident id
  }//class