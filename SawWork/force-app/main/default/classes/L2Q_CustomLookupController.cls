/***
 Author : Rajesh Kumar 
 JIRA # : SFDC-6378 
 Description : Created this class to be used in Generic Lookup component for LWC .
 Future Improvement (>>): List of display field , DateTime in Local Format for display field . 
***/

/**Begin Rajesh Kumar JIRA # SFDC-6378  */
public with sharing class L2Q_CustomLookupController {
    private static final Integer MAX_LIMIT = 2000;
    @AuraEnabled(cacheable = true)
    public static List<SObject> findRecords(String searchKey, String objectName, String searchField, Integer recordLimit, String whereClause, String suggestionField) {
        List<SObject> sObjectList = new List<SObject> ();
        suggestionField = suggestionField == null ? '' : suggestionField;
        suggestionField = String.escapeSingleQuotes((!suggestionField.equals('') && !suggestionField.equals(searchKey)) ? suggestionField + ' ,' : '');
        searchKey = String.escapeSingleQuotes(searchKey);
        objectName = String.escapeSingleQuotes(objectName);
        searchField = String.escapeSingleQuotes(searchField);
        recordLimit = (recordLimit > MAX_LIMIT) ? MAX_LIMIT : recordLimit;
        whereClause = (String.isEmpty(whereClause)) ? '' : whereClause;
        if (!String.isEmpty(searchKey)) {
            String QUERY = 'Select Id, ' + suggestionField + ' ' + searchField + +' From ' + objectName + ' Where ' + searchField + ' LIKE \'%' + searchKey + '%\' ' + ' ' + whereClause + ' Limit  ' + recordLimit;
            System.debug('QUERY # RK #' + QUERY);
            sObjectList = Database.query(QUERY);
            System.debug('SOBJECTLIST # RK #' + sObjectList);
        }
        return sObjectList;
    }
}
/**End Rajesh Kumar JIRA # SFDC-6378  */