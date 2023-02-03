@isTest
public class SC_AddCommunityUserToGroupsTest {

    static testmethod void createUsers(){
        
        //Create Contact
        Id AccId =[SELECT DefaultAccountIdForNewContact__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1].DefaultAccountIdForNewContact__c;
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        Profile customerProfile = [select id from profile where name='SFCommunityCustomers'][0];
        User crmOps = [select id from User where name='CRM Ops'][0];
        Account A = new Account();
        A.Name='test1234olla56';
        insert A;
        
        Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c='.akamai';
        cs.Communities_User_Account_Id__c=A.id;
        cs.Name='Community';
        cs.Self_Registration_Community_Profile_Id__c=pr.id;
        insert cs;
        
        User usr = new User(alias = 'user',isActive =true,companyName = 'Akamai Technologies,Inc.', email='salessxxtest@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usrxxxa@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
       // insert usr;
        
        List<id> userIdList = new List<id>();
        userIdList.add(usr.id);
        
        Contact C = new Contact();
        C.AccountId = A.Id;
        C.Email = 'test8dxx81ytser@akamai.com';
        C.FirstName = 'test';
        C.LastName = 'test';
        C.LinkedIn__c ='testLinkedin';
        Insert C;
        
        user u = new user();
        u.FirstName = 'xxtestxx';
        u.email = C.email;
        u.LastName = 'xxtestxx';
        u.Alias = 'xxtes';
        u.TimeZoneSidKey = 'America/Los_Angeles';
        u.ProfileId = customerProfile.id;
        u.IsActive= true;
        u.ContactId = C.id;
        u.AKAM_User_ID__c = 'tes9019o';
        u.Country = 'NA';
        u.State = 'NA';
        u.LanguageLocaleKey = 'en_US';
        u.LocaleSidKey = 'en_US';
        u.EmailEncodingKey = 'UTF-8';
        u.Username = C.email;
        u.CommunityNickname = 'xxtest';
        list<User> uList = new List<user>();
        insert usr;
        uList.add(usr);
        test.startTest();
        system.runAs(crmOps){
        	//insert u;
			SC_AddCommunityUserToGroups.isTestError = true;
            SC_AddCommunityUserToGroups.findUserType(uList);
            //SC_AddCommunityUserToGroups.sendEmailforException('error');
        }
        test.stopTest();
        
    }
    
}