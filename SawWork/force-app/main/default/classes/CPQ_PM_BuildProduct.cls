public with sharing class CPQ_PM_BuildProduct {

    private static CPQ_PM_UtilityClass.ApiResponseWrapper prodDetails = new CPQ_PM_UtilityClass.ApiResponseWrapper();
    private static Boolean hasMultipleBillingModels = false;
    private static List<String> billingModels = new List<String>();
    private static Integer usageSectionId = 1;

    private static Product2 bundleProduct = new Product2();
    private static List<SBQQ__ProductFeature__c> featuresList = new List<SBQQ__ProductFeature__c>();
    private static List<SBQQ__ProductOption__c> optionsList = new List<SBQQ__ProductOption__c>();
    private static Map<String, Id> featureNameIdMap = new Map<String, Id>();
    private static List<CPQ_PM_UtilityClass.ListItems> filteredListItems = new List<CPQ_PM_UtilityClass.ListItems>();
    private static Map<Integer, List<CPQ_PM_UtilityClass.ListItems>> sectionIdLiMap = new Map<Integer, List<CPQ_PM_UtilityClass.ListItems>>(); //map of pac section ids and related LIs
    private static Map<String, Product2> optionalSkuProdNameMap = null;
    private static Set<String> optionalMktProdIds = new Set<String>();
    private static Map<String, Product2> optionalProductsMap = null; //map of mkt code and product details for optional SKUs
    private static Id commitFeatureId = null;
    private static Integer optionNumber = 10;
    private static Set<String> optionalSkuCreated = new Set<String>();
    private static Map<String, List<SBQQ__ProductOption__c>> liSetLiMap = new Map<String, List<SBQQ__ProductOption__c>>();

    private static final Map<String, Object> BILLING_MODEL_TYPE = (Map<String, List<String>>)JSON.deserialize(CPQSettings.getMetadataValue('CPQ_billingModelType'), Map<String, List<String>>.class);
    private static final Set<String> PRODUCTS_TO_BE_EXCLUDED = CPQSettings.getMetadataValues('CPQ_productsToBeExcluded'); //products that come as add-on but are quoted separately, so the PO need not be created for them inside the main product bundles
    private static Set<String> genericProductRuleIds = CPQSettings.getMetadataValues('CPQ_genericProductRule_integration'); //add integration deselection rule by default
    private static final Map<String, String> BILL_MODEL = new Map<String, String>{
        'Straight-line Commitment' => 'Straight Line Commitment',
        'Usage Commitment' => 'Usage Commitment'
    }; //temp solution for billing model -> picklist match
    

    /**
     * 
     */
    @AuraEnabled
    public static Id buildProduct(String  prodDetailsResponse, List<String> billModels, Integer usgSectionId) {

        try {
            System.debug('inside createProduct');
            prodDetails = (CPQ_PM_UtilityClass.ApiResponseWrapper) JSON.deserialize(prodDetailsResponse, CPQ_PM_UtilityClass.ApiResponseWrapper.Class);
            usageSectionId = usgSectionId;

            if (billModels.size() > 0) {
                hasMultipleBillingModels = true;
                billingModels = billModels;
            }

            createProduct();

        } catch (Exception e) {

            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getCause());
            System.debug(LoggingLevel.ERROR, 'error ==> ' + e.getLineNumber());

            throw new AuraHandledException(e.getStackTraceString());
            
        }

        return bundleProduct.Id;

    }

    /**
     * This method is used to create a product
     * 
     */
    private static void createProduct () {
        
        CPQ_PM_UtilityClass.PacAttributesApi attributeDeserialized = (CPQ_PM_UtilityClass.PacAttributesApi) JSON.deserialize(prodDetails.attributeResponse, CPQ_PM_UtilityClass.PacAttributesApi.Class);
        
        try{
            if(attributeDeserialized.productAttributes.forPartner) {
                bundleProduct = new CPQ_PM_UtilityClass.ProductBuilder(
                    attributeDeserialized.productName
                    ,System.Label.CPQ_Partner_Products_RT
                    ,false
                )
                .withCode(attributeDeserialized.marketingProductId)
                .withFamily(attributeDeserialized.productAttributes.marketingCategory)
                .configurationSettings('Always', 'Allowed')
                .withConfigurationFieldSet('CPQ_OptionConfiguration_Partner')
                .withUpdateCode(attributeDeserialized.currentActiveVersion)
                .withOptionLayout('Tabs')
                .withDescription('Autonomy-Product Master test copy: ' + Datetime.now())
                .saveRecord();
            } 
        } catch (Exception e) {
            throw new BuildProductException('Error creating product.', e);
        }
            
            //if the product insert is success, move ahead with the process
            if (bundleProduct != null) {
                //0 dollar pricebpookentries for new product
                createPricebookentries();
                
                createFeatures(); // try using pricing api for extracting features, will reduce the number of API callout
                
            }        
    }

    /**
     * method to create pricebook entries
     * 
     */
    private static void createPricebookEntries() {

        List<PricebookEntry> pbEntries = new List<PricebookEntry>();
        
        //pricebook will be standard pricebook
        Id stdPricebookId = [SELECT Id FROM Pricebook2
                             WHERE Name = 'Standard Price Book'
                             AND IsActive = true
                             WITH SECURITY_ENFORCED LIMIT 1]?.Id;
        
        //get the list of applicable currencies
        List<CurrencyType> currenciesTypes = [SELECT IsoCode
                                              FROM CurrencyType
                                              WHERE IsActive = true
                                              WITH SECURITY_ENFORCED];
        
        
        if(currenciesTypes.size() > 0 && stdPricebookId != null){
            for(CurrencyType curr : currenciesTypes) {
                PricebookEntry tempPbe = new CPQ_PM_UtilityClass.PricebookEntryBuilder(
                    stdPricebookId
                    , bundleProduct.Id
                    , curr.IsoCode
                    , true
                )
                .withUnitPrice(0.0)
                .getRecord();
                
                pbEntries.add(tempPbe);
                
            }
        }
        
        try{
            if (PricebookEntry.SObjectType.getDescribe().isCreateable()) {
                insert pbEntries;
            }
        } catch (DMLException e) {
            throw new BuildProductException('Error creating price book entries.', e);
        }
        
    }

    /**
     * method to create product features
     * 
     */
    private static void createFeatures(){
        
        List<CPQ_PM_UtilityClass.PacSectionsApi> sectionsDeserialized = (List<CPQ_PM_UtilityClass.PacSectionsApi>) JSON.deserialize(prodDetails.sectionResponse, List<CPQ_PM_UtilityClass.PacSectionsApi>.Class);
        System.debug('no of sections: '+sectionsDeserialized.size());
        
            Integer featureNumber = 10;

            try{

                for (CPQ_PM_UtilityClass.PacSectionsApi section : sectionsDeserialized) {

                    System.debug('section name: ' + section.name + ' : section id: ' + section.id);
                    
                    if (validateSection(section)) {
                        SBQQ__ProductFeature__c tempFeature = createFeatureHelper(section, section.name, featureNumber);
                        
                        // logic for min and max options, specially in case of Usage / Commitment / Integration kind of Feature
                        if (
                            section.id == usageSectionId
                            // || (section.listItemGroupInfo?.groupingCriterion == 'Unit of Measure')
                        ) {
                            //products which are add-ons etc also have min count = 0 sometimes
                            tempFeature.SBQQ__MinOptionCount__c = tempFeature.SBQQ__MaxOptionCount__c = 1;
                            tempFeature.SBQQ__ConfigurationFieldSet__c = 'CPQ_OptionConfiguration_Notes_Partner';
                            
                        } 

                        featureNumber += 10;
                        featuresList.add(tempFeature);

                        if (section.listItemGroupInfo?.groupingCriterion == 'Custom') {
                            //add platform fee feature
                            SBQQ__ProductFeature__c tempPlatformFeeFeature = createFeatureHelper(section, 'Platform Fee', featureNumber);
                            tempPlatformFeeFeature.SBQQ__ConfigurationFieldSet__c = 'CPQ_OptionConfiguration_Notes_Partner';

                            featureNumber += 10;
                            featuresList.add(tempPlatformFeeFeature);

                        }
                    }
                }
            } catch (Exception e) {
                throw new BuildProductException('Error process producct features.', e);
            }
            
            try{
                if (featuresList.size() > 0 && SBQQ__ProductFeature__c.SObjectType.getDescribe().isCreateable()) {
                    insert featuresList;
                }
            } catch (DMLException e) {
                throw new BuildProductException('Error creating product features.', e);
            }
                
                
            for (SBQQ__ProductFeature__c feature : featuresList) {
                featureNameIdMap.put(feature.Name, feature.Id);
                
            }

            createSectionIdLinesMap();

            createOptions();

            createDependencyConstraints();

            createConfigurationAttribute();

            if (hasMultipleBillingModels) { genericProductRuleIds.addAll(CPQSettings.getMetadataValues('CPQ_genericProductRule_billing')); }

            createConfigurationRules(genericProductRuleIds); //created an entry for billing models product rule and integration deselection

    }

    /**
     * method to create product features
     * 
     */
    private static void createOptions() {

        try {
            for (Integer sectionId : sectionIdLiMap.keySet()) {

                if(sectionId == usageSectionId) {

                    System.debug(sectionId + ' is commit section provided by user.');
                    createUsageSectionOptions(sectionIdLiMap.get(sectionId));

                } 
                else {

                    System.debug('processing section: ' + sectionId);
                    createSectionOptions(sectionIdLiMap.get(sectionId));
                    
                }
                
            }
        } catch (Exception e) {
            throw new BuildProductException('Error processing product options.', e);
        }

        try {
            if(optionsList.size() > 0 && SBQQ__ProductOption__c.SObjectType.getDescribe().isCreateable()) {
                System.debug(optionsList.size() + ' :optionsList: ' + optionsList);
                insert optionsList;

            }
        } catch (DMLException e) {
            throw new BuildProductException('Error inserting product options.', e);
        }

    }

    private static void createUsageSectionOptions(List<CPQ_PM_UtilityClass.ListItems> listOfLi) {

        //commit section logic

        for(CPQ_PM_UtilityClass.ListItems li : listOfLi) {

            System.debug('processing line: ' +  li.id);

            SBQQ__ProductOption__c tempOption = new SBQQ__ProductOption__c();
            commitFeatureId = featureNameIdMap.get(li.sectionName);
            
            //commit lines
            //check if the associated and secAssociated prod id is null
            // if (String.isBlank(li.associatedProdId) && String.isBlank(li.secLvlAssociatedProdId)){

                if(li.pricingModel == 'Flat Fee') {

                    System.debug(li.name);
                    tempOption = createOptionsHelper(li, getOptionalSkuProdNameMap(), 'base fee');
                    tempOption.SBQQ__Feature__c  = featureNameIdMap.get('Platform Fee');

                } else {

                    //find the applicable optionalSKU for commit - pricingModel - billingFrequency
                    String optionalSkuName = li.pricingModel + ' - ' + li.billingFrequency;
                    System.debug(optionalSkuName);
                    
                    //logic to handle commit list items
                    tempOption = createOptionsHelper(li, getOptionalSkuProdNameMap(), optionalSkuName.toLowerCase());
                    tempOption.SBQQ__QuantityEditable__c =  true;
                    tempOption.SBQQ__Feature__c  = commitFeatureId;
                    optionNumber += 10;

                    
                    System.debug('hasMultipleBillingModels ' + hasMultipleBillingModels);

                    if (hasMultipleBillingModels && li.pricingModel != 'Quantity based commit') {
                            
                        System.debug('creating commitment POs for multiple billing models');
                        createMutipleBillingOptions(li);
                        
                    }
                }
                //li group settings
                if (li.listItemGroup != null && li.listItemSet != null) {
                    tempOption.CPQ_ListItemGroup__c = li.listItemGroup + '::' + li.listItemGroupCriteria;
                    tempOption.CPQ_ListItemSet__c = li.listItemSet;
                }

                
                tempOption.CPQ_Product_Notes__c = li.listItemSet != null ? li.listItemSet : li.name;

                optionsList.add(tempOption);
            // }
        }

        // return optionNumber;

    }

    private static void createMutipleBillingOptions (CPQ_PM_UtilityClass.ListItems li) {

        // for (String bm : BILLING_MODEL_TYPE.keySet()) {
        for (String bm : billingModels) {
            System.debug(('bm: ' + bm));
            for( String freq : (List<String>) BILLING_MODEL_TYPE.get(bm)) {
                
                String optionalSkuName = bm + ' - ' + freq;
                SBQQ__ProductOption__c tempBillingOption = createOptionsHelper(li, getOptionalSkuProdNameMap(), optionalSkuName.toLowerCase());
                tempBillingOption.SBQQ__QuantityEditable__c =  true;
                tempBillingOption.CPQ_Billing_Model__c = BILL_MODEL.get(bm);
                tempBillingOption.SBQQ__Feature__c = commitFeatureId;
                tempBillingOption.CPQ_Product_Notes__c = li.listItemSet != null ? li.listItemSet : li.name;

                //li group settings
                if (li.listItemGroup != null && li.listItemSet != null) {
                    tempBillingOption.CPQ_ListItemGroup__c = li.listItemGroup + '::' + li.listItemGroupCriteria;
                    tempBillingOption.CPQ_ListItemSet__c = li.listItemSet;
                }
                optionsList.add(tempBillingOption);
                optionNumber += 10;
                
            }
        }

    }

    private static void createSectionOptions(List<CPQ_PM_UtilityClass.ListItems> listOfLi) {

        for (CPQ_PM_UtilityClass.ListItems li : listOfLi) {

            // if (validateLine(li)){
                
            createNonUsageOptions(li); //creates non-usage section lines i.e. included units, add-on, integration
                
            // } else {
            //     System.debug(li.id + ' # ' + li.name + ' not valid for computation.');
            //     // System.debug(' ignored, it has custom pricing or is not applicable for standalone products.');
            // }
        }
    }

    private static void createNonUsageOptions (CPQ_PM_UtilityClass.ListItems li) {

        SBQQ__ProductOption__c tempOption = new SBQQ__ProductOption__c();
                
        //check if the associated and secAssociated prod id is null
        if (String.isBlank(li.associatedProdId) /* && String.isBlank(li.secLvlAssociatedProdId)*/) {

            if (li.sectionName == 'Included') {

                // example: lines like Domains will enter this logic
                tempOption = createOptionsHelper(li, getOptionalSkuProdNameMap(), 'included');
                tempOption.SBQQ__QuoteLineVisibility__c = 'Document Only';

            }

            else if (li.sectionName == 'Fee') {

                //platform fee PLI
                tempOption = createOptionsHelper(li, getOptionalSkuProdNameMap(), 'base fee');
                tempOption.SBQQ__Selected__c = tempOption.SBQQ__Required__c = true;

            }
            else {

                String optionalSkuName = li.pricingModel + ' - ' + li.billingFrequency;
                tempOption = createOptionsHelper(li, getOptionalSkuProdNameMap(), optionalSkuName.toLowerCase());

            }

        }
            
        //non-commit lines --> add ons, integration
        else {
            
            tempOption = createOptionsHelper(li, getOptionalProductsMap(), li.associatedProdId);
            //update included settings eg when any certificate is included i.e. it has an associtedId but section is included
            
        }

        //make an entry in the optionalSkuCreated map in case the optional prod is bundle type, if associatedid is not blank
        if (getOptionalProductsMap().get(li.associatedProdId)?.SBQQ__ConfigurationEvent__c == 'Always') {
            optionalSkuCreated.add(li.associatedProdId);
        }
        
        tempOption.SBQQ__Feature__c = featureNameIdMap.get(li.sectionName);
        
        optionsList.add(tempOption);
        optionNumber += 10;

    }

    /**
     * 
     */
    public static void createDependencyConstraints() {
        /**
         * Option 1: current logic
         * get the base fee item from each set
         * create a dependency constraint kepping the basee fee PO as the contrained item and others as constraining
         * cons - works specifically for products like ksd, etc with flat fee + commitment
         */

        /**
         * option 2: process from the json li
         * create a map of set vs list of LI -> if the length of LI is > 1 the have dependency between the lines (how to select contrained option?)
         * 
         */

        List<SBQQ__ProductOption__c> contrainingOptionsList = new List<SBQQ__ProductOption__c>();
        Map<String, SBQQ__ProductOption__c> liSetContrainedOptionMap = new Map<String, SBQQ__ProductOption__c>(); //map of LI set name and the base fee (constrained) option
        List<SBQQ__OptionConstraint__c> optionConstraints = new List<SBQQ__OptionConstraint__c>();

        //option constraint logic
        for (SBQQ__ProductOption__c option : [SELECT Id, CPQ_Charge_Type__c, CPQ_ListItemGroup__c, CPQ_ListItemSet__c, CPQ_Measurement__c FROM SBQQ__ProductOption__c WHERE CPQ_ListItemGroup__c != null AND SBQQ__ConfiguredSKU__c = :bundleProduct.Id]) {

            if (option.CPQ_Charge_Type__c.equalsIgnoreCase('Flat Fee')) { 
                liSetContrainedOptionMap.put(option.CPQ_ListItemSet__c, option);
            } else {
                contrainingOptionsList.add(option);
            }
        }

        System.debug('liSetContrainedOptionMap: ' + liSetContrainedOptionMap.keySet());

        for (SBQQ__ProductOption__c option : contrainingOptionsList) {
            List<String> tempSet = new List<String>();
            List<SBQQ__ProductOption__c> tempOptionList = new List<SBQQ__ProductOption__c>();

            // if (liGroupLiSetMap.containsKey(option.CPQ_ListItemGroup__c)) {
            //     tempSet = liGroupLiSetMap.get(option.CPQ_ListItemGroup__c);
            // }
            // tempSet.add(option.CPQ_ListItemSet__c);
            // liGroupLiSetMap.put(option.CPQ_ListItemGroup__c, tempSet);

            if (liSetLiMap.containsKey(option.CPQ_ListItemSet__c)) {
                tempOptionList = liSetLiMap.get(option.CPQ_ListItemSet__c);
            }
            tempOptionList.add(option);
            liSetLiMap.put(option.CPQ_ListItemSet__c, tempOptionList);

        }

        // System.debug('liGroupLiSetMap: ' + liGroupLiSetMap);
        System.debug('liSetLiMap: ' + liSetLiMap.keySet());
        System.debug(contrainingOptionsList.size());
        //option constraint logic - end

        for (String liSetName : liSetLiMap.keySet()) {
            for (SBQQ__ProductOption__c po : liSetLiMap.get(liSetName)) {

                if (liSetContrainedOptionMap.containsKey(po.CPQ_ListItemSet__c)) {
                    SBQQ__OptionConstraint__c tempConstraint = new CPQ_PM_UtilityClass.OptionConstraintBuilder(
                        'Base fee ' + po.CPQ_Measurement__c
                        , 'Dependency'
                        , bundleProduct.Id
                    )
                    .withConstraint(liSetContrainedOptionMap.get(po.CPQ_ListItemSet__c).Id, po.Id)
                    .getRecord();

                    optionConstraints.add(tempConstraint);
                }

            }
        }

        try {
            if (optionConstraints.size() > 0 && SBQQ__OptionConstraint__c.SObjectType.getDescribe().isCreateable()) {
                insert optionConstraints;
            }
        } catch (DMLException e) {
            throw new BuildProductException('Error inserting option constraints.', e);
        }

    }

    /**
     * 
     */
    public static void createConfigurationAttribute() {
        
        if (hasMultipleBillingModels) {
            createConfigurationAttribute('');
        } else {
            createConfigurationAttribute('Fee');
        }
    }

    /**
     * method to create billing model configuration attribute
     * @param shownValues use new line character to send multile values like 'Fee\nUsageCommitment'
     */
    public static void createConfigurationAttribute(String shownValues) {

        SBQQ__ConfigurationAttribute__c configAttribute = new CPQ_PM_UtilityClass.ConfigurationAttributeBuilder(
            'Billing Model'
            , bundleProduct.Id
            , commitFeatureId
            , 'CPQ_Billing_Model__c'
            , 1
            , '3'
            , 'Top'
            , true
        )
        .withDefaultObjectField('Quote__c', 'CPQ_Default_Billing_Model__c')
        .requiredSetting(true)
        .getRecord();

        configAttribute.SBQQ__ShownValues__c = String.isNotBlank(shownValues) ? shownValues : '';
                
        if(SBQQ__ConfigurationAttribute__c.SObjectType.getDescribe().isCreateable()) {
            insert configAttribute;
        }

    }

    /**
     * 
     */
    public static void createConfigurationRules(Set<String> productRuleIds) {

        List<SBQQ__ConfigurationRule__c> configRuleList = new List<SBQQ__ConfigurationRule__c>();

        for (String ruleId : productRuleIds) {
            SBQQ__ConfigurationRule__c configRule = new SBQQ__ConfigurationRule__c(
                SBQQ__Product__c = bundleProduct.Id
                , SBQQ__Active__c = true
                , SBQQ__ProductRule__c = ruleId
                , SBQQ__ProductFeature__c = commitFeatureId
            );

            configRuleList.add(configRule);

        }

        if(SBQQ__ConfigurationRule__c.SObjectType.getDescribe().isCreateable()) {
            insert configRuleList;
        }

    }

    //HELPER METHODS

    private static Boolean validateSection(CPQ_PM_UtilityClass.PacSectionsApi section) {

        return section.name != 'End of sale' 
        && !section.name.contains('NetStorage');

    }

    private static SBQQ__ProductFeature__c createFeatureHelper(CPQ_PM_UtilityClass.PacSectionsApi section, String featureName, Integer featureNumber) {

        String category = section.id == usageSectionId || featureName == 'Platform Fee' ? 'Usage' : section.name.containsIgnoreCase('integration') ? 'Integration' : 'Entitlements';

        SBQQ__ProductFeature__c tempFeature = new CPQ_PM_UtilityClass.ProductFeatureBuilder(
            featureName
            , bundleProduct.Id
            , featureNumber
        )
        .withOptionSelection('Click')
        .withCategory(category)
        .withConfigurationFieldSet((featureName == 'Platform  Fee' || featureName == 'Integration') ? 'CPQ_OptionConfiguration_Notes_Partner' : '')
        .getRecord();

        return tempFeature;

    }

    /**
     * 
     */
    public static void createSectionIdLinesMap () {

        CPQ_PM_UtilityClass.PacPricingApi pricingDeserialized = (CPQ_PM_UtilityClass.PacPricingApi) JSON.deserialize(prodDetails.pricingResponse, CPQ_PM_UtilityClass.PacPricingApi.Class);
        // Set<String> optionalMktProdIds = new Set<String>();
        Set<String> missingProdCodes = new Set<String>();
        
        for(CPQ_PM_UtilityClass.ListItems li : pricingDeserialized.listItems) {

            // sub product PLI are added only once
            if(validateLine(li)){

                System.debug(li.id + ' # ' + li.name + ' valid.');
                filteredListItems.add(li);

            }

        }

        for (CPQ_PM_UtilityClass.ListItems li : filteredListItems) {

            List<CPQ_PM_UtilityClass.ListItems> tempList = new List<CPQ_PM_UtilityClass.ListItems>();

            if (sectionIdLiMap.containsKey(li.sectionId)) {
                tempList = sectionIdLiMap.get(li.sectionId);

            }
            tempList.add(li);
            sectionIdLiMap.put(li.sectionId, tempList);

            // System.debug('li.associatedProdId & li.secLvlAssociatedProdId: ' + li.associatedProdId + ' -- ' + li.secLvlAssociatedProdId);
            if(String.isNotBlank(li.associatedProdId)) { optionalMktProdIds.add(li.associatedProdId); }
            if(String.isNotBlank(li.secLvlAssociatedProdId)) { optionalMktProdIds.add(li.secLvlAssociatedProdId); }
            
        }
        System.debug('optionalMktProdIds: ' + optionalMktProdIds);
        missingProdCodes.addAll(optionalMktProdIds);

        // if(optionalMktProdIds.size() > 0) {
                
        //     for(Product2 product : [SELECT Id, ProductCode, SBQQ__ConfigurationType__c, SBQQ__ConfigurationEvent__c FROM Product2 WHERE ProductCode IN :optionalMktProdIds]) {
        //         optionalProductsMap.put(product.ProductCode, product);
        //     }
        // }

        missingProdCodes.removeAll(getOptionalProductsMap().keySet());

        if (missingProdCodes.size() > 0) {

            System.debug('optional products missing from the system: ' +  missingProdCodes);
            //create place holder for these products
            createOptionalProduct(missingProdCodes);
            //fetch the li with missing codes, use them to create options or update teh product

        }
        
        System.debug('sectionIdLiMap: ' + sectionIdLiMap.size());

    }

    private static Map<String, Product2> getOptionalSkuProdNameMap () {
        if (optionalSkuProdNameMap == null) {
            
            optionalSkuProdNameMap = new Map<String, Product2>();
            
            for(Product2 prod : [SELECT Id, Name FROM Product2 WHERE RecordType.DeveloperName = :System.Label.CPQ_Partner_Products_RT AND (Name LIKE '%commit%' OR Name LIKE '%base fee%' OR Name LIKE '%included%')]) {
                optionalSkuProdNameMap.put(prod.Name.toLowerCase(), prod);
            }
            // System.debug('optionalSkuProdNameMap: ' + optionalSkuProdNameMap);
        }
        return optionalSkuProdNameMap;
    }

    private static Map<String, Product2> getOptionalProductsMap() {
        if (optionalProductsMap == null) {

            optionalProductsMap = new Map<String, Product2>();

            for(Product2 product : [SELECT Id, ProductCode, SBQQ__ConfigurationType__c, SBQQ__ConfigurationEvent__c FROM Product2 WHERE ProductCode IN :optionalMktProdIds]) {
                optionalProductsMap.put(product.ProductCode, product);
            }
        }
        return optionalProductsMap;

    }

    /**
     * 
     */
    private static Boolean validateLine(CPQ_PM_UtilityClass.ListItems li) {
        /**
         * PLI should not:
         * have custom pricing
         * have isApplicableWhenStandalone as False
         * be part of special exclusions: NS, mPulse, mPulse Lite
         */
        return li.tiers[0].geoRegionPricing[0].pricePoints.wholesale != -1 
        && li.isApplicableWhenStandalone == true 
        && li.customerTypes.contains('Partner') 
        && !PRODUCTS_TO_BE_EXCLUDED.contains(li.associatedProdId)
        && li.sectionName != 'End of sale'
        && !optionalSkuCreated.contains(li.associatedProdId) //only one entry is needed for bundle type optional prods like china cdn, client reputation etc
        && li.secLvlAssociatedProdId == null; // the PLI should not be second level product.
    }

    private static SBQQ__ProductOption__c createOptionsHelper (CPQ_PM_UtilityClass.ListItems li, Map<String, Product2> productReferenceMap, String optionalSkuName) {
        
        System.debug('creating po for optionalSkuName: ' + optionalSkuName);
        SBQQ__ProductOption__c tempOption = new CPQ_PM_UtilityClass.ProductOptionBuilder(
            bundleProduct.Id
            , productReferenceMap.get(optionalSkuName)?.Id
            , optionNumber
            , li.defaultEntitlement?.value > 0 ? li.defaultEntitlement?.value : 1
        )
        .withAssociatedProductId(li.associatedProdId == null ? li.productId : li.associatedProdId)
        .withBillingFrequency(li.billingFrequency)
        .withChargeType(li.pricingModel)
        .withPliName(li.name)
        .withOptionType('Related Products')
        .withMeasurement(li.uom)
        .withIncludedSettings(li.sectionName == 'Included')
        .getRecord();

        return tempOption;

    }

    public static void createOptionalProduct(Set<String> mktProdIds) {

        List<Product2> productsToInsert = new List<Product2>();
        for ( String prodCode : mktProdIds ) {
            Product2 tempProduct = new CPQ_PM_UtilityClass.ProductBuilder(
                prodCode
                ,System.Label.CPQ_Partner_Products_RT
                ,true
            
            )
            .withCode(prodCode)
            .withConfigurationFieldSet('CPQ_OptionConfiguration_Partner')
            .isComponent(true)
            .getRecord();

            productsToInsert.add(tempProduct);
            optionalMktProdIds.add(prodCode);

        }
        optionalProductsMap = null;

        try {
            if (productsToInsert.size() > 0 && Product2.SobjectType.getDescribe().isCreateable()) {
                insert productsToInsert;
            }
        } catch (DMLException e) {
            throw new BuildProductException('Error inserting optional products.', e);
        }


    }

    @AuraEnabled(cacheable=true)
    public static List<SBQQ__ProductOption__c> getProductOptionDetails(Id configuredSkuId){
        
        return [SELECT Id, SBQQ__Number__c,
                SBQQ__OptionalSKU__r.Name, 
                SBQQ__Feature__c, SBQQ__Feature__r.Name,
                CPQ_Product_Notes__c,
                CPQ_Measurement__c,
                CPQ_Billing_Model__c,
                CPQ_Billing_Frequency__c,
                CPQ_Charge_Type__c
                FROM SBQQ__ProductOption__c 
                WHERE SBQQ__ConfiguredSKU__c = :configuredSkuId 
                WITH SECURITY_ENFORCED
                ORDER BY SBQQ__Number__c];
            
    }

    @AuraEnabled
    public static void deleteSelectedProductOptions(List<Id> prodOptionIds){
        try {
            List<SBQQ__ProductOption__c> optionsToDelete = new list<SBQQ__ProductOption__c>();
            System.debug('prodOptionIds ====> '+prodOptionIds);
            for(Id optionId : prodOptionIds) {
                optionsToDelete.add(new SBQQ__ProductOption__c(Id = optionId));
            }
            if(!optionsToDelete.isEmpty() && SBQQ__ProductOption__c.SObjectType.getDescribe().isDeletable()) {
                delete optionsToDelete;
            }
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public class BuildProductException extends Exception {}
}