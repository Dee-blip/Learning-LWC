/*@Author: Ruchika Sharma
@Story: SFDC-1395*/
public with sharing class ChangeOpportunityCurrencyController {

    private final Opportunity opptyObject;
    public String selectedCurrency {get;set;}
    private Boolean errorOccurred;
    DMLResults results; 
    transient Savepoint spInitialState;
    public id oppid;
    // The extension constructor initializes the private member
    // variable opptyObject by using the getRecord method from the standard
    // controller.
    public ChangeOpportunityCurrencyController(ApexPages.StandardController stdController) {
        this.opptyObject = (Opportunity)stdController.getRecord();
        selectedCurrency = this.opptyObject.currencyISOCode;
        oppid = this.opptyObject.id;
        errorOccurred = false;
        results = new DMLResults(); 
    }

    public List<SelectOption> getCurrencies()
        {
            return GsmUtilClass.getCurrencies('ChangeOpportunityCurrencyController',null);
        }
    public PageReference convertCurrency(){
        system.debug(LoggingLevel.ERROR,'rsh selectedCurrency in oppty: '+opptyObject.currencyISOCode+' stage: '+opptyObject.StageName+' selectedCurrency: '+selectedCurrency);
        Opportunity opp=[select id,Recordtype.DeveloperName from Opportunity where id=:oppid limit 1];
        //check for oppty stage
        String allowedOpptyStages = GsmUtilClass.getGSMSettingValue('ChangeCurrency_Allowed_Oppty_Stages');
        String restrictedOpptyStageError = GsmUtilClass.getGSMSettingValue('ChangeCurrency_OpptyStageValidationError');
        system.debug('Swati::'+opp.Recordtype.DeveloperName);
        if(!allowedOpptyStages.contains(opptyObject.StageName) && opp.Recordtype.DeveloperName !='Administrative_Opportunity'){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, restrictedOpptyStageError));
            return null;    
        }
        if(selectedCurrency.equalsIgnoreCase(this.opptyObject.currencyISOCode)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getGSMSettingValue('ChangeCurrency_sameCurrencyError')));
            return null;       
        }
        List<OpportunityLineItem> copiedOliList = new List<OpportunityLineItem>();
        //To Do: Create apex transaction and rollback in case of error.
        // Create a savepoint while olis are not deleted
        spInitialState = Database.setSavepoint();
        copiedOliList = copyAndDeleteOlis();
        this.opptyObject.currencyISOCode = selectedCurrency;
        //--> TO do: val override in oppty.
        this.opptyObject.validation_Override__c = true; 
        if(!errorOccurred)
            dmlOperation('update',new List<Opportunity>{this.opptyObject});
        system.debug(LoggingLevel.ERROR,'rsh after update this.opptyObject: '+this.opptyObject);
        //convert copiedOliList currency
        //TO do: val override in oli.
        //system.debug(LoggingLevel.ERROR,'rsh genericPopulateMRRFirstRunFlag in ChangeOpportunityCurrencyController : '+OpportunityTriggerClass.genericPopulateMRRFirstRunFlag);

        if(!errorOccurred){
            system.debug(LoggingLevel.ERROR,'rsh genericPopulateMRRFirstRunFlag in ChangeOpportunityCurrencyController : '+OpportunityForecastingTriggerClass.genericPopulateMRRFirstRunFlag);
            //SFDC-2042
            //resetting first run flag which would have set with deletion of line items, so that method runs again to calculate shadow forecastings
            OpportunityForecastingTriggerClass.genericPopulateMRRFirstRunFlag=true;
            dmlOperation('insert',copiedOliList);
        }
        system.debug(LoggingLevel.ERROR,'rsh after insertion copiedOliList: '+copiedOliList);
        if(errorOccurred)
            return null;    
        return new PageReference('/'+opptyObject.id);
    }

    private List<OpportunityLineItem> copyAndDeleteOlis(){
        //copy current oli details
        List<String> listOfParameterNames = buildFieldsList();
        //al.SoqlBuilder queryBuilder = new al.SoqlBuilder().selectx(listOfParameterNames).fromx('OpportunityLineItem').wherex(new al.FieldCondition('OpportunityId',opptyObject.id));
        //String query = queryBuilder.toSoql();

        //System.debug('query' +query);
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        oliList = (List<OpportunityLineItem>)GsmUtilClass.doDatabaseSelect(listOfParameterNames,'OpportunityLineItem','OpportunityId',opptyObject.id,'String','ChangeOpportunityCurrencyController',null);
        Map<String,Id> productToPriceBookIdMap=new Map<String,Id>();
        productToPriceBookIdMap = GsmUtilClass.getPriceBookForProduct();
        system.debug(LoggingLevel.ERROR,'rsh oliList: '+oliList);
        setValidationOverride(oliList);
        List<OpportunityLineItem> copiedOliList = new List<OpportunityLineItem>();
        copiedOliList = oliList;
        
        system.debug(LoggingLevel.ERROR,'rsh copiedOliList: '+copiedOliList);
        //delete olis
        results.storeObjectState();
        system.debug(LoggingLevel.ERROR,'rsh oliList.size(): '+oliList.size());
        if(oliList.size()>0)
            dmlOperation('delete',oliList);
        
        for(OpportunityLineItem copiedOli: copiedOliList){
            //remove id from copied olis
            copiedOli.id=null;
            //associate correct pricebookentryid
            copiedOli.pricebookEntryId = productToPriceBookIdMap.get(copiedOli.Product2.Akam_Product_Id__c+' - '+selectedCurrency);
            system.debug(LoggingLevel.ERROR,'rsh pricebookEntryId  copiedOliList: '+copiedOli.pricebookEntryId);    
        }
        system.debug(LoggingLevel.ERROR,'rsh after deletion copiedOliList: '+copiedOliList);
        Map<OpportunityLineItem,String> oLIToSourceCurrencyMap = new Map<OpportunityLineItem,String>();
        Set<String> sourceCurrencyCodes = new Set<String>();
        sourceCurrencyCodes.add(opptyObject.CurrencyIsoCode);
        for(OpportunityLineItem oli : copiedOliList)
        {
            oLIToSourceCurrencyMap.put(oli,opptyObject.CurrencyIsoCode);
        }
        copiedOliList = GsmUtilClass.genericConvertLineItemCurrencies(copiedOliList,sourceCurrencyCodes,selectedCurrency,opptyObject.CloseDate,oLIToSourceCurrencyMap);
        //copiedOliList = GsmUtilClass.genericConvertLineItemCurrencies(copiedOliList,opptyObject.CurrencyIsoCode,selectedCurrency,opptyObject.CloseDate);
        //for(OpportunityLineItem oliRecord : oliList){
        //    OpportunityLineItem 
        //}
        return copiedOliList;
    }

    private void dmlOperation(String operationName,List<sObject> sObjectRecords){
        try{
            if(operationName.equalsIgnoreCase('delete'))
                delete sObjectRecords;
            if(operationName.equalsIgnoreCase('update'))
                update sObjectRecords;
            if(operationName.equalsIgnoreCase('insert'))
                insert sObjectRecords;
        }catch(Exception ex){
                errorOccurred = true;
                system.debug(LoggingLevel.ERROR,'rsh error occurred: '+ex.getMessage());
                // Rollback to the previous initial state
                Database.rollback(spInitialState);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, GsmUtilClass.getGSMSettingValue('ChangeCurrency_someErrorOccurred')));
                Error_Log__c elc = new Error_Log__c(Name='', Class__c='ChangeOpportunityCurrencyController', Error_Message__c=ex.getMessage());
                insert elc;
            }

    }

    private List<OpportunityLineItem> setValidationOverride(List<OpportunityLineItem> oliList){
        for(OpportunityLineItem oli: oliList)
            oli.Validation_Override__c = true;
        return oliList;
    }
    private List<String> buildFieldsList(){
        List<String> fieldsList = new List<String>();
        //To do: developer name like.
        for(String fieldsToCopy : GsmUtilClass.getGSMSettingValuePartialMatch('ChangeCurrency_OLIFieldsToCopy_')){
            
            system.debug(LoggingLevel.ERROR,'rsh fieldsToCopy: '+fieldsToCopy);    
            fieldsList.addAll(fieldsToCopy.split(','));
        }
        fieldsList.add('Product2.Akam_Product_Id__c');
        system.debug(LoggingLevel.ERROR,'rsh fieldsList: '+fieldsList);
        
        return fieldsList;
    }
}