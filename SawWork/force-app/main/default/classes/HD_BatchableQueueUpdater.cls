/*
* File Name: HD_BatchableQueueUpdater
* Description : 
* @author : 
* Modification Log ===============================================================
* Date              Author          Modification
* Jan 20th, 2020    Arihant Jain    PRTORES-1593 - Create an App to host P2R Dev tools
* Aug 08th, 2020    Aneesh Budnar   PRTORES-1810 - Code scanner fixes
* Nov 29th, 2021    Aneesh Budnar   PRTORES-2358 - HD Code Scanner 1 fixes
*/
global class HD_BatchableQueueUpdater implements Database.Batchable<SObject> {

    global final String query;
    global final List<Id> updatedIncidentIds;
    global final String actionId;
    Set<Id> transferNoteMap = new Set<ID>();
    //count(id),BMCServiceDesk__FKIncident__c from BMCServiceDesk__IncidentHistory__c where BMCServiceDesk__FKIncident__c in ('a5UG0000000HRgLMAW', 'a5UG00000004KieMAE')  and BMCServiceDesk__actionId__c = 'Transfer Note' group by BMCServiceDesk__FKIncident__c

    global HD_BatchableQueueUpdater(String q, List<Id> incidentIds){
        System.debug('In batchable constructor');
        System.debug('Constructor incidentIds: '+incidentIds);
         List<BMCServiceDesk__Action__c> actionList = [select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'ESCALATION_NOTE'];
          if(actionList!=null){
              System.debug('Action not null');
              actionId = actionList[0].Id;
          }
        query=q;
        System.debug('Query: '+query);
        updatedIncidentIds=incidentIds;
        AggregateResult[] incHistList = [ select count(id),BMCServiceDesk__FKIncident__c from
                                                                BMCServiceDesk__IncidentHistory__c where
                                                                BMCServiceDesk__FKIncident__c in :incidentIds  and
                                                                BMCServiceDesk__actionId__c = 'Transfer Note' group by
                                                                BMCServiceDesk__FKIncident__c limit 5000];
        for(AggregateResult incHist : incHistList){
            transferNoteMap.add((ID)incHist.get('BMCServiceDesk__FKIncident__c'));
        }


        System.debug('updatedIncidentIds: '+updatedIncidentIds);
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
      System.debug('In Batchable start');
      System.debug('Query: '+query);
      System.debug('updatedIncidentIds: '+updatedIncidentIds);
      return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<BMCServiceDesk__Incident__c> scope){
        System.debug('In execute');


        List<BMCServiceDesk__IncidentHistory__c> noteList = new List<BMCServiceDesk__IncidentHistory__c>();
        User crmOpsUser = [SELECT Id FROM User WHERE UserName LIKE '%eae-ops@akamai.com%'];
        for(BMCServiceDesk__Incident__c inc:scope){
            inc.HD_OwnerLocked__c = false;
            Id ownerid = inc.OwnerId;

            if(transferNoteMap.contains(inc.Id)){
                continue;
            }

            BMCServiceDesk__IncidentHistory__c transferNote = new BMCServiceDesk__IncidentHistory__c();
            transferNote.BMCServiceDesk__FKIncident__c=inc.Id;

            //System.debug('category: '+inc.BMCSErviceDesk__FKCategory__r.Name);
            if(crmOpsUser != null) {
                transferNote.BMCServiceDesk__FKUser__c = crmOpsUser.Id; //Id for CRM Ops user
            }
            transferNote.BMCServiceDesk__duration__c='00:10';
            transferNote.BMCServiceDesk__description__c='Transfer Note';
            transferNote.BMCServiceDesk__FKAction__c=actionId;
            transferNote.HD_Action__c='ESCALATION_NOTE';
            transferNote.BMCServiceDesk__note__c='Re-Routing to correct queue to rectify incorrect routing due to run-time error';
            noteList.add(transferNote);
        }
		      Database.update(scope, false);

          Database.insert(noteList,false);



    }

    global void finish( Database.BatchableContext BC )
    {
 		System.debug('In Batchable Finish');
    }

}