global without sharing class RenewalOpportunityCreationClass implements Database.Batchable<Sobject>,Database.Stateful{
  public List<Merge_Contract_Header__c> contractList=null;
  //SFDC-6398
    public Map<Id,List<Contract_Product__c>> contractIdContractProductsMap=null;
    public Map<Id,Boolean> mchToAutoRenewMap = null;
    private Boolean isMonthlyAutomatedJob=true;
    public Map<String,Opportunity> contractToOpportunityMap =null;
    global String returnMessage {get;set;} 
    //private Map<Id, Decimal> contractIdToMRR = new Map<Id, Decimal>();
    //private DMLResults results = new DMLResults(true);
    global DMLResults resultsOppty = new DMLResults(true);
    global DMLResults resultsOLI = new DMLResults(true);
    global DMLResults resultsContract = new DMLResults(true);
    global DMLResults resultsContractProduct = new DMLResults(true);

    private String selectedOpportunityCurrency;
    private Datetime opportunityCloseDate;
    private String contractCurrency;

    Map<String, Merge_Contract_Header__c> idToContractMap;
    Map<String, List<Contract_Product__c>> contractIdAndDtToContractProduct;
    Map<String, List<Contract_Product__c>> dateToContractProduct;
    List<Renewal_Contract_Object__c> listOfRenewalContractObjects;
    Map<Id, List<OpportunityLineItem>> MapOpptyIdToOpportunityLineItemList;
    Map<Id, Contract_Product__c> idToContractProductMap;
    Map<Merge_Contract_Header__c, List<Contract_Product__c>> contractToContractProductMap;

  
  global RenewalOpportunityCreationClass()
  {
    returnMessage='Renewal Opportunity Ids inserted : ';
  }
  //SFDC-6398
  /*
  global RenewalOpportunityCreationClass (List<Merge_Contract_Header__c> pContractList,Map<Id,Boolean> pmchToAutoRenewMap)
  {
    this.contractList=pContractList;
    this.mchToAutoRenewMap = pmchToAutoRenewMap;
  }
  global RenewalOpportunityCreationClass(List<String> originalContractIds)
  {
    contractList= [Select Id
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
                              //SFDC-1425
                              ,Opportunity_Name__r.CloseDate
                              ,Parent_Contract__c
                              ,Order_Id__c
                          //SFDC-6398
                          , Auto_Renew__c 
                              ,Opportunity_Name__r.Opportunity_Type__c
                              ,Opportunity_Name__r.Auto_Renewal__c
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
                                       //SFDC-1425
                                       ,original_Contract_id__r.Effective_End_Date__c
                                       ,ZOFF_Promo_Check__c // SFDC-7061
                              from Contract_Products__r where Deleted_From_Source__c = false)
                           from Merge_Contract_Header__c
                          Where original_contract_Id__c in :originalContractIds];

  }

  global RenewalOpportunityCreationClass(String originalContractId, opportunity opportunityId)
  {
    this(new List<String> {originalContractId});
    contractToOpportunityMap = new Map<String,Opportunity>();
    contractToOpportunityMap.put(originalContractId,opportunityId);  
  }

  global RenewalOpportunityCreationClass(String originalContractId)
  {
    this(new List<String> {originalContractId});
  }

    global RenewalOpportunityCreationClass(String originalContractId, Boolean isMonthlyAutomatedJobParam)
    {
    this(new List<String> {originalContractId});
        isMonthlyAutomatedJob = isMonthlyAutomatedJobParam;
    }
  */ 
  global Database.QueryLocator start(Database.BatchableContext BC)
  {
      Date startMonthDate = Date.Today().addMonths(Integer.valueOf(GsmUtilClass.getGSMSettingValue('Renewal_Opportunity_Process_Month')));
      Date startMonthFirstDate = Date.newInstance(startMonthDate.year(),startMonthDate.month(),1);
      Date stopMonthDate = Date.today().addMonths(Integer.valueOf(GsmUtilClass.getGSMSettingValue('Renewal_Opportunity_Process_Month')) + 6);
      Date stopMonthFirstDate= Date.newInstance(stopMonthDate.year(),stopMonthDate.month(),1);

      return Database.getQueryLocator([Select Id
                                      ,Account_Name__r.Name
                                      ,Account_Name__r.OwnerId
                                      ,Opportunity_Name__r.Partner_Involved__c
                                      ,Opportunity_Name__r.currencyIsoCode
                                      ,CurrencyIsoCode
                                      ,Opportunity_Name__r.Deal_Type__c
                                      ,Effective_End_Date__c
                                              ,Currency__c
                                              ,Opportunity_Name__r.Partner_Involved__r.Akam_Account_Id__c
                                      ,original_contract_id__c
                                      //SFDC-1394
                                        ,Parent_Contract__c
                                    ,Order_Id__c
                                    ,AK_Cancellation_Clause__c
                                    ,Contract_Type__c
                                    //SFDC-6398
                                    ,Auto_Renew__c
                                    ,Opportunity_Name__r.Opportunity_Type__c
                                    ,Opportunity_Name__r.Auto_Renewal__c
                                    ,Parent_Account_Name__c
                                    ,Account_Name__r.ECUSTOMS__RPS_Status__c
                                    ,Account_Name__r.Override_Visual_Compliance__c
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
                                                       //SFDC-1425
                                                       ,original_Contract_id__r.Effective_End_Date__c, Effective_End_Date__c
                                                       ,ZOFF_Promo_Check__c // Rajesh - SFDC-7061
                                      from Contract_Products__r where Deleted_From_Source__c = false and Effective_End_Date__c >= :startMonthFirstDate and Effective_End_Date__c < :stopMonthFirstDate and Effective_End_Date__c != null)
                                   from Merge_Contract_Header__c
                    where Contract_Product_Count__c > 0] );
     // and Double_Invoice_Review__c = True and Auto_Renew__c != 'Mutual Consent']);

  }
  global void execute(Database.BatchableContext BC, List<sObject> scope)
  {
     OpportunityTriggerClass.checkForDuplicateRenewalOpportunity=true; 
     //List<Merge_Contract_Header__c>
     contractList=(List<Merge_Contract_Header__c>)scope; 

     //SFDC-3255
     /*
     if(isMonthlyAutomatedJob)
     {
      contractList = checkForExistingOpportunities(contractList);
     }*/
     //End of SFDC-3255
     contractToContractProductMap = new Map<Merge_Contract_Header__c, List<Contract_Product__c>>();
     contractToContractProductMap = checkDuplicateOpportunity(contractList);
     System.debug('contractToContractProductMap:'+contractToContractProductMap+' Size:'+ contractToContractProductMap.size());
     if(contractToContractProductMap.size() > 0) 
       {
         //SFDC-6398 Populate the map to identify contract for Auto Renewal based on Auto Renew Clause
         mchToAutoRenewMap = new Map<Id,Boolean>();
         List<String> autoRenewalClause = GsmUtilClass.getGSMSettingValue('AutoRenewalContractClause').split(',');
         for( Merge_Contract_Header__c mchRec : contractToContractProductMap.keyset())
          {
            /*
            Boolean isAutoRenewalOppty = false;
            for(String autoRenRec : autoRenewalClause)
              {
                if(autoRenRec == mchRec.Auto_Renew__c)
                  {
                    isAutoRenewalOppty = true;
                    mchToAutoRenewMap.put(mchRec.Id,isAutoRenewalOppty);
                  }
              }*/
            
            if(autoRenewalClause.contains(mchRec.Auto_Renew__c)){
              mchToAutoRenewMap.put(mchRec.Id, true);
            }
          }
         //RenewalOpportunityCreationClass renOppCreate=new RenewalOpportunityCreationClass(contractList,mchToAutoRenewMap);
         List<Opportunity> opptylist = createRenewalOpportunityWithProducts();
         List<Id> opptyIdList=new List<Id>();
         for(Opportunity opp : opptylist)
         {
          opptyIdList.add(opp.id);
         }
         returnMessage=returnMessage+String.join(opptyIdList,',')+'\n';
       }
  }
  global void finish(Database.BatchableContext BC)
  {
    List<Cron_Batch_Run__c> cronBatchRunList=[select Id,results__c from Cron_Batch_Run__c where trigger_batch_run__c = true and cron_batch_job__r.Name='Renewal Process' order by lastModifiedDate desc];
    if(cronBatchRunList!=null && cronBatchRunList.size()>0)
    {
      Cron_Batch_Run__c cronBatchRun=cronBatchRunList[0];
      cronBatchRun.results__c=returnMessage;
      update cronBatchRun;
    }
    //SFDC-6398 - Added error logging and email
    resultsOppty.withClassName('RenewalOpportunityCreationClass').withJobName('Renewal Opportunity Creation Process').insertRecordsInErrorLog();
    resultsOppty.withJobName('Renewal Opportunity Creation Process').toAddress(GsmUtilClass.getGSMSettingValue('AutoRenewalBatchEmailList')).sendLogMail();

    resultsOLI.withClassName('RenewalOpportunityCreationClass').withJobName('Renewal Opportunity Line Item Creation Process').insertRecordsInErrorLog();
    resultsOLI.withJobName('Renewal Opportunity Line Item Creation Process').toAddress(GsmUtilClass.getGSMSettingValue('AutoRenewalBatchEmailList')).sendLogMail();

    resultsContract.withClassName('RenewalOpportunityCreationClass').insertRecordsInErrorLog();
    resultsContract.withJobName('Renewal Opportunity associated contract Creation Process').toAddress(GsmUtilClass.getGSMSettingValue('AutoRenewalBatchEmailList')).sendLogMail();

    resultsContractProduct.withClassName('RenewalOpportunityCreationClass').insertRecordsInErrorLog();
    resultsContractProduct.withJobName('Renewal Opportunity associated contract product Creation Process').toAddress(GsmUtilClass.getGSMSettingValue('AutoRenewalBatchEmailList')).sendLogMail();

  }

    // called from renewal monthly job and opportunity create new wizard
    public List<Opportunity> createRenewalOpportunityWithProducts()
    {
      List<Opportunity> renewalOpptyList=new List<Opportunity>();
      //List<Id> contractIdList = New List<Id>();

      contractIdAndDtToContractProduct = new Map<String, List<Contract_Product__c>>();
      dateToContractProduct = new Map<String, List<Contract_Product__c>>();
      idToContractMap = new Map<String, Merge_Contract_Header__c>();
      idToContractProductMap = new Map<Id, Contract_Product__c>();

      for(Merge_Contract_Header__c mch : contractToContractProductMap.keyset()){
        idToContractMap.put(mch.Original_Contract_Id__c, mch);
        for(Contract_Product__c cp : contractToContractProductMap.get(mch)){
          idToContractProductMap.put(cp.id, cp);
          String dateString = cp.Effective_End_Date__c.year() + '-' + cp.Effective_End_Date__c.month();//2021-08
          System.debug('dateString Inside for:'+dateString);
          if(dateToContractProduct.containsKey(dateString)){
            dateToContractProduct.get(dateString).add(cp);
          }
          else{
            dateToContractProduct.put(dateString, new List<Contract_Product__c>{cp});
          }
        }
        System.debug('dateToContractProduct Inside for:'+dateToContractProduct);
        for(String dtString : dateToContractProduct.keyset()){
          contractIdAndDtToContractProduct.put(mch.Original_Contract_Id__c+':'+dtString, dateToContractProduct.get(dtString));
        }
      }
      System.debug('contractIdAndDtToContractProduct Inside for:'+contractIdAndDtToContractProduct);
      if(contractIdAndDtToContractProduct.size() > 0){
        renewalOpptyList.addAll(buildOpportunityRecord(contractIdAndDtToContractProduct));
      }

      if(renewalOpptyList.size()>0)
      {
          /*results.clear();
          results.dmlInsert(renewalOpptyList);
          results.withClassName('RenewalOpportunityCreationClass').withJobName('createRenewalOpportunityWithProducts').insertRecordsInErrorLog();
          results.withClassName('RenewalOpportunityCreationClass').withJobName('Renewal Opportunity Creation Process').insertRecordsInErrorLog();
          results.withJobName('Renewal Opportunity Creation Process').toAddress(GsmUtilClass.getGSMSettingValue('AutoRenewalBatchEmailList')).sendLogMail();*/
          ByPassAndLimitUtils.disable('disableChannelManagerLogicRenewalBatchJob');
          resultsOppty.dmlInsert(renewalOpptyList);
          contractToOpportunityMap = new Map<String, opportunity>();

        for(Opportunity opp : renewalOpptyList)
        {
          String dateString = opp.closeDate.year() + '-' + opp.closeDate.month();
          contractToOpportunityMap.put(opp.Renew_Contract_Id_Text__c+ ':' +dateString, opp);
          System.debug('contractToOpportunityMap:'+contractToOpportunityMap);
        }
        createOpportunityProducts();
        //SFDC-1394
        createRenewalContractObjects();
        createAssociatedRenewalContractObjects();
      }
        return renewalOpptyList;
    }

    //SFDC-1394
    public void createRenewalContractObjects()
    {
      listOfRenewalContractObjects = new List<Renewal_Contract_Object__c>();
      for(String contractIdWithDate : contractIdAndDtToContractProduct.keyset())
      {
        System.debug('contractIdWithDate::createRenewalContractObjects:'+contractIdWithDate);
        Renewal_Contract_Object__c renewalContract    = new Renewal_Contract_Object__c();
        Merge_Contract_Header__c contractDetail = idToContractMap.get(contractIdWithDate.split(':')[0]);
        System.debug('contractDetail:'+contractDetail);
        renewalContract.Name = contractDetail.Original_Contract_Id__c;
        renewalContract.Contract__c = contractDetail.Id;
        renewalContract.Opportunity__c = contractToOpportunityMap.get(contractIdWithDate).id;
        renewalContract.Contract_Id_Text__c = contractDetail.Original_Contract_Id__c;
        renewalContract.Contract_Effective_End_Date__c  = contractToOpportunityMap.get(contractIdWithDate).closeDate;
        renewalContract.Parent_Contract__c = contractDetail.Parent_Contract__c;
        renewalContract.Order_Id__c = contractDetail.Order_Id__c;
        //renewalContract.Cancellation_Clause__c      = contract.AK_Cancellation_Clause__c;
        renewalContract.Contract_Type__c = contractDetail.Contract_Type__c;
        renewalContract.Parent_Account_Name__c = contractDetail.Parent_Account_Name__c;
        listOfRenewalContractObjects.add(renewalContract);
      }
      if(listOfRenewalContractObjects.size()>0)
      {
        /*results.clear();
        results.dmlInsert(listOfRenewalContractObjects);
        results.withClassName('RenewalOpportunityCreationClass').insertRecordsInErrorLog();*/
        resultsContract.dmlInsert(listOfRenewalContractObjects);
        //resultsContract.add(Database.insert(listOfRenewalContractObjects,false),listOfRenewalContractObjects);
      }

    }

    public void createAssociatedRenewalContractObjects(){
      List<Renewal_Contract_Product__c> rcpList = new List<Renewal_Contract_Product__c>();
      for(Renewal_Contract_Object__c renewalContractObject : listOfRenewalContractObjects){
        if(renewalContractObject.get('Id') != null && MapOpptyIdToOpportunityLineItemList != null){
          for(OpportunitylineItem oliDetails : MapOpptyIdToOpportunityLineItemList.get(renewalContractObject.Opportunity__c)){
            Renewal_Contract_Product__c acp = new Renewal_Contract_Product__c();
            acp.Associated_Contract__c = renewalContractObject.id;
            acp.Opportunity_Product__c = oliDetails.id;
            Contract_Product__c conProd = idToContractProductMap.get(Id.valueOf(oliDetails.Comments__c));
            acp.Contract_Product__c = conProd.id;
            //acp.End_Date__c = conProd.Effective_End_Date__c;
            if(conProd.Effective_End_Date__c != null){
              acp.End_Month__c = conProd.Effective_End_Date__c.year()+'-'+conprod.Effective_End_Date__c.month();
            }
            acp.name = conProd.Forecast_Product_id__c;
            rcpList.add(acp);
          }
        }
      }
      if(rcpList.size() > 0){
        List<Contract_Product__c> updateContractProductList = new List<Contract_Product__c>();
        resultsContractProduct.dmlInsert(rcpList);
      }
    }

    public void createOpportunityProducts()
    {
      List<String> productIdList=new List<String>();
      List<String> currencyList=new List<String>();

      for(Merge_Contract_Header__c contract: contractToContractProductMap.keyset())
      {
          for(Contract_Product__c conProduct: contractToContractProductMap.get(contract))
          {
            productIdList.add(conProduct.Forecast_Product_id__c);
            //SFDC-1425
            if(String.isNotBlank(selectedOpportunityCurrency) && !contract.Currency__c.equalsIgnoreCase(selectedOpportunityCurrency))
                currencyList.add(selectedOpportunityCurrency);
            else
              currencyList.add(contract.Currency__c);
          }
      }

      List<PricebookEntry> priceBookEntryList=[select Id, product2.Akam_Product_Id__c, currencyIsoCode
                                                from PricebookEntry where product2.Akam_Product_Id__c IN : productIdList
                                                and currencyIsoCode IN : currencyList];

      Map<String,Id> productToPriceBookIdMap=new Map<String,Id>();

      for(PricebookEntry pbe : priceBookEntryList)
      {
          productToPriceBookIdMap.put(pbe.product2.Akam_Product_Id__c+' - '+pbe.currencyIsoCode,pbe.Id);
      }

      List<OpportunityLineItem> opptyLineItemList = new List<OpportunityLineItem>();

      for(Merge_Contract_Header__c contract: contractToContractProductMap.keyset())
      {
        //SFDC-6398- Checking if Oppty is Auto Renew then Baseline Commit,Usage has to be set to populate a 0 MRR value
        Boolean isAutoRenewalOppty = false;
        if(mchToAutoRenewMap.containsKey(contract.Id) &&  mchToAutoRenewMap.get(contract.Id))
          isAutoRenewalOppty = true;
        //SFDC-1395
        system.debug('selectedOpportunityCurrency: '+selectedOpportunityCurrency);
        if(String.isNotBlank(selectedOpportunityCurrency) && !contract.Currency__c.equalsIgnoreCase(selectedOpportunityCurrency)){
          setContractCurrency(contract.Currency__c);
        } 
        system.debug('contractCurrency: '+contractCurrency);
        for(Contract_Product__c conProduct: contractToContractProductMap.get(contract))
        {
          OpportunitylineItem oli = buildOpportunityLineItem(conProduct,productToPriceBookIdMap,isAutoRenewalOppty);
          if(oli != null){
            opptyLineItemList.add(oli);
          }
        }

      }
      if(opptyLineItemList.size() > 0)
      {
        //convert oli - SFDC-1395
        if(String.isNotBlank(selectedOpportunityCurrency)) //&& !contractList[0].Currency__c.equalsIgnoreCase(selectedOpportunityCurrency))
        {
          Map<OpportunityLineItem,String> oLIToSourceCurrencyMap = new Map<OpportunityLineItem,String>();
          Set<String> sourceCurrencyCodes = new Set<String>();
          sourceCurrencyCodes.add(contractCurrency);
          for(OpportunityLineItem oli : opptyLineItemList)
          {
            oLIToSourceCurrencyMap.put(oli,contractCurrency);
          }
          opptyLineItemList = GsmUtilClass.genericConvertLineItemCurrencies(opptyLineItemList,sourceCurrencyCodes,selectedOpportunityCurrency,opportunityCloseDate,oLIToSourceCurrencyMap);
          //opptyLineItemList = GsmUtilClass.genericConvertLineItemCurrencies(opptyLineItemList,contractCurrency,selectedOpportunityCurrency,opportunityCloseDate);
        }
          /*results.clear();
          results.dmlInsert(opptyLineItemList);
          results.withClassName('RenewalOpportunityCreationClass').withJobName('Renewal Opportunity Line Item Creation Process').insertRecordsInErrorLog();
          results.withJobName('Renewal Opportunity Line Item Creation Process').toAddress(GsmUtilClass.getGSMSettingValue('AutoRenewalBatchEmailList')).sendLogMail();*/
          resultsOLI.dmlInsert(opptyLineItemList);
          //resultsContract.add(Database.insert(opptyLineItemList,false),opptyLineItemList);
          MapOpptyIdToOpportunityLineItemList = new Map<Id, List<OpportunityLineItem>>();
          for(OpportunitylineItem oli : opptyLineItemList){
              if(oli.get('Id') != null){
                if(MapOpptyIdToOpportunityLineItemList.containsKey(oli.OpportunityId)){
                  MapOpptyIdToOpportunityLineItemList.get(oli.OpportunityId).add(oli);
                }
                else{
                  MapOpptyIdToOpportunityLineItemList.put(oli.OpportunityId, new list<OpportunitylineItem>{oli});
                }
              }
          }

      }
    }

    public OpportunityLineItem buildOpportunityLineItem(Contract_Product__c conProduct, Map<String,Id> productToPriceBookIdMap,Boolean isAutoRenewalOppty)
    {

      String endDate = conProduct.Effective_End_Date__c.year() + '-' + conProduct.Effective_End_Date__c.month();
      System.debug('Whats going on:'+conProduct.original_Contract_id__r.Original_Contract_Id__c+ ':' +endDate);
      Id opportunityId = contractToOpportunityMap.get(conProduct.original_Contract_id__r.Original_Contract_Id__c+ ':' +endDate).id;
      OpportunityLineItem oli = null;
      if(opportunityId != null)
      {
        oli = new OpportunityLineItem();
        oli.OpportunityId = opportunityId;
        oli.Quantity = 1;
        //SFDC-1957 - Setting Usage/Commit and Unit Price to 0 for pilot users
        oli.ZoffAutoCreate__c = true; //RAJESH -SFDC-7061
        oli.contract_promo_code__c = conProduct.ZOFF_Promo_Check__c ; //RAJESH -SFDC-7061
        oli.Average_Renewal_Commit_MRR__c = conProduct.Average_Renewal_Commit_MRR__c;
        oli.Average_Renewal_Usage_MRR__c = conProduct.Average_Renewal_Usage_MRR__c;
        oli.UnitPrice = conProduct.UnitPrice__c;
        oli.Comments__c = String.valueOf(conProduct.Id);
        //SFDC-6398 - Setting up Commit and Usage same to make MRR and EMRI as 0
        if(isAutoRenewalOppty)
        {
          oli.Projected_Monthly_commit_fees__c = oli.Average_Renewal_Commit_MRR__c;
          oli.Projected_Avg_Rev_Non_Commit__c  = oli.Average_Renewal_Usage_MRR__c;
          oli.MRR__c = 0.00;
          oli.EMRI__c = 0.00;
        }
        //SFDC-1425
        if(!String.isBlank(selectedOpportunityCurrency) && !conProduct.original_Contract_id__r.Currency__c.equalsIgnoreCase(selectedOpportunityCurrency))
        {
          oli.pricebookEntryId = productToPriceBookIdMap.get(conProduct.Forecast_Product_Id__c+' - '+selectedOpportunityCurrency);
          // oli = GsmUtilClass.genericConvertLineItemCurrencies(oli,contractCurrency,selectedOpportunityCurrency,opportunityCloseDate);
        }
        else{
          oli.pricebookEntryId=productToPriceBookIdMap.get(conProduct.Forecast_Product_Id__c+' - '+conProduct.original_Contract_id__r.Currency__c);
        }
        oli.validation_Override__c=true;
      }
      return oli;
    }

    public list<Opportunity> buildOpportunityRecord(Map<String, List<Contract_Product__c>> contractIdAndDtToContractProduct){
      List<Opportunity> opptyList = new List<Opportunity>();

      for(String contractIdWithDate :  contractIdAndDtToContractProduct.keyset()){
        Merge_Contract_Header__c contractDetail = idToContractMap.get(contractIdWithDate.split(':')[0]);
        Opportunity oppty = new Opportunity();
        oppty.AccountId = contractDetail.Account_Name__c;
        oppty.Partner_Involved_Akam_Id__c = contractDetail.Opportunity_Name__r.Partner_Involved__r.Akam_Account_Id__c;
        oppty.Renew_Contract_Id_Text__c = contractDetail.Original_Contract_Id__c;
        oppty.Deal_Type__c = String.isBlank(contractDetail.Opportunity_Name__r.Deal_Type__c) ? 'Direct' : contractDetail.Opportunity_Name__r.Deal_Type__c;
        Date tarik = null;
        for(Contract_Product__c contractProd : contractIdAndDtToContractProduct.get(contractIdWithDate)){
          if(tarik == null){
            tarik = contractProd.Effective_End_Date__c;
          }
          else{
            tarik = (tarik > contractProd.Effective_End_Date__c)? contractProd.Effective_End_Date__c : tarik;
          }
        }
        oppty.closeDate = tarik;
        system.debug('tarik:'+tarik);
        //Datetime endDate = DateTime.newInstanceGMT(tarik.year(),tarik.month(),tarik.day());
        oppty.name = getOpptyName(contractDetail, tarik); //+ endDateTime.format('YYYY-MM-dd');
         if(isMonthlyAutomatedJob){
          Boolean isAccountNonCompliant = False;
          //contractDetail.Account_Name__r.ECUSTOMS__RPS_Status__c ,Account_Name__r.Override_Visual_Compliance__c
          if((GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Red').split(',').contains(contractDetail.Account_Name__r.ECUSTOMS__RPS_Status__c) && !contractDetail.Account_Name__r.Override_Visual_Compliance__c)
                 || (GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Pending').split(',').contains(contractDetail.Account_Name__r.ECUSTOMS__RPS_Status__c) && !contractDetail.Account_Name__r.Override_Visual_Compliance__c)
                 || (GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_DS_Alert').split(',').contains(contractDetail.Account_Name__r.ECUSTOMS__RPS_Status__c) && !contractDetail.Account_Name__r.Override_Visual_Compliance__c))
            isAccountNonCompliant = true;
          oppty.StageName = '4. Select Option';
          if(mchToAutoRenewMap.containsKey(contractDetail.id)){
            oppty.Opportunity_Type__c = 'Auto-Renewal';
            oppty.Auto_Renewal__c = true;
            oppty.ForecastCategoryName = 'Commit';
            oppty.Override_Forecast_Category_With__c = 'Commit';
          }
          else{
            oppty.Opportunity_Type__c = 'Renewal';
            oppty.ForecastCategoryName = 'Pipeline';
          }
          if(isAccountNonCompliant){
            oppty.StageName = '1. Identify Need';
            oppty.ForecastCategoryName = 'Omitted';
            }
          }
        else{
          oppty.StageName = '1. Identify Need';
          oppty.ForecastCategoryName = 'Omitted';
        }
        oppty.CurrencyIsoCode = (String.isNotBlank(selectedOpportunityCurrency) && !contractDetail.Currency__c.equalsIgnoreCase(selectedOpportunityCurrency)) ? selectedOpportunityCurrency : contractDetail.Currency__c;
        oppty.Validation_Override__c=true;
        opptyList.add(oppty);
      }
      return opptyList;
    }

    public String getOpptyName(Merge_Contract_header__c contract, Date tarik)
    {
      String endDateContract = string.valueOfGmt(contract.Effective_End_Date__c).split(' ')[0];
      String endDateProduct = string.valueOfGmt(tarik).split(' ')[0];
      DateTime endDateTimeProduct = DateTime.newInstanceGMT(tarik.year(),tarik.month(),tarik.day());
      System.debug('endDateContract:' + endDateContract);
      System.debug('endDateProduct:' + endDateProduct);
      String accountName = contract.Account_Name__r.Name;
      String opptyName;

      if( endDateContract.equalsIgnoreCase(endDateProduct)){
        if(mchToAutoRenewMap.containsKey(contract.Id) &&  mchToAutoRenewMap.get(contract.Id)){ //SFDC-6398 - Naming convention for Auto Renewal
          opptyName = accountName +' - Auto Renewal of Contract '+ contract.original_contract_id__c +' renewing on ' + endDateContract;
        }
        else{
          opptyName = accountName +' - Renewal of Contract '+ contract.original_contract_id__c +' expiring on ' + endDateContract;
        }
      }
      else{
        if(mchToAutoRenewMap.containsKey(contract.Id) &&  mchToAutoRenewMap.get(contract.Id)){ //SFDC-6398 - Naming convention for Auto Renewal
          opptyName = accountName + ' - Off-Cycle Auto Renewal of Products on Contract ' + contract.original_contract_id__c + ' renewing on ' + endDateTimeProduct.format('MMM') +' '+tarik.Year();
        }
        else{
          opptyName = accountName + ' - Off-Cycle Renewal of Products on Contract ' + contract.original_contract_id__c + ' expiring on ' + endDateTimeProduct.format('MMM') +' '+tarik.Year();
        }
      }
          
      if(opptyName.length() >120)
      {
        Integer diffLen = Opptyname.length()-120;
        String newAccountname = accountName.subString(0,accountName.length()-(difflen+1));
        opptyName = opptyName.replace(accountName, newAccountname);
      }

      return opptyName ;
    }
  

    public static String createRenewalOpportunityMonthlyJob()
    {
      String returnMessage='1: ';

         RenewalOpportunityCreationClass renewal= new RenewalOpportunityCreationClass();
         Integer batchSize=Integer.valueOf(GsmUtilClass.getGSMSettingValue('Renewal_Process_Batch_Size'));
         Database.executeBatch(renewal,batchSize);
         returnMessage=returnMessage+'Renewal Opportunity creation process started successfully';

       return returnMessage;
    }
    // SFDC-1425
    public void setOpportunityCurrency(String currencyCode)
    {
        selectedOpportunityCurrency = currencyCode;
    }

    public void setOpportunityCloseDate(Datetime closeDate)
    {
        opportunityCloseDate = closeDate;
    }

    public void setContractCurrency(String currencyCode)
    {
        contractCurrency = currencyCode;
    }

    public map<Merge_Contract_Header__c, List<Contract_Product__c>> checkDuplicateOpportunity(List<Merge_Contract_Header__c> listOfContracts){

      System.debug('listOfContracts:'+listOfContracts);
      System.debug('listOfContracts Size:'+listOfContracts.size());
      Set<Id> contractAccountIDs = new Set<Id>();
      Map<Id, Set<String>> ContractIdToContractProductMap = new Map<Id, Set<String>>();
      Map<Merge_Contract_Header__c, List<Contract_Product__c>> contractToItsProduct = new Map<Merge_Contract_Header__c, List<Contract_Product__c>>();
      Id akamaiOpptyRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();
      Id closedRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(GSMUtilClass.getGSMSettingValue('Closed_Opportunity_Rec_Type')).getRecordTypeId();

      for(Merge_Contract_Header__c eachContract : listOfContracts)
      {
        contractAccountIDs.add(eachContract.Account_Name__c);
      }

      List<Renewal_Contract_Object__c> contractsWithExistingOpptys = [select Id, Contract__c, Opportunity__c,Opportunity__r.AccountId, Contract_Effective_End_Date__c, (Select id, Contract_Product__c, End_Month__c from Associated_Contract_Products__r) from Renewal_Contract_Object__c where Contract__c IN :listOfContracts and Opportunity__c != null and (Opportunity__r.RecordTypeId = :akamaiOpptyRecordTypeId Or Opportunity__r.RecordTypeId = :closedRecTypeId)];
      
      for(Renewal_Contract_Object__c rcb : contractsWithExistingOpptys){
        System.debug('rcb:'+rcb+' SIZE:'+rcb.Associated_Contract_Products__r.size());
        for(Renewal_Contract_Product__c rcp : rcb.Associated_Contract_Products__r){
          if(ContractIdToContractProductMap.containsKey(rcb.Contract__c)){
            ContractIdToContractProductMap.get(rcb.Contract__c).add(rcp.Contract_Product__c + ':' + rcp.End_Month__c); //Contract__c - merge contract header id
          }
          else{
            ContractIdToContractProductMap.put(rcb.Contract__c, new Set<String>{rcp.Contract_Product__c + ':' + rcp.End_Month__c});
          }
        }
      }
      System.debug('ContractIdToContractProductMap:'+ContractIdToContractProductMap + ' Size:'+ContractIdToContractProductMap.size()); 
      //system.assertEquals(1,2,'Error');
      for(Merge_Contract_Header__c mch : listOfContracts){// 1 times
        if(ContractIdToContractProductMap.containskey(mch.id)){
          List<Contract_Product__c> cpList = new List<Contract_Product__c>();
          System.debug('Size of contract product:'+mch.Contract_Products__r.size());
          for(Contract_Product__c cp : mch.Contract_Products__r){ // 4 times
            /*
            for(String productIdAndEndDate : ContractIdToContractProductMap.get(mch.id)){
              System.debug('Date comparison:'+productIdAndEndDate+' And '+ cp.id + ':' + cp.Effective_End_Date__c);
              if(!productIdAndEndDate.equalsIgnoreCase(cp.id + ':' + cp.Effective_End_Date__c)){
                cpList.add(cp);
              }
            }*/
            String combination = '';
            if(cp.Effective_End_Date__c != null){
              combination = cp.id + ':' + cp.Effective_End_Date__c.year()+'-'+cp.Effective_End_Date__c.month();
            }
            if(!ContractIdToContractProductMap.get(mch.id).contains(combination)){
              cpList.add(cp);
            }
          }
          if(cpList.size() > 0){
            contractToItsProduct.put(mch, cpList);
          }
        }
        else{
          if(mch.Contract_Products__r.size() > 0){
            contractToItsProduct.put(mch, new list<Contract_Product__c>());
            for(Contract_Product__c cp : mch.Contract_Products__r){
              contractToItsProduct.get(mch).add(cp);
            }
          }
        }
      }
      System.debug('contractToItsProduct:'+contractToItsProduct+ ' Size:'+contractToItsProduct.size());
      //system.assertEquals(1,2,'Error');
        return contractToItsProduct;
    }
}