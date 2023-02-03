/**
 @author: Shubham Richhariya
 MOB-164 : Test class for utility class - GSMLite_UtilClass
 * History:
 * =========================
 * Developer        Date        Description
    
   Shubham    21/June/17        Added this class for MOB-164.
   Shubham    21/June/17		added method populatePickList
**/

@isTest
private class GSMLite_UtilTestClass {
	
	private static testmethod void testPopulatePickList()
	{
		List<String> options = GSMLite_UtilClass.populatePickList('SFDC_MDF__c', 'SOE_or_PubSec_Event__c');
		System.assertNotEquals(options.size(),0);
	}
	
}