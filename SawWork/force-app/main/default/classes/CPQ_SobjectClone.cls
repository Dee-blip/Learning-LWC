abstract public with sharing class CPQ_SobjectClone {

    protected List<String> parentFieldNames { get; private set;}
    public String sObjectType {get; private set;}
    private Schema.DescribeSObjectResult[] describeResult {get; set;}

    public CPQ_SobjectClone(String objectName) {

        describeResult = Schema.describeSObjects(new String[]{objectName});
        this.parentFieldNames = new List<String>( describeResult[0].fields.getMap().keySet() );
        this.sObjectType = describeResult[0].getName();

    }

    abstract public List<sObject> beforeClone();

    abstract public List<sObject> afterClone(List<sObject> clonedRecords);
        
    protected sobject applyFieldValue(Sobject line, Map<String, Object> fieldValue){

        /* for(String fieldName: fieldValue.keySet()){
            System.debug(fieldName);
            System.debug(fieldValue.get(fieldName));
            System.debug(this.describeResult[0].fields.getMap().get(fieldName));
        } */

        for(String fieldName: fieldValue.keySet()){

            if(this.describeResult[0].fields.getMap().get(fieldName) == null){
                continue;
            }

            Schema.DisplayType dp = this.describeResult[0].fields.getMap().get(fieldName).getDescribe().getType();

            switch on dp {
                when DOUBLE {
                    line.put(fieldName, DOUBLE.valueOf(fieldValue.get(fieldName)));
                }
                when else {
                    line.put(fieldName, fieldValue.get(fieldName));
                }
            }

        }

        return line;

    }

    protected List<String> getPicklistValues(String fieldName){

        List<String> picklistValues = new List<String>();

        if(!parentFieldNames.contains(fieldName)){
            return picklistValues;
        }

        Schema.DescribeFieldResult fieldResult = describeResult[0].fields.getMap().get(fieldName).getDescribe();

        if(fieldResult.getType() != Schema.DisplayType.PICKLIST){
            return picklistValues;
        }

        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for(Schema.PicklistEntry entry: ple){
            picklistValues.add(entry.getLabel());
        }

        return picklistValues;
    }

}