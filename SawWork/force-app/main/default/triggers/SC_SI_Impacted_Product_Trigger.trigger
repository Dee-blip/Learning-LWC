/*
Author          : Sheena,Vamsee,Vishnu,Himanshu
Description     : Trigger on SC_SI_Impacted_Product__c
Called From		: 
Test Class		: SC_SI_AllTestCases_TC

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
14 Aug 2020       	Sheena               ESESP-3795             Initial Version 
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_SI_Impacted_Product_Trigger on SC_SI_Impacted_Product__c (before delete) {
    
    // Restricting Impacted Product Deletion for Non-IRAPT Users if the Status is not 'Incident Request'
    if(Trigger.isBefore && Trigger.isDelete ){
        if(!SC_SI_Utility.byPassImpProdTrigger){
            SC_SI_AllTriggerHelperClass.restrictObjectDeletion_NonIRAPTUser(Trigger.Old);
        }
    }
    
}