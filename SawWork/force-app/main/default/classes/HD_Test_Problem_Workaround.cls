/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date :

Base Line : used as a apart of requirment for Problem Managment Workaround, Unit Test

Purpose : an Unit Test for trigger HD_Poblem_workaround_tri.trigger

Usage : used as an test for the business logic , for trigger HD_Poblem_workaround_tri.trigger

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_Poblem_workaround_tri.trigger
Class Associated : HD_Poblem_workaround_tri_class

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
@isTest(SeeAllData = false)
private class HD_Test_Problem_Workaround {



    public static BMCServiceDesk__Incident__c testIncident;
    public static Id serviceID;
    public static Map<String, String> statusMap; // = new Map<String,String>();
    public static Map<String, String> categoryMap; // = new Map<String,String>();
    public static HD_ProblemTestDataFactory probFactory;

//public static statusMap
    static {
        //HD_Test_Remedyforce_TestDataFactory_V2 rfFactory = new HD_Test_Remedyforce_TestDataFactory_V2();
        //testIncident = rfFactory.createIncident(HD_Test_Remedyforce_TestDataFactory_V2.Team.GENERIC);

        //categoryMap = HD_Test_Remedyforce_TestDataFactory_V2.categoryMap;
        //statusMap = HD_Test_Remedyforce_TestDataFactory_V2.statusMap;

        //initializing custom setting
        HD_BATCH_JOB__c cset = new HD_BATCH_JOB__c();
        cset.HD_Problem_Pending_Periodic_batchapex__c = '{"batch_params":[{"periodicdays":"7"}]}';
        cset.HD_TicketStatusAlert_batchapex__c = '{"batch_params":[{"distributionlistemail":"helpdesk-sa@akamai.com","recordlink":"/apex/BMCServiceDesk__RemedyforceConsole?objectName=Incident__c&record_id=","queryorclause":""}]}';
        insert cset;

        

        probFactory = new HD_ProblemTestDataFactory();
        statusMap = HD_Test_Data_Factory.statusMap;
        serviceID = (Id)HD_Test_Data_Factory.categoryMap.get('Access');
    }

    //Creating RunAs Method for user substitution
    private static User runAsUser(String profileName, boolean IsStaffUser ) {
        User u = null;
        if ( profileName == '' || profileName == null ) {
            profileName = 'System Administrator';
        }
        System.debug('Current Profile Name: ' + profileName);
        // Setup test data
        // This code runs as the system user
        Profile p = [ SELECT Id FROM Profile WHERE Name = : profileName limit 1 ];
        if ( p == null ) {
            p = [ SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1 ];
        }
        try {
            /* u = new User(Alias = 'test12', Email='test1234@akamai.com',
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', ProfileId = p.Id,
            TimeZoneSidKey='America/Los_Angeles', UserName='test1234@akamai.com');
            */
            u = [ SELECT Id, FirstName, LastName, Email, BMCServiceDesk__IsStaffUser__c from User WHERE ProfileId = : p.Id AND IsActive = true AND BMCServiceDesk__IsStaffUser__c = : IsStaffUser limit 1];
            System.debug('USER Details ---> ' + u);
        }//try
        catch ( Exception e ) {
            System.debug('[]Exception: ' + e.getMessage());
            u = [ SELECT Id, FirstName, LastName, Email, BMCServiceDesk__IsStaffUser__c from User WHERE ProfileId = : p.Id AND IsActive = true AND BMCServiceDesk__IsStaffUser__c = : IsStaffUser limit 1];

        }//catch()
        return u;

    } //public static User runAsUser()


    //creating workaround
    private static List< Problem_workaround__c >  workaroundtestData( List<BMCServiceDesk__Problem__c> ProblemList , Integer workaroundCount) {
        List<Problem_workaround__c> workaroundList = new List<Problem_workaround__c>();
        for (BMCServiceDesk__Problem__c pr : ProblemList) {
            for (integer i = 1; i <= workaroundCount ; i++) {
                Problem_workaround__c proWorkaround = new Problem_workaround__c();
                proWorkaround.Title_Summary__c = 'WorkAround Version v' + i + '.0';
                proWorkaround.Workaround__c = 'Testing the workaround ' + i;
                proWorkaround.Problem__c = pr.Id;

                //Adding it to List
                workaroundList.add(proWorkaround);
            }//
        }//

        return workaroundList;
    }//

    //creating the Test Class for insertion
    private static testmethod  void InsertTest() {
        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            test.startTest();
            //inserting Problem First
            List<BMCServiceDesk__Problem__c> prob = probFactory.getProblemTestdata(1);
            //   System.debug('CC1_c: '+prob[0].CC1__c);
            //insert prob;

            List<BMCServiceDesk__Problem__c> fetchedProblem = [Select Id, Name, CC1__c from BMCServiceDesk__Problem__c where Id = :prob[0].Id LIMIT 1];
            System.debug(fetchedProblem.get(0).Id + '  ' + fetchedProblem.get(0).CC1__c);
            //Inserting WorkAround
            List<Problem_workaround__c> probWR = workaroundtestData(prob, 1);
            insert probWR;

            //testing some values
            System.assertEquals(prob[0].Title_Summary__c, 'Problem Managment Title 1');
            System.assertEquals(probWR[0].Workaround__c, 'Testing the workaround 1');


            test.stopTest();

        }
    } //


}