global without sharing class WelinaLoginFormController {

    public WelinaLoginFormController() {}

    @AuraEnabled
    public static String login(String username, String password, String startUrl) {
        try{
            startUrl = getStartURL();
            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
            aura.redirect(lgn);
            return null;
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    public static Boolean getIsUsernamePasswordEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getUsernamePasswordEnabled();
    }

    @AuraEnabled
    public static Boolean getIsSelfRegistrationEnabled() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getSelfRegistrationEnabled();
    }

    @AuraEnabled
    public static String getSelfRegistrationUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        if (authConfig.getSelfRegistrationEnabled()) {
            return authConfig.getSelfRegistrationUrl();
        }
        return null;
    }

    @AuraEnabled
    public static String getForgotPasswordUrl() {
        Auth.AuthConfiguration authConfig = getAuthConfig();
        return authConfig.getForgotPasswordUrl();
    }
    
    @AuraEnabled
    public static String getSSOURL(String relayState) {
        SFCommunity_NQLB_Topics__mdt  ssoUrl = [SELECT SSO_Login_URL__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'WelinaNQLB' limit 1];
        if(!String.isEmpty(relayState)) {
            return ssoUrl.SSO_Login_URL__c+'&RelayState'+relayState;
        } else {
            return ssoUrl.SSO_Login_URL__c;
        }
    }
    
    @TestVisible
    private static Auth.AuthConfiguration getAuthConfig(){
        Id networkId = Network.getNetworkId();
        Auth.AuthConfiguration authConfig = new Auth.AuthConfiguration(networkId,'');
        return authConfig;
    }
    
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }
    }
    @AuraEnabled
    public static String getStartURL(){
        String startURL = null;
        List<Marketing_Settings__mdt> welinaList = [SELECT Id, Value__c FROM Marketing_Settings__mdt WHERE DeveloperName = 'WelinaStartURL' LIMIT 1];
        if(welinaList.size()>0) {
            startURL = welinaList[0].Value__c;
        }
        return startURL;
    }  
}