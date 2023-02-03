/*****************************************************************************
 * Name             : CaseCommentTriggerHandler
 * Created By       : Pitamber Sharma
 * Created Date    	: 27-May-2013
 * Purpose          : Handler class for CaseCommentTrigger
 
 Last Modified Date : 07-Feb-2014
 Modified By        : Vijetha Vijayendran
 Purpose            : Implement check on isClosed flag before updating case details.
 *****************************************************************************/
public with sharing class CaseCommentTriggerHandler {
	
	public void onAfterInsert(List<CaseComment> caseComments) {
		setRecentUpdateOnCaseTrue(caseComments);
	}
	
	private void setRecentUpdateOnCaseTrue(List<CaseComment> caseComments) {
		List<Case> recentUpdatedCases = new List<Case>();
		Set<Id> recentUpdatedCaseIds = new Set<Id>();
		Map<Id, Case> caseMap;
		Case cs;
	
		for(CaseComment cc : caseComments) {
			recentUpdatedCaseIds.add(cc.ParentId);
		}
		
		if(recentUpdatedCaseIds.size() > 0) {
			caseMap = new Map<Id, Case>([Select Id, Recent_Update__c, ownerId, isClosed from Case Where Id IN : recentUpdatedCaseIds]);
			
			for(CaseComment cc : caseComments) {
				if(caseMap.get(cc.ParentId).ownerId != cc.CreatedById) {
					cs = caseMap.get(cc.ParentId);
					if(!cs.isClosed) {
						cs.Recent_Update__c = true;
						recentUpdatedCases.add(cs);
                    }
				}
			}
			
			if(recentUpdatedCases.size() > 0) {
				update recentUpdatedCases;
			}
		}
	}
}