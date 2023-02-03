/*
* File Name: HD_Test_IncidentDetailControllerTest
* Description : Test class for HD_IncidentDetailController
* @author :
* Modification Log ===============================================================
* Date 				Author 					Modification
* Dec 12th, 2019	Aneesh Budnar			PRTORES - 1518 - Added from addresses to the From Dropdown by reading from Email conversion settings
* Dec 29th, 2021	Aneesh Budnar		    PRTORES - 2381 - HD Task closure on Closing of incidents
*/
@isTest(SeeAllData=false)
public class HD_Test_IncidentDetailControllerTest {
    static BMCServiceDesk__Incident__c testIncident;
    static Map<String,BMCServiceDesk__Status__c> statusListMap = new Map<String,BMCServiceDesk__Status__c>() ;
    static ID testCategory;
    static Group testQueue;
    static BMCServiceDesk__Incident__c testIncidentForResume;
    static BMCServiceDesk__Incident__c testIncidentForPendingStatus;

    static{

        HD_IncidentTestDataFactory  obj = new HD_IncidentTestDataFactory();
        
        System.runAs((User)[SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1]) {
   	 		testIncident = obj.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
        }
        testQueue = [Select Id, Name from Group g where g.Id IN (SELECT QueueId FROM QueueSobject where SobjectType = 'BMCServiceDesk__Incident__c') and name like '%ITOC%' LIMIT 1];
    	testCategory = (ID)HD_Test_Data_Factory.categoryMap.get('Hardware');
        testIncidentForResume = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        testIncidentForPendingStatus = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);

    }

    //Test Case 1: getTicketDetails- positive
    static TestMethod void testGetTicketDetails(){
        BMCServiceDesk__Incident__c inc = [Select Id,Name, BMCServiceDesk__Type__c, Owner.name,BMCServiceDesk__incidentResolution__c,BMCServiceDesk__incidentDescription__c,BMCServiceDesk__FKClient__r.username  from BMCServiceDesk__Incident__c where Id =:testIncident.Id][0];
        HD_IncidentDetailController.Data result= HD_IncidentDetailController.getTicketDetails(testIncident.Id);
        System.assertNotEquals(null, result, 'Result is null');
        System.assertEquals(inc.Name, result.name);
        System.assertEquals(inc.BMCServiceDesk__Type__c, result.type);
        System.assertEquals(inc.Owner.name, result.owner);
        System.assertEquals(inc.BMCServiceDesk__incidentResolution__c, result.resolution);
        System.assertEquals(inc.BMCServiceDesk__incidentDescription__c, result.summary);
        System.assertEquals(inc.BMCServiceDesk__FKClient__r.username, result.username);
    }

    //getClientInfo- positive
    static TestMethod void testGetClientInfo(){
        Map<String,String> clientResult = HD_IncidentDetailController.getClientInfo(testIncident.Id);
        System.assertNotEquals(null, clientResult, 'Client Info is null');
    }

    //update owner - positive
    static TestMethod void testUpdateOwner(){
        System.runAs((User)[SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1]) {
            BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.updateOwner(testIncident.Id, System.UserInfo.getUserId()); //pass a valid queue/owner id
            System.assertEquals(System.UserInfo.getUserId(), incResult.OwnerId); //change this accordingly
        }
    }

    //update owner - null owner id
    static TestMethod void testUpdateOwnerNullId(){
        try{
            System.runAs((User)[SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1]) {
                BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.updateOwner(testIncident.Id, null); //pass a valid queue/owner id
                System.assertEquals(System.UserInfo.getUserId(), incResult.OwnerId);
            }
        }
        catch(Exception e){
            System.debug('Exception occurred');
        }
    }

    //add resolution - positive
    /*static TestMethod void testAddResolution(){
        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.addResolution(testIncident.Id, 'test resolution', '00:15');
        System.assertEquals('test resolution', incResult.BMCServiceDesk__incidentResolution__c);
        System.assertEquals('00:15', incResult.Effort_Estimation__c);
    }*/

    //add resolution - invalid effort estimate
    static TestMethod void testAddResolutionInvalidEffort(){
        try{
        	BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.addResolution(testIncident.Id, 'test resolution', '100', 'false');
        }
        catch(Exception e){
            System.debug('Exception caught');
        }
        //check what to assert
        //System.assertEquals('test resolution', incResult.BMCServiceDesk__incidentResolution__c);
        //System.assertEquals('00:15', incResult.Effort_Estimation__c);
    }

    //close incident - positive
    static TestMethod void testCloseIncident(){

        Test.startTest();
        try{
            //assign owner to incident
            testIncident.OwnerId = System.UserInfo.getUserId();
            update testIncident;
        	BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.closeIncident(testIncident.Id, 'test resolution', '00:15');
            System.assertEquals('test resolution', incResult.BMCServiceDesk__incidentResolution__c);
        	System.assertEquals('00:15', incResult.Effort_Estimation__c);
        	System.assertEquals(statusListMap.get('CLOSED').Id , incResult.BMCServiceDesk__FKStatus__c);
        }
        catch(Exception e){

        }
        Test.stopTest();

    }

    //transfer incident - positive
    static TestMethod void testTransferIncident(){
        Test.startTest();
        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.transferIncident(testIncident.Id, testQueue.Id, '00:10', 'Test Transfer', testCategory);
        System.assertEquals(testQueue.Id, incResult.OwnerId);
        Test.stopTest();
        //System.assertEquals('catId', incResult.BMCServiceDesk__FKCategory__c);
    }

    //testClass for convertIncidentToSysAdminIncident method
    //@author: Nikhil Karn
    //@date: 10/01/2018
    static TestMethod void testConvertIncidentToSysAdminIncident(){

        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.convertIncidentToSysAdminIncident(testIncident.Id, true, true,true,true,true,true);
        System.assertEquals(true, incResult.HD_System_Admin_Incident__c);
        System.assertEquals(true, incResult.Notify_dl_sysadmin_on_creation__c);
        System.assertEquals(true, incResult.HD_Notify_DL_EIS_on_Notes_Update__c);
        System.assertEquals(true, incResult.Notify_dl_sysadmin_on_status_change__c);
        System.assertEquals(true, incResult.HD_WhiteHat_Incident__c);
    }

    //get all queues- positive
    static TestMethod void testGetAllQueues(){
        Map<String,Id> queueList = HD_IncidentDetailController.getAllQueues();
        System.assertNotEquals(null, queueList,'Queue list is null');
    }

    //get all staff- positive
    static TestMethod void testGetAllStaffs(){
        List<User> staffList = HD_IncidentDetailController.getAllStaffs();
        System.assertNotEquals(null, staffList,'Staff list is null');
    }

    //get all categories- positive
    static TestMethod void testGetAllCategories(){
        Map<String,Id> catList = HD_IncidentDetailController.getAllCategories();
        System.assertNotEquals(null, catList,'Catgeory list is null');
    }

    //update cc text- positive
    static TestMethod void testUpdateCCText(){
        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.updateCCText(testIncident.Id, 'test1@akamai.com;test2@akamai.com;');
        System.assertEquals('test1@akamai.com;test2@akamai.com;', incResult.CCText__c);
    }

    //change category- positive
    static TestMethod void testChangeCategory(){
        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.changeCategory(testIncident.Id, testIncident.BMCServiceDesk__FKCategory__c);
        System.assertEquals(testIncident.BMCServiceDesk__FKCategory__c, incResult.BMCServiceDesk__FKCategory__c);
    }

    //change priority- value = 1
    static TestMethod void testChangePriority1(){
        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.changePriority(testIncident.Id, '1', true);
        System.assertEquals('1', incResult.HD_Ticket_Priority__c);
        System.assertEquals(true, incResult.HD_High_Customer_Impact__c);
    }

    //change priority- value <> 1
    static TestMethod void testChangePriority(){
        //first check existing priority
        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.changePriority(testIncident.Id, '2', true);
        System.assertEquals('2', incResult.HD_Ticket_Priority__c);
        System.assertEquals(false, incResult.HD_High_Customer_Impact__c);
    }

    //get page support- positive
    static TestMethod void testGetPageSupport(){
        Boolean pageSupportValue = HD_IncidentDetailController.getPageSupport(testIncident.Id);
        System.assertEquals(testIncident.HD_High_Customer_Impact__c, pageSupportValue);
    }

    //get incident records- positive

    static TestMethod void testGetIncidentRecords(){
        BMCServiceDesk__Incident__c testIncident2 = [Select Id, Name,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Client_Name__c,BMCServiceDesk__Status_ID__c from BMCServiceDesk__Incident__c LIMIT 1];
        List<BMCServiceDesk__Incident__c> incResult = HD_IncidentDetailController.getIncidentRecords(testIncident.Id, testIncident2.Name);
        System.assertEquals(testIncident2, incResult[0]);
    }


    //get incident records- null ticket number
	static TestMethod void testGetIncidentRecordsNullTicketNumber(){
        try{
        	List<BMCServiceDesk__Incident__c> incResult = HD_IncidentDetailController.getIncidentRecords(testIncident.Id, null);
        }
        catch(Exception e){
            System.debug('Exception in testGetIncidentRecordsNullTicketNumber');
        }
        //System.assertEquals(testIncident, incResult[0]); check for assert
    }

    //get incident type- positive
    static TestMethod void testGetIncType(){
        BMCServiceDesk__Incident__c inc = [Select Id, BMCServiceDesk__Type__c from BMCServiceDesk__Incident__c where Id =:testIncident.Id][0];
        String incType =  HD_IncidentDetailController.getIncType(testIncident.Id);
        System.assertEquals(inc.BMCServiceDesk__Type__c, incType);
    }

    //hold ticket- positive
    static TestMethod void testHoldTicket(){
        try{
        	Id holdStatusId = statusListMap.get('ON HOLD').Id;
        	BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.holdTicket(testIncident.Id, 'ON HOLD', 'Holding');
        	System.assertEquals(holdStatusId, incResult.BMCServiceDesk__FKStatus__c);
        }
        catch(Exception e){
            System.debug('Exception in testHoldTicket');
        }
    }

    //add client note- positive
    static TestMethod void testAddClientNote(){
        //insert(new BMCServiceDesk__Action__c(name='Client Note',BMCServiceDesk__Abbreviation__c  = 'CLIENT_NOTE'));
        Id clientNoteId = HD_IncidentDetailController.addClientNote(testIncident.Id, 'Test Client Note');
        System.assertNotEquals(null, clientNoteId, 'Client Note is null');
    }

    //get email templates- positive
    static TestMethod void testGetEmailTemplates(){
        List<EmailTemplate> templateList = HD_IncidentDetailController.getEmailTemplates();
        System.assertNotEquals(null, templateList, 'Email Template list is null');
    }
    static testMethod void testGetIncident(){
        BMCServiceDesk__Incident__c inc = [select id, BMCServiceDesk__Category_ID__c from BMCServiceDesk__Incident__c limit 1];
        //inc.BMCServiceDesk__FKClient__r.
        Test.startTest();

        BMCServiceDesk__Incident__c returnedIncident = HD_IncidentDetailController.getIncident(inc.id);
        //assert the returned Incident has the same category Id
        System.assertEquals(inc.BMCServiceDesk__Category_ID__c, returnedIncident.BMCServiceDesk__Category_ID__c);

        Test.stopTest();
    }


    static testMethod void testAllApprovers(){
        Test.startTest();
        List<User> allAppr =  HD_IncidentDetailController.allApproversSearch('pra');
        System.assert(allAppr.size() > 0);
        Test.stopTest();
    }

    static testMethod void testAddChangeApprover(){

        ManagedPkgErrorClass.isFromManagedPackage = false;

        //BMCServiceDesk__Incident__c inc = [select id, BMCServiceDesk__Category_ID__c, Approver__c from BMCServiceDesk__Incident__c where
        //                                   BMCServiceDesk__Status_ID__c ='UNASSIGNED' limit 1];
        //test for addChangeApprover
        User approver = [select id,name from User where isActive=true limit 1 ];


        Test.startTest();
        //test getALl approvers
        BMCServiceDesk__Incident__c updatedIncident = [select id, BMCServiceDesk__Category_ID__c,HD_Owner_user_queue__c ,Approver__c from BMCServiceDesk__Incident__c where
                                           	id = :testIncident.Id limit 1];
        System.debug('BMCServiceDesk__Category_ID__c'+updatedIncident.HD_Owner_user_queue__c);
        HD_IncidentDetailController.addChangeApprover(testIncident.id,approver.id);
        BMCServiceDesk__Incident__c incAprr = HD_IncidentDetailController.getCurrentApprover(testIncident.id);
        updatedIncident = [select id, BMCServiceDesk__Category_ID__c, Approver__c from BMCServiceDesk__Incident__c where
                                           	id = :testIncident.Id limit 1];
        System.assertEquals(approver.Id, updatedIncident.Approver__c);
        System.assertEquals(approver.Id,incAprr.Approver__c);


        Test.stopTest();

    }



    static testMethod void testApprovalSubmission(){
        ManagedPkgErrorClass.isFromManagedPackage = false;

        User approver = [select id,name from User where isActive=true limit 1 ];
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();

        System.runAs((User)[SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1]) {
            inc = testIncident;
            inc.OwnerId = System.UserInfo.getUserId();
            inc.Approver__c = approver.id;
            update inc;
        }
        //test for addChangeApprover
        //User approver = [select id,name from User where isActive=true limit 1 ];
        //inc.Approver__c = approver.id;
        //update inc;
        Test.startTest();
        String result = HD_IncidentDetailController.submitForApproval(inc.id,'test Message');
        System.assertEquals('isSuccess', result);
        result = HD_IncidentDetailController.submitForApproval(inc.id,'test Message');

        System.assertNotEquals('isSuccess', result);// as it is already submitted for approval
        HD_IncidentDetailController.recallForApproval(inc.id, 'test comment for recall');
        Test.stopTest();

    }
    /*
    static testMethod void testReopenNonCorporateIT(){
        BMCServiceDesk__Incident__C inc = [select id, BMCserviceDesk__FKCategory__r.BMCServiceDesk__parentTree__c from BMCServiceDesk__incident__c where
                                           BMCserviceDesk__FKCategory__r.BMCServiceDesk__parentTree__c like '%Enterprise Application%'
                                          and BMCserviceDesk__FKCategory__r.BMCServiceDesk__AvailableForIncidents__c  =true
                                           and BMCserviceDesk__FKCategory__r.BMCServiceDesk__inactive__c  = false
                                           and BMCServiceDesk__Status_ID__c  = 'CLOSED'
                                           order by createdDate desc limit 1];

        ManagedPkgErrorClass.isFromManagedPackage = false;
        Test.startTest();
        HD_IncidentDetailController.reopenTicket(inc.Id);
        BMCServiceDesk__Incident__C updatedIncident = [select id, BMCServiceDesk__Status_ID__c from BMCServiceDesk__incident__c where
                                                       id = :inc.Id];
        System.assertEquals('ASSIGNED', updatedIncident.BMCServiceDesk__Status_ID__c);
        Test.stopTest();

    }
*/

    static testMethod void testReopenCorporateIT(){

        System.runAs((User)[SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1]) {
        	HD_IncidentDetailController.updateOwner(testIncident.Id,null);
        }
        Test.startTest();
        BMCServiceDesk__Incident__C debugInc = [select HD_Incident_Group__c, HD_Parent_Tree__c, BMCServiceDesk__FKCategory__r.Name, BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.name  from BMCServiceDesk__Incident__C where id =:testIncident.Id limit 1  ];
        System.debug('pranav debug ' +debugInc.HD_Incident_Group__c);
        System.debug('pranav debug ' +debugInc.HD_Parent_Tree__c);
        System.debug('pranav debug ' +debugInc.BMCServiceDesk__FKCategory__r.Name);
        System.debug('pranav debug ' +debugInc.BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.name);
        //BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKParentCategory__r.name
        System.debug(debugInc);
        HD_IncidentDetailController.addResolution(testIncident.Id, 'test resolution', '00:11', 'false');
        HD_IncidentDetailController.reopenTicket(testIncident.Id);
        BMCServiceDesk__Incident__C updatedIncident = [select id, BMCServiceDesk__Status_ID__c from BMCServiceDesk__incident__c where
                                                       id = :testIncident.Id];
        System.assertEquals('REOPENED', updatedIncident.BMCServiceDesk__Status_ID__c);
        Test.stopTest();

    }

    //getIncidentDetailsForPrint- positive
    static TestMethod void testGetgetIncidentDetailsForPrint(){
        BMCServiceDesk__Incident__c inc = [Select Id,Name, BMCServiceDesk__Type__c, Owner.name,BMCServiceDesk__incidentResolution__c,BMCServiceDesk__incidentDescription__c,BMCServiceDesk__FKClient__r.username  from BMCServiceDesk__Incident__c where Id =:testIncident.Id][0];
        BMCServiceDesk__Incident__c result= HD_IncidentDetailController.getIncidentDeatilsForPrint(testIncident.Id);
        System.assertNotEquals(null, result, 'Result is null');
        System.assertEquals(inc.Name, result.Name);
        System.assertEquals(inc.BMCServiceDesk__Type__c, result.BMCServiceDesk__Type__c);
        System.assertEquals(inc.BMCServiceDesk__incidentResolution__c, result.BMCServiceDesk__incidentResolution__c);
        System.assertEquals(inc.BMCServiceDesk__incidentDescription__c, result.BMCServiceDesk__incidentDescription__c);
        System.assertEquals(inc.BMCServiceDesk__FKClient__r.username, result.BMCServiceDesk__FKClient__r.username);
    }

    static TestMethod void testsaveActionNote(){
        insert(new HD_Incident_Settings__c(Name = 'Missing_Actions_Update',value__c = 'Email Sent'));
        //insert(new BMCServiceDesk__Action__c(name='Internal Note',BMCServiceDesk__Abbreviation__c  = 'INTERNAL_NOTE'));
        HD_IncidentDetailController.getHost();
        HD_IncidentDetailController.getURL();
        ManagedPkgErrorClass.isFromManagedPackage = false;
        test.startTest();
        String result = HD_IncidentDetailController.saveActionNote(testIncident.id,'test','00:14');
        test.stopTest();
    }

    /*static testMethod void testLinkIncidents(){
        BMCServiceDesk__Incident__C inc1 = testIncident;
        BMCServiceDesk__Incident__C inc2 = testIncident;
        inc2.id=null;
        insert inc2;
        List<Id> incIds = new List<Id>();
        incIds.add(inc2.Id);
        Test.startTest();
        HD_IncidentDetailController.linkIncidents2(inc1.id, incIds);
        Test.stopTest();
    }*/

    /*static TestMethod void testSendMail(){

        //get email templates
        List<EmailTemplate> templates = HD_IncidentDetailController.getEmailTemplates();


        ManagedPkgErrorClass.isFromManagedPackage = false;
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc = testIncident;
        //String[] toAddresses,String[] ccAddresses,String[] bccAddresses,String templateId,String subject,String body,List<String> fileData
        String[] toAddresses = new String[]{'pprashan@akamai.com'};
        String[] ccAddresses = new String[]{'pprashan@akamai.com'};
        String[] bccAddresses = new String[]{'pprashan@akamai.com'};
        String templateId = null;
        String subject = 'test';
        String body = 'test';
        List<String> fileData = new List<String>();

        fileData.add('{\"fileName\":\"EntCatQA.csv\",\"fileType\":\"text/csv\",\"fileContents\":\"SWQsUkFfQ2F0ZWdvcnlfR3JvdXBfX2MNCmE1OEcwMDAwMDAwTDJORSxSRVNUUklDVEVEIFBBUkVOVA%3D%3D\"}');

        Test.startTest();
        try{
            HD_IncidentDetailController.sendEmail(inc.id,toAddresses,ccAddresses,bccAddresses,templateId,subject,body,fileData);
        }Catch(Exception e){
            System.debug(e);
        }
        try{
            HD_IncidentDetailController.sendEmail(inc.id,toAddresses,ccAddresses,bccAddresses,templates[0].id,subject,body,fileData);
        }Catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }*/
    static TestMethod void testSendMailNew(){

        //get email templates
        List<EmailTemplate> templates = HD_IncidentDetailController.getEmailTemplates();


        ManagedPkgErrorClass.isFromManagedPackage = false;
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc = testIncident;
        //String[] toAddresses,String[] ccAddresses,String[] bccAddresses,String templateId,String subject,String body,List<String> fileData
        String[] toAddresses = new String[]{'amp@akamai.com'};
        String[] fromAddresses = new String[]{'abudnar@akamai.com'};
        String[] ccAddresses = new String[]{'amp@akamai.com'};
        String[] bccAddresses = new String[]{'amp@akamai.com'};
        String templateId = null;
        String subject = 'test';
        String body = 'test';

        ContentVersion contentVersion = new ContentVersion(
          Title = 'ABC',
          PathOnClient = 'test.jpg',
          VersionData = Blob.valueOf('Test Content'),
          IsMajorVersion = true
        );
        
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument LIMIT 1];

        //create ContentDocumentLink  record
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = inc.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;

        Test.startTest();
        try{
            HD_IncidentDetailController.sendEmailNew(inc.id,fromAddresses, toAddresses,ccAddresses,bccAddresses,templateId,subject,body,new List<String>{documents[0].Id},new List<String>{'test.jpg'});
        }Catch(Exception e){
            System.debug(e);
        }
        try{
            HD_IncidentDetailController.sendEmailNew(inc.id, fromAddresses, toAddresses,ccAddresses,bccAddresses,templates[0].id,subject,body,new List<String>{documents[0].Id},new List<String>{'test.jpg'});
        }Catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    //Komal: New Test Cases - 17.8
    static TestMethod void testIsAccessible(){
         ManagedPkgErrorClass.isFromManagedPackage = false;
        Test.startTest();
        try{
            Boolean val = HD_IncidentDetailController.isAccessableRecord(testIncident.Id);
            System.assertNotEquals(null, val);
        }Catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    static TestMethod void testupdateEmailConfig(){
         ManagedPkgErrorClass.isFromManagedPackage = false;
        Test.startTest();
        try{
            BMCServiceDesk__Incident__c inc1 = HD_IncidentDetailController.updateEmailConfig(testIncident.Id, 'clientNotification', true);
            System.assertEquals(true, inc1.Exclude_Client_Notifications__c);
            BMCServiceDesk__Incident__c inc2 = HD_IncidentDetailController.updateEmailConfig(testIncident.Id, 'onCreation', true);
            System.assertEquals(true, inc2.Notify_dl_sysadmin_on_creation__c);
            BMCServiceDesk__Incident__c inc3 = HD_IncidentDetailController.updateEmailConfig(testIncident.Id, 'onStatusChange', true);
            System.assertEquals(true, inc3.Notify_dl_sysadmin_on_status_change__c);
            BMCServiceDesk__Incident__c inc4 = HD_IncidentDetailController.updateEmailConfig(testIncident.Id, 'onNoteUpdate', true);
            System.assertEquals(true, inc4.HD_Notify_DL_EIS_on_Notes_Update__c);
        }Catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    static TestMethod void testGetContentForceURL(){
         ManagedPkgErrorClass.isFromManagedPackage = false;
        Test.startTest();
        try{
            String url = HD_IncidentDetailController.getContentForceURL();
            System.assertNotEquals(null, url);
        }Catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

     static TestMethod void testChangeApproverNullId(){
         ManagedPkgErrorClass.isFromManagedPackage = false;
        Test.startTest();
        try{
            HD_IncidentDetailController.addChangeApprover(testIncident.Id, null);
        }Catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    static TestMethod void getCategoriesTest(){
    	   List<BMCServiceDesk__Category__c> cats =  HD_IncidentDetailController.getCategories();
        	System.assert(cats.size()>0);
   	}

    static TestMethod void searchCategories(){
        List<BMCServiceDesk__Category__c> catList = HD_IncidentDetailController.searchCategories('Hard');
        System.assert(catList.size()>0);
    }

    static TestMethod void testReopenTicketClosedStatus(){
        HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        Test.startTest();
        BMCServiceDesk__Incident__c inc;
        System.runAs((User)[SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1]) {
            inc = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.GENERIC);
            inc.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
            inc.OwnerId = System.UserInfo.getUserId();

       		insert inc;
        }

        BMCServiceDesk__Incident__c incResult = HD_IncidentDetailController.closeIncident(inc.Id, 'test resolution', '00:15');
        ManagedPkgErrorClass.isFromManagedPackage = false;

        try{
            HD_IncidentDetailController.reopenTicket(incResult.Id);
        }Catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }


    static TestMethod void testResumeTicket(){
        Test.startTest();
        ManagedPkgErrorClass.isFromManagedPackage = false;
        testIncidentForResume.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ON HOLD');
        insert testIncidentForResume;
        System.debug('Initial status: '+testIncidentForResume.BMCServiceDesk__FKStatus__c);
        try{
            HD_IncidentDetailController.resumeTicket(testIncidentForResume.Id);
            BMCServiceDesk__Incident__c updatedInc = [Select BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where Id =:testIncidentForResume.Id limit 1];
            System.debug('ASSIGNED: '+HD_Test_Data_Factory.statusMap.get('ASSIGNED'));
            System.debug('ON HOLD: '+HD_Test_Data_Factory.statusMap.get('ON HOLD'));
            //System.assertEquals(HD_Test_Data_Factory.statusMap.get('ASSIGNED'), updatedInc.BMCServiceDesk__FKStatus__c);
        }
        catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    static TestMethod void testIsPendingStatus(){
        Test.startTest();
        ManagedPkgErrorClass.isFromManagedPackage = false;
        testIncidentForPendingStatus.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ON HOLD');
        insert testIncidentForPendingStatus;
        try{
            boolean result1 = HD_IncidentDetailController.isPendingStatus(testIncident.Id);
            System.assertEquals(false, result1);
            boolean result2 = HD_IncidentDetailController.isPendingStatus(testIncidentForPendingStatus.Id);
            System.assertEquals(true, result2);
        }
        catch(Exception e){
            System.debug(e);
        }
        Test.stopTest();
    }

    static TestMethod void testLowPriorityPicklist(){
        User contextUser=[SELECT Id, PermissionSet.Name,AssigneeId,Assignee.HD_View_Helpdesk_Confidential_Data__c FROM PermissionSetAssignment where PermissionSet.Name = 'HD_HR_View_Encrypted_data_permission' and Assignee.HD_View_Helpdesk_Confidential_Data__c = true and Assignee.isActive = true limit 1].Assignee;
        //contextUser = [select Id, username from User where Profile.name = 'System Administrator' and isActive = true limit 1];
        HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
        List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
        tempList.order='1';
        tempList.responseType='Text Area';
        tempList.prompt='Description';
        tempList.required='FALSE';
        tempList.hidden='FALSE';
        templist.runWorkflow = 'FLASE';


        fulfilmentInputLists.add(tempList);


        HD_Test_Data_Factory.init();

        MAP<String,Id>categoriesCreated = HD_Test_Data_Factory.categoryMap;
        System.debug(categoriesCreated);

        String clientEmailId=System.UserInfo.getUserEmail();

        Map<String,Id> result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Hardware'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.GENERIC);
        System.debug(' INCIDENTB ID '+result.get('incidentId'));
        String incid = result.get('incidentId');

        BMCServiceDesk__SRM_FulfillmentInputs__c ffi = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi.BMCServiceDesk__Prompt__c = 'Priority' ;
        ffi.BMCServiceDesk__InputValues__c = 'Highф3фfalseПStandardф4фfalseПLowф5фtrue';
        ffi.Input_Values_holder__c = 'High?3?false*Standard?4?false*Low?5?true';
        ffi.BMCServiceDesk__ResponseType__c = 'Picklist';
        ffi.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        insert ffi;

        BMCServiceDesk__SRM_RequestDetailInputs__c rdi = new BMCServiceDesk__SRM_RequestDetailInputs__c();
        rdi.BMCServiceDesk__FKFulfillmentInputs__c = ffi.Id;
        rdi.BMCServiceDesk__Input__c = 'Priority';
        rdi.BMCServiceDesk__Response__c = 'Low';
        rdi.BMCServiceDesk__StoredValue__c = '5';
        rdi.BMCServiceDesk__FKRequestDetail__c = result.get('serviceRequestDetailId');
        insert rdi;

        HD_IncidentDetailController.IncidentAndOptions incioptions =  HD_IncidentDetailController.getIncidentWithPriority(incid);
        System.assertEquals(incioptions.selectedOpt, 'Low');
    }

     static TestMethod void testShowAttachments(){
        Test.startTest();
        ManagedPkgErrorClass.isFromManagedPackage = false;
        HD_IncidentDetailController.showAttachments(testIncident.Id);
        Test.stopTest();
    }

    @isTest
    static void whenGetOpenTasksIsCalledExpectOnlyOpenTasksToBeReturned(){
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder().buildAndSave();
        BMCServiceDesk__Task__c task1 = new BMCServiceDesk__Task__c(
            BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('OPENED'),
            BMCServiceDesk__FKIncident__c = testIncident.Id);
        insert task1;
        BMCServiceDesk__Task__c task2 = new BMCServiceDesk__Task__c(
            BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('CLOSED'),
            BMCServiceDesk__FKIncident__c = testIncident.Id);
        insert task2;
        Test.startTest();
        List<BMCServiceDesk__Task__c> openTasks = HD_IncidentDetailController.getOpenTasks(testIncident.Id);
        Test.stopTest();
        System.assertEquals(1, openTasks.size(), 'Actual not same as expected');
    }
    
    @isTest
    public static void when_InIncidentDetailsScreen_Expect_OnlyEmailsValidForProfileInSendEmailFrom() {
        Profile sysAdmin = getProfile('System Administrator');
        Profile engineering = getProfile('Engineering');
        List<OrgWideEmailAddress> orgWideAddresses = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress LIMIT 500];

        if(orgWideAddresses!= null && orgWideAddresses.size() > 2) {        
            User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
            System.runAs ( thisUser ) {
                
                User adminUser = new UserBuilder()
                    .withFirstName('Test')
                    .withLastName('User 1')
                    .withUserName('Test.user1@akamai.com')
                    .withEmail('Test.user1@akamai.com')
                    .withProfile(sysAdmin.Id)
                    .withAlias('tuser1')
                    .withAkamUserId('tuser1')
                    .buildAndSave();
                
                User engineeringUser = new UserBuilder()
                    .withFirstName('Test')
                    .withLastName('User 2')
                    .withUserName('Test.user2@akamai.com')
                    .withEmail('Test.user2@akamai.com')
                    .withProfile(engineering.Id)
                    .withAlias('tuser2')
                    .withAkamUserId('tuser2')
                    .buildAndSave();
                                   
                System.runAs(adminUser) {
                    System.debug('Org Wide Address:'+orgWideAddresses[0]+':ALL PROFILESП'+orgWideAddresses[1]+':'+sysAdmin.Id);
                    BMCServiceDesk__SYSProperties__c props = new RemedyForceSysPropsBuilder()
                        .withProperty('multipleEmailFromAddprop',orgWideAddresses[0].Id+':ALL PROFILESП'+orgWideAddresses[1].Id+':'+sysAdmin.Id)
                        .buildAndSave();
    
                    List<OrgWideEmailAddress> addresses = (List<OrgWideEmailAddress>)JSON.deserialize(
                        HD_IncidentDetailController.getOrgWideAddresses(), List<OrgWideEmailAddress>.Class) ;
                    System.assert(addresses.contains(orgWideAddresses[0]) &&addresses.contains(orgWideAddresses[1]));
                }
                
                System.runAs(engineeringUser) {
                    List<OrgWideEmailAddress> addresses = (List<OrgWideEmailAddress>)JSON.deserialize(
                        HD_IncidentDetailController.getOrgWideAddresses(), List<OrgWideEmailAddress>.Class) ;
                    System.assert(addresses.contains(orgWideAddresses[0]));
                }
            }
        }
    }
    
    private static Profile getProfile(String profileName) {
        return [Select Id FROM Profile WHERE Name = :profileName];
    }
    
    /*
    * Builder class that build the 'BMCServiceDesk__SYSProperties__c' object. This object stores all the settings defined in
    * 'Remedyforce Administration'
    */
    private class RemedyForceSysPropsBuilder {
        private BMCServiceDesk__SYSProperties__c record;
        
        public RemedyForceSysPropsBuilder() {
            record = new BMCServiceDesk__SYSProperties__c();
        }
        
        public RemedyForceSysPropsBuilder withProperty(String propertyName, String propertyValue) {
            record.BMCServiceDesk__property__c = propertyName;
            record.BMCServiceDesk__value__c = propertyValue;
            return this;
        }
        
        public RemedyForceSysPropsBuilder withSequence(String sequence) {
            record.BMCServiceDesk__Sequence__c = sequence;
            return this;
        }
        
        public RemedyForceSysPropsBuilder withPrimaryRole(String primaryRole) {
            record.BMCServiceDesk__Primary_Role__c = primaryRole;
            return this;
        }
        
        public BMCServiceDesk__SYSProperties__c buildAndSave() {
            upsert record;
            return record;
        }
    }
        
    /*
    * Builder class that build the 'UserBuilder' object.
    */
    private class UserBuilder{
        private User record;
        
        public UserBuilder() {
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name= 'System Administrator' LIMIT 100];
            record = new User(
                Alias = 'tUser', 
                Email='abudnar@akamai.com',
                EmailEncodingKey='UTF-8', 
                LastName='User', 
                FirstName = 'Test',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', 
                ProfileId = adminProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', 
                UserName= 'test.user@akamai.com');
        }
        
        public UserBuilder withAlias(String alias) {
            record.Alias = alias;
            return this;
        }
        
        public UserBuilder withFirstName(String firstName) {
            record.FirstName = firstName;
            return this;
        }
        
        public UserBuilder withLastName(String lastName) {
            record.LastName = lastName;
            return this;
        }
        
        public UserBuilder withUserName(String userName) {
            record.UserName = userName;
            return this;
        }
        
        public UserBuilder withEmail(String email) {
            record.Email = email;
            return this;
        }
        
        public UserBuilder withProfile(Id profileId) {
            record.ProfileId = profileId;
            return this;
        }
        
        public UserBuilder withAkamUserId(String akamUserId) {
            record.AKAM_User_ID__c = akamUserId;
            return this;
        }
        
        public User buildAndSave() {
            insert record;
            return record;
        }
    }
}
// CLASS END