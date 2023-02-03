/* Author   :  Jay
   Date     :  July 6 , 2015
   Purpose  : When transition gets updated , we might need to case to different queue based on target shift.
             case transition might get updated from several places and by time based actions.
             So moving code to trigger instead of class.
             Reference CR:3018620
   Test Class : SC_Case_Trgr_EmlServc_Class_TC
Modification History:                                                                            
DATE             DEVELOPER       CR          DESCRIPTION                               
===========      =========       =======     =========== 
10-Mar-2016      Sonia                       Modified the class to remove the static variable and use a list of processed Id's
                                             Static variable was causing issues with Time Trigger processing logic of Salesforce which processes data in chunks but in same context     
27-Apr-2016      Vamsee         3172971      Changed the trigger from before update to before insert, before update and also 
                                             Modified the logic accordingly                                             
09-Jan-2016      Pinkesh        CR 3528581 -  Update CCare queue label prefixes from CC to ATS (Akamai Technical Support)
27-Apr-2017      Pinkesh        JIRA ESESP-542   - Added case transition feature for BOCC
26-Sep-2017      Vamsee         JIRA ESESP-714   - Case transition for DR
24-Aug-2018      Sumanth        JIRA ESESP-1567  - Removing update outside the loop
31-May-2022		 Saiyam			ESESP-5957		Added Case transition feature for BOCC
*/
trigger SC_CaseTransitionCaseUpdate on Case_Transition__c (before update, before insert) {
    //Check for active Org
    Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
    if(environmentSetup.Active_Org__c){
        List<Case> newCaseList = new List<Case>();
        List<Id> currentCaseIdList = new List<id>();
        Map<Id,Case> caseIdCaseMapList = new Map<Id,Case>();
        
        //Lists used to call updateCaseAsync method
        List<Id> lUpdateCaseTransition = new List<Id>();
        List<Id> lUpdateCase = new List<Id>();
        //rca Case Transition Record Type id
        Id rcaTransitionId = Schema.SObjectType.Case_Transition__c.getRecordTypeInfosByName().get('RCA').getRecordTypeId();
        List<Case> caseToUpdateRcaQueue = new List<Case>();
        List<Id> caseIdRCA = new List<Id>();

        //map to store Case RecordType Name and corresponding SC_Case_Transition_RecordType_Map__mdt
        Map<String, SC_Case_Transition_RecordType_Map__mdt> mCTRecordType = new Map<String, SC_Case_Transition_RecordType_Map__mdt>();
        for(SC_Case_Transition_RecordType_Map__mdt ct : [Select Case_RecordType__c, Queue_Id__c, Case_Transition_RecordType__c  from SC_Case_Transition_RecordType_Map__mdt])
        {
            mCTRecordType.put(ct.Case_RecordType__c, ct);
        }
        
            for(Case_transition__c newObject:trigger.new){
                currentCaseIdList.add(newObject.case__c);
            }
            
        	//changes by Saiyam - ESESP-5957 - added Sub_Type__c in query
            caseIdCaseMapList = new Map<ID, Case>([SELECT Id,
                                                        ownerId,
                                                        RecordType.Name, Sub_Type__c
                                                   FROM Case
                                                   WHERE id in :currentCaseIdList]);    
            
            for(Case_transition__c newObject:trigger.new){
                //set flag to avoid recurring checks.
                //SC_CaseTriggerHelperClass.caseTransitionUpdate = true;
                //Check the static list of processed records to prevent recursion
                if(!SC_CaseTriggerHelperClass.lstProcessedTransitionIds.contains(newObject.Id))
                {
                   SC_CaseTriggerHelperClass.lstProcessedTransitionIds.add(newObject.Id);
                   //Case_transition__c oldObject = trigger.oldmap.get(newObject.id);
                   /* when user approves transition , there are 2 use cases.
                   1. use transition now and approve directly
                   2. use shift tracker and post dated assign shift
                   */
                    
                    if(Trigger.isInsert && newObject.Approved_by__c != null ){
                        if(newObject.target_shift__c == 'Transition Now'){
                             case newCaseObject = new case(id=newObject.case__c);
                             newCaseObject.Case_Assignment_Using_Active_Rules__c = true;
                             newCaseObject.has_active_transition__c = true;
                             newCaseObject.Transitioned__c = true;
                             newCaseList.add(newCaseObject);
                            //transition timer started
                            newObject.Start_Date__c = system.now();
                            Case ownerCaseObject = caseIdCaseMapList.get(newObject.case__c);
                            if (ownerCaseObject != null){ 
                                //keep current owner
                                newObject.Previous_Owner__c = ownerCaseObject.OwnerId;
                            } 
                            //changes by Saiyam - ESESP-5957 - BOCC Case Transition
                            String recType = '';
                            if(ownerCaseObject.Sub_Type__c == 'BOCC') {
                                recType = 'BOCC';
                            }
                            else {
                                recType = caseIdCaseMapList.get(newObject.case__c).RecordType.Name;
                            }
                            newObject.preevious_shift_assignment__c  = SC_Utility.getCurrentShiftDetails(mCTRecordType.get(recType).Case_Transition_RecordType__c);
                        }
                        else {
                            //if shift tracker is TRUE , then case should be in Transition queue.
                            //class 
                            if(newObject.Shift_Tracker__c){
                                //changes by Saiyam - ESESP-5957 - BOCC Case Transition
                                Case ownerCaseObject = caseIdCaseMapList.get(newObject.case__c);
                                String recType = '';
                                if(ownerCaseObject.Sub_Type__c == 'BOCC') {
                                    recType = 'BOCC';
                                }
                                else {
                                    recType = caseIdCaseMapList.get(newObject.case__c).RecordType.Name;
                                }
                                newObject.Future_Trigger_Time__c = sc_utility.getShiftDateTime(newObject.Target_Shift__c, mCTRecordType.get(recType).Case_Transition_RecordType__c);
                                //Case ownerCaseObject = caseIdCaseMapList.get(newObject.case__c);
                                if (ownerCaseObject != null){ 
                                    //keep current owner
                                    newObject.Previous_Owner__c = ownerCaseObject.OwnerId;
                                } 
                                newObject.preevious_shift_assignment__c  = SC_Utility.getCurrentShiftDetails(mCTRecordType.get(recType).Case_Transition_RecordType__c);
                                //populate case fields
                                case newCaseObject = new case(id=newObject.case__c);
                                //assign owner to Transition queue
                                if(mCTRecordType.get(recType).Queue_Id__c != null)
                                    newCaseObject.ownerId = mCTRecordType.get(recType).Queue_Id__c;
                                newCaseObject.Case_Assignment_Using_Active_Rules__c = false;
                                newCaseObject.has_active_transition__c = false;
                                newCaseObject.Transitioned__c = true;
                                newCaseObject.Case_In_Transition_Queue__c = true;
                                newCaseList.add(newCaseObject);
                            }
                        }
                            
                    }
                    else if(Trigger.isUpdate && newObject.completed__c == false){
                                /* workflow would have reset this. this happens for time based workflow update.
                               when workflow field update happens , 
                               case will not fire assignment rule due to order of execution  so call future method to update case
                                set few start date fields
                                transition timer started */
                                Case_transition__c oldObject = trigger.oldmap.get(newObject.id);
                                if(oldObject.Shift_Tracker__c != newObject.Shift_Tracker__c){
                                    lUpdateCaseTransition.add(newObject.id);
                                    lUpdateCase.add(newObject.case__c);
                                }     
                     }
                 }
                 if( Trigger.isUpdate && newObject.RecordTypeId == rcaTransitionId 
                    && newObject.completed__c != trigger.oldmap.get(newObject.id).completed__c 
                    && newObject.completed__c && SC_CaseTriggerHelperClass3.rcaTransitionFlag == False ){
                        newObject.Completed_Date__c = DateTime.now();
                        caseIdRCA.add(newObject.Case__c);
                 }
            }
            if(caseIdRCA.size()>0){
                Id queueId = [select Id from Group where Name = 'SERVICE_INCIDENTS_QUEUE'].Id;
                for( Id caseId : caseIdRCA ){
                    Case cs = new Case();
                    cs.Id = caseId;
                    cs.Status = 'Unassigned';
                    cs.OwnerId = queueId; 
                    caseToUpdateRcaQueue.add(cs);
                }
            }
            

             if (newCaseList != null && newCaseList.size() > 0){
                                update newCaseList ;
            } 
            if(caseToUpdateRcaQueue.size()>0){
                update caseToUpdateRcaQueue;
            }


        if(System.isFuture() == false && lUpdateCaseTransition.size()>0 && lUpdateCase.size()>0){
            SC_CaseTransitionControllerV2.updateCaseAsync(lUpdateCaseTransition,lUpdateCase);           
            }
         }
 }