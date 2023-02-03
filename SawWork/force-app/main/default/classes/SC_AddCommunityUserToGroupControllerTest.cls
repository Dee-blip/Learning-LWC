@isTest(seeAllData = false)
public class SC_AddCommunityUserToGroupControllerTest {
    @testSetup
    static void setupMethod()
    {
        Profile sfProfile = [select id from profile where name='Support - Tech Support Manager'][0];
        
        //Create Account
        Account testAccount = new Account();
        testAccount.Name = 'test1234567yej';
        insert testAccount;
        
        //Create Community
        Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c='.akamai';
        cs.Communities_User_Account_Id__c=testAccount.id;
        cs.Name='Community';
        cs.Self_Registration_Community_Profile_Id__c=sfProfile.id;
        insert cs;
        
        //Create Contact
        Contact testContact = new Contact();
        testContact.LastName = 'Last';
        testContact.AKAM_Contact_Id__c = 'ABC123';
        testContact.AccountId = testAccount.id;
        testContact.email = 'testtestjgiur83@akamai.com';
        testContact.Active_Portal_Login__c = true;
        testContact.Validation_Override__c = true;
        insert testContact;
        
        Contact testContactPortal = new Contact();
        testContactPortal.LastName = 'Last123';
        testContactPortal.AKAM_Contact_Id__c = 'ABC1234';
        testContactPortal.AccountId = testAccount.id;
        testContactPortal.email = 'testtestjgiur8345@akamai.com';
        testContactPortal.Active_Portal_Login__c = true;
        testContactPortal.Validation_Override__c = true;
        insert testContactPortal;
        
        
        
    }
    
    @isTest
    public static void testAddUserToGroup()
    {
		Profile sfProfile = [select id from profile where name='Support - Tech Support Manager'][0];
        
        User testUsr = new User(alias = 'user',CompanyName = 'Akamai', email='salesoptest75xv8rj@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = sfProfile.Id);
        testUsr.AKAM_User_ID__c = 'ABC123';
        insert testUsr;
        
        List<User> userList = new List<User>();
     	userList = [Select id,contactId,profile.Name,profileId,companyName,email,Profile.UserLicense.Name from user where email = 'salesoptest75xv8rj@akamai.com'];
        
        CollaborationGroup testCollGroup = new CollaborationGroup();
        testCollGroup.Name='My Group in Testing';
        testCollGroup.CollaborationType='Public'; //can be 'Public' or 'Private'                   
        //insert testCollGroup;
        
        CollaborationGroupMember testCollGroupMem =  new CollaborationGroupMember();
        testCollGroupMem.CollaborationGroupId = testCollGroup.Id;
        testCollGroupMem.MemberId = userList[0].Id;
        //insert testCollGroupMem;
        
        Group testGroup = new Group();
        testGroup.Name = 'Test Group';
        //insert testGroup;
        
        GroupMember gm = new GroupMember();
        gm.GroupId = testGroup.Id;
        gm.UserOrGroupId = userList[0].id;
        //insert gm;
        
        test.startTest();
        SC_AddCommunityUserToGroupController ctrlInstance = new SC_AddCommunityUserToGroupController();
        ctrlInstance.errorMsg='Error-Please Ignore ';
        ctrlInstance.addUserToGroup(userList);
        test.stopTest();
    }
    
    @isTest
    public static void testAddCustomerUserToGroup()
    {
        Profile custProfile = [select id from profile where name='SFCommunityCustomers'][0];
        
        Contact testContact = [Select id from Contact where email = 'testtestjgiur83@akamai.com' limit 1];
        
        User customerUsr = new User(contactId = testContact.id, alias = 'user23',CompanyName = 'Micro', email='salesoptest175xv8rj@micro.com',emailencodingkey='UTF-8', lastname='OldOwner1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usrcust@akamai.com',profileid = custProfile.Id);
        customerUsr.AKAM_User_ID__c = 'ABCsd12345';
        insert customerUsr;
        
        List<User> userList = new List<User>();
     	userList = [Select id,contactId,profile.Name,profileId,companyName,email,Profile.UserLicense.Name from user where email = 'salesoptest175xv8rj@micro.com'];
       
        test.startTest();
        SC_AddCommunityUserToGroupController ctrlInstance = new SC_AddCommunityUserToGroupController();
        ctrlInstance.errorMsg='Error-Please Ignore ';
        ctrlInstance.addUserToGroup(userList);
        test.stopTest();
    }
    
    @isTest
    public static void testAddPartnerUserToGroup()
    {
        Profile partProfile = [select id from profile where name='SFCommunityPartners'][0];
        
        Contact testContactPortal = [Select id from Contact where email = 'testtestjgiur8345@akamai.com' limit 1];

        User partnerUsr = new User(contactId = testContactPortal.id, alias = 'user234',CompanyName = 'Micro1', email='salesopt32est75xv8rj@micro.com',emailencodingkey='UTF-8', lastname='OldOwner12', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usrport@akamai.com',profileid = partProfile.Id);
        partnerUsr.AKAM_User_ID__c = 'ABCsd1234545';
        insert partnerUsr;

        List<User> userList = new List<User>();
     	userList = [Select id,contactId,profile.Name,profileId,companyName,email,Profile.UserLicense.Name from user where email = 'salesopt32est75xv8rj@micro.com'];
       
        SC_AddCommunityUserToGroupController ctrlInstance = new SC_AddCommunityUserToGroupController();
        ctrlInstance.errorMsg='Error-Please Ignore ';
        ctrlInstance.isTestError = true;
        ctrlInstance.addUserToGroup(userList);
    }
}