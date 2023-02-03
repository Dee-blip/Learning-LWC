/*=====================================================================================================+
Trigger name        :   SC_SI_EmailBE_Trigger
Author              :   Vamsee Surya
Created             :   10-Nov-2020
Purpose             :   SC_SI_Business_Excecutive__c Trigger. 
Test Class          :   

Last Modified 	Developer   	Purpose             
============= 	==========  	=======
10-Nov-20     	Vamsee Surya  	Initial Development(Jira Ticket# ESESP-3015) 
+=====================================================================================================*/

trigger SC_SI_EmailBE_Trigger on SC_SI_Business_Excecutive__c (before insert, after insert, before delete) {

	// ensure Trigger.new does not have duplicate entries for same User
	List<Id> userIdList = new List<Id>();
    if(Trigger.isInsert && Trigger.isBefore){
        for(SC_SI_Business_Excecutive__c eachEmailBE : Trigger.new){
        	eachEmailBE.Unique_Id__c = eachEmailBE.User__c;
            userIdList.add(eachEmailBE.User__c);
        }
        
        if(userIdList.size() > 0)
            SC_SI_AllTriggerHelperClass.updateBusinesExecOnUser(userIdList, True);
    }
    
    
    if(Trigger.isDelete && Trigger.isBefore){
        for(SC_SI_Business_Excecutive__c eachEmailBE : Trigger.old)
        	userIdList.add(eachEmailBE.User__c);
        
        if(userIdList.size() > 0)
            SC_SI_AllTriggerHelperClass.updateBusinesExecOnUser(userIdList, False);
    }

}