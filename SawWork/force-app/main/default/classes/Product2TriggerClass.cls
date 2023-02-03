public without sharing class Product2TriggerClass {
    public static boolean zoffFirstrun = true;
    public static L2Q_ZOFF_Feature__mdt  zoffmdtValue = ZoffUtilClass.getZOFFmdtsetting('ZOFF');  
	public static void zoffopportunityUpdate(List<id> prodIdList) {
        set<id> opportunityIds = new set<id> ();
        String prodName = '';
         Integer batchSize = (Integer)((String.isBlank(String.ValueOf(zoffmdtValue.Product2SyncBatchSize__c))) ? 2 : zoffmdtValue.Product2SyncBatchSize__c);       
		if (zoffFirstrun) {
			for (OpportunityLineItem oli: [Select opportunityId from OpportunityLineItem where product2Id in: prodIdList and opportunity.isClosed = false and Opportunity.RecordType.DeveloperName = 'Akamai_Opportunity' limit 50000]) {
				opportunityIds.add(oli.opportunityId);
            }
           if (!opportunityIds.isEmpty()) {
                L2Q_Product2OpptySyncBatchClass prodsyncInstance = new L2Q_Product2OpptySyncBatchClass(opportunityIds);
                Database.executeBatch(prodsyncInstance,batchSize);
			}
        }
        zoffFirstrun= false;
    }
    

}