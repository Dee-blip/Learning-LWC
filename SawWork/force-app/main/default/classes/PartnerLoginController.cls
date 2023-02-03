global class PartnerLoginController
{
    global static PageReference redirectToIdp()
    {

        String ssoStartUrl =GsmUtilClass.getPRMSettingValue('SSOStartURL'); 
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        String idpUrl = GsmUtilClass.getPRMSettingValue('PartnerCommunityIDPURL');
        String brandedPartnerSiteUrl = GsmUtilClass.getPRMSettingValue('BrandedPartnerSiteURL');

        PageReference pRef;
        String nonLoggedInUserType = 'Guest';

        if(UserInfo.getUserType().equals(nonLoggedInUserType))
        {

            startUrl = (startUrl=='' || startUrl==null) ? ssoStartUrl : startUrl;
            startUrl =(GsmUtilClass.isSandbox()) ? startUrl : (brandedPartnerSiteUrl + startUrl);

            pRef = new PageReference(idpUrl);pRef.getParameters().put('RelayState',startURL);
            System.Debug(Logginglevel.Error, 'AGH_D startURL: '+ startURL + ' pRef '+pRef);
        }
        else
        {
            pRef = new PageReference(ssoStartUrl);
            System.Debug(Logginglevel.Error, 'AGH_D pRef'+pRef);
        }
        pRef.setRedirect(true);
        return pRef;
    }
}