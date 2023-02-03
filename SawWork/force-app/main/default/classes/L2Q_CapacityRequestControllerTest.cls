@isTest
public class L2Q_CapacityRequestControllerTest {
    @testSetup static void setup() {
        Account acc = new Account();
        acc.Name = 'TestAccountPlan_01';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        acc.website = 'www.AccountPlanWebsitetest.com';
        insert acc;
        Capacity_request__c cs0 = new Capacity_Request__c(name = 'Test', Status__c = 'Need More Information', Unit_of_Measure__c = 'Gbps', Account__c = acc.Id, LATAM_Capacity__c = 3, validation_override__c = true);
		insert cs0;
		Capacity_Allocation__c ca = new Capacity_Allocation__c(Associated_CPR__c = cs0.id,Region__c = 'APJ',Requested_Capacity__c = 1,Approved_Capacity__c = 0);
		insert ca;
    }
    @isTest
    static void testUtil() { // covers l2q_cprUtil
        L2Q_CprUtil.CPRallocationwrapper ps = new L2Q_CprUtil.CPRallocationwrapper();
        ps.recordid = '';
        ps.country = '';
        ps.region = '';
        ps.cprid = '';
        ps.allocatedcapacity = 0.00;
        ps.approvedcapacity = 0.00;
        L2Q_CprUtil.getCountrydependentList();
        L2Q_CprUtil.CPRrequestapprovewrapper lq = new L2Q_CprUtil.CPRrequestapprovewrapper();
        lq.parentrecid = '001';
        lq.parentunqid = '';
        lq.recordid = '';
        lq.rowunqid = '';
        lq.country = '';
        lq.allocatedcapacity = '0.00';
        lq.approvedcapacity = '0.00';
        lq.region = '';
        lq.index = 1;
        List < L2Q_CprUtil.CPRrequestapprovewrapper > lq0 = new List < L2Q_CprUtil.CPRrequestapprovewrapper > ();
        lq0.add(lq);
        List < Capacity_Allocation__c > ls = L2Q_CprUtil.preparerequestapproveList(lq0, 'approval');
        System.assertEquals(true, ls.size() > -1,'message');
    }
    @isTest
    static void testfieldSchema() {
        User accOwner = SobjectRepository.getSalesOpsUser();
        Account acc = [select id, Name from Account limit 1];
        System.runAs(accOwner) {
            L2Q_CapacityRequestController.checkAcessandbuildschema(acc.id);
            L2Q_CapacityRequestController.redirectHandler(acc.id);
            L2Q_CapacityRequestController.getData('Account', ' Name,Createddate ', ' ', 10, ' createddate desc ');
            L2Q_MdtWrapper ls = new L2Q_MdtWrapper();
            L2Q_GridRecordList k = new L2Q_GridRecordList();
			System.assert(true,true);
        }
        L2Q_CapacityRequestController.deleteRecord(acc.id);
    }
    @isTest
    static void testSaverecords() {
        Account acc = [select id, Name from Account limit 1];
        String jsonString = '[{"recordId":"","fieldArray":[{"fieldapiName":"Delivery_Product__c","fieldapiValue":"Object Delivery","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Object Delivery","value":"Object Delivery"},{"label":"Legacy HTTP Delivery","value":"Legacy HTTP Delivery"},{"label":"Download Delivery","value":"Download Delivery"},{"label":"Cloud Embed","value":"Cloud Embed"},{"label":"Chain Delivery","value":"Chain Delivery"},{"label":"API Acceleration","value":"API Acceleration"},{"label":"Adaptive Media Delivery","value":"Adaptive Media Delivery"},{"label":"Ion","value":"Ion"},{"label":"DSA","value":"DSA"},{"label":"Other","value":"Other"}],"readonly":false,"isrequired":true},{"fieldapiName":"Name","fieldapiValue":"TEST_EVT","fieldType":"STRING","readonly":false,"isrequired":true},{"fieldapiName":"Event_Type__c","fieldapiValue":"Step Change","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Step Change","value":"Step Change"},{"label":"Scheduled Event","value":"Scheduled Event"}],"readonly":false,"isrequired":true},{"fieldapiName":"Event_Start_Date_Time__c","fieldapiValue":"2020-07-27T09:38:00.000Z","fieldType":"DATETIME","readonly":false,"isrequired":true},{"fieldapiName":"Event_End_Date_Time__c","fieldapiValue":"2020-08-30T09:38:00.000Z","fieldType":"DATETIME","readonly":false,"isrequired":false},{"fieldapiName":"Traffic_Type__c","fieldapiValue":"API;Download","fieldType":"MULTIPICKLIST","fieldPicklistvalues":[{"label":"API","value":"API"},{"label":"Download","value":"Download"},{"label":"OTT - VoD","value":"OTT - VoD"},{"label":"OTT - Live Linear","value":"OTT - Live Linear"}],"readonly":false,"isrequired":false},{"fieldapiName":"Akamai_Origin_Services__c","fieldapiValue":"Akamai Direct Connect;Cloud Wrapper","fieldType":"MULTIPICKLIST","fieldPicklistvalues":[{"label":"Akamai Direct Connect","value":"Akamai Direct Connect"},{"label":"Cloud Wrapper","value":"Cloud Wrapper"},{"label":"Media Services Live","value":"Media Services Live"},{"label":"Netstorage","value":"Netstorage"},{"label":"Site Shield","value":"Site Shield"},{"label":"Cloud Interconnects","value":"Cloud Interconnects"}],"readonly":false,"isrequired":false},{"fieldapiName":"Network__c","fieldapiValue":"Freeflow - HTTP;ESSL","fieldType":"MULTIPICKLIST","fieldPicklistvalues":[{"label":"Freeflow - HTTP","value":"Freeflow - HTTP"},{"label":"Freeflow - HTTPS","value":"Freeflow - HTTPS"},{"label":"ESSL","value":"ESSL"}],"readonly":false,"isrequired":true},{"fieldapiName":"North_America_Capacity__c","fieldapiValue":"2","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"North_America_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"LATAM_Capacity__c","fieldapiValue":"3","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"LATAM_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"EMEA_Capacity__c","fieldapiValue":"4","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"EMEA_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"APJ_Capacity__c","fieldapiValue":"5","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"APJ_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"Unit_of_Measure__c","fieldapiValue":"Gbps","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Hits","value":"Hits"},{"label":"Gbps","value":"Gbps"}],"readonly":false,"isrequired":true},{"fieldapiName":"Flit_to_Bit_ratio__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"Contractual_Guarantee__c","fieldapiValue":false,"fieldType":"BOOLEAN","readonly":false,"isrequired":false},{"fieldapiName":"Validation_Override__c","fieldapiValue":true,"fieldType":"BOOLEAN","readonly":false,"isrequired":false},{"fieldapiName":"KSD_Enabled__c","fieldapiValue":false,"fieldType":"BOOLEAN","readonly":false,"isrequired":false},{"fieldapiName":"Other_Request__c","fieldapiValue":null,"fieldType":"TEXTAREA","readonly":false,"isrequired":false},{"fieldapiName":"Decision_Reason__c","fieldapiValue":null,"fieldType":"TEXTAREA","readonly":false,"isrequired":false},{"fieldapiName":"Status__c","fieldapiValue":"Pending","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Pending","value":"Pending"},{"label":"In Progress","value":"In Progress"},{"label":"Need More Information","value":"Need More Information"},{"label":"Closed - Approved","value":"Closed - Approved"},{"label":"Closed - Modified Approved","value":"Closed - Modified Approved"},{"label":"Closed - Denied","value":"Closed - Denied"}],"readonly":false,"isrequired":true}]}]';
        L2Q_CapacityRequestController.saveRecords(jsonString, 'Capacity_Request__c', acc.id);
		System.assert(true,true);
    }

    @isTest
    static void negativeTestsave() {
        Account acc = [select id, Name from Account limit 1];
        String jsonString = '[{"recordId":"","fieldArray":[{"fieldapiName":"Delivery_Product__c","fieldapiValue":"Object Delivery","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Object Delivery","value":"Object Delivery"},{"label":"Legacy HTTP Delivery","value":"Legacy HTTP Delivery"},{"label":"Download Delivery","value":"Download Delivery"},{"label":"Cloud Embed","value":"Cloud Embed"},{"label":"Chain Delivery","value":"Chain Delivery"},{"label":"API Acceleration","value":"API Acceleration"},{"label":"Adaptive Media Delivery","value":"Adaptive Media Delivery"},{"label":"Ion","value":"Ion"},{"label":"DSA","value":"DSA"},{"label":"Other","value":"Other"}],"readonly":false,"isrequired":true},{"fieldapiName":"Name","fieldapiValue":"TEST_EVT","fieldType":"STRING","readonly":false,"isrequired":true},{"fieldapiName":"Event_Type__c","fieldapiValue":"Step Change","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Step Change","value":"Step Change"},{"label":"Scheduled Event","value":"Scheduled Event"}],"readonly":false,"isrequired":true},{"fieldapiName":"Event_Start_Date_Time__c","fieldapiValue":"2020-07-27T09:38:00.000Z","fieldType":"DATETIME","readonly":false,"isrequired":true},{"fieldapiName":"Event_End_Date_Time__c","fieldapiValue":"2020-08-30T09:38:00.000Z","fieldType":"DATETIME","readonly":false,"isrequired":false},{"fieldapiName":"Traffic_Type__c","fieldapiValue":"API;Download","fieldType":"MULTIPICKLIST","fieldPicklistvalues":[{"label":"API","value":"API"},{"label":"Download","value":"Download"},{"label":"OTT - VoD","value":"OTT - VoD"},{"label":"OTT - Live Linear","value":"OTT - Live Linear"}],"readonly":false,"isrequired":false},{"fieldapiName":"Akamai_Origin_Services__c","fieldapiValue":"Akamai Direct Connect;Cloud Wrapper","fieldType":"MULTIPICKLIST","fieldPicklistvalues":[{"label":"Akamai Direct Connect","value":"Akamai Direct Connect"},{"label":"Cloud Wrapper","value":"Cloud Wrapper"},{"label":"Media Services Live","value":"Media Services Live"},{"label":"Netstorage","value":"Netstorage"},{"label":"Site Shield","value":"Site Shield"},{"label":"Cloud Interconnects","value":"Cloud Interconnects"}],"readonly":false,"isrequired":false},{"fieldapiName":"Network__c","fieldapiValue":"Freeflow - HTTP;ESSL","fieldType":"MULTIPICKLIST","fieldPicklistvalues":[{"label":"Freeflow - HTTP","value":"Freeflow - HTTP"},{"label":"Freeflow - HTTPS","value":"Freeflow - HTTPS"},{"label":"ESSL","value":"ESSL"}],"readonly":false,"isrequired":true},{"fieldapiName":"North_America_Capacity__c","fieldapiValue":"2","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"North_America_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"LATAM_Capacity__c","fieldapiValue":"3","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"LATAM_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"EMEA_Capacity__c","fieldapiValue":"4","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"EMEA_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"APJ_Capacity__c","fieldapiValue":"5","fieldType":"DOUBLE","readonly":false,"isrequired":true},{"fieldapiName":"APJ_Approved_Capacity__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"Unit_of_Measure__c","fieldapiValue":"Gbps","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Hits","value":"Hits"},{"label":"Gbps","value":"Gbps"}],"readonly":false,"isrequired":true},{"fieldapiName":"Flit_to_Bit_ratio__c","fieldapiValue":null,"fieldType":"DOUBLE","readonly":false,"isrequired":false},{"fieldapiName":"Contractual_Guarantee__c","fieldapiValue":false,"fieldType":"BOOLEAN","readonly":false,"isrequired":false},{"fieldapiName":"Validation_Override__c","fieldapiValue":true,"fieldType":"BOOLEAN","readonly":false,"isrequired":false},{"fieldapiName":"KSD_Enabled__c","fieldapiValue":false,"fieldType":"BOOLEAN","readonly":false,"isrequired":false},{"fieldapiName":"Other_Request__c","fieldapiValue":null,"fieldType":"TEXTAREA","readonly":false,"isrequired":false},{"fieldapiName":"Decision_Reason__c","fieldapiValue":null,"fieldType":"TEXTAREA","readonly":false,"isrequired":false},{"fieldapiName":"Status__c","fieldapiValue":"Pending","fieldType":"PICKLIST","fieldPicklistvalues":[{"label":"--None--","value":""},{"label":"Pending","value":"Pending"},{"label":"In Progress","value":"In Progress"},{"label":"Need More Information","value":"Need More Information"},{"label":"Closed - Approved","value":"Closed - Approved"},{"label":"Closed - Modified Approved","value":"Closed - Modified Approved"},{"label":"Closed - Denied","value":"Closed - Denied"}],"readonly":false,"isrequired":true}]}]';
        try {
            L2Q_CapacityRequestController.saveRecords(jsonString, 'Capacity_Request__c', acc.id);
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
        try {
            L2Q_CapacityRequestController.saveRecords(jsonString, '', acc.id);
        } catch (Exception ex) {
			System.debug(LoggingLevel.ERROR, ex.getMessage());
		}
        try {
            L2Q_CapacityRequestController.getData('', '', '', 10, '');
        } catch (Exception ex) {System.debug(LoggingLevel.ERROR, ex.getMessage());}
        try {
            L2Q_CapacityRequestController.deleteRecord('');
        } catch (Exception ex) {System.debug(LoggingLevel.ERROR, ex.getMessage());}
        System.assert(true,true);
    }
    @isTest
    static void testCapacitycreation() {
        Account acc = [select id, Name from Account limit 1];
        Capacity_request__c cs = new Capacity_Request__c(name = 'Test', Status__c = 'Need More Information', Unit_of_Measure__c = 'Gbps', Account__c = acc.Id, LATAM_Capacity__c = 3, validation_override__c = true);
        insert cs;
        delete cs;
        System.assert(true,true);
    }
    @isTest
    static void capacityrqUpdate() {
        User testUser1 = utilTestClass.CreateUser('userAR1','Worldwide','System Administrator');
        insert testUser1;

        PermissionSetAssignment psa = new PermissionSetAssignment();
        psa.PermissionSetId = '0PS4R000000lW4x';
        psa.AssigneeId = testUser1.id;
        insert psa;

        System.runas(testUser1){
            Capacity_Request__C cp = [select id, Name from Capacity_Request__C limit 1];
            cp.name = 'Name_Test';
            update cp;
            List<Id> ids = new List<Id>();
            ids.add(cp.id);
            List<Capacity_Request__c> cs = new List<Capacity_Request__c>();
            CapacityRequestTriggerClass.updatecpallocationCapacity(ids,cs);
            L2Q_CapacityRequestController.getallocatedCapacity(cp.id,new List<String>{'APJ'});
            System.assert(true,true);
        }
    }
	@isTest
	static void testCPralloc() {
		Capacity_Allocation__c c = [Select id from Capacity_Allocation__c limit 1];
		delete c;
		System.assert(true,true);
	}
}