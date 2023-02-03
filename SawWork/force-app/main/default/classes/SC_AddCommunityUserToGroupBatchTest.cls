@isTest
public class SC_AddCommunityUserToGroupBatchTest {
    static testmethod void TestMethod1()
    {
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT EmployeePublicGroupId__c,AddUserToGroupDayCount__c,EnableAutoAddUserToGroupTrigger__c,CustomerPublicGroupId__c,PartnerPublicGroupId__c,GuestPublicGroupId__c,AllRegisteredCollabGroupId__c, AllRegExceptGuestCollabGroupId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0]; 
        User usr = new User(alias = 'user', email='saleso111ptest@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner',companyname='Akamai', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__1111usr@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        user crmOpsUsr = [Select id from user where name='CRM Ops' limit 1];

            system.runAs(crmOpsUsr){
              Account A = new Account();
                A.Name='test123456';
                insert A;
                Contact C = new Contact();
                C.AccountId = A.Id;
                C.Email = 'test8001yt000User@gmail.com';
                C.FirstName = 'test';
                C.LastName = 'test';
                C.LinkedIn__c ='testLinkedin';
                Insert C;
            }
        Contact cont = [Select id from contact where email = 'test8001yt000User@gmail.com' limit 1];
        Profile commProfile = [select id from profile where name='SFCommunityCustomers'][0];
        User usr1 = new User(alias = 'usrrer', email='stest8001yt000User@gmail.com',emailencodingkey='UTF-8', lastname='OldOwner',companyname='Akr', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__11112wusr@akamai.com',profileid = commProfile.Id,contactid=cont.id);
        usr1.AKAM_User_ID__c = 'ABC123eeess';
        insert usr1;
        Test.startTest();
        SC_AddCommunityUserToGroupBatch obj = new SC_AddCommunityUserToGroupBatch();
        DataBase.executeBatch(obj);
        Test.stopTest();
        
    }
}