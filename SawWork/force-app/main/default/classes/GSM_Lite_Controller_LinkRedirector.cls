public class GSM_Lite_Controller_LinkRedirector 
{
	private Id recordId;
    private Opportunity opp;
	public GSM_Lite_Controller_LinkRedirector(ApexPages.StandardController controller) 
	{
		opp = (Opportunity)controller.getRecord();
		
		opp = [Select AccountId from Opportunity where Id=:opp.Id];
		recordId = opp.AccountId;

	}

	private String getRedirectLink(String recordId, Boolean isLightning)
	{
		String urlToRedirect = '';
		GSM_LITE_SETTING__c linkSetting = GSM_LITE_SETTING__c.getValues('Contracts');
		if(linkSetting != null)
		{
			if(isLightning)
			{
				urlToRedirect = linkSetting.LightningLink__c;
			}
			else
			{
				urlToRedirect = linkSetting.ClassicLink__c;
			}	
			if(recordId != null)
			{			
				urlToRedirect = urlToRedirect.replace('[ID]',recordId);
			}
			else
			{
				if(isLightning)
				{
					urlToRedirect = urlToRedirect.replace('[ID]/rlName/Merge_Contracts__r/view','Contract/list?filterName=');	
				}
				else
				{
					urlToRedirect = urlToRedirect.replace('[ID]','');	
				}
			}
		}
		return  urlToRedirect;

	}

	public PageReference redirectToURL()
	{
		Boolean isLightning = false;

        if(UserInfo.getUiThemeDisplayed() == 'Theme4d')
        {
        	isLightning = True;
        }

        String redirectURL = getRedirectLink(recordId, isLightning);
		return new PageReference(redirectURL);
	}
    
    /*MOB - 143 */
    private String redirectURLForAddPartnerContact(String recordId, Boolean isLightning)
	{
		String urlToRedirect = '';
		urlToRedirect='/apex/PRMAddPartnerToSalesTeam?id='+recordId;
		return  urlToRedirect;

	}
    
    public PageReference addPartnerContact()
	{
		Boolean isLightning = false;

        if(UserInfo.getUiThemeDisplayed() == 'Theme4d')
        {
        	isLightning = True;
        }

        String redirectURL = redirectURLForAddPartnerContact(opp.Id, isLightning);
		return new PageReference(redirectURL);
	}
    
    /* end of MOB -143 */


}