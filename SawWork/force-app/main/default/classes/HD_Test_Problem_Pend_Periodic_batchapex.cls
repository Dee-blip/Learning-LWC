/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date :

Base Line : used as a apart of requirment for Problem Managment Batch apex Process , Unit Test

Purpose : an Unit Test for batch job class HD_Problem_Pending_Periodic_batchapex.cls

Usage : used as an test for the business logic , for batch job class HD_Problem_Pending_Periodic_batchapex.cls

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated :
Class Associated : HD_Problem_Pending_Periodic_batchapex.cls

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
private class HD_Test_Problem_Pend_Periodic_batchapex {


    public static BMCServiceDesk__Incident__c testIncident;
    public static Id serviceID;
    public static Map<String, String> statusMap; // = new Map<String,String>();
    public static Map<String, String> categoryMap; // = new Map<String,String>();
    public static HD_ProblemTestDataFactory probFactory;

    //public static statusMap
    static {
       

        //initializing custom setting
        HD_BATCH_JOB__c cset = new HD_BATCH_JOB__c();
        cset.HD_Problem_Pending_Periodic_batchapex__c = '{"batch_params":[{"periodicdays":"7"}]}';
        cset.HD_TicketStatusAlert_batchapex__c = '{"batch_params":[{"distributionlistemail":"helpdesk-sa@akamai.com","recordlink":"/apex/BMCServiceDesk__RemedyforceConsole?objectName=Incident__c&record_id=","queryorclause":""}]}';
        insert cset;
        probFactory = new HD_ProblemTestDataFactory();
        statusMap = HD_Test_Data_Factory.statusMap;
        //List<BMCServiceDesk__Problem__c>  plist  = probFactory.getProblemTestdata(1);
    }
    


    
    /*
    *@Usage will test the Batch Apex class
    *
    */
    static testMethod void runAbatchTest() {
        //creating a problem test data
        List<BMCServiceDesk__Problem__c> prb = new List<BMCServiceDesk__Problem__c>();
        prb = probFactory.getProblemTestdata(1);

        for (BMCServiceDesk__Problem__c prob : prb) {
            prob.BMCServiceDesk__FKStatus__c = (Id)statusMap.get('RISK ANALYSIS');
            prob.Status_Change_Comment__c = 'Changed while running test';


        }//for(BMCServiceDesk__Problem__c prob : prb)
        update prb;
        Test.startTest();
        //positive work
        HD_Problem_Pending_Periodic_batchapex hd = new HD_Problem_Pending_Periodic_batchapex(false);
        String cronID = Database.executeBatch(hd);
        System.assertNotEquals(cronID, null);
        //negative work
        HD_Problem_Pending_Periodic_batchapex hd1 = new HD_Problem_Pending_Periodic_batchapex(true);
        cronID = Database.executeBatch(hd1);
        System.assertNotEquals(cronID, null);
        Test.stopTest();

    }//


}// CLASS END