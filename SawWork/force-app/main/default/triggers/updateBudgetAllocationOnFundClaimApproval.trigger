/*
* History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N	9/3/11		Made changes to the trigger to create fund allocation records on click of approve button
*/
trigger updateBudgetAllocationOnFundClaimApproval on SFDC_MDF_Claim__c (before update) {
    //PRMTriggerClass.FundClaimTrigger(Trigger.new,Trigger.oldMap,Trigger.newMap);
    /*MDF_Configurations__c mdfConfigurations = Util.getConfigurations();
    SFDC_MDF_Claim__c oldMDFClaim = null;
    //Vinay: creating a temp object
    //PRMAutomateFundClaim tempObj;
    Boolean CreateAllocationSuccess;
    list<SFDC_MDF_Claim__c> FundClaimList = new list<SFDC_MDF_Claim__c>();
    //End of the change
    Map<Id,SFDC_MDF_Claim__c> fundClaimMap  = new Map<Id,SFDC_MDF_Claim__c>();
    Map<Id, List<Attachment>> fundClaimAttachmentMap = new Map<Id, List<Attachment>>();
    Set<Id> fundRequestIdSet = new Set<Id>();
    //Changed by VINAY for testing curency
    for (SFDC_MDF_Claim__c fundClaim : trigger.new) {
        oldMDFClaim = Trigger.oldMap.get(fundClaim.Id);
        system.debug('NEw status'+fundClaim.Status__c +'OLD VALUE '+oldMDFClaim.Status__c);
        if ((fundClaim.Status__c == 'Approved' && oldMDFClaim.Status__c != 'Approved') || (fundClaim.Status__c == 'Submitted' && oldMDFClaim.Status__c != 'Submitted') || (fundClaim.Amount__c != oldMDFClaim.Amount__c) ) {
        	FundClaimList.add(fundClaim);
        }
    }
    Map<Id,Boolean> FcflagMap = new Map<Id,Boolean>();
    if(FundClaimList.size()>0)
    FcflagMap = PRM_opportunity.convertAndCheckFC(FundClaimList);
    for (SFDC_MDF_Claim__c fundClaim : trigger.new) {
        oldMDFClaim = Trigger.oldMap.get(fundClaim.Id);
        if (fundClaim.Status__c == 'Approved' && oldMDFClaim.Status__c != 'Approved') {
        	//Vinay: Adding logic to clone the functions of allocate button call, on click of button
		    Boolean CurrencyValidateSuccess=FcflagMap.get(fundClaim.id);	
		   if(CurrencyValidateSuccess==true){
		    	//tempObj = new PRMAutomateFundClaim(fundClaim);
		    	CreateAllocationSuccess=PRM_opportunity.createBudgetAllocation(fundClaim);//tempObj.saveAllocations();
		    	if(CreateAllocationSuccess==True)
	            {
		            fundClaimMap.put(fundClaim.Id,fundClaim);
		            fundRequestIdSet.add(fundClaim.Fund_Request__c);
	            }
	            else
	            	Continue;
		    }
            //End of the change
        }
    }
    if (fundClaimMap != null && fundClaimMap.size() > 0  && fundRequestIdSet != null && fundRequestIdSet.size() > 0) {
    	
	    List<Budget_Allocation__c>  bugetAllocationList = [Select b.Name, b.Id, b.Fund_Claim__c,b.Approved__c From Budget_Allocation__c b where b.Fund_Claim__c IN :fundClaimMap.keySet() ];
	    Map<Id, List<Budget_Allocation__c>> fundClaimBudgetAllocationMap = new Map<Id, List<Budget_Allocation__c>>();
	    if (bugetAllocationList != null && bugetAllocationList.size() > 0) {
	        for(Budget_Allocation__c budgetAllocation : bugetAllocationList) {
	            if (!fundClaimBudgetAllocationMap.containsKey(budgetAllocation.Fund_Claim__c)) {
	                fundClaimBudgetAllocationMap.put(budgetAllocation.Fund_Claim__c, new List<Budget_Allocation__c>());
	            }
	            fundClaimBudgetAllocationMap.get(budgetAllocation.Fund_Claim__c).add(budgetAllocation);
	        }
	    }
	    if (mdfConfigurations != null && mdfConfigurations.Alert_Claim_Without_Attachments__c) {
	        List<Attachment>  attachmentList = [Select a.ParentId, a.Name, a.Id From Attachment a where a.ParentId IN : fundClaimMap.keySet() ];
	        if (attachmentList != null && attachmentList.size() > 0) {
	            for(Attachment attachment : attachmentList) {
	                if (!fundClaimAttachmentMap.containsKey(attachment.ParentId)) {
	                    fundClaimAttachmentMap.put(attachment.ParentId, new List<Attachment>());
	                }
	                fundClaimAttachmentMap.get(attachment.ParentId).add(attachment);
	            }
	        }
	    }
	    Map<Id,SFDC_MDF__c> fundRequestMap = null;
	    Map<Id, List<Budget_Allocation__c>> fundRequestBudgetAllocationMap = null;
	    if (fundRequestIdSet.size() > 0) {
	        fundRequestMap = new Map<Id,SFDC_MDF__c>([select id, name,Status__c from SFDC_MDF__c where id IN : fundRequestIdSet]);
	        
	        List<Budget_Allocation__c>  fundRequestBudgetAllocationList = [Select b.Name, b.Id, b.Fund_Request__c,b.Approved__c From Budget_Allocation__c b where b.Fund_Request__c IN :fundRequestIdSet ];
	        fundRequestBudgetAllocationMap = new Map<Id, List<Budget_Allocation__c>>();
	        if (fundRequestBudgetAllocationList != null && fundRequestBudgetAllocationList.size() > 0) {
	            for(Budget_Allocation__c budgetAllocation : fundRequestBudgetAllocationList) {
	                if (!fundRequestBudgetAllocationMap.containsKey(budgetAllocation.Fund_Request__c)) {
	                    fundRequestBudgetAllocationMap.put(budgetAllocation.Fund_Request__c, new List<Budget_Allocation__c>());
	                }
	                fundRequestBudgetAllocationMap.get(budgetAllocation.Fund_Request__c).add(budgetAllocation);
	            }
	        }
	    }
	    
	    List<Budget_Allocation__c>  updateBugetAllocationList = new List<Budget_Allocation__c>();
	    boolean hasErrors = false;
	    for (SFDC_MDF_Claim__c fundClaim : fundClaimMap.values()) {
	        hasErrors = false;
	        if (fundRequestMap != null &&fundRequestBudgetAllocationMap != null) {
	            if (fundRequestMap.get(fundClaim.Fund_Request__c).Status__c != 'Approved' || (!fundRequestBudgetAllocationMap.containsKey(fundClaim.Fund_Request__c) || fundRequestBudgetAllocationMap.get(fundClaim.Fund_Request__c).size() == 0)) {
	                trigger.newMap.get(fundClaim.Id).addError('<BR>' +  Label.Fund_Request_has_to_be_approved);
	                hasErrors = true;
	            }
	        }
	        if (mdfConfigurations != null && mdfConfigurations.Alert_FC_or_FR_Without_Allocations__c) {
	            if (!fundClaimBudgetAllocationMap.containsKey(fundClaim.Id)) {
	                trigger.newMap.get(fundClaim.Id).addError('<BR>' +  Label.Fund_Claim_Without_Allocations_Msg);
	                hasErrors = true;
	            }
	        }
	        if (mdfConfigurations != null && mdfConfigurations.Alert_Claim_Without_Attachments__c) {
	            if (!fundClaimAttachmentMap.containsKey(fundClaim.Id)) {
	                trigger.newMap.get(fundClaim.Id).addError('<BR>' +  Label.Fund_Claim_Without_Attachments_Msg);
	                hasErrors = true;
	            }
	        }
	        if (!hasErrors) {
	            for (Budget_Allocation__c budgetAllocation : fundClaimBudgetAllocationMap.get(fundClaim.Id)) {
	                budgetAllocation.Approved__c = true;
	                updateBugetAllocationList.add(budgetAllocation);
	            } 
	        }
	    }
	    if (updateBugetAllocationList != null && updateBugetAllocationList.size() > 0) {
	        update updateBugetAllocationList;
	    }
    }*/
}