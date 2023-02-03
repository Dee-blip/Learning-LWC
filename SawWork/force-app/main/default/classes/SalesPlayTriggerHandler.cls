public without sharing class SalesPlayTriggerHandler extends ApexTriggerHandlerAbstractClass {

	public SalesPlayTriggerHandler(){
	    
    }

    public override void beforeInsertBeforeUpdateTrigger(){
    	List<Sales_Play__c> dsrTriggerNew = (List<Sales_Play__c>)newList;
    	system.debug('Akam Creation');
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, dsrTriggerNew);
    }
    
    public override void afterInsertAfterUpdateTrigger() {
    }

    public override void beforeDeleteBeforeUndeleteTrigger() {
    }

    public override void afterDeleteAfterUndeleteTrigger() {
        
    }
}