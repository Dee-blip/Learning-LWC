/*
Author: Samir Jha
Date: 5/8/2014
CR: 2026963
*/
public class SI_UpdateSIOwnerAndLastOwner 
{
    
    public static void SI_UpdateSIOwnerAndLastOwner(list<BMCServiceDesk__Incident__c> newServiceIncidentList , Map<Id,BMCServiceDesk__Incident__c> oldServiceIncidentMap)
    {
       List<BMCServiceDesk__Incident__c> incidentsToUpdateList = new list<BMCServiceDesk__Incident__c>();
       String recordTypeIdSI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
       for(BMCServiceDesk__Incident__c incident:newServiceIncidentList)
       {
            if(incident.RecordTypeId == recordTypeIdSI && incident.OwnerId != oldServiceIncidentMap.get(incident.id).OwnerId && ((string)(oldServiceIncidentMap.get(incident.id).OwnerId)).startsWith('005'))
            {
                incident.Last_Owner__c = oldServiceIncidentMap.get(incident.id).OwnerId;
               
            }
                
       }
          
    
    }    
        
}