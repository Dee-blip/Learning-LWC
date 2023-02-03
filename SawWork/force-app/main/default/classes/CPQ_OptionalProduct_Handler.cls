/**
* Test Class: CPQ_Test_CPQ_Create_Products
*/
public with sharing class CPQ_OptionalProduct_Handler {
    public static Boolean productPresenceCheck(Map<String, product2> optionalIds,Map<String,String> productPricingMap,String typeofProduct){

        
        
        if(typeOfProduct == 'Partner'){
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
            
            addPriceBookEntries(productIds,productPricingMap);
        }
        else
        {
             
            List<Id> productIdsSet = new List<Id>();
            List<product2> carrierOptionalProducts = [SELECT Id, Name, productCode,Product_Notes__c FROM Product2 WHERE Product_Notes__c IN :optionalIds.keySet()];
            
            for(product2 item: carrierOptionalProducts){
                productIdsSet.add(item.id);
                optionalIds.remove(item.Product_Notes__c);
            }
            //If the This price definition already exists in this price book
            List<PricebookEntry> pricebooklist = [Select id FROM PricebookEntry WHERE Product2Id =: productIdsSet];
            CPQ_LogException.logInformation('pricebooklist: '+pricebooklist);
            if(!pricebooklist.isEmpty()){
               Database.delete(pricebooklist,false);
                 
            }
            if(optionalIds.isEmpty()){
                addPriceBookEntries(productIdsSet,productPricingMap);
                return true;
            }
            
            List<Id> carrierProductIds = new List<Id>();
            Database.SaveResult[] carrierProducts = Database.insert(optionalIds.values(), false);
            
            for(Database.SaveResult sr : carrierProducts) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                carrierProductIds.add(sr.getId());


            }
        }
        addPriceBookEntries(carrierProductIds,productPricingMap);
        updateProduct(carrierProductIds);
        }

        
        return true;
    }
    public static void updateProduct(List<Id> productIds)
    {   
        Map<String,Id> discountSchdeulesMap = new Map<String,Id>();
        
        List<SBQQ__DiscountSchedule__c> dslist = [SELECT Id, Name FROM SBQQ__DiscountSchedule__c LIMIT 10000];
        for(SBQQ__DiscountSchedule__c ds : dslist){
            discountSchdeulesMap.put(ds.name,ds.id);
        }
        
        List<Product2> updateProdlist = new List<Product2>();
        List<Product2> productIdlist = [SELECT Id, Name,SBQQ__DiscountSchedule__c,Product_Notes__c  FROM Product2 where Id=:productIds];
        for(Product2 prod : productIdlist){
            prod.SBQQ__DiscountSchedule__c = discountSchdeulesMap.get(prod.Product_Notes__c.right(80).trim())!=null?discountSchdeulesMap.get(prod.Product_Notes__c.right(80).trim()):null;
            updateProdlist.add(prod);
        }
           if(!updateProdlist.isEmpty()){
            Database.update(updateProdlist, false);
           }

            
    }
    @future
    public static void addPriceBookEntries(List<Id> productIds,Map<String,String> productPricingMap){


        Map<String,Id> productMap = new Map<String,Id>();
        
        List<Product2> productIdlist = [SELECT Id, Name, productCode,Product_Notes__c FROM Product2 where Id=:productIds];
        for(Product2 prod : productIdlist){
            productMap.put(prod.Product_Notes__c,prod.id);
           }

        List<PricebookEntry> newPriceEntries = new List<PricebookEntry>();

        Id stdPricebookId = [SELECT Id FROM Pricebook2
                             WHERE Name = 'Standard Price Book'
                             AND IsActive = true LIMIT 1]?.Id;
        
        //get the list of applicable currencies
        List<CurrencyType> currenciesTypes = [SELECT IsoCode
                                            FROM CurrencyType
                                            WHERE IsActive = true];

        Set<String> isocodeSet = new Set<String>();
 
         for(CurrencyType item: currenciesTypes){
         isocodeSet.add(item.IsoCode);
         }
        
        for(String prodName: productMap.keySet()){
            for(String item: isocodeSet){
                PricebookEntry temp = new PricebookEntry();
                temp.Pricebook2Id = stdPricebookId;
                temp.Product2Id = productMap.get(prodName);
                temp.CurrencyIsoCode = item;
                temp.IsActive = true;
                if(productPricingMap.get(item+'_'+prodName)!=null && productPricingMap.get(item+'_'+prodName)!='-1'){
                    temp.UnitPrice = Decimal.valueOf(productPricingMap.get(item+'_'+prodName));
                }
                else{
                    temp.UnitPrice =0.0;
                }
                newPriceEntries.add(temp);
                
            }
        }

        Database.SaveResult[] priceBookIds =Database.insert(newPriceEntries,false);
        CPQ_LogException.logInformation('priceBookIds: '+priceBookIds);
            
    }
}