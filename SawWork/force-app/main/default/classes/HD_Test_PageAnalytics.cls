/*
* File Name: HD_Test_PageAnalytics
* Description : Test class for HD_PageAnalytics
* @author :
* Modification Log ===============================================================
* Date 				Author 					Modification
* Aug 08th, 2020    Aneesh Budnar           PRTORES-1810 - Code scanner fixes
*/
@isTest(seeAllData=false)
public class HD_Test_PageAnalytics {

    static testMethod void testPageAudit() {
        HD_Test_Data_Factory.init();
       	BMCServiceDesk__Incident__c testIncident;
		BMCServiceDesk__Category__c testCategory;
        ManagedPkgErrorClass.isFromManagedPackage = false;
        testIncident = new BMCServiceDesk__Incident__c();
        testIncident.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
        testIncident.BMCServiceDesk__FKCategory__c = Id.valueOf(HD_Test_Data_Factory.categoryMap.get('Access'));
        testIncident.HD_Ticket_Priority__c ='4';
        insert testIncident;
        HD_PageAnalytics.addPageAudit(testIncident.Id,'testPageName',Datetime.now(),'testpageurl.com','testBrowserName','61');
        String incidentId=testIncident.Id;
        String pageName=([Select Name from HD_Page_Analytic__c where HD_Page_Analytic__c.Incident__c=:testIncident.Id][0].name);
        System.assert(pageName.equalsIgnoreCase('testPageName'));
        
    }

}