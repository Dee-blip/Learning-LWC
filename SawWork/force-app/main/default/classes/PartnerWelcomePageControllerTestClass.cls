@isTest
public class PartnerWelcomePageControllerTestClass
{
    static User dmlUser = new User(id=UserInfo.getUserId());

    static testmethod void testPartnerPortalPages()
    {
        //Aayushi
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('LunaControlCenterSettings__c'), 'CS_LunaControlCenterSettings');
        
        System.runAs(dmlUser) 
        {
            String accName = '__Test Account';
            Account acc = utilTestClass.CreateAccount(accName);
            Test.startTest();
            insert acc;
            List<User> listOfPartnerUsers= utilTestClass.createPartnerUsers(1, acc.Id);
            User partnerUser = listOfPartnerUsers[0];
            //This is to make sure the Partner_User__c field on contact gets updated
            Test.stopTest();
            system.runAs(partnerUser)
            {

                PageReference pageRef = Page.WelcometoPartnerportal;
                Test.setCurrentPageReference(pageRef);
                WelcomeToPartnerPortal tController = new WelcomeToPartnerPortal();
                tController.init();

                pageRef = Page.viewMyProfilePageCustom;
                Test.setCurrentPageReference(pageRef);
                viewMyProfilePageCustomController tempController = new viewMyProfilePageCustomController();
                tempController.init();
                tempController.Edit();
                tempController.ChangeMyPassword();
                tempController.Save();
                tempController.Cancel();

                pageRef = Page.PartnerPortalWelcomeCustom;
                Test.setCurrentPageReference(pageRef);
                PartnerPortalWelcomeCustom iController = new PartnerPortalWelcomeCustom();
                iController.init();

                PageReference ppNewPage = Page.partnerProfileNew;
                Test.setCurrentPageReference(ppNewPage);
                ppNewPage.getParameters().put('id', String.valueOf(acc.Id));
                /*
                PartnerProfileNewController controller = new PartnerProfileNewController();
                controller.pageRedirect();
                */

            }
        }
    }

    //CR 3018377
    static testmethod void testAKULogin()
    {
        //Aayushi
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('LunaControlCenterSettings__c'), 'CS_LunaControlCenterSettings');
        
        System.runAs(dmlUser) {
            String accName = 'Test Account'+utilTestClass.getRandomString(4);
            Account acc = utilTestClass.CreateAccount(accName);
            insert acc;
            List<User> listOfPartnerUsers= utilTestClass.createPartnerUsers(1, acc.Id);
            User partnerUser = listOfPartnerUsers[0];
            Contact con = [Select id,Partner_User__c from Contact where id = :partnerUser.ContactId];
            con.Partner_User__c = partnerUser.id;
            Test.startTest();
            update con;
            
            system.runAs(partnerUser)
            {
                PageReference pageRef = Page.AkamaiUniversityRedirect;
                Test.setCurrentPageReference(pageRef);
                AkamaiUniversityRedirectController testController = new AkamaiUniversityRedirectController();
                testController.captureAULogin();
                System.debug('testController: '+testController+' : '+testController.currentContact);
                system.assertNotEquals(testController.currentContact,null);
                List<Contact> conList = new List<Contact>();
                conList = [select Id, Name, Last_AU_Login__c from Contact where id = :testController.currentContact.id];
            
                system.assertNotEquals(conList.size(),0);
                System.debug('con[0].Last_AU_Login__c: '+conList);
                system.assertNotEquals(conList[0].Last_AU_Login__c,null);
                AkamaiUniversityRedirectController.getAUURL();
            }
            Test.stopTest();
            
        }
    }
}