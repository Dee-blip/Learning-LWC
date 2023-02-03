/**
* @description       : 
* @author            : 
* @group             : 
* @last modified on  : 09-21-2021
* @last modified by  : apyati
* Modifications Log 
* TAG   Date         Author    Modification
* T01   07-22-2021   apyati    Modified for manageproducts revamp
*    
**/
public without sharing class CreateRenewalOpptyWithMultipleContracts {
    
    private List<Merge_Contract_Header__c> contractList =null;
    private List<Opportunity> renewalOpptyList = null;
    private Set<Contract_Product__c> setOfContractProducts = null;
    private DMLResults results = new DMLResults(true);
    private String selectedOpportunityCurrency;
    //private String contractCurrency;
    private Set<String> contractCurrecnyList;
    private Boolean isContractOpptyCurrencyMismatch;
    private Datetime opportunityCloseDate;
    public Boolean errorOccured = false;
    public static Boolean opptycurrencycheckflag = true;
    map<Id,Id> mapDeleteContractProdOptyProd = new map<Id,Id>();
    map<Id,Id> mapRenewalContractProduct = new map<Id,Id>();
    List<Renewal_Contract_Object__c> lstRenewalContractObjects = new List<Renewal_Contract_Object__c>();
    map<string,List<Contract_Product__c>> mapProductIdContractProducts = new map<string,List<Contract_Product__c>>();
    map<String, Id> mapRenewalContracts = new Map<String,Id>();
    map<String, Renewal_Contract_Product__c> mapRenewalContractProducts = new Map<String,Renewal_Contract_Product__c>();
    
    //paramater constructer with conproductIds
    public CreateRenewalOpptyWithMultipleContracts(List<String> originalContractIds, List<String> contractProductIds)
    {
        contractList = [Select Id
                        ,Account_Name__r.Name
                        ,Account_Name__r.OwnerId
                        ,Opportunity_Name__r.Partner_Involved__c
                        ,Opportunity_Name__r.currencyIsoCode
                        ,CurrencyIsoCode
                        ,Currency__c
                        ,Opportunity_Name__r.Deal_Type__c
                        ,Effective_End_Date__c
                        ,original_contract_id__c
                        ,Opportunity_Name__r.Partner_Involved__r.Akam_Account_Id__c
                        ,Opportunity_Name__r.CloseDate
                        ,Parent_Contract__c
                        ,Order_Id__c
                        ,Account_Name__r.ECUSTOMS__RPS_Status__c
                        ,Account_Name__r.Override_Visual_Compliance__c
                        ,AK_Cancellation_Clause__c,Contract_Type__c,Parent_Account_Name__c
                        ,(Select Id
                          ,Name
                          ,UnitPrice__c
                          ,Forecast_Product_id__c
                          ,Effective_End_Date__c
                          ,Deleted_From_Source__c
                          ,original_Contract_id__r.currencyIsoCode
                          ,Average_Renewal_Commit_MRR__c
                          ,Average_Renewal_Usage_MRR__c
                          ,original_Contract_id__r.original_Contract_id__c
                          ,Original_Contract_id__c
                          ,original_Contract_id__r.Currency__c
                          ,original_Contract_id__r.Effective_End_Date__c
                          ,ZOFF_Promo_Check__c// Rajesh   SFDC-7061
                          from Contract_Products__r where Deleted_From_Source__c = false and Id in: contractProductIds)
                        from Merge_Contract_Header__c
                        Where original_contract_Id__c in :originalContractIds];
    }
    public CreateRenewalOpptyWithMultipleContracts(List<String> originalContractIds)
    {
        contractList = [Select Id
                        ,Account_Name__r.Name
                        ,Account_Name__r.OwnerId
                        ,Opportunity_Name__r.Partner_Involved__c
                        ,Opportunity_Name__r.currencyIsoCode
                        ,CurrencyIsoCode
                        ,Currency__c
                        ,Opportunity_Name__r.Deal_Type__c
                        ,Effective_End_Date__c
                        ,original_contract_id__c
                        ,Opportunity_Name__r.Partner_Involved__r.Akam_Account_Id__c
                        ,Opportunity_Name__r.CloseDate
                        ,Parent_Contract__c
                        ,Order_Id__c
                        ,Account_Name__r.ECUSTOMS__RPS_Status__c
                        ,Account_Name__r.Override_Visual_Compliance__c
                        ,AK_Cancellation_Clause__c,Contract_Type__c,Parent_Account_Name__c
                        ,(Select Id
                          ,Name
                          ,UnitPrice__c
                          ,Forecast_Product_id__c
                          ,original_Contract_id__r.currencyIsoCode
                          ,Average_Renewal_Commit_MRR__c
                          ,Average_Renewal_Usage_MRR__c
                          ,original_Contract_id__r.original_Contract_id__c
                          ,Original_Contract_id__c
                          ,original_Contract_id__r.Currency__c
                          ,original_Contract_id__r.Effective_End_Date__c
                          ,ZOFF_Promo_Check__c// Rajesh   SFDC-7061
                          ,Effective_End_Date__c
                          ,Deleted_From_Source__c
                          from Contract_Products__r where Deleted_From_Source__c = false)
                        from Merge_Contract_Header__c
                        Where original_contract_Id__c in :originalContractIds];
    }
    
    public CreateRenewalOpptyWithMultipleContracts(String originalContractId)
    {
        this(new List<String> {originalContractId});
    }
    
    public void setOpportunityCurrency(String currencyCode)
    {
        selectedOpportunityCurrency = currencyCode;
    }
    
    
    //public void setContractCurrency(String currencyCode)
    public void setContractCurrency(Set<String> currencyCodes)
    {
        //contractCurrency = currencyCode;
        contractCurrecnyList = currencyCodes;
        for(String cur : currencyCodes)
        {
            if(!String.isBlank(selectedOpportunityCurrency) )//&& selectedOpportunityCurrency!=null && !selectedOpportunityCurrency.contains('none') )//&& !contractList[0].Currency__c.equalsIgnoreCase(selectedOpportunityCurrency))
            {
                isContractOpptyCurrencyMismatch = true;
            } 
            else{
                isContractOpptyCurrencyMismatch = false;
                //selectedOpportunityCurrency = contractList[0].Currency__c;
            }
        }
    }
    
    
    public string setDestinationCurrency(){
        system.debug('Source and Dest Currency before'+contractCurrecnyList +' D '+selectedOpportunityCurrency);
        if(isContractOpptyCurrencyMismatch){
            setContractCurrency(contractCurrecnyList);
        }
        else
        {
            Set<String> contractCurrencySetTemp = new Set<String>();
            contractCurrencySetTemp.add(contractList[0].Currency__c);
            setContractCurrency(contractCurrencySetTemp);
            selectedOpportunityCurrency = contractList[0].Currency__c;
        }
        system.debug('Source and Dest Currency after'+contractCurrecnyList +' D '+selectedOpportunityCurrency);
        return selectedOpportunityCurrency;
    }
    
    
    public void setOpportunityCloseDate(Datetime closeDate)
    {
        opportunityCloseDate = closeDate;
    }
    
    public Opportunity createRenewalOpportunityWithProducts(string oppType) //Added parameter as part of SFDC-3550
    {
        // build opportunity record
        Opportunity newOpportunity = buildOpportunityRecord(oppType);
        
        //SFDC-3550
        if(oppType != null && oppType != '')
            newOpportunity.Opportunity_Type__c = oppType;
        
        if(newOpportunity!=null)
        {
            insert (new List<Opportunity>{newOpportunity});
            /*
            results.clear();
            results.dmlInsert(new List<Opportunity>{newOpportunity});
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
            */

            setOpportunityCloseDate(newOpportunity.CloseDate);
            createRenewalContractObjects(newOpportunity.Id);
            List<OpportunityLineItem> opptyLineItemList = new List<OpportunityLineItem>();
            opptyLineItemList =   createOpportunityProducts(newOpportunity.Id);
            system.debug('HC Final Oppty List '+opptyLineItemList);
            
            for(OpportunitylineItem newOLI : opptyLineItemList)
            {
                if(newOLI.UnitPrice == null)
                    newOLI.UnitPrice = 0.00;
                //SFDC-7056
                if(oppType == 'Auto-Renewal'){
                    newOLI.Projected_Monthly_commit_fees__c = newOLI.Average_Renewal_Commit_MRR__c;
                    newOLI.Projected_Avg_Rev_Non_Commit__c  = newOLI.Average_Renewal_Usage_MRR__c;
                    newOLI.MRR__c = 0.00;
                    newOLI.EMRI__c = 0.00;
                }
            }
            if(opptyLineItemList.size()>0 && !errorOccured)
            {

                insert opptyLineItemList;
                /*
                results.clear();
                results.dmlInsert(opptyLineItemList);
                results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
                if(results.failurecount>0)
                    errorOccured = true;
                    */
            }
        }
        return newOpportunity;
    }
    
    public void refreshOpportunityProducts(Id opptyId)
    {
        
        
        
        Map<Id,OpportunitylineItem> mapOfPriceBookEntryIdToOldOli = new Map<Id,OpportunitylineItem>();
        Map<Id,OpportunitylineItem> mapOfPriceBookEntryIdToNewOli = new Map<Id,OpportunitylineItem>();
        Map<Id,OpportunitylineItem> mapOpportunityLineItems = new Map<Id,OpportunitylineItem>();
        
        List<OpportunitylineItem> listToUpdate                    = new List<OpportunitylineItem>();
        List<OpportunitylineItem> listToInsert                    = new List<OpportunitylineItem>();
        List<OpportunitylineItem> listToDelete                   = new List<OpportunitylineItem>();
        
        
        
        Opportunity oppty = [Select id, Opportunity_Type__c from opportunity where Id =:opptyId];
        
        
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

        

            
        for(OpportunitylineItem oli : createOpportunityProductsOnRefresh(opptyId))
            mapOfPriceBookEntryIdToNewOli.put(oli.PricebookEntryId,oli);
        

            
        for(Id newPbeId:mapOfPriceBookEntryIdToNewOli.keySet())
        {
            if(mapOfPriceBookEntryIdToOldOli.containsKey(newPbeId))
            {

                if(mapOfPriceBookEntryIdToOldOli.get(newPbeId).Average_Renewal_Usage_MRR__c!=mapOfPriceBookEntryIdToNewOli.get(newPbeId).Average_Renewal_Usage_MRR__c
                   || mapOfPriceBookEntryIdToOldOli.get(newPbeId).Average_Renewal_Commit_MRR__c!=mapOfPriceBookEntryIdToNewOli.get(newPbeId).Average_Renewal_Commit_MRR__c
                   || mapOfPriceBookEntryIdToOldOli.get(newPbeId).UnitPrice!=mapOfPriceBookEntryIdToOldOli.get(newPbeId).UnitPrice)
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
        
        

        for(OpportunitylineItem newOLi :listToInsert)
        {
            if(newOLi.UnitPrice == null)
                newOLi.UnitPrice = 0.00;
            
            if(oppty.Opportunity_Type__c == 'Auto-Renewal'){
                newOLI.Projected_Monthly_commit_fees__c = newOLI.Average_Renewal_Commit_MRR__c;
                newOLI.Projected_Avg_Rev_Non_Commit__c  = newOLI.Average_Renewal_Usage_MRR__c;
                newOLI.MRR__c = 0.00;
                newOLI.EMRI__c = 0.00;
            }
            if(newOLI.Projected_Avg_Rev_Non_Commit__c == null)
                newOLI.Projected_Avg_Rev_Non_Commit__c =0.00;
            if( newOLI.Projected_Avg_Rev_Non_Commit__c  ==null)
                newOLI.Projected_Avg_Rev_Non_Commit__c =0.00;
            
            
        }
        
     
        
        if(listToUpdate.size()>0)
        {
            update listToUpdate;
            /*
            results.clear();
            results.dmlUpdate(listToUpdate);
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
            */
        }
        
        if(listToInsert.size()>0)
        {
            insert listToInsert;
            /*
            results.clear();
            results.dmlInsert(listToInsert);
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
            */
        }
        
        if(listToDelete.size()>0)
        {
            delete listToDelete;
            /*
            results.clear();
            results.dmlDelete(listToDelete);
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
            */
        }
        

        refreshRenewalContractProductObjects(opptyId);
        
        
    }
    
    
    public Opportunity buildOpportunityRecord(String type)
    {
        Date closeDate = buildOpportunityCloseDate();
        
        String contractName                      = buildContractName();
        Opportunity opportunityRecord            = new Opportunity();
        opportunityRecord.Name                   = buildOpportunityName(contractName,closeDate, type);
        if(type != null && type != '')
            opportunityRecord.Opportunity_Type__c = type;  //<T01>
        if(type == 'Auto-Renewal'){
            if((GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Red').split(',').contains(contractList[0].Account_Name__r.ECUSTOMS__RPS_Status__c) && !contractList[0].Account_Name__r.Override_Visual_Compliance__c)
                 || (GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Pending').split(',').contains(contractList[0].Account_Name__r.ECUSTOMS__RPS_Status__c) && !contractList[0].Account_Name__r.Override_Visual_Compliance__c)
                 || (GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_DS_Alert').split(',').contains(contractList[0].Account_Name__r.ECUSTOMS__RPS_Status__c) && !contractList[0].Account_Name__r.Override_Visual_Compliance__c))
                {
                    opportunityRecord.StageName='1. Identify Need';
                    opportunityRecord.ForecastCategoryName   = 'Omitted';
                }
            else
                {
                    opportunityRecord.StageName='4. Select Option';
                    opportunityRecord.ForecastCategoryName = 'Commit';
                    opportunityRecord.Override_Forecast_Category_With__c = 'Commit';
                }
                opportunityRecord.Auto_Renewal__c = True;
            }
        else{
            opportunityRecord.StageName              = '1. Identify Need'; //SFDC-3539
            opportunityRecord.ForecastCategoryName   = 'Omitted';
            opptycurrencycheckflag=false;
        }
        
        opportunityRecord.CurrencyIsoCode        =  isContractOpptyCurrencyMismatch ? selectedOpportunityCurrency : contractList[0].Currency__c;
        opportunityRecord.AccountId              = contractList[0].Account_Name__c;
        opportunityRecord.Closedate              = closeDate;
        opportunityRecord.Validation_Override__c = true;
        opportunityRecord.Deal_Type__c           = 'Direct';
        opportunityRecord.Renew_Contract_Id_Text__c = contractName;
        
        
        return opportunityRecord;
    }
    
    private Date buildOpportunityCloseDate()
    {
        Date closeDate;

        for(Merge_Contract_Header__c con : contractList)
        {
            for(Contract_Product__c conprod : con.Contract_Products__r){
                if(closeDate==null ||conprod.Effective_End_Date__c < closeDate){
                    closeDate = conprod.Effective_End_Date__c;
                }
            }
        }
        return closeDate;
        
    }
    
    private String buildOpportunityName(String contractName, Date closeDate, String type)
    {
        String opptyName;
        Datetime dt = closeDate;
        String endMonth = dt.format('MMM')+'\''+dt.year();
        String accountName   = contractList[0].Account_Name__r.Name;
        String typeString ='';
        Boolean offcycle = true;

        for(Merge_Contract_Header__c con : contractList){
            for(Contract_Product__c conprod : con.Contract_Products__r){
                if(con.Effective_End_Date__c == conprod.Effective_End_Date__c ){
                    offcycle =false;
                    break;
                }
            }
        }


        if( offcycle){
            if(type.equals('Auto-Renewal')){ 
                typeString = ' - Off-Cycle Auto Renewal of Products on Contract ' + contractName + ' renewing on ' +endMonth;
            }
            else{
               typeString =  ' - Off-Cycle Renewal of Products on Contract ' + contractName+ ' expiring on ' + endMonth;
            }
        }
        else{
           if(type.equals('Auto-Renewal')){ 
               typeString = ' - Auto Renewal of Contract '+ contractName +' renewing on ' + endMonth;
            }
            else{
                typeString = ' - Renewal of Contract '+ contractName +' expiring on ' + endMonth;
            }
        }



        if(accountname!= null && (accountname?.length()+ typeString?.length()) >120)
        {
            Integer diffLen = accountname.length()-120;
            accountname =accountName.length()>difflen?accountName.subString(0,accountName.length()-(difflen+1)):accountName;
        }
        
        opptyName = accountname + typeString;
        
        return opptyName;
    }
    
    public String buildContractName()
    {
        String contractName;
        for(Merge_Contract_Header__c contract : contractList)
        {
            if(String.isBlank(contractName))
                contractName = contract.original_contract_id__c;
            else
                contractName += ',' + contract.original_contract_id__c;
        }
        
        return contractName;
    }
    
    public void createRenewalContractObjects(Id opportunityId)
    {
        List<Renewal_Contract_Object__c> listOfRenewalContractObjects = new List<Renewal_Contract_Object__c>();
        for(Merge_Contract_Header__c contract : contractList)
        {
            Renewal_Contract_Object__c renewalContract    = new Renewal_Contract_Object__c();
            renewalContract.Name              = contract.Original_Contract_Id__c;
            renewalContract.Contract__c           = contract.Id;
            renewalContract.Opportunity__c                = opportunityId;
            renewalContract.Contract_Id_Text__c       = contract.Original_Contract_Id__c;
            renewalContract.Contract_Effective_End_Date__c  = contract.Effective_End_Date__c;
            renewalContract.Parent_Contract__c        = contract.Parent_Contract__c;
            renewalContract.Order_Id__c           = contract.Order_Id__c;
            //renewalContract.Cancellation_Clause__c      = contract.AK_Cancellation_Clause__c;
            renewalContract.Contract_Type__c = contract.Contract_Type__c;
            renewalContract.Parent_Account_Name__c = contract.Parent_Account_Name__c;
            
            listOfRenewalContractObjects.add(renewalContract);
        }
        if(listOfRenewalContractObjects.size()>0 )
        {
            insert listOfRenewalContractObjects;
            /*
            results.clear();
            results.dmlInsert(listOfRenewalContractObjects);
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
                */
        }
        
    }
    
    public void refreshRenewalContractProductObjects(Id OpportunityId){
        
        List<Renewal_Contract_Product__c> lstInsertRenewalContractProducts = new List<Renewal_Contract_Product__c>();
        List<Renewal_Contract_Product__c> lstDeleteRenewalContractProducts = new List<Renewal_Contract_Product__c>();
        List<Renewal_Contract_Object__c> lstDeleteRenewalContractObject = new List<Renewal_Contract_Object__c>();
        for( OpportunityLineItem oli : [SELECT Id,Product2Id,Product2.Name,Product2.Akam_Product_Id__c,PricebookEntryId,OpportunityId
                                        FROM OpportunityLineItem WHERE OpportunityId =: OpportunityId]){
                                            if(mapProductIdContractProducts.containsKey(oli.Product2.Akam_Product_Id__c)){
                                                for(Contract_Product__c conprod : mapProductIdContractProducts.get(oli.Product2.Akam_Product_Id__c) ){
                                                    string uniquestr = mapRenewalContracts.get(conprod.Original_Contract_Id__c+''+oli.OpportunityId)+''+conprod.Id+oli.Id;
                                                    if(!mapRenewalContractProducts.containsKey(uniquestr)){
                                                        Renewal_Contract_Product__c acp = new Renewal_Contract_Product__c();
                                                        acp.Name= oli.Product2.Akam_Product_Id__c;
                                                        acp.Opportunity_Product__c = oli.Id;
                                                        acp.Contract_Product__c =conprod.Id;
                                                        acp.Associated_Contract__c = mapRenewalContracts.get(conprod.Original_Contract_Id__c+''+oli.OpportunityId);
                                                        acp.End_Month__c= conprod.Effective_End_Date__c.year()+'-'+conprod.Effective_End_Date__c.month();
                                                        lstInsertRenewalContractProducts.add(acp);
                                                    }else{
                                                        mapRenewalContractProducts.remove(uniquestr);
                                                    }
                                                }
                                            }
                                        }
        
       
        if(lstInsertRenewalContractProducts.size()>0)
        {
            insert lstInsertRenewalContractProducts;
            /*
            results.clear();
            results.dmlInsert(lstInsertRenewalContractProducts);
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
                */
        }
        if(mapRenewalContractProducts.values().size()>0)
        {
            delete mapRenewalContractProducts.values();
            /*
            results.clear();
            results.dmlDelete(mapRenewalContractProducts.values());
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
                */
        }
        for(Renewal_Contract_Object__c  rco : [SELECT Id,Contract__c,Opportunity__c, 
                                               (SELECT Id FROM Associated_Contract_Products__r) 
                                               FROM Renewal_Contract_Object__c WHERE Opportunity__c= : OpportunityId ]){
                                                   if(rco.Associated_Contract_Products__r.size()<1){
                                                       lstDeleteRenewalContractObject.add(rco);
                                                   }
                                               }
        

                                               
        if(lstDeleteRenewalContractObject.size()>0)
        {
            delete lstDeleteRenewalContractObject;
            /*
            results.clear();
            results.dmlDelete(lstDeleteRenewalContractObject);
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
                */
        }
        
        
    }
    
    public void createRenewalContractProductObjects(Id OpportunityId, Map<String,Set<Contract_Product__c>> mapProductIdContractProducts ){
        
        List<Renewal_Contract_Product__c> lstInsertRenewalContractProducts = new List<Renewal_Contract_Product__c>();
        map<String, Id> mapRenewalContracts = new Map<String,Id>();
        
        for(Renewal_Contract_Object__c  rco : [SELECT Id,Contract__c,Opportunity__c FROM Renewal_Contract_Object__c WHERE Opportunity__c= : OpportunityId ]){
            mapRenewalContracts.put(rco.Contract__c+''+rco.Opportunity__c, rco.Id);
        }
        
        for( OpportunityLineItem oli : [SELECT Id,Product2Id,Product2.Name,Product2.Akam_Product_Id__c,PricebookEntryId,OpportunityId
                                        FROM OpportunityLineItem WHERE OpportunityId =: OpportunityId]){
                                            if(mapProductIdContractProducts.containsKey(oli.Product2.Akam_Product_Id__c)){
                                                for(Contract_Product__c conprod : mapProductIdContractProducts.get(oli.Product2.Akam_Product_Id__c) ){
                                                    Renewal_Contract_Product__c acp = new Renewal_Contract_Product__c();
                                                    acp.Name= oli.Product2.Akam_Product_Id__c;
                                                    acp.Opportunity_Product__c = oli.Id;
                                                    acp.Contract_Product__c =conprod.Id;
                                                    acp.Associated_Contract__c = mapRenewalContracts.get(conprod.Original_Contract_Id__c+''+oli.OpportunityId);
                                                    acp.End_Month__c= conprod.Effective_End_Date__c.year()+'-'+conprod.Effective_End_Date__c.month();
                                                    lstInsertRenewalContractProducts.add(acp);
                                                }
                                            }
                                        }
        
        if(lstInsertRenewalContractProducts.size()>0 )
        {
            insert lstInsertRenewalContractProducts;
            /*
            results.clear();
            results.dmlInsert(lstInsertRenewalContractProducts);
            results.withClassName('CreateRenewalOpptyWithMultipleContracts').insertRecordsInErrorLog();
            if(results.failurecount>0)
                errorOccured = true;
                */
        }
    }
    
    
    public List<OpportunitylineItem> createOpportunityProductsOnRefresh(Id opportunityId){
        
        List<string> lstEndMonth = new List<String>();
        Set<String> productIdList           = new Set<String>();
        Set<String> currencyList            = new Set<String>();
        List<OpportunityLineItem> opptyLineItemList   = new List<OpportunityLineItem>();
        Map<OpportunityLineItem,String> oLIToCurrencyReturnMap = new Map<OpportunityLineItem,String>();
        setOfContractProducts = new Set<Contract_Product__c>();
        Map<String,Id> productToPriceBookIdMap          = new Map<String,Id>();
        
        lstRenewalContractObjects =[SELECT Id,Contract__c,Opportunity__c,
                                    (SELECT Id,Opportunity_Product__c, Associated_Contract__c,End_Month__c,Contract_Product__c,Contract_Product__r.Effective_End_Date__c, Contract_Product__r.Deleted_From_Source__c 
                                     FROM Associated_Contract_Products__r) 
                                    FROM Renewal_Contract_Object__c WHERE Opportunity__c= : OpportunityId ];
        
        for(Renewal_Contract_Object__c  rco : lstRenewalContractObjects){
            mapRenewalContracts.put(rco.Contract__c+''+rco.Opportunity__c, rco.Id);
            for( Renewal_Contract_Product__c rcp :rco.Associated_Contract_Products__r){
                lstEndMonth.add(rcp.End_Month__c);
                if(rcp.Contract_Product__r.Deleted_From_Source__c){
                    mapDeleteContractProdOptyProd.put(rcp.Contract_Product__c,rcp.Opportunity_Product__c);
                }
                mapRenewalContractProducts.put(rcp.Associated_Contract__c+''+rcp.Contract_Product__c+''+rcp.Opportunity_Product__c, rcp);
            }
        }
         
        
        
        for(Merge_Contract_Header__c contract: contractList)
        {
            for(Contract_Product__c conProduct: contract.Contract_Products__r)
            {
                if((!conProduct.deleted_from_source__c)&& conProduct.Effective_End_Date__c!= null){
                    String endMonth =  conProduct.Effective_End_Date__c.year()+'-'+conProduct.Effective_End_Date__c.month();
                    //conproducts to be delted
                    if(lstEndMonth.contains(endMonth)){
                        setOfContractProducts.add(conProduct);
                        productIdList.add(conProduct.Forecast_Product_id__c);
                        if(mapProductIdContractProducts.containskey(conProduct.Forecast_Product_Id__c)){
                            mapProductIdContractProducts.get(conProduct.Forecast_Product_Id__c).add(conProduct);
                        }else{
                            List<Contract_Product__c> lstConProd = new List<Contract_Product__c>();
                            lstConProd.add(conProduct);
                            mapProductIdContractProducts.put(conProduct.Forecast_Product_Id__c,lstConProd);
                        }              
                    }
                }
            }
            currencyList.add(!String.isBlank(selectedOpportunityCurrency) ?selectedOpportunityCurrency:contract.Currency__c);
        }
        
        
        for(PricebookEntry pbe : [select Id,product2.Akam_Product_Id__c,currencyIsoCode from PricebookEntry where product2.Akam_Product_Id__c IN : productIdList and currencyIsoCode IN : currencyList and product2.IsActive = true]){
            productToPriceBookIdMap.put(pbe.product2.Akam_Product_Id__c+' - '+pbe.currencyIsoCode,pbe.Id);
        }
        
        oLIToCurrencyReturnMap = buildOpportunityLineItems(setOfContractProducts,productToPriceBookIdMap,opportunityId,contractList[0].Account_Name__r.OwnerId);
        
        
        for(OpportunitylineItem oli:oLIToCurrencyReturnMap.keySet())
        {
            opptyLineItemList.add(oli);
        }
        
        if(isContractOpptyCurrencyMismatch){
            setContractCurrency(contractCurrecnyList);
        }
        else
        {
            Set<String> contractCurrencySetTemp = new Set<String>();
            contractCurrencySetTemp.add(contractList[0].Currency__c);
            setContractCurrency(contractCurrencySetTemp);
            selectedOpportunityCurrency = contractList[0].Currency__c;
        }
        
        opptyLineItemList = GsmUtilClass.genericConvertLineItemCurrencies(opptyLineItemList,contractCurrecnyList,selectedOpportunityCurrency,opportunityCloseDate,oLIToCurrencyReturnMap);
        
        List<OpportunityLineItem> opptyListToReturn = new List<OpportunityLineItem>();
        
        opptyListToReturn = buildAggregateOpportunityLineItems(opptyLineItemList,opportunityId,contractList[0].Account_Name__r.OwnerId);
        
        
        return opptyListToReturn;
    }
    
    
    
    
    
    
    
    public List<OpportunitylineItem> createOpportunityProducts(Id opportunityId)
    {
        Set<String> productIdList           = new Set<String>();
        Set<String> currencyList            = new Set<String>();
        List<OpportunityLineItem> opptyLineItemList   = new List<OpportunityLineItem>();
        Map<OpportunityLineItem,String> oLIToCurrencyReturnMap = new Map<OpportunityLineItem,String>();
        setOfContractProducts = new Set<Contract_Product__c>();
        Map<String,Id> productToPriceBookIdMap          = new Map<String,Id>();
        
        for(Merge_Contract_Header__c contract: contractList)
        {
            for(Contract_Product__c conProduct: contract.Contract_Products__r)
            {
                setOfContractProducts.add(conProduct);
                productIdList.add(conProduct.Forecast_Product_id__c);
            }
            currencyList.add(!String.isBlank(selectedOpportunityCurrency) ?selectedOpportunityCurrency:contract.Currency__c);
        }
        
        
        for(PricebookEntry pbe : [select Id,product2.Akam_Product_Id__c,currencyIsoCode from PricebookEntry where product2.Akam_Product_Id__c IN : productIdList and currencyIsoCode IN : currencyList and product2.IsActive = true]){
            productToPriceBookIdMap.put(pbe.product2.Akam_Product_Id__c+' - '+pbe.currencyIsoCode,pbe.Id);
        }
        
        oLIToCurrencyReturnMap = buildOpportunityLineItems(setOfContractProducts,productToPriceBookIdMap,opportunityId,contractList[0].Account_Name__r.OwnerId);
        
        for(OpportunitylineItem oli:oLIToCurrencyReturnMap.keySet())
        {
            opptyLineItemList.add(oli);
        }
        if(isContractOpptyCurrencyMismatch)
            setContractCurrency(contractCurrecnyList);
        else
        {
            Set<String> contractCurrencySetTemp = new Set<String>();
            contractCurrencySetTemp.add(contractList[0].Currency__c);
            setContractCurrency(contractCurrencySetTemp);
            selectedOpportunityCurrency = contractList[0].Currency__c;
        }
        
        opptyLineItemList = GsmUtilClass.genericConvertLineItemCurrencies(opptyLineItemList,contractCurrecnyList,selectedOpportunityCurrency,opportunityCloseDate,oLIToCurrencyReturnMap);
        
        List<OpportunityLineItem> opptyListToReturn = new List<OpportunityLineItem>();
        
        opptyListToReturn = buildAggregateOpportunityLineItems(opptyLineItemList,opportunityId,contractList[0].Account_Name__r.OwnerId);
        
        
        return opptyListToReturn;
        
    }
    
    public  Map<OpportunityLineItem,String> buildOpportunityLineItems(Set<Contract_Product__c> setOfContractProducts,Map<String,Id> productToPriceBookIdMap, Id opportunityId,Id opptyOwnerId)
    {
        Map<OpportunityLineItem,String> oLIToCurrencyMap =  new Map<OpportunityLineItem,String>();
        Integer counter ;
        Boolean isPilotUserFlag = GsmUtilClass.isPilotUser(opptyOwnerId); // SFDC-6409
        if(opportunityId!=null)
        {
            counter = 0;
            for(Contract_Product__c conProduct : setOfContractProducts)
            {
                if(productToPriceBookIdMap.containsKey(conProduct.Forecast_Product_Id__c+' - '+selectedOpportunityCurrency) || productToPriceBookIdMap.containsKey(conProduct.Forecast_Product_Id__c+' - '+conProduct.original_Contract_id__r.Currency__c))
                {
                    OpportunityLineItem oli = new OpportunityLineItem();
                    //oli.OpportunityId=opportunityId;
                    oli.Quantity=1;
                    //SFDC-1957 - Setting Usage/Commit and Unit Price to 0 for pilot users
                    oli.Average_Renewal_Commit_MRR__c=conProduct.Average_Renewal_Commit_MRR__c;
                    oli.Average_Renewal_Usage_MRR__c=conProduct.Average_Renewal_Usage_MRR__c;
                    oli.Contract_Promo_Code__c = conProduct.ZOFF_Promo_Check__c; // Added by Rajesh SFDC-7061
                    oli.UnitPrice=conProduct.UnitPrice__c;
                    oli.Description = string.valueof(counter);
                    counter++;
                    //oli.Validation_Override__c=true;
                    String conProductCurrency = conProduct.original_Contract_id__r.Currency__c;
                    
                    if(!String.isBlank(selectedOpportunityCurrency)){// && !conProduct.original_Contract_id__r.Currency__c.equalsIgnoreCase(selectedOpportunityCurrency)){}
                        oli.pricebookEntryId = productToPriceBookIdMap.get(conProduct.Forecast_Product_Id__c+' - '+selectedOpportunityCurrency);
                    }
                    else{
                        oli.pricebookEntryId=productToPriceBookIdMap.get(conProduct.Forecast_Product_Id__c+' - '+conProduct.original_Contract_id__r.Currency__c);
                    }
                    
                    oLIToCurrencyMap.put(oli,conProductCurrency);
                }
            }
            
        }
        return oLIToCurrencyMap;
        
    }
    
    public List<OpportunitylineItem> buildAggregateOpportunityLineItems(List<OpportunitylineItem> opptyLineItemList,Id OpptyId ,Id opptyOwnerId)//,Set<Contract_Product__c> setOfContractProducts,Map<String,Id> productToPriceBookIdMap)
    {
        Map<String,List<OpportunityLineItem>> mapOfPriceBookEntryIdToLineItems = new Map<String,List<OpportunityLineItem>>();
        List<OpportunitylineItem> buildOPLIRecordList;
        List<OpportunitylineItem> finalOLIList = new List<OpportunitylineItem>();
        Boolean isPilotUserFlag = GsmUtilClass.isPilotUser(opptyOwnerId);
        
        for(OpportunityLineItem oli:opptyLineItemList)
        {
            if(mapOfPriceBookEntryIdToLineItems.containsKey(oli.pricebookEntryId))
            {
                mapOfPriceBookEntryIdToLineItems.get(oli.pricebookEntryId).add(oli);
            }
            else
            {
                buildOPLIRecordList = new List<OpportunitylineItem>();
                buildOPLIRecordList.add(oli);
                mapOfPriceBookEntryIdToLineItems.put(oli.pricebookEntryId,buildOPLIRecordList);
            }
        }
        
        for(String currencyKey :mapOfPriceBookEntryIdToLineItems.keySet())
        {
            OpportunityLineItem oliRecord = new OpportunityLineItem();
            oliRecord = mapOfPriceBookEntryIdToLineItems.get(currencyKey)[0];
            Decimal unitPrice = 0;
            Decimal renewalCommit = 0;
            Decimal renewalUsage = 0;
            
            for(OpportunitylineItem oli : mapOfPriceBookEntryIdToLineItems.get(currencyKey))
            {
                if(oli.UnitPrice != null)
                    unitPrice+=oli.UnitPrice;
                if(oli.Average_Renewal_Commit_MRR__c != null)
                    renewalCommit+=oli.Average_Renewal_Commit_MRR__c;
                if(oli.Average_Renewal_Usage_MRR__c != null)
                    renewalUsage+=oli.Average_Renewal_Usage_MRR__c;
            }
            
            oliRecord.OpportunityId = OpptyId;
            oliRecord.Quantity=1;
            oliRecord.UnitPrice = unitPrice;
            oliRecord.Average_Renewal_Commit_MRR__c =  renewalCommit;
            oliRecord.Average_Renewal_Usage_MRR__c = renewalUsage;
            oliRecord.Description = '';
            oliRecord.Validation_Override__c=true;
            
            finalOLIList.add(oliRecord);
        }
        return finalOLIList;
    }
    
}