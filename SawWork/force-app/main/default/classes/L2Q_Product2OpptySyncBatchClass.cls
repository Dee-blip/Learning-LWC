global class L2Q_Product2OpptySyncBatchClass implements Database.Batchable<sObject> , Database.Stateful {
	public set<id> opptyList;
	global L2Q_Product2OpptySyncBatchClass(set<id> listOpp) {
		this.opptyList = listOpp;
	}
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([Select id from opportunity where id in: opptyList]);
	}
	global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
		set<Id> ids = new set<id> ();
		for (Opportunity op: scope) {
			ids.add(op.id);
		}
		if (!ids.isEmpty()) {
			OpportunityLineItemTriggerClass.updatezoffopptyonLinezoffchanges(ids,new List<OpportunityLineItem> (),'async');
        }
        ids.clear();
	}
	global void finish(Database.BatchableContext BC) {}
}