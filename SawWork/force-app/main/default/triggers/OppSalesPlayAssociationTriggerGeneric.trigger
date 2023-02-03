trigger OppSalesPlayAssociationTriggerGeneric 
on Opportunity_Sales_Play_Association__c (after delete, after insert, after undelete, 
							       		  after update, before delete, before insert, 
                                          before update) {
	ApexTriggerHandlerAbstractClass.createHandler('Opportunity_Sales_Play_Association__c');
}