/*
* History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N   9/3/11      Made changes to the trigger to create fund allocation records on click of approve button
*
*/
trigger updateBudgetAllocationOnFundRequestApproval on SFDC_MDF__c (before update) {
PRMTriggerClass.FRUpdateBudgetAllocationOnFundRequestApprovalTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
/*
    MDF_Configurations__c mdfConfigurations = Util.getConfigurations();
    SFDC_MDF__c oldMDFRequest = null;
    //Vinay: creating a temp object
    //PRMAutomatefundRequest tempObj;
    Boolean CreateAllocationSuccess;
    //End of the change
    Map<Id,SFDC_MDF__c> fundRequestMap  = new Map<Id,SFDC_MDF__c>();
    Set<Id> accountIdSet = new Set<Id>();
    for (SFDC_MDF__c fundRequest : trigger.new) {
        oldMDFRequest = Trigger.oldMap.get(fundRequest.Id);
        if (fundRequest.Status__c == 'Approved' && oldMDFRequest.Status__c != 'Approved') {
            //Vinay: Adding logic to clone the functions of allocate button call, on click of button
            //tempObj = new PRMAutomateFundRequest(fundRequest);
            CreateAllocationSuccess=PRM_opportunity.createBudgetAllocation(fundRequest);//tempObj.validateAllocations();
            if(CreateAllocationSuccess==True)
            {
                fundRequestMap.put(fundRequest.Id,fundRequest);
                if (fundRequest.Account__c != null) {
                    accountIdSet.add(fundRequest.Account__c);
                }
                if (fundRequest.Funding_Approved__c == null) {
                    fundRequest.Funding_Approved__c = fundRequest.Amount_In_Corporate_Currency__c;
                }
            }
            else
                Continue;
            //End of the change
        }
    }
    if (fundRequestMap != null && fundRequestMap.size() > 0) {
        List<Budget_Allocation__c>  bugetAllocationList = [Select b.Name, b.Id, b.Fund_Request__c,b.Approved__c From Budget_Allocation__c b where b.Fund_Request__c IN :fundRequestMap.keySet() ];
        Map<Id, List<Budget_Allocation__c>> fundRequestBudgetAllocationMap = new Map<Id, List<Budget_Allocation__c>>();
        if (bugetAllocationList != null && bugetAllocationList.size() > 0) {
            for(Budget_Allocation__c budgetAllocation : bugetAllocationList) {
                if (!fundRequestBudgetAllocationMap.containsKey(budgetAllocation.Fund_Request__c)) {
                    fundRequestBudgetAllocationMap.put(budgetAllocation.Fund_Request__c, new List<Budget_Allocation__c>());
                }
                fundRequestBudgetAllocationMap.get(budgetAllocation.Fund_Request__c).add(budgetAllocation);
            }
        }
        
        List<Budget_Allocation__c>  updateBugetAllocationList = new List<Budget_Allocation__c>();
        Map<Id,SObject> accountMap = null;
        if(mdfConfigurations != null) {
            if(mdfConfigurations.Account_Region_Field_Name__c != null && accountIdSet.size() > 0) { 
                accountMap = Util.getAccountRegions(accountIdSet,mdfConfigurations);
            }
        }
        Boolean validateAllocations = true;
        for (SFDC_MDF__c fundRequest : fundRequestMap.values()) {
            validateAllocations = true;
            if (!fundRequestBudgetAllocationMap.containsKey(fundRequest.Id)) {
                if(mdfConfigurations.Account_Region_Field_Name__c != null && mdfConfigurations.Regions_Without_Fund_Allocations__c != null) {
                    if (accountMap != null && accountMap.containsKey(fundRequest.Account__c)) {
                        validateAllocations = Util.checkValidationFundRequired(accountMap.get(fundRequest.Account__c), mdfConfigurations);
                    }
                }
                if (mdfConfigurations != null && mdfConfigurations.Alert_FC_or_FR_Without_Allocations__c && validateAllocations) {
                    trigger.newMap.get(fundRequest.Id).addError('<BR>' +  Label.Fund_Request_Without_Allocations_Msg);
                }
            } else {
                for (Budget_Allocation__c budgetAllocation : fundRequestBudgetAllocationMap.get(fundRequest.Id)) {
                    budgetAllocation.Approved__c = true;
                    updateBugetAllocationList.add(budgetAllocation);
                } 
            }
        }
        
        if (updateBugetAllocationList != null && updateBugetAllocationList.size() > 0) {
            update updateBugetAllocationList;
        }
    }
    */
}