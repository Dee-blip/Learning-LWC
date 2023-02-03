/*
* File Name: HD_Advanced_Search_Controller
* Description : This class is used by the Advanced Search component to fetch fields for querying and building the query logic
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 22nd, 2021    Aneesh Budnar       PRTORES-2123 - HD Create Knowledge article Search and view Panel in LWC for Lighting UI for staff Part 2
*/
public class HD_Advanced_Search_Controller {
    @AuraEnabled(cacheable = true)
    public static String getFields(String objectName) {
        try {
            Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
            List<FieldMetadata> metaData = new List<FieldMetadata>();
            for(Schema.SObjectField sfield : fieldMap.Values())
            {
                Schema.DescribeFieldResult dfield = sfield.getDescribe();
                FieldMetadata meta = new FieldMetadata();
                meta.fieldLabel = dfield.getLabel();
                meta.fieldApiName = dField.getName();
                meta.fieldType = String.valueOf(dField.getType());
                if(dField.getReferenceTo().size() > 0) {
                    meta.typeApiName = dField.getReferenceTo()[0].getDescribe().getName();
                }
                metaData.add(meta);
            }
            return JSON.serialize(metaData);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static String getAdvancedSearchFilter(String logicalOperator, String filterLogic, String filterConditions) {
        try {
            List<Condition> conditions = (List<Condition>)JSON.deserialize(filterConditions, List<Condition>.class);
            return (logicalOperator == ' CUSTOM ') ? handleCustomLogicExpression(conditions, filterLogic) 
                : handleLogicalConditionExpression(conditions, logicalOperator);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static String handleLogicalConditionExpression(List<Condition> conditions, String logicalOperator) {
        String finalLogic = '';
        for(Integer cond = 0; cond < conditions.size(); cond++) {
            finalLogic += interpretCondition(conditions[cond]);
            if(cond != conditions.size() - 1) {
                finalLogic += logicalOperator;
            }
        }
        return finalLogic;
    }
    
    private static String handleCustomLogicExpression(List<Condition> conditions, String filterLogic) {
        String finalLogic = '';
        Map<Integer, Condition> conditionMap = new Map<Integer, Condition>();
        for(Integer cond =0; cond < conditions.size(); cond++) {
            conditionMap.put(conditions[cond].order, conditions[cond]);
        }
        for(Integer index = 0; index < filterLogic.length(); index++) {
            String character = (index == filterLogic.length()-1) ? filterLogic.substring(index) 
                : filterLogic.substring(index, index+1);
            if(character.isNumeric()){
                Integer order = Integer.valueOf(character);
                if(conditionMap.containsKey(order)) {
                    finalLogic += interpretCondition(conditionMap.get(order));
                }
            }
            else {
                finalLogic += character;
            }
        }
        return finalLogic;
    }
    
    private static String interpretCondition(Condition condition) {
        if(condition.isPicklist || condition.isLookup || condition.fieldApiName == 'Id' || condition.fieldApiName == 'Name') {
            return condition.fieldApiName + ' ' + condition.operator + ' \'' + condition.fieldValue + '\'';
        }
        else {
            return condition.fieldApiName + ' ' + condition.operator + ' ' + condition.fieldValue;
        }
    }
    
    @TestVisible
    private class FieldMetadata {
        public String fieldLabel {get;set;}
        public String fieldApiName {get;set;}
        public String fieldType {get;set;}
        public String typeApiName {get;set;}
    }
    
    @TestVisible
    private class Condition {
        public String fieldApiName {get;set;}
        public String operator {get;set;}
        public String fieldValue {get;set;} 
        public Integer order {get;set;}
        public Boolean isPicklist {get;set;}
        public Boolean isLookup {get;set;}
        public Boolean isLWCInput{get;set;}
        public String type {get;set;}
    }
}