/* Notify assigned staff whenever client replies to the mail received via “Email Conversation” feature.
    - The status of the associated Incident should change to “Customer responded”.
    Changed by janantha on 01/04/2013 to update the status for only Helpdesk
    
    with CR 2769690  by Kartikeya - 
      The code has been optimized with removing 0th reference to matching the map set.
      Conditioning has been changed with better readability.
      Removed extra SOQL with map set.
    * Modification Log ===============================================================
    * Date 				        Author 					  Modification
    * Sept 15th, 2021     Aneesh Budnar     PRTORES-2275 - Added tests for handling OOO changes
*/

trigger HD_UpdateStatusToCustomerResponded on BMCServiceDesk__IncidentHistory__c (before insert, before update, after insert, after update)
{
    if(Test.isRunningTest() && ManagedPkgErrorClass.isFromManagedPackage)
        return ;
        
    //get all the incident groups from custom settings
    HD_EIS_INCIDENT_GROUP__c HELPDESK_HARDWARE = HD_EIS_INCIDENT_GROUP__c.getInstance('HELPDESK_HARDWARE');
    HD_EIS_INCIDENT_GROUP__c HELPDESK_MALWARE = HD_EIS_INCIDENT_GROUP__c.getInstance('HELPDESK_MALWARE');
    HD_EIS_INCIDENT_GROUP__c HELPDESK_TRIAGE = HD_EIS_INCIDENT_GROUP__c.getInstance('HELPDESK_TRIAGE');
    HD_EIS_INCIDENT_GROUP__c ITOC = HD_EIS_INCIDENT_GROUP__c.getInstance('ITOC');
    HD_EIS_INCIDENT_GROUP__c ITOC_Alerts = HD_EIS_INCIDENT_GROUP__c.getInstance('ITOC_Alerts');
        
   
     // allRecords: All records of Incident History object.
    List<BMCServiceDesk__IncidentHistory__c> allRecords = trigger.new;
    
    //Start CR 2769690  by Kartikeya
    List<Id> incidentIds = new  List<Id>();
    for( BMCServiceDesk__IncidentHistory__c incidentHistory : trigger.new){
      incidentIds.add(incidentHistory.BMCServiceDesk__FKIncident__c);
    }
    
     Map<Id,BMCServiceDesk__Incident__c > incidentMap = new Map<Id,BMCServiceDesk__Incident__c>() ;
     for(BMCServiceDesk__Incident__c incident : [ Select Id,RecordType.Name,Owner.Email, BMCServiceDesk__clientEmail__c,HD_IncidentGroup__c,BMCServiceDesk__Status_ID__c, BMCServiceDesk__FKStatus__c,
      Name,BMCServiceDesk__shortDescription__c,BMCServiceDesk__Category_ID__c,BMCServiceDesk__inc_console_detail_link__c,dl_SysAdmin__c,HD_Notify_DL_EIS_on_Notes_Update__c,
      BMCServiceDesk__incidentDescription__c,BMCServiceDesk__incidentResolution__c,Last_Updated_Date_Time__c
      From BMCServiceDesk__Incident__c  Where Id IN :incidentIds]){
        
        incidentMap.put(incident.id,incident);
     }
    
    // End CR 2769690  by Kartikeya     
        
        

   if(Trigger.isBefore){
   
   
    
    // StatusID: stores the ID of status "Customer Responded"
    List<BMCServiceDesk__Status__c> StatusID;
        
    StatusID = [select id from BMCServiceDesk__Status__c where Name='CUSTOMER RESPONDED' Limit 1];
    
    //query to get the incident object based on the matching incident ID and get the Client Email Address
    //CR 2407602 - "Customer Responded" status enhancement: added the query to get the incident ID and client email ID : by srramakr on 23/12/2013
  
    //BMCServiceDesk__Incident__c incidentObj =   [ Select b.Id, b.BMCServiceDesk__clientEmail__c,b.HD_IncidentGroup__c From BMCServiceDesk__Incident__c b Where Id =: Trigger.new[0].BMCServiceDesk__FKIncident__c ];
    //string incidentGroup = incidentObj.HD_IncidentGroup__c;
    //String email_From = 'From:'+incidentObj.BMCServiceDesk__clientEmail__c;
 
     
    
    List<BMCServiceDesk__Incident__c> incidentUpdateList =  new   List<BMCServiceDesk__Incident__c> ();
    
    if(StatusID.size()!=0)
    {
        for(BMCServiceDesk__IncidentHistory__c iterator: allRecords)
        {      
            BMCServiceDesk__Incident__c incident =  incidentMap.get(iterator.BMCServiceDesk__FKIncident__c);
            string incidentGroup = incident.HD_IncidentGroup__c;
            String emailFrom = 'From: '+incident.BMCServiceDesk__clientEmail__c;   
            String ownerEmail = 'From: '+incident.Owner.Email;
            //CR 2769690  by Kartikeya  Added condition for != closed -  Old code has been refactored with conditioning
            //PRTORES-627 by Nisarga Added condition !String.valueOf(Iterator.BMCServiceDesk__note__c).contains(ownerEmail) - For not changing status to customer responded when owner sends the mail.
            //PRTORES-
            if(incident.RecordType.Name != 'Service Incident'  && 
               incident.BMCServiceDesk__Status_ID__c != 'CLOSED' && 
               iterator.BMCServiceDesk__actionId__c == 'Email Received' && 
               !String.valueOf(Iterator.BMCServiceDesk__note__c).contains(ownerEmail)){
                   Boolean containsOOOPattern = false;
                   for(HD_Incident_Settings__c oooSetting : HD_Incident_Settings__c.getAll().values()) {
                       if(oooSetting.Name.contains('OOO_Subject_Pattern') && 
                          String.valueOf(iterator.BMCServiceDesk__note__c).contains(oooSetting.Value__c)) {
                              containsOOOPattern = true;
                              break;
                          }
                   }
                   
                   if(!containsOOOPattern) {
                       //start of change by janantha 01/04/2013   
                       //CR 2407602 - "Customer Responded" status enhancement: added the condition  to validate the client email ID : by srramakr on 23/12/2013
                       if(incidentGroup != NULL && 
                          (incidentGroup == HELPDESK_HARDWARE.IncidentGroup__c || 
                           incidentGroup == HELPDESK_MALWARE.IncidentGroup__c || 
                           incidentGroup == ITOC.IncidentGroup__c || 
                           incidentGroup == HELPDESK_TRIAGE.IncidentGroup__c || 
                           incidentGroup == ITOC_Alerts.IncidentGroup__c))
                       {   
                           //CR 2769690  by Kartikeya - condition has been changed with optimization.
                           if( String.valueOf(Iterator.BMCServiceDesk__note__c).contains(emailFrom)  )
                           {
                               //end of change by janantha 01/04/2013
                               //selectedRecords.add(iterator.BMCServiceDesk__FKIncident__c); 
                               incident.BMCServiceDesk__FKStatus__c = StatusID[0].id;
                               incidentUpdateList.add(incident);
                           }
                       }
                       else
                       {
                           
                           //end of change by janantha 01/04/2013
                           //selectedRecords.add(iterator.BMCServiceDesk__FKIncident__c); 
                           incident.BMCServiceDesk__FKStatus__c = StatusID[0].id;
                           incidentUpdateList.add(incident);
                           
                       }
                   }
                   System.debug('Client Note Content -----------> '+Iterator.BMCServiceDesk__note__c );
               }
            
        }
        
    
         //CR 2769690  by Kartikeya - removed SOQL call for selected incident obj
         if(incidentUpdateList.size() > 0)
           update incidentUpdateList;
         }      
         
      } //IsBefore
      
      if(Trigger.isAfter){
        HD_Incident_Settings__c missingActionsValues = HD_Incident_Settings__c.getInstance('Missing_Actions_Update');
        Set<String> missingActions = new Set<String>(missingActionsValues.value__c.split(','));

        List<BMCServiceDesk__Incident__c> inciUpdateList =  new   List<BMCServiceDesk__Incident__c> ();
        for(BMCServiceDesk__IncidentHistory__c iterator: allRecords)
        {  
   
           BMCServiceDesk__Incident__c inci = incidentMap.get(iterator.BMCServiceDesk__FKIncident__c);
           if(( iterator.BMCServiceDesk__actionId__c == 'Notes' || iterator.BMCServiceDesk__actionId__c == 'Client Note') && inci != null && inci.HD_Notify_DL_EIS_on_Notes_Update__c == true){
             
              Messaging.Singleemailmessage  mail = HD_IncidentUtils.NoteUpdatedEmail('Added with Action Note',iterator.BMCServiceDesk__note__c,iterator.LastModifiedDate, inci);
              Messaging.sendEmail(new Messaging.Singleemailmessage[]{mail}); 
           }
           if(missingActions.contains(iterator.BMCServiceDesk__actionId__c)){
            inci.Last_Updated_Date_Time__c = System.now();
            inciUpdateList.add(inci);
          }
        }
        if(inciUpdateList.size() > 0){
           update inciUpdateList;
         }
      
      }//isAfter      
}