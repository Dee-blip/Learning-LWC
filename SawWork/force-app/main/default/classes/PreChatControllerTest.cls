@istest
public class PreChatControllerTest {
    static User dmlUser = new User(id=UserInfo.getUserId());
    static testMethod void preChatCtrlTestMethod(){
        System.runAs(dmlUser) {
            test.startTest();
            Account testAccount = utilTestClass.CreateAccount('testAccount');
            insert testAccount;
            Contact testContact = utilTestClass.CreateContact('test','Contact');
            testContact.AccountId = testAccount.Id;
            testContact.AKAM_Contact_ID__c = 'HHH';
            insert testContact;
            String userName = utilTestClass.getRandomString(5);
            final List<Profile> partnerProfiles = [select id,name from Profile where (Name='SFCommunityCustomers') limit 1];
            User testUser = new User(Username=''+userName+'@akamai1.com',
                        Alias = 'tst'+userName, 
                        Email=''+userName+'@akamai1.com', 
                        FirstName='John', 
                        LastName='Doe'+userName, 
                        ProfileId = partnerProfiles[0].Id, 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', 
                        EmailEncodingKey='UTF-8', 
                        TimeZoneSidKey='America/Los_Angeles',
                        AKAM_User_id__c = testContact.AKAM_Contact_ID__c,          
                        ContactId = testContact.id);
            insert testUser;
            System.runAs(testUser) {
                PreChatController ctrlInstance = new PreChatController();
                PreChatController.validateCaseId('');
            }
            test.stopTest();
        }
    }
    static testMethod void preChatCtrlTestMethod1(){
        test.startTest();
        System.runAs(dmlUser) {
            Account testAccount = utilTestClass.CreateAccount('testAccount');
            insert testAccount;
            Contact testContact = utilTestClass.CreateContact('test','Contact');
            testContact.AccountId = testAccount.Id;
            testContact.AKAM_Contact_ID__c = 'HHH';
            insert testContact;
            String userName = utilTestClass.getRandomString(5);
            Id profileId = [Select id from profile where name=: 'System Administrator'].id;
            Map <String,Schema.RecordTypeInfo> recordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id recordTypeId = recordTypes.get('AMG').getRecordTypeId();
            User testUser = new User(Username=''+userName+'@akamai1.com',
                        Alias = 'tst'+userName, 
                        Email=''+userName+'@akamai.com', 
                        FirstName='John', 
                        LastName='Doe'+userName, 
                        ProfileId = profileId, 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', 
                        EmailEncodingKey='UTF-8', 
                        TimeZoneSidKey='America/Los_Angeles',
                        AKAM_User_id__c = testContact.AKAM_Contact_ID__c);
            insert testUser;
            System.runAs(testUser) {
                PreChatController ctrlInstance = new PreChatController();
                PreChatController.validateCaseId('Test');
            }
        }
        test.stopTest();
    }
    static testMethod void preChatCtrlTestMethod2(){
        test.startTest();
        System.runAs(dmlUser) {
            Account testAccount = utilTestClass.CreateAccount('testAccount');
            insert testAccount;
            Contact testContact = utilTestClass.CreateContact('test','Contact');
            testContact.AccountId = testAccount.Id;
            testContact.AKAM_Contact_ID__c = 'HHH';
            insert testContact;
            String userName = utilTestClass.getRandomString(5);
            Id profileId = [Select id from profile where name=: 'System Administrator'].id;
            Map <String,Schema.RecordTypeInfo> recordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id recordTypeId = recordTypes.get('AMG').getRecordTypeId();
            User testUser = new User(Username=''+userName+'@akamai1.com',
                        Alias = 'tst'+userName, 
                        Email=''+userName+'@akamai.com', 
                        FirstName='John', 
                        LastName='Doe'+userName, 
                        ProfileId = profileId, 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', 
                        EmailEncodingKey='UTF-8', 
                        TimeZoneSidKey='America/Los_Angeles',
                        AKAM_User_id__c = testContact.AKAM_Contact_ID__c);
            insert testUser;
            SC_Akachat_Product_Mapping__c setting = new SC_Akachat_Product_Mapping__c();
            setting.Name = 'Product Test Class';
            setting.Skill__c = 'Web Experience';
            insert setting;
            System.runAs(testUser) {
                PreChatController ctrlInstance = new PreChatController();
                PreChatController.setAkatecAgent('Other');
                PreChatController.setAkatecAgent('Product Test Class');
            }
        }
        test.stopTest();
    }
}