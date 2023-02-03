/**

 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Sonali Tandon    4/8/2015     CR 3103581 : NAP -- Default Contact Account on Creation
                                              Test class to test when a Partner Community Admin creates Contact in NAP Portal, populate admin's account by default.
  
 **/
@isTest

private class ContactCreateNewTestClass{

    static User partner;

    static User dmlUser = new User(id=UserInfo.getUserId());

    static {
        utilTestClass.insertCustomSettings();
    }
            
    static testmethod void autoPopulateAccount(){

        ManagedPkgErrorClass.isFromManagedPackage = false;

        // Create account 
         Account acc = utilTestClass.CreateAccount('__Test Account');
         insert acc;

         //Create a partner User with profile "Partner Community Admin" for that account
        System.runAs(utilTestClass.getTestRunUser())
        { 
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
        }

         Profile partnerCommunityProfile = [Select name, Id from Profile where Name = 'Partner Community Admin'];
         partner.ProfileId = partnerCommunityProfile.Id;
          System.runAs(utilTestClass.getTestRunUser())
        {
            update partner;
        }
       
         System.runAs(partner)
         {
            PageReference pageRef = Page.ContactCreateNew;
            Test.setCurrentPageReference(pageRef);
            ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(new Contact());
            ContactCreateNew controller = new ContactCreateNew(stdController);
            Test.startTest();
            PageReference returnUrl = controller.pageRedirect();
            System.assertEquals(returnUrl.getParameters().get('con4'),acc.Name);
            Test.stopTest();

         }
    }

    static testmethod void updateAccountLicensesTest()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();

            Account accOld = utilTestClass.CreateAccount('__Test Account Old');
            insert accOld;

            Account accNew = utilTestClass.CreateAccount('__Test Account New');
            accNew.Partner_Type__c = 'ADS Partner';
            accNew.Partner_status__c = 'Partner';
            insert accNew;

            accNew.IsPartner = true;
            accNew.Validation_Override__c=true;
            update accNew;

            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = accOld.Id;
            insert con;


            User partnerAdmin=new User(
                    Username='TstPar@akamai.com',
                    Alias = 'testuser', 
                    Email='TstPar@akamai.com', 
                    FirstName='John', 
                    LastName='Doe', 
                    ProfileId = GsmUtilClass.getPRMSettingValue('Partner_Admin_Id'),
                    LanguageLocaleKey='en_US', 
                    LocaleSidKey='en_US', 
                    EmailEncodingKey='UTF-8', 
                    TimeZoneSidKey='America/Los_Angeles',
                    ContactId = con.id,
                    UserPreferencesShowEmailToExternalUsers=true
                    );
            insert partnerAdmin;

            con.AccountId = accNew.Id;
            con.Active_Partner__c = true;
            con.Partner_User__c = partnerAdmin.Id;

            update con;

            Test.stopTest();
        }
    }
}