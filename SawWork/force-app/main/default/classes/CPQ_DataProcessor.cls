abstract public with sharing class CPQ_DataProcessor {
//public members
public String productCode{get;set;}
public Id recordTypeId{ get; set;}
public Set<String> optionalSkuCreated;
public Boolean hasMultipleBillingModels{get;set;}
public Decimal usageSectionId{ get; set;}
public List<String> billingModels{ get;set;}
protected Boolean canHavePlatformFee{ get; set;}
public Set<String> optionalMktProdIds{ get; set;}
public List<String> optionalMktProdIdsCarrier{get; set;}
public set<String> parentSubProducts{ get; set;}
public String unitOfMeasure{get; set;}
public Id usageSectionSFId{get; set;}
public String usageSectionName{ get; set;}

public CPQ_PM_UtilityClass.PacAttributesApi attributeDeserialized{get; private set;}
public List<CPQ_PM_UtilityClass.ListItems> filteredListItems{get; private set;}
public List<CPQ_PM_UtilityClass.PacSectionsApi> productSectionInfo{get; private set;}
public CPQ_PM_UtilityClass.PacLiteratureApiWrapper literatureDeserialized{get; private set;}
public CPQ_PM_UtilityClass.PacPricingApi pricingDeserialized{get; private set;}
public Map<String,String> pricingDetails = new Map<String,String>();

public CPQ_DataProcessor(String productCode, Id recordTypeId){
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
abstract public Boolean validateLine(CPQ_PM_UtilityClass.ListItems li); 

protected void apiDataProcessing(String prodDetailsResponse){
    CPQ_PM_UtilityClass.ApiResponseWrapper prodDetails = (CPQ_PM_UtilityClass.ApiResponseWrapper) JSON.deserialize(prodDetailsResponse, CPQ_PM_UtilityClass.ApiResponseWrapper.Class);

    //if the the response is in invalid. 
    if(prodDetails.validity == false){
        throw new CPQ_DataProcessorException('Invalid information: ' +  
                                                    this.productCode + '\n' + 
                                                    JSON.serialize(prodDetails.errorResponse),
                                                    CPQ_CustomException.StatusCode.PAC_ERROR);
    }
    
    this.attributeDeserialized = (CPQ_PM_UtilityClass.PacAttributesApi) JSON.deserialize(prodDetails.attributeResponse, CPQ_PM_UtilityClass.PacAttributesApi.Class);
    this.literatureDeserialized = (CPQ_PM_UtilityClass.PacLiteratureApiWrapper)  JSON.deserialize(prodDetails.literatureResponse, CPQ_PM_UtilityClass.PacLiteratureApiWrapper.class);
    
    List<CPQ_PM_UtilityClass.PacSectionsApi> sectionsDeserialized = (List<CPQ_PM_UtilityClass.PacSectionsApi>) JSON.deserialize(prodDetails.sectionResponse, List<CPQ_PM_UtilityClass.PacSectionsApi>.Class);
    
    //setting the feature data
    for(CPQ_PM_UtilityClass.PacSectionsApi section : sectionsDeserialized){
    
    if(section.name != 'End of sale' && !section.name.containsIgnoreCase('NetStorage')){
    
    this.productSectionInfo.add(section);
    
    }
    }
    this.pricingDeserialized = (CPQ_PM_UtilityClass.PacPricingApi) JSON.deserialize(prodDetails.pricingResponse, CPQ_PM_UtilityClass.PacPricingApi.Class);
    this.pricingDetails = prodDetails.currencyResponse;


}
public class CPQ_DataProcessorException extends CPQ_CustomException {

    public CPQ_DataProcessorException(String message, CPQ_CustomException.StatusCode ec) {
        super(message, ec);    
    }

} 
}