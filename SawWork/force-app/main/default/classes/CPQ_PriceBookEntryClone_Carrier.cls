public with sharing class CPQ_PriceBookEntryClone_Carrier extends CPQ_SobjectClone{
    private Id sourceProductId;
    private Id newProductId;
    private Map<String,String> commitPriceMap;
    
    public CPQ_PriceBookEntryClone_Carrier(Id sourceProductId, Id newProductId,Map<String,String> commitPriceMap) {
        Super('PriceBookEntry');
        this.sourceProductId = sourceProductId;
        this.newProductId = newProductId;
        this.commitPriceMap = commitPriceMap;
    }
    public override List<Sobject> beforeClone(){

        List<SObject> clonedRecords = new List<Sobject>();
        List<String> isocodeSet = new List<String>();

        Id stdPricebookId = [SELECT Id FROM Pricebook2
                             WHERE Name = 'Standard Price Book'
                             AND IsActive = true LIMIT 1]?.Id;
        
            //get the list of applicable currencies
        List<CurrencyType> currenciesTypes = [SELECT IsoCode
                                                FROM CurrencyType
                                                WHERE IsActive = true];
        for(CurrencyType item: currenciesTypes){
            isocodeSet.add(item.IsoCode);
        }

        clonedRecords = createStandardPrices(stdPricebookId, isocodeSet);
            
       
       
        for(Integer i = 0; i < clonedRecords.size(); i++){
            clonedRecords[i].put('Product2Id', this.newProductId);
        }
        
        return clonedRecords;
    }

    public override List<SObject> afterClone(List<Sobject> clonedRecords){
        return clonedRecords;
    }

    private List<SObject> createStandardPrices(Id stdPricebookId, List<String> isocodeSet){

        List<SObject> returnList = new List<SObject>();
        Map<String,Id> productMap = new Map<String,Id>();
        
        List<Product2> productIdlist = [SELECT Id, Name, productCode,Product_Notes__c FROM Product2 where Id=:this.newProductId];
        for(Product2 prod : productIdlist)
        {
            productMap.put(prod.Product_Notes__c,prod.id);
        }

        for(String item: isocodeSet){
            PricebookEntry temp = new PricebookEntry();
            temp.Pricebook2Id = stdPricebookId;
            temp.Product2Id = this.newProductId;
            temp.CurrencyIsoCode = item;
            temp.IsActive = true;
            if(commitPriceMap.get(item)!=null){
                temp.UnitPrice = Decimal.valueOf(commitPriceMap.get(item));
                
            }
            else{
                temp.UnitPrice =0.0;
            }
            
            returnList.add((Sobject)temp);
        }

        return returnList;
    }
}