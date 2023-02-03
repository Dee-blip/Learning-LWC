trigger ContractPurchaseOrderTrigger on Merge_Contract_PO__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
	ApexTriggerHandlerAbstractClass.createHandler('Merge_Contract_PO');
    
}