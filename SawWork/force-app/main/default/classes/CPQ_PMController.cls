public with sharing class CPQ_PMController {

    public static Map<String, String> productInformation = new map<string, String>();
    public static Map<String, CPQ_PM_APIDataProcessor> productAPIDetails = new Map<String, CPQ_PM_APIDataProcessor>();
    
    public static Boolean getProductInformation(Map<String, CPQ_ProductLaunchManagement__c> plmMap, Map<String, CPQ_ProductLaunchSetting__c> productSettings){
        
        Set<String> optionalProductIds = new Set<String>(); 
        List<CPQ_ProductLaunchManagement__c> updateList = new List<CPQ_ProductLaunchManagement__c>();
        try {
            
            for(String productId: productSettings.Keyset()){
                
                try{
                    String aPIResponse = JSON.serialize(CPQ_PM_ApiCalllout.getProductDetails(productId));
                    productInformation.put(productId,aPIResponse);
                }
                catch(Exception e){

                    CPQ_ProductLaunchManagement__c removedItem = plmMap.remove(productId);
                    removedItem = new CPQ_PM_UtilityClass.productLaunchRecordBuilder(removedItem).setCreationStatus('Failure').setCreationMessage(e.getMessage()).getRecord();
                    updateList.add(removedItem);
                    CPQ_LogException.add(new CPQ_LogException(e, null).setShortMessage('CPQ_PMController: ' + productId + ' : Failed to get the data from the source').getErrorRecord());
                }
                
            
            }

            //Inserting the settings to database 
            //Database.upsert(productSettings.values());
            Insert plmMap.values();
            //TODO: this hardcoded record type needs to be addressed.
            RecordType parterRecordType = [SELECT id, DeveloperName, SobjectType 
                                        FROM RecordType
                                        WHERE DeveloperName = 'Partner_Products' AND SobjectType = 'Product2'
                                        WITH SECURITY_ENFORCED];


            for(String pId: productInformation.keySet()){
                
                try{
                    CPQ_PM_APIDataProcessor processedData = new CPQ_PM_APIDataProcessor(pId, parterRecordType.Id).generateProductData(productInformation.get(pId), productSettings.get(pId));
                    productAPIDetails.put(pId,processedData);
                    // collect all the optional product Ids from all the main products
                    optionalProductIds.addAll(processedData.optionalMktProdIds);
                    //removing the sub-product which has further configuration (e.g client reputation) will be removed As it has to be configured separately 
                    optionalProductIds.removeAll(processedData.parentSubProducts);
                }
                catch(CPQ_PM_APIDataProcessor.CPQ_PM_APIDataProcessorException e){
                    
                    CPQ_ProductLaunchManagement__c removedItem = plmMap.remove(pId);
                    removedItem = new CPQ_PM_UtilityClass.productLaunchRecordBuilder(removedItem)
                                        .setCreationStatus('Failure')
                                        .setCreationMessage(errorMessageHelper(e.getStatusCode(), e))
                                        .getRecord();
                    updateList.add(removedItem);
                    CPQ_LogException.add(new CPQ_LogException(e, e.getStatusCode()).setShortMessage('CPQ_PMController[' + new CPQ_CustomException().getLineNumber() + ']:' + pId + ' : Failed to process the data').getErrorRecord());
                }
                
            }

            productPresenceCheck(CPQ_PM_APIDataProcessor.optionalProductMap);
            // System.debug('productPresenceStatus ==>' + productPresenceStatus);

            for(String productCode: productAPIDetails.keySet()){
                System.enqueueJob(new CPQ_AsyncProductClone(productCode, productAPIDetails.get(productCode), plmMap.get(productCode))); 
            }
            

        } catch (Exception e) {

            for(String item:plmMap.KeySet()){
                CPQ_ProductLaunchManagement__c temp = plmMap.get(item);
                temp = new CPQ_PM_UtilityClass.productLaunchRecordBuilder(temp).setCreationStatus('Failure').setCreationMessage(e.getMessage()).getRecord();
                updateList.add(temp);
            }

            CPQ_LogException.add(new CPQ_LogException(e, null).setShortMessage('CPQ_PMController: product creation process failed').getErrorRecord());
            

        }
        finally{

            // update the launch management settings
            if(updateList.size() > 0){
                Database.upsert(updateList);
            }
            CPQ_LogException.flush();
            CPQ_LogException.clear();
            
        }

        return true;
    }
    
    private static Boolean productPresenceCheck(Map<String, product2> optionalIds){

        List<product2> optionalProducts = [SELECT Id, Name, productCode FROM Product2 WHERE productCode IN :optionalIds.keySet()];
        List<Id> productIds = new List<Id>();

        for(product2 item: optionalProducts){
            optionalIds.remove(item.ProductCode);
        }

        if(optionalIds.isEmpty()){
            return true;
        }

        Database.SaveResult[] products = Database.insert(optionalIds.values(), false);

        for (Database.SaveResult sr : products) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                productIds.add(sr.getId());
            }
        }

        addPriceBookEntries(productIds);
        return true;
    }

    // This need to be removed from here while deploying 
    public static CPQ_ProductLaunchManagement__c getRecordWithDefaultValues(Id launchId, String productCode){

        CPQ_ProductLaunchManagement__c returnRecord =  new CPQ_ProductLaunchManagement__c();

        returnRecord.Name = productCode;
        returnRecord.Launch__c = launchId;
        returnRecord.Product_Creation_Status__c = 'In Progress';
        returnRecord.Product_Launch_Status__c = 'Draft';

         return returnRecord;
    }

    private static string errorMessageHelper(CPQ_CustomException.StatusCode sc, Exception e){

        switch on sc {
            when  PAC_ERROR {
                return System.Label.CPQ_Error_message_for_PAC_error;
            }
            when else {
                return e.getMessage();
            }
        }
    }

    @future
    private static void addPriceBookEntries(List<Id> productIds){


        List<PricebookEntry> newPriceEntries = new List<PricebookEntry>();

        Id stdPricebookId = [SELECT Id FROM Pricebook2
                             WHERE Name = 'Standard Price Book'
                             AND IsActive = true LIMIT 1]?.Id;
        
        //get the list of applicable currencies
        List<CurrencyType> currenciesTypes = [SELECT IsoCode
                                            FROM CurrencyType
                                            WHERE IsActive = true];
        for(Id prodId: productIds){
            for(CurrencyType item: currenciesTypes){
                PricebookEntry temp = new PricebookEntry();
                temp.Pricebook2Id = stdPricebookId;
                temp.Product2Id = prodId;
                temp.CurrencyIsoCode = item.IsoCode;
                temp.IsActive = true;
                temp.UnitPrice = 0.0;
                newPriceEntries.add(temp);
            }
        }

        Database.insert(newPriceEntries, false);
            
    }

}