/*
Template: Apex Test Class/Trigger Template

CopyRight: Vidhya Dessai @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 17/10/2014

Base Line : used as a apart of requirment for Survey Functionality, Unit Test

Purpose : an Unit Test for Survey Functionality Feature

Usage : used as an test for the business logic , for Survey Functionality Feature

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : NONE
Class Associated :HD_FeedbackSurveyController

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
@isTest(seealldata = false)
Public class HD_FeedbackSurveyControllerTest {

//creating a test data
    static BMCServiceDesk__Urgency__c urgency;
    public static List<BMCServiceDesk__Status__c> status;
    public static  BMCServiceDesk__Impact__c impactlow;

    public static  BMCServiceDesk__Category__c cat;

    public static id newActionID;
    public static List<BMCServiceDesk__Action__c> actList;
    public static BMCServiceDesk__Incident__c testIncident;

    static{
        HD_IncidentTestDataFactory incFactory = new HD_IncidentTestDataFactory();
        testIncident = incFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
    }

    //creating a function to inert Custom Settings
    private static void UtilFunc() {
        List<HD_EIS_INCIDENT_GROUP__c> groupList = HD_EIS_INCIDENT_GROUP__c.getall().values();


        if ( groupList == null || groupList.size() == 0 ) {
            HD_EIS_INCIDENT_GROUP__c IncidentGroup = new HD_EIS_INCIDENT_GROUP__c();
            HD_EIS_INCIDENT_GROUP__c IncidentGroup1 = new HD_EIS_INCIDENT_GROUP__c();
            HD_EIS_INCIDENT_GROUP__c IncidentGroup2 = new HD_EIS_INCIDENT_GROUP__c();
            HD_EIS_INCIDENT_GROUP__c IncidentGroup3 = new HD_EIS_INCIDENT_GROUP__c();
            HD_EIS_INCIDENT_GROUP__c IncidentGroup4 = new HD_EIS_INCIDENT_GROUP__c();

            IncidentGroup.NAME = 'HELPDESK_HARDWARE';
            IncidentGroup.IncidentGroup__c = 'Q_HELPDESK_HARDWARE';
            groupList.add(IncidentGroup);


            IncidentGroup1.NAME = 'HELPDESK_MALWARE';
            IncidentGroup1.IncidentGroup__c = 'Q_HELPDESK_MALWARE';
            groupList.add(IncidentGroup1);


            IncidentGroup2.NAME = 'HELPDESK_TRIAGE';
            IncidentGroup2.IncidentGroup__c = 'Q_HELPDESK_TRIAGE';
            groupList.add(IncidentGroup2);


            IncidentGroup3.NAME = 'ITOC';
            IncidentGroup3.IncidentGroup__c = 'Q_ITOC';
            groupList.add(IncidentGroup3);


            IncidentGroup4.NAME = 'ITOC_Alerts';
            IncidentGroup4.IncidentGroup__c = 'Q_ITOC_Alerts';
            groupList.add(IncidentGroup4);

            Insert groupList;



        }//if( groupList==null|| groupList.size() == 0 )
        System.debug('GroupList CustomSetting------>' + groupList);

    }//private static void UtilFunc()

    //initializing this as main function


    public static  testMethod void SurveyControllerTest() {
        //Calling init method
        
        test.startTest();
        
        system.AssertNotEquals(testIncident, Null);


        PageReference ref
            = new PageReference('/apex/HD_FeedbackSurveyPage?sid=s123test&incident=' + testIncident.ID);
        Test.setCurrentPage(ref);
        System.assertEquals(testIncident.ID, ApexPages.currentPage().getParameters().get('incident'));
        system.debug(ApexPages.currentPage().getParameters().get('incident'));


        // Instantiate a new controller with all parameters in the page
        HD_FeedbackSurveyController controller = new HD_FeedbackSurveyController();
        controller.save();

        // Verify that the success page displays

        List<HD_Survey__c> survey = [select Satisfaction_To_Resolution__c, First_Time_Issue__c, Communication_Followup__c, Satisfaction_To_Experience__c, NPS__c, Discuss__c from HD_Survey__c where Survey_Id__c = 's123test'];
        System.debug(survey[0].Satisfaction_To_Resolution__c);
        System.assertEquals('Yes', survey[0].Satisfaction_To_Resolution__c);
        System.assertEquals('Yes', survey[0].First_Time_Issue__c);
        System.assertEquals('5', survey[0].Communication_Followup__c);
        System.assertEquals('5', survey[0].Satisfaction_To_Experience__c);
        System.assertEquals('5', survey[0].NPS__c);
        System.assertEquals('Yes', survey[0].Discuss__c);


        ApexPages.CurrentPage().getHeaders().put('Host', 'akamai--qa.cs10.my.salesforce.com');
        controller.closeSurvey();
        ref = new PageReference('/apex/HD_FeedbackSurveyPage?sid=s123test');
        Test.setCurrentPage(ref);
        try {
            controller.validate();
        } catch (Exception e) {}
        test.stopTest();


    }//static testMethod void SurveyControllerTest()

}//Test Class Ends