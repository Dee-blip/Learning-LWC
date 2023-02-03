/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : OCT 28 2014

Base Line : used as a apart of requirment for SRM Console, Unit Test

Purpose : an Unit Test for Controller HD_SRM_ServiceRequest_Extension
          
Usage : used as an test for the business logic , for Controller HD_SRM_ServiceRequest_Extension
          
Test Class Asssociated : NONE

Controller (Boolean): TRUE

Page Used/Asssociated (default -> NONE) : ServiceRequest

Trigger Associated : NONE
Class Associated : HD_SRM_ServiceRequest_Extension.cls
              
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
@isTest
private class HD_Test_SRM_ServiceRequest_Extension {

    static testMethod void PositiveTest() {
        Pagereference pagerf = Page.ServiceRequest ;
        Test.setCurrentPage(pagerf);

        
        //invoking controller
        HD_SRM_ServiceRequest_Extension srmext = new HD_SRM_ServiceRequest_Extension();
        //calling the srmsave method
        List<BMCServiceDesk__Incident__c> srmlist  = srmext.getSrmList();
        srmext.Search_String = 'test';
        if(srmlist.size() > 0)
        {
        	system.assertNotEquals(srmlist.size(),0);
        }
        
        //lets check for other methods
        srmext.nextbutton();
        srmext.previousbutton();
        List<SelectOption> incListview =  srmext.getIncidentListViews();
        srmext.Search_String = 'test';
        srmext.searchResult();
        srmext.emptySearchString();
        srmext.reset();
        srmext.refreshButton();

    }//static testMethod void PositiveTest() {
}