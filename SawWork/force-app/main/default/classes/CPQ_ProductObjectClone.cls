/**
* Test Class: CPQ_Test_CPQ_Create_Products
*/
public with sharing class CPQ_ProductObjectClone extends CPQ_SobjectClone{

    public String productCode{get; private set;}
    public CPQ_PartnerDataProcessor productAPIDetails{get; private set;}
    public map<Id,Id> productMappings{get; private set;}

    public CPQ_ProductObjectClone(string productCode, CPQ_PartnerDataProcessor productAPIDetails){
        super('Product2');
        this.productCode = productCode;
        this.productAPIDetails = productAPIDetails;
        this.productMappings = new Map<Id,Id>();
        
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
        ' AND CPQ_Record_Type_Name__c = \'Partner_Products\' ' +
        ' LIMIT 1 '
        ;

        parentRecords = Database.Query( parentQuery );

        SObject clonedProduct;
        
        product2 newProduct = createProduct(productAPIDetails.attributeDeserialized, productAPIDetails.recordTypeId);

        newProduct.Description = productAPIDetails.literatureDeserialized.marketingCollaterals.tagLine + (CPQ_UtilityClass.isSandbox() ? '( PMI: ' + Datetime.now() + ' )': '');
        
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

    private static Product2 createProduct(CPQ_PM_UtilityClass.PacAttributesApi productInfo, Id recordTypeId){

        Product2 returnProduct = new Product2();

        returnProduct.Name = productInfo.productName;
        returnProduct.ProductCode = productInfo.marketingProductId;
        returnProduct.Family = productInfo.productAttributes.marketingCategory;
        /* returnProduct.SBQQ__ConfigurationEvent__c = 'Always';
        returnProduct.SBQQ__ConfigurationType__c = 'Allowed';
        returnProduct.SBQQ__ConfigurationFieldSet__c = 'CPQ_OptionConfiguration_Partner'; */
        returnProduct.CPQ_ProductUpdateCode__c = productInfo.currentActiveVersion;
        // returnProduct.SBQQ__OptionLayout__c = 'Tabs';
        // returnProduct.Description = 'New Autonomy-Product Master test copy: ' + Datetime.now(); //TODO: need to review this
        returnProduct.CPQ_Reviewed__c = false;
        returnProduct.CPQ_ProductIntegrationMessage__c = '//** Created By Product Master Integration: ' + Datetime.now() + ' **//';
        returnProduct.recordTypeId = recordTypeId;
        
        return returnProduct;

    }

    private static Product2 setDefaultValuesforProduct(Product2 record){

        record.SBQQ__ConfigurationEvent__c = 'Always';
        record.SBQQ__ConfigurationType__c = 'Allowed';
        record.SBQQ__ConfigurationFieldSet__c = 'CPQ_OptionConfiguration_Partner';
        record.SBQQ__OptionLayout__c = 'Tabs';

        return record;

    }
        

}