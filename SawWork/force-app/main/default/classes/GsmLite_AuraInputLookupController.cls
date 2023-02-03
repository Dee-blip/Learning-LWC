/**
@author: Shubham Richhariya
MOB-156 : Controller for SF1_LookupComponent cmp

* History:
* =========================
* Developer        Date        Description

Shubham      05/June/17      Controller for SF1_LookupComponent cmp
Shivam       30/July/19		 If value belongs to User and type is coming as Group
                             then, fix the type to correct value i.e. User
**/

public class GsmLite_AuraInputLookupController {
    
    @AuraEnabled
    /*type is sobjectType , value is initial value */
    public static String getCurrentValue(String type, String value){
        if(String.isBlank(type)) {
            return null;
        }
        ID lookupId = null;
        try {
            lookupId = (ID)value;
        } catch(Exception e){
            return null;
        }
        if(String.isBlank(lookupId)) {
            return null;
        }
        SObjectType objType = Schema.getGlobalDescribe().get(type);
        if(objType == null) {
            return null;
        }
        if (value.startsWith('005') && type.endsWithIgnoreCase('group')) {
            type = 'User';
        }
        System.debug('Type :'+type);
        String nameField = getSobjectNameField(objType);
        String query = 'Select Id, '+nameField+' From '+type+' Where Id = \''+lookupId+'\'';
        List<SObject> oList = Database.query(query);
        if(oList.size()==0) {
            return null;
        }
        return (String) oList[0].get(nameField);
    }
    
    /*Utility class for search results*/
    public class SearchResult {
        public String value {get; Set;}
        public Sobject sobjt {get; set;}
    }
    
    /*Returns the "Name" field for a given SObject*/
    private static String getSobjectNameField(SobjectType sobjType){
        
        //describes lookup obj and gets its name field
        String nameField = 'Name';
        Schema.DescribeSObjectResult dfrLkp = sobjType.getDescribe();
        for(schema.SObjectField sotype : dfrLkp.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescObj = sotype.getDescribe();
            if(fieldDescObj.isNameField() ) {
                nameField = fieldDescObj.getName();
                break;
            }
        }
        return nameField;
    }
    
    /*Searchs (using SOSL) for a given Sobject type*/
    @AuraEnabled
    public static String searchSObject(String type, String searchString, String fieldsToShowInSuggestion, String whereClause){
        if(String.isBlank(type) || String.isBlank(searchString)) {
            return null;
        }
        SObjectType objType = Schema.getGlobalDescribe().get(type);
        if(objType == null) {
            return null;
        }
        if(String.isBlank(whereClause) || whereClause == null) {
            whereClause = '';
        }
        else {
            whereClause = ' WHERE ' + whereClause;
        }
        String nameField = getSobjectNameField(objType);
        
        //SFDC-2331
        if(!fieldsToShowInSuggestion.equals('') && !fieldsToShowInSuggestion.equals(nameField))
            fieldsToShowInSuggestion = ','+fieldsToShowInSuggestion;
        else 
            fieldsToShowInSuggestion='';
        
        searchString = searchString.replaceAll('\\\\', '');
        searchString = searchString.replaceAll('\'','\\\\\'');
        
        List<SearchResult> output = new List<SearchResult>();
        
        if (searchString.length() > 2) {
            searchString = '\'*'+searchString+'*\'';
            String soslQuery = 'FIND '+searchString+' IN NAME FIELDS RETURNING '
                + type +'(Id'+fieldsToShowInSuggestion+', '+nameField + whereClause + ' ORDER BY '+nameField+') LIMIT 10'; // SFDC-3093
            
            List<List<SObject>> results =  Search.query(soslQuery);
            
            if(results.size()>0) {
                for(SObject sobj : results[0]) {
                    SearchResult sr = new SearchResult();
                    sr.sobjt = sobj;
                    sr.value = (String)sobj.get(nameField);
                    output.add(sr);
                }
            }
        }
        return JSON.serialize(output);
    }
    
}