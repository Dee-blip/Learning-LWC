/*

   Author - Anand Hegde Aug 19th 2016
   Hitesh - 10 Aug 2017 -  Added Logic to get the Component Product Summed up as Contracted Products under each Sales Channel Record
   */

global class CurrentSalesChannelBatchClass implements Database.Batchable<Sobject>, Database.Stateful
{
    global final string query;
    global DMLResults results;
    //global DMLResults deleteResults;
    global Boolean triggerDelete=false;

     global CurrentSalesChannelBatchClass()
     {
        //Get all the Active Accounts
         //query='select Id,Direct_Customer__c ,Indirect_Customer__c, Active_NAP_Master_Contract__c  from account where account_status__c like \'%Active\' and (not account_status__c like \'%Inactive\')';
         query='select Id,Direct_Customer__c ,Indirect_Customer__c, Active_NAP_Master_Contract__c, account_status__c  from account';
         triggerDelete=false;
     }

     global CurrentSalesChannelBatchClass(Boolean trigDelete)
     {
         this();
         triggerDelete=trigDelete;
     }
     //Both Upsert and Delete to be called from same batch class
     global Database.QueryLocator start(Database.BatchableContext BC){ 
         results= new DMLResults(); 
         results.storeObjectState();
         

         return Database.getQueryLocator(query); 
     }
    //Scope size is configured in metadata
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        List<Account> AllAccounts = (List<Account>)scope;
        Set<Id> AllAccountsIds = new Set<Id>();
        Set<Id> AllAccountsIdsWithNapActiveAsTrue = new Set<Id>();

        System.Debug(LoggingLevel.Error, 'AGH_D scope in CurrentSalesChannelBatchClass'+AllAccounts);
        Set<Id> customerAccountIds = new Set<Id>();
        //Get all the Account Ids
        for(Account acc : AllAccounts)
        {
            if((acc.account_status__c).contains('Active') && !(acc.account_status__c).contains('Inactive'))
                customerAccountIds.add(acc.id);

            AllAccountsIds.add(acc.id); 

            if(acc.Active_NAP_Master_Contract__c){
                AllAccountsIdsWithNapActiveAsTrue.add(acc.id);
            }   

        }

        //SFDC-3091
        Set<Account> AccountIdsWithActiveNapMaster = new Set<Account>();
        Map<Id, List<merge_contract_header__c>> AccToContracts = new Map<Id, List<merge_contract_header__c>>();
        List<merge_contract_header__c> NapMasterMCHActiveList = new List<Merge_contract_header__c>();

        NapMasterMCHActiveList = [select Account_Name__c, Account_Name__r.Active_NAP_Master_Contract__c, Contract_Type__c, Active__c, Effective_Start_Date__c, Effective_End_Date__c from merge_contract_header__c where Account_Name__c in :AllAccountsIds];

        System.debug('List content::::'+NapMasterMCHActiveList);
        for(merge_contract_header__c mch : NapMasterMCHActiveList){
            if(AccToContracts.containsKey(mch.Account_Name__c)){
                List<merge_contract_header__c> l1 = AccToContracts.get(mch.Account_Name__c);
                l1.add(mch);
                AccToContracts.put(mch.Account_Name__c, l1);
            }
            else{
                List<merge_contract_header__c> s1 = new List<merge_contract_header__c>();
                s1.add(mch);
                AccToContracts.put(mch.Account_Name__c, s1);
            }
        }

        System.debug('Map content::::'+AccToContracts);
        for(Id AccId : AccToContracts.keySet()){
            List<merge_contract_header__c> l = AccToContracts.get(AccId);
            System.debug('list of contracts::'+l);
            System.debug('Account id::'+AccId);
            Boolean flag = false;
            Account acc = new Account(id = AccId);
            System.debug('account reference:::'+acc);
            for(merge_contract_header__c mch : l){
                System.debug('Value of mch'+mch);
                if(mch.Active__c && mch.Effective_Start_Date__c <= Date.Today() && mch.Effective_End_Date__c >= Date.Today() && mch.Contract_Type__c == 'NAP Master Agreement'){
                    //acc.Active_NAP_Master_Contract__c = true;
                    System.debug('Active Nap Master Agreement');
                    flag = true;
                    break;
                }
            }
            if(flag){
                    System.debug('Inside if');
                    acc.Active_NAP_Master_Contract__c = true;
                    //AccountIdsWithActiveNapMaster.add(acc);
            }else{
                    System.debug('Inside else');
                    acc.Active_NAP_Master_Contract__c = false;
                    //AccountIdsWithActiveNapMaster.add(acc);
            }
            acc.Validation_Override__c = true;
            AccountIdsWithActiveNapMaster.add(acc);
        }

        for(Id acc1 : AllAccountsIdsWithNapActiveAsTrue){
            if(!AccToContracts.containsKey(acc1)){
                Account acc = new Account(id = acc1);
                acc.Active_NAP_Master_Contract__c = false;
                acc.Validation_Override__c = true;
                AccountIdsWithActiveNapMaster.add(acc);
            }
        }


        System.debug('AccountIdsWithActiveNapMaster:::'+AccountIdsWithActiveNapMaster);
        List<Account> AccountIdsWithActiveNapMasterList = new List<Account>();
        AccountIdsWithActiveNapMasterList.addAll(AccountIdsWithActiveNapMaster);

//end SFDC-3091
        

        List<String> contractTypes = GsmUtilClass.getGSMSettingValue('CurrentSalesChannelContractTypes').split(',');
        List<merge_contract_header__c> mchActiveList = new List<Merge_contract_header__c>();
        //Get all the future Contracts for Accounts in scope which are Active and Contract Type is Direct Customer/Indirect Customer and it expires in future
        
        //List<AggregateResult> activeContractsGroup= [select Account_Name__c, Parent_Account_Name__c, Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Contract_Type__c from merge_contract_header__c where Active__c=true and isdeleted=false and Contract_Type__c in :contractTypes and Account_Name__c in :customerAccountIds and Effective_End_Date__c >= TODAY group by Account_Name__c,Parent_Account_Name__c, Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Contract_Type__c order by Account_Name__c];
        mchActiveList= [select Account_Name__c,Parent_Account_Name__c,Effective_End_Date__c,Contract_Type__c,Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                        Parent_Contract__c,Parent_Contract__r.Account_Name__c,Parent_Contract__r.Contract_Type__c,Parent_Contract__r.Parent_Account_Name__c,Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                        Parent_Contract__r.Parent_Contract__c,Parent_Contract__r.Parent_Contract__r.Account_Name__c,Parent_Contract__r.Parent_Contract__r.Contract_Type__c,Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c,Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                        Parent_Contract__r.Parent_Contract__r.Parent_Contract__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c
                        from merge_contract_header__c 
                        where Active__c=true and isdeleted=false and Contract_Type__c in :contractTypes and Account_Name__c in :customerAccountIds and Effective_End_Date__c >= TODAY];

        System.Debug(LoggingLevel.Error, 'AGH_D contracts:'+mchActiveList);


        //get all contract details for contracts of this customer account

        Map<String, Set<String>> externalIdToProducts = new Map<String, Set<String>>();
        Map<Merge_contract_header__c,Boolean> mchToParentDoNotContactCheckMap = new Map<Merge_contract_header__c,Boolean>();
        Set<String> marketingProductIds = new Set<String>();
        Map<String,Date> externalIdToYEEDate = new Map<String,Date>();
        Map<String,Date> externalIdToOEEDate = new Map<String,Date>();


        //Query for all the Contract Details for the Account's Contract in scope
        List<Merge_Contract_Detail__c> mcdList = [select Original_Contract_Id__r.Contract_Type__c,Original_Contract_Id__r.Account_Name__c,Original_Contract_Id__r.Effective_End_Date__c, Original_Contract_Id__r.Parent_Account_Name__c, Product__c, Product_Id__c,Original_Contract_Id__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                                                  Original_Contract_Id__r.Parent_Contract__c,Original_Contract_Id__r.Parent_Contract__r.Contract_Type__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Account_Name__c,Original_Contract_Id__r.Parent_Contract__r.Account_Name__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Original_Contract_Id__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                                                  Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c,
                                                  Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c,Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c
                                                  
                                                  
                                                  from Merge_Contract_Detail__c 
                                                  
                                                  where Original_Contract_Id__r.Account_Name__c in :customerAccountIds and Original_Contract_Id__r.Active__c=true and Original_Contract_Id__r.Contract_Type__c in :contractTypes and Original_Contract_Id__r.IsDeleted=false and Original_Contract_Id__r.Effective_End_Date__c >= TODAY];

        //SFDC-1481
        List<Partner_Client_Manager__c> pcmList = [Select Indirect_Account__c,Partner_Account__c,Akamai_User__c,Akamai_User__r.Name,Manager_Type__c from Partner_Client_Manager__c where Indirect_Account__c in :customerAccountIds];
        System.Debug(LoggingLevel.Error, 'AGH_D contract detail in CurrentSalesChannelBatchClass'+mcdList);
        System.Debug(LoggingLevel.Error, 'rsh pcmList in CurrentSalesChannelBatchClass'+pcmList);
        String internalManagerTypes = GsmUtilClass.getGSMSettingValue('CurrentSalesChannelInternalManagerTypes');
        String partnerManagerType = GsmUtilClass.getGSMSettingValue('CurrentSalesChannelpartnerManagerType');
        Map<String, String> externalIdToPcm = new Map<String, String>();

        for(Partner_Client_Manager__c pcm : pcmList){
            String partnerClientManager ='';
            if(internalManagerTypes.contains(pcm.Manager_Type__c))
                partnerClientManager = pcm.Akamai_User__r.Name;
            else if(partnerManagerType.contains(pcm.Manager_Type__c))
                partnerClientManager = 'Partner Led';
            externalIdToPcm.put(pcm.Indirect_Account__c+'#'+pcm.Partner_Account__c,partnerClientManager);
        }
        System.Debug(LoggingLevel.Error,'externalIdToPcm: '+externalIdToPcm);

        for(Merge_Contract_Detail__c mcd : mcdList)
        { 
            //Check if mcd.contract.type == direct then the Parent Account is equted to null and the Contract Account becomes the Direct Customer Account 
            if(mcd.Original_Contract_Id__r.Contract_Type__c == 'Direct Customer')
            {
                System.Debug(LoggingLevel.Error, 'Hitesh_D Inside Direct Check'+mcd.Original_Contract_Id__r.Account_Name__c);
                //if(mcd.Original_Contract_Id__r.Account_Name__c==mcd.Original_Contract_Id__r.Parent_Account_Name__c)
                    mcd.Original_Contract_Id__r.Parent_Account_Name__c=null;
            }
            //Get all the Product Ids from Contract Detail Record to Query Component Product from PMI SKU table
            marketingProductIds.add(mcd.Product_Id__c);
        }
        System.Debug(LoggingLevel.Error, 'AGH_D MArketing Product Id map '+marketingProductIds);

        Map<String, String> marketingProductIdToProductName = new Map<String, String>();
        //PMI SKU table being used to get the parent product name 
        //Assumption - There is only one Component Product against each Marketing Product Id in PMI SKU table
        //This component Product becomes the Contracted Product for Current Sales Channel Record
        for(PMI_SKU__c psku : [select Parent_Product_Name__c, Marketing_Product_Id__c,Component_Product_Name__c from PMI_SKU__c where Marketing_Product_Id__c in :marketingProductIds ])
        {
            if(marketingProductIdToProductName.isEmpty())
            {
               if(psku.Component_Product_Name__c != null)
                    marketingProductIdToProductName.put(psku.Marketing_Product_Id__c, psku.Component_Product_Name__c) ;
            }
            else
            {
                if(!marketingProductIdToProductName.containsKey(psku.Marketing_Product_Id__c))
                   {
                    if(psku.Component_Product_Name__c != null)
                        marketingProductIdToProductName.put(psku.Marketing_Product_Id__c, psku.Component_Product_Name__c); 
                    }
            } 
                    


            //marketingProductIdToProductName.put(psku.Marketing_Product_Id__c, psku.Parent_Product_Name__c);
        }
        System.Debug(LoggingLevel.Error, 'AGH_D MArketing Product Id map to Product '+marketingProductIdToProductName);

        //Loop through all the Contract details to formulate externalIdToProducts map
        //Key is calculated based on Customer Account # ParentAccount/Account on first immediate Reseller Contract for Indirect Customer Contracts
        //We travel up the hierarchy using Parent Contract field until we find a Contract of type Resellerto calculate the PArentAccount/Account for the key
        //mchToParentDoNotContactCheckMap Map is used to get the Partner Account's flag value 
        for(Merge_Contract_Detail__c mcd : mcdList)
        {
            String key;
            if(mcd.Original_Contract_Id__r.Contract_Type__c == 'Direct Customer')
                {
                    key = mcd.Original_Contract_Id__r.Account_Name__c+'#'+null;
                    mchToParentDoNotContactCheckMap.put(mcd.Original_Contract_Id__r,false);
                }
            else
                {
                    if(mcd.Original_Contract_Id__r.Parent_Contract__c != null && mcd.Original_Contract_Id__r.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                        {   
                            if(mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Account_Name__c != null)
                                {
                                    key = mcd.Original_Contract_Id__r.Account_Name__c+'#'+mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Account_Name__c;
                                    mchToParentDoNotContactCheckMap.put(mcd.Original_Contract_Id__r,mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                                }
                            else
                                {
                                    key = mcd.Original_Contract_Id__r.Account_Name__c+'#'+mcd.Original_Contract_Id__r.Parent_Contract__r.Account_Name__c;
                                    mchToParentDoNotContactCheckMap.put(mcd.Original_Contract_Id__r,mcd.Original_Contract_Id__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                                }
                        }
                    else if(mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__c != null && mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                        {
                            if(mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c != null)
                                {
                                    key = mcd.Original_Contract_Id__r.Account_Name__c+'#'+mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c;
                                    mchToParentDoNotContactCheckMap.put(mcd.Original_Contract_Id__r,mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c); 
                                }
                            else
                                {
                                    key = mcd.Original_Contract_Id__r.Account_Name__c+'#'+mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c;
                                    mchToParentDoNotContactCheckMap.put(mcd.Original_Contract_Id__r,mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                                }
                                
                        }
                    else if(mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c != null && mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                        {
                            if(mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c != null)
                                {
                                    key = mcd.Original_Contract_Id__r.Account_Name__c+'#'+mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c;
                                    mchToParentDoNotContactCheckMap.put(mcd.Original_Contract_Id__r,mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                                }
                            else
                                {
                                    key = mcd.Original_Contract_Id__r.Account_Name__c+'#'+mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c;
                                    mchToParentDoNotContactCheckMap.put(mcd.Original_Contract_Id__r,mcd.Original_Contract_Id__r.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                
                                }
                            }
                
            
            }
            String productName = marketingProductIdToProductName.containsKey(mcd.Product_Id__c) ? marketingProductIdToProductName.get(mcd.Product_Id__c) : 'Not Found';
            System.Debug(LoggingLevel.Error, 'AGH_D MArketing Product Id map to Product '+productName);
            //Youngest effective end date is the closest End date from now for all the Contratcs under one Current sales channel
            //Oldest effective end date is the farthest End date from now for all the Contratcs under one Current sales channel
            if(externalIdToProducts.containsKey(key))
            {
                externalIdToProducts.get(key).add(productName);
                if(!externalIdToYEEDate.containsKey(key))
                    externalIdToYEEDate.put(key,mcd.Original_Contract_Id__r.Effective_End_Date__c);
                else if(externalIdToYEEDate.get(key) > mcd.Original_Contract_Id__r.Effective_End_Date__c)
                        externalIdToYEEDate.put(key,mcd.Original_Contract_Id__r.Effective_End_Date__c);

                if(!externalIdToOEEDate.containsKey(key))
                    externalIdToOEEDate.put(key,mcd.Original_Contract_Id__r.Effective_End_Date__c);
                else if(externalIdToOEEDate.get(key) < mcd.Original_Contract_Id__r.Effective_End_Date__c)
                        externalIdToOEEDate.put(key,mcd.Original_Contract_Id__r.Effective_End_Date__c);
                    

            }
            else
            {
                externalIdToProducts.put(key, new Set<String>{productName});
                externalIdToYEEDate.put(key,mcd.Original_Contract_Id__r.Effective_End_Date__c);
                externalIdToOEEDate.put(key,mcd.Original_Contract_Id__r.Effective_End_Date__c);    
            }
        }

        System.Debug(LoggingLevel.Error, 'AGH_D externalIdToProducts'+externalIdToProducts);
        // get existing summary records to compare
        //Getting all the current Sales records and comapre based on the External Id
        //If any Update/Insert it will be updated here and if any Delete then the Delete Job will take care of it weekly.

        List<Current_Sales_Channel__c> existingSummaryRecords = [select Id, Name, Customer_Account__c,Customer_Account__r.Direct_Customer__c ,Customer_Account__r.Indirect_Customer__c , Partner_Account__c,CurrentSalesChannelExternalID__c,Has_Partner_Prohibited_Marketing__c, Products_Contracted__c,Oldest_Effective_End_Date__c,Youngest_Effective_End_Date__c,Partner_Client_Manager__c from Current_Sales_Channel__c where Customer_Account__c in :customerAccountIds];
        System.Debug(LoggingLevel.Error, 'AGH_D existingSummaryRecords size'+existingSummaryRecords.size());
        
        CurrentSalesChannelCollection existingSummaries = new CurrentSalesChannelCollection(existingSummaryRecords);
        system.debug(LoggingLevel.Error,'MCH Active Records '+mchActiveList);

        for(merge_contract_header__c mch : mchActiveList)
        {            
            String key = null;
            if(mch.Contract_Type__c == 'Direct Customer')
            {
                    key = mch.Account_Name__c+'#'+null;
                    mchToParentDoNotContactCheckMap.put(mch,false);
                    
            }

            else
            {
                if(mch.Parent_Contract__c != null && mch.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                {
                    if(mch.Parent_Contract__r.Parent_Account_Name__c != null)
                    {
                        key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Account_Name__c;
                        mchToParentDoNotContactCheckMap.put(mch,mch.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c);

                    }
                    else 
                    {
                        key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Account_Name__c;
                        mchToParentDoNotContactCheckMap.put(mch,mch.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                    }
                    
                    
                    
                }
                else if(mch.Parent_Contract__r.Parent_Contract__c != null && mch.Parent_Contract__r.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                {
                    if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c != null)
                    {
                        key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c;
                        mchToParentDoNotContactCheckMap.put(mch,mch.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                    }
                    else
                    {
                       key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Account_Name__c;
                       mchToParentDoNotContactCheckMap.put(mch,mch.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c); 
                    }
                    
                   
                    
                }
                else if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__c != null && mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Contract_Type__c.contains('Reseller'))
                {
                    if(mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c != null)
                    {
                        key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__c;
                        mchToParentDoNotContactCheckMap.put(mch,mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Parent_Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                    }
                    else
                    {
                       key = mch.Account_Name__c+'#'+mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__c;
                       mchToParentDoNotContactCheckMap.put(mch,mch.Parent_Contract__r.Parent_Contract__r.Parent_Contract__r.Account_Name__r.Do_Not_Contact_Indirect_Customers__c);
                    
                    }
                    
                }
                
            
            }
            system.debug(LoggingLevel.Error,'Hitesh Key before Map '+key);
            system.debug(LoggingLevel.Error,'Hitesh MCH beforeMap '+mch);
            
            
            if(!externalIdToYEEDate.containsKey(key))
                externalIdToYEEDate.put(key,mch.Effective_End_Date__c);
            else if(externalIdToYEEDate.get(key) > mch.Effective_End_Date__c)
                externalIdToYEEDate.put(key,mch.Effective_End_Date__c);
            
            if(!externalIdToOEEDate.containsKey(key))
                    externalIdToOEEDate.put(key,mch.Effective_End_Date__c);
            else if(externalIdToOEEDate.get(key) < mch.Effective_End_Date__c)
                        externalIdToOEEDate.put(key,mch.Effective_End_Date__c);
            
            system.debug(LoggingLevel.Error,'Hitesh MCHKey Map Other Map'+mchToParentDoNotContactCheckMap);

            if(key != null)
            {
                    CurrentSalesChannelWrapper newSummary = new CurrentSalesChannelWrapper(mch,key,mchToParentDoNotContactCheckMap);
                    //SFDC-1481 - set partner client manager, if its an indirect account i.e. indirect contract
                    system.debug(LoggingLevel.ERROR,'newSummary.csc.Partner_Account__c: '+newSummary.csc.Partner_Account__c);
                    if(!String.isBlank(newSummary.csc.Partner_Account__c))
                        newSummary.addPartnerClientManager(externalIdToPcm.get(key));
                    system.debug(LoggingLevel.Error,'Hitesh externalIdToProducts Map '+externalIdToProducts + 'Key '+key);
        
                    //Populate the new Summary record based on the Key calculated and the Products Contracted
                    if(externalIdToProducts.containsKey(key))
                    {
                        newSummary.addProducts(externalIdToProducts.get(key));
                        newSummary.addDates(externalIdToOEEDate.get(key),externalIdToYEEDate.get(key));
                    }
                    else
                    {
                        system.debug(LoggingLevel.Error,'Inside else part ');
                        // maybe there are no contract details
                        newSummary.addProducts(new Set<String>{'Not Found'});
                        newSummary.addDates(externalIdToOEEDate.get(key),externalIdToYEEDate.get(key));
        
                    }
        
                    //Check if the New Summary record already exists in system then it is an update otherwise an Insert.
        
                    System.Debug(LoggingLevel.Error, 'AGH_D newSummary products added'+newSummary);
        
                    if(existingSummaries.contains(newSummary))
                    {
                        System.Debug(LoggingLevel.Error, 'AGH_D existing');
                        CurrentSalesChannelWrapper existingSummary = existingSummaries.getExisting(newSummary);
                        System.Debug(LoggingLevel.Error, 'AGH_D existing'+existingSummary);
                        if(!newSummary.equals(existingSummary))
                        {
                            System.Debug(LoggingLevel.Error, 'AGH_D modifyng existing');
                            existingSummaries.modifyExistingSummaryWith(newSummary);
                        }
                    }
                    else
                    {
                        existingSummaries.add(newSummary);
                    } 
                }
            
        }
        system.debug(LoggingLevel.Error,'MCH Active MAp '+externalIdToOEEDate + ' '+externalIdToYEEDate);

       
        

        List<Current_Sales_Channel__c> summaryRecordsToBeUpserted = existingSummaries.getRecordsToBeUpserted();
        /*List<Current_Sales_Channel__c> summaryRecordsToBeDeleted = new List<Current_Sales_Channel__c>();
        
        Map<String,Current_Sales_Channel__c> externalIdtoCSCToBeUpsertedRecordMap = new Map<String,Current_Sales_Channel__c>();
        Map<String,Current_Sales_Channel__c> externalIdtoCSCToBeDeletedRecordMap = new Map<String,Current_Sales_Channel__c>();
        //Get all the records which are in scope but not marked for Upsert
        
        for(Current_Sales_Channel__c cscTBU : summaryRecordsToBeUpserted)
            {
                externalIdtoCSCToBeUpsertedRecordMap.put(cscTBU.CurrentSalesChannelExternalID__c,cscTBU);
            }
        
        
            for(Current_Sales_Channel__c csc : existingSummaryRecords)
            {
                if(!externalIdtoCSCToBeUpsertedRecordMap.containsKey(csc.CurrentSalesChannelExternalID__c))
                    externalIdtoCSCToBeDeletedRecordMap.put(csc.CurrentSalesChannelExternalID__c,csc);
            }
        
        if(externalIdtoCSCToBeDeletedRecordMap.size() > 0)
            summaryRecordsToBeDeleted = externalIdtoCSCToBeDeletedRecordMap.values();
        

        System.Debug(LoggingLevel.Error, 'AGH_D summaryRecordsToBeUpserted'+summaryRecordsToBeUpserted);
        System.Debug(LoggingLevel.Error, 'AGH_D summaryRecordsToBeDeleted'+summaryRecordsToBeDeleted);*/

        if(summaryRecordsToBeUpserted.size()>0)
        {
            results.add(Database.upsert(summaryRecordsToBeUpserted,Current_Sales_Channel__c.Fields.CurrentSalesChannelExternalID__c, false),summaryRecordsToBeUpserted);
        }
        /*if(summaryRecordsToBeDeleted.size() > 0)
        {
            deleteResults.dmlDelete(summaryRecordsToBeDeleted);
        }*/
        if(AccountIdsWithActiveNapMasterList.size()>0){
            Database.update(AccountIdsWithActiveNapMasterList);
        }

        
    }

    global void finish(Database.BatchableContext BC)
    {
        System.Debug(LoggingLevel.Error, 'AGH_D finish method');
        //results.withJobName('Current Sales Channel').toAddress(GsmUtilClass.getGSMSettingValue('CurrentSalesChannelEmailLogToAddress')).sendLogMail();
        //results.toAddress('smore@akamai.com').sendLogMail();
        //deleteResults.withJobName('Current Sales Channel').toAddress(GsmUtilClass.getGSMSettingValue('CurrentSalesChannelEmailLogToAddress')).sendLogMail();
        if(triggerDelete)               
        {       
            CurrentSalesChannelDeletionBatchClass cscDelete = new CurrentSalesChannelDeletionBatchClass();      
            Database.executeBatch(cscDelete);       
        }
        
    }
 }