/* Author: Sharath
Created: 6/4/2011
Description : This class returns the ABI Report URL (stored in a custom setting) back to the page that requested it. This class was created for CR 1027650 CSAT: New Custom Tab to navigate to ABI Relation Survey Upload File Report
*/

public class CS_ABIReportController {

public String getreportUrl(){
CS_FieldMapping__c orgValues = CS_FieldMapping__c.getOrgDefaults();
return orgValues.CS_ProviderFileABIReportLink__c;
}

/*
Test method for the class.
Check whether the string returned is correct using system.assertEquals
*/
 //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
//static testMethod void myTestMethod(){
//ManagedPkgErrorClass.isFromManagedPackage=false;	
//CS_FieldMapping__c orgValues = CS_FieldMapping__c.getOrgDefaults();
//orgValues.CS_ProviderFileABIReportLink__c = 'test url';
//// change it to a dummy value so that we can test against the dummy value
//database.update(orgValues);

//CS_ABIReportController testInstance = new CS_ABIReportController();
//String url = testInstance.getreportUrl();
////system.assertEquals(url,'test url');
//}
}