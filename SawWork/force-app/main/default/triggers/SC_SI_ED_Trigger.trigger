/*=====================================================================================================+
Trigger name        :   SC_SI_ED_Trigger
Author              :   Vamsee Surya
Created             :   22-Oct-2020
Purpose             :   External Dependency Trigger. 
Test Class          :   

Last Modified 	Developer   	Purpose             
============= 	==========  	=======
22-Oct-20     	Vamsee Surya  	Initial Development(Jira Ticket# ESESP-4461) 
+=====================================================================================================*/

trigger SC_SI_ED_Trigger on SC_SI_External_Dependency__c (before Insert, before Update) {
    
    // Before Insert
    if(Trigger.isInsert && Trigger.isBefore){
      SC_SI_AllTriggerHelperClass.getJiraInfo(Trigger.New, Trigger.OldMap, true);  
    }
    
    // Before Update
    if(Trigger.isUpdate && Trigger.isBefore){
       SC_SI_AllTriggerHelperClass.getJiraInfo(Trigger.New, Trigger.OldMap, false); 
    }
    
    
    

}