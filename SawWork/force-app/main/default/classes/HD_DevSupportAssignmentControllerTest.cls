/*
* File Name: HD_DevSupportAssignmentControllerTest
* Description : Test class for HD_DevSupportAssignmentController
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 				Modification
* Sep 09th, 2020    Aneesh Budnar       PRTORES-1915 - Incident details page - Technical tire support_disable Update Record button till the fields are loaded
*/
@isTest
public class HD_DevSupportAssignmentControllerTest {
    static {
        HD_Test_Data_Factory.init();
    }
    
	@isTest
    public static void when_GetUserCalledWithId_Expect_UserIsReturned() {
        User testUser = new UserTestHelper.UserBuilder().buildAndSave();
        Test.startTest();
        User expectedUser = HD_DevSupportAssignmentController.getUser(testUser.Id);
        Test.stopTest();
        System.assert(testUser.Id == expectedUser.Id, 'Expected value not equal to the actual');
    }
    
    @isTest
    public static void when_IncidentCategoryIsInTheSettings_Expect_TrueToBeReturned() {
        BMCServiceDesk__CategoryTypes__c categoryType = 
            new BMCServiceDesk__CategoryTypes__c(Name='Q_ITOC_Win');
        insert categoryType;
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForIncidents__c = true,
            Name='Windows Server OS Firewall Request');
        insert category;
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder()
            .withCategory(category.Id)
            .buildAndSave();

        Test.startTest();
        Boolean isSendEmail = HD_DevSupportAssignmentController.shouldSendEmail(testIncident.Id);
        Test.stopTest();
        
        System.assert(isSendEmail == true,  'Expected value not equal to the actual');
    }
    
    @isTest
    public static void when_IncidentCategoryNotInTheSettings_Expect_FalseToBeReturned() {
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder()
            .buildAndSave();

        Test.startTest();
        Boolean isSendEmail = HD_DevSupportAssignmentController.shouldSendEmail(testIncident.Id);
        Test.stopTest();
        
        System.assert(isSendEmail == false,  'Expected value not equal to the actual');
    }
}