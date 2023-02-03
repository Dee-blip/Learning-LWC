/*
Author          : Sheena,Vamsee,Vishnu,Himanshu
Description     : Trigger on SC_SI_Impacted_Account__c
Called From     : 
Test Class      : SC_SI_AllTestCases_TC

Date                Developer                   JIRA #                 Description                                                       
---------------------------------------------------------------------------------------------------------------------------------------------------
14 Aug 2020         Sheena,Vamsee               ESESP-3795             Initial Version
15 Jan 2020			Sheena						ESESP-4768			   Restrict deletion of manually added Impacted Accounts when Case is delinked
---------------------------------------------------------------------------------------------------------------------------------------------------

*/
trigger SC_SI_Impacted_Account_Trigger on SC_SI_Impacted_Account__c (after insert, after update, after delete, before insert, before update, before delete) {
    
    // To Store Incident ID List
    Set<Id> incidentSet = new Set<Id>();  
    
    // Before Insert
    if(Trigger.isInsert && Trigger.isBefore){ 
       
        // Assigning Unique Value
        for(SC_SI_Impacted_Account__c eachImpactedAccount : Trigger.new){
            
            eachImpactedAccount.SC_SI_Unique_field__c = eachImpactedAccount.Service_Incident__c + '-' +
                                                        eachImpactedAccount.Account_Name__c;
        }
    }
    
    // After Insert
    if(Trigger.isInsert && Trigger.isAfter){
       
        for(SC_SI_Impacted_Account__c eachImpactedAccount : Trigger.new){
            incidentSet.add(eachImpactedAccount.Service_Incident__c);
        }
        
        SC_SI_AllTriggerHelperClass.UpdateTierDistribution(incidentSet);
        
    }
    
    // Before Update
    if(Trigger.isUpdate && Trigger.isBefore){
        
        // Assigning Unique Value
        for(SC_SI_Impacted_Account__c eachImpactedAccount : Trigger.new){
            
            // Modifying Unique ID if Account / Service Incident changed
            if( (eachImpactedAccount.Account_Name__c != Trigger.oldmap.get(eachImpactedAccount.Id).Account_Name__c) ||
                (eachImpactedAccount.Service_Incident__c != Trigger.oldmap.get(eachImpactedAccount.Id).Service_Incident__c)
              ){
                eachImpactedAccount.SC_SI_Unique_field__c = eachImpactedAccount.Service_Incident__c + '-' +
                                                        eachImpactedAccount.Account_Name__c;
            }
            // Restrict deletion of manually added Impacted accounts when Case is delinked
            if(eachImpactedAccount.Auto_Created_Record__c != Trigger.oldmap.get(eachImpactedAccount.Id).Auto_Created_Record__c && eachImpactedAccount.Auto_Created_Record__c==True){
                eachImpactedAccount.Auto_Created_Record__c = False;
            }
            
        }
    }
    
    // After Update
    if(Trigger.isUpdate && Trigger.isAfter){
       
        for(SC_SI_Impacted_Account__c eachImpactedAccount : Trigger.new){
            
            if(eachImpactedAccount.Account_Name__c != Trigger.oldmap.get(eachImpactedAccount.Id).Account_Name__c 
               || eachImpactedAccount.From_Proactive_Case__c != Trigger.oldmap.get(eachImpactedAccount.Id).From_Proactive_Case__c){
                incidentSet.add(eachImpactedAccount.Service_Incident__c);
            }
        }
        
        if(incidentSet.size() > 0){
            SC_SI_AllTriggerHelperClass.UpdateTierDistribution(incidentSet);
        }
    }
    
    // Restricting Impacted Account Deletion for Non-IRAPT Users if the Status is not 'Incident Request'
    if(Trigger.isBefore && Trigger.isDelete ){
        if(!SC_SI_Utility.byPassImpAccTrigger){
            SC_SI_AllTriggerHelperClass.restrictObjectDeletion_NonIRAPTUser(Trigger.Old);
            }
        
    }
    
    if(Trigger.isAfter && Trigger.isDelete){
        for(SC_SI_Impacted_Account__c eachImpactedAccount : Trigger.Old){
                incidentSet.add(eachImpactedAccount.Service_Incident__c);
            }
            SC_SI_AllTriggerHelperClass.UpdateTierDistribution(incidentSet);
    }

}