/**
 * @author : Vinayendra T N <vintara@akamai.com>
    @Description : An apex page controller that exposes the site login functionality
    --Developer			--Date			--Description
    Vinayendra.T.N		April/2012		Changed logic to redirect if user visits any other site except https://netalliance.akamai.com.
    									CR 1610779 PRM: Login page infinite loop cache fix
    Pranav Moktali		Sept/2013		CR 2359974 SSO: Redirecting the requests to Luna-IDP with the the suffix.
    									-> Also redirect the Partner user to a Welcome page instead of home page.
 * 
 */
global with sharing class SiteLoginController {
    global String username {get; set;}
    global String password {get; set;}
    global Boolean FirstTimeLoadFlag {get; set;}
	global string urlpath {get; set;}
	global string idpUrl {get; set;}
	private Boolean connectToLuna {get;set;}
	private Boolean currentOrgProduction {get;set;}
	private Boolean redirectToNAPDomain {get;set;}
	
	global SiteLoginController () {
    	FirstTimeLoadFlag=true;
    	
        System.Debug('called');
    	connectToLuna = Util.isLunaConnectionActive();
    	currentOrgProduction = Util.isOrganizationProduction();
    	redirectToNAPDomain = PRM_Settings__c.getInstance('AkamaiNetallianceBrandingEnabled').Value__c=='TRUE';
    	idpUrl = Util.getLunaIdpUrl();
    }
    
    
	global PageReference redirect() {
		if(connectToLuna)
		{
			return redirectToIdp();
		}
        System.Debug('In here');
	
		Boolean DoRedirect=false;
		string p_redirect='';
    	p_redirect=System.currentPageReference().getParameters().get('redirect');
		// Check if current Org is Prod and A Custom setting is set
		if(Userinfo.getOrganizationId().contains('00DA0000000Hu5a') && PRM_Settings__c.getInstance('AkamaiNetallianceBrandingEnabled').Value__c=='TRUE')
    	{//Check if URL not starts with https://netalliance.akamai.com
    		if(!URL.getCurrentRequestUrl().toExternalForm().toLowerCase().startsWith(PRM_Settings__c.getInstance('BrandedPartnerSiteURL').Value__c) && p_redirect!='false')
    		{//If all abv condtions are satisfied, set a variable
    			DoRedirect=true;
    		}
    	}
    	//If variable is set, do the redirect.
    	if(DoRedirect==true)
    	return new PageReference(URL.getCurrentRequestUrl().toExternalForm().replace(URL.getSalesforceBaseUrl().toExternalForm(), PRM_Settings__c.getInstance('BrandedPartnerSiteURL').Value__c));
    	else
    	return null;
    
    }
    
    global PageReference redirectToIdp(){
        System.Debug('wat');
    	String startUrl = System.currentPageReference().getParameters().get('startURL');
    	String prefix = idpUrl;
    	
    	 
        if(startUrl==''|| startUrl==null)
        {
            startUrl = PRM_Settings__c.getInstance('SSOStartURL').Value__c;
        }

        
        if(currentOrgProduction && redirectToNAPDomain)
    	{
    		startUrl = PRM_Settings__c.getInstance('BrandedPartnerSiteURL').Value__c + startUrl;
    	}
    	
        if(prefix!=null)
        {
        	startUrl = prefix + '&RelayState=' + startUrl;
        }

        System.Debug('### startURLagain' + startURL);
        return new PageReference(startUrl);   
    }
    
    global PageReference login() 
    {
        FirstTimeLoadFlag=false;
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        if(startUrl==''|| startUrl==null)
            startUrl='/home/home.jsp';
        String prefix=Site.getPathPrefix();
        if(prefix!=null)
            startUrl=prefix+startUrl;
        return Site.login(username, password, startUrl);
    }

    public static PageReference exceptionNotification(PageReference pageRef,Exception e) {
        String mailTo = GSM_Custom_Settings__c.getInstance('CronBatchJob#EmailDestro').value__c;//CronBatchJob#EmailDestro
        List<String> recepients = mailTo.split(',');
        String errorString = 'There are problems while executing request.' + '<br/>User Id : '+UserInfo.getUserId();

        if(pageRef!=null)
        {
            errorString = errorString + '<br/> URL: '+ pageRef.getUrl() + '<br/> Parameters: '+ pageRef.getParameters();
        }
        else
        {
            errorString = errorString + '<br/> PageReference was null. Probably errored in a webservice method. ';
        }
        errorString = errorString + '<br/>Error Message :'+e.getMessage() + '<br/>StackTrace :'+ e.getStackTraceString();
        EmailUtils.sendHTMLEmail(recepients,'Alert: Unhandled PRM Exception', errorString);
        PageReference errorPage = Page.Exception;
        errorPage.setRedirect(true);
        return errorPage;
    }    
    
}