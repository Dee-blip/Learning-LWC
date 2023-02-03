/***
    PSA_ProjectContractActions
    @author Liz Ichihashi
    @Description : This Class is called from the PSA_ProjectContract_Trigger 
               
                   This class supports PSA customization requirment 4.1.4 - Billing Effective Date trigger
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.   
    Samir Jha             6/27/14       Commented the method to check the Billing effective dates for Project Contracts  
*/
public with sharing class PSA_ProjectContractActions {
    /*Removing for Billing effective Date change
    /* called on after delete of Project Contract
    public static void checkForBillingEffectiveDateUpdateOnProjContDelete(List<Project_Contract__c> oldList) {              
        Set<Id> projectIds = new Set<Id>(); 
        for (Project_Contract__c projContRow : oldList) {
            projectIds.add(projContRow.Project__c);
        }
        PSA_ContractActions.checkProjectContractsForEarliestBillingDate(projectIds);
    }
     */
    /* this method enforces the rule that project contracts may only be deleted   */
    /* using the VF Page from the Project View page.. */
    public static void checkForInvalidDelete(List<Project_Contract__c> contList) {  
        for (Project_Contract__c lineRow : contList) {
            System.debug('lineRow='+lineRow);
            if (!lineRow.Valid_Delete__c) {
                lineRow.addError('Project Contracts only be deleted from the Project view page using the "Add/Remove Project Contract Line Items" button.');
            }   
        }
    }
    
}