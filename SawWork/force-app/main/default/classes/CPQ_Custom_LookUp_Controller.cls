/* CPQ_Custom_LookUp_Controller is a reusable custom lookup component  
* Test Class: CPQ_Test_Lookup_Search_Result
* @author  Mausam Singh
* @since   2021-09-23
*/

public with sharing class CPQ_Custom_LookUp_Controller {
    
    
    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTerm, String myObject) {
        String myQuery = null;
        
        myQuery = 'Select Id, Name from '+myObject+' Where Name Like  \'%' + searchTerm + '%\' LIMIT  5';
        
        List<sObject> lookUpList = database.query(myQuery);
        System.debug(LoggingLevel.INFO, 'lookUpList ==> ' + lookUpList);
        return lookUpList;
    }
}