//SFDC-1748 - Generic class for Fund Request buttons
public class FundRequestButtonPageController
{
	PageReference pageRef;

	public static Id recordId;
	public static Id userProfileId;
	// SFDC-6609
	public String message {get;set;}

	public PageReference init()
	{
		String fromButton;

    	fromButton = ApexPages.currentPage().getParameters().get('fromButton');
    	recordId   = ApexPages.currentPage().getParameters().get('recordId');
    	userProfileId   = ApexPages.currentPage().getParameters().get('userProfileId');

    	if(!String.isBlank(fromButton))
    	{
    		if(fromButton == 'SubmitForApproval')
    		{
                pageRef = submitForApproval();
                return pageRef;
            }

            else if(fromButton == 'AssociateToCampaign') {
            	pageRef = associateToCampaign();
                return pageRef;
            }
    	}

		return null;
	}

	public PageReference submitForApproval()
	{
		// SFDC-6609
		message = '';
		String result1, result2;
		result1 = 'Error . Contact System Administrator';
		// SFDC-6609
		message = '';
		if(recordId != null){ // SDFC 7223
			result1 = FCM_page_controller.assignMasterChannelMapping((Id)recordId);
		}
		if( !String.isBlank(result1) && result1 == 'Succesfully Assigned Channel Manager')
		{
			//SFDC-8900
			SFDC_MDF__c fundRequestRecord = [SELECT Id, Status__c,Amount__c,Partner_Marketing_Activity__c FROM SFDC_MDF__c WHERE Id = :recordId];
			Id pmaId = fundRequestRecord.Partner_Marketing_Activity__c;
			Partner_Marketing_Activity__c currPMA = [Select Activity_Cost__c,Valid_FR_Cost__c from Partner_Marketing_Activity__c where id =: pmaId];
			
			
			if(fundRequestRecord != null && fundRequestRecord.Status__c != 'Rejected') {
				result2 = 'Error . Contact System Administrator';

				//SFDC-8900
				if(currPMA.Valid_FR_Cost__c +fundRequestRecord.Amount__c<=currPMA.Activity_Cost__c){
					result2 = PRM_Opportunity.submitForApproval((Id)recordId);
				}
				else {
					result2 = 'Running cost exceeds PMA cost';
				}

				result2 = result2.replace('Succesfully', 'Successfully');
				if(!String.isBlank(result2) && result2 == 'Successfully Submitted for Approval')
				{
					// SFDC-6609
					if (Apexpages.currentPage() != null) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, result2));
					}
					pageRef = new PageReference('/'+(Id)recordId);
					pageRef.setRedirect(true);

					return pageRef;
				}

				else
				{
					// SFDC-6609
					if (Apexpages.currentPage() != null) {
						ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An unknown exception occurred. '+result2+' Partner Support has been notified.'));
					}else{
						message = 'An unknown exception occurred. '+result2+' Partner Support has been notified.';
					}

					Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();

					string CRMOpsOrgWideId = GsmUtilClass.getPRMSettingValue('CRM_Ops_Org_Wide_Address');
					String toAddress = GsmUtilClass.getNAPSettingValue('PartnerSupportDefaultMailId');

					EmailTemplate supportMail = [select Body,Subject from EmailTemplate where DeveloperName='Fund_Request_Inactive_Approver'][0];

					if(supportMail != null)
					{
						String tempEmailBody=supportMail.Body;
						String tempEmailSubject=supportMail.Subject;

						SFDC_MDF__c fr = [select Account__r.Name,Account__r.Id,Fund_Request_Approver__r.Id from SFDC_MDF__c where Id = :recordId][0];

						tempEmailSubject = tempEmailSubject.replace('{!SFDC_MDF__c.Account__c}', fr.Account__r.Name);
						tempEmailBody = tempEmailBody.replace('{!SFDC_MDF__c.Id}', recordId);
						tempEmailBody = tempEmailBody.replace('{!SFDC_MDF__c.Account__c}', fr.Account__r.Name);
						tempEmailBody = tempEmailBody.replace('{!SFDC_MDF__c.AccountId__c}', fr.Account__r.Id);
						tempEmailBody = tempEmailBody.replace('{!SFDC_MDF__c.Fund_Request_ApproverId__c}', fr.Fund_Request_Approver__r.Id);
						if(UserInfo.getUserType().equals('PowerPartner'))
						{
							tempEmailBody = tempEmailBody.replace('{!Organization.Id}', URL.getSalesforceBaseUrl().toExternalForm()+'/'+Label.Partner_Community_Name);
						}
						else
						{
							tempEmailBody = tempEmailBody.replace('{!Organization.Id}', URL.getSalesforceBaseUrl().toExternalForm());
						}
						tempEmailBody = tempEmailBody.replace('{!Organization.Id}', URL.getSalesforceBaseUrl().toExternalForm());

						sendEmailList.add(GsmUtilClass.createSingleEmailWithOrgId(toAddress,'',tempEmailSubject,tempEmailBody,tempEmailBody,CRMOpsOrgWideId));

						if(sendEmailList.size() > 0)
						{
							Messaging.sendEmail(sendEmailList);
						}
					}
				}
			}
			else if(fundRequestRecord != null && fundRequestRecord.Status__c == 'Rejected') {
				// SFDC-6609
				if(Apexpages.currentPage() != null)
					ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot submit a Rejected Fund Request for Approval'));
				else{
					message = 'Cannot submit a Rejected Fund Request for Approval';
				}
			}
		}

		else
		{
			// SFDC-6609
			if (Apexpages.currentPage() != null) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An unknown exception occurred. '+result1));
			}else{
				message = 'An unknown exception occurred. '+result1;
			}
		}

		return null;
	}

	public PageReference associateToCampaign() {
		Profile profileRec = [Select Name from Profile where Id = :userProfileId];
		if(profileRec.Name == 'System Administrator' || profileRec.Name == 'Partner Marketing' ||
		   profileRec.Name == 'Partner Support' || profileRec.Name == 'CRM Integration' ||
		   profileRec.Name == 'Marketing - wo Import') {
			pageRef = new PageReference('/apex/FRToCampaignAssociationPage?id='+(Id)recordId);
			pageRef.setRedirect(true);
			return pageRef;

		} else {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 
									 'You do not have sufficient access rights'));
		}
		return null;
	}

	public PageReference backToFundRequest() {
		pageRef = new PageReference('/'+(Id)ApexPages.currentPage().getParameters().get('recordId'));
		pageRef.setRedirect(true);
		return pageRef;
	}
}