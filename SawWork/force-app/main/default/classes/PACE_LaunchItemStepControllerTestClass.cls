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
@isTest
public class PACE_LaunchItemStepControllerTestClass {

    private static User CreateUser(String pUsrAlias, String pProfile, String pRole) {
        Profile pr = [select Id from Profile where Name =: pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name =: pRole][0];
        User newUser = new User(alias = pUsrAlias, email = pUsrAlias + '@akamai.com', emailencodingkey = 'UTF-8', lastname = 'NewOwner', languagelocalekey = 'en_US', localesidkey = 'en_US', timezonesidkey = 'America/Los_Angeles', username = pUsrAlias + '@akamai.com', profileid = pr.Id, UserRoleId = null);
        return newUser;
    }

    /* private static PACE_Concept__c CreatePACEConcept(String name, String conceptType,User productManager1, User generalUser1,Product_Line__c plc1){

       //PACE_Concept__c 
       PACE_Concept__c concept = new PACE_Concept__c();

       concept.Comments__c = 'Some comment which no-body reads, but knew you would!';
       concept.Concept_Commit_Date__c = Date.today();

       concept.Concept_Type__c = conceptType;
       concept.Division__c = 'Media';
       concept.Executive_Sponsor__c = generalUser1.Id;
       concept.Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
       concept.Product_Line__c = plc1.Id;
       concept.Product_Manager__c = generalUser1.Id;
       concept.Program_Manager__c = generalUser1.Id;
       concept.Name = name;

       return concept;

     }*/

    private static PACE_Program__c CreatePACEProgram(String name, User productManager1, User generalUser1) {

        PACE_Program__c program = new PACE_Program__c();
        //program.Additional_Detail__c = 
        //program.Concept__c = concept1.Id;
        //program.Concept_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Concept_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Development_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Development_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Dev_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Development_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Development_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Development_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Development_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        program.Division__c = 'Media';
        //program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Launch_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Launch_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Launch_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Launch_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Launch_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        program.Product_Manager__c = productManager1.Id;
        program.Program_Manager__c = productManager1.Id;
        program.Program_Type__c = 'New Product';
        program.Original_CC__c = Date.today();
        program.Planned_CC__c = Date.today();
        //  program.Target_Definition_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //  program.Target_Development_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //  program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        program.Version__c = '1.0';

        return program;


    }

    testmethod static void getPhaseRecordList_PositiveTest() {

        User productManager = CreateUser('pm1', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm2', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('pm3', 'Sales Operations', 'Sales Operations');
        insert testUser;

        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;

            //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            //  insert concept;

            PACE_Program__c lis = CreatePACEProgram('ipv81', productManager, generalUser);
            insert lis;

            //  PACE_LaunchItemStep_Controller lis=new PACE_LaunchItemStep_Controller();
            Apexpages.StandardController stdController = new Apexpages.StandardController(lis);
            PACE_LaunchItemStep_Controller launchitem = new PACE_LaunchItemStep_Controller(stdController);

            Apexpages.StandardController stdController1 = new Apexpages.StandardController(lis);
            PACE_CalendarDocLink_Controller launchitem1 = new PACE_CalendarDocLink_Controller(stdController1);
            Id SIR_MeetingRT =  Schema.SObjectType.PACE_Review_Calendar__c.getRecordTypeInfosByName().get('SIR Meeting').getRecordTypeId();
            PACE_Review_Calendar__c calObj = new PACE_Review_Calendar__c(Review_Date__c = date.today().addDays(100), Name = 'July 31 2012', RecordTypeId = SIR_MeetingRT);
            insert calObj;
            PACE_Phase__c SIRobj = [Select SIR_Meeting_Date__c from PACE_Phase__c where PACE_Program__c =: lis.id limit 1];
            SIRobj.SIR_Meeting_Date__c = calObj.id;
            update SIRobj;

            Apexpages.StandardController stdController3 = new Apexpages.StandardController(calObj);
            PACE_CalendarDocLink_Controller launchitem3 = new PACE_CalendarDocLink_Controller(stdController3);

            User thisUser = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
            System.runAs(thisUser) {

                Test.startTest();
                System.debug(stdController);
                launchitem.getStepRecordList();
                launchitem1.getStepRecordList();
                launchitem3.getStepRecordList();
                Test.stopTest();
            }
        }
    }

}