/*
* File Name: HD_Test_ActionAudit
* Description : Test class for HD_ActionAudit
* @author :
* Modification Log ===============================================================
* Date 				Author 				Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
@isTest(seeAllData=false)
public class HD_Test_ActionAudit {

    static testMethod void testActionAudit() {
        HD_Test_Data_Factory.init();
        BMCServiceDesk__Incident__c testIncident;
        BMCServiceDesk__Category__c testCategory;
        ManagedPkgErrorClass.isFromManagedPackage = false;
        testIncident = new BMCServiceDesk__Incident__c();
        testIncident.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKCategory__c = Id.valueOf(HD_Test_Data_Factory.categoryMap.get('Access'));
        testIncident.HD_Ticket_Priority__c ='4';
        insert testIncident;
        HD_ActionAudit.addActionAudit(testIncident.Id,'testAction',Datetime.now(),Datetime.now().addSeconds(4),0,'SUCCESS');
        System.assertNotEquals(null,[select Name from HD_Action_Audit__c where Name = 'testAction' limit 1]);
    }

}