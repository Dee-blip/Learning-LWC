trigger ContractProductTrigger on Contract_Product__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
	ApexTriggerHandlerAbstractClass.createHandler('Contract_Product');
    
}