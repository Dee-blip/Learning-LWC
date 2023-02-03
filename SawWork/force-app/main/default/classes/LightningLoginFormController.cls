/*<!--Customer Community Component-->*/
//changes for Welina Playground. Added without sharing
global without sharing class LightningLoginFormController {

    public LightningLoginFormController() {
        
    }

    @AuraEnabled
    public static String login(String username, String password, String startUrl) {
        try{
             List<String> profileNames = new List<String>();
            Profile communityguestProfile;
            Profile guestProfile;
            profileNames.add('SFWelinaGuests');
            profileNames.add('SFCommunityGuests');
            for(Profile selectedProfile: [SELECT id,name from profile where name in : profileNames]) {
                if (selectedProfile.name == 'SFWelinaGuests') {
                    guestProfile = selectedProfile;
                }
                if (selectedProfile.name == 'SFCommunityGuests') {
                    communityguestProfile = selectedProfile;
                }
            }
            User u = [Select Id,profileId from User where Username = :username];
            if (guestProfile != null && communityguestProfile!=null && u.ProfileId == guestProfile.Id) {
               update new User(Id=u.Id,ProfileId = communityguestProfile.Id);
            }
            ApexPages.PageReference lgn = Site.login(username, password, startUrl);
            aura.redirect(lgn);
            return null;
        }
        catch (Exception ex) {
            SC_Jarvis_utility.sendErrorMails('Error in Community Login Controller: ', 'Username: ' + username + '<br>' + ex.getMessage(), ex.getStackTraceString());
            if(ex.getMessage().containsIgnoreCase('access is disabled')) {
                return Label.Jarvis_LightningLoginFormController_AccessDisabledError;
            }
            return Label.Jarvis_LightningLoginFormController_LoginAttemptFailedError;
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
        SFCommunity_NQLB_Topics__mdt  SSOUrl = [SELECT SSO_Login_URL__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        if(!String.isEmpty(relayState))
            return SSOUrl.SSO_Login_URL__c+'&RelayState'+relayState;
        else
        	return SSOUrl.SSO_Login_URL__c;
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
}