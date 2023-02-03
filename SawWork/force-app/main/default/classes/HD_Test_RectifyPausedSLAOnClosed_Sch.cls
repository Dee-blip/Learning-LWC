/* Developer @Hemant Barapatre
* Used to test the classes : HD_RectifyPausedSLAOnClosed_Schedular , HD_RectifyPausedSLAOnClosed
* Modification Log ===============================================================
* Date               Author            Modification
* Oct 13th, 2021     Aneesh Budnar     PRTORES-977 - Fix Test class failures
*/
@isTest(seeAllData=false)
public class HD_Test_RectifyPausedSLAOnClosed_Sch{
    
static BMCServiceDesk__Incident__c incident1;

    static{
        HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        incident1 = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
    }//static
    
    @isTest static void Test_BatchClass(){
    //assigning the Incident
    incident1.OwnerId = new UserTestHelper.UserBuilder().buildAndSave().Id;
    incident1.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
    update incident1;
    //
    test.startTest();
    
    //closing the incident
    incident1.BMCServiceDesk__FKStatus__c = HD_Test_Data_Factory.statusMap.get('CLOSED');
    incident1.BMCServiceDesk__incidentResolution__c = 'Testing..';
    update incident1;
        
    //creating SLA 
    BMCServiceDesk__Incident_Service_Target__c  iSST  = new BMCServiceDesk__Incident_Service_Target__c();
        iSST.BMCServiceDesk__FKIncident__c = incident1.id;
        iSST.BMCServiceDesk__ClockState__c = 'running';
        insert iSST;
        
    HD_RectifyPausedSLAOnClosed hdr = new HD_RectifyPausedSLAOnClosed();
    ID cronID = Database.executeBatch(hdr);    
        system.assertNotEquals(cronID,null);
    test.stopTest();    
    }//
    
    @isTest static void Test_ScheduleClass(){
    test.startTest();
    HD_RectifyPausedSLAOnClosed_Schedular hdrs = new HD_RectifyPausedSLAOnClosed_Schedular();
    String cronStr = '0 30 * * * ?';
    Datetime now = Datetime.now();
    Integer offset = UserInfo.getTimezone().getOffset(now);
    Datetime local = now.addSeconds(offset/1000);
    hdrs.execute(null); 
    System.schedule('HD_RectifyPausedSLAOnClosed_Schedular '+local, cronStr, hdrs);
    test.stopTest();
    }//
    
    
}// END