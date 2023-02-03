trigger Channel_Hierarchy on Channel_Hierarchy_Map__c (before insert, before update) {
	if(Trigger.isBefore)
		for (Channel_Hierarchy_Map__c so : Trigger.new) {
			//friends remind friends to bulkify
			if(trigger.isInsert||(trigger.isUpdate && Util.hasChanges('Name',trigger.oldMap.get(so.id),so))){
				so.Channel_Name_Unique__c = so.Name;
			}
		}
}