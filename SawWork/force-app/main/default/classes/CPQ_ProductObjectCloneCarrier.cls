public with sharing class CPQ_ProductObjectCloneCarrier extends CPQ_SobjectClone {
    public String productCode{get; private set;}
    public CPQ_CarrierDataProcessor productAPIDetails{get; private set;}
    public map<Id,Id> productMappings{get; private set;}
    public String unitOfMeasure;
    public Id launchId;
    
    public CPQ_ProductObjectCloneCarrier(string productCode, CPQ_CarrierDataProcessor productAPIDetails,CPQ_ProductLaunchManagement__c launchInstance) {

        super('Product2');
        this.productCode = productCode;
        this.productAPIDetails = productAPIDetails;
        this.productMappings = new Map<Id,Id>();
        this.unitOfMeasure = productAPIDetails.unitOfMeasure;
        this.launchId = launchInstance.Launch__c;
    }
    public override List<SObject> beforeClone(){

       List<SObject> parentRecords = new List<Sobject>();
        
        String parentQuery =
        ' SELECT ' +
        String.join( parentFieldNames, ',' ) +
        ' FROM ' +
        sObjectType +
        ' WHERE ' +
        ' ProductCode = :productCode ' +
        ' AND IsActive = true ' +
        ' AND SBQQ__Component__c =false'+
        ' AND CPQ_Record_Type_Name__c = \'Carrier_Products\' ' +
        ' LIMIT 1 '
        ;

        parentRecords = Database.Query( parentQuery );

        SObject clonedProduct;
        
        product2 newProduct = createProduct(productAPIDetails.attributeDeserialized, productAPIDetails.recordTypeId);

        newProduct.Description = productAPIDetails.literatureDeserialized.marketingCollaterals.tagLine !=null ? productAPIDetails.literatureDeserialized.marketingCollaterals.tagLine : productAPIDetails.attributeDeserialized.productName+ (CPQ_UtilityClass.isSandbox() ? '( PMI: ' + Datetime.now() + ' )': '');
        
        
            //if the product is created new set the default values
           /* newProduct = setDefaultValuesforProduct(newProduct);
            clonedProduct = (SObject) newProduct;*/
        
        
            if(parentRecords.size() < 1){
                //if the product is created new set the default values
                newProduct = setDefaultValuesforProduct(newProduct);
                clonedProduct = (SObject) newProduct;
            }
            else{
               
                clonedProduct = parentRecords[0].clone(false, true);
                Map<String, Object> latestChange = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(newProduct));
                clonedProduct = this.applyFieldValue(clonedProduct, latestChange);   
                    
    
                
            }

        clonedProduct.put('CPQExternalID__c', null);
        clonedProduct.put('IsActive', false);
        clonedProduct.put('AKAM_Product_ID__c', null);
        clonedProduct.put('AKAM_INT_ID__c', null);
        clonedProduct.put('OD_Product_Row_ID__c', null);
        //Testing specific condition is handled here
        if(test.isRunningTest()){
            clonedProduct.put('AKAM_Product_ID__c', 'test-string-autonomy');
        }

        return new List<Sobject>{clonedProduct};
        
    }

    public override List<sObject> afterClone(List<SObject> clonedRecords){

        for(Integer i = 0; i < clonedRecords.size(); i++){
            if(clonedRecords[i].getCloneSourceId() != null)
            this.productMappings.put(clonedRecords[i].getCloneSourceId(),clonedRecords[i].Id);
        }

        return clonedRecords;
    }

    private  Product2 createProduct(CPQ_PM_UtilityClass.PacAttributesApi productInfo, Id recordTypeId){

        Product2 returnProduct = new Product2();

        returnProduct.Name = productInfo.productName;
        returnProduct.ProductCode = productInfo.marketingProductId;
        returnProduct.Family = productInfo.productAttributes.marketingCategory;
        returnProduct.CPQ_ProductUpdateCode__c = productInfo.currentActiveVersion;
        returnProduct.CPQ_Reviewed__c = false;
        returnProduct.SBQQ__PricingMethod__c = 'List';
        returnProduct.SBQQ__PriceEditable__c = true;
        returnProduct.SBQQ__QuantityEditable__c = false;
        returnProduct.CPQ_ProductIntegrationMessage__c = '//** Created By Product Master Integration: ' + Datetime.now() + ' **//';
        returnProduct.recordTypeId = recordTypeId;
        returnProduct.UOM__c= this.unitOfMeasure;
        returnProduct.CPQ_Launch__c=setLaunchforProduct(this.launchId);
        returnProduct.SBQQ__DiscountSchedule__c = setDiscountScheduleforProduct(productInfo.productName);
        
        return returnProduct;

    }

    private static Product2 setDefaultValuesforProduct(Product2 record){

        record.SBQQ__ConfigurationEvent__c = 'Always';
        record.SBQQ__ConfigurationType__c = 'Allowed';
        record.SBQQ__ConfigurationFieldSet__c = 'OptionConfiguration';
        record.SBQQ__OptionLayout__c = 'Tabs';
        

        return record;

    }
    private static Id setDiscountScheduleforProduct(String productName){

         for(SBQQ__DiscountSchedule__c record: [SELECT Id FROM SBQQ__DiscountSchedule__c WHERE Name = :productName limit 1]) {
            return record.Id;
          }
          return null;

    }
    private static String setLaunchforProduct(Id launchId){

           for(PLU__c record: [SELECT Id,Name FROM PLU__c WHERE id = : launchId]) {
            return record.Name;
          }
          return null;
    }
    
}