/***
    ValidCountryCallingCodesControllerTest
    @author : Sonali Tandon - 27/04/2015-  CR 2991485 - PRM: Handle Phone number validation API 
    @Description : This class implements the test cases for the Visual Force controller - "ValidCountryCallingCodesController"
*/
@isTest
private class ValidCountryCallingCodesControllerTest 
{
    static
    {
        utilTestClass.insertCustomSettings(new List<String>{'CountryCode'});
    }
    
    static testMethod void myUnitTest() 
    {
        Test.startTest();
        Integer countryCodeCount = [select Id from CountryCode__c limit 50000].size();
        PageReference pageRef = Page.ValidCountryCallingCodes;
        Test.setCurrentPageReference(pageRef);
        ValidCountryCallingCodesController controller = new ValidCountryCallingCodesController();
        System.assertEquals(controller.countrycodes.size(), countryCodeCount);
        Test.stopTest();
    }
}