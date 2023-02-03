public with sharing class HD_SRMActionHistory_component_controller {

    //used as part of Component Attribute to get Incident Object Record ID
	public static String RecordId{get;set;}
	//Setting Record Limit 
	public static Integer recordLimit{get;set;}
	//List
	private List<BMCServiceDesk__IncidentHistory__c> actionHistoryList;
	
	//Select Name, BMCServiceDesk__userId__c, BMCServiceDesk__note__c, BMCServiceDesk__duration__c, BMCServiceDesk__description__c, BMCServiceDesk__actionId__c, BMCServiceDesk__Reply__c From BMCServiceDesk__IncidentHistory__c  where  BMCServiceDesk__FKIncident__c  = 'a5UZ00000009m9T'
	public HD_SRMActionHistory_component_controller() {
		actionHistoryList = new List<BMCServiceDesk__IncidentHistory__c>();
	
		
	}//public HD_SRMActionHistory_component_controller()

   public List<BMCServiceDesk__IncidentHistory__c> getActionhistory()
   {
	if( RecordId != '' || RecordId != null  )
		{
          actionHistoryList = [Select Name, BMCServiceDesk__userId__c, BMCServiceDesk__note__c, BMCServiceDesk__duration__c, BMCServiceDesk__description__c, BMCServiceDesk__actionId__c, BMCServiceDesk__Reply__c,BMCServiceDesk__date__c,BMCServiceDesk__FKUser__c  From BMCServiceDesk__IncidentHistory__c  where  BMCServiceDesk__FKIncident__c  =:RecordId];
		}//if( RecordId != '' && RecordId != null  )
		return actionHistoryList;
   }//

}