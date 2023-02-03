/***
    ValidCountriesControllerTestClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class implements the test cases for the Visual Force controller - "ValidCountriesController"
*/
@isTest(seeAllData = false)
private class ValidCountriesControllerTestClass 
{
	/** 
	    myUnitTest() 
	    - This testmethod checks if the number of Country & State records retrieved by the Controller is same as the number of Country & State records in the respective entities.
	*/
    static testMethod void myUnitTest() 
    {
    	Test.startTest();
    	Integer countriesCount = [select Id from Country_List__mdt limit 50000].size();
    	Integer statesCount = [select Id from State_List__mdt limit 50000].size();
        PageReference pageRef = Page.ValidCountries;
        Test.setCurrentPageReference(pageRef);
        ValidCountriesController controller = new ValidCountriesController();
        system.assertEquals(controller.countries.size(), countriesCount);
        system.assertEquals(controller.states.size(), statesCount);
        Test.stopTest();
    }
}