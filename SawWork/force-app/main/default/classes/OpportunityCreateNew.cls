/**
 * Extension controller for opportunityNew.page
 * URL querystring manipulation to populate the Partner Involved
 * field when an opportunity is first created. Once string created, it redirects user
 * back to the standard new opportunity page without an override
 *
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Mayank Singh     04/2014         Created Class as part of CR 2578890 - Deal Reg -- Default Partner Involved default 
   Sonali Tandon     02/01/2015    CR 2868375 - Visual Flow: Intermediate page for new opportunity
                                               - added AccountPopulated() and search()
   Ruchika Sharma    31/03/2016    CR 3348741 - Ability for CSM's to route Opptys to Sales
                                              - Prepopulate fields for AMG opportunity and AMG profiles
 **/
public class OpportunityCreateNew {

public Boolean flag {get;set;}
public Boolean flagRenewal {get;set;}
public Opportunity opp;
public String urlCode {get;set;}
public List<Opportunity> openOpps{get;set;}
public List<Opportunity> openRenewalOpps{get;set;}
public Boolean noOpenOpps{get;set;}
public Boolean fromAccount{get;set;}
public String contractBaselineOption{get;set;}
public Boolean showOpenOpptySection {get; set;}
public Boolean showOpenRenewalOpptySection {get;set;}
public Boolean showContractSection{get;set;}
public String contractSelected  {get;set;}
public static List<ContractWrapper> cwList;
public Merge_Contract_Header__c mchSelected {get; set;}
public Boolean isContractSelected{get;set;}
public Merge_Contract_Header__c opportunityContract {get; set;}
public Boolean hasContractBaseline {get; set;}
public Boolean showContractListSection{get; set;}
public Boolean isFeatureToggle{get; set;}
public String selectedCurrency {get;set;}
public String selectedcurrencyOption {get;set;}
public List<Merge_Contract_Header__c> setOfSelectedContracts{get;set;}
public Boolean showContractRelatedSection {get;set;}
public static Map<String,List<Contract_Product__c>> mapOfContractIdToProducts;
public Boolean showContractProductPop {get;set;}
public String contractIdForProduct{get;set;}
public List<ContractProductWrapper> contractProductList;
public Id opportunityIdForContracts{get;set;}
public Boolean showContractsAssociatedToOppty{get;set;}
public List<Merge_Contract_Header__c> associatedContracts {get;set;}
public static Id accountId;
public Boolean EMRIMultipleContractsToggle {get;set;}
public Boolean isContractCurrencyMismatch{get; set;}

//SFDC-3550
public String selectedOpptyType {get;set;}
public List<SelectOption> withBaselineOpptyTypes {get;set;}
public List<SelectOption> withoutBaselineOpptyTypes {get;set;}
public Boolean showOppTypeBlock {get;set;}
public String SkipIntermediateOpptyCreationPage {get;set;}

public String contractChangeType {get;set;}
public Boolean isContractChange {get;set;}
public List<SelectOption> contractChangeOpptyTypes {get;set;}

    
public OpportunityCreateNew(){}
  
    public OpportunityCreateNew(ApexPages.StandardController controller){
        //list of open opportunities
        openOpps = new List<Opportunity>();
        openOpps.clear();
        urlCode = String.valueof(URL.getSalesforceBaseUrl().toExternalForm());
        opp=(Opportunity)controller.getRecord();
        System.debug(LoggingLevel.ERROR, 'opp' + opp);
        accountId = opp.AccountId;
        showContractProductPop = false;
        contractIdForProduct = null;
        EMRIMultipleContractsToggle = GSMUtilClass.isFeatureToggleEnabledCustomMetadata('EMRIMultipleContractsToggle');
        SkipIntermediateOpptyCreationPage = GsmUtilClass.getGSMSettingValue('SkipIntermediateOpptyCreationPage');
        AccountPopulated();

        //SFDC-3550
        withBaselineOpptyTypes = new List<SelectOption>{new SelectOption('--None--','--None--')};
        for(string oppType : GsmUtilClass.getGSMSettingValue('OpptyTypesWithContractBaseline').split(','))
          withBaselineOpptyTypes.add(new SelectOption(oppType,oppType));

        withoutBaselineOpptyTypes = new List<SelectOption>{new SelectOption('--None--','--None--')};
        for(string oppType : GsmUtilClass.getGSMSettingValue('OpptyTypesWithoutContractBaseline').split(','))
          withoutBaselineOpptyTypes.add(new SelectOption(oppType,oppType));

        contractChangeOpptyTypes = new List<SelectOption>{new SelectOption('Contract Change','Contract Change')};
        
        selectedOpptyType = '--None--';
        showOppTypeBlock = false;
        isContractChange = false;
   }

    public void AccountPopulated()
    {
      
      noOpenOpps = true;
        //Default do not show Open Oppty Section
      showOpenOpptySection = false;
      showContractSection = false;
      showOpenRenewalOpptySection = false;
      showContractListSection = false;
      flagRenewal = false;

      
      ID accId = ApexPages.currentPage().getParameters().get('accid');

      //check if oppty is created via Partner Portal -deal reg record type 
      //SFDC-2572
      String partnerAdminId = GsmUtilClass.getPRMSettingValue('Partner_Admin_Id');
      String partnerUserId = GsmUtilClass.getPRMSettingValue('Partner_User_ID');
      System.debug('pad' + partnerAdminId + 'pus' + partnerUserId);
      System.debug('user profile id' + UserInfo.getProfileId());
     
     //skip to new oppty creation page if no open opptys tied to the account
      if(SkipIntermediateOpptyCreationPage.contains(UserInfo.getProfileId()))
        noOpenOpps = false;
      System.debug('no open opps'+noOpenOpps);
      
      //check if oppty is created from account record
      System.debug('id'+accId);
       if(accId!=null)
           fromAccount = true;
       else
           fromAccount = false;
    
      //check if account looked up is not null
      if(opp.AccountId!=null)
       {
        //get list of open opportunities related to account selected
          accountId = opp.AccountId;
         openOpps = search();
          if(openOpps.isEmpty())
          {
              flag = false;
              //skip to new oppty creation page if no open opptys tied to the account
              if(accId!=null)
                  noOpenOpps = false;
          }
          else
              flag = true;
       }     
      else
           flag = false;
      
 }
 public List<SelectOption> getContractChangeOptions() {
    List<SelectOption> options = new List<SelectOption>();
    options.add(new SelectOption('CE','Extend Contract'));
    options.add(new SelectOption('BEDD','BED Deferment'));
    options.add(new SelectOption('OTHER','Other'));
    return options;
 }
    
    //Select options for Contract baseline and redirect based on selection
    public List<SelectOption> getContractBaselineOptions() {

        String selectOptionWith = GSMUtilClass.getGSMSettingValue('ContractBaseLineOptionWith');
        String selectOptionWithout = GSMUtilClass.getGSMSettingValue('ContractBaseLineOptionWithout');
        String createContractChangeOppty = GSMUtilClass.getGSMSettingValue('CreateContractChangeOppty');


        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(selectOptionWith,selectOptionWith));
        options.add(new SelectOption(selectOptionWithout,selectOptionWithout));
        options.add(new SelectOption(createContractChangeOppty,createContractChangeOppty));
        return options;
    }
    public String getContractBaselineOption() {
    return contractBaselineOption;
  }
    public void setContractBaselineOption(String contractBaselineOption) { 
        this.contractBaselineOption = contractBaselineOption; 
    }
    
    //Get Contract List for the selected Account
    public List<Merge_Contract_Header__c> getContractFromAccount() {


      System.debug('opp.AccountId' + opp.AccountId);
      System.debug(LoggingLevel.ERROR, 'opp.AccountId' + opp.AccountId + accountId + opportunity.AccountId);

      // from OpportunityGetBaseline.page
      if(opp.AccountId == null &&  ApexPages.currentPage().getParameters().get('accId')!=null)
        accountId = Id.valueOf(ApexPages.currentPage().getParameters().get('accId'));
      else
      accountId  = opp.AccountId;

      System.debug(LoggingLevel.ERROR, accountId);


        List<Merge_Contract_Header__c> contractRecords = new List<Merge_Contract_Header__c>();
        for(Merge_Contract_Header__c mc : [select Id,name,Contract_Type__c,Parent_Contract__c,Order_Id__c,Parent_Account_Name__c,Currency__c,Solution_Set__c,Effective_Start_Date__c,CurrencyIsoCode,Account_Name__c,Account_Name__r.Id,Account_Name__r.Name ,Active__c ,Effective_End_Date__c , Original_Contract_Id__c,Opportunity_Name__r.currencyIsoCode,Opportunity_Name__r.Deal_Type__c,Opportunity_Name__r.Partner_Involved__c,
  Contract_Product_Count__c,(Select Id,CurrencyIsoCode,Average_Renewal_Commit_MRR__c,Average_Renewal_Usage_MRR__c,Forecast_Product_Id__c from Contract_Products__r where Deleted_From_Source__c = false) from Merge_Contract_Header__c where Account_Name__c = :accountId and Active__c = true 
  AND Effective_End_Date__c >= LAST_N_MONTHS:2 
  AND Contract_Product_Count__c > 0 ORDER BY Effective_End_Date__c ASC])
        {
            contractRecords.add(mc);
        }
        
        return contractRecords;

    }
    
    //Wrapper class to store the Contract Selected and Input Checkbox
    public class ContractWrapper{
        public Merge_Contract_Header__c mch{get; set;}
        public Boolean CheckBox{get; set;}
    }
    
public List<ContractWrapper> getContractWrapper(){
      cwList = new List<ContractWrapper>();
      Id oppId = ApexPages.currentPage().getParameters().get('opportunityID');
      List<ContractWrapper> filteredContractList = new List<ContractWrapper>();
      List<Id> assciatedContractId = new List<Id>();
      for(Renewal_Contract_Object__c associatedContract : [Select id, Contract__c from Renewal_Contract_Object__c where Opportunity__c = :oppId]){
          assciatedContractId.add(associatedContract.Contract__c);
      }
      System.debug('assciatedContractId:'+assciatedContractId);
      try{
        //Check if the Contract List is not empty
        List<Merge_Contract_Header__c> mcList = getContractFromAccount();
        System.debug('mcList:'+mcList);
        System.debug('Size:'+mcList.size());
        if(!mcList.isEmpty()){
          //SFDC-1394
          system.debug('Inside if::');
          mapOfContractIdToProducts = new  Map<String,List<Contract_Product__c>>();
          for(Merge_Contract_Header__c mcRecord : mcList){
            ContractWrapper cw = new ContractWrapper();
            cw.mch = mcRecord;
            cw.CheckBox = false;
            cwList.add(cw);
            if(!assciatedContractId.contains(mcRecord.id)){
              system.debug('contract Id:'+mcRecord.id);
              filteredContractList.add(cw);
            }
            mapOfContractIdToProducts.put(cw.mch.Original_Contract_Id__c,cw.mch.Contract_Products__r);
          } 
        }
          System.debug('filteredContractList:'+filteredContractList);
          if(filteredContractList.size() > 0){
          return filteredContractList; 
          }
          else{
            Apexpages.addMessage( new ApexPages.Message (ApexPages.Severity.ERROR,GsmUtilClass.getErrorPageSettingValue('ContractAlreadyAssociated')));
            return null;
          }
      } 
        catch (exception e) {
          ApexPages.addMessages(e);   
          return null;
        }
    }
  //Set value to show Open Opportunities Section
  public PageReference  checkOptionValue()
    {
      if(contractBaselineOption.contains(GSMUtilClass.getGSMSettingValue('CreateContractChangeOppty'))){
          isContractChange = true;
      }else{
          isContractChange = false;
      }
      String newOpptyOption = GSMUtilClass.getGSMSettingValue('ContractBaseLineOptionWithout');
      //SFDC-3550
      selectedOpptyType = '--None--';
      contractChangeType = null;
      isContractSelected = false;
      setOfSelectedContracts = new List<Merge_Contract_Header__c>();

      if(contractBaselineOption.contains(newOpptyOption))
      {
         showOpenOpptySection= true;
         showContractSection = false;
         isContractSelected = false;
         //SFDC-3550
         showOppTypeBlock = true;
      }
      else if(contractBaselineOption.contains(GSMUtilClass.getGSMSettingValue('ContractBaseLineOptionWith')))
      {
          showContractSection = true;
          showOpenOpptySection = false;
                List<Merge_Contract_Header__c> mcListCheck = getContractFromAccount();
                if(mcListCheck.size() > 0)
                {
                  showContractListSection= true;
                }
          //SFDC-3550
          showOppTypeBlock = false;
      }
      else{
        showContractSection = false;
        showOpenOpptySection = false;
        showContractListSection= false;
        showOppTypeBlock = false;
      }
      return null;
    }

    public PageReference onContractTypeChange(){
      showContractSection = true;
      showOpenOpptySection = false;
      List<Merge_Contract_Header__c> mcListCheck = getContractFromAccount();
      if(mcListCheck.size() > 0)
      {
        showContractListSection= true;
      }
      //SFDC-3550
      showOppTypeBlock = false;
      isContractSelected = false;
      setOfSelectedContracts = new List<Merge_Contract_Header__c>();
      return null;
    }
    
    
    //Call function to get the selected Contract and check if any Renewal Opportunity exists 
    
  public PageReference  inputCheckForRenewalOppty()
    {
        //SFDC-1394
        setOfSelectedContracts = new List<Merge_Contract_Header__c>();
        showOpenRenewalOpptySection = false;
        openRenewalOpps = new List<Opportunity>();
        isContractSelected = false;
        isContractCurrencyMismatch = false;
        List<Id> listOfOpportunityIds = new List<Id>();
        for(ContractWrapper cw: cwList)
        {
           if(cw.Checkbox == True)
           {
               mchSelected = cw.mch;
               isContractSelected = true;
               setOfSelectedContracts.add(mchSelected);
           }
        }
        System.debug(LoggingLevel.ERROR, 'setOfContracts' + setOfSelectedContracts);
        System.debug('setOfContracts' +setOfSelectedContracts);
        system.debug('Opp Account Id '+opp.accountId +'Contract Selected '+mchSelected +'Size '+openRenewalOpps.size() +'isContractSelected '+isContractSelected +''+showOpenRenewalOpptySection);

             //SFDC-1394
            if(setOfSelectedContracts.size()>0)
            {
                System.debug('setOfSelectedContracts' +setOfSelectedContracts);
                String firstCurrency = setOfSelectedContracts[0].Currency__c;
                for(Merge_Contract_Header__c mch : setOfSelectedContracts)
                {
                    if( !firstCurrency.equalsIgnoreCase(mch.Currency__c) && ( !selectedcurrencyOption.containsIgnoreCase('Other Currency') || (selectedcurrencyOption.containsIgnoreCase('Other Currency') && selectedCurrency.contains('None'))))
                        isContractCurrencyMismatch = true;
                      
                }
            }




        if(isContractSelected)
        {   
            //SFDC-1394
            for(Renewal_Contract_Object__c renewalContract : [Select Opportunity__c,Contract__c, Contract__r.Original_Contract_Id__c from Renewal_Contract_Object__c where Contract__c IN:setOfSelectedContracts and Opportunity__c!=null])
            {
              listOfOpportunityIds.add(renewalContract.Opportunity__c);
            }  
            for(Opportunity opp: [Select Id,name,CloseDate,StageName,MRR__c,Primary_Product_Name__c,Opportunity_Type__c from Opportunity Where AccountId =:opp.accountId AND (NOT StageName like '%Closed%')/* AND Contract_Effective_End_Date__c = :mchSelected.Effective_End_Date__c */AND Id IN: listOfOpportunityIds AND Opportunity_Type__c ='Renewal' ])
            {
                openRenewalOpps.add(opp);
            }

         }
        
        if(openRenewalOpps.size()> 0)
        {
            showOpenRenewalOpptySection = true;
            flagRenewal = true;
        }
        else
        {
          flagRenewal = false;

        }


        system.debug('Falg' +flagRenewal +'Contract Selected '+mchSelected +'Size '+openRenewalOpps.size() +'isContractSelected '+isContractSelected +''+showOpenRenewalOpptySection);
        return null;
    }


         
  // run the search and return the records found. 
  private List<Opportunity> search() {
 
    String soql = 'select Id,name,CloseDate,StageName,MRR__c,Primary_Product_Name__c,Opportunity_Type__c from Opportunity where Opportunity.AccountId=\''+ accountId + 
    '\' and (not StageName like \'%Closed%\') ORDER BY CloseDate DESC LIMIT 20';
 
    System.debug(soql);
    return database.query(soql); 
 
  }
      
    public PageReference pageRedirect(){
    
        //SFDC-3550
        if(selectedOpptyType == '--None--' && !SkipIntermediateOpptyCreationPage.contains(UserInfo.getProfileId())){
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select Opportunity Type.'));
          return null;
        }

        String Prefix =  Schema.Sobjecttype.Opportunity.getKeyPrefix();
        PageReference returnURL = new Pagereference ('/'+ Prefix+ '/e?');
      
        //SFDC-839
        String amgOppRecordType = GSMUtilClass.getGSMSettingValue('OppTrigger_bi_amgOppRecordType');
        String profilesForDefaulting = GSMUtilClass.getGSMSettingValue('OppTrigger_bi_amgOppProfiles');
        String opptyDealTypeId = GsmUtilClass.getGSMSettingValue('Opportunity_Deal_Type');
        String opptyTypeId = GsmUtilClass.getGSMSettingValue('Opportunity_TypeId');
    

        Map<ID,Schema.RecordTypeInfo> rt_Map = Opportunity.sObjectType.getDescribe().getRecordTypeInfosById();

        Id currentUserId=UserInfo.getUserId();
        
        User relatedUser=null;
        if(currentUserId!=null)
            {
            relatedUser=[select Contact.AccountId,Contact.Account.Name,Profile.Name from User where Id=:currentUserId][0];
            }
        
        for(string key:ApexPages.currentPage().getParameters().keySet())
            {
                returnURL.getParameters().put(key, ApexPages.currentPage().getParameters().get(key) != null ? String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get(key).escapeHtml4()) : ApexPages.currentPage().getParameters().get(key));
            }
            
        if(relatedUser!=null && GsmUtilClass.getGSMSettingValue('OpportunityNew_Profiles').contains(relatedUser.Profile.Name))
            {
                returnURL.getParameters().put('CF00NA0000000saHP_lkid', relatedUser.Contact.AccountId);
                returnURL.getParameters().put('CF00NA0000000saHP', relatedUser.Contact.Account.Name);
            }        

            returnURL.getParameters().put('nooverride', '1');
            returnURL.getParameters().remove('save_new');

            //SFDC-839: Default stage, closedate and deal type for AMG opportutnities
           
            if(profilesForDefaulting.containsIgnoreCase(UserInfo.getProfileId().substring(0, 15)) ||(opp.RecordTypeId!=null && rt_Map.get(opp.RecordTypeId).getName()==amgOppRecordType)){
                
               Integer amgCloseDateDays = Integer.valueof([select Id, Value__c from GSM_Settings__mdt where DeveloperName = 'OppTrigger_bi_amgCloseDateDays'].Value__c);
               returnURL.getParameters().put('opp11', '2. Explore Options');//SFDC-3539
               String closeDate = (Date.today()+amgCloseDateDays).format();
               returnURL.getParameters().put('opp9', closeDate);
               returnURL.getParameters().put(opptyDealTypeId, 'Direct');
            }
            returnURL.getParameters().put(opptyTypeId,selectedOpptyType); //SFDC-3550
            returnURL.setRedirect(true);       
         return returnURL;
        
       
        }

        public PageReference createOpportunity() {

          //SFDC-3550
          if(selectedOpptyType == '--None--' && !SkipIntermediateOpptyCreationPage.contains(UserInfo.getProfileId())){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select Opportunity Type.'));
            return null;
          }

          List<String> listOfOriginalContractIds = new List<String>();
          Set<String> contractCurrencyList = new Set<String>();
          String firstCurrency = setOfSelectedContracts[0].Currency__c;
                    system.debug('Selected Option '+selectedcurrencyOption +' Is a mismatch '+isContractCurrencyMismatch);
                    system.debug(' Condition '+selectedcurrencyOption.containsIgnoreCase('Other Currency'));

          for(Merge_Contract_Header__c mch : setOfSelectedContracts)
          {
            
            listOfOriginalContractIds.add(mch.Original_Contract_Id__c);
            contractCurrencyList.add(mch.Currency__c);
          }
          //SFDC-1394
          CreateRenewalOpptyWithMultipleContracts roc= new CreateRenewalOpptyWithMultipleContracts(listOfOriginalContractIds);
          // SFDC-1425
          if(selectedcurrencyOption.containsIgnoreCase('Other Currency') && !selectedCurrency.contains('None'))
          {
            roc.setOpportunityCurrency(selectedCurrency);
            roc.setContractCurrency(contractCurrencyList);
          }

          else{
                  
                  roc.setContractCurrency(contractCurrencyList);
          }

          Opportunity opptyCreated;
          opptyCreated = roc.createRenewalOpportunityWithProducts(selectedOpptyType); //SFDC-SFDC-3550 : Passed Parameter

          if(roc.errorOccured)
          {
            noOpenOpps = false;
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'An error has occurred while performing this operation.'));
            return null;
          }
           
            opptyCreated = [Select Id,OwnerId From Opportunity Where Id =: opptyCreated.Id];
               
            PageReference pageRef;
            system.debug('Owner  '+opptyCreated.OwnerId + 'Current User '+UserInfo.getUserId());
            
            if(opptyCreated.OwnerID == UserInfo.getUserId().substring(0,15))
              {
                pageRef = new PageReference('/' + opptyCreated.Id + '/e');
                pageRef.getParameters().put('retURL', '/'+opptyCreated.Id);
                return pageRef;
              }

            else
                {
                  pageRef = new PageReference('/' + opptyCreated.Id );
                  return pageRef;
                }

 
        }

        public void inputCheckForGetBaseline(){

          for(ContractWrapper cw: cwList)
            {
            if(cw.Checkbox == True)
              {
                mchSelected = cw.mch;
              }
            }



        }

        public List<SelectOption> getCurrencies()
        {
            selectedcurrency = '--None--';
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('--None--','--None--'));
            for(String isoCode : GsmUtilClass.getCurrencyIsoCodes())
                options.add(new SelectOption(isoCode,isoCode));
            
            return options;

        }

        public List<SelectOption> getcurrencyOptions()
        {
            selectedcurrencyOption = 'With Contract Currency';
            system.debug(' Mismatch value '+isContractCurrencyMismatch);
            List<SelectOption> options = new List<SelectOption>();
            
                options.add(new SelectOption('With Contract Currency', 'With Selected Contract\'s Currency'));
                if(!isContractChange)
                  options.add(new SelectOption('Other Currency: ', 'Other Currency: '));
              
            return options;

        }


    // SFDC-1394
    public class ContractProductWrapper {

    public String forecastProductName {get;set;}
    public Decimal averageRenewalCommit{get;set;}
    public Decimal averageRenewalUsage{get;set;}
    public String currencyCode{get;set;}
  }

  public List<ContractProductWrapper> getContractProductWrapper(){

    contractProductList = new List<ContractProductWrapper>();

    if(contractIdForProduct!=null)
    {
    showContractProductPop = true;

    System.debug('contractIdForProduct' +contractIdForProduct);
      //show = true;
      Map<Id,String> mapOfContractProductIdToForecastProductId = new Map<Id,String>();
      Map<Id,ContractProductWrapper> mapOfContractProductIdToContractProductWrapper = new Map<Id,ContractProductWrapper>();
      Map<String,String> mapOfForecastProductIdToForecastProductName = new Map<String,String>();


      for(Contract_Product__c contractProduct : mapOfContractIdToProducts.get(contractIdForProduct))
      {
        ContractProductWrapper contractWrapper = new ContractProductWrapper();
        contractWrapper.averageRenewalCommit = contractProduct.Average_Renewal_Commit_MRR__c;
        contractWrapper.averageRenewalUsage = contractProduct.Average_Renewal_Usage_MRR__c;
        contractWrapper.currencyCode = contractProduct.CurrencyIsoCode;
        mapOfContractProductIdToContractProductWrapper.put(contractProduct.Id,contractWrapper);
        mapOfContractProductIdToForecastProductId.put(contractProduct.Id,contractProduct.Forecast_Product_Id__c);
      }

      for(PricebookEntry pbe : [Select Name,product2.Akam_Product_Id__c from PricebookEntry where product2.Akam_Product_Id__c IN : mapOfContractProductIdToForecastProductId.values()])
      {
        mapOfForecastProductIdToForecastProductName.put(pbe.product2.Akam_Product_Id__c, pbe.Name);
      }

      for(Id contractProductId : mapOfContractProductIdToContractProductWrapper.keySet())
      {
        mapOfContractProductIdToContractProductWrapper.get(contractProductId).forecastProductName =   mapOfForecastProductIdToForecastProductName.get(mapOfContractProductIdToForecastProductId.get(contractProductId));
      }
      if(mapOfContractProductIdToContractProductWrapper.size()>0)
      {
        contractProductList.addAll(mapOfContractProductIdToContractProductWrapper.values());

      }

      System.debug('contractProductList' + contractProductList);

    }

    return contractProductList;

  }
  //SFDC-1394
  public void showContractProducts()
  {
    showContractProductPop = true;
    System.debug('showContractProductPop' +showContractProductPop);
  }
  //SFDC-1394
   public void closePopup() {        
        showContractProductPop = false; 
        contractIdForProduct = null;   
    }    
  //SFDC-1394
  public void showContractsAssociatedToOppty()
  {
    showContractsAssociatedToOppty = true;
    associatedContracts = new List<Merge_Contract_Header__c>();

    System.debug('opportunityIdForContracts' +opportunityIdForContracts);

        if(opportunityIdForContracts!=null)
        {
          for(Renewal_Contract_Object__c rc : [Select Contract__c,Contract_Effective_End_Date__c,Contract_Id_Text__c,Parent_Contract__c,Order_Id__c,Contract_Type__c,Parent_Account_Name__c from Renewal_Contract_Object__c where Opportunity__c =:opportunityIdForContracts])
          {
            Merge_Contract_Header__c mch = new Merge_Contract_Header__c(Id=rc.Contract__c,Original_Contract_Id__c=rc.Contract_Id_Text__c,
             Parent_Contract__c=rc.Parent_Contract__c,Order_Id__c=rc.Order_Id__c,Contract_Type__c=rc.Contract_Type__c,Parent_Account_Name__c=rc.Parent_Account_Name__c,Effective_End_Date__c = rc.Contract_Effective_End_Date__c);
            associatedContracts.add(mch);
          }
        }

        System.debug('associatedContracts' +associatedContracts);
  }

   public void closeContractsAssociatedToOppty() {        
        showContractsAssociatedToOppty = false;    
    } 

    public PageReference navigateToNextScreen(){
      String selectedContractId = '', returnURL = '';
      if(setOfSelectedContracts != null && setOfSelectedContracts.size() > 0)
        selectedContractId = setOfSelectedContracts[0].Id;
      if(contractChangeType == 'CE' || contractChangeType == 'BEDD'){
        returnURL = '/apex/GSM_Lite_Contract_BEDDeferement?contractId=' + selectedContractId + '&pRequestType=' + contractChangeType + '&accountId=' + accountId;
      }
      else if(contractChangeType == 'OTHER'){
        String res = SF1_CreateNewOpportunityFlowController.createPaperPOC(selectedContractId,accountId);
        if(res != '' && res != 'ERROR'){
          returnURL = '/'+res;
        }
        else{
          ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Opportunity creation failed! Please contact your System Administrator.'));
          return null;
        }
      }
      PageReference pageRef = new Pagereference(returnURL);
      return pageRef;
    }

}