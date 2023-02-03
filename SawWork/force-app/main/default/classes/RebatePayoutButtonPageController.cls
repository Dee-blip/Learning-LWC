public class RebatePayoutButtonPageController {
	PageReference pageRef;
	public static String recordId;
	public static String associatedPartner;
	public Boolean sendToCMG {get; set;}

	public PageReference init() {
		String fromButton;
		fromButton = ApexPages.currentPage().getParameters().get('fromButton');
		recordId   = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('recordId').escapeHtml4()); // SFDC-5952 Added escapeHTML4 and esacped single quotes
		associatedPartner   = ApexPages.currentPage().getParameters().get('associatedPartner');
		sendToCMG = false;

		if(fromButton == 'SendToCMG') {
			pageRef = sendToCMG();
			return pageRef;
		}

		return null;

	}

	public PageReference sendToCMG() {
		String result = PRM_opportunity.updateRebatePayoutStatusAndCreateTask((Id)recordId,(Id)associatedPartner);
		if(result != '' && result != null) {
			if(result.contains('Success')) {
				sendToCMG = true;
				return null;
			}
			else {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,result));
			}
		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
					'You are not authorized. Please contact system administrator.'));
		}
		return null;

	}

	public PageReference backToRebatePayout() {
		recordId   = ApexPages.currentPage().getParameters().get('recordId');
		pageRef = new PageReference('/'+(Id)recordId);
		pageRef.setRedirect(true);
		return pageRef;
	}

}