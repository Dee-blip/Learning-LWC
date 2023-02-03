trigger SalesPlayTriggerGeneric on Sales_Play__c (after delete, after insert, after undelete, 
							       				  after update, before delete, before insert,
                                                  before update) {
	ApexTriggerHandlerAbstractClass.createHandler('Sales_Play__c');
}