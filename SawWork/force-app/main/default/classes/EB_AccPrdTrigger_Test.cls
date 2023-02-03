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
 /*
 ###################################################################################
 Author : Jayalakshmi A
 Description : Test Class to check the functioning of the EB_AccPrdTrigger
 Modified: On 08/09/2010 by janantha for CR# 778863 for displaying an error if an invalid Akam account Id is entered.
           On 10/04/2013 by ssawhney for fixing error with test class
 ###################################################################################
 */

 
@isTest
private class EB_AccPrdTrigger_Test {
    
    static testMethod void PositiveUnitTest() {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        EB_AccountProductMap__c accPrdMap = new EB_AccountProductMap__c();
        //added by ssawhney on 10/04/2013 - fix error with test class
        Account account = CS_InitializeObjects.createAccount('test eb acc product');
        account.AKAM_Account_Id__c = 'TEST-1-30Q89';
        insert account;
        //end of changes
        accPrdMap.Name = 'test eb product';
        accPrdMap.EB_Product__c =  'test eb product';
        accPrdMap.EB_AKAM_AccountId__c = 'TEST-1-30Q89';
        Database.Insert(accPrdMap);
    }
    //start of changes on 08/09/2010 by janantha for CR# 778863 for displaying an error if an invalid Akam account Id is entered.
    static testMethod void NegativeUnitTest() {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        EB_AccountProductMap__c accPrdMap = new EB_AccountProductMap__c();
        accPrdMap.EB_AKAM_AccountId__c = '4678jhu';
        try
        {
            Database.Insert(accPrdMap);
        }
        catch(Exception e)
        {
            
        }
        System.assertEquals(accPrdMap.EB_Account__c,null);
    }
    //end of changes on 08/09/2010 by janantha for CR# 778863 for displaying an error if an invalid Akam account Id is entered.
}