@IsTest(SeeAllData=false)
public class HD_Test_lwcUtilityClass {

    static List<BMCServiceDesk__Incident__c> testIncidents = new List<BMCServiceDesk__Incident__c>();
    static List<User> testUsers = new List<User>();

   static{

        HD_IncidentTestDataFactory testIncident = new HD_IncidentTestDataFactory();
        testIncidents.add(testIncident.getIncidentTestData(HD_IncidentTestDataFactory.Team.EAEOPS));

        testUsers = [SELECT Id, Name, Profile.Name, isActive, BMCServiceDesk__IsStaffUser__c FROM User where Profile.Name = 'ServiceDesk Staff' and isActive = true and BMCServiceDesk__IsStaffUser__c = true LIMIT 10];
    }

    @IsTest
    static void testFileAttachmentSuccess(){
        List<string> testFileData = new List<string>();
        testFileData.add('{\"strFileName\":\"EntCatQA.csv\",\"idParent\":\"'+ testIncidents[0].id + '\",\"base64data\":\"SWQsUkFfQ2F0ZWdvcnlfR3JvdXBfX2MNCmE1OEcwMDAwMDAwTDJORSxSRVNUUklDVEVEIFBBUkVOVA%3D%3D\"}');
        Test.startTest();
        System.runAs(testUsers[0]){
            Integer result = HD_lwcUtilityClass.saveAttachments(testFileData);
            System.assertNotEquals(null, result, 'Error In file Attachement method');

        }
        Test.stopTest();
        
    }

    @IsTest
    static void testFileAttachmentFailure(){
        List<string> testFileData = new List<string>();
        testFileData.add('{\"strFileName\":\"EntCatQA.csv\",\"idParent\":\"'+ testIncidents[0].id + '\",\"base64data\":\"SWQsUkFfQ2F0ZWdvcnlfR3JvdXBfX2MNCmE1OEcwMDAwMDAwTDJORSxSRVNUUklDVEVEIFBBUkVOVA%3D%3D@%%#^#\"}');
        Test.startTest();
        System.runAs(testUsers[0]){
            try{
            Integer result = HD_lwcUtilityClass.saveAttachments(testFileData);
            }
            catch(Exception e){
                System.debug(e.getMessage());
            }
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void dataTable(){
        Test.startTest();
        List<HD_Category__mdt> queryValues = HD_lwcUtilityClass.getDataTableValues();
        Test.stopTest();
        System.assertNotEquals(0, queryValues.size(), 'Failed');
    }

    @IsTest
    static void statusList(){
        Test.startTest();
        List<String> statusList = new List<String>{'IN PROGRESS','SOLUTION IDENTIFIED'};
        List<BMCServiceDesk__Status__c> queryValues = HD_lwcUtilityClass.getStatusId(statusList);
        Test.stopTest();
        System.assertNotEquals(0, queryValues.size(), 'Failed');
    }
}