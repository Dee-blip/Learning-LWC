@IsTest
public with sharing class WelinaLoginFormControllerTest 
{
    @IsTest
    static void testLoginWithInvalidCredentials()  
    {
       String retVel = WelinaLoginFormController.login('testUser', 'fakepwd', null);
       System.assert(retVel == null);
    }
    
    
    @IsTest
    static void welinaLoginFormControllerInstantiation() 
    {
        WelinaLoginFormController controller = new WelinaLoginFormController();
        System.assertNotEquals(controller, null, 'Controller instantiation inclomplete');
    }

    //@IsTest
    //static void testIsUsernamePasswordEnabled() {
    //    //System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
    //    Boolean b = WelinaLoginFormController.getIsUsernamePasswordEnabled();
    //    System.assertEquals(true, b, 'Username password enablement to be true');
    //}
    
    @IsTest
    static void testIsSelfRegistrationEnabled() {
        Boolean b = WelinaLoginFormController.getIsSelfRegistrationEnabled();
        System.assertEquals(false, b, 'Username password enablement to be true');
    }
    
    @IsTest
    static void testGetSelfRegistrationURL() {
        String retVal = WelinaLoginFormController.getSelfRegistrationUrl();
        System.assert(retVal == null);
    }
    
    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = WelinaLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig, 'auth confid check incorrect');
    }
    
    @IsTest
    static void testgetForgotPasswordUrl() {
        String retVal =  WelinaLoginFormController.getForgotPasswordUrl();
        System.assert(retVal == null);
    }
    
    @IsTest
    static void testgetSSOURL() {
        String retVal = WelinaLoginFormController.getSSOURL('test');
        System.assert(retVal != null);
    }
    
    @IsTest
    static void testsetExperienceId() {
        String retVal = WelinaLoginFormController.setExperienceId('Test');
        System.assert(retVal != null);
    }

    @isTest static void testWelinaLoginController(){
        WelinaLoginController c = new WelinaLoginController();
        System.assertEquals(c.forwardToAuthPage(), null, 'Not null');
    }

    @isTest static void testStartURL(){
        String startURL = WelinaLoginFormController.getStartURL();
        System.assert(startURL != null);
    }
}