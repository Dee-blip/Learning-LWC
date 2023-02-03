@isTest 
public class Annuitas_ContactUpdateBatchTestClass 
{
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            
            User oldOwner;
            User oldOwnerRSM;
            User newOwner;
            User newOwnerRSM;
            Account_Reassignment_Rule__c oldOwnerRule;
            Account_Reassignment_Rule__c newOwnerRule;
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
            PSA_Settings__c psa = new PSA_Settings__c();
            psa.Name = 'Engineering Team Email';
            psa.Value__c = 'services-engg-qa@akamai.com';
            insert psa;
            /*GSM_Settings__mdt gsm1 = new GSM_Settings__mdt();
            gsm1.DeveloperName = 'AnnuitasContactUpdateJobLimit';
            gsm1.Value__c = '200';
            insert gsm1;*/
            /* End Of Custom Setting Insertion */

            List<Territory_Mapping__c> tms = (List<Territory_Mapping__c>)new SobjectBuilder(Territory_Mapping__c.sObjectType)
                .count(5)
                .create()
                .getRecords();
            
            Profile pr = [select id from profile where name='Sales Operations'][0];
            UserRole role = [select id, Name from UserRole where name=:GsmUtilClass.getGSMSettingValue('User_Role')][0];
            List<User> userList = new List<User>();
            User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(accOldOwnerUser);
            User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(accNewOwnerUser);
            User tmUser1 = new User(alias = 'tmUser1', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member1@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(tmUser1);
            User tmUser2 = new User(alias = 'tmUser2', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member2@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(tmUser2);
            insert userList;
            
            Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name=:roleName][0].Id;
            
            // Create Old Owner User
            oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
            oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);
            newOwner = CreateUser('TST_NUSR', salesRepProfileId, roleId);
            newOwnerRSM = CreateUser('TST_NRSM', salesRepProfileId, roleId);
            insert (new User[] {oldOwner, oldOwnerRSM, newOwner, newOwnerRSM});

            User ONAUser = [SELECT Id, Name FROM User WHERE ALIAS = 'ONA'][0];
            
            Account_Reassignment_Rule__c ONAReassignmentRule = utilTestClass.CreateAccountReassignmentRule('No Owner', ONAUser.Id, 'Owner Not Assigned');
            ONAReassignmentRule.Territory_ID__c = tms[0].Id;

            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);
            rule.Territory_ID__c = tms[1].Id;

            Account_Reassignment_Rule__c oldRule = utilTestClass.CreateAccountReassignmentRule('__OldRule', accOldOwnerUser.Id, role.Name);
            oldRule.Territory_ID__c = tms[2].Id;
            
            oldOwnerRule = utilTestClass.CreateAccountReassignmentRule(oldOwner.ALIAS, oldOwner.Id, roleName);
            oldOwnerRule.Associated_User_RSM__c = oldOwnerRSM.Id;
            oldOwnerRule.Territory_ID__c = tms[3].Id;
            
            
            newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.ALIAS, newOwner.Id, roleName);
            newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
            newOwnerRule.Territory_ID__c = tms[4].Id;

            // Create rules for the users
            insert (new Account_Reassignment_Rule__c[] {ONAReassignmentRule, oldOwnerRule, newOwnerRule,rule, oldRule});
        }
    }
     private static User CreateUser(String pUsrAlias, Id profileId, Id roleId)
    {
        User newUser = new User(alias = pUsrAlias,
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8',
                                lastname=pUsrAlias,
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles',
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = profileId,
                                UserRoleId = roleId );
        return newUser;
    }

    
    static testMethod void testMethod1() 
    {
        User accOldOwnerUser,accNewOwnerUser,tmUser1,tmUser2;
            List<String> userLastNameList = new List<String>{'OldOwner','NewOwner', 'TmUser1', 'TmUser2'};
                for(User u : [select Id, lastname from User where lastname IN : userLastNameList]){
                    if(u.lastname == 'OldOwner')
                        accOldOwnerUser = u;
                    else if(u.lastname == 'NewOwner')
                        accNewOwnerUser = u;
                    else if(u.lastname == 'TmUser1')
                        tmUser1 = u;
                    else if(u.lastname == 'TmUser2')
                        tmUser2 = u;
                }
        Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId = accOldOwnerUser.Id;
            system.runAs(accOldOwnerUser){
                insert acc;
            }
        List<Contact> lstContact= new List<Contact>();
        for(Integer i=0 ;i <3;i++)
        {
            Contact con = utilTestClass.CreateContact('__ Test First'+i,'__Test Contact'+i);
            con.AccountId = acc.Id;
            lstContact.add(con);
        }
        
        insert lstContact;
        
        Lead l= utilTestClass.CreateLead();
        l.Associated_Contact__c=lstContact[0].Id;
        insert l;
        
        Test.startTest();

            Annuitas_ContactUpdateBatch obj = new Annuitas_ContactUpdateBatch();
            DataBase.executeBatch(obj); 
            
        Test.stopTest();
    }
}