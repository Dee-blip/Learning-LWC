trigger AccSalesPlayAssociationTriggerGeneric on 
Account_Sales_Play_Association__c (after delete, after insert, after undelete, 
							       after update, before delete, before insert, before update) {

	ApexTriggerHandlerAbstractClass.createHandler('Account_Sales_Play_Association__c');

}