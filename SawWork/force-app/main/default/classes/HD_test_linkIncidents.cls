/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date :

Base Line : used as a apart of requirment for Bulk incident link, Unit Test

Purpose : an Unit Test for Controller 'HD_linkincidents_extension.cls'

Usage : used as an test for the business logic , bulk incident link

Test Class Asssociated : NONE

Controller (Boolean): false

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : none
Class controller Associated : HD_linkincidents_extension.cls

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
@isTest(seeAllData = false)
private  class HD_test_linkIncidents {

/*
    public static List<BMCServiceDesk__Incident__c> incidentList;
    public static BMCServiceDesk__Urgency__c urgency;
    public static BMCServiceDesk__Category__c category;
    public static BMCServiceDesk__Impact__c impact;
    public static Map<Id, User> userMap;
    public static Map<String, Group> groupMap ;
    public static Map<String, Id> statusMap;

    static {
        incidentList = new List<BMCServiceDesk__Incident__c>();
        urgency = [select id from BMCServiceDesk__Urgency__c where name = 'Severity 2' limit 1];
        category = [select id, name, BMCServiceDesk__parentTree__c, BMCServiceDesk__AvailableForIncidents__c, BMCServiceDesk__inactive__c from BMCServiceDesk__category__c  where BMCServiceDesk__AvailableForIncidents__c = true  and BMCServiceDesk__inactive__c = false and  BMCServiceDesk__parentTree__c like '%Corporate%' limit 1 ];

        impact = [select id, name from BMCServiceDesk__Impact__c where name = 'LOW'];
        userMap = new Map<Id, User>([select id, name from user where isactive = true]);
        //Test Incident
        groupMap = new Map<String, Group>([Select id, name from group where name = 'VIP Users' OR Type = 'Queue' LIMIT 5000]);
        statusMap = HD_test_linkIncidents.createStatusMap();
    }

    static Map<String, Id> createStatusMap() {
        List<BMCServiceDesk__Status__c> statusList = [select id, name from BMCServiceDesk__Status__c limit 100];
        Map<String, Id> stMap = new Map<String, Id>();
        for (BMCServiceDesk__Status__c status : statusList) {
            stMap.put(status.name, status.id);
        }
        return stMap;
    }
*/

     static BMCServiceDesk__Incident__c  testIncident;

     static{
         HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
     }

    //This method will test the page loeading
    static testMethod void loadPage() {
        Test.startTest();
        //Id incid = [select id from BMCServiceDesk__Incident__c order by createdDate limit 1].id;
        ID incid = testIncident.ID;
        Test.setCurrentPageReference(new PageReference('Page.HDlinknncidents'));
        System.currentPageReference().getParameters().put('id', incid);
        System.currentPageReference().getParameters().put('isConsole', 'false' );

        //Lets Call Controller which does redirection
        HD_linkincidents_extension linkinci  = new HD_linkincidents_extension();

        System.assertNotEquals(System.currentPageReference(), null);
        linkinci.emptySearchString();

        linkinci.Search_String = 'CLOSED';
        linkinci.searchResult();
        linkinci.getIncludes();
        linkinci.getIncidenttoLink();
        linkinci.columnOrder();
        linkinci.nextbutton();
        linkinci.previousbutton();
        linkinci.linkButtonVisiblility = false;
        linkinci.includeSelectListvalue = 'CLOSED';
        linkinci.getIncidenttoLink();
        System.debug(linkinci.parentIncidentLinkageValidation());
        //diable link button
        //linkinci.linkButtonVisiblility = false;

        Test.stopTest();
    }//static testMethod void loadPage()


}//