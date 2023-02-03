/*

 Author : Sharath
 Description: Contains test cases for the class EB_CtrlAccountWO247Contacts

 */
 
@isTest
private class EB_CtrlAccountWO247Contacts_Test {
    
static testMethod void myUnitTest() { 
		ManagedPkgErrorClass.isFromManagedPackage=false;
        EB_CtrlAccountWO247Contacts controller= new EB_CtrlAccountWO247Contacts();
        Integer x;
        List<Account> accList = new List<Account>();
        Test.startTest();
        accList= controller.getAccountsSans24X7Contacts();
        test.stopTest();
        x=controller.getPremiumcount();
        x=controller.getPrioritycount();
        x=controller.getIndirectcount();
        x=controller.getOthercount();
        x=controller.getcustomerAACount();
        x=controller.getcustomerACount();
        x=controller.getcustomerBCount();
        x=controller.getcustomerCCount();
        x=controller.getcustomerOCount();
    }
}