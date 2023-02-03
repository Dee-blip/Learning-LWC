/**
 * @description       : 
 * @author            : apyati
 * @group             : 
 * @last modified on  : 08-17-2021
 * @last modified by  : apyati
 * Modifications Log 
 * Ver   Date         Author   Modification
 * 1.0   07-29-2021   apyati   Initial Version
**/
public without sharing class SF1_ChangeCurrencyController {

    static List<Renewal_Contract_Product__c> lstRenewalContractProducts = new List<Renewal_Contract_Product__c>();
    
    @AuraEnabled(cacheable= true)
    public static Opportunity fetchOpportunity(Id oppId){
        Opportunity opp;
        try {
            opp = SF1_OpportunityService.getOpportunity(oppId);
        } catch (Exception e){
            System.debug('No record was found for the Id provided. Returning null Opp');
            throw new AuraHandledException(e.getMessage());
        }
        return opp;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> loadCurrencyPicklist(String sobjectName, String picklistFieldName)
    {
        List<String> options = new List<String>();
        try{
            options.addall(GsmUtilClass.getCurrencyIsoCodes('ChangeOpportunityCurrencyController',null));
            options.sort();
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return options;
    }
    
    @AuraEnabled
    public static String checkErrors(Opportunity pageObject) {
        try{
            String allowedOpptyStages = GsmUtilClass.getGSMSettingValue('ChangeCurrency_Allowed_Oppty_Stages');
            String restrictedOpptyStageError = GsmUtilClass.getGSMSettingValue('ChangeCurrency_OpptyStageValidationError');
            Opportunity oppObj = SF1_OpportunityService.getOpportunity(pageObject.Id);
            
            if(!allowedOpptyStages.contains(pageObject.StageName) && pageObject.Recordtype.DeveloperName !='Administrative_Opportunity'){
                return restrictedOpptyStageError;    
            }
            else if(oppObj.CurrencyIsoCode.equalsIgnoreCase(pageObject.CurrencyIsoCode)){
                return GsmUtilClass.getGSMSettingValue('ChangeCurrency_sameCurrencyError');       
            }
            else {
                return 'Success';
            }
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());

        }
        
    }
    
    @AuraEnabled
    public static String convertCurrency(Opportunity pageObject) {
        List<OpportunityLineItem> copiedOliList = new List<OpportunityLineItem>();
        //To Do: Create apex transaction and rollback in case of error.
        // Create a savepoint while olis are not deleted
        //spInitialState = Database.setSavepoint();
        try {
            Opportunity opptyObject = [select id,closedate,currencyIsocode,zoff_status__c,zoff_enabled__c from Opportunity where Id = :pageObject.Id];

            string zoffstatus = opptyObject.zoff_status__c;
            boolean zoffenabled = opptyObject.zoff_enabled__c;

            copiedOliList = copyAndDeleteOlis(pageObject);
            //oppObj.currencyISOCode = pageObject.currencyISOCode;
            //--> TO do: val override in oppty.

            pageObject.zoff_status__c = zoffstatus; 
            pageObject.zoff_enabled__c = zoffenabled ;
            pageObject.validation_Override__c = true; 

            dmlOperation('update',new List<Opportunity>{pageObject});
            system.debug(LoggingLevel.ERROR,'rsh after update this.opptyObject: '+pageObject);
            //convert copiedOliList currency
            //TO do: val override in oli.
            OpportunityForecastingTriggerClass.genericPopulateMRRFirstRunFlag=true;
            OpportunityUtilClass.updateOpportunityOpptyLineItemAfterInsertUpdate = true;
            dmlOperation('insert',copiedOliList);
            system.debug(LoggingLevel.ERROR,'rsh after insertion copiedOliList: '+copiedOliList);
            copyAndDeleteRenewalContractProducts(pageObject.Id);
        } catch(Exception e){
            Error_Log__c elc = new Error_Log__c(Name='', Class__c='ChangeOpportunityCurrencyController', Error_Message__c=e.getMessage());
            insert elc;   
            system.debug('Error =>'+e.getMessage());        
            throw new AuraHandledException (e.getMessage());
        }
        return 'Success';     
    }
    
     public Static List<OpportunityLineItem> copyAndDeleteOlis(Opportunity pageObject){
        //copy current oli details
        List<String> listOfParameterNames = buildFieldsList();
        Opportunity opptyObject = [select id,closedate,currencyIsocode,zoff_status__c,zoff_enabled__c from Opportunity where Id = :pageObject.Id];

        //al.SoqlBuilder queryBuilder = new al.SoqlBuilder().selectx(listOfParameterNames).fromx('OpportunityLineItem').wherex(new al.FieldCondition('OpportunityId',opptyObject.id));
        //String query = queryBuilder.toSoql();

        //System.debug('query' +query);
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        oliList = (List<OpportunityLineItem>)GsmUtilClass.doDatabaseSelect(listOfParameterNames,'OpportunityLineItem','OpportunityId',pageObject.id,'String','ChangeOpportunityCurrencyController',null);
        
        //List<Renewal_Contract_Product__c> lstRenewalContractProduct = new List<Renewal_Contract_Product__c>();
        lstRenewalContractProducts = [Select Id,Contract_Product__c,End_Month__c,Contract_Product__r.Effective_End_Date__c,Contract_Product__r.Forecast_Product_Id__c,Associated_Contract__c from Renewal_Contract_Product__c where Opportunity_Product__c in : oliList];
        


        Map<String,Id> productToPriceBookIdMap=new Map<String,Id>();
        List<String> listOfPEParameterNames = new List<String>{'Id'
                                                            ,'product2.Akam_Product_Id__c'
                                                            ,'currencyIsoCode'};
        List<PricebookEntry> priceBookEntryList = new List<PricebookEntry>();
        priceBookEntryList = 
            (List<PricebookEntry>)GsmUtilClass.doDatabaseSelect(listOfPEParameterNames,'PricebookEntry','isActive','true','Boolean','ChangeOpportunityCurrencyController',null);
        //productToPriceBookIdMap = GsmUtilClass.getPriceBookForProduct();
        for(PricebookEntry pbe : priceBookEntryList)
        { 
            productToPriceBookIdMap.put(pbe.product2.Akam_Product_Id__c+' - '+pbe.currencyIsoCode,pbe.Id);
        }
        system.debug('Product to Price Book Map = '+productToPriceBookIdMap);
        system.debug(LoggingLevel.ERROR,'rsh oliList: '+oliList);
        setValidationOverride(oliList);
        List<OpportunityLineItem> copiedOliList = new List<OpportunityLineItem>();
        copiedOliList = oliList;
        
        system.debug(LoggingLevel.ERROR,'rsh copiedOliList: '+copiedOliList);
        //delete olis
        //results.storeObjectState();
        system.debug(LoggingLevel.ERROR,'rsh oliList.size(): '+oliList.size());
        if(oliList.size()>0)
            dmlOperation('delete',oliList);

        for(OpportunityLineItem copiedOli: copiedOliList){
            //remove id from copied olis
            copiedOli.id=null;
            //associate correct pricebookentryid
            copiedOli.pricebookEntryId = productToPriceBookIdMap.get(copiedOli.Product2.Akam_Product_Id__c+' - '+pageObject.CurrencyIsoCode);
             
        }
        Map<OpportunityLineItem,String> oLIToSourceCurrencyMap = new Map<OpportunityLineItem,String>();
        Set<String> sourceCurrencyCodes = new Set<String>();
        sourceCurrencyCodes.add(opptyObject.CurrencyIsoCode);
        for(OpportunityLineItem oli : copiedOliList)
        {
            oLIToSourceCurrencyMap.put(oli,opptyObject.CurrencyIsoCode);
        }
        copiedOliList = GsmUtilClass.genericConvertLineItemCurrencies(copiedOliList,sourceCurrencyCodes,pageObject.CurrencyIsoCode,opptyObject.CloseDate,oLIToSourceCurrencyMap);
        //copiedOliList = GsmUtilClass.genericConvertLineItemCurrencies(copiedOliList,opptyObject.CurrencyIsoCode,pageObject.CurrencyIsoCode,opptyObject.CloseDate);
        //for(OpportunityLineItem oliRecord : oliList){
        //    OpportunityLineItem 
        //}
        return copiedOliList;
    }
    
    public static void dmlOperation(String operationName,List<sObject> sObjectRecords){
        if(operationName.equalsIgnoreCase('delete'))
                delete sObjectRecords;
        if(operationName.equalsIgnoreCase('update'))
                update sObjectRecords;
        if(operationName.equalsIgnoreCase('insert'))
                insert sObjectRecords;
	}
    
     public static List<String> buildFieldsList(){
        List<String> fieldsList = new List<String>();
        //To do: developer name like.
        for(String fieldsToCopy : GsmUtilClass.getGSMSettingValuePartialMatch('ChangeCurrency_OLIFieldsToCopy_')){
            
            system.debug(LoggingLevel.ERROR,'rsh fieldsToCopy: '+fieldsToCopy);    
            fieldsList.addAll(fieldsToCopy.split(','));
        }
        fieldsList.add('Product2.Akam_Product_Id__c');
        fieldsList.add('Specialist_Projected_Monthly_Commit__c');
        system.debug(LoggingLevel.ERROR,'rsh fieldsList: '+fieldsList);
        
        return fieldsList;
    }
    
    public Static List<OpportunityLineItem> setValidationOverride(List<OpportunityLineItem> oliList){
        for(OpportunityLineItem oli: oliList)
            oli.Validation_Override__c = true;
        return oliList;
    }

    public static void copyAndDeleteRenewalContractProducts(Id OpportunityId){

        map<Id,Id>  mapConProductIdContractId  = new map<Id,Id>();
        map<Id,String>  mapConProductIdEndMonth  = new map<Id,String>();
        map<String,List<String>>  mapProductIdContractProductIds  = new map<String,List<String>>();
        List<Renewal_Contract_Product__c> lstInsertRenewalContractProducts = new List<Renewal_Contract_Product__c>();
        for(Renewal_Contract_Product__c renewalprod :lstRenewalContractProducts){
            mapConProductIdContractId.put(renewalprod.Contract_Product__c,renewalprod.Associated_Contract__c);
            mapConProductIdEndMonth.put(renewalprod.Contract_Product__c,renewalprod.End_month__c);

            if(mapProductIdContractProductIds.containskey(renewalprod.Contract_Product__r.Forecast_Product_Id__c)){
                mapProductIdContractProductIds.get(renewalprod.Contract_Product__r.Forecast_Product_Id__c).add(renewalprod.Contract_Product__c);
            }else{
                mapProductIdContractProductIds.put(renewalprod.Contract_Product__r.Forecast_Product_Id__c,new List<String>{renewalprod.Contract_Product__c});
            }     
        }

        for( OpportunityLineItem oli : [SELECT Id,Product2Id,Product2.Name,Product2.Akam_Product_Id__c,PricebookEntryId,OpportunityId
                                        FROM OpportunityLineItem WHERE OpportunityId =: OpportunityId AND (Average_Renewal_Commit_MRR__c!=null OR Average_Renewal_Usage_MRR__c!=null)]){
                                            if(mapProductIdContractProductIds.containsKey(oli.Product2.Akam_Product_Id__c)){
                                                for(Id conprodId : mapProductIdContractProductIds.get(oli.Product2.Akam_Product_Id__c) ){
                                                    Renewal_Contract_Product__c acp = new Renewal_Contract_Product__c();
                                                    acp.Name = oli.Product2.Akam_Product_Id__c;
                                                    acp.Opportunity_Product__c = oli.Id;
                                                    acp.Contract_Product__c =conprodId;
                                                    acp.Associated_Contract__c = mapConProductIdContractId.get(conprodId);
                                                    acp.End_Month__c= mapConProductIdEndMonth.get(conprodId);
                                                    lstInsertRenewalContractProducts.add(acp);
                                                }
                                            }
                                        }
        
        if(lstRenewalContractProducts.size()>0)
        {
            dmlOperation('Delete',lstRenewalContractProducts);
        }

        if(lstInsertRenewalContractProducts.size()>0)
        {
            dmlOperation('Insert',lstInsertRenewalContractProducts);
        }
       

    }


    
    
}