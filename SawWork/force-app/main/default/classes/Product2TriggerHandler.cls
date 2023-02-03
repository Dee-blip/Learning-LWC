public without sharing class Product2TriggerHandler extends ApexTriggerHandlerAbstractClass {
    public static L2Q_ZOFF_Feature__mdt  zoffmdtValue = ZoffUtilClass.getZOFFmdtsetting('ZOFF');  //Rajesh - SFDC-7061
	public override void beforeInsertBeforeUpdateTrigger() {}
	public override void afterInsertAfterUpdateTrigger() {
		//Begin Interface variable decalartion
		List<Product2 > product2TriggerNew = (List<Product2 > ) newList;
		List<Product2 > product2TriggerOld = (List<Product2 > ) oldList;
		Map<Id, Product2 > product2TriggerNewMap = (Map<Id, Product2 > ) newMap;
		Map<Id, Product2 > product2TriggerOldMap = (Map<Id, Product2 > ) oldMap;
		//End Interface variable decalartion
		List<Id> zoffChangelist = new List<Id>();
		for (SObject so: newList) {
			Product2 prodNew = (Product2) so;
			Product2 prodOld = null;
			if (Trigger.isUpdate) {
				prodOld = (Product2) oldMap.get(prodNew.Id);
			}
            if (Trigger.isUpdate && Util.hasChanges('Zoff_Product__c', prodOld, prodNew)  && zoffmdtValue.WebProduct2List__c.split(',').contains(prodNew.AKAM_Product_ID__c) && zoffmdtValue.Product2OppotySyncAllowed__c  && zoffmdtValue.Feature_Enabled__c
                ) {
				zoffChangelist.add(so.id);
			}
        }
		if (!zoffChangelist.isEmpty()) {
            Product2TriggerClass.zoffopportunityUpdate(zoffChangelist);
		}
	}
	public override void beforeDeleteBeforeUndeleteTrigger() {}
	public override void afterDeleteAfterUndeleteTrigger() {

	}
}