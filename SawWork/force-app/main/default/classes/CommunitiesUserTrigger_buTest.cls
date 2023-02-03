/**
 * Appirio | Dharmesh Patel | Initital Development
 * An apex page controller that exposes the site login functionality
 */
@IsTest public with sharing class CommunitiesUserTrigger_buTest{

    // Changes for CR 2842878(fix the Mixed Dml Exception)
         static User dmlUser = new User(id=UserInfo.getUserId());

    @IsTest(SeeAllData=true) 
     public static void testclassCommunitiesUserTrigger_bu() {

        
        //CR 2770464 - rsharma: creating user in the test class itself
        //Note: not able to call createUser of UtilTestClass, because profile used below, does not have any role
        String pProfileName = 'Customer Communities Profile';
        String pUserName = 'TestUser';
        Profile pr = [select Id from profile where name=:pProfileName][0];
        Contact cont = utilTestClass.CreateContact('Test','User');
        Account acc = UtilTestClass.CreateAccount('testwac');
       
        Test.startTest();

         insert acc;
         acc.IsPartner = true;
          update acc;
        cont.accountId = acc.id;
        insert cont;

        // Added line for CR 2842878(fix the Mixed Dml Exception)
        System.runAs(dmlUser) {
            User usr = new User(alias = pUserName, email=pUserName+'@akamai.com',emailencodingkey='UTF-8', lastname='testLastName', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=pUserName+'_@akamai.com',profileid = pr.Id, ContactId= cont.id);
            //User usr = utilTestClass.createUser('TestUser','','Customer Communities Profile');
            insert usr;
            User u = [Select ContactId, Id, Username From User Where id= :usr.id];
            //IsActive = true limit 1

            u.username = u.username + '.akamai';
            update u;
            
            u.username = u.username.replace('.akamai','');
            update u;
        }
        Test.stopTest();
     
     }
}