// Test class for SC_CustomLookUpController

@isTest(seeAllData = false)
public class SC_CustomLookUpController_Test 
{
	public static testMethod void customLookupCtrlrTest()
    {
        Test.startTest();
        User u = [SELECT Name from User where Profile.Name like '%AMG%' and IsActive = TRUE LIMIT 1];
        List<sObject> sObj = SC_CustomLookUpController.fetchLookUpValues(u.Name,'User',NULL);
        sObj = SC_CustomLookUpController.fetchLookUpValues('TestContact','Contact',NULL);
        Test.stopTest();
    }
}