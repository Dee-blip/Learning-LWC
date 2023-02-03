public with sharing class HD_service_req_Incident_link_Controller {
//Service request ID     
    public static Id SRMID{get;set;}
    public static String  pageblocktitle{get;set;} 
    public static String  recordLimit{get;set;}
        
//creating a query

private ApexPages.StandardSetController service_request_incident_link_setctrl{
        get{ 
   if(service_request_incident_link_setctrl == null){  service_request_incident_link_setctrl = new ApexPages.StandardSetController(Database.getQueryLocator([Select id, name, Service_Request_Incident_Link__c, Service_Request_name__c, Service_Request__c, Linked_Incident_name__c, Created_By_Name__c, CreatedById from HD_Service_Request_Incident_Link__c where Service_Request__c =:SRMID])); }
        return service_request_incident_link_setctrl;
    }
    set;}    
    
//getting list related list
public List<HD_Service_Request_Incident_Link__c> getSrmincidentlink()
{
     system.debug('--->'+service_request_incident_link_setctrl.getResultSize());
    List<HD_Service_Request_Incident_Link__c> srmIncidentLink = new  List<HD_Service_Request_Incident_Link__c>();
    if(service_request_incident_link_setctrl.getResultSize() > 0 )
    {
        srmIncidentLink = (List<HD_Service_Request_Incident_Link__c>) service_request_incident_link_setctrl.getRecords();
    }
    System.debug('--->'+srmIncidentLink);
    return srmIncidentLink; 
}//

}//END OF CLASS