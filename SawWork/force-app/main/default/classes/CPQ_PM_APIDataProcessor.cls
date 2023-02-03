/**
* CPQ_PM_APIDataProcessor class processes the response from the Product Master APIs to store in appropriate data structures to create the product version 
* Test Class: CPQ_Test_PM_APIDataProcessor
* @author  Shashank Hegade
* @since   2021-07-20
*/
public with sharing class CPQ_PM_APIDataProcessor {
    
    //final members
    private static final Set<String> PRODUCTS_TO_BE_EXCLUDED = CPQSettings.getMetadataValues('CPQ_productsToBeExcluded');
    
    //static members
    public static Map<String, product2> optionalProductMap = new Map<String, product2>();
    public static Map<String,String> mainProductPricingMap = new Map<String,String>(); //handle currency for main product
    public static Map<String,String> optionalProductPricingMap = new Map<String,String>(); //handle currency for optional products
    public static Map<String,List<CPQ_PM_UtilityClass.Tiers>> discountSchedules = new Map<String,List<CPQ_PM_UtilityClass.Tiers>>(); // handle Discount Schdeule response
    
    //public members
    public String productCode{get; private set;}
    public Boolean hasMultipleBillingModels{get; private set;}
    public List<String> billingModels{ get; private set;}
    public Decimal usageSectionId{ get; private set;}
    public Boolean canHavePlatformFee{ get; private set;}
    public Set<String> optionalMktProdIds{ get; private set;}
    public List<String> optionalMktProdIdsCarrier{get; private set;}
    public set<String> parentSubProducts{ get; private set;}
    public Id recordTypeId{ get; private set;}
    public Integer count=0;

    public Id usageSectionSFId{get; set;}
    public String usageSectionName{ get; set;}
    public String unitOfMeasure{get; set;}

    public CPQ_PM_UtilityClass.PacAttributesApi attributeDeserialized{get; private set;}
    public List<CPQ_PM_UtilityClass.ListItems> filteredListItems{get; private set;}
    public List<CPQ_PM_UtilityClass.PacSectionsApi> productSectionInfo{get; private set;}
    public CPQ_PM_UtilityClass.PacLiteratureApiWrapper literatureDeserialized{get; private set;}

    //private members
    private Set<String> optionalSkuCreated;
    
    // public Map<Integer, List<SBQQ__ProductOption__c>> sectionIdLiMap = new Map<Integer, List<SBQQ__ProductOption__c>>(); //map of pac section ids and related LIs
   
    public CPQ_PM_APIDataProcessor(String productCode, Id recordTypeId) {
        this.productCode = productCode;
        this.recordTypeId = recordTypeId;
        
        //default initialization
        this.optionalSkuCreated = new Set<String>();
        this.filteredListItems = new List<CPQ_PM_UtilityClass.ListItems>();
        this.productSectionInfo = new List<CPQ_PM_UtilityClass.PacSectionsApi>();
        this.hasMultipleBillingModels = false;
        this.billingModels = new List<String>();
        this.canHavePlatformFee = false;
        this.optionalMktProdIds = new Set<String>();
        this.optionalMktProdIdsCarrier = new List<String>();
        this.parentSubProducts = new Set<String>();
        
    }

    /**
     * @description generateProductData method will process the product master API respose data
     * @param  prodDetailsResponse The raw response from the product master API
     * @param  billingModels       Types of billing model applicable for this product 
     * @param  usageSectionId      the identifier number for the usage section in response of the section API
     * @return                     process success status
     */
    public CPQ_PM_APIDataProcessor generateProductData(String prodDetailsResponse, CPQ_ProductLaunchSetting__c productSetting,String typeOfProduct){
        
        this.usageSectionId = productSetting.UsageSectionNumber__c;
        
        //parsing the product information 
        CPQ_PM_UtilityClass.ApiResponseWrapper prodDetails = (CPQ_PM_UtilityClass.ApiResponseWrapper) JSON.deserialize(prodDetailsResponse, CPQ_PM_UtilityClass.ApiResponseWrapper.Class);

        //if the the response is in invalid. 
        if(prodDetails.validity == false){
            throw new CPQ_PM_APIDataProcessorException('Invalid information: ' +  
                                                        this.productCode + '\n' + 
                                                        JSON.serialize(prodDetails.errorResponse),
                                                        CPQ_CustomException.StatusCode.PAC_ERROR);
        }

        //get the billing models
        List<String> billingModels = productSetting.BillingModels__c?.split(';');
        System.debug('The billing models ==> ' + productSetting.BillingModels__c);
        if( billingModels != null && billingModels.size() > 0){
            hasMultipleBillingModels = true;
            this.billingModels = billingModels;
        }


        //parsing the attribute information
        attributeDeserialized = (CPQ_PM_UtilityClass.PacAttributesApi) JSON.deserialize(prodDetails.attributeResponse, CPQ_PM_UtilityClass.PacAttributesApi.Class);
        
        //check if the product is available for partners
        /*if(!attributeDeserialized.productAttributes.forPartner){
            throw new CPQ_PM_APIDataProcessorException('The product is not enabled for the partner: ' +
                                                        this.productCode,
                                                        CPQ_CustomException.StatusCode.VALIDATION_ERROR);
        }*/

        // parsing the literature information
        literatureDeserialized = (CPQ_PM_UtilityClass.PacLiteratureApiWrapper)  JSON.deserialize(prodDetails.literatureResponse, CPQ_PM_UtilityClass.PacLiteratureApiWrapper.class);

        //parsing the section information
        List<CPQ_PM_UtilityClass.PacSectionsApi> sectionsDeserialized = (List<CPQ_PM_UtilityClass.PacSectionsApi>) JSON.deserialize(prodDetails.sectionResponse, List<CPQ_PM_UtilityClass.PacSectionsApi>.Class);

        //setting the feature data
        for(CPQ_PM_UtilityClass.PacSectionsApi section : sectionsDeserialized){

            // Map<String,String> pfInfo = new Map<String, String>();

            // end of sale section and the netstorage section is not considered for feature createion 
            if(section.name != 'End of sale' && !section.name.containsIgnoreCase('NetStorage')){

                productSectionInfo.add(section);

            }
   

        } 

        //parsing the pricing values
        CPQ_PM_UtilityClass.PacPricingApi pricingDeserialized = (CPQ_PM_UtilityClass.PacPricingApi) JSON.deserialize(prodDetails.pricingResponse, CPQ_PM_UtilityClass.PacPricingApi.Class);
        
        if(typeOfProduct == 'Carrier'){
            
            for(CPQ_PM_UtilityClass.ListItems li : pricingDeserialized.listItems) {

            if(validateLine(li,typeOfProduct)){

            // TODO: this condition needs to be checked. 

            if(li.associatedProdId == null){
                count = count+1;
                System.debug('count ;- '+count);   
            }
            }
        }
            for(CPQ_PM_UtilityClass.ListItems li : pricingDeserialized.listItems){
        
           if(validateLine(li,typeOfProduct)){

            if(li.associatedProdId != null){
                filteredListItems.add(li); // IF ASSOCIATED ID IS NOT NULL ADD IT TO FILTERED LIST 
            }
            else
            {
                if(count >1){
                    filteredListItems.add(li);
                }

            }
            }
        // Discount Schdeules for the main bundle product
            if(count < =1 && li.associatedProdId ==null){

                unitOfMeasure = li.uom; // Unit of Measure for the main bundle product

                if(li.tiers.size()>1 && li.pricingModel!='Quantity based commit')
                    {
                    discountSchedules.put(li.productName,li.tiers);
                    }   
            }
        }
        for (CPQ_PM_UtilityClass.ListItems li : filteredListItems){

        if(String.isNotBlank(li.associatedProdId) && li.associatedProdId != li.productId){

                    optionalMktProdIdsCarrier.add(li.associatedProdId); 
                    optionalProductMap.put(li.Name,createOptionalProduct(li, this.recordTypeId,typeOfProduct,attributeDeserialized));
                    System.debug('optionalProductMap'+optionalProductMap);

        }
        else
        {
                    optionalMktProdIdsCarrier.add(li.productId);
                    optionalProductMap.put(li.Name,createOptionalProduct(li, this.recordTypeId,typeOfProduct,attributeDeserialized));
                    System.debug('optionalProductMap'+optionalProductMap);

        }

        if(li.tiers.size()>1 && li.pricingModel!='Quantity based commit'){

            discountSchedules.put(li.Name,li.tiers);
            }

    }

    Map<String,String> pricingDetails = new Map<String,String>();
    pricingDetails = prodDetails.currencyResponse;

    System.debug(pricingDetails+'pricingDetails');

    for(String pricing : pricingDetails.keySet()){
        
        if(!pricingDetails.get(pricing).contains('status')){
            CPQ_PM_UtilityClass.PacPricingApi multiplePricingDeserialized = (CPQ_PM_UtilityClass.PacPricingApi) JSON.deserialize(pricingDetails.get(pricing), CPQ_PM_UtilityClass.PacPricingApi.Class);
        
            for(CPQ_PM_UtilityClass.ListItems li : multiplePricingDeserialized.listItems) {
                if(validateLine(li,typeOfProduct)){
                    
                    if(count < =1 && li.associatedProdId ==null){
       
                    mainProductPricingMap.put(li.currencyId,li.tiers[0].geoRegionPricing[0].pricePoints.list_Z);
                    System.debug('mainProductPricingMap :- '+ mainProductPricingMap);
                        
                    }
                    optionalProductPricingMap.put(li.currencyId+'_'+li.Name,li.tiers[0].geoRegionPricing[0].pricePoints.list_Z);
                    System.debug('optionalProductPricingMap'+optionalProductPricingMap);  
                    
                }
                
            }
        }
        
    }
           
    }
    else{
            for(CPQ_PM_UtilityClass.ListItems li : pricingDeserialized.listItems) {
            if(validateLine(li,typeOfProduct)){
                // TODO: this condition needs to be checked. 
                filteredListItems.add(li);
            }
            /*  if(li.associatedProdId != null && li.associatedProdId != this.productCode){
                optionalSkuCreated.add(li.associatedProdId);
            } */
        }

        for (CPQ_PM_UtilityClass.ListItems li : filteredListItems){

            if(String.isNotBlank(li.associatedProdId) && li.associatedProdId != li.productId) { 
                optionalMktProdIds.add(li.associatedProdId); 
                optionalProductMap.put(li.associatedProdId, createOptionalProduct(li, this.recordTypeId,typeOfProduct,attributeDeserialized));
            }
            /* if(String.isNotBlank(li.secLvlAssociatedProdId)) { 
                optionalMktProdIds.add(li.secLvlAssociatedProdId); 
            } */
            if( li.secLvlAssociatedProdId != null){
                parentSubProducts.add(li.associatedProdId);
            }

        }
        }
        
        return this;
    }

    /**
     * @description validateLine will validate the PLIs in the pricing response to find the autonomy applicable features
     * @param  li pricing API PLI
     * @return    returns true if valid , else returns false
     */
    private static Boolean validateLine(CPQ_PM_UtilityClass.ListItems li,String typeOfProduct) {
        /**
         * PLI should not:
         * have custom pricing
         * have isApplicableWhenStandalone as False
         * be part of special exclusions: NS, mPulse, mPulse Lite
         */
        
    if(typeOfProduct == 'Partner'){
        return li.tiers[0].geoRegionPricing[0].pricePoints.wholesale != -1 // for partners we check wholesale price
        && !PRODUCTS_TO_BE_EXCLUDED.contains(li.associatedProdId)
        && li.sectionName != 'End of sale' //only one entry is needed for bundle type optional prods like china cdn, client reputation etc
        && li.secLvlAssociatedProdId == null;
    }
    else{
        Decimal listprice = Decimal.valueOf(li.tiers[0].geoRegionPricing[0].pricePoints.list_Z); //// for partners we check list price
        return listprice != -1 
        && !PRODUCTS_TO_BE_EXCLUDED.contains(li.associatedProdId)
        && li.sectionName != 'End of sale' 
        && li.secLvlAssociatedProdId == null;

    }

    }

    private static product2 createOptionalProduct(CPQ_PM_UtilityClass.ListItems li, Id recordTypeId,String typeOfProduct,CPQ_PM_UtilityClass.PacAttributesApi attributeDeserialized){
        Integer randomInt = getindex();
        product2 tempProduct = new Product2();

        tempProduct.Name = li.associatedProdName!=null ? li.associatedProdName :li.Name ;
        tempProduct.ProductCode = li.associatedProdId !=null ?li.associatedProdId: li.productId;
        tempProduct.Product_Notes__c = li.Name;
        tempProduct.SBQQ__Component__c = true;
        tempProduct.IsActive = true;
        
        if(test.isRunningTest()){
        tempProduct.AKAM_Product_ID__c='F-PRO'+randomInt;
        }
        
        if(typeOfProduct=='Partner'){
        tempProduct.SBQQ__ConfigurationFieldSet__c = 'CPQ_OptionConfiguration_Partner';  
        }
        else{
        tempProduct.SBQQ__ConfigurationFieldSet__c = 'OptionConfiguration';
        tempProduct.Family = attributeDeserialized.productAttributes.marketingCategory;
        tempProduct.UOM__c = li.uom != null?li.uom:null;
        tempProduct.Description=li.Name;
        }
        tempProduct.RecordTypeId = recordTypeId;

        return tempProduct;
    }
    public static Integer getindex(){
    return Math.round((Math.random() * (900000) + 100000));
    }

    public class CPQ_PM_APIDataProcessorException extends CPQ_CustomException {

        public CPQ_PM_APIDataProcessorException(String message, CPQ_CustomException.StatusCode ec) {
            super(message, ec);    
        }

    }

}