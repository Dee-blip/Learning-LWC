/* 
* @author  Shashank Hegade, Mausam Singh
* @since   2021-09-23 (Updated to verify section Details)
*/
public with sharing class CPQ_PM_ApiCalllout {

// Pricing End Point
private static final String PAC_PRICING_ENDPOINT = CPQSettings.getValue('PAC_Endpoint_Get_Pricing');
private static final String GEOSET = 'WORLD';
private static final String PARTNER_ACC_ID ='F-AC-1950718';


private static CpqAPICalloutClass calloutObj = new CpqAPICalloutClass();
private static CPQ_PM_UtilityClass.ApiResponseWrapper responseObj = new CPQ_PM_UtilityClass.ApiResponseWrapper();
/**
* This method first validates the product mkt id, if success then makes the other callouts.
*/
@AuraEnabled
public static CPQ_PM_UtilityClass.ApiResponseWrapper getProductDetails(String  mktProdId) {
    
    String attributeResponse = calloutObj.getAttributeDetails(mktProdId);
    CPQ_LogException.logInformation('attributeResponse: '+attributeResponse);
    
    Map<String, Object> validateAttributeApiResponse = (Map<String, Object>) JSON.deserializeUntyped(attributeResponse);
    
    if (validateAttributeApiResponse.containsKey('status')) {
        //error occurred
        
        CPQ_PM_UtilityClass.ErrorResponse errorResponse = (CPQ_PM_UtilityClass.ErrorResponse) JSON.deserialize(attributeResponse, CPQ_PM_UtilityClass.ErrorResponse.Class);
        responseObj.errorResponse = errorResponse;
        responseObj.validity = false;
        
        return responseObj;
        
    } 
    
    responseObj.validity = true;
    responseObj.attributeResponse = attributeResponse;
    
    // get the features from section API
    String sectionResponse = calloutObj.getSectionsDetails(mktProdId, 'Direct,Partner', GEOSET);
    responseObj.sectionResponse = sectionResponse;
    
    //get options from pricing API
    String pricingResponse = calloutObj.getPricingDetails(mktProdId, 'USD', 'Direct,Partner', GEOSET, 'NA',PARTNER_ACC_ID);
    pricingResponse = pricingResponse.replaceAll('"list":', '"list_Z":');
    responseObj.pricingResponse = pricingResponse;
    
    String literatureResponse = calloutObj.getLiteratureDetails(mktProdId);
    responseObj.literatureResponse = literatureResponse;
    
    return responseObj;
    
}

@AuraEnabled
public static CPQ_PM_UtilityClass.ApiResponseWrapper getProductDetails(String  mktProdId,List<CurrencyType> currenciesTypes) {
    
    Map<String,String> priceInfo = new Map<String,String>();
    String carrierPricingResponse ='';

    String attributeResponse = calloutObj.getAttributeDetails(mktProdId);
    CPQ_LogException.logInformation('attributeResponse: '+attributeResponse);
    
    Map<String, Object> validateAttributeApiResponse = (Map<String, Object>) JSON.deserializeUntyped(attributeResponse);
    
    if (validateAttributeApiResponse.containsKey('status')) {
        //error occurred
        
        CPQ_PM_UtilityClass.ErrorResponse errorResponse = (CPQ_PM_UtilityClass.ErrorResponse) JSON.deserialize(attributeResponse, CPQ_PM_UtilityClass.ErrorResponse.Class);
        responseObj.errorResponse = errorResponse;
        responseObj.validity = false;
        
        return responseObj;
        
    } 
    
    responseObj.validity = true;
    responseObj.attributeResponse = attributeResponse;
    
    // get the features from section API
    String sectionResponse = calloutObj.getSectionsDetails(mktProdId, 'Direct,Partner', GEOSET);
    responseObj.sectionResponse = sectionResponse;

    
    //get options from pricing API
    String pricingResponse = calloutObj.getCarrierPricingDetails(mktProdId, 'USD', 'Direct,Partner', GEOSET, 'NA',PAC_PRICING_ENDPOINT);
    pricingResponse = pricingResponse.replaceAll('"list":', '"list_Z":');
    responseObj.pricingResponse = pricingResponse;

    //get product description from pricing API
    String literatureResponse = calloutObj.getLiteratureDetails(mktProdId);
    responseObj.literatureResponse = literatureResponse;
    
    /*
    1. get pricing response for Carrier products for Different Currency
    2. For Partner Product - we don't need pricing response for different currency + Heap size will exceed(apex heap size too large)
    */
        
    for(CurrencyType cr : currenciesTypes)
    {
        carrierPricingResponse = calloutObj.getCarrierPricingDetails(mktProdId,cr.IsoCode,'Direct,Partner', GEOSET, 'NA',PAC_PRICING_ENDPOINT);
        CPQ_LogException.logInformation('carrierPricingResponse: '+carrierPricingResponse);
            
            carrierPricingResponse = carrierPricingResponse.replaceAll('"list":', '"list_Z":'); // Handles APEX reserved keyword in JSON
            priceInfo.put(cr.IsoCode,carrierPricingResponse);
        
        
    }
    responseObj.currencyResponse = priceInfo;
    
    return responseObj;
    
}
/**
 * This method validates the productsIds from PAC 
 */

@AuraEnabled
public static CPQ_PM_UtilityClass.ApiResponseWrapper verifyMarktetingProductId(List<string> productId){
        
        String requestBody = requestBodyBuilder(productId);
        String productsInfo = calloutObj.postProductCodes(JSON.deserializeUntyped(requestBody));
        Map<String, Object> productApiResponse = (Map<String, Object>) JSON.deserializeUntyped(productsInfo);
        CPQ_LogException.logInformation('productApiResponse: '+productApiResponse);

        if (productApiResponse.containsKey('status')) {
            //error occurred
            
            CPQ_PM_UtilityClass.ErrorResponse errorResponse = (CPQ_PM_UtilityClass.ErrorResponse) JSON.deserialize(productsInfo, CPQ_PM_UtilityClass.ErrorResponse.Class);
            responseObj.errorResponse = errorResponse;
            responseObj.validity = false;
            return responseObj;
            
        } 
        
        responseObj.validity = true;
        responseObj.productsInfo = productsInfo;
        return responseObj;
}

private static string requestBodyBuilder (List<string> productIdList){
    
    JSONGenerator gen = JSON.createGenerator(false);
    
    gen.writeStartObject();
    gen.writeObjectField('mktProdId', productIdList);
    gen.writeStringField('consumer', 'DEFAULT' );
    gen.writeStringField('locale','en_US');
    gen.writeEndObject();
    
    return gen.getAsString();
    
}
// get the features of multilple products from section API
@AuraEnabled(cacheable=true)
public static Map<String,String> consumeSectionInfo(List<String> productIds){ 
    Map<String, String> sectionMap = new Map<String, String>();
        for(String productId: productIds)
        {    
        String sectionData = calloutObj.getSectionsDetails(productId, 'Direct,Partner', GEOSET);
        sectionMap.put(productId,sectionData);
        }
    return sectionMap;
}

public class PM_CalloutException extends Exception {
    
}
}