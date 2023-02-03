/*
* Details : Class for utility methods to provide temporary fix for Flow that passes SObject with Picklist field as input to Invocable Apex
* Developer         Date            Version     Update 
* kimishra          23-FEB-2021     1.0         Initial logic to clean the picklist values for sObjects
* 
* NOTE: The issue is scheduled to be fixed in Summer'21, after which this class can be commented.
*
*/
public class CPQ_UtilityClass_Flow {
    
    private Map<String, Schema.SObjectField> sObjectFieldsMap;

    public CPQ_UtilityClass_Flow (String sObjectType) {
        this.sObjectFieldsMap = Schema.describeSObjects(new List<String> { sObjectType })[0].fields.getMap();
    }

    public List<SObject> cleanPickListValues(List<SObject> records) {
        for (SObject record : records) {
            cleanPickListValues(record);
        }
        return records;
    }

    public SObject cleanPickListValues(SObject record) {
        for (String fieldName : record.getPopulatedFieldsAsMap().keySet()) {
            if (sObjectFieldsMap.get(fieldName).getDescribe().getType() == Schema.DisplayType.PICKLIST) {
                record.put(fieldName, String.valueOf(record.get(fieldName)));
            }
        }
        return record;
    }
}