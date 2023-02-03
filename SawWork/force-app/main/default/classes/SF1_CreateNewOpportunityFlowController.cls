/**
 * Extension controller for Lightning JS Controller:: SF1_OpportunityFlow
 * This controller ports 'Create Opportunity from Contracts' functionality of 'OpportunityCreateNew' controller class.
 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Ali KM          Jun/2017     Created Class as part of MOB-15

 **/
global class SF1_CreateNewOpportunityFlowController {

    @AuraEnabled
    public static Opportunity createRenewalOpportunityWithProducts( String[] selectedContractIds, String selectedCurrency, String selectedOpptyType){
      System.debug('selectedContractIds'+selectedContractIds);
      System.debug('selectedCurrency'+selectedCurrency);
      System.debug('selectedOpptyType'+selectedOpptyType);

      List<Contract_Product__c> lstContractProducts = new List<Contract_Product__c>();
      List<OpportunityLineItem> lstOpptyLineItems = new List<OpportunityLineItem>();
      List<OpportunityLineItem> lstInsertOpptyLineItems = new List<OpportunityLineItem>();
      List<String> lstContractCurrency= new List<String>();
      Set<String> setOriginalContractIds = new  Set<String>();
      List<String> lstAllCurrency = new List<String>();
      string selectedOpportunityCurrency ='';
      Map<String,Id> mapProductCurrencyPricebookId = new Map<String,Id>();
      Map<OpportunityLineItem,String> mapOptyLineItemCurrency = new   Map<OpportunityLineItem,String>();
      Map<String,Set<Contract_Product__c>> mapProductIdContractProducts = new Map<String,Set<Contract_Product__c>>();
      Opportunity objNewOppty = new Opportunity();


      try{
        lstContractProducts =  [SELECT Id,Name,UnitPrice__c,Forecast_Product_Id__c,Average_Renewal_Commit_MRR__c,Average_Renewal_Usage_MRR__c,Effective_Start_Date__c,Effective_End_Date__c,ZOFF_Promo_Check__c,
                                Original_Contract_Id__c, Original_Contract_Id__r.Original_Contract_Id__c,Original_Contract_Id__r.CurrencyIsoCode,
                                Original_Contract_Id__r.Account_Name__c,Original_Contract_Id__r.Account_Name__r.OwnerId,Original_Contract_Id__r.Currency__c
                                FROM Contract_Product__c 
                                WHERE Id in:selectedContractIds];                                                                  

        for(Contract_Product__c conprod : lstContractProducts){
            lstContractCurrency.add(conprod.Original_Contract_Id__r.Currency__c);

            lstAllCurrency.add((selectedCurrency!=null && !selectedCurrency.contains('none')) ?selectedCurrency: conprod.Original_Contract_Id__r.Currency__c);

            setOriginalContractIds.add(conprod.Original_Contract_Id__r.Original_Contract_Id__c);
            if(mapProductIdContractProducts.containskey(conprod.Forecast_Product_Id__c)){
                mapProductIdContractProducts.get(conprod.Forecast_Product_Id__c).add(conprod);
            }else{
                Set<Contract_Product__c> setConProd = new Set<Contract_Product__c>();
                setConProd.add(conprod);
                mapProductIdContractProducts.put(conprod.Forecast_Product_Id__c,setConProd);
            }
        }

        System.debug('lstContractCurrency'+lstContractCurrency) ;
        System.debug('lstAllCurrency'+lstAllCurrency) ;


        CreateRenewalOpptyWithMultipleContracts roc= new CreateRenewalOpptyWithMultipleContracts(new List<String>(setOriginalContractIds),selectedContractIds);
        //public CreateRenewalOpptyWithMultipleContracts(List<String> originalContractIds, List<String> selectedContractIds)


        if(selectedCurrency!=null && !selectedCurrency.contains('none')){
          system.debug('selectedCurrency not null'+ selectedCurrency);
          roc.setOpportunityCurrency(selectedCurrency);
        }
        roc.setContractCurrency(new set<string>(lstContractCurrency));
        string destCurrency = roc.setDestinationCurrency();

        objNewOppty = roc.buildOpportunityRecord(selectedOpptyType);
        System.debug('objNewOppty'+objNewOppty) ;
        insert objNewOppty; 

        roc.createRenewalContractObjects(objNewOppty.Id);

        system.debug('mapProductIdContractProducts'+mapProductIdContractProducts);
        system.debug('lstContractCurrency'+lstContractCurrency);

        for(PricebookEntry pbe : [SELECT Id,product2.Akam_Product_Id__c,currencyIsoCode 
                                    FROM PricebookEntry 
                                    WHERE product2.Akam_Product_Id__c IN : mapProductIdContractProducts.keySet() AND currencyIsoCode IN :lstAllCurrency AND product2.IsActive = true]){
            
            System.debug('map variable' +pbe.product2.Akam_Product_Id__c+' - '+pbe.currencyIsoCode+  ' Id ' +pbe.Id);
                                      mapProductCurrencyPricebookId.put(pbe.product2.Akam_Product_Id__c+' - '+pbe.currencyIsoCode,pbe.Id);
        }
        system.debug('mapProductCurrencyPricebookId'+mapProductCurrencyPricebookId);

        Id AccountOwnerId = lstContractProducts[0].Original_Contract_Id__r.Account_Name__r.OwnerId;


        // private Map<OpportunityLineItem,String> buildOpportunityLineItems(Set<Contract_Product__c> setOfContractProducts,Map<String,Id> productToPriceBookIdMap, Id opportunityId,Id opptyOwnerId)

        mapOptyLineItemCurrency = roc.buildOpportunityLineItems(new set<Contract_Product__c> (lstContractProducts), mapProductCurrencyPricebookId,objNewOppty.Id,AccountOwnerId);

        lstOpptyLineItems = new List<OpportunityLineItem> (mapOptyLineItemCurrency.keyset());

        system.debug('selectedCurrency'+selectedCurrency);
        system.debug('lstContractCurrency'+lstContractCurrency);
        System.debug('objNewOppty.Closedate'+objNewOppty.Closedate);
        system.debug('mapOptyLineItemCurrency'+mapOptyLineItemCurrency);



        //public static List<OpportunityLineItem> genericConvertLineItemCurrencies(List<OpportunityLineItem> listOfLineItems, Set<String> sourceCurrency,String destinationCurrency, Datetime closeDate,Map<OpportunityLineItem,String> oLIToCurrencyMap)
        GsmUtilClass.genericConvertLineItemCurrencies(lstOpptyLineItems,new set<String>(lstContractCurrency),destCurrency,objNewOppty.Closedate,mapOptyLineItemCurrency);

        lstInsertOpptyLineItems = roc.buildAggregateOpportunityLineItems(lstOpptyLineItems,objNewOppty.Id,AccountOwnerId);

        for(OpportunitylineItem newOLI : lstInsertOpptyLineItems)
            {
                if(newOLI.UnitPrice == null)
                newOLI.UnitPrice = 0.00;
                //SFDC-7056
                if(selectedOpptyType == 'Auto-Renewal'){
                  newOLI.Projected_Monthly_commit_fees__c = newOLI.Average_Renewal_Commit_MRR__c;
                  newOLI.Projected_Avg_Rev_Non_Commit__c  = newOLI.Average_Renewal_Usage_MRR__c;
                  newOLI.MRR__c = 0.00;
                  newOLI.EMRI__c = 0.00;
                }
                
                if(newOLI.Projected_Monthly_commit_fees__c ==null)
                  newOLI.Projected_Monthly_commit_fees__c = 0.00;
                if(newOLI.Projected_Avg_Rev_Non_Commit__c ==null)
                  newOLI.Projected_Avg_Rev_Non_Commit__c = 0.00;

            }
        insert lstInsertOpptyLineItems;

        roc.createRenewalContractProductObjects(objNewOppty.Id,mapProductIdContractProducts);

        /*
        System.Debug('Before errorOccured');
        if(roc.errorOccured)
        {
          return null;
        }
        System.Debug('After errorOccured');
        */
        objNewOppty = [Select Id,OwnerId, CreatedById From Opportunity Where Id =: objNewOppty.Id];

        return objNewOppty;
    }
    catch(Exception e){
      sawyer.saw(e);
      throw new AuraHandledException(e.getMessage());
    }
    }

    @AuraEnabled
    public static Opportunity createRenewalOpportunityFromContracts(String[] selectedContractIds, String selectedCurrency, Boolean isContractCurrencyMismatch, String selectedOpptyType) {

      System.debug('selectedContracts:' + Json.serialize(selectedContractIds) + '; curr:' + selectedCurrency + '; isContractCurrencyMismatch:' + isContractCurrencyMismatch);
      List<String> listOfOriginalContractIds = new List<String>();
      Set<String> contractCurrencyList = new Set<String>();
      String firstCurrency = null;
      for(Merge_Contract_Header__c mch : [Select Id, Name, Original_Contract_Id__c, Currency__c from Merge_Contract_Header__c where Id IN : selectedContractIds])
      {
        if (firstCurrency==null)
          firstCurrency = mch.Currency__c;
        listOfOriginalContractIds.add(mch.Original_Contract_Id__c);
        contractCurrencyList.add(mch.Currency__c);
      }

      //SFDC-1394
      CreateRenewalOpptyWithMultipleContracts roc= new CreateRenewalOpptyWithMultipleContracts(listOfOriginalContractIds);

      // SFDC-1425
      // @todo: Need to move this to JS cntrllr
      // selectedcurrencyOption.containsIgnoreCase('Other Currency') &&
      if(selectedCurrency!=null && !selectedCurrency.contains('none')) {

        roc.setOpportunityCurrency(selectedCurrency);
        roc.setContractCurrency(contractCurrencyList);

      } else{

          roc.setContractCurrency(contractCurrencyList);

      }

      Opportunity opptyCreated;
      opptyCreated = roc.createRenewalOpportunityWithProducts(selectedOpptyType); //SFDC-SFDC-3550 : Passed Parameter

      System.Debug('Before errorOccured');
      if(roc.errorOccured)
      {
        return null;
      }

       System.Debug('After errorOccured');
      opptyCreated = [Select Id,OwnerId, CreatedById From Opportunity Where Id =: opptyCreated.Id];

      return opptyCreated;

    }

    public class AmgWrapper{
      @AuraEnabled public boolean skipIntermediatePage {get; set;}
      @AuraEnabled public integer amgCloseDateDays {get; set;}
      public AmgWrapper(){
        skipIntermediatePage = false;
        amgCloseDateDays = 0;
      }
    }

    @AuraEnabled
    public static Map<string,list<string>> getOpptyTypesBasedOnContractBaseline(){
      Map<string,list<string>> opptyTypeMap = new Map<string,list<string>>();
      opptyTypeMap.put(GsmUtilClass.getGSMSettingValue('ContractBaseLineOptionWith').toLowerCase(),GsmUtilClass.getGSMSettingValue('OpptyTypesWithContractBaseline').split(','));
      opptyTypeMap.put(GsmUtilClass.getGSMSettingValue('ContractBaseLineOptionWithout').toLowerCase(),GsmUtilClass.getGSMSettingValue('OpptyTypesWithoutContractBaseline').split(','));
      opptyTypeMap.put(GsmUtilClass.getGSMSettingValue('CreateContractChangeOppty').toLowerCase(),new List<string>{'Contract Change'});
      return opptyTypeMap;
    }

    @AuraEnabled
    public static AmgWrapper skipIntermediatePageForOpptyCreation(){
      AmgWrapper amgWrap = new AmgWrapper();
      String SkipIntermediateOpptyCreationPage = GsmUtilClass.getGSMSettingValue('SkipIntermediateOpptyCreationPage');
      if(SkipIntermediateOpptyCreationPage.contains(UserInfo.getProfileId()))
        amgWrap.skipIntermediatePage = true;
      amgWrap.amgCloseDateDays = Integer.valueOf(GsmUtilClass.getGSMSettingValue('OppTrigger_bi_amgCloseDateDays'));
      return amgWrap;
    }

    @AuraEnabled
    public static string createPaperPOC(string contractId, string accountId){
        String originalContractId = '';
        String returnVal = '';
        String contractEndDate = '';
        //VC Validations - SFDC-6364
        String vcStatus = '';
        Boolean vcOverride ;
        String errorMessage = '';
        if(contractId != null && contractId != ''){
          Merge_Contract_Header__c contractHeader = [select Id, Original_Contract_Id__c, Effective_End_Date__c,Account_Name__r.ECUSTOMS__RPS_Status__c,Account_Name__r.Override_Visual_Compliance__c from Merge_Contract_Header__c where id =: contractId];
          //Merge_Contract_Header__c contractHeader = [select Id, Original_Contract_Id__c, Effective_End_Date__c from Merge_Contract_Header__c where id =: contractId];
          if(contractHeader != null){
            originalContractId = contractHeader.Original_Contract_Id__c;
            contractEndDate = String.valueOf(contractHeader.Effective_End_Date__c);
            vcStatus = contractHeader.Account_Name__r.ECUSTOMS__RPS_Status__c;
            vcOverride = contractHeader.Account_Name__r.Override_Visual_Compliance__c; 
          }
        }
        system.debug('VC Status '+vcStatus +' VC Override '+vcOverride);
        //SFDC-6364
          if(GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Red').split(',').contains(vcStatus) && !vcOverride)
            {
              errorMessage = 'ERROR:' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Red');
              return errorMessage;
            }
          if(GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Pending').split(',').contains(vcStatus) && !vcOverride)
            {
              errorMessage = 'ERROR:' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Pending');
                return errorMessage;
            }
          if(GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_DS_Alert').split(',').contains(vcStatus) && !vcOverride )
            {
              errorMessage = 'ERROR:' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_DS_Alert');
                return errorMessage;
            }
        system.debug('Error Message '+errorMessage);
        Opportunity paperPoc = new Opportunity();
        paperPoc.Name = 'Contract Change for '+originalContractId+' expiring '+contractEndDate;
        paperPoc.CloseDate = Date.today().addDays(10);
        paperPoc.StageName = '5. Negotiate';
        paperPoc.Deal_Type__c = 'Direct';
        paperPoc.AccountId = accountId;
        paperPoc.Opportunity_Type__c = 'Contract Change';
        paperPoc.Validation_Override__c = true;
        try {
          insert paperPoc;
          /* SFDC-4178
            Order_Approval__c manualTrialOA = new Order_Approval__c();
            manualTrialOA.Associated_Opportunity__c = manualTrialOppty.Id;
            manualTrialOA.CCG_Owner__c = UserInfo.getUserId();
            insert manualTrialOA;
            */
            String orderAppId = OrderApprovalClass.Create_OrderApproval(paperPoc.Id, paperPoc.RecordTypeId, paperPoc.StageName, '');
            //returnVal = manualTrialOA.Id;
            returnVal = orderAppId.split(':')[1];
            //returnVal += ',' + GSMLite_UtilClass.getUIThemeDescription();
        }
        catch(Exception e) {
          Error_log__c erroLog = new Error_log__c(Name = 'PaperPOC Opportunity Creation', Class__c = 'SF1_CreateNewOpportunityFlowController', Error_Message__c = e.getMessage());
          insert erroLog;
          returnVal = 'ERROR';
        }
        return returnVal;
    }
}