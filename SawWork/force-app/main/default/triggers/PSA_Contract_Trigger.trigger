/***
    PSA_Contract_Trigger
    @author Liz Ichihashi
    @Description : This trigger calls methods in the Action class on after update and delete
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.     
    History: Samir Jha -- Date: 6/27/2014 -- Commented the Code to facilitate the CR 2589321 
*/
trigger PSA_Contract_Trigger on Merge_Contract_Header__c (after update, after delete) {
   /* PSA_ContractActions.checkForBillingEffectiveDateUpdate(Trigger.old, Trigger.new);*/
}