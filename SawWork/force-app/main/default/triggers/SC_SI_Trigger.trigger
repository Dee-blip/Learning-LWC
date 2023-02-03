/*=====================================================================================================+
Trigger name        :   SC_SI_Trigger
Author              :   Vamsee Surya
Created             :   10-Sep-2020
Purpose             :   Service Incident Trigger. 
Test Class          :   SC_SI_AllTestCases_TC

Last Modified   Developer       Purpose             
=============   ==========      =======
10-Sept-20      Vamsee Surya    Initial Development(Jira Ticket# ESESP-3015) 
+=====================================================================================================*/
trigger SC_SI_Trigger on SC_SI_Service_Incident__c (Before Insert, After Insert, Before Update, After Update, Before Delete) {
    
    
    /*............Trigger Design Patten starts here...............*/
    
    // 1. Before Insert
    if(Trigger.isInsert && Trigger.isBefore){
        SC_SI_AllTriggerHelperClass.prePopulateIncidentFields(Trigger.new, null, True);
        SC_SI_AllTriggerHelperClass.updateQueueChangeDatetime(null,Trigger.new,'Create');
    }
    
    // 2. After Insert
    else if(Trigger.isInsert && Trigger.isAfter){
        
        
    }
    
    // 3. Before Update
    else if(Trigger.isUpdate && Trigger.isBefore){
        SC_SI_AllTriggerHelperClass.prePopulateIncidentFields(Trigger.new,trigger.oldmap, False);
        SC_SI_AllTriggerHelperClass.updateQueueChangeDatetime(Trigger.oldMap,Trigger.new,'Update');
    }
    
    // 4. After Update
    else if(Trigger.isUpdate && Trigger.isAfter){
        //Vishnu - Updating new owner on Transition record , if available
        SC_SI_AllTriggerHelperClass.updateLatestTransitionRecordForNewOwner(Trigger.oldMap,Trigger.newMap);
    }
    
    // 5. Before Delete
    else if(Trigger.isDelete && Trigger.isBefore){
        // Restricting users from deleting the Service Incident
        SC_SI_AllTriggerHelperClass.restrictSIDeletion(Trigger.Old);
    }  
    
}