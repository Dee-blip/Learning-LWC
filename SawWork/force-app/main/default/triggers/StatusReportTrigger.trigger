/*****************************************************************************
 * Name             : StatusReportTrigger
 * Created By       : Pitamber Sharma
 * Created Date    	: 09-May-2013
 * Purpose          : Trigger to update Last Status Report on Case
 *****************************************************************************/
trigger StatusReportTrigger on Status_Report__c (after insert, after update) {
	if(Trigger.isAfter && !UserInfo.getName().equalsIgnoreCase('Connection User')) {
		if(Trigger.isUpdate || Trigger.isInsert) {
			List<Case> updateableCase = new List<Case>();
			Set<Id> caseIds = new Set<Id>();
			for(Status_Report__c sr : Trigger.new) {
				if(sr.Status_Report_Sent__c != null) {
					caseIds.add(sr.Case__c);
					//updateableCase.add(new Case(Id = sr.Case__c, Last_Status_Report__c = sr.Status_Report_Sent__c));
				}
			}
			
			Map<Id, Case> caseMap = new Map<Id, Case>([Select Id, Last_Status_Report__c, IsClosed From Case Where Id IN: caseIds]);
			Case cs; 
			for(Status_Report__c sr : Trigger.new) {
				if(caseMap.containsKey(sr.Case__c)) {
					cs = caseMap.get(sr.Case__c);
					if(cs.IsClosed) {
						sr.addError('Status Report can not be Added on Closed Case. Please Reopen the Case First.');
					} else {
						cs.Last_Status_Report__c = sr.Status_Report_Sent__c;
						updateableCase.add(cs);
					}
				}
			}
			if(updateableCase.size() > 0) {
				update updateableCase;
			}
		}
	}

}