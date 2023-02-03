/*
 	Modification Log ===============================================================
    Date    			Author  		Modification
	Dec  21st, 2020     Aneesh Budnar   PRTORES-342 - Test class code coverage - 6th and Final
*/
@isTest
public class HD_RESTIncidentController_Test {
    @isTest
    public static void test_createIncident() {
        HD_Test_Data_Factory.init();
        insert new HD_API_Profiles__c(Name='Admin', Id__c = UserInfo.getProfileId());
        HD_RESTIncidentController.createIncident('P2R','2','Test Description',UserInfo.getUserId(),'','test@akamai.com');
    }
    
    @isTest
    public static void test_IncidentNotCreated_when_CategoryEmpty() {
        HD_Test_Data_Factory.init();
        String returnValue = HD_RESTIncidentController.createIncident('','2','Test Description',UserInfo.getUserId(),'','test@akamai.com');
        System.assertEquals('Error: Category, Description and Priority are manadatory fields.', returnValue);
    }
    
    @isTest
    public static void test_IncidentNotCreated_when_ParentTreeInvalid() {
        HD_Test_Data_Factory.init();
        String returnValue = HD_RESTIncidentController.createIncident('P2R','1','Test Description',UserInfo.getUserId(),'Enterprise Applications','test@akamai.com');
        System.assertEquals('Error: Cannot create ticket with priority 1 , It is considered as High Customer Impact issue.', returnValue);
    }
}