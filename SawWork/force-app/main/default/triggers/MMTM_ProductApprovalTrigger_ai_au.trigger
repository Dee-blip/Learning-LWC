/* Owner - Shiv Gautam (Momentum)
   */
trigger MMTM_ProductApprovalTrigger_ai_au on Product_Approvals__c (after insert, after update) {
   
   if(Trigger.isUpdate){
       Set<Id> oppIds = new Set<Id>();
       Set<Id> oppIdsToReject = new Set<Id>();
       Set<String> approvalIdsForMomentum = new Set<String>();
       List<Product_Approvals__c> statusChangedApprovalsMomentum = new List<Product_Approvals__c>();

    for(Product_Approvals__c prod_approval:Trigger.new){
        if(prod_approval.Status__c!= Trigger.oldMap.get(prod_approval.Id).Status__c && prod_approval.Status__c=='APPROVED'){
            approvalIdsForMomentum.add(prod_approval.Id);
            statusChangedApprovalsMomentum.add(prod_approval);
            oppIds.add(prod_approval.Opportunity__c);
        }
        else if(prod_approval.Status__c!= Trigger.oldMap.get(prod_approval.Id).Status__c && prod_approval.Status__c=='REJECTED')
        {
            oppIdsToReject.add(prod_approval.Opportunity__c);
        }
    }

    List<Momentum_Order_Product_Approval__c> momOrderProdApprs = [select id, momentum_order_id__c, workflow_id__c, approval_is_draftable__c, approval_is_lockable__c, approval_status__c, Product_Approval__c from Momentum_Order_Product_Approval__c where Product_Approval__c in :approvalIdsForMomentum]; 
    List<Momentum_Order_Product_Approval__c> momOrderProdApprsUpdated = new List<Momentum_Order_Product_Approval__c>();
    for(Momentum_Order_Product_Approval__c mopa : momOrderProdApprs)
    {
        for(Product_Approvals__c pa : statusChangedApprovalsMomentum)
        {
            if(pa.Id == mopa.Product_Approval__c && pa.Workflow_ID__c == mopa.workflow_id__c && pa.Order_Id__c == mopa.momentum_order_id__c){
                mopa.approval_is_draftable__c = true;
                mopa.approval_is_lockable__c = true;
                mopa.approval_status__c = 'APPROVED';
                momOrderProdApprsUpdated.add(mopa);
            }
        }
    }
     
     if(momOrderProdApprsUpdated.size() >0)
         update momOrderProdApprsUpdated;
   }
}