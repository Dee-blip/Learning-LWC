/**
   @author: Shubham Richhariya
   MOB-164 : Utility Class for GSMLite team
 * History:
 * =========================
 * Developer        Date        Description

   Shubham    21/June/17        Added this class for MOB-164.
   Shubham    21/June/17		added method populatePickList
   Nagaraj    22/Nov/17        Added method populatePickListWithLabelAndValues, MapObject Class.
   Nagaraj    24/Jan/18        Added method getUIThemeDescription
 **/

public with sharing class GSMLite_UtilClass {


        public GSMLite_UtilClass() {

        }

        public class MapObject {
                @AuraEnabled private String label  {get; set;}
                @AuraEnabled private String value  {get; set;}
                @AuraEnabled private Boolean isSelected  {get; set;}
                public MapObject(String label, String value) {
                        this.label = label;
                        this.value = value;
                        this.isSelected = false;
                }
                public MapObject(String label, String value, Boolean isSelected) {
                        this.label = label;
                        this.value = value;
                        this.isSelected = isSelected;
                }
        }

        @AuraEnabled
        public static String populatePickListWithLabelAndValues(String sobjectName, String picklistFieldName) {

                Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                List<String> objNames = new List<String>(schemaMap.keySet());
                List<MapObject> options = new List<MapObject>();

                Map <String, Schema.SObjectField> fieldMap = schemaMap.get(sobjectName).getDescribe().fields.getMap();
                Schema.DescribeFieldResult fieldResult = fieldMap.get(picklistFieldName).getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry f : ple) {
                        options.add(new MapObject(f.getLabel(), f.getValue()));
                }

                return JSON.serialize(options);
        }

        @AuraEnabled
        public static String getUIThemeDescription() {
                String theme = UserInfo.getUiThemeDisplayed();
                return theme;
        }

        /*
           returns piclist values from a given sobject and given picklist field
         */
        public static List<String> populatePickList(String sobjectName, String picklistFieldName) {
                Map <String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
                List<String> objNames = new List<String>(schemaMap.keySet());
                List<String> options = new List<String>();

                Map <String, Schema.SObjectField> fieldMap = schemaMap.get(sobjectName).getDescribe().fields.getMap();
                Schema.DescribeFieldResult fieldResult = fieldMap.get(picklistFieldName).getDescribe();
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for (Schema.PicklistEntry f : ple) {
                        options.add(f.getLabel());
                }

                return options;
        }

        public static Map<String,List<String>> GetDependentOptions(String pObjName, String pControllingFieldName, String pDependentFieldName){
                Map<String,List<String>> objResults = new Map<String,List<String>>();
                //get the string to sobject global map
                Map<String,Schema.SObjectType> objGlobalMap = Schema.getGlobalDescribe();
                if (!objGlobalMap.containsKey(pObjName))
                        return objResults;
                //get the type being dealt with
                Schema.SObjectType pType = objGlobalMap.get(pObjName);
                Map<String, Schema.SObjectField> objFieldMap = pType.getDescribe().fields.getMap();
                //verify field names
                if (!objFieldMap.containsKey(pControllingFieldName) || !objFieldMap.containsKey(pDependentFieldName))
                        return objResults;
                //get the control values
                List<Schema.PicklistEntry> ctrl_ple = objFieldMap.get(pControllingFieldName).getDescribe().getPicklistValues();
                //get the dependent values
                List<Schema.PicklistEntry> dep_ple = objFieldMap.get(pDependentFieldName).getDescribe().getPicklistValues();
                //iterate through the values and get the ones valid for the controlling field name
                TStringUtils.Bitset objBitSet = new TStringUtils.Bitset();
                //set up the results
                for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++) {
                        //get the pointer to the entry
                        Schema.PicklistEntry ctrl_entry = ctrl_ple[pControllingIndex];
                        //get the label
                        String pControllingLabel = ctrl_entry.getLabel();
                        //create the entry with the label
                        objResults.put(pControllingLabel,new List<String>());
                }
                //cater for null and empty
                //objResults.put('',new List<String>());
                //objResults.put(null,new List<String>());
                //check the dependent values
                for(Integer pDependentIndex=0; pDependentIndex<dep_ple.size(); pDependentIndex++) {
                        //get the pointer to the dependent index
                        Schema.PicklistEntry dep_entry = dep_ple[pDependentIndex];
                        //get the valid for
                        String pEntryStructure = JSON.serialize(dep_entry);
                        TStringUtils.TPicklistEntry objDepPLE = (TStringUtils.TPicklistEntry)JSON.deserialize(pEntryStructure, TStringUtils.TPicklistEntry.class);
                        //if valid for is empty, skip
                        if (objDepPLE.validFor==null || objDepPLE.validFor=='') {
                                continue;
                        }
                        //iterate through the controlling values
                        for(Integer pControllingIndex=0; pControllingIndex<ctrl_ple.size(); pControllingIndex++) {
                                if (objBitSet.testBit(objDepPLE.validFor,pControllingIndex)) {
                                        //get the label
                                        String pControllingLabel = ctrl_ple[pControllingIndex].getLabel();
                                        objResults.get(pControllingLabel).add(objDepPLE.label);
                                }
                        }
                }
                return objResults;
        }

}