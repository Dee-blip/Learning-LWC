public with sharing class CPQ_PartnerDataProcessor extends CPQ_DataProcessor  {
//final members
private static final Set<String> PRODUCTS_TO_BE_EXCLUDED = CPQSettings.getMetadataValues('CPQ_productsToBeExcluded');


//static members
public static Map<String, product2> optionalProductMap = new Map<String, product2>();
public static Map<String,String> optionalProductPricingMap = new Map<String,String>(); //handle currency for optional products


public CPQ_PartnerDataProcessor(String productCode, Id recordTypeId) {
    super(productCode,recordTypeId);
}

public CPQ_PartnerDataProcessor generateProductData(String prodDetailsResponse,CPQ_ProductLaunchSetting__c productSetting){
    
    this.apiDataProcessing(prodDetailsResponse);

    usageSectionId = productSetting.UsageSectionNumber__c;
    
    
    List<String> billingModelslist = productSetting.BillingModels__c?.split(';');
    //System.debug('The billing models ==> ' + productSetting.BillingModels__c);
    if( billingModelslist != null && billingModelslist.size() > 0){
        hasMultipleBillingModels = true;
        billingModels = billingModelslist;
    }

        for(CPQ_PM_UtilityClass.ListItems li : pricingDeserialized.listItems) {
            if(validateLine(li)){
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
                optionalProductMap.put(li.associatedProdId, createOptionalProduct(li, this.recordTypeId,attributeDeserialized));
            }
            /* if(String.isNotBlank(li.secLvlAssociatedProdId)) { 
                optionalMktProdIds.add(li.secLvlAssociatedProdId); 
            } */
            if( li.secLvlAssociatedProdId != null){
                parentSubProducts.add(li.associatedProdId);
            }

        }

        
    return this;
}

/**
 * @description validateLine will validate the PLIs in the pricing response to find the autonomy applicable features
 * @param  li pricing API PLI
 * @return    returns true if valid , else returns false
 */
public override Boolean validateLine(CPQ_PM_UtilityClass.ListItems li) {
    /**
     * PLI should not:
     * have custom pricing
     * have isApplicableWhenStandalone as False
     * be part of special exclusions: NS, mPulse, mPulse Lite
     */
    return li.tiers[0].geoRegionPricing[0].pricePoints.wholesale != -1 // for partners we check wholesale price
    && !PRODUCTS_TO_BE_EXCLUDED.contains(li.associatedProdId)
    && li.sectionName != 'End of sale' //only one entry is needed for bundle type optional prods like china cdn, client reputation etc
    && li.secLvlAssociatedProdId == null;
    


    }
    
public static product2 createOptionalProduct(CPQ_PM_UtilityClass.ListItems li, Id recordTypeId,CPQ_PM_UtilityClass.PacAttributesApi attributeDeserialized){
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
    tempProduct.SBQQ__ConfigurationFieldSet__c = 'CPQ_OptionConfiguration_Partner';  
    tempProduct.RecordTypeId = recordTypeId;

    return tempProduct;
}

public static Integer getindex(){
    return Math.round((Math.random() * (900000) + 100000));
}

public class CPQ_PartnerDataProcessorException extends CPQ_CustomException {

    public CPQ_PartnerDataProcessorException(String message, CPQ_CustomException.StatusCode ec) {
        super(message, ec);    
    }

}
}