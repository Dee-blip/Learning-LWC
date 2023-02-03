//Begin SFDC-7368
public  class CapacityAllocationTriggerHandler extends ApexTriggerHandlerAbstractClass {
	public CapacityAllocationTriggerHandler() {}
	public override void beforeInsertBeforeUpdateTrigger() {
        List < Capacity_Allocation__c > caAllocnew = (List < Capacity_Allocation__c > ) newList;
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, caAllocnew);
		
	}
	public override void afterInsertAfterUpdateTrigger() {}
	public override void beforeDeleteBeforeUndeleteTrigger() {}
	public override void afterDeleteAfterUndeleteTrigger() {}
}
//End SFDC-7368