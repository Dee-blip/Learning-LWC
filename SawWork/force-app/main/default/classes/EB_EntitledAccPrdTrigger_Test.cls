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
 Description : Test Class to check the functioning of the EB_EntitledAccPrdTrigger CR 1733044.
 ###################################################################################
 */
 
@isTest
private class EB_EntitledAccPrdTrigger_Test {

    static testMethod void PositiveUnitTest() {
		ManagedPkgErrorClass.isFromManagedPackage=false;
		//added by ssawhney on 17/1/2014 - fix error with test class
        Account account = CS_InitializeObjects.createAccount('test eb acc product');
        account.AKAM_Account_Id__c = 'TEST-1-30Q89';
        insert account;
        //end of changes
        EB_EntitledAccountProduct__c entAccPrdMap = new EB_EntitledAccountProduct__c();
        entAccPrdMap.EB_AKAMAccountId__c = 'TEST-1-30Q89';
        Database.Insert(entAccPrdMap);
    }
    
    static testMethod void NegativeUnitTest() {
		ManagedPkgErrorClass.isFromManagedPackage=false;
        EB_EntitledAccountProduct__c entAccPrdMap = new EB_EntitledAccountProduct__c();
        entAccPrdMap.EB_AKAMAccountId__c = '4678jhu';
        try
        {
        	Database.Insert(entAccPrdMap);
        }
        catch(Exception e)
        {
        	
        }
        System.assertEquals(entAccPrdMap.EB_Account__c,null);
    }
}