/*
* File Name: HD_Custom_lookup_Controller
* Description : This class is used by the Lookup component to display all the possible lookup values
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 22nd, 2021    Aneesh Budnar       PRTORES-2123 - HD Create Knowledge article Search and view Panel in LWC for Lighting UI for staff Part 2
*/
public with sharing class HD_Custom_lookup_Controller {
    @AuraEnabled(cacheable = true)
    public static List<SObject> findRecords(String searchParams) {
        try {
            SearchParams params = (SearchParams)JSON.deserialize(searchParams, SearchParams.class);
            String query = 'SELECT Id, '+params.searchField+(String.isEmpty(params.fields) ? '' : ','+params.fields)+
                    ' FROM '+params.objectName;
            if(!String.isEmpty(params.searchKey) || !String.isEmpty(params.additionalFilters)) {
                query += ' WHERE ';
                String condition1, condition2='';
                if(!String.isEmpty(params.searchKey)) {
                	String key = '%' + params.searchKey + '%';
                    condition1 = params.searchField +' LIKE '+'\'%' + params.searchKey + '%\'';
                }
                if(!String.isEmpty(params.additionalFilters)) {
                    condition2 = params.additionalFilters;
                }
                
                query += (!String.isEmpty(condition1) && !String.isEmpty(condition2)) ? (condition1 + ' AND '+ condition2) : (!String.isEmpty(condition1) ?  condition1 : condition2);
            }
            if(!String.isEmpty(params?.recordRetrieveLimit)) {
            	query += ' LIMIT '+params.recordRetrieveLimit;
            }
            System.debug(System.LoggingLevel.DEBUG, query);
            List<SObject> sObjectList = Database.query(query);
            return sObjectList;
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static List<SObject> getRecentlyViewedRecords(String searchParams) {
        try {
            SearchParams params = (SearchParams)JSON.deserialize(searchParams, SearchParams.class);
            List<String> objectIds = params.objectIds;
            String query = 'SELECT Id, '+params.searchField+(String.isEmpty(params.fields) ? '' : ','+params.fields)+' FROM '+params.objectName +' WHERE Id IN :objectIds';
            System.debug(System.LoggingLevel.DEBUG, query);
            List<SObject> sObjectList = Database.query(query);
            return sObjectList;
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @TestVisible
    private class SearchParams {
        public String searchKey{get;set;}
        public String searchField{get;set;}
        public String fields{get;set;}
        public String objectName{get;set;}
        public String additionalFilters{get;set;}
        public String recordRetrieveLimit{get;set;}
        public List<String> objectIds{get;set;}
    }
}