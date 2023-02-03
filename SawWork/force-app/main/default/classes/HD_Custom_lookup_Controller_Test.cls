/*
* File Name: HD_Custom_lookup_Controller_Test
* Description : Test class for 'HD_Custom_lookup_Controller'
* @author : Aneesh Budnar 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 22nd, 2021    Aneesh Budnar       PRTORES-2123 - HD Create Knowledge article Search and view Panel in LWC for Lighting UI for staff Part 2
*/
@IsTest
public class HD_Custom_lookup_Controller_Test {
    static {
        HD_Test_Data_Factory.init();
    }
    
	@IsTest
    public static void whenFindRecordsInvokedWithFiltersRecordsAreReturned() {     
        User user = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        BMCServiceDesk__Incident__c inc1 = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Compensation'))
            .withRegion('India')
            .withDescription('Incident 4')
            .withClient(user.Id)
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .buildAndSave();   
        new IncidentTestHelper.IncidentBuilder().withClient(user.Id).withDescription('Incident 1').buildAndSave();
        // Already marked as VIP ticket from Front End UI checkbox
        new IncidentTestHelper.IncidentBuilder().withVIPStatus(true).withDescription('Incident 2').buildAndSave();
        // Incident with empty BMCServiceDesk__FKClient__c
        new IncidentTestHelper.IncidentBuilder().withClient(user.Id).withDescription('Incident 3').buildAndSave();
        
        Test.startTest();
        HD_Custom_lookup_Controller.SearchParams searchParams = new HD_Custom_lookup_Controller.SearchParams();
        searchParams.searchKey = inc1.HD_HR_Region__c;
        searchPArams.objectName = 'BMCServiceDesk__Incident__c';
        searchParams.fields = 'BMCServiceDesk__FKClient__c,RecordTypeId,VIP_Ticket__c,BMCServiceDesk__FKCategory__c,BMCServiceDesk__Service_Request_Title__c';
        searchParams.searchField = 'HD_HR_Region__c';
        searchParams.additionalFilters = '';
        searchParams.recordRetrieveLimit = '1';
        List<SObject> records = HD_Custom_lookup_Controller.findRecords(JSON.serialize(searchParams));
        Test.stopTest();
        System.assertEquals(1, records.size(),'The returned values do not match the actual');
    }
    
	@IsTest
    public static void whenFindRecordsInvokedWithAdditionalFiltersRecordsAreReturned() {     
        User user = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        BMCServiceDesk__Incident__c inc1 = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Compensation'))
            .withRegion('India')
            .withDescription('Incident 4')
            .withClient(user.Id)
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .buildAndSave();   
        new IncidentTestHelper.IncidentBuilder().withClient(user.Id).withDescription('Incident 1').buildAndSave();
        // Already marked as VIP ticket from Front End UI checkbox
        new IncidentTestHelper.IncidentBuilder().withVIPStatus(true).withDescription('Incident 2').buildAndSave();
        // Incident with empty BMCServiceDesk__FKClient__c
        new IncidentTestHelper.IncidentBuilder().withClient(user.Id).withDescription('Incident 3').buildAndSave();
        
        Test.startTest();
        HD_Custom_lookup_Controller.SearchParams searchParams = new HD_Custom_lookup_Controller.SearchParams();
        searchParams.searchKey = '';
        searchPArams.objectName = 'BMCServiceDesk__Incident__c';
        searchParams.fields = 'BMCServiceDesk__FKClient__c,RecordTypeId,VIP_Ticket__c,BMCServiceDesk__FKCategory__c,BMCServiceDesk__Service_Request_Title__c';
        searchParams.searchField = 'HD_HR_Region__c';
        searchParams.additionalFilters = 'Id = \''+inc1.Id+'\'';
        List<SObject> records = HD_Custom_lookup_Controller.findRecords(JSON.serialize(searchParams));
        Test.stopTest();
        System.assertEquals(1, records.size(),'The returned values do not match the actual');
    }
    
    @IsTest
    public static void whenGetRecentRecordsInvokedExpectRecentlyViewedRecords() {   
        User user = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.email1@akamai.com')
            .buildAndSave();
        BMCServiceDesk__Incident__c inc = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Compensation'))
            .withRegion('India')
            .withDescription('Incident 4')
            .withClient(user.Id)
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .buildAndSave();   
        Test.startTest();
        HD_Custom_lookup_Controller.SearchParams searchParams = new HD_Custom_lookup_Controller.SearchParams();
        searchParams.objectIds = new List<Id>{inc.Id};
        searchPArams.objectName = 'BMCServiceDesk__Incident__c';
        searchParams.fields = 'BMCServiceDesk__FKClient__c,RecordTypeId,VIP_Ticket__c,BMCServiceDesk__FKCategory__c,BMCServiceDesk__Service_Request_Title__c';
        searchParams.searchField = 'Name';
        List<SObject> records = HD_Custom_lookup_Controller.getRecentlyViewedRecords(JSON.serialize(searchParams));
        System.assertEquals(1, records.size(),'The returned values do not match the actual');
    }
}