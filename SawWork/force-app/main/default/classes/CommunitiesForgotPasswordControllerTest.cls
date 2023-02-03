/**
 * Appirio | Dharmesh Patel | Initital Development
 * An apex page controller that exposes the site login functionality
 */
@IsTest global with sharing class CommunitiesForgotPasswordControllerTest{
/* static{
     utilTestClass.insertCustomSettings();
    }*/
    @IsTest(SeeAllData=True) 
    global static void testCommunitiesForgotPasswordController() {

         /*CR 2770464 - rsharma: Commenting insertion of custom settings, 
        As this class is marked SeeAllData = true and hence it is failing with 'FIELD_INTEGRITY_EXCEPTION' for cs.name = 'Community'  */
        
        /*Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c = '.akamai';
        cs.Communities_User_Account_Id__c = 'accountId';
        cs.Self_Registration_Community_Profile_Id__c = 'profileId';
        cs.name = 'Community';
        insert cs;*/
        
        
        CommunitiesForgotPasswordController controller = New CommunitiesForgotPasswordController();
        controller.userName = 'test@akamai.com';
        controller.ResetPassword();
        
    }
}