public class NAPURLService
{
    private static final string landingPage = '/apex/APPLandingPage';
    private static final String notAuthorizedRedirectLocation = landingPage+ '?error_code=401';
    public static final String noSuchPageRedirectLocation = landingPage + '?error_code=404';
    private static final String detailPage = '/apex/APP?page_id=';

    public static String getLink(NAP_Page_Builder__c menuItem)
    {
        if(menuItem.Component_Type__c.equalsIgnoreCase('Page'))
        {
            if(NAPWatchman.allows(menuItem))
                return NAPWatchman.getAddress(menuItem.Id);
        }
        // main menu doesnt have access
        if(menuItem.Component_Type__c.equalsIgnoreCase('Main Menu'))
        {
            if(NAPWatchman.allows(menuItem))
                return getLink(menuItem.Name);
            else 
                return NAPWatchman.getAddress(menuItem.Id)+'?error_code=401';
        }

        // page doesnt have access
        return notAuthorizedPage();
    }

    public static String getLink(String mainMenuAutoNameId)
    {
        return getUserTypeAwareUrl( detailPage + mainMenuAutoNameId);
    }

    public static String getLink(Id pageId)
    {
        return NAPWatchman.getAddress(pageId)+'&error_code=401';
    }


    public static String getUserTypeAwareUrl(String link)
    {
        if(UserInfo.getUserType().equals('PowerPartner') && !link.containsIgnoreCase('/'+Label.Partner_Community_Name+'/'))
            return link.replace('apex', Label.Partner_Community_Name + '/apex');

        return link;
    }

    public static String notAuthorizedPage()
    {
        return getUserTypeAwareUrl( notAuthorizedRedirectLocation);
    }
}