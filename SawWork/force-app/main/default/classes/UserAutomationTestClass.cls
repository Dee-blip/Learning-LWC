@isTest(seeAllData=false)
public class UserAutomationTestClass {
    static 
    {        
        utilTestClass.insertCustomSettings();   
    }

    static testMethod void testBulkUserUpdate()
    {

        System.runAs(utilTestClass.getTestRunUser())
        {

            Profile pr = [select id from profile where name='Sales - Media'][0];
            UserRole role = [select Id, name from UserRole where name='Worldwide'][0];
            integer numberOfTestUsers = 100;
            List<user> listOfTestUsers = new List<User>();

            for(integer i=0;i<numberOfTestUsers;i++)
            {

                User tmUser = new User(alias = 'tUsr1'+i, email='ttt12'+i+'@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_meber1'+i+'@akamai.com',profileid = pr.Id, UserRoleId=role.Id, Has_view_content_in_portals__c=false);

                listOfTestUsers.add(tmUser);
            }
            Test.startTest();
            insert listOfTestUsers;

            // create a new rule for sales operations profile and worldwide role

            User_Automation_Trigger_Condition__c uuatc = new User_Automation_Trigger_Condition__c(Active__c=true, Filter_Condition__c='Profile AND Role', Profile__c='Sales Operations', Role__c='Worldwide');

            insert uuatc;

            List<User_Automation_Action__c> actions = new List<User_Automation_Action__c>();

            User_Automation_Action__c uaa1 = new User_Automation_Action__c(Action_Type__c='Field Update', Field_API_Name__c='Has_view_content_in_portals__c', Field_Value__c='true', Trigger_Condition__c=uuatc.id);

            actions.add(uaa1);

            User_Automation_Action__c uaa2 = new User_Automation_Action__c(Action_Type__c='Permission Set Assignment', Trigger_Condition__c=uuatc.id, Permission_Sets__c='Data.com users;DocuSign User');

            actions.add(uaa2);

            User_Automation_Action__c uaa3 = new User_Automation_Action__c(Action_Type__c='Permission Set License Assignment', Trigger_Condition__c=uuatc.id,Permission_Set_Licenses__c='Sales Console User;Admin Analytics Apps');

            actions.add(uaa3);

            insert actions;


            Profile pr2 = [select id from profile where name='Sales Operations'][0];

            for(User ithUser : listOfTestUsers)
            {
                ithUser.profileId = pr2.Id;
            }


            update listOfTestUsers;
            Test.stopTest();

            listOfTestUsers = [select id, Has_view_content_in_portals__c from User where id in :listOfTestUsers];

            for(User ithUser : listOfTestUsers)
            {
                System.assert(ithUser.Has_view_content_in_portals__c, true);
            }


            System.assertEquals(numberOfTestUsers*2,  [select count() from PermissionSetAssignment where AssigneeId in :listOfTestUsers and (PermissionSet.Label='Data.com users' or PermissionSet.Label='DocuSign User')]);
            /*
               commenting this out since we get license limit exceeded

            try
            {
                System.assertEquals(numberOfTestUsers*2,  [select count() from PermissionSetLicenseAssign where AssigneeId in :listOfTestUsers and (PermissionSetLicense.masterlabel='Sales Console User' or PermissionSetLicense.masterlabel='Admin Analytics Apps')]);
            }
            catch(Exception ex){

                System.assert([select Error_Message__c from Error_log__c limit 1][0].Error_Message__c.containsIgnoreCase('licenses are in use'));
            }

            */



        }
    }

}