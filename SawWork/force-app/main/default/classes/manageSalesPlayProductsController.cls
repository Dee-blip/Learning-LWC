public class manageSalesPlayProductsController {

    public static Boolean deleteOpportunitySalesPlayFirstRunFlag=true;

    public void manageSalesPlayProductsCompSetUp() {
        Id salesPlayId;
        salesPlayId = ApexPages.currentPage().getParameters().get('Id');
    }

    @AuraEnabled
    public static Map<String,String> fetchForecastingProducts(Id recId)
    { 
        Map<String,String> returnValMap = new Map<String,String>();
        Map<String,String> ProductNamesMap = new Map<String,String>();
        Map<String,String> selectedProductMap = new Map<String,String>();
        for( Product2 prodObj : [Select Id, Name 
                                 From Product2 WHERE isActive=true and 
                                 RecordType.Name= 'Forecasting Products' ORDER BY Name DESC]) {
            ProductNamesMap.put(String.valueOf(prodObj.Id).substring(0, 15),prodObj.Name);                                
        }
        Sales_Play__c salesPlayRec = [Select Product_Id__c  from Sales_Play__c where Id = :recId];
        if(salesPlayRec.Product_Id__c != null && salesPlayRec.Product_Id__c != '') {
            for(String prdId : salesPlayRec.Product_Id__c.split(',')) {
                selectedProductMap.put(prdId,ProductNamesMap.get(prdId));           
            }
        }
        system.debug('ProductNamesMap = '+ProductNamesMap);
        returnValMap.put('ProductNamesMap', JSON.serialize(ProductNamesMap));
        returnValMap.put('SelectedProdcuts', JSON.serialize(selectedProductMap));
        return returnValMap;
    }

    @AuraEnabled
    public static String saveForecastingProducts(Id salesPlayId, 
                                                 Map<String,String> productNameMap, 
                                                 List<String> prodIds) {
        String successMessage = 'success';
        List<String> prodNames = new List<String>();
        Sales_Play__c salesPlayRec;
        List<String> truncProdIds = new List<String>();
        for(String pId : prodIds) {
            prodNames.add(productNameMap.get(pId));
        }
        salesPlayRec = [Select Id,Product_Id__c, Relevant_Products__c, (select Id, Account__c from Account_Sales_Play_Associations__r), (select Id,Opportunity__c from Opportunity_Sales_Play_Associations__r) from Sales_Play__c 
                        where Id = :salesPlayId];
        
        List<String> existingProducts = new List<String>();
        List<String> removedProducts = new List<String>();
        List<Opportunity_Sales_Play_Association__c> ospaDeleteList = new List<Opportunity_Sales_Play_Association__c>();
        List<String> newProducts = new List<String>();

        salesPlayRec.Relevant_Products__c = string.join(prodNames,', ');
        for(String pId : prodIds) {
            truncProdIds.add(String.valueOf(pId).substring(0, 15));
        }

        if(salesPlayRec.Product_Id__c != '' && salesPlayRec.Product_Id__c != null)
            existingProducts = salesPlayRec.Product_Id__c.split(',');
        
        for(String existingProduct : existingProducts){
            if(!truncProdIds.contains(existingProduct)){
                removedProducts.add(existingProduct);
            }
        }
        for(String newProduct : truncProdIds){
            if(!existingProducts.contains(newProduct)){
                newProducts.add(newProduct);
            }
        }

        salesPlayRec.Product_Id__c = string.join(truncProdIds,',');

        if(removedProducts.size() > 0)
        {
            Map<String, Opportunity_Sales_Play_Association__c> oppIdToOSPA = new Map<String, Opportunity_Sales_Play_Association__c>();
            for(Opportunity_Sales_Play_Association__c ospa : salesPlayRec.Opportunity_Sales_Play_Associations__r){
                oppIdToOSPA.put(ospa.Opportunity__c, ospa);
            }
            if(oppIdToOSPA.size() > 0){
                Boolean yesDelete;
                for(Opportunity op : [Select Id, (Select Id, Product2Id__c from OpportunityLineItems) from Opportunity where Id IN : oppIdToOSPA.keySet()]){
                    yesDelete = false;
                    for(OpportunityLineItem oli : op.OpportunityLineItems){
                        if(!truncProdIds.contains(oli.Product2Id__c)){
                            yesDelete = true;
                        }else{
                            yesDelete = false;
                            break;
                        }
                    }
                    if(yesDelete){
                        ospaDeleteList.add(oppIdToOSPA.get(op.Id));
                    }
                }
            }
        }

        try {
            database.update(salesPlayRec);
            if(newProducts.size() > 0)
            {
                Set<Id> accountIds = new Set<Id>();
                for(Account_Sales_Play_Association__c aspa : salesPlayRec.Account_Sales_Play_Associations__r){
                    accountIds.add(aspa.Account__c);
                }
                AccSalesPlayAssociationTriggerClass.insertOSPARecords(salesPlayRec.Account_Sales_Play_Associations__r,new Set<Id>{salesPlayId}, accountIds);
            }
            if(ospaDeleteList.size() > 0){
                Database.delete(ospaDeleteList);
            }
        }
        catch (exception e) {
            successMessage = e.getmessage();
        }

        return successMessage;
    }

    public static void deleteOpportunitySalesPlay(Set<Id> oppIdSet){
        if(!deleteOpportunitySalesPlayFirstRunFlag)
            return;
        List<Opportunity_Sales_Play_Association__c> ospaDeleteList = new List<Opportunity_Sales_Play_Association__c>();
        List<String> salesPlayProducts;
        String productString;
        Boolean yesDelete;
        for(Opportunity op : [Select Id, (Select Id, Product2Id__c from OpportunityLineItems), (Select Id, Sales_Play__r.Product_Id__c from Opportunity_Sales_Play_Associations__r) from Opportunity where Id IN : oppIdSet]){
            for(Opportunity_Sales_Play_Association__c ospa : op.Opportunity_Sales_Play_Associations__r){
                salesPlayProducts = new List<String>();
                productString = '';
                yesDelete = false;
                productString = ospa.Sales_Play__r.Product_Id__c;
                if(productString != '' && productString != null)
                    salesPlayProducts = productString.split(',');
                if(salesPlayProducts.size() > 0){
                    for(OpportunityLineItem oli : op.OpportunityLineItems){
                        if(!salesPlayProducts.contains(oli.Product2Id__c)){
                            yesDelete = true;
                        }else{
                            yesDelete = false;
                            break;
                        }
                    }
                    if(yesDelete || op.OpportunityLineItems.size()==0){
                        ospaDeleteList.add(ospa);
                    }
                }
            }
        }
        if(ospaDeleteList.size() > 0){
            Database.delete(ospaDeleteList);
        }
        deleteOpportunitySalesPlayFirstRunFlag = false;
    }
}