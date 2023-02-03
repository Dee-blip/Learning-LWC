public with sharing class CPQ_Partner_Product_Bundle {

    public static void createPartnerBundleProduct(String productCode,CPQ_PartnerDataProcessor processedData,CPQ_ProductLaunchManagement__c launchInstance){

        CPQ_ProductObjectClone productInstance = new CPQ_ProductObjectClone(productCode,processedData);
        List<sObject> clonedRecords = new CPQ_CloneHandler().run(productInstance);

        launchInstance.Product_previous_version__c = clonedRecords[0].getCloneSourceId();

        CPQ_ProductFeatureClone productFeatureInstance = new CPQ_ProductFeatureClone(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id, productInstance.productAPIDetails);
        new CPQ_CloneHandler().run(productFeatureInstance);

        CPQ_ProductOptionClone productOptionInstance = new CPQ_ProductOptionClone(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id,productFeatureInstance.featureMapping, productFeatureInstance.productAPIDetails);
        new CPQ_CloneHandler().run(productOptionInstance);

        CPQ_OptionConstraintClone optionConstraintInstance = new CPQ_OptionConstraintClone(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id,  productOptionInstance.optionMapping);
        new CPQ_CloneHandler().run(optionConstraintInstance);

        CPQ_ConfigurationAttributeClone configurationAttributeInstance = new CPQ_ConfigurationAttributeClone(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id, productOptionInstance.productAPIDetails, productFeatureInstance.featureMapping);
        new CPQ_CloneHandler().run(configurationAttributeInstance);

        CPQ_ConfigurationRuleClone configurationRuleInstance = new CPQ_ConfigurationRuleClone( clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id,productOptionInstance.productAPIDetails, productFeatureInstance.featureMapping);
        new CPQ_CloneHandler().run(configurationRuleInstance);

        CPQ_PriceBookEntryClone pbeInstance = new CPQ_PriceBookEntryClone(clonedRecords[0].getCloneSourceId(), clonedRecords[0].Id);
        new CPQ_CloneHandler().run(pbeInstance);

        launchInstance.Product_Creation_Status__c = 'Success';
        launchInstance.Product__c = clonedRecords[0].Id;
        Database.upsert(launchInstance);

}
                
}