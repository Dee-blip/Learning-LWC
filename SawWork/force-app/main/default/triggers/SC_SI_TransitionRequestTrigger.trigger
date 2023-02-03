/*
Author          : Sheena,Vamsee,Vishnu,Himanshu
Description     : Trigger on SC_SI_Transition_Request__c
Called From		: 
Test Class		: SC_SI_AllTestCases_TC

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
14 Aug 2020       	Vishnu               ESESP-3795             Initial Version
------------------------------------------------------------------------------------------------------------------

*/
trigger SC_SI_TransitionRequestTrigger on SC_SI_Transition_Request__c (Before Update,Before Delete) {
  
    if(Trigger.isUpdate && Trigger.isBefore){

        // Logic to update parent Service Incident's owner to SERVICE_INCIDENT_QUEUE when transition is completed 
        List<SC_SI_Service_Incident__c> toUpdateSIList = new List<SC_SI_Service_Incident__c>();
        
        SC_SI_Service_Incident__c eachSIRec;
        Id serviceIncidentQueueId =  [select Id from Group where Name = 'SERVICE_INCIDENTS_QUEUE' and Type = 'Queue' limit 1].Id;
          
        // Loop for Transition Records
        for(SC_SI_Transition_Request__c itrTransitions : trigger.new){
            
            // Condition for identifying Transition is waking up
            if(itrTransitions.SC_SI_New_Owner__c == trigger.oldMap.get(itrTransitions.Id).SC_SI_New_Owner__c && 
               trigger.oldMap.get(itrTransitions.Id).SC_SI_New_Owner__c == null && 
               itrTransitions.SC_SI_Completed__c == true && 
               trigger.oldMap.get(itrTransitions.Id).SC_SI_Completed__c == false && 
               itrTransitions.SC_SI_Completed_Date__c != null && 
               trigger.oldMap.get(itrTransitions.Id).SC_SI_Completed_Date__c == null){
                
               eachSIRec= new SC_SI_Service_Incident__c(Id=itrTransitions.SC_SI_Service_Incident__c,
                                                       ownerId = serviceIncidentQueueId,Validation_Override__c = true);
                toUpdateSIList.add(eachSIRec);
                
            }
        }

        if(toUpdateSIList.size() > 0){
            Update toUpdateSIList;
        }
        
    } 
    
    if(Trigger.isDelete && Trigger.isBefore){
        for(SC_SI_Transition_Request__c itrTransitions : trigger.old){
            itrTransitions.addError('Transition Records can not be deleted');
        }
    }
}