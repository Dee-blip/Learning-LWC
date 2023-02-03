/**
 * Appirio | Dharmesh Patel | Initital Development
 * An apex page controller that supports self registration of users in communities that allow self registration
 
 3.39.1.. sts
 */
@IsTest public with sharing class CommunitiesSelfRegControllerTest {
    @IsTest(SeeAllData=true) 
    public static void testCommunitiesSelfRegController() {
        Account a = New Account();
        a.Name = 'Test Comunity Acount';
        a.Website = 'www.comunity.com';
        a.Partner_Type__c = 'unknown';
        a.BillingCountry = 'USA';
        a.BillingPostalCode='99999';
        a.BillingState = 'NY';
        a.BillingCity = 'Buffalo';
        a.BillingStreet = 'Line1 \r\n Line2';
        insert a;
        
        profile p = [Select p.name, p.id From Profile p where p.UserLicense.Name like '%Customer Portal Manager Custom%' limit 1];
        
        //Test case update 1 start 
        /*
        Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c = '.akamai';
        cs.Communities_User_Account_Id__c = a.id;
        cs.Self_Registration_Community_Profile_Id__c = p.id;
        cs.name = 'Community';
        insert cs;
        */
        
        System.runAs ( new User(Id = UserInfo.getUserId()) ) {
        /*Insert a user with PRM Profile*/
        Account acc=utilTestClass.CreateAccount('Test Partneracc__1');
        insert acc;
        List<User> prmUsers = utilTestClass.createPartnerUsers(1,acc.Id);
        User prmUser = prmUsers[0];
        
        /*Insert a user with SystemAdmin Profile to check duplicate later */
        profile pEx = [Select name, id From Profile where Name like '%System Administrator%' limit 1];
        User uEx = new User(alias = 'uExFL', email='testFirstLast@apttus.com',emailencodingkey='UTF-8', lastname='testLastName', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='testFirstLast@apttus.com',profileid = pEx.Id );
        insert uEx;
        //Test case updat 1 end
        
        CommunitiesSelfRegController controller = new CommunitiesSelfRegController();
        controller.firstName = 'testFirst';
        controller.lastName = 'testLast';
        controller.email = 'testFirstLast@akamai.com';
        controller.password = 'abcd1234';
        controller.confirmPassword = 'abdc1234';
        controller.communityNickname = 'testlastfirst';
        controller.AgreeToTermsAndConditions = true;
        
        PageReference pr;
        
        //Test case update 2 start
          // Test Akamai User
          pr = controller.registerUser();
          System.assert(pr==null);
          
          // Test PRM User
          controller.email = prmUser.email;
          pr = controller.registerUser();
          System.assert(pr==null);
          
          // Test Existing User
          controller.email = 'testFirstLast@apttus.com';
          pr = controller.registerUser();
          System.assert(pr==null);
        //Test case update 2 end
          
        // Test Password Validation
        pr = controller.registerUser();
        System.assert(pr==null);
        
        controller.confirmPassword = 'abcd1234';
        controller.AgreeToTermsAndConditions = false;
        // Test Terms and Conditions
        pr = controller.registerUser();
        System.assert(pr==null);
        
        controller.AgreeToTermsAndConditions = true;
        // Test User Creation
        pr = controller.registerUser();
        System.assert(pr==null);
        
        
    }
    }    
}