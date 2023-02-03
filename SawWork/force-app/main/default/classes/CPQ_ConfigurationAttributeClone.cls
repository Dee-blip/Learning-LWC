public with sharing class CPQ_ConfigurationAttributeClone extends CPQ_SObjectClone{

    // public Map<Id,Id> productIdMap{get; private set;}
    // private Set<Id> sourceProductIds;
    // private Set<Id> destinationProductIds;
    private Id sourceProductId;
    private Id newProductId;

    CPQ_PartnerDataProcessor productAPIDetails;
    private Map<Id,Id> featureIdMap;
    
    public CPQ_ConfigurationAttributeClone(Id sourceProductId, Id newProductId, CPQ_PartnerDataProcessor productAPIDetails, Map<Id,Id> featureIdMap) {

        super('SBQQ__ConfigurationAttribute__c');
        
        this.sourceProductId = sourceProductId;
        this.newProductId = newProductId;

        this.productAPIDetails = productAPIDetails;
        this.featureIdMap = featureIdMap;

    }

    public override List<SObject> beforeClone(){

        List<SObject> clonedRecords = new List<Sobject>();
        Map<String, Sobject> keyCAMap = new Map<String, Sobject>();

        if(sourceProductId != null){

            String parentQuery =
            ' SELECT ' +
            String.join( parentFieldNames, ',' ) +
            ' FROM ' +
            sObjectType +
            ' WHERE ' +
            ' SBQQ__Product__c = :sourceProductId ' 
            ;
            //would need a map<productId, Map<featureId, featureNumber>>
            // 
            List<SObject> parentRecords = Database.query( parentQuery );

            
            for(Integer i = 0; i < parentRecords.size(); i++){
                String key = this.uniqueKey((SBQQ__ConfigurationAttribute__c)parentRecords[i]);
                keyCAMap.put(key, parentRecords[i].clone(false, true));
            
            }

        }
        
        clonedRecords = generateCofigurationAttribute(keyCAMap);

        for(Integer i = 0; i < clonedRecords.size(); i++){
            // clonedRecords[i].put('CPQExternalID__c', '');
                clonedRecords[i].put('SBQQ__Product__c', newProductId);
                // clonedRecords[i].put('SBQQ__Feature__c', ''); // TODO: this logic has to be changed;
        }

        return clonedRecords;
    }

    private List<Sobject> generateCofigurationAttribute(Map<String, SObject> keyCAMap){

        List<SObject> returnList = new List<Sobject>();

        List<SBQQ__ConfigurationAttribute__c> tempList = new List<SBQQ__ConfigurationAttribute__c>();
        if(this.productAPIDetails.hasMultipleBillingModels){
            SBQQ__ConfigurationAttribute__c tempLine = new ConfigurationAttributeBuilder('Billing Model', newProductId, 'CPQ_Billing_Model__c')
                                                            .isRequired(true)
                                                            .withDefaultValue('Quote__c', 'CPQ_Default_Billing_Model__c')
                                                            .withFeature(this.productAPIDetails.usageSectionSFId)
                                                            .immediateApply(true)
                                                            .getRecord();
            tempList.add(tempLine);
        }

        if(tempList.size()>0){

            for(SBQQ__ConfigurationAttribute__c ca: tempList ){
                String key = this.uniqueKey(ca);
                keyCAMap.remove(key);
                returnList.add((SObject)ca);
            }
        }
        // }
        
        if(!keyCAMap.isEmpty()){
            // returnList.AddAll(keyCAMap.values());
            for(String key: keyCAMap.keySet()){

                SBQQ__ConfigurationAttribute__c temp = (SBQQ__ConfigurationAttribute__c)keyCAMap.get(key);
                
                if(temp.SBQQ__Feature__c != null && featureIdMap.containsKey(temp.SBQQ__Feature__c)){
                    
                    temp.SBQQ__Feature__c = featureIdMap.get(temp.SBQQ__Feature__c);
                    returnList.add((Sobject)temp);
                }
               
            }
        }

        return returnList;

    }

    public override List<SObject> afterClone(List<SObject> clonedRecords){

        return clonedRecords;
    }

    private String uniqueKey( SBQQ__ConfigurationAttribute__c ca){

        return ca.Name;
    }

    public class ConfigurationAttributeBuilder {
        
        private SBQQ__ConfigurationAttribute__c newRecord;
        public ConfigurationAttributeBuilder(String name, Id productId, String targetField){

            newRecord = new SBQQ__ConfigurationAttribute__c();
            newRecord.Name = name;
            newRecord.SBQQ__Product__c = productId;
            newRecord.SBQQ__TargetField__c = targetField;
            newRecord.SBQQ__DisplayOrder__c = 1;
            newRecord.SBQQ__ColumnOrder__c = '3';
            newRecord.SBQQ__Position__c = 'Top';
        }

        public ConfigurationAttributeBuilder isRequired(Boolean required){
            this.newRecord.SBQQ__Required__c = required;
            return this;
        }

        public ConfigurationAttributeBuilder withFeature(Id featureId){
            this.newRecord.SBQQ__Feature__c = featureId;
            return this;
        }

        public ConfigurationAttributeBuilder withDefaultValue(String defaultObject, String defaultField){

            this.newRecord.SBQQ__DefaultObject__c = defaultObject;
            this.newRecord.SBQQ__DefaultField__c = defaultField;

            return this;
        }

        public ConfigurationAttributeBuilder immediateApply(Boolean apply){
            this.newRecord.SBQQ__AppliedImmediately__c = apply;

            return this;
        }

        public SBQQ__ConfigurationAttribute__c getRecord(){
            return this.newRecord;
        }
    }




}