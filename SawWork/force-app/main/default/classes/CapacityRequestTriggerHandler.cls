public class CapacityRequestTriggerHandler extends ApexTriggerHandlerAbstractClass {
	public CapacityRequestTriggerHandler() {}
	private static boolean firstRunstatuscheck = true;
	public override void beforeInsertBeforeUpdateTrigger() {
		List < Capacity_Request__c > capacityRequestnew = (List < Capacity_Request__c > ) newList;
		ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, capacityRequestnew);
       // Begin SFDC-7368
		List < Id > cprIds = new List < Id > ();
		List<Capacity_Request__c> crListForQueueAssignment = new list<Capacity_Request__c>();
		for (SObject so: newList) {
			Capacity_Request__c crNew = (Capacity_Request__c) so;
			Capacity_Request__c crOld = null;
			crOld = (Trigger.isUpdate) ? (Capacity_Request__c) oldMap.get(crNew.Id) : crOld;
			if (Trigger.isUpdate) {
				if (Util.hasChanges('Status__c', crOld, crNew) && crNew.Status__c == 'Closed - Approved') {
					cprIds.add(crNew.id);
				}
			}
			if (firstRunstatuscheck && !cprIds.isEmpty()) {
				firstRunstatuscheck = false;
				CapacityRequestTriggerClass.updatecpallocationCapacity(cprIds, Trigger.new);
			}
			//SFDC-8279
			if(trigger.isUpdate && util.hasChanges('Status__c', crOld, crNew) && crNew.Status__c == 'Enhanced Review'){
				crListForQueueAssignment.add(crNew);
			}
		}
		// End SFDC-7368
		if(crListForQueueAssignment.size() > 0){
			CapacityRequestTriggerClass.reassignQueue(crListForQueueAssignment);
		}
	}
	public override void afterInsertAfterUpdateTrigger() {
		List <Capacity_Request__c> capacityRequestnew = (List <Capacity_Request__c>) newList;
		List<Capacity_Request__c> crListForEmailNotification = new List<Capacity_Request__c>();
		Set<Id> assigneeUserId = new Set<Id>();
		for(SObject so: newList){
			Capacity_Request__c crNew = (Capacity_Request__c) so;
			Capacity_Request__c crOld = (Trigger.isUpdate) ? (Capacity_Request__c) oldMap.get(crNew.Id) : null;
			if(Trigger.isUpdate && util.hasChanges('Assigned_To__c', crOld, crNew)){
				crListForEmailNotification.add(crNew);
				assigneeUserId.add(crNew.Assigned_To__c);
			}
		}
		if(crListForEmailNotification.size() > 0){
			CapacityRequestTriggerClass.verifyUserAndSendEmail(crListForEmailNotification, assigneeUserId);
		}
	}
	public override void beforeDeleteBeforeUndeleteTrigger() {}
	public override void afterDeleteAfterUndeleteTrigger() {}
}