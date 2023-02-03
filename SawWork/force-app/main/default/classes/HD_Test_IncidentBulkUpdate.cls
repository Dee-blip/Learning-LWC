/*
* File Name: HD_Test_IncidentBulkUpdate
* Description : Test class for HD_IncidentBulkUpdate
* @author :
* Modification Log ===============================================================
* Date 				  Author 			    Modification
* Aug 08th, 2020      Aneesh Budnar         PRTORES-1810 - Code scanner fixes
*/
@isTest(SeeAllData = false)
public class HD_Test_IncidentBulkUpdate {
    
    static testMethod void testBulkAssign()
    {
        HD_Test_Data_Factory.init();
       	ManagedPkgErrorClass.isFromManagedPackage = false;
        BMCServiceDesk__Incident__c testIncident=new BMCServiceDesk__Incident__c();
        testIncident.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKCategory__c = Id.valueOf(HD_Test_Data_Factory.categoryMap.get('Access'));
        testIncident.HD_Ticket_Priority__c ='4';
        insert testIncident;
        
        Test.startTest();
        List<User> staffUsers = HD_IncidentBulkUpdate.getAllStaffs();
        HD_IncidentBulkUpdate.bulkAssign(new List<Id>{testIncident.Id},new List<BMCServiceDesk__Incident__c>{testIncident},null);
        System.assertNotEquals(null, staffUsers);
        Test.stopTest();
    }

}