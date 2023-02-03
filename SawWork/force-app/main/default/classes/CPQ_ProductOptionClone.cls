public with sharing class CPQ_ProductOptionClone extends CPQ_SobjectClone {

    private static final Integer OPTION_NUMBER_OFFSET = 10;
    private static final Map<String, String> BILL_MODEL = new Map<String, String>{
         'Straight Line Commitment' => 'Straight-line Commitment'
    };
    private static final Map<String, Object> BILLING_MODEL_TYPE = (Map<String, List<String>>)JSON.deserialize(CPQSettings.getMetadataValue('BillingModelTerms'), Map<String, List<String>>.class);
    //Static Variables
    private static Map<String, Product2> optionalProductsMapById = new Map<String, Product2>();
    private static Map<String, Product2> optionalProductsMapByName = new Map<String, Product2>();
    private static Integer optionCounter = 0;
    //Instance Variables
    private Id sourceProductId;
    private Id newProductId;

    public Map<Id,Id> featureIdMap{get; private set;}
    public CPQ_PartnerDataProcessor productAPIDetails{get; private set;}
    public Map<Id,Id> optionMapping{get;private set;}

    public CPQ_ProductOptionClone(Id sourceProductId, Id newProductId, Map<Id,Id> featureIdMap,  CPQ_PartnerDataProcessor productAPIDetails) {

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
        
        Set<String> allOptionalProducts = new Set<String>();
        
        allOptionalProducts.addAll(this.productAPIDetails.optionalMktProdIds);

        for(Product2 product : [SELECT Id,Name, ProductCode, SBQQ__ConfigurationType__c, SBQQ__ConfigurationEvent__c FROM Product2 WHERE ProductCode IN :allOptionalProducts OR (Name LIKE '%commit%' OR Name LIKE '%base fee%' OR Name LIKE '%included%')]) {
            
            if(product.Name.containsIgnoreCase('commit') || product.Name.containsIgnoreCase('base fee') || product.Name.containsIgnoreCase('Included')){
                optionalProductsMapByName.put(product.Name.toLowerCase(), product);
                // System.debug(product.Name.toLowerCase());
                continue;
            }
            optionalProductsMapById.put(product.ProductCode, product);
        }
        // System.debug(optionalProductsMapByName);
        // System.debug(optionalProductsMapById);
        //getting the feature
        Map<String, Id> featureMap = new Map<String, Id>();
        for(SBQQ__ProductFeature__c pf: [SELECT Id, Name, SBQQ__Number__c, SBQQ__ConfiguredSKU__c FROM SBQQ__ProductFeature__c WHERE SBQQ__ConfiguredSKU__c = :this.newProductId ]){
            featureMap.put(pf.Name.toLowerCase(), pf.Id);
            // featureMap.put(pf.SBQQ__ConfiguredSKU__c, tempMap);
        }
        //System.debug(featureMap);
        // for(Id configuredSKU: this.productAPIDetails.keySet()){
            
            // CPQ_PM_APIDataProcessor productInfo = this.productAPIDetails.get(configuredSKU);
        List<CPQ_PM_UtilityClass.ListItems> filteredListItems = this.productAPIDetails.filteredListItems;
        
        List<SBQQ__ProductOption__c> poList = new List<SBQQ__ProductOption__c>();
        // Id destProdId = productIdMap.get(configuredSKU);

        for(CPQ_PM_UtilityClass.ListItems li: filteredListItems){

            Boolean usageSection = li.sectionId == this.productAPIDetails.usageSectionId ? true : false;

            String featureName = li.pricingModel == 'Flat Fee' && usageSection ? 'platform fee' : li.sectionName.toLowerCase();
            Id featureId = featureMap.containsKey(featureName) ? featureMap.get(featureName) : featureMap.get(li.sectionName.toLowerCase()) ;

            poList.add(createOptionLineData(li,usageSection,featureId));
            if(usageSection && li.pricingModel != 'Flat Fee' && this.productAPIDetails.hasMultipleBillingModels && li.pricingModel != 'Quantity based commit'){
                for(String billingModel: this.productAPIDetails.billingModels){
                    poList.addAll(createBillingModelLines(li, billingModel, featureId));
                }
            }
            
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
        // }

        //if cloned lines are empty return the generated lines so far
        if(keyPoLineMap.isEmpty()){
            return returnList;
        }

        //add all the remaining cloned lines
        /* for(String key: keyPoLineMap.keySet()){
            Sobject clone = keyPoLineMap.get(key);
            Id featureId = clone.get('SBQQ__Feature__c');
            clone.put('SBQQ__Feature__c', featureIdMap.get(featureId));
            returnList.add(keyPoLineMap.get(key));
        } */

        return returnList;
    }

    private static SBQQ__ProductOption__c createOptionLineData(CPQ_PM_UtilityClass.ListItems listItem, Boolean usageSection, Id featureId){
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

        if(listItem.sectionName == 'Included' || listItem.pricingModel == 'Included Units'){

            tempHolder.SBQQ__Bundled__c = true;
            tempHolder.SBQQ__Required__c = true;
            tempHolder.SBQQ__Selected__c = true;

        }
        if(listItem.pricingModel != 'Flat Fee' && listItem.pricingModel != 'Included Units'){
            tempHolder.SBQQ__QuantityEditable__c = true;
        }
        if (listItem.listItemGroup != null && listItem.listItemSet != null) {
            tempHolder.CPQ_ListItemGroup__c = listItem.listItemGroup + '::' + listItem.listItemGroupCriteria;
            tempHolder.CPQ_ListItemSet__c = listItem.listItemSet;
        }

        if(usageSection){
            // System.debug('is it comming to 112');
            if(listItem.pricingModel == 'Flat Fee'){
                tempHolder.SBQQ__OptionalSKU__c = optionalProductsMapByName.get('Base Fee'.toLowerCase())?.Id;
                // po.SBQQ__Feature__c = featureMap.containsKey(destProdId) ? featureMap.get(destProdId).containsKey(li.sectionName.toLowerCase()) ? featureMap.get(destProdId).get(li.sectionName.toLowerCase()) : null : null;
            }
            else{
                String optionalSkuName = tempHolder.CPQ_Charge_Type__c + ' - ' + tempHolder.CPQ_Billing_Frequency__c;
                optionalSkuName = optionalSkuName.toLowerCase();
                //System.debug(optionalSkuName);
                tempHolder.SBQQ__OptionalSKU__c = optionalProductsMapByName.get(optionalSkuName)?.Id;
            }

        }
        else if (listItem.associatedProdId == null){
            
            if (listItem.sectionName == 'Included' || listItem.pricingModel == 'Included Units') {
                // example: lines like Domains will enter this logic
                tempHolder.SBQQ__OptionalSKU__c = optionalProductsMapByName.get(listItem.sectionName.toLowerCase())?.Id;
                tempHolder.SBQQ__QuoteLineVisibility__c = 'Document Only';
        
            }
            else if (listItem.sectionName == 'Fee' || listItem.pricingModel == 'Flat Fee') {

                //platform fee PLI
                tempHolder.SBQQ__OptionalSKU__c = optionalProductsMapByName.get('base fee')?.Id;
                tempHolder.SBQQ__Selected__c = tempHolder.SBQQ__Required__c = true;

            }
            else {

                String optionalSkuName = listItem.pricingModel + ' - ' + listItem.billingFrequency;
                // System.debug(optionalSkuName);
                optionalSkuName = optionalSkuName.toLowerCase();
                tempHolder.SBQQ__OptionalSKU__c = optionalProductsMapByName.get(optionalSkuName)?.Id;

            }
        }
        else {

            Product2 subproduct = optionalProductsMapById.get(listItem.associatedProdId);
            tempHolder.SBQQ__OptionalSKU__c = subproduct?.Id ;
            //update included settings eg when any certificate is included i.e. it has an associatedId but section is included 
            if(subproduct.SBQQ__ConfigurationType__c == 'Allowed' || subproduct.SBQQ__ConfigurationType__c == 'Required'){
                // if it is a configurable product remove the uom from the main line as sub-product inside will have to be selected
                tempHolder.CPQ_Measurement__c = null;
            }
        }

        if(listItem.listItemSet != null){
            tempHolder.CPQ_Product_Notes__c = listItem.listItemSet;
        }
        
        tempHolder.CPQ_Billing_Model__c = 'Fee';
        tempHolder.CPQ_PAC_Line_Item_Id__c = setQuoteDocumentNotation(listItem, usageSection);
        //TODO: to handle the CPQ_PAC_Line_Item_Id__c field which influences the the quote document creation
        
        return tempHolder;

    }

    private static List<SBQQ__ProductOption__c> createBillingModelLines(CPQ_PM_UtilityClass.ListItems listItem, String billingModel, Id featureId){

        List<SBQQ__ProductOption__c> returnList = new List<SBQQ__ProductOption__c>();

        for(String frequency : (List<String>) BILLING_MODEL_TYPE.get(billingModel)){
            SBQQ__ProductOption__c temp = createOptionLineData(listItem, true, featureId);
            String optionalSKUName = BILL_MODEL.get(billingModel) != null ? BILL_MODEL.get(billingModel) : billingModel;
            optionalSKUName = optionalSKUName + ' - ' + frequency + ' - ' + listItem.uom;
            optionalSKUName = optionalSKUName.toLowerCase();

            temp.SBQQ__optionalSKU__c = optionalProductsMapByName.get(optionalSKUName)?.Id;
            temp.CPQ_Billing_Model__c = billingModel;
            returnList.add(temp);
        }

        return returnList;
    }

    private string getUniqueKey(SBQQ__ProductOption__c poLine){

        return poLine.CPQ_Associated_Product_Id__c + poLine.CPQ_Measurement__c + poLine.CPQ_Charge_Type__c + poLine.CPQ_Billing_Frequency__c + poLine.CPQ_Billing_Model__c;
    }


    private static string setQuoteDocumentNotation(CPQ_PM_UtilityClass.ListItems listItem, Boolean usageSection){

        Set<String> commitmentItems = new Set<String>{'commitment', 'commitment + overage', 'quantity based commit'};

        if(commitmentItems.contains(listItem.pricingModel.toLowerCase()) && !usageSection && listItem.associatedProdId == null ){
            //The line item which directly belongs to main product, but not in the usage section
            return 'Additional ' + listItem.uom + ' : Up To';
        }

        if(commitmentItems.contains(listItem.pricingModel.toLowerCase())){
            //The line item which has commitment to be made
            return 'Commitment';
        }

        if(new List<String>{'base fee', 'flat fee'}.contains(listItem.pricingModel.toLowerCase()) && usageSection){
            //The flat fee line item in usage section  
            return 'Base Fee';
        }

        return listItem.pricingModel;
    }
}