/*
* File Name: HD_Test_GenericHistory
* Description : Test class for HD_GenericHistoryComponentController
* @author :
* Modification Log ===============================================================
* Date 				        Author 			          Modification
* Aug 08th, 2020      Aneesh Budnar         PRTORES-1810 - Code scanner fixes
*/
@isTest(seeAllData=false)
public class HD_Test_GenericHistory {
    static testMethod void checkObjectHistory(){
        HD_Test_Data_Factory.init();
        ManagedPkgErrorClass.isFromManagedPackage = true;
        BMCServiceDesk__Incident__c testIncident = new BMCServiceDesk__Incident__c();
        testIncident.BMCServiceDesk__FKClient__c = System.UserInfo.getUserId();
      	testIncident.BMCServiceDesk__FKImpact__c = HD_Test_Data_Factory.impactMap.get('LOW');
      	testIncident.BMCServiceDesk__FKUrgency__c = HD_Test_Data_Factory.urgencyMap.get('Severity 4');
        testIncident.BMCServiceDesk__FKCategory__c = Id.valueOf(HD_Test_Data_Factory.categoryMap.get('Access'));
        testIncident.HD_Ticket_Priority__c ='4';
        testIncident.Approver__c = System.UserInfo.getUserId();
        insert testIncident;
        HD_GenericHistoryComponentController instance = new HD_GenericHistoryComponentController();
        instance.myObject = testIncident;//[select id from bmcservicedesk__incident__c order by createdDate desc limit 1];
        //instance.getObjectHistory();
        //System.debug(instance.getObjectHistory());
        System.assertEquals(instance.getObjectHistory().size()>0,true);
    }
    
}