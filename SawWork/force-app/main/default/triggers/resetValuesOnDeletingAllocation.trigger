trigger resetValuesOnDeletingAllocation on Budget_Allocation__c (after delete) {
	PRMTriggerClass.resetValuesOnDeletingAllocationTrigger(Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.old);
/*	
	
	Map<Id,Decimal> fundRequestIdAndAmt = new Map<Id,Decimal>();
	Map<Id,Decimal> fundClaimIdAndAmt = new Map<Id,Decimal>();
	Decimal amount = null;
	for (Budget_Allocation__c allocation : Trigger.old) {
		if(allocation.Fund_Request__c != null) {
			amount =  allocation.Amount__c;
			if(fundRequestIdAndAmt.containsKey(allocation.Fund_Request__c)) {
			     amount = amount + fundRequestIdAndAmt.get(allocation.Fund_Request__c);
			}
			fundRequestIdAndAmt.put(allocation.Fund_Request__c, amount);
		} else if (allocation.Fund_Claim__c != null) {
			amount =  allocation.Amount__c;
			if(fundClaimIdAndAmt.containsKey(allocation.Fund_Claim__c)) {
			    amount = amount + fundRequestIdAndAmt.get(allocation.Fund_Claim__c);
			}
			fundClaimIdAndAmt.put(allocation.Fund_Claim__c, amount);
		}
	}
	
	if (fundRequestIdAndAmt != null && fundRequestIdAndAmt.size() > 0) {
		List<SFDC_MDF__c> fundRequestList = new List<SFDC_MDF__c>();
		for(SFDC_MDF__c fundRequest : [select id,name,Funding_Approved__c from SFDC_MDF__c Where Id IN : fundRequestIdAndAmt.keySet()]) {
			fundRequest.Funding_Approved__c = fundRequest.Funding_Approved__c - fundRequestIdAndAmt.get(fundRequest.Id);
			fundRequestList.add(fundRequest);
		}
		update fundRequestList;
	}
	if (fundClaimIdAndAmt != null && fundClaimIdAndAmt.size() > 0) {
		List<SFDC_MDF_Claim__c> fundClaimList = new List<SFDC_MDF_Claim__c>();
		for(SFDC_MDF_Claim__c fundClaim : [select id,name,Approved_Amount__c from SFDC_MDF_Claim__c Where Id IN : fundClaimIdAndAmt.keySet()]) {
			fundClaim.Approved_Amount__c = fundClaim.Approved_Amount__c - fundClaimIdAndAmt.get(fundClaim.Id);
			fundClaimList.add(fundClaim);
		}
		update fundClaimList;
	}
*/
}