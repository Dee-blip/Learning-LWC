/*
* File Name: HD_Incident_TagFinder_Test
* Description : Test class for HD_Incident_TagFinder
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 				Modification
* Dec 22nd, 2021    Aneesh Budnar       PRTORES-2377 - Add Tag Incidents field to email service
*/
@isTest(SeeAllData = false)
public class HD_Incident_TagFinder_Test {
    static {
        HD_Test_Data_Factory.init();
    }
    
    @isTest
    public static void whenIncidentWithCategoryInMDTCreatedExpectTagToBeReturned() {
        BMCServiceDesk__CategoryTypes__c categoryType = [SELECT Id FROM BMCServiceDesk__CategoryTypes__c WHERE Name = 'Q_EAE_OPS'];
        BMCServiceDesk__Category__c parentCategory = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForIncidents__c = true,
            Name='DaSH Alerts');
        insert parentCategory;
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForIncidents__c = true,
            HD_Application__c = 'DASH',
            BMCServiceDesk__FKParentCategory__c = parentCategory.Id,
            Name='Test Alert');
        insert category;
        insert new Topic(Name = 'Test_Topic');
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder()
            .withCategory(category.Id)
            .buildAndSave();
        
        Test.startTest();
        List<List<Id>> topicIds = HD_Incident_TagFinder.getIncidentTags(new List<Id> {testIncident.Id});
        Test.stopTest();
        System.assert(topicIds[0].size() == 1,  'Expected value not equal to the actual');
    }
    
    @isTest
    public static void whenIncidentWithOwnerInMDTCreatedExpectTagToBeReturned() {
        BMCServiceDesk__CategoryTypes__c categoryType = [SELECT Id FROM BMCServiceDesk__CategoryTypes__c WHERE Name = 'Q_EAE_OPS'];
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForIncidents__c = true,
            HD_Application__c = 'DASH',
            Name='Test Alert');
        insert category;
        insert new Topic(Name = 'Test_Topic');
        User manager = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('Manager')
            .withUserName('test.user1@akamai.com')
            .buildAndSave();
        User client = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('Client')
            .withUserName('test.user2@akamai.com')
            .withManager(manager.Id)
            .buildAndSave();
        BMCServiceDesk__Incident__c testIncident;
        System.runAs(client) {
			testIncident = new IncidentTestHelper.IncidentBuilder()
                .withCategory(category.Id)
                .build();
            testIncident.BMCServiceDesk__Client_Manager__c = manager.Id;
            insert testIncident;
        }
        
        Test.startTest();
        List<List<Id>> topicIds = HD_Incident_TagFinder.getIncidentTags(new List<Id> {testIncident.Id});
        Test.stopTest();
        System.assert(topicIds[0].size() == 1,  'Expected value not equal to the actual');
    }
    
    @isTest
    public static void whenIncidentWithTagInEmailAlertExpectTagToBeReturned() {
        BMCServiceDesk__CategoryTypes__c categoryType = [SELECT Id FROM BMCServiceDesk__CategoryTypes__c WHERE Name = 'Q_EAE_OPS'];
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForIncidents__c = true,
            HD_Application__c = 'DASH',
            Name='Test Alert');
        insert category;
        insert new Topic(Name = 'Test_Topic1');
        insert new Topic(Name = 'Test_Topic');
        User manager = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('Manager')
            .withUserName('test.user1@akamai.com')
            .buildAndSave();
        User client = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('Client')
            .withUserName('test.user2@akamai.com')
            .withManager(manager.Id)
            .buildAndSave();
        BMCServiceDesk__Incident__c testIncident;
        System.runAs(client) {
			testIncident = new IncidentTestHelper.IncidentBuilder()
                .withCategory(category.Id)
                .build();
            testIncident.BMCServiceDesk__Client_Manager__c = manager.Id;
            testIncident.HD_ServiceRequest_FInput__c = 'Test_Topic1';
            insert testIncident;
        }
        
        Test.startTest();
        List<List<Id>> topicIds = HD_Incident_TagFinder.getIncidentTags(new List<Id> {testIncident.Id});
        Test.stopTest();
        System.assert(topicIds[0].size() == 2,  'Expected value not equal to the actual');
    }
    
    @isTest
    public static void whenIncidentWithCategoryNotInMDTCreatedExpectNoTagsToBeReturned() {
        BMCServiceDesk__CategoryTypes__c categoryType = [SELECT Id FROM BMCServiceDesk__CategoryTypes__c WHERE Name = 'Q_EAE_OPS'];
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForIncidents__c = true,
            Name ='Test Category');
        insert category;
        insert new Topic(Name = 'Test_Topic');
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder()
            .withCategory(category.Id)
            .buildAndSave();
        
        Test.startTest();
        List<List<Id>> topicIds = HD_Incident_TagFinder.getIncidentTags(new List<Id> {testIncident.Id});
        Test.stopTest();
        System.assert(topicIds[0].size() == 0,  'Expected value not equal to the actual');
    }
}