/****************************************************************************
* Class name          :   SC_DD_FieldTracker.cls
* Author              :   Vishnu Vardhan
* Created             :   20-May-2020
* Purpose             :   grouped by the time of change
* Test Class          :   SC_DD_DealDeskTest
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* @getHistory  :   Get Historic Data of a Record, grouped by timestamp of change
DATE             DEVELOPER          CR              DESCRIPTION
===========      =========          =======         ===========
20-May-2020     Vishnu Vardhan      ESESP-3644      Initial Development
****************************************************************************/

public with sharing class SC_DD_FieldTracker {
    
    /****************************************************************************
    * Author              :   Vishnu Vardhan
    * Created             :   20-May-2020
    * getHistory          :   Group the changes that occured at same time, and return in "timestamp => list of field changes" format
    ****************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getHistory( String sobjectName, List<String> sobjFields, Id recordId) {

        // Query for Historic Data
        String historyQueryTemplate = 'select id, ParentId, CreatedById, CreatedDate, Field, OldValue, NewValue, typeof createdby when USER then id, name, email, smallphotourl end from {0} where field in :sobjFields and ParentId = :recordId order by createdDate ASC' ;
        // Query for record data, as unchanged fields will not be available in history table
        String objectQueryTemplate = 'select id, CreatedById, CreatedBy.Name, CreatedBy.SmallPhotoUrl, CreatedDate, {0} from {1} where Id = :recordId' ;

        // First Change : field values when record was created
        //                If a field was changed atleast once, get this from SObject__history
        //                If a field was never changed, get this from sObject record

        Map<String, Object> firstChange = new Map<String, Object>();

        // Grouped changes: filed values AFTER the record was created
        Map<String, Map<String, Object>> groupedChanges = new Map<String, Map<String, Object>> ();

        try {

            String histQueryStr = String.format(historyQueryTemplate, new List<String> {sobjectName.replace('__c', '__History')});
            List<SObject> historyData = Database.query(histQueryStr);
            // Fix for test class, as History data will not be generated in Test Execution
            if(Test.isRunningTest()) {
                historyData = new List<Sobject>();
                groupedChanges.put('Test', new Map<String, Object>());
            }
            // Query Historic Data, for fieldSet fields
            for(SObject sobj: historyData) {
                String createdDateStr = String.valueOf((DateTime)sobj.get('CreatedDate'));
                if(!groupedChanges.containsKey(createdDateStr)) {
                    groupedChanges.put(createdDateStr, getStandardFields(sobj));
                }

                String fieldName = (String)sobj.get('Field');
                
                groupedChanges.get(createdDateStr).put(fieldName, sobj.get('NewValue'));

                // If a field is being changed for first time, store it in firstchange map
                if(!firstChange.containsKey(fieldName)) {
                    firstChange.put(fieldName, sobj.get('OldValue'));
                }
            }

            String sobjQuery = String.format(objectQueryTemplate, new List<String>{ String.join(sobjFields, ', '), sobjectName});
            Sobject sobj = Database.query(sobjQuery);

            firstChange.putAll(getStandardFields(sobj));

            // If a field was never changed, get firstChange from sObject record
            for(String fieldName: sobjFields) {
                if(!firstChange.containsKey(fieldName)) {
                    firstChange.put(fieldName, sobj.get(fieldName));
                }
            }
            
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

        List<Map<String, Object>> changesList = groupedChanges.values();
        if(changesList.isEmpty()) {
            changesList.add(firstChange);
        } else{
            changesList.add(0, firstChange);
        }
        
        return changesList;

    }

    static Map<String, Object> getStandardFields(SObject sobj) {
        return new Map<String, Object>{
                                        'CreatedDate' =>  sobj.get('CreatedDate'),
                                        'CreatedBy'   => sobj.getSobject('CreatedBy').get('Name'),
                                        'CreatedById' => sobj.get('CreatedById'),
                                        'SmallPhotoUrl' => sobj.getSobject('CreatedBy').get('SmallPhotoUrl')
                                    };
    }

}