public with sharing class CPQ_CarrierDataProcessor extends CPQ_DataProcessor {

//final members
private static final Set<String> PRODUCTS_TO_BE_EXCLUDED = CPQSettings.getMetadataValues('CPQ_productsToBeExcluded');

//static members
public static Map<String, product2> optionalProductMap = new Map<String, product2>();
public static Map<String,String> optionalProductPricingMap = new Map<String,String>(); //handle currency for optional products
public static Map<String,List<CPQ_PM_UtilityClass.Tiers>> discountSchedules = new Map<String,List<CPQ_PM_UtilityClass.Tiers>>(); // handle Discount Schdeule response

public  Map<String,String> mainProductPricingMap = new Map<String,String>(); //handle currency for main product
public Integer count=0;

public CPQ_CarrierDataProcessor(String productCode, Id recordTypeId) {
    super(productCode,recordTypeId);
    
}

public CPQ_CarrierDataProcessor generateProductData(String prodDetailsResponse,CPQ_ProductLaunchSetting__c productSetting){

    this.apiDataProcessing(prodDetailsResponse);

    for(CPQ_PM_UtilityClass.ListItems li : pricingDeserialized.listItems) {

        if(validateLine(li)){

            
            /* Logic to Handle products with mutiple commit pricing
            Here we are getting the count of plis where associated productid is null.
            If count < 1 ----> we dont create the pli ( pass all the commit pli details to the main product (ex :- pricing+ discount schdeule and more))
            If count > 1 ----> we create all the plis */

            if(li.associatedProdId == null){    // TODO: this condition needs to be checked.
                count = count+1;
                CPQ_LogException.logInformation('count: '+count);   
            }
                
        }
    }

    for(CPQ_PM_UtilityClass.ListItems li : pricingDeserialized.listItems){
        
        if(validateLine(li)){

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

                unitOfMeasure = li.uom; //Unit of Measure for the main bundle product
                if(li.tiers.size()>1 && li.pricingModel!='Quantity based commit')
                {

                    discountSchedules.put(li.productName,li.tiers);
                    }
                    
                    
            
        }
    }

    for (CPQ_PM_UtilityClass.ListItems li : filteredListItems){

        if(String.isNotBlank(li.associatedProdId) && li.associatedProdId != li.productId){

                    optionalMktProdIdsCarrier.add(li.associatedProdId); 
                    optionalProductMap.put(li.Name,createOptionalProduct(li, this.recordTypeId,attributeDeserialized));
                    CPQ_LogException.logInformation('optionalProductMap: '+optionalProductMap);

        }
        else
        {
                    optionalMktProdIdsCarrier.add(li.productId); 
                    optionalProductMap.put(li.Name,createOptionalProduct(li, this.recordTypeId,attributeDeserialized));
                    CPQ_LogException.logInformation('optionalProductMap: '+optionalProductMap);

        }

        if(li.tiers.size()>1 && li.pricingModel!='Quantity based commit'){

            discountSchedules.put(li.Name,li.tiers);
            }

    }


    //System.debug(pricingDetails+'pricingDetails');

    for(String pricing : pricingDetails.keySet()){
        
        if(!pricingDetails.get(pricing).contains('status')){
            CPQ_PM_UtilityClass.PacPricingApi multiplePricingDeserialized = (CPQ_PM_UtilityClass.PacPricingApi) JSON.deserialize(pricingDetails.get(pricing), CPQ_PM_UtilityClass.PacPricingApi.Class);
        
            for(CPQ_PM_UtilityClass.ListItems li : multiplePricingDeserialized.listItems) {
                if(validateLine(li)){
                    
                    if(count < =1 && li.associatedProdId ==null){
        
                    mainProductPricingMap.put(li.currencyId,li.tiers[0].geoRegionPricing[0].pricePoints.list_Z);
                    CPQ_LogException.logInformation('mainProductPricingMap: '+mainProductPricingMap);
                        
                    }
                    
                    optionalProductPricingMap.put(li.currencyId+'_'+li.Name,li.tiers[0].geoRegionPricing[0].pricePoints.list_Z);
                    CPQ_LogException.logInformation('optionalProductPricingMap: '+optionalProductPricingMap);  
                    
                }
                
            }
        }
        
    }
    
    return this;
}

/**
 * @description validateLine will validate the PLIs in the pricing response to find the carrier applicable features
 * @param  li pricing API PLI
 * @return    returns true if valid , else returns false
 */
public override Boolean validateLine(CPQ_PM_UtilityClass.ListItems li) {
    
   
        return li.sectionName != 'End of sale' // filter to remove plis which are EOS
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
    tempProduct.SBQQ__ConfigurationFieldSet__c = 'OptionConfiguration';
    tempProduct.Family = attributeDeserialized.productAttributes.marketingCategory;
    tempProduct.UOM__c = li.uom != null?li.uom:null;
    tempProduct.Description=li.Name;
    tempProduct.RecordTypeId = recordTypeId;

    return tempProduct;
}
public static Integer getindex(){
    return Math.round((Math.random() * (900000) + 100000));
}

public class CPQ_CarrierDataProcessorException extends CPQ_CustomException {

    public CPQ_CarrierDataProcessorException(String message, CPQ_CustomException.StatusCode ec) {
        super(message, ec);    
    }

}
}