@isTest(seeAllData=false)
public class GSM_SendEmailToSalesOpsBatchTest 
{
     
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup
    static void setupMethod() 
    {
                    
        System.runAs(dmlUser) {
            ByPassAndLimitUtils.disable('AccountReassignmentTrigger');
            List<User> userList = new List<User>();
            List<user> managerList = new List<User>();

            User um = utilTestClass.CreateUser('TST_MANA', 'Worldwide', 'Sales - Web');
            um.IsActive = true;
            um.Division = 'GEO Sales & Pre Sales';
            um.profileid = '00e0f000000i4ATAAY';
            managerList.add(um);

            User um1 = utilTestClass.CreateUser('PSalesM', 'Worldwide', 'Solutions Engineer');
            um1.IsActive = true;
            um1.Division = 'GEO Sales & Pre Sales';
            um1.profileid = '00eG0000000f9LK';
            managerList.add(um1);

            User um2 = utilTestClass.CreateUser('tUserMan', 'Worldwide', 'Solutions Engineer');
            um2.IsActive = true;
            um2.Division = 'GEO Sales & Pre Sales';
            um2.profileid = '00eG0000000f9LK';
            managerList.add(um2);

            insert managerList;


            User newUser = utilTestClass.CreateUser('TST_USR', 'Unknown', 'Helpdesk Client-Chatter Only');
            newUser.managerid = um.Id;
            newUser.IsActive = true;
            newUser.GSM_AlertOps_timestamp__c = null;
            newUser.Division = 'GEO Sales & Pre Sales';
            userList.add(newUser);
            
            User newUser1 = utilTestClass.CreateUser('PSales', 'Unknown', 'Helpdesk Client-Chatter Only');
            newUser1.managerid = um1.Id;
            newUser1.IsActive = true;
            newUser1.GSM_AlertOps_timestamp__c = null;
            newUser1.Division = 'GEO Sales & Pre Sales';
            userList.add(newUser1);

            User newUser2 = utilTestClass.CreateUser('testUser', 'Unknown', 'Sales - Web');
            newUser2.managerid = um2.Id;
            newUser2.IsActive = true;
            newUser2.GSM_AlertOps_timestamp__c = null;
            newUser2.Division = 'GEO Sales & Pre Sales';
            userList.add(newUser2);

            insert userList;
            
            Account_Reassignment_Rule__c rule = new Account_Reassignment_Rule__c();
            rule.Name = 'Test';
            rule.Associated_User__c = um.Id;
            rule.User_Role__c = 'Worldwide';
            rule.Sales_Ops_Approver__c = newUser2.id;
            insert rule;     
            
        }
          

    }
    static testmethod void oneTestToTestThemAll() 
    {
        Test.startTest();
        User newUser = [select id,email,ManagerId,GSM_AlertOps_timestamp__C,Manager.name,Name,Manager.Profile.Name
                                        from User where alias = 'TST_USR' limit 1];
        User um = [select id,email,ManagerId,GSM_AlertOps_timestamp__C,Manager.name, Name, Manager.Profile.Name
                                        from User where alias = 'TST_MANA' limit 1];

        User newUser1 = [select id,email,ManagerId,GSM_AlertOps_timestamp__C,Manager.name,Name,Manager.Profile.Name
                                        from User where alias = 'PSales' limit 1];
        User um1 = [select id,email,ManagerId,GSM_AlertOps_timestamp__C,Manager.name, Name, Manager.Profile.Name
                                        from User where alias = 'PSalesM' limit 1];


            
        List<String> emailTemplateDevNames = GsmUtilClass.getGSMSettingValue('SalesOps_NewUserEmail_EmailTemplate').split(',');
        List<EmailTemplate> templates = [select Id, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName IN : emailTemplateDevNames Order by DeveloperName];
           
        GSM_SendEmailToSalesOpsBatchClass sendEmail = new GSM_SendEmailToSalesOpsBatchClass();
        sendEmail.execute(null);
        sendEmail.getEmailFromTemplate(newUser,um, templates[1], false);
                  
        test.stopTest();
        
        
    }
    
}