public with sharing class CPQ_Carrier_Product_Bundle {
    
    public static void createCarrierBundleProduct(String productCode,CPQ_CarrierDataProcessor processedData,CPQ_ProductLaunchManagement__c launchInstance){

        CPQ_ProductObjectCloneCarrier productInstance = new CPQ_ProductObjectCloneCarrier(productCode,processedData,launchInstance);
        List<sObject> clonedRecords = new CPQ_CloneHandler().run(productInstance);
    
        launchInstance.Product_previous_version__c = clonedRecords[0].getCloneSourceId();
    
        CPQ_ProductFetaureCloneCarrier productFeatureInstance = new CPQ_ProductFetaureCloneCarrier(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id, productInstance.productAPIDetails);
        new CPQ_CloneHandler().run(productFeatureInstance);
    
        CPQ_Product_Option_Clone_Carrier productOptionInstanceCarrier = new CPQ_Product_Option_Clone_Carrier(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id,productFeatureInstance.featureMapping, productFeatureInstance.productAPIDetails);
        new CPQ_CloneHandler().run(productOptionInstanceCarrier);
                 
        CPQ_PriceBookEntryClone_Carrier pbeInstance = new CPQ_PriceBookEntryClone_Carrier(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id,processedData.mainProductPricingMap);
        new CPQ_CloneHandler().run(pbeInstance);
    
        launchInstance.Product_Creation_Status__c = 'Success';
        launchInstance.Product__c = clonedRecords[0].Id;
        Database.upsert(launchInstance);

    }
}