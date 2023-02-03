global with sharing class HD_Problem_Incident_Clone_Extension {
    @RemoteAction
    @AuraEnabled
    webservice static String cloneIncidentToProblem(String currentIncidentId)
    {
        try{
            System.debug('Current Incident id in class: '+currentIncidentId);
            BMCServiceDesk__Incident__c currentIncident=new BMCServiceDesk__Incident__c();
            currentIncident=[Select name, BMCServiceDesk__incidentDescription__c, BMCServiceDesk__FKImpact__c, BMCServiceDesk__FKCategory__c, BMCServiceDesk__shortDescription__c, BMCServiceDesk__FKUrgency__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Incident__c.Id=:currentIncidentId];
            BMCServiceDesk__Problem__c newProblem=new BMCServiceDesk__Problem__c();
            newProblem.BMCServiceDesk__Problem_Source__c='Incident';
            newProblem.Parent_Incident__c =currentIncidentId;
            newProblem.Title_Summary__c = 'Problem created from incident number ->' + currentIncident.name+'. PLEASE CHANGE TO APPROPRIATE TITLE';  
            List<Incident_Problem_Clone__c> fields=Incident_Problem_clone__c.getAll().values();
            for(Incident_Problem_Clone__c cloneField:fields){
                String fieldIncident= cloneField.IncidentAPIName__c;
                String fieldProblem = cloneField.ProblemAPIName__c;
                newProblem.put(fieldProblem,currentIncident.get(fieldIncident));
            }
            if(String.isBlank(currentIncident.BMCServiceDesk__incidentDescription__c))
            {
                newProblem.BMCServiceDesk__Problem_Description__c  = 'Enter Problem Description.';
            }
            insert newProblem;
            String newProblemId=newProblem.Id;    
            return newProblemId;
        }
        catch(Exception e){
            return null;
        }
    }
    
    @AuraEnabled
	public static string getPage(String currentId){
    	PageReference pg = new PageReference('/apex/BMCServiceDesk__StdLayoutBtnToolbarPage?Id='+currentId+'&action=CreateIncidentTaskLink&incidentId='+currentId);
    	return pg.getUrl();
	}
}