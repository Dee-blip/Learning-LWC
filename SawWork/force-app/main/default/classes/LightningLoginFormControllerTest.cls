@IsTest
public with sharing class LightningLoginFormControllerTest 
{
    @IsTest
    static void testLoginWithInvalidCredentials() 
    {
        //System.assertEquals('Argument 1 cannot be null', LightningLoginFormController.login('testUser', 'fakepwd', null));
        LightningLoginFormController.login('testUser', 'fakepwd', null);
    }
    
    @IsTest
    static void LightningLoginFormControllerInstantiation() 
    {
        LightningLoginFormController controller = new LightningLoginFormController();
        System.assertNotEquals(controller, null);
    }

    @IsTest
    static void testIsUsernamePasswordEnabled() {
        //System.assertEquals(true, LightningLoginFormController.getIsUsernamePasswordEnabled());
        Boolean b = LightningLoginFormController.getIsUsernamePasswordEnabled();
    }
    
    @IsTest
    static void testIsSelfRegistrationEnabled() {
        LightningLoginFormController.getIsSelfRegistrationEnabled();
    }
    
    @IsTest
    static void testGetSelfRegistrationURL() {
        LightningLoginFormController.getSelfRegistrationUrl();
    }
    
    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = LightningLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }
    
    @IsTest
    static void testgetForgotPasswordUrl() {
        LightningLoginFormController.getForgotPasswordUrl();
    }
    
    @IsTest
    static void testgetSSOURL() {
        LightningLoginFormController.getSSOURL('test');
    }
    
    @IsTest
    static void testsetExperienceId() {
        LightningLoginFormController.setExperienceId('Test');
    }
}