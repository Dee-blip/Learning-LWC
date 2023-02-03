/*
Template: Apex Test Class/Trigger Template

CopyRight: Komal Narsinghani @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Incident Managment, Unit Test

Purpose : an Unit Test for class 'HD_IncidentUtils.cls'
          
Usage : used as test for the business logic
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : none
Class controller Associated : HD_IncidentUtils.cls
              
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
 * Modification Log ===============================================================
 * Date               Author            Modification
 * Oct 13th, 2021     Aneesh Budnar     PRTORES-977 - Fix Test class failures
 */

@IsTest(SeeAllData=false)
public class HD_Test_IncidentUtilsTest {
//Global variable 
static BMCServiceDesk__Incident__c incident1;
static BMCServiceDesk__Incident__c incident2;

static{

  HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
  incident1 = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
    
    System.runAs(new UserTestHelper.UserBuilder().buildAndSave()) {
        incident2 = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
    }

  }//static

  @isTest
  private static void testUtils(){
    //List<BMCServiceDesk__Incident__c> incidents = getIncidentList();
    List<BMCServiceDesk__Incident__c> incidents = new List<BMCServiceDesk__Incident__c>();
    incidents.add(incident1);
    incidents.add(incident2);
    //test constructor
    HD_IncidentUtils obj = new HD_IncidentUtils(incidents);
    //insert incidents;
    List<Id> incIdList = new List<Id>();
    for(BMCServiceDesk__Incident__c inc:incidents){
      incIdList.add(inc.Id);
    }
    Id id1 = incIdList.get(0);
    Id id2 = incIdList.get(1);
    BMCServiceDesk__Incident__c parentInc = [Select Id, Name, BMCServiceDesk__FKIncident__c from BMCServiceDesk__Incident__c where Id = :id1 LIMIT 1];
    BMCServiceDesk__Incident__c childInc = [Select Id, Name, BMCServiceDesk__FKIncident__c from BMCServiceDesk__Incident__c where Id = :id2 LIMIT 1];
    System.debug('Child Incident in test class: '+childInc);
    childInc.BMCServiceDesk__FKIncident__c = id1;
    update childInc;
    //get Id of closed status
    BMCServiceDesk__Status__c closedStatus = [Select Id, Name from BMCServiceDesk__Status__C where Name = 'CLOSED' LIMIT 1];
    System.debug('Closed status Id: '+closedStatus.Id);

    //test updateChildIncident
    HD_IncidentUtils.updatechildIncident(incIdList, closedStatus.Id);
        
    //test insertIncidentHistory
    Map<Id,String> incParentMap = new Map<Id,String>();
    incParentMap.put(id2, parentInc.Name);
    HD_IncidentUtils.insertIncidentHistory(incParentMap, closedStatus.Id);
        
    //test NoteUpdatedEmail
    DateTime modified_date = System.today();
    HD_IncidentUtils.NoteUpdatedEmail('Test Note','Note from test class', modified_date, childInc);
  }
}