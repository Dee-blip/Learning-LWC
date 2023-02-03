/* Utility Class to hold methods/logics BMCServiceDesk__Incident__c Trigger 
   Created by Kartikeya
*/   


public class  HD_IncidentUtils{

  public Static Boolean SKIP_TRIGEER = false;

  public List<BMCServiceDesk__Incident__c> incidents = new List<BMCServiceDesk__Incident__c>();
 
  public HD_IncidentUtils(List<BMCServiceDesk__Incident__c> incident_list)
  {
  
    incidents = incident_list;
  }
  
  
 //Kartikeya - CR 2728794 - Request Mgmt - Cascading Parent fields to child
  @future(callout=true)
  public static void insertIncidentHistory( Map<Id,String> incidentParentName, Id closedStatusId){
  
      List<BMCServiceDesk__IncidentHistory__c> incidentHistoryList = new List<BMCServiceDesk__IncidentHistory__c>();
      
      List< BMCServiceDesk__Action__c> actionNote = [SELECT ID FROM BMCServiceDesk__Action__c WHERE Name = 'Notes' and BMCServiceDesk__appliesToIncident__c = true and BMCServiceDesk__inactive__c != true];
       
      if(actionNote.size() >  0){
          for( BMCServiceDesk__Incident__c incident :
           [SELECT ID,BMCServiceDesk__FKStatus__c FROM BMCServiceDesk__Incident__c where BMCServiceDesk__FKStatus__c != :closedStatusId and ID IN :incidentParentName.keyset()])
          {
 
            String parent_name = incidentParentName.get(incident.id);
            BMCServiceDesk__IncidentHistory__c incidentHistory = new BMCServiceDesk__IncidentHistory__c();
            incidentHistory.BMCServiceDesk__FKAction__c = actionNote[0].id;
            incidentHistory.BMCServiceDesk__FKIncident__c = incident.id;
            incidentHistory.BMCServiceDesk__duration__c = '00:10';
            incidentHistory.BMCServiceDesk__description__c = 'Note :Linked to Parent Incident #'+parent_name;
            incidentHistory.BMCServiceDesk__note__c = 'Incident has been linked Parent Incident #'+parent_name;
            incidentHistoryList.add(incidentHistory);
      
          }
      
    
          if(incidentHistoryList.size() > 0){
            insert  incidentHistoryList;
          }
      
      }//actionNote size()
      
        
  }// End of method insertIncidentHistory


  @future(callout=true)
  public static void updatechildIncident( List<Id> incident_ids,Id statusCLOSED_Id)
  {

      List<BMCServiceDesk__Incident__c> child_incidents = new List<BMCServiceDesk__Incident__c>();

      child_incidents = [select Id,BMCServiceDesk__FKStatus__c,HD_Ticket_Priority__c,BMCServiceDesk__FKIncident__c,BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKIncident__r.HD_Ticket_Priority__c from BMCServiceDesk__Incident__c where 
      BMCServiceDesk__FKIncident__c IN :incident_ids and BMCServiceDesk__FKStatus__c != :statusCLOSED_Id ];

     for(BMCServiceDesk__Incident__c incident: child_incidents )
     {
       System.debug(incident.BMCServiceDesk__FKStatus__c);

       incident.BMCServiceDesk__FKStatus__c = incident.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKStatus__c;
       incident.HD_Ticket_Priority__c = incident.BMCServiceDesk__FKIncident__r.HD_Ticket_Priority__c;
            

     }//for(BMCServiceDesk__Incident__c incident: child_incidents )

     update child_incidents;

  }//END public static void updatechildIncident()
 
     public static Messaging.Singleemailmessage NoteUpdatedEmail(String note_title, String note_body, DateTime modified_date, BMCServiceDesk__Incident__c inci ){
     
          Messaging.Singleemailmessage  mail = new Messaging.Singleemailmessage();
                  String[] toAddresses = new List<String>();
                  String ebody = '';
                  toAddresses.add(inci.dl_SysAdmin__c);
                  mail.setToAddresses(toAddresses);
                  
                  mail.setSubject('Service Based Incident  #(Ref:IN:'+inci.name+') updated with a New Note');
                  ebody = 'Incident #'+inci.Name+' has been updated with a New Note as listed below';
                  ebody += '<br><br>';
                  ebody += 'Note Title: '+note_title;
                  ebody += '<br><br>Updated Date Time: '+modified_date;
                  ebody += '<br><br>Note: '+note_body;
                  ebody += '<br><h5>Incident Details:-</h5>';
                  ebody += 'Category: '+inci.BMCServiceDesk__Category_ID__c;
                  ebody += '<br>Short Description:'+ inci.BMCServiceDesk__shortDescription__c;
                  ebody += '<br>Description:'+ inci.BMCServiceDesk__incidentDescription__c;
                  ebody += '<br>Resolution:'+ inci.BMCServiceDesk__incidentResolution__c;
                  ebody += '<br><br>For further details, please click on the below links:';
                  
                  String recordLink = URL.getSalesforceBaseUrl().toExternalForm()+'/'+inci.Id ;
                  ebody += '<br><br>Link to Incident: '+recordLink;
                  ebody += '<br>Incident Console Link: '+ URL.getSalesforceBaseUrl().toExternalForm()+'/apex/BMCServiceDesk__RemedyforceConsole?record_id='+inci.Id+'&objectName=Incident__c';
                  ebody += '<br><br>';
                  mail.setHtmlBody(ebody);
                  
                  return mail;
     
     
     
     
     }

}