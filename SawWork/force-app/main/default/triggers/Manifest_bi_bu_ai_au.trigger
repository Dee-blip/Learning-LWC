trigger Manifest_bi_bu_ai_au on Manifest_Custom__c (before insert, before update, after insert, after update) {

	if(Trigger.isAfter && Trigger.isUpdate) {
		Map<id, boolean> manifestIdApprovedForProdMap = new Map<id, boolean>();
		Map<id, boolean> dsIdApprovedForProdMap = new Map<id, boolean>();
		List<Id> dsIds = new List<Id>();
		for(Manifest_Custom__c manifest : Trigger.new) {
			dsIds.add(manifest.Deployment_Step__c);
		}

		List<Deployment_Step__c> deploymentSteps = [Select id, Approved_for_Prod__c from Deployment_Step__c where id in :dsIds];
		
		for(Deployment_Step__c ds : deploymentSteps) {
			if(!dsIdApprovedForProdMap.containsKey(ds.id))
				dsIdApprovedForProdMap.put(ds.id, ds.Approved_for_Prod__c);
		}

		for(Manifest_Custom__c manifest : Trigger.new) {
			if(!manifestIdApprovedForProdMap.containsKey(manifest.id))
				manifestIdApprovedForProdMap.put(manifest.id, dsIdApprovedForProdMap.get(manifest.Deployment_Step__c));
		}

		for(Manifest_Custom__c manifest : Trigger.new) {
			if((manifestIdApprovedForProdMap.get(manifest.id) == true) && 
			   ((Trigger.oldMap.get(manifest.id).Component_Type__c != manifest.Component_Type__c) ||
			   (Trigger.oldMap.get(manifest.id).Component_Name__c != manifest.Component_Name__c) ||
			   (Trigger.oldMap.get(manifest.id).Object_or_Folder_Name__c != manifest.Object_or_Folder_Name__c))) {
				manifest.addError('Component details cannot be changed once DS is Approved for Prod');
			}
		}
	}
}