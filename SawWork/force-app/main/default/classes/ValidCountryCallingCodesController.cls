/***
    ValidCountryCallingCodesController
    @author : Sonali Tandon 27/04/2015
    @Description : CR 2991485 - PRM: Handle Phone number validation API
                   This class is used as a VisualForce controller for the VisualForce page "apex/ValidCountryCallingCodes".
                   It returns the list of valid international dialling country codes for phone numbers.
**/
public class ValidCountryCallingCodesController 
{
        public List<CountryCode__c> countrycodes {get; set;}
        public ValidCountryCallingCodesController()
        {
                countrycodes = CountryCode__c.getall().values();
        }
}