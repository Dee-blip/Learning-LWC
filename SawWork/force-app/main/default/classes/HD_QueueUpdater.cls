global class HD_QueueUpdater implements Schedulable {
global void execute(SchedulableContext sc) 
    {
      System.debug('In execute of HD_QueueUpdater');
      try{
          List<BMCServiceDesk__Incident__c> incidents = new List<BMCServiceDesk__Incident__c>();
          List<BMCServiceDesk__Incident__c> updatedIncidents = new List<BMCServiceDesk__Incident__c>();
          List<BMCServiceDesk__IncidentHistory__c> noteList = new List<BMCServiceDesk__IncidentHistory__c>();
          List<Id> updatedIncidentIds = new List<Id>();
          String actionId;
          String userId;
          String unassignedNote = 'Re-Routing to correct queue to rectify incorrect routing due to run-time error';
          String reassignedNote = 'Re-routing as Triage Team queue is invalid';
          
          //remove hard-coding for "Triage Team. use custom setting"
          //get list of incidents for which routing is incorrect
          if(Test.isRunningTest()){
          incidents = [Select Id, OwnerId, Last_Owner__c, BMCServiceDesk__Status_ID__c, BMCServiceDesk__Category_ID__c, BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c, HD_Owner_user_queue__c, HD_Routing_Settings__c  from BMCServiceDesk__Incident__c where (BMCServiceDesk__Status_ID__c ='UNASSIGNED' OR BMCServiceDesk__Status_ID__c ='REASSIGNED') and HD_Owner_user_queue__c like '%Default Queue%' and (BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c <> 'Q_HELPDESK_TRIAGE' and BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c <> '' and BMCServiceDesk__FKCategory__r.BMCServiceDesk__inactive__c <> true) and BMCServiceDesk__FKCategory__r.RA_Category_Group__c <> 'RESTRICTED PARENT'LIMIT 10 ];
          }
          else{
          incidents = [Select Id, OwnerId, Last_Owner__c, BMCServiceDesk__Status_ID__c, BMCServiceDesk__Category_ID__c, BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c, HD_Owner_user_queue__c, HD_Routing_Settings__c  from BMCServiceDesk__Incident__c where (BMCServiceDesk__Status_ID__c ='UNASSIGNED' OR BMCServiceDesk__Status_ID__c ='REASSIGNED') and HD_Owner_user_queue__c like '%Default Queue%' and (BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c <> 'Q_HELPDESK_TRIAGE' and BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c <> '' and BMCServiceDesk__FKCategory__r.BMCServiceDesk__inactive__c <> true)  and BMCServiceDesk__FKCategory__r.RA_Category_Group__c <> 'RESTRICTED PARENT'];
          }    
      List<BMCServiceDesk__Action__c> actionList = [select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'ESCALATION_NOTE'];
          if(actionList!=null){
              actionId = actionList[0].Id;
          }
          
          for(BMCServiceDesk__Incident__c incident:incidents){
                System.debug('Incident status: '+incident.BMCServiceDesk__Status_ID__c);  
                //adding a transfer note for the incident
                /*
                 * Moving to Batchable
                BMCServiceDesk__IncidentHistory__c transferNote = new BMCServiceDesk__IncidentHistory__c();  
                transferNote.BMCServiceDesk__FKIncident__c=incident.Id;  
              Id ownerid = incident.OwnerId;    
              transferNote.BMCServiceDesk__FKUser__c='005A0000001XPcD';//Id for CRM Ops user
              transferNote.BMCServiceDesk__duration__c='00:10';
              transferNote.BMCServiceDesk__description__c='Transfer Note';
              transferNote.BMCServiceDesk__FKAction__c=actionId;
              transferNote.HD_Action__c='ESCALATION_NOTE';
                if(incident.BMCServiceDesk__Status_ID__c == 'UNASSIGNED'){
                      transferNote.BMCServiceDesk__note__c = unassignedNote;
                }  
                else{
                      transferNote.BMCServiceDesk__note__c = reassignedNote;
                      incident.OwnerId = incident.Last_Owner__c; //updating owner as the last owner for tickets in "Reassigned" status
                }
              noteList.add(transferNote);   
              updatedIncidents.add(incident); 
*/
              updatedIncidentIds.add(incident.Id);
              System.debug('Incident list: '+incidents);
          }//end of for loop
          //insert noteList;
          //update updatedIncidents;
          String q = 'Select Id,OwnerId from BMCServiceDesk__Incident__c where Id in :updatedIncidentIds';
          HD_BatchableQueueUpdater batch=new HD_BatchableQueueUpdater(q,updatedIncidentIds); 
           if(test.isRunningTest())  {
               Database.executeBatch(batch, 10);
           } 
           else{
                Database.executeBatch(batch, 1);
           }
     }//try
     catch(Exception e) {
           System.debug('Error '+e);
     }    
  }//execute
}