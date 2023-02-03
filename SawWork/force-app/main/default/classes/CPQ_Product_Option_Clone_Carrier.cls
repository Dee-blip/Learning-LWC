public with sharing class CPQ_Product_Option_Clone_Carrier extends CPQ_SobjectClone {

    private static final Integer OPTION_NUMBER_OFFSET = 10;
    
    //Static Variables
    private static Map<String, Product2> optionalProductsMapById = new Map<String, Product2>();
    
    private static Integer optionCounter = 0;
    //Instance Variables
    private Id sourceProductId;
    private Id newProductId;

    public Map<Id,Id> featureIdMap{get; private set;}
    public CPQ_CarrierDataProcessor productAPIDetails{get; private set;}
    public Map<Id,Id> optionMapping{get;private set;}



    public CPQ_Product_Option_Clone_Carrier(Id sourceProductId, Id newProductId, Map<Id,Id> featureIdMap,  CPQ_CarrierDataProcessor productAPIDetails) {

        super('SBQQ__ProductOption__c');

        this.sourceProductId = sourceProductId;
        this.newProductId = newProductId;

        this.productAPIDetails = productAPIDetails;
        
        this.featureIdMap = featureIdMap;
        this.optionMapping = new Map<Id,Id>();

    }

    public override List<sobject> beforeClone(){
        
        List<SObject> clonedRecords = new List<Sobject>();
        Map<String, Sobject> keyPoLineMap = new Map<String, Sobject>();

        if(sourceProductId != null){

            String parentQuery =
            ' SELECT ' +
            String.join( parentFieldNames, ',' ) +
            ' FROM ' +
            sObjectType +
            ' WHERE ' +
            ' SBQQ__ConfiguredSKU__c = :sourceProductId ' 
            ;

            List<SObject> parentRecords = Database.query( parentQuery );

            for(Integer i = 0; i < parentRecords.size(); i++){
                sobject clone = parentRecords[i].clone(false, true);
                clonedRecords.add(clone);
                String uniqueKey = this.getUniqueKey((SBQQ__ProductOption__c)clone);
                keyPoLineMap.put(uniqueKey, clone);
            }

        }
        
        //would need a map<productId, Map<featureId, featureNumber>> 
        clonedRecords = applyAPIchanges(clonedRecords, keyPoLineMap);

        for(Integer i = 0; i < clonedRecords.size(); i++){
            clonedRecords[i].put('CPQExternalID__c', '');
            clonedRecords[i].put('SBQQ__ConfiguredSKU__c', newProductId);
            
        }
            

        return clonedRecords;
    }

    public override List<sObject> afterClone(List<SObject> clonedRecords){

        for(Integer i = 0; i < clonedRecords.size(); i++){
            if(clonedRecords[i].getCloneSourceId() != null){
                this.optionMapping.put(clonedRecords[i].getCloneSourceId(),clonedRecords[i].Id);
            }
        }

        return clonedRecords;
    }

    private List<sobject> applyAPIchanges(List<Sobject> clonedRecords, Map<String, Sobject> keyPoLineMap){

        List<Sobject> returnList = new List<Sobject>();
          
        List<String> allOptionalProducts = new List<String>();
        
        allOptionalProducts.addAll(this.productAPIDetails.optionalMktProdIdsCarrier);
        
        for(Product2 product : [SELECT Id,Name, ProductCode,Product_Notes__c, SBQQ__ConfigurationType__c, SBQQ__ConfigurationEvent__c FROM Product2 WHERE ProductCode IN :allOptionalProducts]) {
        
            CPQ_LogException.logInformation('optional products: '+product); 
            
            optionalProductsMapById.put(product.Product_Notes__c, product);
            
            
        }
        
        //getting the feature
        Map<String, Id> featureMap = new Map<String, Id>();
        for(SBQQ__ProductFeature__c pf: [SELECT Id, Name, SBQQ__Number__c, SBQQ__ConfiguredSKU__c FROM SBQQ__ProductFeature__c WHERE SBQQ__ConfiguredSKU__c = :this.newProductId ]){
            featureMap.put(pf.Name.toLowerCase(), pf.Id);
            
        }
        
        List<CPQ_PM_UtilityClass.ListItems> filteredListItems = this.productAPIDetails.filteredListItems;
        List<SBQQ__ProductOption__c> poList = new List<SBQQ__ProductOption__c>();
        // Id destProdId = productIdMap.get(configuredSKU);

        for(CPQ_PM_UtilityClass.ListItems li: filteredListItems){

            String featureName = li.pricingModel == 'Flat Fee' ? 'platform fee' : li.sectionName.toLowerCase();
            Id featureId = featureMap.containsKey(featureName) ? featureMap.get(featureName) : featureMap.get(li.sectionName.toLowerCase()) ;

            poList.add(createOptionLineData(li,featureId));
            
            
        }

        for(SBQQ__ProductOption__c po: poList){
            po.SBQQ__configuredSKU__c = this.newProductId;
            String uniqueKey = this.getUniqueKey(po);
            if(keyPoLineMap.containsKey(uniqueKey)){
                sobject clone = keyPoLineMap.remove(uniqueKey);
                Map<String, Object> latestChange = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(po));
                returnList.add(this.applyFieldValue(clone, latestChange));
            }
            else{
                returnList.add((Sobject)po);
            }
        }
        

        //if cloned lines are empty return the generated lines so far
        if(keyPoLineMap.isEmpty()){
            return returnList;
        }

        return returnList;
    }

    private static SBQQ__ProductOption__c createOptionLineData(CPQ_PM_UtilityClass.ListItems listItem, Id featureId){
        //TODO: the operations in this method can be optimized further
        SBQQ__ProductOption__c tempHolder = new SBQQ__ProductOption__c();
        tempHolder.SBQQ__ConfiguredSKU__c = null; // dynamically fetched based on product code
        tempHolder.SBQQ__OptionalSKU__c = null; //dynamically fetched based on Name
        tempHolder.SBQQ__Feature__c = featureId; // need to get dynamically baseon the line section
        tempHolder.SBQQ__Number__c = ++optionCounter * OPTION_NUMBER_OFFSET;
        tempHolder.SBQQ__Quantity__c = listItem.defaultEntitlement?.value > 0 ? listItem.defaultEntitlement?.value : 1;
        tempHolder.CPQ_Associated_Product_Id__c = listItem.associatedProdId != null ? listItem.associatedProdId: listItem.productId;
        tempHolder.CPQ_Billing_Frequency__c = listItem.billingFrequency;
        tempHolder.CPQ_Charge_Type__c = listItem.pricingModel;
        tempHolder.CPQ_PAC_Line_Item_Id1__c = listItem.name;
        tempHolder.CPQ_Product_Notes__c = listItem.name;
        tempHolder.SBQQ__Type__c = 'Related Product';
        tempHolder.CPQ_Measurement__c = listItem.uom;

        

        if(listItem.pricingModel != 'Flat Fee'){
            tempHolder.SBQQ__QuantityEditable__c = true;
        }

        if(listItem.sectionName == 'Included' || listItem.pricingModel == 'Included Units'){

            tempHolder.SBQQ__Bundled__c = true;
            tempHolder.SBQQ__Required__c = true;
            tempHolder.SBQQ__Selected__c = true;
            tempHolder.SBQQ__QuantityEditable__c = false;

        }
        
        if (listItem.listItemGroup != null && listItem.listItemSet != null) {
            tempHolder.CPQ_ListItemGroup__c = listItem.listItemGroup + '::' + listItem.listItemGroupCriteria;
            tempHolder.CPQ_ListItemSet__c = listItem.listItemSet;
        }



            
                Product2 subproduct = optionalProductsMapById.get(listItem.name);
                CPQ_LogException.logInformation('subproduct: '+subproduct);
                tempHolder.SBQQ__OptionalSKU__c = subproduct?.Id ;
                //update included settings eg when any certificate is included i.e. it has an associatedId but section is included 
                if(subproduct.SBQQ__ConfigurationType__c == 'Allowed' || subproduct.SBQQ__ConfigurationType__c == 'Required'){
                // if it is a configurable product remove the uom from the main line as sub-product inside will have to be selected
                tempHolder.CPQ_Measurement__c = null;
            }
            
           

            
       // }

        if(listItem.listItemSet != null){
            tempHolder.CPQ_Product_Notes__c = listItem.listItemSet;
        }
        
        tempHolder.CPQ_Billing_Model__c = 'Fee';
        //tempHolder.CPQ_PAC_Line_Item_Id__c = setQuoteDocumentNotation(listItem, usageSection);
        //TODO: to handle the CPQ_PAC_Line_Item_Id__c field which influences the the quote document creation
        
        return tempHolder;

    }


    private string getUniqueKey(SBQQ__ProductOption__c poLine){

        return poLine.CPQ_Associated_Product_Id__c + poLine.CPQ_Measurement__c + poLine.CPQ_Charge_Type__c + poLine.CPQ_Billing_Frequency__c + poLine.CPQ_Billing_Model__c;
    }
    

    
    
}