/***
    PSA_ContractActions
    @author Liz Ichihashi
    @Description : This Class contains methods called from PSA_Contract_Trigger
                   after update and delete.  
                   Check all projects that are related to the contract.  If the 
                   project's billing effective date is after the new contract date,
                   update that project's billing effective date to be that date.
                   
                   This class supports PSA customization requirment 4.1.4 - Billing Effective Date trigger
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.     
*/
public with sharing class PSA_ContractActions {
    
    /* called on after update and delete of Contract */
    /* Need to check to see if the Revision Effective Date has been updated.  If so, */
    /* all associated projects need to be checked to see if the Billing Effective Date is set to the */
    /* earliest of all related Contracts Revision Effective Date */
    public static void checkForBillingEffectiveDateUpdate(List<Merge_Contract_Header__c> oldList, List<Merge_Contract_Header__c> newList) {     
    
        Map<Id, Merge_Contract_Header__c> newMap;
        
        if (newList != null && newList.size() > 0) {
             newMap = new Map<Id, Merge_Contract_Header__c>(newList);
        }    
        Map<Id, pse__Proj__c> projectsToUpdate = new Map<Id, pse__Proj__c>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();

        if (newList == null) {
            /* after delete */
            for (Merge_Contract_Header__c contRow : oldList) {
                contractIds.add(contRow.Id);
            }
        } else {
            /* after update */
            for (Merge_Contract_Header__c contRow : oldList) {
                if (newMap.get(contRow.Id).Revision_Effective_Start_Date__c != contRow.Revision_Effective_Start_Date__c) {
                    contractIds.add(contRow.Id);
                }
            }
        }   
                
        if (contractIds.size() > 0) {
            /* get all projects that are related to these contracts */
            List<Project_Contract__c> tempProjContracts = [Select Id, Project__c, Original_Contract_Id__c,
                                                           Original_Contract_Id__r.Revision_Effective_Start_Date__c 
                                                           From Project_Contract__c 
                                                           Where Original_Contract_Id__c in :contractIds];                                 
            if (tempProjContracts != null && tempProjContracts.size() > 0) {
                for (Project_Contract__c projContRow : tempProjContracts) {
                    projectIds.add(projContRow.Project__c);
                }
            }   
            /* pass list of project Ids into method to set Billing Effective Date */        
            checkProjectContractsForEarliestBillingDate(projectIds);          
        }
    }
    
    public static void checkProjectContractsForEarliestBillingDate(Set<Id> projectIds) {
        /* Get all Projects with Project Contracts for all related to these Contracts. */
        /* Sort Project Contracts so that the earliest one shows up first.  Also, ignore those contracts will a null revision start date */                            
        List<pse__Proj__c> projects = [Select Id, Billing_Effective_Date__c,
                                                   (Select Id, Contract_Detail__c, 
                                                   Contract_Detail__r.Effective_Start_Date__c, Effective_Start_Date__c 
                                                   From Project_Contract_Line_Items__r 
                                                   Where Effective_Start_Date__c <> null
                                                   order by Contract_Detail__r.Effective_Start_Date__c limit 1)
                                       From pse__Proj__c
                                       Where Id in :projectIds
                                       And pse__Stage__c <> 'Closed'];  
        if (projects != null && projects.size() > 0) {
            for (pse__Proj__c projRow : projects) {
                if (projRow.Project_Contract_Line_Items__r.size() > 0) {
                    /* if the project billing effective date is null or not equal to the earliest contract revision eff date, set the billing eff date to this one */
                    if (projRow.Billing_Effective_Date__c == null || projRow.Project_Contract_Line_Items__r[0].Contract_Detail__r.Effective_Start_Date__c <> projRow.Billing_Effective_Date__c) {
                        projRow.Billing_Effective_Date__c = projRow.Project_Contract_Line_Items__r[0].Contract_Detail__r.Effective_Start_Date__c;
                    } else {
                        System.debug('not updating proj bill effective date because it is already the earliest of all cont rev eff dates related to proj.');
                    }
                } else {
                    System.debug('blanking billing effective date because there are no contract related to proj.');
                    projRow.Billing_Effective_Date__c = null;
                } 
            }
            update projects;            
        }               
    }
    
}