trigger CPQ_ProductApprovalTrigger on Product_Approvals__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    CPQ_TriggerDispatcher.run(new CPQ_ProductApprovalTriggerHandler());
}