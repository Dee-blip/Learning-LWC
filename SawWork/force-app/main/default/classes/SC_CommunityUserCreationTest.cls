@IsTest
public Class SC_CommunityUserCreationTest
{
    static testmethod void TestMethod1()
    {
        //Create Contact
        Id AccId =[SELECT DefaultAccountIdForNewContact__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1].DefaultAccountIdForNewContact__c;
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        
        Account A = new Account();
        A.Name='test123456';
        //A.isPartner=true;
        insert A;
        
        Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c='.akamai';
        cs.Communities_User_Account_Id__c=A.id;
        cs.Name='Community';
        cs.Self_Registration_Community_Profile_Id__c=pr.id;
        insert cs;
        
        User usr = new User(alias = 'user', email='salesoptest@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        
        List<id> userIdList = new List<id>();
        userIdList.add(usr.id);
        Contact C = new Contact();
        C.AccountId = AccId;
        C.Email = 'test878781yt000User@akamai.com';
        C.FirstName = 'test';
        C.LastName = 'test';
        C.LinkedIn__c ='testLinkedin';
        Insert C;
        
        Contact C1 = new Contact();
        C1.AccountId = AccId;
        C1.Email = 'test87yt000User@akamai.com';
        C1.FirstName = 'test';
        C1.LastName = 'te';
        C1.LinkedIn__c ='testLinkedin';
        Insert C1;
        
        //Calling the Method
        Test.StartTest();
        SC_CommunityUserCreation.createCommunityPortalUser('test878781yt000User@akamai.com');
        SC_CommunityUserCreation.resetUserPasswordAndSendEmail(userIdList,true);
        SC_CommunityUserCreation.sendEmailForError('Subject','Body');
        Test.StopTest(); 
    }  
}