/**
 * @created By : Aayushi Agrawal
 * @description       : This class is used to Products creation , updation and deletion.
 * @author            : apyati
 * @group             : 
 * @last modified on  : 09-08-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-22-2021   apyati   Initial Version
**/
public without sharing class l2qManageProductController {
    public static Map<String,String> mapOfProduct = new  Map<String,String>();

    /**
    * @Method Name : getRenewalContractProducts
    * @parameters : oppID, this will have opportunity id
    * @purpose : This method will be called on manage products load in order to get renewal contract products
    */
    @AuraEnabled
    public static List<OpportunityLineItem> getOpportunityProductsWithContracts(String oppId){
        try{
            return [SELECT Product2.Id,Product2.Name, Id, Average_Renewal_Commit_MRR__c , Projected_Monthly_commit_fees__c,MRR__c,
            Specialist_Net_MRR__c,Average_Renewal_Usage_MRR__c,Projected_Avg_Rev_Non_Commit__c,Net_Non_Commit__c,
            NRR__c,Term__c,Opportunity.CurrencyIsoCode,Specialist_Projected_Monthly_Commit__c,
            Specialist_Forecast_Category__c,Specialist_Close_Date__c,Specialist_Touched__c,Specialist_NRR_Touched__c,
            Specialist_Forecast_Touched__c,Specialist_Usage_Touched__c,Specialist_Close_Date_Touched__c, Specialist_NRR__c,Emri__c,
            CurrencyIsoCode,
            (SELECT Contract_Product__c
            FROM Associated_Contract_Products__r)
            from OpportunityLineItem WHERE OpportunityId =: oppId];
       
           } catch (Exception e) {
                 Sawyer.saw(e);
                 AuraHandledException ex = new  AuraHandledException(e.getMessage());
                 ex.setMessage(e.getMessage());
                 throw ex;
           }
           
    }//end of getRenewalContractProducts method


    /**
     * @Method Name : getPriceBookEntry
     * @created by : Aayushi Agrawal
     * @parameters :
     * @param1 : productList, this will hold list of product ids
     * @param2 : currencyIsoCode, Opportunity currency
     * @purpose : This method will get associated active price book entry on product
     */
    public static Map<String,String> getPriceBookEntry( List<String> productList , String currencyIsoCode){
        try {
            Map<String,String> resultMap = new Map<String,String>();
            
            for(Product2 prod : [Select id, Name,AKAM_Product_ID__c,(select id from pricebookentries where CurrencyIsoCode=:currencyIsoCode and IsActive=true ) From Product2 WHERE id in : productList])
            {
                if(prod.pricebookentries != null && prod.pricebookentries.size() >0){
                    resultMap.put(prod.id , prod.pricebookentries[0].id);
                    mapOfProduct.put(prod.pricebookentries[0].id,prod.AKAM_Product_ID__c);
                }
                
            }
            return resultMap;
            
        } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }//end of getPriceBookEntry
    
    /**
     * @Method Name : saveProductHandler
     * @created by : Aayushi Agrawal
     * @parameters :
     * @param1 :payload , this will hold list of products in json string format
     * @purpose :Perform DML operation on products
     */
    @AuraEnabled
    public static void saveProductHandler(String payload){
        try {
            //convert payload in wrapper list
            List<OpportunityProductWrapper> payloadObject = (List<OpportunityProductWrapper>) JSON.deserialize(payload, List<OpportunityProductWrapper>.class); //convert payload in search paramters
            doDmlOnOpportunityLineItems(payloadObject); // perform dmls
          } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
          } //end of catch
    }//end of saveProductHandler\

     /**
     * @Method Name : saveProductHandler
     * @created by : Aayushi Agrawal
     * @parameters :
     * @param1 :payload , this will hold list of products in json string format
     * @purpose :Perform DML operation on products
     */
    @AuraEnabled
    public static void saveOpptyAndProductHandler(String oppty, String opptyProducts){
        try {

            if(oppty != null && oppty !=''){
            Opportunity opptyObject = (Opportunity) JSON.deserialize(oppty, Opportunity.class);// convert fields to opptyObject
            update opptyObject; 
            }
            if(opptyProducts != null && opptyProducts !=''){
                //convert payload in wrapper list
            List<OpportunityProductWrapper> payloadObject = (List<OpportunityProductWrapper>) JSON.deserialize(opptyProducts, List<OpportunityProductWrapper>.class); //convert payload in search paramters
            doDmlOnOpportunityLineItems(payloadObject); // perform dmls'
            }
          } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
          } //end of catch
    }//end of saveProductHandler
    /**
     * @Method Name : insertOpportunity
     * @created by : Aayushi Agrawal
     * @parameters :
     * @param1 :payload , this will OpportunityWrapper in string format
     * @purpose :Update given fields on opportunity
     */ //
    @AuraEnabled
    public static void insertOpportunity(String payload){ // Todo : update ---  uiapi , updateRecord 
            try {
                Opportunity opp = new Opportunity();
                List<OpportunityWrapper> payloadObject = (List<OpportunityWrapper>) JSON.deserialize(payload, List<OpportunityWrapper>.class); //convert payload in search paramters
                for(OpportunityWrapper oppWrap : payloadObject){
                    //put all the fields dynamically and their values too
                    opp.put(oppWrap.fieldApiName, removeNoneFromPicklist(oppWrap.fieldApiName , oppWrap.value));
                }
                update opp; //Todo : GSMUtils.doinsert
          } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
          } //end of catch
    }//end of insertOpportunity
    /**
     * @Method Name : save
     * @created by : Aayushi Agrawal
     * @parameters :
     * @param1 :oppDetail, this will OpportunityWrapper in string format
     * @param2 :OppLineItems,this will hold OpportunityProductWrapper in string format
     * @purpose :Update given fields on opportunity
     */
    @AuraEnabled
    public static void save(String oppDetail , String OppLineItems){
        try {
            insertOpportunity(oppDetail);
            saveProductHandler(OppLineItems);
            
        } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }//end of catch
    }//end of save method
    /**
     * @Class Name : OpportunityProductWrapper
     * @created by : Aayushi Agrawal
     * @purpose :This class is used to map Opportunity line item fields from UI to backend
     */
    public class OpportunityProductWrapper{
        public String Name;
        public String SFid;
        public String ProductId;
        public String Baseline_Mrr;
        public String Forecast_Mrr;
        public String Net_Mrr;
        public String Specialist_Net_Mrr;
        public String Baseline_Usage;
        public String Forecast_Usage;
        public String Net_Usage;
        public String Onetime_Fee;
        public String Specialist_Onetime_Fee;
        public String Term;
        public String Specialist_Projected_Monthly_Commit;
        public String Specialist_Forecast_Category;
        public Date Specialist_Close_Date;
        public Boolean isNew;
        public Boolean isDelete;
        public String currencyOpp;
        public String oppId;
        public Boolean SpCommitTouched;
        public Boolean SpUsageTouched;
        public Boolean SpForecastTouched;
        public Boolean SpOneTimeFeeTouched;
        public Boolean SpCloseDateTouched;
        public String Emri;
        public Boolean isFromContractScreen;
        public List<ContractDetail> contractDetailObj; // this will hold list of asscociated contracts on oli
        
    }//end of class OpportunityProductWrapper
     /**
     * @Class Name : ContractDetail
     * @created by : Aayushi Agrawal
     * @purpose :This class is used to map contract asscociation on oli records
     */
    public class ContractDetail{
        public String ContractId;
        public String Name;
        public String CurrencyIsoCode;
        public Date EffectiveStartDat;
        public Date EffectiveEndDate;
        public String AutoRenew;
        public String ParentContract;
        public String OrderId;
        public String ContractType;
        public String contractProductId;
    }//end of class ContractDetail
    /**
     * @Class Name : OpportunityWrapper
     * @created by : Aayushi Agrawal
     * @purpose :This class is used to map opportunity fields and their values
     */
    public class OpportunityWrapper{ 
        public String fieldApiName ;
        public String value;
    }//end of OpportunityWrapper
    /**
     * @Method Name : removeNoneFromPicklist
     * @created by : Aayushi Agrawal
     * @purpose :This method is used to replace none value from picklist to blank
     */
    public static String removeNoneFromPicklist(String fieldName ,String value){
        if(fieldName == 'Opportunity_Sub_Category' && value == '--None--')
         return '';
         if(fieldName == 'Opportunity_Category' && value == '--None--')
         return ''; 
         if(fieldName == 'Aggregation_Partner' && value == '--None--')
         return '';
         if(fieldName == 'Competitor' && value == '--None--')
         return '';
         if(fieldName == 'Loss_Reason' && value == '--None--')
         return '';
         if(fieldName == 'Opportunity_Type' && value == '--None--')
         return '';
         if(fieldName == 'Zoff_Status' && value == '--None--')  
         return '';
         return value;
    }//end of removeNoneFromPicklist
     /**
     * @Method Name : doDmlOnOpportunityLineItems
     * @created by : Aayushi Agrawal
     * @param1 : list of OpportunityProductWrapper
     * @purpose :This method will perform dml operation on opportunity line item object
     */
    public static void doDmlOnOpportunityLineItems(List<OpportunityProductWrapper> oliList){
        try{
            List<OpportunityLineItem> deleteOliList = new List<OpportunityLineItem>(); // this list will hold olis to be deleted
            String currencyOpp ; // this will hold opportunity currency
            String oppId; // opportunity id
            List<String> productIdList = new List<String>(); // this list is used to query price book entry
            Set<Id> processedContracts = new  Set<Id>(); // to avoid duplicate contracts
            Map<Integer , List<ContractDetail>> mapOfSequenceToContractDetail = new Map<Integer , List<ContractDetail>>();
            Map<Integer,OpportunityLineItem> mapOfSeqToOli = new Map<Integer,OpportunityLineItem>();
            Map<Id, ContractDetail> MapOfContractIdToDetail = new Map<Id, ContractDetail>();
            for(OpportunityProductWrapper oli : oliList){
                if(oli.isDelete == false ){
                    productIdList.add(oli.ProductId);
                    currencyOpp = oli.currencyOpp;
                }//end of if
            }//end of  for(OpportunityProductWrapper oli : oliList)    
            Map<String,String> productIdToPriceBook = new Map<String,String>();
            Set<String> deleteChildRenewalContracts = new Set<String>();
            if(productIdList.size () > 0){ // query on price book entry only when there is product to be inserted
                productIdToPriceBook = getPriceBookEntry(productIdList , currencyOpp);
            }//end of  if(productIdList.size () > 0)
            integer sequence = 0;
            for(OpportunityProductWrapper oli : oliList){
                oppId = oli.oppId;
                   
                //insert or update case
                if(oli.isDelete == false){  // update or insert
                    OpportunityLineItem oppLineItem = new OpportunityLineItem();
                    if(oli.SFid  != null){ // case of update
                        oppLineItem.id = oli.SFid; 
                        
                    }else{ // case of insert
                        if( productIdToPriceBook.get(oli.ProductId) != null){
                            oppLineItem.PriceBookEntryId = productIdToPriceBook.get(oli.ProductId);
                            oppLineItem.OpportunityId= oli.oppId;
                        }else{
                            continue;
                        }
                    
                    }
                    populateFieldsOnOli(oppLineItem,oli,oppId);//this method call will update all fields on opplineitem
                    mapOfSeqToOli.put(sequence , oppLineItem);
                    if(oli.isFromContractScreen == true && oli.SFid!= null){
                        deleteChildRenewalContracts.add(oli.SFid);
                    }
                    if(oli.contractDetailObj.size() > 0){
                        mapOfSequenceToContractDetail.put(sequence ,oli.contractDetailObj);
                        //prepare a list of contract ids to insert
                        for(ContractDetail contract : oli.contractDetailObj){
                            if(processedContracts.contains(contract.ContractId)) continue; // using processedContracts set to avoid duplicate record creation
                            processedContracts.add(contract.ContractId);
                            MapOfContractIdToDetail.put(contract.ContractId , contract);
                        }
                        
                    }  
                    sequence++;

                }
                //delete case
                if(oli.isDelete == true && oli.SFid != null){
                    deleteOliList.add(new OpportunityLineItem(id =  oli.SFid ));
                }
            }//end of for loop
            deleteOliAndRelateContracts(deleteOliList,oppId);   
            //SFDC-9427 Reset the first run flag to complete Opportunity update
            OpportunityUtilClass.updateOpportunityOpptyLineItemAfterInsertUpdate = true;
            upsertOliAndRelatedContracts(processedContracts,mapOfSeqToOli ,MapOfContractIdToDetail,oppId, mapOfSequenceToContractDetail,deleteChildRenewalContracts);
            cleanupEmptyContracts(oppId);
            
        } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
          } //end of catch
    }//end of doDmlOnOpportunityLineItems 
    /**
     * @Method Name : getForecastCategory
     * @created by : Aayushi Agrawal
     * @purpose : To Load forecast category picklist values 
     */
    @AuraEnabled(cacheable = true)
    public static List<String> getForecastCategory(){
        try {
            List<String> forecastCategoryList = new List<String>();
            String objectName = 'OpportunityLineItem';
            String fieldName ='Specialist_Forecast_Category__c';
            Schema.SObjectType s = Schema.getGlobalDescribe().get(objectName) ;
            Schema.DescribeSObjectResult r = s.getDescribe() ;
            Map<String,Schema.SObjectField> fields = r.fields.getMap() ;
            Schema.DescribeFieldResult fieldResult = fields.get(fieldName).getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            for( Schema.PicklistEntry pickListVal : ple){
                forecastCategoryList.add(pickListVal.getLabel());
            }    
            return forecastCategoryList;
        } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }//end of catch
    }//end of getForecastCategory
    /**
     * @Method Name : populateFieldsOnOli
     * @created by : Aayushi Agrawal
     * @purpose : Map fields on Opportunity Line Item with the values from UI 
     */
    private static void populateFieldsOnOli(OpportunityLineItem oppLineItem,OpportunityProductWrapper oli, String oppId){
        oppLineItem.Quantity = 1;
        oppLineItem.Quantity__c=1;
        oppLineItem.Average_Renewal_Commit_MRR__c =  oli.Baseline_Mrr != null ? Decimal.valueOf(oli.Baseline_Mrr): null;
        oppLineItem.Projected_Monthly_commit_fees__c =  oli.Forecast_Mrr != null ?Decimal.valueOf(oli.Forecast_Mrr) : null;
        oppLineItem.MRR__c = oli.Net_Mrr != null ? Decimal.valueOf(oli.Net_Mrr): null;
        oppLineItem.unitprice = oli.Net_Mrr != null ? Decimal.valueOf(oli.Net_Mrr): null;
        oppLineItem.Average_Renewal_Usage_MRR__c = oli.Baseline_Usage != null ? Decimal.valueOf(oli.Baseline_Usage): null;
        oppLineItem.Projected_Avg_Rev_Non_Commit__c = oli.Forecast_Usage != null ? Decimal.valueOf(oli.Forecast_Usage): null;
        oppLineItem.Net_Non_Commit__c = oli.Net_Usage != null ? Decimal.valueOf(oli.Net_Usage): null;
        oppLineItem.NRR__c = oli.Onetime_Fee != null ? Decimal.valueOf(oli.Onetime_Fee): null;
        oppLineItem.Term__c = oli.Term != null ? Decimal.valueOf(oli.Term): null;
        oppLineItem.Specialist_Projected_Monthly_Commit__c = oli.Specialist_Projected_Monthly_Commit != null ? Decimal.valueOf(oli.Specialist_Projected_Monthly_Commit): null;
        oppLineItem.Specialist_Forecast_Category__c = oli.Specialist_Forecast_Category;
        oppLineItem.Specialist_Close_Date__c = oli.Specialist_Close_Date;
        oppLineItem.Specialist_NRR_Touched__c = oli.SpOneTimeFeeTouched;
        oppLineItem.Specialist_Usage_Touched__c = oli.SpUsageTouched;
        oppLineItem.Specialist_Forecast_Touched__c = oli.SpForecastTouched;
        oppLineItem.Specialist_Close_Date_Touched__c = oli.SpCloseDateTouched;
        oppLineItem.Specialist_Touched__c = oli.SpCommitTouched;
        oppLineItem.Specialist_Nrr__c = oli.Specialist_Onetime_Fee != null ? Decimal.valueOf(oli.Specialist_Onetime_Fee): null;
       
        oppLineItem.Emri__c = oli.Emri != null ? Decimal.valueOf(oli.Emri): null;

    }//end of populateFieldsOnOli
     /**
     * @Method Name : createRenewalContractRecord
     * @created by : Aayushi Agrawal
     * @purpose : create an insttance of Renewal_Contract_Object__c
     */
    private static Renewal_Contract_Object__c createRenewalContractRecord(ContractDetail contract, String oppId){
        Renewal_Contract_Object__c renewalContract    = new Renewal_Contract_Object__c();
        renewalContract.Name              = contract.Name;
        renewalContract.Contract__c           = contract.ContractId;
        renewalContract.Opportunity__c                = oppId;
        renewalContract.Contract_Id_Text__c       = contract.ContractId;//not available OriginalContractId
        renewalContract.Contract_Effective_End_Date__c  = contract.EffectiveEndDate;
        renewalContract.Parent_Contract__c        = contract.ParentContract; // 
        renewalContract.Order_Id__c           = contract.OrderId;
        renewalContract.Contract_Type__c = contract.ContractType;
        return renewalContract;
    }//end of createRenewalContractRecord

    /**
     * @Method Name : getForecastProducts
     * @created by : Ambica Pyati
     * @purpose :To get all forecast products availble to add in opportunity manage products    
     **/
       @AuraEnabled(cacheable=true)
       public static Map<String,List<Product2>>  getForecastProducts(){
           Map<String,List<Product2>> mapFamilyProducts = new Map<String,List<Product2>>();
           try {
               //get the recordtype Id
               Id forecastProductRecType = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Forecasting Products').getRecordTypeId();
               //group product by forcast group
               for(Product2 prod : [Select Id,Name,Family,AKAM_Product_ID__c from Product2 where isActive=true and RecordTypeId = :ForecastProductRecType]){
                   if(mapFamilyProducts.containskey(prod.Family)){
                       mapFamilyProducts.get(prod.Family).add(prod);
                   }else{
                       
                       mapFamilyProducts.put(prod.Family, new List<Product2>{prod});
                   }
               }    
           } catch (Exception e) {
               Sawyer.saw(e);
               AuraHandledException ex = new  AuraHandledException(e.getMessage());
               ex.setMessage(e.getMessage());
               throw ex;
           }
           return mapFamilyProducts;
       }
      //end of getForecastProducts


          /**
     * @Method Name : getProduct2Records
     * @created by : Ambica Pyati
     * @purpose :To get product2 records for the contarct products   
     **/
    @AuraEnabled(cacheable=true)
    public static Map<String,Product2>  getProduct2Records(Id accountId){
        Map<String,Product2> mapForecastIdProduct2 = new Map<String,Product2>();
        List<String> lstForecastProductIds = new List<String>();
        try{

            //get list of forcast product ids from contr
            for (Contract_Product__c conprod: [SELECT Forecast_Product_Id__c FROM Contract_Product__c  
                                                WHERE Deleted_From_Source__c =false  AND  Original_Contract_Id__r.Account_Name__c = :accountId AND Original_Contract_Id__r.Active__c = true 
                                                AND Effective_End_Date__c >= LAST_N_MONTHS:2 AND Original_Contract_Id__r.Contract_Product_Count__c > 0]){
                lstForecastProductIds.add(conprod.Forecast_Product_Id__c);
            }

            //get products by forcast id
            for(Product2 prod : [SELECT Id,Name,Family,AKAM_Product_ID__c FROM Product2 WHERE AKAM_Product_ID__c IN :lstForecastProductIds]){
                mapForecastIdProduct2.put(prod.AKAM_Product_ID__c,Prod);
            }   

        } catch (Exception e) {
            Sawyer.saw(e);
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
        return mapForecastIdProduct2;
    }
    //end of getProduct2Records

       //To get all opportunity products available to edit in Opportunity Manage Products
       @AuraEnabled(cacheable=true)
       public static List<OpportunityLineItem> getOpportunityProducts( String opportunityId){
           List<OpportunityLineItem> lstOpptyProducts = new List<OpportunityLineItem>();
           try {
               if (OpportunityLineItem.SObjectType.getDescribe().isAccessible()){
                   lstOpptyProducts= [Select Id, Product2Id, Product2.Name,ProductCode, UnitPrice, Quantity from OpportunityLineItem where OpportunityId = : OpportunityId];
               }
           } catch (Exception e) {
                Sawyer.saw(e);
                AuraHandledException ex = new  AuraHandledException(e.getMessage());
                ex.setMessage(e.getMessage());
                throw ex;
           }
           return lstOpptyProducts;
       }
   
         /**
     * @Method Name : getContractProducts
     * @created by : Ambica Pyati
     * @purpose :to get all contract products available to add/remove in Opportunity Manage Products
     **/
       @AuraEnabled(cacheable=true)
       public static Map<String,Map<String,List<Contract_Product__c>>> getContractProducts(Id accountId){
           Map<String,Map<String,List<Contract_Product__c>>> mapContractProducts= new map<String,Map<String,List<Contract_Product__c>>>();
           try { 
               List<Merge_Contract_Header__c> lstContract = [SELECT
                                                                   Id,Name,Currency__c,CurrencyIsoCode,Effective_Start_Date__c,Effective_End_Date__c,Original_Contract_Id__c,Auto_Renew__c,Parent_Account_Name__c,Parent_Contract__c,Order_Id__c,Contract_Type__c,
                                                                   (SELECT 
                                                                           Id,Name,UnitPrice__c,Forecast_Product_Id__c,Average_Renewal_Commit_MRR__c,Average_Renewal_Usage_MRR__c,Effective_Start_Date__c,Effective_End_Date__c
                                                                           FROM Contract_Products__r  WHERE Deleted_From_Source__c =false AND Effective_End_Date__c!= null AND Effective_End_Date__c >= LAST_N_MONTHS:2                                                                  
                                                                           )
                                                                   FROM Merge_Contract_Header__c
                                                                   WHERE  Account_Name__c =: accountId AND Active__c = true  AND Contract_Product_Count__c > 0
                                                               ];
   
               for(Merge_Contract_Header__c con : lstContract){
                   Map<String,List<Contract_Product__c>> mapEndProducts= new Map<String,List<Contract_Product__c>>();

                   for( Contract_Product__c conProd : con.Contract_Products__r){

                       //lstForecastProductIds.add(conProd.Forecast_Product_Id__c);
                       DateTime dt = conProd.Effective_End_Date__c;
                       //prepare format of endmonth
                       String endMonth = dt.format('MMM')+'\''+dt.year();

                        //Group Products by end months
                       if(mapEndProducts.containskey(EndMonth)){
                           mapEndProducts.get(EndMonth).add(conProd);
                       }
                       else{
                           List<Contract_Product__c> lstConProd = new List<Contract_Product__c>();
                           lstConProd.add(conProd);
                           mapEndProducts.put(EndMonth,lstConProd);
                       }
                       System.debug('mapEndProducts EndMonth'+mapEndProducts.get(EndMonth));
                   }

                   //group endmonth products by contract
                   if(mapEndProducts.keyset().size()>0){
                       mapContractProducts.put(JSON.serialize(con),mapEndProducts);
                   }

                   System.debug('mapContractProducts'+mapContractProducts);
   
               }
   
           } catch (Exception e) {
               Sawyer.saw(e);
               AuraHandledException ex = new  AuraHandledException(e.getMessage());
                ex.setMessage(e.getMessage());
                throw ex;
           }
   
           return mapContractProducts;
       }
       //end of getContractProducts

    /**
    * @Method Name : getRenewalContractProducts
    * @parameters : oppID, this will have opportunity id
    * @purpose : This method will be called on manage products load in order to get renewal contract products
    */
   /* @AuraEnabled
    public static Map<Id,List<String>> getRenewalContractProducts(String oppId){
        Map<Id,List<String>> oliIdToSelectedProducts = new  Map<Id,List<String>>();
               try{
                for(Renewal_Contract_Product__c rcp : [SELECT Id,Contract_Product__c,Opportunity_Product__c, Associated_Contract__c 
                                                       FROM Renewal_Contract_Product__c WHERE Opportunity_Product__r.OpportunityId = :oppId]){
                
                    if(!oliIdToSelectedProducts.containsKey(rcp.Opportunity_Product__c)){
                        oliIdToSelectedProducts.put(rcp.Opportunity_Product__c, new List<String>());
                   }
                   List<String> contractIds = oliIdToSelectedProducts.get(rcp.Opportunity_Product__c);
                   contractIds.add(rcp.Contract_Product__c);
                   oliIdToSelectedProducts.put(rcp.Opportunity_Product__c,contractIds );

                }
           } catch (Exception e) {
                 Sawyer.saw(e);
                 AuraHandledException ex = new  AuraHandledException(e.getMessage());
                 ex.setMessage(e.getMessage());
                 throw ex;
           }
           return oliIdToSelectedProducts;
    }//end of getRenewalContractProducts method */

    private static void deleteOliAndRelateContracts(List<OpportunityLineItem> deleteOliList,String oppId){
        try{
                //delete related Renewal_Contract_Product__c records in case of deletion of oli
                if(deleteOliList.size() > 0){ 
                    List<Renewal_Contract_Product__c> deleteList = [SELECT ID FROM Renewal_Contract_Product__c WHERE(
                        Opportunity_Product__c IN : deleteOliList)];
                    delete deleteList;  
                }//end of  if(deleteOliList.size() > 0)
                if(!deleteOliList.isEmpty()){
                    delete deleteOliList;//delete oli records
                }//end of  if(!deleteOliList.isEmpty())
                
            } catch (Exception e) {
                Sawyer.saw(e);
                AuraHandledException ex = new  AuraHandledException(e.getMessage());
                ex.setMessage(e.getMessage());
                throw ex;
             }
    }//end of deleteOliAndRelateContracts

    private static void upsertOliAndRelatedContracts(Set<ID> processedContracts,  Map<Integer,OpportunityLineItem> mapOfSeqToOli, 
    Map<Id, ContractDetail> MapOfContractIdToDetail ,String oppId,  Map<Integer , List<ContractDetail>> mapOfSequenceToContractDetail ,Set<String> deleteChildRenewalContracts){
        try{
            //delete existing junction object records for the records where update is happening todo
            if(deleteChildRenewalContracts.size() > 0){ 
                List<Renewal_Contract_Product__c> deleteList = [SELECT ID FROM Renewal_Contract_Product__c WHERE
                    Opportunity_Product__c IN : deleteChildRenewalContracts];
                delete deleteList;  
            }//end of  if(deleteOliList.size() > 0)
            Map<Id,Id> mapOfContractIdToAssociatedContract = new  Map<Id,Id>();
            List<Renewal_Contract_Object__c> associatedContractToInsert = new List<Renewal_Contract_Object__c>();
                
            if(processedContracts.size() > 0){
                System.debug('processedContracts-------'+processedContracts);
                //before creating contracts check if it already exist , if yes then asscociate junction object with it self else create new one
                List<Renewal_Contract_Object__c> existingCont = [SELECT Contract__c,ID FROM Renewal_Contract_Object__c WHERE Contract__c IN : processedContracts and Opportunity__c = : oppId]; 
                for(Renewal_Contract_Object__c con :existingCont ){
                    mapOfContractIdToAssociatedContract.put(con.Contract__c, con.Id);
                }
                for(String contId : processedContracts){
                    if(!mapOfContractIdToAssociatedContract.containsKey(contId)){
                        ContractDetail contract =  MapOfContractIdToDetail.get(contId);
                        associatedContractToInsert.add(createRenewalContractRecord(contract,oppId));
                    }
                }
                System.debug('mapOfContractIdToAssociatedContract-------'+mapOfContractIdToAssociatedContract);
                System.debug('associatedContractToInsert-------'+associatedContractToInsert);
            }//end of  if(processedContracts.size() > 0)
            // upsert oppline items               
            if(mapOfSeqToOli.keySet().size() > 0){
                    upsert(mapOfSeqToOli.values());
                    
                    if(!associatedContractToInsert.isEmpty()  ){
                        insert associatedContractToInsert; 
                        for(Renewal_Contract_Object__c asscoiatedCon : associatedContractToInsert){
                            mapOfContractIdToAssociatedContract.put(asscoiatedCon.Contract__c , asscoiatedCon.Id); // map contract id to mapOfContractIdToAssociatedContract
                        }
                    
                    }
                    //create Renewal_Contract_Product__c records
                    List<Renewal_Contract_Product__c> associatedContractProducts = new List<Renewal_Contract_Product__c>();
                    for(Integer seq : mapOfSeqToOli.keySet()){
                            if(mapOfSequenceToContractDetail.containsKey(seq)){
                                for(ContractDetail contract : mapOfSequenceToContractDetail.get(seq)){
                                    Renewal_Contract_Product__c renewalProduct = new Renewal_Contract_Product__c();
                                    renewalProduct.Associated_Contract__c =mapOfContractIdToAssociatedContract.get(contract.ContractId);
                                    renewalProduct.Opportunity_Product__c = mapOfSeqToOli.get(seq).Id;
                                    renewalProduct.Contract_Product__c = contract.contractProductId;
                                    renewalProduct.End_Month__c = contract.EffectiveEndDate != null ? contract.EffectiveEndDate.year()+'-'+contract.EffectiveEndDate.month() : null;
                                    renewalProduct.name = mapOfProduct.get(mapOfSeqToOli.get(seq).pricebookentryid);
                                    associatedContractProducts.add(renewalProduct); 
                                }  
                            }          
                    }    
                    if(!associatedContractProducts.isEmpty()){
                        insert associatedContractProducts;
                    }
            }
        } catch (Exception e) {
            Sawyer.saw(e);
            System.debug('Failure----'+e.getMessage());
            AuraHandledException ex = new AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());   
            System.debug('ex----'+ex)     ;
            throw ex;
        }    

    }
    @AuraEnabled(cacheable = true)
    public static User getUserInfo(){
        try {
            return [SELECT ID , Profile.Name FROM User WHERE ID =: UserInfo.getUserId()];
        } catch (Exception e) {
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }
    }

    @AuraEnabled(cacheable = true)
    public static boolean hasEditAccess(String recordId){
        boolean hasAccesss = false;
        try {
            UserRecordAccess ura =  [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: UserInfo.getUserId() AND RecordId =: recordId limit 1];
            if(ura != null){
                hasAccesss = ura.HasEditAccess;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return hasAccesss;
    }

    @AuraEnabled(cacheable = true)
    public static string getGSMSettingValue(String name){
        String value = '';
        try {
            if( name != null && name != '')
            value = GsmUtilClass.getGSMSettingValue(name);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return value;
    }



    private static void cleanupEmptyContracts(String oppId){
        try{
            //cleanup of Renewal_Contract_Object__c where there is no Renewal_Contract_Product__c
            List<Renewal_Contract_Object__c> contList = [SELECT ID,(SELECT ID FROM Associated_Contract_Products__r) FROM Renewal_Contract_Object__c WHERE Opportunity__c =: oppId];
            if(!contList.isEmpty()){
                List<Renewal_Contract_Object__c> deleteContList = new List<Renewal_Contract_Object__c>();
                for(Renewal_Contract_Object__c cont : contList){
                    if(cont.Associated_Contract_Products__r.size() == 0)
                    deleteContList.add(cont);
                }
                if(!deleteContList.isEmpty()){
                    delete deleteContList;
                }
            }//end of if(!contList.isEmpty()) 
        } catch (Exception e) {
            AuraHandledException ex = new  AuraHandledException(e.getMessage());
            ex.setMessage(e.getMessage());
            throw ex;
        }    
    }
    /**
    * @Method Name : validateRefreshBaseline
    * @parameters : oppID, this will have opportunity id
    * @purpose : This method will be called on manage products  to validate refreshbaseline
    **/
@AuraEnabled
public static boolean validateRefreshBaseline(String opportunityID){
    
    Boolean showError;
    try{
        if(OpportunityUtilClass.isClosed(opportunityID))
        {
            showError = true;
            throw new AuraException(Label.Opportunity_is_in_Closed_Stage);
        }
         if(!OpportunityUtilClass.hasAssociatedRenewalContract(opportunityID))
         {
            showError = true;
            string message = GsmUtilClass.getErrorPageSettingValue('NoContractAssociatedError');
            system.debug('message'+message);
            throw new AuraException(message); 
         }
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    return showError;
}

 /**
    * @Method Name : validateRefreshBaseline
    * @parameters : oppID, this will have opportunity id
    * @purpose : This method will be called on manage products  to  refreshbaseline
**/
@AuraEnabled
public static string refreshContractBaseline(String opportunityID){

        GsmUtilClass.disableLossReasonValidation = False; 
        system.debug('Inside refresh method  Op ' +opportunityID );
        String opptyCurrency;
        Date opptyCloseDate ;
        Set<String> setorignalContractIds = new Set<String>();
        List<String> contractProductIds = new List<String>();
        Set<String> contractCurrencySet = new Set<String>();
        String returnMessage ;
        try{
            for(Renewal_Contract_Object__c contractObj: [SELECT Name,Opportunity__c,Opportunity__r.CurrencyIsoCode, Opportunity__r.Closedate,
                                    Contract__r.Original_Contract_Id__c,Contract__r.Currency__c,
                                    (SELECT Id,Associated_Contract__c,Opportunity_Product__c,Contract_Product__c FROM Associated_Contract_Products__r) 
                                    FROM Renewal_Contract_Object__c WHERE Opportunity__c =:opportunityID])
                {
                        if( String.isBlank(opptyCurrency))
                            opptyCurrency = contractObj.Opportunity__r.CurrencyIsoCode;
                        if(opptyCloseDate== null)
                           opptyCloseDate = contractObj.Opportunity__r.Closedate;
                        setorignalContractIds.add(contractObj.Contract__r.Original_Contract_Id__c);
                        contractCurrencySet.add(contractObj.Contract__r.Currency__c);
                        for( Renewal_Contract_Product__c rcp : contractObj.Associated_Contract_Products__r){
                                contractProductIds.add(rcp.Contract_Product__c);
                        }
                }
             
            CreateRenewalOpptyWithMultipleContracts roc = new CreateRenewalOpptyWithMultipleContracts(new List<String>(setorignalContractIds));

            roc.setOpportunityCurrency(opptyCurrency);
            roc.setContractCurrency(contractCurrencySet);
            roc.setOpportunityCloseDate(opptyCloseDate);
            roc.refreshOpportunityProducts(opportunityID);
            if(roc.errorOccured){
                throw new AuraException('An error occured while refreshing baseline.');
            }else{
                returnMessage= 'Baseline sucessfully refreshed.';
            }   
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return returnMessage;

    }


/**
    * @Method Name : getCurrencyConversionRates
    * @parameters : closedate, this will have opportunity closedate
    * @purpose : This method will retrive currencyconversion rates
**/

@AuraEnabled
public static map<String,Decimal>  getCurrencyConversionRates(Date closedate){
    map<String,Decimal> mapOfIsoCodeToDC = new  map<String,Decimal>();
    try {
        for(DatedConversionRate dcr : [SELECT IsoCode, ConversionRate, NextStartDate, StartDate FROM DatedConversionRate WHERE  StartDate <= :closeDate AND NextStartDate > :closeDate ])
            {
                mapOfIsoCodeToDC.put(dcr.IsoCode,dcr.ConversionRate);
            }
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    return mapOfIsoCodeToDC ;
}

@AuraEnabled
public static Boolean checkRefreshBaselineWarning(String OpptyId){

    String opptyCurrency;
    Date opptyCloseDate ;
    Set<String> setorignalContractIds = new Set<String>();
    List<String> contractProductIds = new List<String>();
    Set<String> contractCurrencySet = new Set<String>();
    Boolean refreshContractBaselineFlag = false;

    Map<Id,OpportunitylineItem> mapOfPriceBookEntryIdToOldOli = new Map<Id,OpportunitylineItem>();
    Map<Id,OpportunitylineItem> mapOfPriceBookEntryIdToNewOli = new Map<Id,OpportunitylineItem>();
    Map<Id,OpportunitylineItem> mapOpportunityLineItems = new Map<Id,OpportunitylineItem>();
    
    List<OpportunitylineItem> listToUpdate  = new List<OpportunitylineItem>();
    List<OpportunitylineItem> listToInsert  = new List<OpportunitylineItem>();
    List<OpportunitylineItem> listToDelete  = new List<OpportunitylineItem>();
    Id closedRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(GSMUtilClass.getGSMSettingValue('Closed_Opportunity_Rec_Type')).getRecordTypeId();

    try {

        for(Renewal_Contract_Object__c contractObj: [SELECT Name,Opportunity__c,Opportunity__r.CurrencyIsoCode, Opportunity__r.Closedate, Contract__r.Original_Contract_Id__c,Contract__r.Currency__c,
                (SELECT Id,Associated_Contract__c,Opportunity_Product__c,Contract_Product__c FROM Associated_Contract_Products__r) FROM Renewal_Contract_Object__c WHERE Opportunity__c =:OpptyId and Opportunity__r.recordtypeid != :closedRecTypeId])
                    {
                        if(String.isBlank(opptyCurrency)){
                            opptyCurrency = contractObj.Opportunity__r.CurrencyIsoCode;
                        }
                            
                        if(opptyCloseDate == null){
                            opptyCloseDate = contractObj.Opportunity__r.Closedate;
                        }
                        setorignalContractIds.add(contractObj.Contract__r.Original_Contract_Id__c);
                        contractCurrencySet.add(contractObj.Contract__r.Currency__c);
                        for( Renewal_Contract_Product__c rcp : contractObj.Associated_Contract_Products__r){
                                contractProductIds.add(rcp.Contract_Product__c);
                        }
                    }

        if(setorignalContractIds.size() > 0){
            CreateRenewalOpptyWithMultipleContracts roc = new CreateRenewalOpptyWithMultipleContracts(new List<String>(setorignalContractIds));

            roc.setOpportunityCurrency(opptyCurrency);
            roc.setContractCurrency(contractCurrencySet);
            roc.setOpportunityCloseDate(opptyCloseDate);
            
            for(OpportunitylineItem oli : [Select Id,Average_Renewal_Commit_MRR__c
                                        ,Projected_Monthly_commit_fees__c
                                        ,Average_Renewal_Usage_MRR__c
                                        ,PricebookEntryId
                                        ,UnitPrice
                                        ,Product2.Akam_Product_Id__c
                                        From OpportunityLineItem
                                        Where OpportunityId =:opptyId AND
                                        (Average_Renewal_Commit_MRR__c != null OR Average_Renewal_Usage_MRR__c != null)] )
                mapOfPriceBookEntryIdToOldOli.put(oli.PricebookEntryId,oli);

                
            for(OpportunitylineItem oli : roc.createOpportunityProductsOnRefresh(opptyId))
                mapOfPriceBookEntryIdToNewOli.put(oli.PricebookEntryId,oli);
            

                
            for(Id newPbeId:mapOfPriceBookEntryIdToNewOli.keySet())
            {
                if(mapOfPriceBookEntryIdToOldOli.containsKey(newPbeId))
                {

                    if(mapOfPriceBookEntryIdToOldOli.get(newPbeId).Average_Renewal_Usage_MRR__c.setScale(2, RoundingMode.HALF_UP) != mapOfPriceBookEntryIdToNewOli.get(newPbeId).Average_Renewal_Usage_MRR__c.setScale(2, RoundingMode.HALF_UP)
                    || mapOfPriceBookEntryIdToOldOli.get(newPbeId).Average_Renewal_Commit_MRR__c.setScale(2, RoundingMode.HALF_UP) != mapOfPriceBookEntryIdToNewOli.get(newPbeId).Average_Renewal_Commit_MRR__c.setScale(2, RoundingMode.HALF_UP))
                    {

                        mapOfPriceBookEntryIdToNewOli.get(newPbeId).Id = mapOfPriceBookEntryIdToOldOli.get(newPbeId).Id;
                        listToUpdate.add(mapOfPriceBookEntryIdToNewOli.get(newPbeId));
                    }
                    
                }else{

                    listToInsert.add(mapOfPriceBookEntryIdToNewOli.get(newPbeId));
                }
                
            }
            
            for(Id oldPbeId:mapOfPriceBookEntryIdToOldOli.keySet()){
                if(!mapOfPriceBookEntryIdToNewOli.containsKey(oldPbeId)){

                    listToDelete.add(mapOfPriceBookEntryIdToOldOli.get(oldPbeId));
                }
            }

            if(listToUpdate.size() > 0 || listToInsert.size() > 0 || listToDelete.size() > 0){
                refreshContractBaselineFlag = true;
            }
        }
    } catch (Exception e) {
        throw new AuraHandledException(e.getMessage());
    }
    System.debug('Inside checkRefreshBaselineWarning:'+refreshContractBaselineFlag);
    return refreshContractBaselineFlag;
}
    
       
}//end of class