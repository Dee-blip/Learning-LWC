/*
* File Name: HD_Test_Self_Service_Redifect_Controller
* Description : Test class for HD_Self_Service_Redifect_Controller
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* Mar 23rd, 2022     Aneesh Budnar        PRTORES-2483 - HD Lightning UI page redirect for controlling the SelfService URL for aloha
*/
@isTest
public class HD_Test_Self_Service_Redifect_Controller {
	@isTest
    public static void whenRedirectionRequestByAUserNameExpectValidURLIsReturned() {
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User')
            .withUserName('testuser@akamai.com.p2rdemo')
            .buildAndSave();
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Order__c = 3 AND Environment__c = 'p2rdemo'];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }
    
    @isTest
    public static void whenRedirectionRequestByAUserWithPSExpectValidURLIsReturned() {
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('PS')
            .withLastName('User')
            .withUserName('psuser@akamai.com.p2rdemo')
            .buildAndSave();
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'HD_View_New_LWC_UI'];
		insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id);
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Order__c = 4 AND Environment__c = 'p2rdemo'];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }   
    
    @isTest
    public static void whenRedirectionRequestByAUserWithProfileExpectValidURLIsReturned() {
        Id profileId = [SELECT Id FROM Profile WHERE Name = 'ServiceDesk Staff'].Id;
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('Profile')
            .withLastName('User')
            .withUserName('profileuser@akamai.com.p2rdemo')
            .withProfile(profileId)
            .buildAndSave();
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Order__c = 5 AND Environment__c = 'p2rdemo'];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }   
    
    @isTest
    public static void whenRedirectionRequestByAUserWithRoleExpectValidURLIsReturned() {
        Id roleId = [SELECT Id FROM UserRole WHERE Name = 'EIS Staff User'].Id;
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('User')
            .withLastName('Role')
            .withUserName('userrole@akamai.com.p2rdemo')
            .withRole(roleId)
            .buildAndSave();
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Order__c = 6 AND Environment__c = 'p2rdemo'];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }
    
    @isTest
    public static void whenRedirectionRequestByAUserInGroupExpectValidURLIsReturned() {
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('User')
            .withLastName('InGroup')
            .withUserName('useringroup@akamai.com.p2rdemo')
            .buildAndSave();
		Group grp = new Group(Name = 'Test Group');
        insert grp;
        insert new GroupMember(GroupId = grp.Id, UserOrGroupId = testUser.Id);
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Order__c = 7 AND Environment__c = 'p2rdemo'];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }
    
    @isTest
    public static void whenRedirectionRequestByAUserWithNoMatchExpectDefaultIsReturned() {
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('No')
            .withLastName('Match')
            .withUserName('nomatch@akamai.com.p2rdemo')
            .buildAndSave();
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Order__c = 8 AND Environment__c = 'p2rdemo'];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }
    
    @isTest
    public static void whenRedirectionRequestByAUserWithNoEnvExpectDefaultIsReturned() {
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('No')
            .withLastName('Environment')
            .withUserName('noenvironment@akamai.com')
            .buildAndSave();
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Environment__c = ''];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }
    
    @isTest
    public static void whenRedirectionRequestByAUserWithStrictDenyExpectDefaultIsReturned() {
        User testUser = new UserTestHelper.UserBuilder()
            .withFirstName('Strict')
            .withLastName('Deny')
            .withUserName('strictdeny@akamai.com.p2rdemo')
            .buildAndSave();
        Test.startTest();
        String redirectURL = '';
        System.runAs(testUser) {
			redirectURL = HD_Self_Service_Redifect_Controller.getRedirectURL();
        }
        Test.stopTest();
        HD_Self_Service_Redirect__mdt setting = [SELECT Id, Order__c, Redirect_URL__c FROM HD_Self_Service_Redirect__mdt WHERE Order__c = 8 AND Environment__c = 'p2rdemo'];
        System.assertEquals(setting.Redirect_URL__c, redirectURL);
    }
}