/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date :

Base Line : used as apart of requirment for Problem Managment, Unit Test

Purpose : an Unit Test for trigger HD_Problem_Customization.trigger

Usage : used as an test for the business logic , for trigger HD_Problem_Customization.trigger

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_Problem_Customization.trigger

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
private class HD_Test_Problem_Customization_tri {



    public static Map<String, String> statusMap;
    public static BMCServiceDesk__Incident__c testIncident;
    public static String serviceID;
    static HD_ProblemTestDataFactory problemFactory;
    static List<BMCServiceDesk__Problem__c> plroblemList;
    static List<BMCServiceDesk__Problem__c> plroblemListWithIncident;

    
    static {
        List<BMCServiceDesk__Incident__c> incList =  new List<BMCServiceDesk__Incident__c>();
        HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);

        //insert test incident in list
        incList.add(testIncident);
        serviceID = HD_Test_Data_Factory.categoryMap.get('Access');
        statusMap = HD_Test_Data_Factory.statusMap;
        problemFactory = new HD_ProblemTestDataFactory();
        plroblemList = problemFactory.getProblemTestdata(10);
        plroblemListWithIncident = problemFactory.getProblemWithIncidentTest(incList, 1);
    }

    // This will Create the test data for the Problem Object.
    /*
    *  @Parameter : countProblem -> provide the size of the data generation
    */

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

    //Running test for Single
    private static testMethod void SingleRecordInsertTest() {
        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            Test.startTest();
            List<BMCServiceDesk__Problem__c> probList =  plroblemList;
            //Inserting List of Object
            //Insert probList;
            List<BMCServiceDesk__Problem__c> insertedProb =  [ Select Title_Summary__c, Id From BMCServiceDesk__Problem__c WHERE Id = : probList[0].Id LIMIT 10 ];
            System.assertEquals(insertedProb[0].Title_Summary__c, 'Problem Managment Title 1');
            Test.stopTest();
        }//
    }//private static testMethod void SingleRecordInsertTest()

    private static testMethod void priorValueSetterCheck() {
        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            Test.startTest();
            List<BMCServiceDesk__Problem__c> probList =  plroblemList;
            //Inserting List of Object
            //Insert probList;
            List<BMCServiceDesk__Problem__c> insertedProb =  [ Select Title_Summary__c, Id From BMCServiceDesk__Problem__c WHERE Id = : probList[0].Id LIMIT 10 ];
            System.assertEquals(insertedProb[0].Title_Summary__c, 'Problem Managment Title 1');
            update probList;
            Test.stopTest();
        }//
    }//private static testMethod void SingleRecordInsertTest()

    private static testMethod void smeCheck() {
        //createa sme
        Subject_Matter_Expert__c sme = null;
        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            Test.startTest();
            List<BMCServiceDesk__Problem__c> probList =  plroblemList;
            //Inserting List of Object
            //Insert probList;
            List<BMCServiceDesk__Problem__c> insertedProb =  [ Select Title_Summary__c, Id From BMCServiceDesk__Problem__c WHERE Id = : probList[0].Id LIMIT 10 ];
            System.assertEquals(insertedProb[0].Title_Summary__c, 'Problem Managment Title 1');
            update probList;
            Test.stopTest();
        }//
    }//private static testMethod void SingleRecordInsertTest()

    //Running test for Bulk
    private static testMethod void BulkRecordInsertTest() {
        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            Test.startTest();
            List<BMCServiceDesk__Problem__c> probList =  plroblemList;
            //Inserting List of Object
            //Insert probList;
            List<BMCServiceDesk__Problem__c> insertedProb =  [ Select Title_Summary__c, Id From BMCServiceDesk__Problem__c WHERE Id = : probList[0].Id LIMIT 10 ];
            System.assertEquals(insertedProb[0].Title_Summary__c, 'Problem Managment Title 1');
            Test.stopTest();
        }//
    }//private static testMethod void SingleRecordInsertTest()

    //Runnning test for Problem With incident
    static testMethod void singleRecordwithIncidentInsertTest() {
        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            Test.startTest();
            Id currentUser = (Id)system.userinfo.getUserId();
            //Inserting Incident
            //BMCServiceDesk__Incident__c testIncident1 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKClient__c = currentUser, BMCServiceDesk__FKUrgency__c = urgency.id, BMCServiceDesk__FKCategory__c = category.id, BMCServiceDesk__FKImpact__c = impact.id);
            List<BMCServiceDesk__Incident__c> incidentList = new List<BMCServiceDesk__Incident__c>();
            incidentList.add(testIncident);
            //insert incidentList;

            //Inserting Problem
            List<BMCServiceDesk__Problem__c> insertedProb = plroblemListWithIncident;
            //insert  insertedProb;

            System.assertNotEquals(null, insertedProb[0]);
            Test.stopTest();

        }//

    }//private static testMethod void singleRecordwithIncidentInsertTest()

    static testMethod void statusPickListLogicCheck() {
        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            Test.startTest();

            String serId = serviceID;
            BMCServiceDesk__Problem__c x = new BMCServiceDesk__Problem__c();
            BMCServiceDesk__Problem__c y = new BMCServiceDesk__Problem__c();
            List<BMCServiceDesk__Problem__c> oldlist = new List<BMCServiceDesk__Problem__c>();
            List<BMCServiceDesk__Problem__c> newlist = new List<BMCServiceDesk__Problem__c>();
            oldlist.add(x);
            y.BMCServiceDesk__FKStatus__c = (ID)statusMap.get('CLOSED');
            newlist.add(y);

            HD_RF_Cust_tri_code.statusPickListLogic(newlist, oldlist);
            oldlist[0].BMCServiceDesk__FKStatus__c = (ID)statusMap.get('CLOSED');

            HD_RF_Cust_tri_code.statusPickListLogic(newlist, oldlist);
            List<BMCServiceDesk__Problem__c>  plist = plroblemList;
            System.assertEquals(plist.size() > 0 , true);
            Test.stopTest();

        }//

    }//

    //added by Pranav
    static testMethod void smeEmailSenderCheck() {
        System.runAs(runAsUser('ServiceDesk Staff', true)) {

            Id currentUser = System.UserInfo.getUserId();
            Test.startTest();
            List<BMCServiceDesk__Problem__c> probList =  plroblemList;
            //Inserting List of Object
            //Insert probList;
            Subject_Matter_Expert__c sme = new Subject_Matter_Expert__c(problem__c = probList[0].id, User__c = currentUser);
            insert sme;

            String email = [select id, Email__c, sme_email__c from Subject_Matter_Expert__c where id = : sme.id].Email__c;
            probList[0].BMCServiceDesk__Problem_Description__c = 'new Description';
            update probList;
            BMCServiceDesk__Problem__c prob = [select id, CC__c from BMCServiceDesk__Problem__c where id = :probList[0].id ];
            System.assertNotEquals(email, null);
            Test.stopTest();

        }//

    }//



}//End