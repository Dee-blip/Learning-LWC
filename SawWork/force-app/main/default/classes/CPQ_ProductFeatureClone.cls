public with sharing class CPQ_ProductFeatureClone extends CPQ_SobjectClone{

    // private Set<Id> sourceProductIds;
    // public Map<Id,Id> productIdMap {get; private set;}
    private Id sourceProductId;
    private Id newProductId;
    public CPQ_PartnerDataProcessor productAPIDetails{get; private set;}
    public Map<Id,Id> featureMapping{get; private set;}
    
    //static members
    private static List<String> categories = new List<String>();

    public CPQ_ProductFeatureClone(Id sourceProductId, Id newProductId, CPQ_PartnerDataProcessor productAPIDetails) {
        super('SBQQ__ProductFeature__c');
        this.sourceProductId = sourceProductId;
        this.productAPIDetails = productAPIDetails;
        this.newProductId = newProductId;
        this.featureMapping = new Map<Id,Id>();
    }

    public override List<SObject> beforeClone(){

        List<SObject> clonedRecords = new List<Sobject>();
        List<SObject> parentRecords = new List<Sobject>();
        Map<String, Sobject> featureLineMap = new Map<String, Sobject>();

        // Map<Id, List<sobject>> tempItemStorageMap = new Map<Id, List<sobject>>();
        if(sourceProductId != null){

            String parentQuery =
            ' SELECT ' +
            String.join( parentFieldNames, ',' ) +
            ' FROM ' +
            sObjectType +
            ' WHERE ' +
            ' SBQQ__ConfiguredSKU__c = :sourceProductId' +
            ' LIMIT 1000 '
            ;

            parentRecords = Database.query( parentQuery );

            for(Integer i = 0; i < parentRecords.size(); i++){
                sobject clone = parentRecords[i].clone(false, true);
                clonedRecords.add(clone);
                String uniqueKey = getUniqueKey((SBQQ__ProductFeature__c)clone);
                featureLineMap.put(uniqueKey, clone);
                // clonedRecords.add(parentRecords[i].clone(false, true));
            }

        }
        
        clonedRecords = this.applyAPIchanges(featureLineMap);

        for(Integer i = 0; i < clonedRecords.size(); i++){
            clonedRecords[i].put('CPQExternalID__c', '');
            clonedRecords[i].put('SBQQ__ConfiguredSKU__c', this.newProductId);
        }

        return clonedRecords;
    }

    public override List<sObject> afterClone(List<SObject> clonedRecords){

        System.debug('inserted records ==>' + clonedRecords.size());
        for(Integer i = 0; i < clonedRecords.size(); i++){
            if(clonedRecords[i].getCloneSourceId() != null){
                this.featureMapping.put(clonedRecords[i].getCloneSourceId(),clonedRecords[i].Id);
            }
            if(clonedRecords[i].get('Name') == this.productAPIDetails.usageSectionName){
                this.productAPIDetails.usageSectionSFId = clonedRecords[i].Id;
            }
        }

        return clonedRecords;
    }

    private List<SObject> applyAPIchanges(Map<String,SObject> featureLineMap){

        List<Sobject> returnList = new List<Sobject>();
        
        categories = this.getPicklistValues('sbqq__category__c');
            
        List<CPQ_PM_UtilityClass.PacSectionsApi> productSectionInfo = productAPIDetails.productSectionInfo;
        Decimal usageSectionId = productAPIDetails.usageSectionId;
        List<SBQQ__ProductFeature__c> tempList = new List<SBQQ__ProductFeature__c>();

        for(CPQ_PM_UtilityClass.PacSectionsApi section: productSectionInfo){

            SBQQ__ProductFeature__c pf = createSection(section, usageSectionId);
            pf.SBQQ__ConfiguredSKU__c = newProductId;
            tempList.add(pf);
            if(section.ranking == usageSectionId){
                this.productAPIDetails.usageSectionName = section.name;
            }
            if(section.listItemGroupInfo?.groupingCriterion =='custom' && section.ranking == usageSectionId){
                // logic to know if the product has base fee is to check if is grouped with other PLIs with custom grouping criteria
                pf = createSection(section, usageSectionId);
                pf.Name = 'Platform Fee';
                pf.SBQQ__MinOptionCount__c = 0;
                pf.SBQQ__ConfiguredSKU__c = newProductId;
                tempList.add(pf);
            }
        }

        for(SBQQ__ProductFeature__c item: tempList){
            //logic merge the cloned info and the API info based on uniqueKey
            String uniqueKey = getUniqueKey(item);
            if(featureLineMap.containsKey(uniqueKey)){
                sobject clone = featureLineMap.remove(uniqueKey);
                Map<String, Object> latestChange = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(item));
                returnList.add(this.applyFieldValue(clone, latestChange));
            }
            else{
                returnList.add((Sobject)item);
            }

        }
        
        if(featureLineMap.isEmpty()){
            return returnList;
        }

        //add all the remaining cloned lines
        /* for(String key: featureLineMap.keySet()){
            returnList.add(featureLineMap.get(key));
        } */

        return returnList;
    }

    private static SBQQ__ProductFeature__c createSection(CPQ_PM_UtilityClass.PacSectionsApi section, Decimal usageSectionId){

        SBQQ__ProductFeature__c temp = new SBQQ__ProductFeature__c();
        
        temp.Name = section.name;
        temp.SBQQ__OptionSelectionMethod__c = 'Click';
        temp.SBQQ__ConfigurationFieldSet__c = 'CPQ_OptionConfiguration_Notes_Partner';
        temp.SBQQ__Number__c = section.ranking * 10;
        temp.SBQQ__MinOptionCount__c = 0;
        temp.SBQQ__Category__c = '';

        for(String item: categories){
            if(section.Name.containsIgnoreCase(item) || item.containsIgnoreCase(section.name)){
                //the logic to set category for feature is to check if the available category is part of name e.g SSL certificate has certificate 
                temp.SBQQ__Category__c = item;
                break;
            }
        }
        
        if(temp.SBQQ__Category__c == null || temp.SBQQ__Category__c == ''){
            temp.SBQQ__Category__c = 'Entitlements';
        }
        
        if(section.id == usageSectionId){
            //the max and min option that can be selected in usage section is 1
            temp.SBQQ__MinOptionCount__c = 1;
            temp.SBQQ__MaxOptionCount__c = 1;
            temp.SBQQ__Category__c = 'Usage';
        }

        return temp;
    }

    private static string getUniqueKey(SBQQ__ProductFeature__c po){

        return po.Name.toLowerCase();

    }

}