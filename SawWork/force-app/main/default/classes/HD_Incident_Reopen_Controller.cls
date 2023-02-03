public class HD_Incident_Reopen_Controller {

    public String DisplayText {get; set;}
    public Boolean CallUpdate {get; set;}
        
    private BMCServiceDesk__Incident__c Incident;
    public HD_Incident_Reopen_Controller(ApexPages.StandardController stdController) {

		Incident = (BMCServiceDesk__Incident__c)stdController.getRecord();
		String IncidentId = Incident.Id;            
		Incident = [select Id, Name, Last_Owner__c, OwnerId, BMCServiceDesk__FKStatus__c, Effort_Estimation__c , BMCServiceDesk__FKClient__c from BMCServiceDesk__Incident__c where ID = :IncidentId];
          
		DisplayText = 'Please wait while your ticket is being reopened';
		CallUpdate = true;
    }
    
    public pagereference UpdateIncident()
    {
        if(!Authorize()) 
        {
            CallUpdate = false;
            DisplayText = 'You are not authorised to reopen this ticket';
            return null;
        }
        
        try
        {
            string ReopenStatus = '';
            string AssignedStateId = [select Id from BMCServiceDesk__Status__c where Name='ASSIGNED'][0].Id; 
            string UnAssignedStateId = [select Id from BMCServiceDesk__Status__c where Name='UNASSIGNED'][0].Id;
            
            HD_Resolved_Status_Settings__c custom_settings = HD_Resolved_Status_Settings__c.getInstance('reopen_status');
			if(custom_settings != null)
				ReopenStatus= custom_settings.textvalue__c;            
            
            string ReopenedStateId = '';
            
            if(ReopenStatus != null)
            ReopenedStateId = [select Id from BMCServiceDesk__Status__c where Name= :ReopenStatus][0].Id; 
            else
                ReopenedStateId = UnAssignedStateId;
            
			incident.BMCServiceDesk__FKStatus__c = ReopenedStateId;
			incident.Effort_Estimation__c = null;
			update incident;
            return Redirect();
        }
        catch (DMLException e)
        {
            DisplayText = 'Sorry, could not reopen the ticket. \n' + e.getDmlMessage(0);
			
            CallUpdate = false;
            return null;
        }
        catch (Exception e)
        {
            system.debug(e.getMessage());
            DisplayText = 'Sorry, could not reopen the ticket. \n' + e.getMessage();
			
            CallUpdate = false;
            return null;
        }
        
    }

    private Boolean Authorize()
    {
        String userId = userinfo.getUserId();
        if(userId == Incident.BMCServiceDesk__FKClient__c)
        return true;
        else
            return false;        
    }
    
   public pagereference Redirect(){
       try
       {
			PageReference demoPage = new PageReference('/?startURL=/apex/bmcservicedesk__ssredirect?inc=' + Incident.Id);
			demoPage.setRedirect(true);
			return demoPage;
       }
       catch( Exception e)
       {
            CallUpdate = false;
            return null;
       }
	}
    
}