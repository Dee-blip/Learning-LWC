public with sharing class HD_IncidentBulkUpdate {
    
    public class DatabaseResult
    {
        @AuraEnabled 
        public List<Id> successes;
        @AuraEnabled 
        public Map <Id,String> failures;
                
        public DatabaseResult()
        {
           successes = new List<Id>();
           failures = new Map<Id,String>();
        }
        
    }
    
    @AuraEnabled
    public static DatabaseResult bulkAssign(List<Id> incidentIds,List<BMCServiceDesk__Incident__c> incidentData,Id ownerId){
        
        try
        {
            
        
        DatabaseResult res = new DatabaseResult();
        List<BMCServiceDesk__Incident__c> incidents = new List<BMCServiceDesk__Incident__c>();
        BMCServiceDesk__Incident__c incident;
        BMCServiceDesk__Status__c assigned = [select Id,Name from BMCServiceDesk__Status__c where Name='ASSIGNED' limit 1];

        for(BMCServiceDesk__Incident__c inc:incidentData)
        {
            incident = new BMCServiceDesk__Incident__c();
            incident.id = inc.Id;
            if(ownerId == null)
            {
                incident.OwnerId = System.Userinfo.getUserId();
            }
            else
            {
                incident.OwnerId = ownerId;
            }
            incident.BMCServiceDesk__FKStatus__c = assigned.Id;
            System.debug('incident name'+incident.Name);
            incidents.add(incident);
        }
        
        List<Database.SaveResult> srList = Database.update(incidents, false);
        
        System.debug('srList'+srList);
        System.debug('incidents'+incidents);
        
        /*
        for (Database.SaveResult sr : srList) 
        {
            if (sr.isSuccess()) 
            {
        		System.debug('Successfully Updated Incident' + sr.getId());
                res.successes.add(sr.getId());
                
            }
            else 
            {
                for(Database.Error err : sr.getErrors()) 
                {
                    System.debug('The following error has occurred.'+err.getStatusCode() + ': ' + err.getMessage()+err);
                    
                    Set<Id> s1 = new Set<Id>();

                    
                    res.failures.put(sr.getId(), err.getMessage());
                    //System.debug('Incident fields that affected this error: ' + err.getFields());
                }
            }
        }*/
        for(Integer i=0;i<incidents.size();i++)
        {
            Database.SaveResult sr = srList[i];
            if (sr.isSuccess()) 
            {
        		System.debug('Successfully Updated Incident' + sr.getId());
                res.successes.add(sr.getId());
                
            }
            else 
            {
                for(Database.Error err : sr.getErrors()) 
                {
                    System.debug('The following error has occurred.'+err.getStatusCode() + ': ' + err.getMessage()+err);
                    res.failures.put(incidents[i].Id ,err.getMessage());
                    //System.debug('Incident fields that affected this error: ' + err.getFields());
                }
            }
        }
        
        System.debug('result'+res);
		return res;
        }
        catch(Exception e){
             throw new AuraHandledException(e.getMessage()); 
        }
        
        
    }
    
    @AuraEnabled
    public static List<User> getAllStaffs(){
        List<User> staffUsers = [Select ID, name, Email  from User where IsActive=true and BMCServiceDesk__IsStaffUser__c=true order by name asc limit 10000]; 
        return staffUsers;
    }

}