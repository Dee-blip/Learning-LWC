/**
 * Created by jrathod on 12/23/21.
 */

@IsTest
private class SC_FeedItemTriggerHandlerTest {

    @TestSetup
    static void testSetup(){
        Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Direct - Active');
        insert accRec;
        //Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',AKAM_Contact_ID__c ='test-222', Email = 'external@example.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = false, Primary_Contact_Method__c = 'Phone');
        //insert conRec;
    }

    @IsTest
    static void test_validateTaggedUsers_ExternalUser() {
        /*
        Profile internalUserProf = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile externalUserProf = [SELECT Id FROM Profile WHERE Name = 'Customer Community Login User' LIMIT 1];
        UserRole role = [SELECT Id FROM UserRole WHERE Name='Worldwide'];
        Contact conRec = [SELECT Id FROM Contact WHERE AKAM_Contact_ID__c = 'test-222' LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        User internalUser = new User(
                FirstName = 'Internal',
                LastName = 'User',
                Username = 'internaluser@akamai.com',
                Email = 'internaluser@akamai.com',
                Alias = 'intuser',
                EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Los_Angeles',
                ProfileId = internalUserProf.Id,
                UserRoleId = role.Id
        );

        User externalUser = new User(
                FirstName = 'Internal',
                LastName = 'User',
                Username = 'external@example.com',
                Email = 'external@example.com',
                Alias = 'intuser',
                EmailEncodingKey='UTF-8',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Los_Angeles',
                ProfileId = externalUserProf.Id,
                ContactId = conRec.Id
        );
        insert new List<User>{
                internalUser,
                externalUser
        };*/

        Account acc = [SELECT Id FROM Account LIMIT 1];


        FeedItem aFeedItem = new FeedItem();
        aFeedItem.Body = 'Post body 1';
        aFeedItem.Title = 'New Title';
        aFeedItem.ParentId = acc.Id;
        insert aFeedItem;

        Map<Id,FeedItem> feedItemMap = new Map<Id, FeedItem>();
        feedItemMap.put(aFeedItem.Id,aFeedItem);

        SC_FeedItemTriggerHandler.validateTaggedUsers(feedItemMap);


    }
}