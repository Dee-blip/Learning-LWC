public with sharing class CPQ_ConfigurationRuleClone extends CPQ_SobjectClone{

    private Id sourceProductId;
    private Id newProductId;

    private Map<Id, Id> featureIdMap;
    private CPQ_PartnerDataProcessor productAPIDetails;

    private static final Set<String> BILLING_MODEL_RULES = CPQSettings.getMetadataValues('BillingModelRules');
    private static final Set<String> INTEGRATION_RULES = CPQSettings.getMetadataValues('IntegrationRules');

    public CPQ_ConfigurationRuleClone(Id sourceProductId, Id newProductId, CPQ_PartnerDataProcessor productAPIDetails, Map<Id, Id> featureIdMap) {
        super('SBQQ__ConfigurationRule__c');
        
        this.sourceProductId = sourceProductId;
        this.newProductId = newProductId;

        this.featureIdMap = featureIdMap;

        this.productAPIDetails = productAPIDetails;

    }

    public override List<SObject> beforeClone(){
        
        List<SObject> clonedRecords = new List<Sobject>();
        Map<String, Sobject> keyCRMap = new Map<String, Sobject>();

        if(this.sourceProductId != null){

            String parentQuery =
            ' SELECT ' +
            String.join( parentFieldNames, ',' ) +
            ' FROM ' +
            sObjectType +
            ' WHERE ' +
            ' SBQQ__Product__c = :sourceProductId ' 
            ;
        
            List<SObject> parentRecords = Database.query( parentQuery );

            for(Integer i = 0; i < parentRecords.size(); i++){
                String key = this.uniqueKey((SBQQ__ConfigurationRule__c)parentRecords[i]);
                keyCRMap.put(key, parentRecords[i].clone(false, true));
            
            }

        }
        

        clonedRecords = createConfigurationRule(keyCRMap);

        for(Integer i = 0; i < clonedRecords.size(); i++){
                clonedRecords[i].put('SBQQ__Product__c', this.newProductId);
        }

        return clonedRecords;
    }

    public override List<SObject> afterClone(List<SObject> clonedRecords){

        return clonedRecords;
    }

    private List<SObject> createConfigurationRule(Map<String, Sobject> keyCRMap){

        List<Sobject> returnList = new List<sobject>();
        Set<String> ruleNames = new Set<String>();

        ruleNames.addAll(INTEGRATION_RULES);

        if(this.productAPIDetails.hasMultipleBillingModels){
            ruleNames.addAll(BILLING_MODEL_RULES);
        }

        List<SBQQ__ProductRule__c> genericRules = [SELECT Id, Name FROM SBQQ__ProductRule__c WHERE Name IN :ruleNames];

        // for(Id configuredSKU: this.productAPIDetails.keySet()){

            // CPQ_PM_APIDataProcessor productDetails = this.productAPIDetails.get(configuredSKU);
        List<SBQQ__ConfigurationRule__c> tempList = new List<SBQQ__ConfigurationRule__c>();

       
            //create generic billing models
        for(SBQQ__ProductRule__c rule: genericRules){
            tempList.add(createConfigurationRuleLine(rule.Id, this.newProductId, null));
        }

        if(tempList.size() > 0){

            for(SBQQ__ConfigurationRule__c rule: tempList){
                String key = uniqueKey(rule);
                SObject removedItem = keyCRMap.remove(key);
                returnList.add((SObject)rule);
            }
        }
               
        // }

        if(!keyCRMap.isEmpty()){
            for(String key: keyCRMap.keySet()){

                SBQQ__ConfigurationRule__c temp = (SBQQ__ConfigurationRule__c)keyCRMap.get(key);
                
                if(temp.SBQQ__ProductFeature__c != null && featureIdMap.containsKey(temp.SBQQ__ProductFeature__c)){
                    //if feature is not null, check if the mapping exists and add
                    temp.SBQQ__ProductFeature__c = featureIdMap.get(temp.SBQQ__ProductFeature__c);
                    returnList.add((Sobject)temp);
                }
                else if (temp.SBQQ__ProductFeature__c == null){
                    // if feature is null add directly
                    returnList.add((SObject)temp);
                }
               
            }
        }

        return returnList;
    }

    private SBQQ__ConfigurationRule__c createConfigurationRuleLine(Id ruleId, Id configuredSKU, Id featureId){

        SBQQ__ConfigurationRule__c returnLine = new SBQQ__ConfigurationRule__c();

        returnLine.SBQQ__Product__c = configuredSKU;
        returnLine.SBQQ__Active__c = true;
        returnLine.SBQQ__ProductRule__c = ruleId;
        returnLine.SBQQ__ProductFeature__c = featureId;

        return returnLine;
    }

    private String uniqueKey(SBQQ__ConfigurationRule__c cr){

        return (String)cr.SBQQ__ProductRule__c;

    }


}