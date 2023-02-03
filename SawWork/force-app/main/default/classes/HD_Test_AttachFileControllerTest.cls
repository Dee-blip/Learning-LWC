@isTest(SeeAllData=false)
public class HD_Test_AttachFileControllerTest {
	static BMCServiceDesk__Incident__c testIncident;
    static{
        HD_IncidentTestDataFactory rfFactory =  new HD_IncidentTestDataFactory();
        testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.EAEOPS);
        //testIncident = [select id from bmcservicedesk__incident__c limit 1];
        

        //adding custom settings
        List<GSM_Custom_Settings__c> settings =  new List<GSM_Custom_Settings__c>();
        settings.add(new GSM_Custom_Settings__c(name='name', value__c='1'));
        insert settings;
        
    }
    
    static TestMethod void testSaveFile(){
        Test.startTest();
        Id result = HD_AttachFileController.saveFile(testIncident.Id, 'Test File', EncodingUtil.urlEncode('This is a test file', 'UTF-8'), 'test type');
        System.assertNotEquals(null, result, 'Attachment Id is null');
        Test.stopTest();
    }
    
    static TestMethod void testSaveFileError(){
        //Id incId = (Id)'dummy inc id';
        Test.startTest();
        Id result = HD_AttachFileController.saveFile(null, 'Test File', '', 'test type');
        System.assertEquals(null, result);
        Test.stopTest();
    }
    
    static TestMethod void testConstructor(){
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.standardController(testIncident);
        HD_AttachFileController testConst = new HD_AttachFileController(sc);
        Test.stopTest();
    }
    
}