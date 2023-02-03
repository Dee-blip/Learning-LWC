/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date :

Base Line : used as a apart of requirment for Problem Managment, Unit Test

Purpose : an Unit Test for Controller 'HD_ProblemTaskPage_Ctrl'

Usage : used as an test for the business logic , for controller 'HD_ProblemTaskPage_Ctrl'

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : none
Class controller Associated : HD_ProblemTaskPage_Ctrl

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
private class HD_Test_ProblemTaskPage_ctrl {


    static HD_ProblemTestDataFactory problemFactory;

    static {
        problemFactory = new HD_ProblemTestDataFactory();
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

    private static testmethod  void javascriptsingleInsertTest() {

        System.runAs(runAsUser('ServiceDesk Staff', true)) {
            //first setting the page
            PageReference pageRef = Page.HDProblemTaskPage;
            Test.setCurrentPage(pageRef);

            
            test.startTest();

            //inserting Problem First
            List<BMCServiceDesk__Problem__c> prob = problemFactory.getProblemTestdata(1);
            
            
            ApexPages.currentPage().getParameters().put('probid', prob[0].Id );
            BMCServiceDesk__Task__c tsk = new BMCServiceDesk__Task__c();

            //for apex Extension calling controller
            ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(tsk);

            //calling Controller now
            HD_ProblemTaskPage_Ctrl Probctrl = new HD_ProblemTaskPage_Ctrl(stdController);

            String pageurl = Probctrl.saveIt().getUrl();

            
            //ApexPages.currentPage().getParameters().put('','');
            BMCServiceDesk__Task__c tsk1 = new BMCServiceDesk__Task__c();
            
            //for apex Extension calling controller
            ApexPages.Standardcontroller stdController1 = new ApexPages.Standardcontroller(tsk1);

            //calling Controller now
            HD_ProblemTaskPage_Ctrl Probctrl1 = new HD_ProblemTaskPage_Ctrl(stdController1);

          
            //testing some values
            
            System.assertNotEquals(prob[0], null);


            test.stopTest();
        }


    }//


}