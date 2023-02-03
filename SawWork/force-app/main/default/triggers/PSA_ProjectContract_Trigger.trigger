/***
    PSA_ProjectContract_Trigger
    @author Liz Ichihashi
    @Description : This trigger calls methods in the Action class on before and after delete
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.   
    Samir Jha             6/27/2014     Commented the else block to facilitate the CR 2589321  
*/
trigger PSA_ProjectContract_Trigger on Project_Contract__c (before delete, after delete) {
    if (Trigger.isBefore) {
        PSA_ProjectContractActions.checkForInvalidDelete(trigger.old);
    }  
    /*else {
        PSA_ProjectContractActions.checkForBillingEffectiveDateUpdateOnProjContDelete(trigger.old);
    } */  
}