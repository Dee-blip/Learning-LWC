@isTest(SeeAllData=false)
public class HD_Test_SLA_GAUGE {
    static{

        HD_IncidentTestDataFactory rfFactory =  new HD_IncidentTestDataFactory();
        BMCServiceDesk__Incident__c testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);

    }

    static TestMethod void testgetSLADetails()
    {
        Test.startTest();
        ManagedPkgErrorClass.isFromManagedPackage = false;
        BMCServiceDesk__Category__c testCategory = [Select Id,Name from BMCServiceDesk__Category__c where BMCServiceDesk__AvailableForIncidents__c=true and BMCServiceDesk__inactive__c=false limit 1];
        BMCServiceDesk__Incident__c testIncident = new BMCServiceDesk__Incident__c();
        testIncident.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKCategory__c = testCategory.id;
        testIncident.HD_Ticket_Priority__c ='4';
        insert testIncident;
        HD_SLA_GAUGE_apcls.getSLADetails(testIncident.Id);
        HD_SLA_GAUGE_apcls.ClassObject(testIncident.Id);
        Test.stopTest();
    }



}