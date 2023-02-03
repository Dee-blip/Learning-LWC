/**
 * Appirio | Dharmesh Patel | Initital Development
 * An apex page controller that exposes the site login functionality
 */
@IsTest global with sharing class CommunitiesLoginControllerTest {
   /* static{
     utilTestClass.insertCustomSettings();
    }*/
    
    @IsTest(SeeAllData=true) 
    global static void testCommunitiesLoginController () {
        Account a = New Account();
        a.Name = 'Test Community Account';
        a.Website = 'www.community.com';
        a.Partner_Type__c = 'unknown';
        a.BillingCountry = 'USA';
        a.BillingPostalCode ='90897';
        a.BillingState = 'NY';
        a.BillingCity = 'Buffalo';
        a.BillingStreet = 'Line1 \r\n Line2';
        insert a;
        
        profile p = [Select p.name, p.id From Profile p where p.UserLicense.Name like '%Customer Portal Manager Custom%' limit 1];
        
         /*CR 2770464 - rsharma: Commenting insertion of custom settings, 
        As this class is marked SeeAllData = true and hence it is failing with 'FIELD_INTEGRITY_EXCEPTION' for cs.name = 'Community'  */

        /*Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c = '.akamai';
        cs.Communities_User_Account_Id__c = a.Id;
        cs.Self_Registration_Community_Profile_Id__c = p.Id;
        cs.name = 'Community';
        insert cs;*/
        
        String startUrl = '/community/';
        
        CommunitiesLoginController controller = new CommunitiesLoginController ();
        controller.userName = 'test@test.com';
        controller.password = 'password';
        System.assertEquals(controller.logIn(),null);
    }    
}