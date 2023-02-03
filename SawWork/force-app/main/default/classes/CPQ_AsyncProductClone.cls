/**
* Test Class: CPQ_Test_CPQ_Create_Products
*/
public with sharing class CPQ_AsyncProductClone implements Queueable,Database.AllowsCallouts {

private string productCode;
private CPQ_ProductLaunchSetting__c productSettings;
private CPQ_PartnerDataProcessor partnerProcessedData;
private CPQ_ProductLaunchManagement__c launchInstance;

private String aPIResponse;

public CPQ_AsyncProductClone(String productCode,CPQ_ProductLaunchSetting__c productSettings,CPQ_ProductLaunchManagement__c launchInstance){
    
    this.productCode = productCode;
    this.productSettings = productSettings;
    this.launchInstance = launchInstance;
}

public void execute(QueueableContext context) {

    try {

        aPIResponse = JSON.serialize(CPQ_PM_ApiCalllout.getProductDetails(this.productCode));
    }
    catch (Exception e) {
        
    this.launchInstance.Product_Creation_Status__c = 'Failure';
    this.launchInstance.Product_Creation_Message__c = e.getMessage();
    Database.upsert(this.launchInstance);
    CPQ_LogException.add(new CPQ_LogException(e, null).setShortMessage('CPQ_AsyncProductClone: ' + this.productCode + ' : Failed to get the data from the source').getErrorRecord());
    }

RecordType productRecordType = new RecordType();

Set<String> optionalProductIds = new Set<String>();

Savepoint sp = Database.setSavepoint();
try {

productRecordType = [SELECT id, DeveloperName, SobjectType 
FROM RecordType
WHERE DeveloperName = 'Partner_Products' AND SobjectType = 'Product2'
WITH SECURITY_ENFORCED];

CPQ_PartnerDataProcessor processedData = new CPQ_PartnerDataProcessor(this.productCode, productRecordType.Id).generateProductData(aPIResponse,this.productSettings);
this.partnerProcessedData = processedData;

// collect all the optional product Ids from all the partner products
optionalProductIds.addAll(this.partnerProcessedData.optionalMktProdIds);
CPQ_LogException.logInformation('optionalProductIds: '+optionalProductIds);

//removing the sub-product which has further configuration (e.g client reputation) will be removed As it has to be configured separately 
optionalProductIds.removeAll(this.partnerProcessedData.parentSubProducts);

// create optional products if needed
CPQ_OptionalProduct_Handler.productPresenceCheck(CPQ_PartnerDataProcessor.optionalProductMap,CPQ_PartnerDataProcessor.optionalProductPricingMap,'Partner');

CPQ_Partner_Product_Bundle.createPartnerBundleProduct(this.productCode, this.partnerProcessedData, this.launchInstance);
}



catch (Exception e) {

Database.rollback(sp);
this.launchInstance.Product_Creation_Status__c = 'Failure';
this.launchInstance.Product_Creation_Message__c = e.getMessage();
Database.upsert(this.launchInstance);
CPQ_LogException.add(new CPQ_LogException(e, null).setShortMessage('CPQ_AsyncProductClone:' + new CPQ_CustomException().getLineNumber() + ']:' + this.productCode + ' : Failed to process the data').getErrorRecord());
}
finally{

CPQ_LogException.flush();
CPQ_LogException.clear();

}

    

}
}