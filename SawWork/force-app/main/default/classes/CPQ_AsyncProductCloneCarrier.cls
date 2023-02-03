public with sharing class CPQ_AsyncProductCloneCarrier implements Queueable,Database.AllowsCallouts {

    private string productCode;
    private CPQ_ProductLaunchSetting__c productSettings;
    private CPQ_CarrierDataProcessor processedData;
    private CPQ_ProductLaunchManagement__c launchInstance;
    
    private String aPIResponse;
    
    public CPQ_AsyncProductCloneCarrier(String productCode,CPQ_ProductLaunchSetting__c productSettings,CPQ_ProductLaunchManagement__c launchInstance){
        
        this.productCode = productCode;
        this.productSettings = productSettings;
        this.launchInstance = launchInstance;
        
    }
    
    public void execute(QueueableContext context) {
    
        try {

            List<CurrencyType> currenciesTypes= [SELECT IsoCode
            FROM CurrencyType
            WHERE IsActive = true];
    
            aPIResponse = JSON.serialize(CPQ_PM_ApiCalllout.getProductDetails(this.productCode,currenciesTypes));
        }
        catch (Exception e) {
            
        this.launchInstance.Product_Creation_Status__c = 'Failure';
        this.launchInstance.Product_Creation_Message__c = e.getMessage();
        Database.upsert(this.launchInstance);
        CPQ_LogException.add(new CPQ_LogException(e, null).setShortMessage('CPQ_AsyncProductCloneCarrier: ' + this.productCode + ' : Failed to get the data from the source').getErrorRecord());
        }
    
    RecordType productRecordType = new RecordType();
    
    List<String> optionalMktProdIdsCarrier = new List<String>();
    
    Savepoint sp = Database.setSavepoint();
    try {
    
    
    
    productRecordType = [SELECT id, DeveloperName, SobjectType 
    FROM RecordType
    WHERE DeveloperName = 'Carrier_Products' AND SobjectType = 'Product2'
    WITH SECURITY_ENFORCED];
    
    CPQ_CarrierDataProcessor processedData = new CPQ_CarrierDataProcessor(this.productCode, productRecordType.Id).generateProductData(aPIResponse,this.productSettings);
    this.processedData = processedData;
    
    // collect all the optional product Ids from all the carrier products
    optionalMktProdIdsCarrier.addAll(this.processedData.optionalMktProdIdsCarrier);
    CPQ_LogException.logInformation('optionalMktProdIdsCarrier: '+optionalMktProdIdsCarrier);
    
    // create discount schedules
    CPQ_DiscountSchedule.createDiscountSchedules(CPQ_CarrierDataProcessor.discountSchedules);
    
    // create optional products if needed
    CPQ_OptionalProduct_Handler.productPresenceCheck(CPQ_CarrierDataProcessor.optionalProductMap,CPQ_CarrierDataProcessor.optionalProductPricingMap,'Carrier');
    
    
    CPQ_Carrier_Product_Bundle.createCarrierBundleProduct(this.productCode, this.processedData, this.launchInstance);
     
    } 
    catch (Exception e) {
    
    Database.rollback(sp);
    this.launchInstance.Product_Creation_Status__c = 'Failure';
    this.launchInstance.Product_Creation_Message__c = e.getMessage();
    Database.upsert(this.launchInstance);
    CPQ_LogException.add(new CPQ_LogException(e, null).setShortMessage('CPQ_AsyncProductCloneCarrier:' + new CPQ_CustomException().getLineNumber() + ']:' + this.productCode + ' : Failed to process the data').getErrorRecord());
    }
    finally{
    
    CPQ_LogException.flush();
    CPQ_LogException.clear();
    
    }
    
        
    
    }

}