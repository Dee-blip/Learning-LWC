/***
    ValidCountriesController
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class is used as a VisualForce controller for the VisualForce page "apex/ValidCountries".
    			   It returns the list of valid countries {!countries} and the list of valid states {!states} to the page.
*/
public class ValidCountriesController 
{
        public List<Country_List__mdt> countries {get; set;}
        public List<State_List__mdt> states {get; set;}
        public ValidCountriesController()
        {
                countries = [select Label,Check_State__c from Country_List__mdt ORDER BY Label limit 50000];                
                states = [select Label,Associated_Country__c from State_List__mdt ORDER BY Label limit 50000];
        }
}