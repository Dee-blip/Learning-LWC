public class FundClaimButtonPageController {
	PageReference pageRef;
    public static String recordId;
    public static String status;
    public static Id userProfileId;
    public String resultData {get; set;}
     // SFDC-6609
    public String message {get;set;}

    public PageReference init() {
		String fromButton;
		fromButton = ApexPages.currentPage().getParameters().get('fromButton');
    	recordId   = ApexPages.currentPage().getParameters().get('recordId');
        status   = ApexPages.currentPage().getParameters().get('status');
        userProfileId   = ApexPages.currentPage().getParameters().get('userProfileId');
        
        // SFDC-5895 - Added By Prabhanjan
        if(status != null && status != '') {
            status = String.escapeSingleQuotes(status.escapeHtml4());
        }

        if(recordId != null && recordId != '') {
            recordId = String.escapeSingleQuotes(recordId.escapeHtml4());
        }


    	if(!String.isBlank(fromButton))
    	{
    		if(fromButton == 'Pay')
    		{
                pageRef = payClaim();
                return pageRef;
            } 

            else if(fromButton == 'AddPrivateNote') {
                pageRef = addPrivateNote();
                return pageRef;
            }

            else if(fromButton == 'SubmitForApproval') {
                pageRef = submitForApproval();
                return pageRef;
            }
		}
		return null;
	}
    
    public PageReference payClaim() {
        if( !String.valueof(status).contains('Paid'))	{
        	pageRef = new PageReference('/apex/PayClaim?scontrolCaching=1&id='+(Id)recordId);
			pageRef.setRedirect(true);
			return pageRef;    
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
									 'This Fund Claim has already been Paid'));
        }
        return null;
    }

    public PageReference addPrivateNote() { 
        Profile profileRec = [Select Name from Profile where Id = :userProfileId];
        if(profileRec.Name == 'System Administrator' || profileRec.Name == 'Partner Marketing' ||
           profileRec.Name == 'Partner Support' || profileRec.Name == 'CRM Integration' ||
           profileRec.Name == 'Sales - Partner Account Executive' || 
           profileRec.Name == 'Sales Operations') {
            pageRef = new PageReference('/apex/FundClaimAddPrivateNote?id='+(Id)recordId);
            pageRef.setRedirect(true);
            return pageRef;

        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                     'You do not have sufficient access rights'));
        }
        return null;
    }

    public PageReference submitForApproval() {
        // SFDC-6609
        message = '';
        if(status == 'Draft' || status == 'Rejected For Re-submit') {
            String result = PRM_opportunity.submitForApproval((Id)recordId);
            if(result != '' && result != null ){
                if(result.contains('Succesful')) {
                    resultData = result.replace('Succesful', 'Successful');
                } else {
                    // SFDC-6609
                    if (Apexpages.currentPage() != null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                         result));
                    }else{
                        message = result;
                    }
                }
                return null;
            } else {
                // SFDC-6609
                    if (Apexpages.currentPage() != null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                         'Some unknown exception occurred'));
                    }else{
                        message = 'Some unknown exception occurred';
                    }
            }
            
        }
        else if(status == 'Rejected') {
             // SFDC-6609
            if (Apexpages.currentPage() != null) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                         'Cannot Submit a Fund Claim that has already been Rejected')); 
                    }else{
                        message = 'Cannot Submit a Fund Claim that has already been Rejected';
                    }
        } else {
            // SFDC-6609
            if (Apexpages.currentPage() != null) {
                       ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
                                         'This Fund Claim has already been Submitted for Approval'));    
                    }else{
                        message = 'This Fund Claim has already been Submitted for Approval';
                    }
        }
        return null;
    }
    
    public PageReference backToFundClaim() {
        recordId   = ApexPages.currentPage().getParameters().get('recordId');
		pageRef = new PageReference('/'+(Id)recordId);
		pageRef.setRedirect(true);
		return pageRef;
	}
}