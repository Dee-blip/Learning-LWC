/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Problem Managment, Unit Test

Purpose : an Unit Test for Controller 'HD_Closepopup.cls'

Usage : used as an test for the business logic , Custome close incident

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : none
Class controller Associated : HD_Closepopup.cls

 */
/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)//@nikhil:changed from true to false as per the jira 871 and now test coverage is 85% 
private class HD_Test_SRMClose 
{


  //Global variable 
  
  private static BMCServiceDesk__Incident__c testIncident;

  static{
    /*
     *@LastModifiedBy: Nikhil Karn
     *@ModificationReason: added this lines to load test data factory.
    */
    HD_IncidentTestDataFactory rfFactory =  new HD_IncidentTestDataFactory();
    testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
  
  }

  //Test Method #1 
  private static testmethod void ControllerTest()
  {
    //first setting the page
    PageReference pageRef = Page.HDProblemTaskPage;
    Test.setCurrentPage(pageRef);

    Test.startTest();
    BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
    incident.BMCServiceDesk__FKCategory__c  = HD_Test_Data_Factory.categoryMap.get('Compensation');
    incident.BMCServiceDesk__FKUrgency__c = HD_Test_Data_Factory.urgencyMap.get('Severity 3'); 
    incident.BMCServiceDesk__FKImpact__c =  HD_Test_Data_Factory.impactMap.get('LOW');
    incident.HD_Ticket_Priority__c = '3';
    incident.BMCServiceDesk__incidentDescription__c ='Testing'; 
    incident.BMCServiceDesk__FKClient__c =System.UserInfo.getUserId();
    insert incident;
    System.debug('Inserted Incident ----> '+incident);
    ApexPages.currentPage().getParameters().put('id',incident.id );
    BMCServiceDesk__Incident__c inciPg = new BMCServiceDesk__Incident__c();
    //for apex Extension calling controller
    ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(inciPg);

    //calling Controller now
    HD_Closepopup srmclosectrl = new HD_Closepopup(stdController);
    srmclosectrl.ajaxSave();
    //lets call action
    //srmclosectrl.ajaxSave();
    Test.stopTest();

  }//private static testmethod void ControllerTest()

  //Komal- Adding method to test closed incident
  private static testmethod void testForClosedIncident()
  {    
    PageReference pageRef = Page.HDProblemTaskPage;
    Test.setCurrentPage(pageRef);

    //insert testIncident;
    testIncident.BMCServiceDesk__incidentResolution__c='Resolved';
    testIncident.BMCServiceDesk__FKStatus__c=HD_Test_Data_Factory.statusMap.get('ASSIGNED');
    update testIncident;
    testIncident.BMCServiceDesk__FKStatus__c=HD_Test_Data_Factory.statusMap.get('CLOSED');
    update testIncident;
    System.debug('Updated Incident:'+testIncident);
    BMCServiceDesk__Incident__c incident1 = [Select Id, Name, BMCServiceDesk__Status_ID__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Status_ID__c='CLOSED' LIMIT 1];
    Test.startTest();
    System.debug('Fetched incident: '+incident1);
    ApexPages.currentPage().getParameters().put('id',incident1.id );
    BMCServiceDesk__Incident__c inciPg = new BMCServiceDesk__Incident__c();
    //for apex Extension calling controller
    ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(incident1);

    //calling Controller now
    HD_Closepopup srmclosectrl = new HD_Closepopup(stdController);
    srmclosectrl.ajaxSave();    
    Test.stopTest();
  }//testForClosedIncident




}//END OF CLASS