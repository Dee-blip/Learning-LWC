/*
* File Name: HD_Test_TwoStepClosure
* Description : Test class for HD_Incident_Reopen_Controller
* @author :
* Modification Log ===============================================================
* Date 				Author 					Modification
* Dec 23rd, 2020    Aneesh Budnar           PRTORES-342 - Test class code coverage - 6th and Final
*/
@isTest(SeeAllData=false)
public class HD_Test_TwoStepClosure {

    public static BMCServiceDesk__Incident__c Incident;
    public static BMCServiceDesk__Incident__c testIncident;

    
    static{
        
        HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        Incident = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        testIncident = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.GENERIC);

        List<HD_Resolved_Status_Settings__c> custom_settings1 = new List<HD_Resolved_Status_Settings__c>();
        custom_settings1.add(new HD_Resolved_Status_Settings__c(name = 'reopen_status', textvalue__c = 'REOPENED'));
        insert custom_settings1;
    }
    
    private static void Initialize()
    {
            User staff = HD_Test_Remedyforce_TestDataFactory.runAsUser('ServiceDesk Staff',true);
            Incident.BMCServiceDesk__FKClient__c = System.userinfo.getUserId();   
            Id originalQueueId = Incident.ownerId;            
            Incident.ownerId = staff.id;
            Incident.BMCServiceDesk__queueName__c = 'Triage Team';
            Incident.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
            insert Incident;
            Incident.BMCServiceDesk__incidentResolution__c = 'Test-Fixed';
            Incident.Effort_Estimation__c = '11:11';
            Incident.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('RESOLVED');
            update Incident;
            
    }
    
    public static testMethod void test_HD_Incident_Reopen_Controller()
    {
        Test.startTest();
        Initialize();
        Apexpages.StandardController stdController = new Apexpages.StandardController(Incident);
        HD_Incident_Reopen_Controller controllerext = new HD_Incident_Reopen_Controller(stdController);
        PageReference r = controllerext.UpdateIncident();    
        System.assert(r.getUrl().contains('bmcservicedesk__ssredirect'));    
        //System.assertEquals(Incident.BMCServiceDesk__FKStatus__c, statusMapNametoID.get('ASSIGNED'));
        //Incident.BMCServiceDesk__incidentResolution__c = 'Test-Fixed';
        //Incident.Effort_Estimation__c = '11:11';
        //Incident.BMCServiceDesk__FKStatus__c = statusMapNametoID.get('RESOLVED');
        //update Incident;
    }

    public static testMethod void testUnauthorizedIncident()
    {      
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        System.runAs ( thisUser ) {
            Profile pf = [Select Id FROM Profile WHERE Name = 'System Administrator'];
            Test.startTest();
            //Initialize();
            User adminUser = new UserTestHelper.UserBuilder()
                .withFirstName('Test')
                .withLastName('User 1')
                .withUserName('Test.user1@akamai.com')
                .withEmail('Test.user1@akamai.com')
                .withProfile(pf.Id)
                .withAlias('tuser1')
                .buildAndSave();
            System.runAs(adminUser) {
                User staff = HD_Test_Remedyforce_TestDataFactory.runAsUser('ServiceDesk Staff',true);
                Id originalQueueId = testIncident.ownerId;            
                testIncident.ownerId = staff.id;
                testIncident.BMCServiceDesk__queueName__c = 'Triage Team';
                testIncident.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
                insert Incident;
                Apexpages.StandardController stdController = new Apexpages.StandardController(Incident);
                HD_Incident_Reopen_Controller controllerext = new HD_Incident_Reopen_Controller(stdController);
                PageReference r = controllerext.UpdateIncident();   
            }
        }
    }
    
    /*public static testMethod void test_HD_Resolved_State_To_Closed()
    {
        Test.startTest();
        Initialize();
        HD_Resolved_State_to_Closed Schedulable = new HD_Resolved_State_to_Closed();
        Schedulable.execute(null);
        String incidentid = Incident.Id;
        Incident = [select Id, BMCServiceDesk__FKStatus__c from BMCServiceDesk__Incident__c where id = :incidentid];
        system.debug(Incident);
        System.assertEquals(Incident.BMCServiceDesk__FKStatus__c, statusMapNametoID.get('CLOSED'));
    }*/
    
}