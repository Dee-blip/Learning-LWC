/*
* File Name : HD_Test_AnnouncementController
* Description : This is the test class for HD_AnnouncementController
* @author : Vaishnavi Sinha
* Modification Log ===============================================================
* Date 				 Author 			   Modification
* March 2nd, 2022    Vaishnavi Sinha       PRTORES-2354 - HD CMR Announcement module in LWC
*/

@isTest(seeAllData = false)
public class HD_Test_AnnouncementController {

    static HD_Announcement__c a1;
    static HD_Announcement__c a2;
    static HD_Announcement__c a3;

    static HD_Announcement_Features__c fa1;
    static HD_Announcement_Features__c fa2;
    static HD_Announcement_Features__c fa3;

    static User u;
    
    private static void initialize() {

        u = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();

        List<HD_Announcement__c> annList = new List<HD_Announcement__c>();
        List<HD_Announcement_Features__c> feaList = new List<HD_Announcement_Features__c>();

        a1 = new HD_Announcement__c(); 
        a1.Name = 'Announcement For Home Page';
        a1.Summary__c = 'Announcement Summary 1';
        a1.Active__c = true;
        a1.ToDate__c = Datetime.now().addDays(10);
        a1.Show_On_Page__c = 'Home Page';
        a1.App_Name__c = 'Akamai Helpdesk';
        annList.add(a1);

        a2 = new HD_Announcement__c(); 
        a2.Name = 'Announcement For Record Page';
        a2.Summary__c = 'Announcement Summary 2';
        a2.Active__c = true;
        a2.ToDate__c = Datetime.now().addDays(10);
        a2.Show_On_Page__c = 'Record Page';
        a2.App_Name__c = 'Akamai Helpdesk';
        a2.Object_Api_Name__c = 'BMCServiceDesk__Incident__c';
        annList.add(a2);

        a3 = new HD_Announcement__c(); 
        a3.Name = 'Global Announcement';
        a3.Summary__c = 'Announcement Summary 3';
        a3.Active__c = true;
        a3.ToDate__c = Datetime.now().addDays(10);
        a3.Show_On_Page__c = 'Global';
        a3.App_Name__c = 'Akamai Helpdesk';
        annList.add(a3);

        insert annList;

        fa1 = new HD_Announcement_Features__c();
        fa1.Name = 'Feature 1 for Announcement 1';
        fa1.Short_Description__c = 'Short description for fa1';
        fa1.Order__c = 1;
        fa1.Details__c = 'Description for fa1';
        fa1.Active__c = TRUE;
        fa1.HD_Announcement__c = a1.Id;
        feaList.add(fa1);

        fa2 = new HD_Announcement_Features__c();
        fa2.Name = 'Feature 2 for Announcement 1';
        fa2.Short_Description__c = 'Short description for fa2';
        fa2.Order__c = 2;
        fa2.Details__c = 'Description for fa2';
        fa2.Active__c = TRUE;
        fa2.HD_Announcement__c = a2.Id;
        feaList.add(fa2);

        fa3 = new HD_Announcement_Features__c();
        fa3.Name = 'Feature 1 for Announcement 2';
        fa3.Short_Description__c = 'Short description for fa3';
        fa3.Order__c = 1;
        fa3.Details__c = 'Description for fa3';
        fa3.Active__c = TRUE;
        fa3.HD_Announcement__c = a3.Id;
        feaList.add(fa3);

        insert feaList;

    }

    @IsTest
    static void testGetActiveGlobalAnnouncement() {
        initialize();
        HD_Announcement__c globalAnnouncement; 
        Test.startTest();
        System.runAs(u) {
            List<Id> cookieAnnouncementIds = new List<Id>();
            globalAnnouncement =  HD_AnnouncementController.getGlobalActiveAnnouncement(cookieAnnouncementIds);
        }
        Test.stopTest();
        System.assertEquals(a3.Id, globalAnnouncement.Id, 'Expected value not same as actual value');  
    }


    @IsTest
    static void testGetActiveAnnouncementInvokedForRecordPage() {
        initialize();
        HD_Announcement__c activeAnnouncement; 
        Test.startTest();
        System.runAs(u) {
            List<Id> cookieAnnouncementIds = new List<Id>();
            activeAnnouncement =  HD_AnnouncementController.getActiveAnnouncement(cookieAnnouncementIds, 'standard__recordPage', 'BMCServiceDesk__Incident__c');
        }
        Test.stopTest();
        System.assertEquals(a2.Id, activeAnnouncement.Id, 'Expected value not same as actual value');  
    }

    @IsTest
    static void testGetActiveAnnouncementInvokedForHomePage() {
        initialize();
        HD_Announcement__c activeAnnouncement;
        Test.startTest();
        System.runAs(u) {
            List<Id> cookieAnnouncementIds = new List<Id>();
            activeAnnouncement =  HD_AnnouncementController.getActiveAnnouncement(cookieAnnouncementIds, 'standard__namedPage', null);
        }
        Test.stopTest();
        System.assertEquals(a1.Id, activeAnnouncement.Id, 'Expected value not same as actual value');  
    }

    @IsTest
    static void testGetActiveAnnouncementInvokedForOtherPage() {
        initialize();
        HD_Announcement__c activeAnnouncement;
        Test.startTest();
        System.runAs(u) {
            List<Id> cookieAnnouncementIds = new List<Id>();
            activeAnnouncement =  HD_AnnouncementController.getActiveAnnouncement(cookieAnnouncementIds, 'otherPage', null);
        }
        Test.stopTest();
        System.assertEquals(null, activeAnnouncement, 'Expected value not same as actual value');  
    }

    @IsTest
    static void testGetAnnouncementFeatures() {
        initialize();
        Test.startTest();
        List<HD_Announcement_Features__c> features = HD_AnnouncementController.getAnnouncementFeatures(a1.Id);
        Test.stopTest();
        System.assertEquals(1, features.size(), 'Expected value not same as actual value');  
    }

    @IsTest
    static void testsaveUserAnnouncementWhenRecordNotPresent() {
        initialize();
        Test.startTest();
        System.runAs(u) {
            HD_AnnouncementController.saveUserAnnouncement(a1.Id, false);
        }
        Test.stopTest();
        List<HD_Announcement_User__c> uList = [SELECT Id, HD_Announcement_Id__c, User_Id__c, Last_Seen__c, Hide_Announcement__c, No_of_Times_Seen__c 
                                               FROM HD_Announcement_User__c WHERE User_Id__c= :u.Id AND HD_Announcement_Id__c = :a1.Id LIMIT 1];

        System.assertEquals(1, ulist[0].No_of_Times_Seen__c, 'Expected value not same as actual value');  
    }

    @IsTest
    static void testsaveUserAnnouncementWhenRecordIsPresent() {
        initialize();
        HD_Announcement_User__c re = new HD_Announcement_User__c();
        re.User_Id__c = u.Id;
        re.HD_Announcement_Id__c = a1.Id;
        re.Last_Seen__c = Date.today();
        insert re;

        Test.startTest();
        System.runAs(u) {
            HD_AnnouncementController.saveUserAnnouncement(a1.Id, false);
        }
        Test.stopTest();
        List<HD_Announcement_User__c> uList = [SELECT Id, HD_Announcement_Id__c, User_Id__c, Last_Seen__c, Hide_Announcement__c, No_of_Times_Seen__c 
                                               FROM HD_Announcement_User__c WHERE User_Id__c= :u.Id AND HD_Announcement_Id__c = :a1.Id LIMIT 1];

        System.assertEquals(2, ulist[0].No_of_Times_Seen__c, 'Expected value not same as actual value');  
    }
}