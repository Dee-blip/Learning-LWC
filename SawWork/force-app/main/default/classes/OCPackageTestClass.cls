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
private class OCPackageTestClass {

    static testMethod void myUnitTest() {
        System.runAs(utilTestClass.getTestRunUser())
        {
        // TO DO: implement unit test
        Campaign_Package__c testocp=new Campaign_Package__c();
        testocp.Name='Test';
        //CR 2768583: Ruchika Sharma: commenting reference of Package_Id__c, as data type of this field needs to be changed
        //testocp.Package_Id__c='tpckid';
        insert testocp;      
 
        testocp = [select id, AKAM_Package_ID__c from Campaign_Package__c where id = :testocp.id];
        System.assert(testocp.AKAM_Package_ID__c.contains('OCP'));
        }
        
      
        
        
    }
}