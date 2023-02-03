@isTest(seeAllData=false)
public class HD_Test_IncidentHeaderController_Test {

    static BMCServiceDesk__Incident__c testIncident1;
    static BMCServiceDesk__Incident__c testIncident2;
    static BMCServiceDesk__Incident__c testIncident3;

    static BMCServiceDesk__Category__c testCategory;
    static Group testQueue;

    static List<BMCServiceDesk__Incident__c> incList = new List<BMCServiceDesk__Incident__c>();

    static{
        /*
        ManagedPkgErrorClass.isFromManagedPackage = false;
       	testCategory = [Select Id,Name from BMCServiceDesk__Category__c where BMCServiceDesk__AvailableForIncidents__c=true and BMCServiceDesk__inactive__c=false  limit 1];
        testIncident = new BMCServiceDesk__Incident__c();
        testIncident.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKCategory__c = testCategory.id;
        testIncident.HD_Ticket_Priority__c ='4';
        insert testIncident;
        */


        ManagedPkgErrorClass.isFromManagedPackage = false;
        /*
        List<HD_RF_TRIGGER_FLAG__c> roleSettings = [select name, Role_Id__c, Run_New_Trigger__c from HD_RF_TRIGGER_FLAG__c];
        if(roleSettings.size()>0){ delete roleSettings; }


        HD_RF_TRIGGER_FLAG__c adminRole = new HD_RF_TRIGGER_FLAG__c();
        adminRole.name = 'Role: System Administartor';
        adminRole.Role_Id__c = System.UserInfo.getUserRoleId();
        adminRole.Run_New_Trigger__c = true;
        insert adminRole;
        */

        //HD_Test_Remedyforce_TestDataFactory_V2 rfFactory = new HD_Test_Remedyforce_TestDataFactory_V2();
        HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        testIncident1 = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
        testIncident2 = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.GENERIC);

        testIncident2.CCText__c = 'example1@akamai.com;example2@akamai.com';
        testIncident2.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
		insert testIncident2;
        testIncident3 = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.EAEOPS);
        testIncident3.CCText__c = 'example1@akamai.com;example2@akamai.com';
        testIncident3.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
		insert testIncident3;
        /*incList.add(testIncident3);
        incList.add(testIncident2);
        insert incList;*/


   	}

    @isTest
    static void testCaseOne(){

        Test.startTest();

        testIncident3.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('RESOLVED');
        testIncident3.BMCServiceDesk__incidentResolution__c = 'Test Resolution';
        testIncident3.Effort_Estimation__c = '01:10';
        update testIncident3;

       	BMCServiceDesk__Incident__c incident = [select id from bmcservicedesk__incident__c where HD_Total_Effort_Spent_minutes__c>1 limit 1];
        BMCServiceDesk__Incident__c incidentFromFunction = HD_IncidentHeaderController.getIncident(incident.id);
        HD_IncidentHeaderController.Data returnValue = HD_IncidentHeaderController.getIncidentDetailsFormatedData(incident.id);
        HD_IncidentHeaderController.Data result = HD_IncidentHeaderController.getIncidentDetailsFormatedData(testIncident3.id);
        System.assert(result.ccInfo.size()>0);

        Test.stopTest();
    }

    @isTest
    static void testCaseTwo(){

        Test.startTest();

       	BMCServiceDesk__Incident__c incident = [select id from bmcservicedesk__incident__c where HD_Total_Effort_Spent_minutes__c<60 limit 1];
        BMCServiceDesk__Incident__c incidentFromFunction = HD_IncidentHeaderController.getIncident(incident.id);
        HD_IncidentHeaderController.Data returnValue = HD_IncidentHeaderController.getIncidentDetailsFormatedData(incident.id);

        Test.stopTest();
    }

    @isTest
    static void testForTasks(){
        Test.startTest();
        BMCServiceDesk__Task__c incTask = new BMCServiceDesk__Task__c();
        incTask.BMCServiceDesk__FKIncident__c = testIncident1.id;
        insert incTask;
        HD_IncidentHeaderController.Data result = HD_IncidentHeaderController.getIncidentDetailsFormatedData(testIncident1.id);
        System.assert(result.TaskCount > 0);
        Test.stopTest();
    }

    @isTest
    static void testChangeStatusToInProgress(){
        Test.startTest();
        BMCServiceDesk__Incident__c updatedInc = HD_IncidentHeaderController.changeStatusToInProgress(testIncident1.Id);
        System.debug('status: '+updatedInc.BMCServiceDesk__FKStatus__c);
        System.assertEquals(updatedInc.BMCServiceDesk__FKStatus__c,HD_Test_Data_Factory.statusMap.get('IN PROGRESS'));
        Test.stopTest();
    }

    @isTest
    static void whenGetAllStatusesInvokedExpectAllStatusesToBeReturned(){
        Test.startTest();
        String statuses = HD_IncidentHeaderController.getAllStatuses(testIncident1.Id);
        System.assertNotEquals('',statuses,'Expected value does not match the actual value');
        Test.stopTest();
    }

}