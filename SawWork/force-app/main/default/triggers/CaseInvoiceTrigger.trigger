trigger CaseInvoiceTrigger on Case_Invoice__c (before insert, before update) {
	
	Map<Id,Case> idCaseMap;
	List<Id> caseIds=new List<Id>();
	String errorToThrow = GsmUtilClass.getGSMSettingValue('CaseInvoiceTrigger_AccMismatchError'); // SFDC-2705 Custom Settings Migration
	for(Case_Invoice__c ci : Trigger.new)
	{
		caseIds.add(ci.Case_Id__c);
	}
	idCaseMap=new Map<id,Case>([Select Id,Collection_Account__C from Case where id=: caseIds]);
	for(Case_Invoice__c ci : Trigger.new)
	{
		Case cCase=idCaseMap.get(ci.case_Id__c);
		if(ci.Account__c!=null && cCase!=null && ci.Account__c!=cCase.Collection_Account__c)
		{
			ci.addError(errorToThrow);
		}
	}
	

}