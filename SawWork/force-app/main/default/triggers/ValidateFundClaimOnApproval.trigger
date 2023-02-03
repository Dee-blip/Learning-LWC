/**
* Trigger to:
* 1. verify if the fields Performance Attached, Performance Verified and Performance Verified Date are not missing before approving a Fund Claim
* 2. verify if the fields Performance Attached, Performance Verified and Performance Verified Date are not missing before a Fund Claim is 'Paid'
* Date: 02/05/2010
* Author: Shruti Parchure
**/
trigger ValidateFundClaimOnApproval on SFDC_MDF_Claim__c (before update) {
//PRMTriggerClass.FCValidateFundClaimOnApprovalTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
/*
    MDF_Configurations__c mdfConfigurations = Util.getConfigurations();
    Set<Id> verifiedFcIds = new Set<Id>();
    Set<Id> frIds = new Set<Id>();
    Set<Id> submittedFcIds = new Set<Id>();
    Map<Id, List<Attachment>> fundClaimAttachmentMap = new Map<Id, List<Attachment>>();
    
    for(SFDC_MDF_Claim__c fc : trigger.new){
        SFDC_MDF_Claim__c oldFcInfo = trigger.oldMap.get(fc.Id);
        if (oldFcInfo.Status__c != fc.Status__c) {
            if ('Submitted'.equalsIgnoreCase(fc.Status__c)) {
                submittedFcIds.add(fc.Id);
            } else if ('Verified'.equalsIgnoreCase(fc.Status__c)) {
                verifiedFcIds.add(fc.Id);
            }
        }
    }
    
    if (mdfConfigurations != null && mdfConfigurations.Alert_Claim_Without_Attachments__c && submittedFcIds.size() > 0) {
        for(Attachment attachment : [Select a.ParentId, a.Name, a.Id From Attachment a where a.ParentId IN : submittedFcIds ]) {
            if (!fundClaimAttachmentMap.containsKey(attachment.ParentId)) {
                fundClaimAttachmentMap.put(attachment.ParentId, new List<Attachment>());
            }
            fundClaimAttachmentMap.get(attachment.ParentId).add(attachment);
        }

    }
    
    if (verifiedFcIds.size() > 0) {
        for(SFDC_MDF_Claim__c fc :[Select Id, (Select Id, Reserve_Closed__c from Fund_Budget_Allocations__r) from SFDC_MDF_Claim__c where Id in :verifiedFcIds]){
            if (fc.Fund_Budget_Allocations__r.isEmpty()) {
                 fc.addError(Label.No_Alocations_On_Fund_Claim_On_Verified_Status);
            }
        }
    }
    
    for(SFDC_MDF_Claim__c fc : trigger.new){
        String newStatus = fc.Status__c == null ? '' : fc.Status__c;
        String oldStatus = trigger.oldMap.get(fc.Id).Status__c == null ? '' : trigger.oldMap.get(fc.Id).Status__c;
        
        //Verify field before update
        if(trigger.isBefore){
            //Verify fields before a Fund Claim is 'Verified'
            if(!newStatus.equals(oldStatus) && newStatus.equals('Verified')){
                if(!fc.Performance_Attached__c){
                    fc.addError(Label.Performance_Verification_Msg);
                }
                if(!fc.Performance_Verified__c){
                    fc.addError(Label.Performance_Verification_Msg);
                }
                if(fc.Performance_Verified_Date__c == null){
                    fc.addError(Label.Empty_Performance_Date_Msg);
                }
            }
            
            //Verify fields before a Fund Claim is 'Paid'
            if (mdfConfigurations != null && mdfConfigurations.Payment_Details_Validation__c) {
                if(!newStatus.equals(oldStatus) && newStatus.equals('Paid')){
                    String refNum = fc.Paid_Check_Number__c == null ? '' : fc.Paid_Check_Number__c;
                    String settlementMethod = fc.Settlement_Method__c == null ? '' : fc.Settlement_Method__c;
                    if(fc.Claim_Paid_Date__c == null){
                        fc.addError(Label.Empty_Claim_Date_Msg);
                    }
                    if(refNum.equals('')){
                        fc.addError(Label.Empty_Settlement_Reference_Number);
                    }
                    if(fc.Invoice_Date_del__c == null){
                        fc.addError(Label.Empty_Invoice_Date);
                    }
                    if(settlementMethod.equals('')){
                        fc.addError(Label.Empty_Settlement_Method);
                    }
                    
                    frIds.add(fc.Fund_Request__c);
                }
            }
            if (mdfConfigurations != null && mdfConfigurations.Alert_Claim_Without_Attachments__c) {
                if(!newStatus.equals(oldStatus) && newStatus.equals('Submitted')){
                    if (!fundClaimAttachmentMap.containsKey(fc.Id)) {
                        fc.addError(Label.Fund_Claim_Without_Attachments_Msg);
                    }
                }
            }
        }

    }

    List<Budget_Allocation__c> budgetAllocations = new List<Budget_Allocation__c>();
    
    if (! frIds.isEmpty()) { //
        for(Budget_Allocation__c fba : [Select Id, Reserve_Closed__c, Temp_Actual_Spent__c from Budget_Allocation__c where Fund_Request__c In :frIds]) {
            fba.Reserve_Closed__c = true;
            fba.Actual_Spend__c = fba.Temp_Actual_Spent__c;
            budgetAllocations.add(fba);
        }
    }
    if (! budgetAllocations.isEmpty()) {
        update budgetAllocations;
    }
*/
}