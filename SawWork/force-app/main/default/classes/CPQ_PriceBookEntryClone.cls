public with sharing class CPQ_PriceBookEntryClone extends CPQ_SobjectClone{
    
    private Id sourceProductId;
    private Id newProductId;

    public CPQ_PriceBookEntryClone(Id sourceProductId, Id newProductId) {
        Super('PriceBookEntry');
        this.sourceProductId = sourceProductId;
        this.newProductId = newProductId;

    }

    public override List<Sobject> beforeClone(){

        List<SObject> clonedRecords = new List<Sobject>();
        List<SObject> parentRecords = new List<Sobject>();
        
        if(sourceProductId != null){

            String parentQuery =
            ' SELECT ' +
            String.join( parentFieldNames, ',' ) +
            ' FROM ' +
            sObjectType +
            ' WHERE ' +
            ' Product2Id = :sourceProductId ' +
            ' AND IsActive = true ' +
            ' LIMIT 10000 '
            ;
    
            parentRecords = Database.Query( parentQuery );
    
            for(Integer i = 0; i < parentRecords.size(); i++){
                clonedRecords.add(parentRecords[i].clone(false, true));
            }

        }
        else{

            Id stdPricebookId = [SELECT Id FROM Pricebook2
                             WHERE Name = 'Standard Price Book'
                             AND IsActive = true LIMIT 1]?.Id;
        
            //get the list of applicable currencies
            List<CurrencyType> currenciesTypes = [SELECT IsoCode
                                                FROM CurrencyType
                                                WHERE IsActive = true];

            clonedRecords = createStandardPrices(stdPricebookId, currenciesTypes);
            
        }
       
        for(Integer i = 0; i < clonedRecords.size(); i++){
            clonedRecords[i].put('Product2Id', this.newProductId);
        }
        
        return clonedRecords;
    }

    public override List<SObject> afterClone(List<Sobject> clonedRecords){
        return clonedRecords;
    }

    private List<SObject> createStandardPrices(Id stdPricebookId, List<CurrencyType> currenciesTypes){

        List<SObject> returnList = new List<SObject>();

        for(CurrencyType item: currenciesTypes){
            PricebookEntry temp = new PricebookEntry();
            temp.Pricebook2Id = stdPricebookId;
            temp.Product2Id = this.newProductId;
            temp.CurrencyIsoCode = item.IsoCode;
            temp.IsActive = true;
            temp.UnitPrice = 0.0;
            returnList.add((Sobject)temp);
        }

        return returnList;
    }
}