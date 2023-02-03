public class PartnerPlanButtonPageController {
	PageReference pageRef;
    public static String recordId;
    public static String profileName;
    
    public PageReference init() {
        String fromButton;
		fromButton = ApexPages.currentPage().getParameters().get('fromButton');
    	recordId   = ApexPages.currentPage().getParameters().get('recordId').substring(0, 15);
        profileName   = ApexPages.currentPage().getParameters().get('profileName');
        // SFDC-5895 - Added By Prabhanjan
        if(recordId != null && recordId != '') {
            recordId = String.escapeSingleQuotes(recordId.escapeHtml4());
        }
        if(fromButton == 'PrintPartnerPlans') {
            pageRef = printPartnerPlans();
            return pageRef;
        }
        
        return null;
    }
    
    public PageReference printPartnerPlans() {
        if(profileName == 'Akamai Partner Administrator' || profileName == 'Partner Community Admin') {
            pageRef = new PageReference('/partners/00OG00000049r8B?pv0='+recordId);
        } else {
			pageRef = new PageReference('/00OG00000049r8B?pv0='+recordId);            
        }
        pageRef.setRedirect(true);
        return pageRef;
    }
    
    public PageReference backToPartnerPlan() {
        pageRef = new PageReference('/'+(Id)recordId);
		pageRef.setRedirect(true);
		return pageRef;
    }

}