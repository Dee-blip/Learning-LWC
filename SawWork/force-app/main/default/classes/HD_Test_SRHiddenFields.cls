@isTest(SeeAllData=false)
public class HD_Test_SRHiddenFields {

    static BMCServiceDesk__Incident__c testIncident;
    static Map<String,BMCServiceDesk__Status__c> statusListMap = new Map<String,BMCServiceDesk__Status__c>() ;
    static ID testCategory;
    static Group testQueue;
    static BMCServiceDesk__Incident__c testIncidentForResume;
    static BMCServiceDesk__Incident__c testIncidentForPendingStatus;

    static{

        HD_IncidentTestDataFactory  obj = new HD_IncidentTestDataFactory();
   	 	testIncident = obj.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
        testQueue = [Select Id, Name from Group g where g.Id IN (SELECT QueueId FROM QueueSobject where SobjectType = 'BMCServiceDesk__Incident__c') and name like '%ITOC%' LIMIT 1];
    	testCategory = (ID)HD_Test_Data_Factory.categoryMap.get('Hardware');
        testIncidentForResume = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        testIncidentForPendingStatus = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);

    }
    
    @isTest
	static void positivTEstCase(){
        
        HD_SRHiddenFields srh = new HD_SRHiddenFields();
        srh.getRequestDetail(testIncident.ID);
        srh.setIncId(testIncident.ID);
        ID inc =  (ID)srh.getIncId();
        srh.getRequestInputs();
        // create an incident
        // create a service request
        // create a request detail
        // create a request detial input
        // create a request detail input
    }
}