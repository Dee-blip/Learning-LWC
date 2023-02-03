/*
* File Name: HD_Test_Request_Detail_Input_Test
* Description : Test class for HD_Request_Detail_Input_Lightning
* @author : 
* Modification Log ===============================================================
* Date 				Author 				Modification
*                   Nikhil Karn         changed seeAllData=false, this class is associated with  HD_Request_Detail_Input_Lightning.cls and covers 80%
* Oct 13th, 2020    Aneesh Budnar       PRTORES-1966 - HD Service Request Field Level Encryption , Team level bifurcation and data integrity
* Nov 29th, 2021    Aneesh Budnar       PRTORES-2358 - HD Code Scanner 1 fixes
*/
@isTest(seeAllData = false)
public class HD_Test_Request_Detail_Input_Test {

    public static HD_Request_Detail_Input_Lightning testClass;
    public static Map<String,Id> result;
    public static Map<String,Id> categoriesCreated;
    public static User contextUser;

    static{
        HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
        List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
        tempList.order='1';
        tempList.responseType='Text Area';
        tempList.prompt='Host Name';
        tempList.required='FALSE';
        tempList.hidden='FALSE';
        tempList.inputValuesHolder='upguard.akamai.com?upguard.akamai.com?false'; 
        tempList.runWorkflow='TRUE';

        fulfilmentInputLists.add(tempList);
        
        HD_Test_Data_Factory.init();
        categoriesCreated = HD_Test_Data_Factory.categoryMap;
        BMCServiceDesk__CategoryTypes__c categoryType = 
            new BMCServiceDesk__CategoryTypes__c(Name='Q_Corp_Sustainability');
        insert categoryType;
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = categoryType.Id, 
            BMCServiceDesk__AvailableForServiceCatalog__c = true,
            BMCServiceDesk__Display_In_SelfService__c = true,
            BMCServiceDesk__AvailableForIncidents__c = true,
            Name='Customer 1:1 Meeting Request');
        insert category;
        HD_Test_Data_Factory.categoryMap.put('Customer 1:1 Meeting Request',category.Id);
        System.debug(categoriesCreated);

        result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Compensation'),fulfilmentInputLists,'nkarn@akamai.com',true,HD_IncidentTestDataFactory.Team.HR);
        System.debug('RESULT========'+result);
    }

    @isTest(seeAllData = false) 
    public static void testMethodgetDetails(){
        
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
        	contextUser = setupTestUser('HR', 'System Administrator', true, 'HD_HR_View_Encrypted_data_permission','context.user@akamai.com');
        }
        Test.startTest();
        
        User testUser;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('Worldwide', 'System Administrator', true, 'HD_View_Encrypted_Data_HR', null);
        }
        
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;
        
        BMCServiceDesk__SRM_RequestDetail__c reqdetail = new BMCServiceDesk__SRM_RequestDetail__c();
        reqdetail.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
        reqdetail.BMCServiceDesk__FKIncident__c = incident.Id;
        reqdetail.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        reqdetail.BMCServiceDesk__DateExpected__c = Date.today(); 
        insert reqdetail;
        
        incident.BMCServiceDesk__FKClient__c=contextUser.Id;
        incident.BMCServiceDesk__FKRequestDetail__c = reqdetail.Id;
        incident.BMCServiceDesk__FKStatus__c=HD_Test_Data_Factory.statusMap.get('ASSIGNED');
        incident.OwnerId = contextUser.Id;
        UPDATE incident;
        
        
        
        //lets insert the fufillment inputs to Request Input details
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqdetInp = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
        //looping through fullfilment
        for(BMCServiceDesk__SRM_FulfillmentInputs__c fulInp : [SELECT Id, BMCServiceDesk__Prompt__c, HD_Secure_Field__c FROM BMCServiceDesk__SRM_FulfillmentInputs__c LIMIT 10] )
        {
            BMCServiceDesk__SRM_RequestDetailInputs__c reqdeinpinsertdata = new BMCServiceDesk__SRM_RequestDetailInputs__c();
            reqdeinpinsertdata.BMCServiceDesk__FKRequestDetail__c = reqdetail.id;
            reqdeinpinsertdata.BMCServiceDesk__FKFulfillmentInputs__c = fulInp.id;
            reqdeinpinsertdata.BMCServiceDesk__Input__c = fulInp.BMCServiceDesk__Prompt__c;
            //Starting encrypting text Area data
            Blob ResponseData = Blob.valueOf('Sample Text to be encrypted');
            //generating random key for for Encryption and storing it in encrypted HD_Aes_Key__c field
            Blob key = Crypto.generateAesKey(128);
            reqdeinpinsertdata.HD_Aes_Key__c =  EncodingUtil.base64Encode(key);
            //let's encrypt it the data here 
            Blob encrypted = Crypto.encryptWithManagedIV('AES128', key, ResponseData);
            //Now  Storing the encrypted data in to  the same Text Area Field
            reqdeinpinsertdata.BMCServiceDesk__Response__c = EncodingUtil.base64Encode(encrypted);
            reqdeinpinsertdata.BMCServiceDesk__StoredValue__c = EncodingUtil.base64Encode(encrypted);
            //adding the request details input to List
            reqdetInp.add(reqdeinpinsertdata);
            
        }//
        
        //insert the Request details inputs 
        insert reqdetInp;

        System.debug('UPDATED INCIDENT:'+incident);
        try {
            System.RunAs(testUser){
        		HD_Request_Detail_Input_Lightning.getDetails(incident.Id);
            }
        }
        catch(Exception ex) {
            
        }
        Test.stopTest();
    } 
    
    @isTest(seeAllData = false) 
    public static void testMethoddecryptTextAreaDataStatic(){
        
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
        	contextUser = setupTestUser('HR', 'System Administrator', true, 'HD_HR_View_Encrypted_data_permission','context.user@akamai.com');
        }
        Test.startTest();
        System.RunAs(contextUser){
            Object result1=HD_Request_Detail_Input_Lightning.decryptTextAreaDataStatic('testDecrypt','1234');
            System.assertEquals(result1,null);
        }
        Test.stopTest();
    }
    
    private static User setupTestUser(String roleName, String profileName, Boolean confidentialFlag, String psName, String userName) {
        UserRole role = [Select Id,Name from UserRole WHERE Name = :roleName];
        Profile profile = [Select Id FROM Profile WHERE Name = :profileName];
        User testUser;
        if(string.isEmpty(userName)) {
            testUser = new UserTestHelper.UserBuilder()
                .withRole(role.Id)
                .withProfile(profile.Id)
                .withConfidentialDataFlag(confidentialFlag)
                .buildAndSave();
        }
        else {
            testUser = new UserTestHelper.UserBuilder()
                .withRole(role.Id)
                .withProfile(profile.Id)
                .withUserName(userName)
                .withConfidentialDataFlag(confidentialFlag)
                .buildAndSave();
            
        }
        if(String.isNotEmpty(psName)) {
            PermissionSet ps = [Select ID,Name from PermissionSet WHERE Name = :psName];
            insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id);
        }
        return testUser;
    }
    
    private static BMCServiceDesk__Incident__c setupTestIncident(String category, String region, String recordType) {
        return new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get(category))
            .withRegion(region)
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get(recordType).getRecordTypeId())
            .build();
    }
    
    @isTest
    public static void whenDecryptCalledByUserRoleWithSharingAndNoFlagSetAndWithPSExpectNotAccessible() {
        // Given
        User testUser;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('HR', 'System Administrator', false, 'HD_View_Encrypted_Data_HR',null);
        }
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;
        
        List<BMCServiceDesk__Incident__Share> incidentSharing = new List<BMCServiceDesk__Incident__Share>{
            createSharedRecords(incident.Id, 'Edit', getGroupIdForRole(testUser.UserRoleId), 'Rule')
        };

        // Then
        System.runAs (testUser) {
        	System.assertEquals(
                false, 
                HD_Request_Detail_Input_Lightning.isAccessible(incident.Id, incidentSharing),
                'Expected value not same as actual value');
        }
    }
    
    @isTest
    public static void whenDecryptCalledByUserRoleWithSharingAndFlagSetAndNoPSExpectNotAccessible() {
        // Given
        User testUser;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('HR', 'System Administrator', true, null, null);
        }
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;
        List<BMCServiceDesk__Incident__Share> incidentSharing = new List<BMCServiceDesk__Incident__Share>{
            createSharedRecords(incident.Id, 'Edit', getGroupIdForRole(testUser.UserRoleId), 'Rule')
        };

        // Then
        System.runAs ( testUser ) {
        	System.assertEquals(false, HD_Request_Detail_Input_Lightning.isAccessible(incident.Id, incidentSharing),'Expected value not same as actual value');
        }
    }
    
    @isTest
    public static void whenDecryptCalledByUserRoleWithNoSharingAndFlagNotSetAndWithPSExpectNotAccessible() {
        // Given
        User testUser;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('HR', 'System Administrator', false, 'HD_View_Encrypted_Data_HR', null);
        }
        
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;

        // Then
        System.runAs ( testUser ) {
        	System.assertEquals(false, HD_Request_Detail_Input_Lightning.isAccessible(incident.Id, null),'Expected value not same as actual value');
        }
    }
    
    @isTest
    public static void whenDecryptCalledByUserRoleWithSharingAndFlagSetAndWithPSExpectAccessible() {
        // Given
        User testUser;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('HR', 'System Administrator', true, 'HD_View_Encrypted_Data_HR', null);
        }
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;
        
        List<BMCServiceDesk__Incident__Share> incidentSharing = new List<BMCServiceDesk__Incident__Share>{
            createSharedRecords(incident.Id, 'Edit', getGroupIdForRole(testUser.UserRoleId), 'Rule')
        };

        // Then
        System.runAs ( testUser ) {
        	System.assertEquals(true, HD_Request_Detail_Input_Lightning.isAccessible(incident.Id, incidentSharing),'Expected value not same as actual value');
        }
    }
    
    @isTest
    public static void whenDecryptCalledByUserInGroupWithSharingAndFlagSetAndWithPSExpectAccessible() {
        // Given
        User testUser;
        Group grp = new Group(Name = 'Test Sharing Group');
        insert grp;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('HR', 'System Administrator', true, 'HD_View_Encrypted_Data_HR', null);
            GroupMember member = new GroupMember(UserOrGroupId = testUser.Id, GroupId = grp.Id);
            insert member;
        }
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;
        List<BMCServiceDesk__Incident__Share> incidentSharing = new List<BMCServiceDesk__Incident__Share>{
            createSharedRecords(incident.Id, 'Edit', grp.Id, 'Regular')
        };

        // Then
        System.runAs ( testUser ) {
        	System.assertEquals(true, HD_Request_Detail_Input_Lightning.isAccessible(incident.Id, incidentSharing),'Expected value not same as actual value');
        }
    }
    
    @isTest
    public static void whenDecryptCalledByUserRoleWOSharingAndFlagSetAndWithPSExpectNotAccessible() {
        // Given
        User testUser;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('Worldwide', 'System Administrator', true, 'HD_View_Encrypted_Data_HR', null);
        }
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;
        
        UserRole hrRole = [Select Id,Name from UserRole WHERE Name = 'HR'];
        List<BMCServiceDesk__Incident__Share> incidentSharing = new List<BMCServiceDesk__Incident__Share>{
            createSharedRecords(incident.Id, 'Edit', getGroupIdForRole(hrRole.Id), 'Rule')
        };
        // Then
        System.runAs ( testUser ) {
        	System.assertEquals(false, HD_Request_Detail_Input_Lightning.isAccessible(incident.Id, incidentSharing), 'Expected value not same as actual value');
        }
    }
    
    
    @isTest
    public static void whenDecryptCalledByMultipleUserRolesWithFlagSetAndWithPSExpectAccessBasedOnRole() {
        // Given
        User wwRoleUser, hrRoleUser;
        User currentUser =[SELECT Id from User where Id = :UserInfo.getUserId()];
        System.runAs (currentUser) {
            wwRoleUser = setupTestUser('Worldwide', 'System Administrator', true, 'HD_View_Encrypted_Data_Corp_Sust', 'test.user1@akamai.com');
            hrRoleUser = setupTestUser('HR', 'System Administrator', true, 'HD_View_Encrypted_Data_HR', 'test.user2@akamai.com');
        }
        
        Test.startTest();
        BMCServiceDesk__Incident__c hrIncident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        BMCServiceDesk__Incident__c corpSustIncident = setupTestIncident('Customer 1:1 Meeting Request', 'India', 'Helpdesk');
        
        insert new List<BMCServiceDesk__Incident__c>{ hrIncident, corpSustIncident };
        Test.stopTest();
        // Then
        System.runAs ( hrRoleUser ) {
            List<BMCServiceDesk__Incident__Share> incidentSharing = new List<BMCServiceDesk__Incident__Share>{
                createSharedRecords(hrIncident.Id, 'Edit', getGroupIdForRole(hrRoleUser.UserRoleId), 'Rule')
            };
        	System.assertEquals(true, HD_Request_Detail_Input_Lightning.isAccessible(hrIncident.Id, incidentSharing), 'Expected value not same as actual value');
        }
        
        System.runAs ( hrRoleUser ) {
        	System.assertEquals(false, HD_Request_Detail_Input_Lightning.isAccessible(corpSustIncident.Id, null), 'Expected value not same as actual value');
        }
        
        System.runAs ( wwRoleUser ) {
            List<BMCServiceDesk__Incident__Share> incidentSharing = new List<BMCServiceDesk__Incident__Share>{
                createSharedRecords(corpSustIncident.Id, 'Edit', getGroupIdForRole(wwRoleUser.UserRoleId), 'Rule')
            };
        	System.assertEquals(true, HD_Request_Detail_Input_Lightning.isAccessible(corpSustIncident.Id, incidentSharing), 'Expected value not same as actual value');
        }
        
        System.runAs ( wwRoleUser ) {
        	System.assertEquals(false, HD_Request_Detail_Input_Lightning.isAccessible(hrIncident.Id, null), 'Expected value not same as actual value');
        }
    }
    
    @isTest
    public static void whenDecryptCalledWithIncidentSettingInPlaceExpectOldLogicToBeUsed() {
        // Given
        User testUser;
        System.runAs ( (User)[SELECT Id from User where Id = :UserInfo.getUserId()] ) {
            testUser = setupTestUser('Worldwide', 'System Administrator', true, 'HD_HR_View_Encrypted_data_permission', null);
        }
        BMCServiceDesk__Incident__c incident = setupTestIncident('Compensation', 'India', 'Helpdesk');
        insert incident;
        insert new HD_Incident_Settings__c(Name = 'Execute_Old_Encryption_Logic', Value__c = 'True');
        // Then
        System.runAs ( testUser ) {
        	System.assertEquals(true, HD_Request_Detail_Input_Lightning.isAccessible(incident.Id, null), 'Expected value not same as actual value');
        }
    }
    
    private static Id getGroupIdForRole(String roleId) {
        return [SELECT Id, DeveloperName, RelatedId, Type FROM Group WHERE RelatedId = :roleId AND Type = 'Role'].Id;
    }
    
    private static BMCServiceDesk__Incident__Share createSharedRecords(
        ID parentId, 
        String accessLevel, 
        Id userGrpId, 
        String rowCause) {
        return new BMCServiceDesk__Incident__Share(
            ParentId = parentId,
            AccessLevel = accessLevel,
            UserOrGroupId = userGrpId,
            RowCause = rowCause);
    }
}