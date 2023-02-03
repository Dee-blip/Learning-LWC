/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR          DESCRIPTION                               

|  ===========      =========       =======         =========== 
                                                       
|  16-MAR-2017      Himanshu Kar    3281921(17.3)     This batch class is used to sync the data from  CONTRACT_ENGINEERING_PRODUCT_DETAIL__c to   
                                                    SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c object 
                                                    - Called from
                                                    1. SC_Autogen_COB_Batch (Apex Class)
                                                    2. RecalculateEnggProductSync (Apex Trigger)
                                                    3. SC_showContractDetOnCase (VF Page)
--------------------------------------------------------------------------------------------------------
    04-Jul-2017     Vamsee S        ESESP-647(17.7) Added logic to handle when MCH record is not present on SFDC
+=====================================================================================================*/



global class SC_Sync_Contract_Eng_MrktgProd_Batch implements Database.Batchable<SObject>, Database.stateful {

    
    // Setting Error Message
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                        'Batch Class Name = SC_Sync_Contract_Eng_MrktgProd_Batch\n' + 
                                    'Support Class Name = SC_Sync_Contract_Eng_MrktgProd_Support\n' +
                                    'Method Name = processingLayer\n';
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    
    //Normal Execution Query for CONTRACT_ENGINEERING_PRODUCT_DETAILS
    public String batchQuery = Null;
    
    //Test Class Query
    public String TestClass_Query ; 
    
    // Variable to store Last time Run Value
    public DateTime lastRun;
    
    // Map to store BOCC Engg Product Name + Display Name
    public Map<string,string> BOCCProdmap = new Map<string,string>();
    public List<string> allBoccProd = new List<string>();
    
    //Property for sorting Field
    public String sortField {get;set;}
    
    //Property for sort order
    public String sortOrder {get;set;}
    
    //Boolean property for pagination
    public Boolean fromMethod {get;set;}
    
    // Constructor of Batch Class
    Public SC_Sync_Contract_Eng_MrktgProd_Batch(){
    
            this.lastRun = SC_SupportEmail__c.getValues('1').Last_EngMrktgProd_Synch_Job_Run__c;
            
            // Setting BOCCProductMap from Custom Metadata
            for (SC_BOCC_Entitlement_Product__mdt eachRec : [select Mapping_Prod_Name__c,MasterLabel  from 
                                                SC_BOCC_Entitlement_Product__mdt]){
                BOCCProdmap.put(eachRec.Mapping_Prod_Name__c, eachRec.MasterLabel); 
                allBoccProd.add(eachRec.Mapping_Prod_Name__c);                                      
            }
            
            //(EFFECTIVE_START_DATE__c = Today) is for Future Dated Contracts
            //isContractNotSynced__c will be marked true when Contract is not present on SFDC, So it will be picked in the next batch
            batchQuery = 'select CONTRACT_ID__c,EFFECTIVE_START_DATE__c,EFFECTIVE_END_DATE__c,ENGINEERING_PRODUCT_NAME__c,' + 
                        'MARKETING_PRODUCT_ID__c,MARKETING_PRODUCT_NAME__c,UNIQUE_KEY__c, isContractNotSynced__c' +
                        ' from CONTRACT_ENGINEERING_PRODUCT_DETAIL__c' + 
                        ' where ENGINEERING_PRODUCT_NAME__c IN :allBoccProd '+
                        ' and ((lastmodifieddate >= :lastRun and EFFECTIVE_START_DATE__c < Today) or (EFFECTIVE_START_DATE__c = Today) or (isContractNotSynced__c = True))' ;
                        
            this.TestClass_Query = batchQuery + ' order by Createddate Limit 10';       
            
    }
   
      
    /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
   global Database.QueryLocator start(Database.BatchableContext BC){
       
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : batchQuery;
        
        // Update the Custom Setting Value with Current Time Stamp for Last Run
        SC_SupportEmail__c UpdateLastRun = SC_SupportEmail__c.getValues('1');
        UpdateLastRun.Last_EngMrktgProd_Synch_Job_Run__c = system.now();
        Update UpdateLastRun;
        
        
        return Database.getQueryLocator(batchQuery);
   }
   
   global void execute(Database.BatchableContext BC, list<SObject> scope){
   
        string errHdr = ' ******* ';
   
        // List to store all Incoming Contract Header
        list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> allIncomingData = new list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
        allIncomingData = (CONTRACT_ENGINEERING_PRODUCT_DETAIL__c[]) scope ;
        
        try{    
        processingLayer(allIncomingData,false);
        }
        catch(Exception e)
            {
                noOfErrors += 1;
                errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                                + '\n' + errHdr + '\n';
            }
        
            
     }
     
      global void finish(Database.BatchableContext BC){
      
        string setEmailSub = 'Exception: In Batch Job - SC_Sync_Contract_Eng_MrktgProd_Batch. # Of Errors : '+noOfErrors;
       
          // Calling Send Email Method for Errors
         if(noOfErrors > 0){
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
         }
         
        // call delete method
        deleteExpiredData();
        
      }
      
      // Method-1: For Processing
      public void processingLayer(list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> allIncomingData, boolean isDeleteCall) {
      
        // set to store all Unique Original Contract Id
        set<string> allOrgContractIds = new set<string>();
        
        // Map to store ContractId+ProductId - List<MarketingProdNames>
        Map<string, set<string>> contractIdProductId_AllEnggProdListMap = new Map<string, set<string>>();
        
        // Map to store ContractId+ProductId - Earliest Effective Start Date
        Map<string, Date> contractIdProductId_EESDMap = new Map<string, Date>();
        
        // Map to store ContractId+ProductId - Latest Effective End Date
        Map<string, Date> contractIdProductId_LEEDMap = new Map<string, Date>();
        
        // List to store all CEPD Records
        list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> getRelatedCEPDrecs = new list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
        
        // Map-1 to store ContractId+ProductId - any CEPD Rec
        Map<string, CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> contractIdProductId_CEPDRecMap = new Map<string, CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
        
        // Map-2 to store ContractId+ProductId - List of valid Engg Products comma separated
        Map<string, string> contractIdProductId_validEnggProdMap = new Map<string, string>();
        
        // Map to store Org Contract Id - Contract rec
        Map<string, Merge_Contract_Header__c> contractId_MCHRecMap = new Map<string, Merge_Contract_Header__c>();
        
        // Step-1 : Loop for all Incoming Data for getting Unique Original Contract Id ..................
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c eachRec : allIncomingData){
            if(eachRec.CONTRACT_ID__c != null)
                allOrgContractIds.add(eachRec.CONTRACT_ID__c);
        } 
        
        // Step-2 : Designing Map (contractIdProductId_AllEnggProdListMap)....................
       if(allOrgContractIds.size() > 0){
        getRelatedCEPDrecs = [select CONTRACT_ID__c,EFFECTIVE_START_DATE__c,EFFECTIVE_END_DATE__c,ENGINEERING_PRODUCT_NAME__c,
                        MARKETING_PRODUCT_ID__c,MARKETING_PRODUCT_NAME__c,UNIQUE_KEY__c 
                        from CONTRACT_ENGINEERING_PRODUCT_DETAIL__c 
                        where CONTRACT_ID__c IN :allOrgContractIds and 
                        EFFECTIVE_START_DATE__c <= Today and 
                        EFFECTIVE_END_DATE__c >= Today
                        ];
        }
                        
        contractIdProductId_AllEnggProdListMap = setMapdata(allOrgContractIds, getRelatedCEPDrecs,contractIdProductId_CEPDRecMap,
                                                            contractIdProductId_EESDMap, contractIdProductId_LEEDMap); 
        
        // Step-3: Calculate Valid contracts who are Qualifying ...............
        
        // reuse of existing Variable which will store qualified contract Ids
        allOrgContractIds = new set<string>(); 
        allOrgContractIds = validateContracts(contractIdProductId_AllEnggProdListMap,contractIdProductId_validEnggProdMap,isDeleteCall);
        
        // Step-4 : Getting Contract Details from Merge Contract Header Object and call to sync method
        if(allOrgContractIds.size() > 0){
            
            for(Merge_Contract_Header__c eachMCHRec : [select Id,Account_Name__c,Original_Contract_ID__c from Merge_Contract_Header__c 
                                        where Original_Contract_ID__c IN :allOrgContractIds]){
                contractId_MCHRecMap.put(eachMCHRec.Original_Contract_ID__c, eachMCHRec);                      
            }
            
            // Method for syncing data
            callDataSync(contractIdProductId_validEnggProdMap,contractIdProductId_CEPDRecMap,contractId_MCHRecMap,
                        contractIdProductId_EESDMap, contractIdProductId_LEEDMap);
            
            //Update Engg product Contract based on Contract in SFDC. It should not call for Delete calls
            if(!isDeleteCall)
                marketingProductContractCheck(allIncomingData,contractId_MCHRecMap);
        }
        
        
      }
      
      // Method-2 : For setting contractIdProductId_AllEnggProdListMap Data
      public Map<string, set<string>> setMapdata (set<string> allOgContractIds, list<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> allCEPDrecs, 
                                Map<string, CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> contractIdProductId_CEPDRecMap,
                                Map<string, Date> contractIdProductId_EESDMap, Map<string, Date> contractIdProductId_LEEDMap ){
      
        // Map to store ContractId+ProductId - List<MarketingProdNames>
        Map<string, set<string>> contractIdProductId_AllEnggProdListMap = new Map<string, set<string>>();
        
        // Key to store contractId + Product Id
        string mapKey;
        
        // List to store Map Values
        set<string> mapValues; 
        
        // Loop for all CEPD Records
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c eachCEPDRec : allCEPDrecs){
        
            // Get the Key Value
            mapKey = eachCEPDRec.CONTRACT_ID__c + ':' + eachCEPDRec.MARKETING_PRODUCT_ID__c;
            
            if(contractIdProductId_AllEnggProdListMap.get(mapKey) == null){
            
                mapValues = new set<string>(); 
                contractIdProductId_EESDMap.put(mapKey,eachCEPDRec.EFFECTIVE_START_DATE__c);
                contractIdProductId_LEEDMap.put(mapKey,eachCEPDRec.EFFECTIVE_END_DATE__c); 
            }
            else
            {
                mapValues = contractIdProductId_AllEnggProdListMap.get(mapKey);
                
                // Condition for setting EESD
                if(contractIdProductId_EESDMap.get(mapKey) > eachCEPDRec.EFFECTIVE_START_DATE__c)
                    contractIdProductId_EESDMap.put(mapKey,eachCEPDRec.EFFECTIVE_START_DATE__c);
                    
                // Condition for setting LEED
                if(contractIdProductId_LEEDMap.get(mapKey) < eachCEPDRec.EFFECTIVE_END_DATE__c)
                    contractIdProductId_LEEDMap.put(mapKey,eachCEPDRec.EFFECTIVE_END_DATE__c);
            }
            
            mapValues.add(eachCEPDRec.ENGINEERING_PRODUCT_NAME__c);
            
            contractIdProductId_AllEnggProdListMap.put(mapKey, mapValues);
            contractIdProductId_CEPDRecMap.put(mapKey, eachCEPDRec);
        }
        
        return contractIdProductId_AllEnggProdListMap;
      }
      
      // Method-3 : For evaluating the Contracts whether they meet the criteria or not
      public set<string> validateContracts (Map<string, set<string>> contractIdProductId_AllEnggProdListMap, 
                                            Map<string, string> contractIdProductId_validEnggProdMap, boolean isDeleteCall){
      
        set<string> allQualifiedContracts = new set<string>();
        
        // List to store Map Values
        set<string> mapValues; 
        
        // string for getting ContractId from Key
        string getContractIdfromKey;
        
        // string to set all valid Engg Prod Names separated by comma
        string allValidEnggProdForContrat;
        
        // Loop for all the Map Key for evaluation
        for(string eachMapKey : contractIdProductId_AllEnggProdListMap.keyset()){
        
            allValidEnggProdForContrat = '';
            getContractIdfromKey = eachMapKey.substring(0, eachMapKey.indexOf(':'));
            mapValues = contractIdProductId_AllEnggProdListMap.get(eachMapKey);
            
            if(mapValues.contains ('Services_and_Support::Services_and_Support')){
            
                //Loop for each Map Value
                for(string eachMapValue : mapValues){
                
                    if(BOCCProdmap.keyset().contains(eachMapValue) && eachMapValue != 'Services_and_Support::Services_and_Support'){
                        allQualifiedContracts.add(getContractIdfromKey);
                        allValidEnggProdForContrat += BOCCProdmap.get(eachMapValue) + '; ';
                    }
                }
                
                // If any Valid Prod is there then add to Map. Or if it is called from Delete Trigger and no valid prod is there,
                // then add to Map with null value.Later on you can delete the records from finish method
                if(allValidEnggProdForContrat != null && allValidEnggProdForContrat.length() > 1)
                    contractIdProductId_validEnggProdMap.put(eachMapKey, allValidEnggProdForContrat);
                else if(allValidEnggProdForContrat == '' && isDeleteCall)
                    contractIdProductId_validEnggProdMap.put(eachMapKey, null);
            
            }
        }
        
        return allQualifiedContracts;
      }
      
    // Method-4 : For syncing Data
    public void callDataSync(Map<string, string> contractIdProductId_validEnggProdMap,Map<string, CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> contractIdProductId_CEPDRecMap,
                        Map<string, Merge_Contract_Header__c> contractId_MCHRecMap, 
                        Map<string, Date> contractIdProductId_EESDMap, Map<string, Date> contractIdProductId_LEEDMap){
                        
            // List to store all Filtered data for Upsert Opeartion in Destn Object
            List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> allBoccDataForUpsert = new List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c>();
            
            // For Individual Rec
            SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c eachBoccRec;
            
            // Variable to store Account Id
            Id getAccountId;
            
            // Loop for each key for contractIdProductId_validEnggProdMap 
            for(string eachMapKey : contractIdProductId_validEnggProdMap.keyset()){
            
                getAccountId = (contractId_MCHRecMap.get(eachMapKey.substring(0, eachMapKey.indexOf(':'))) == null) ? null :
                            contractId_MCHRecMap.get(eachMapKey.substring(0, eachMapKey.indexOf(':'))).Account_Name__c;
                
                if(getAccountId != null){
                
                eachBoccRec = new SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c();
                eachBoccRec.Account__c              = contractId_MCHRecMap.get(eachMapKey.substring(0, eachMapKey.indexOf(':'))).Account_Name__c;
                eachBoccRec.Area__c             = contractIdProductId_validEnggProdMap.get(eachMapKey);
                eachBoccRec.Contract_ID__c           = eachMapKey.substring(0, eachMapKey.indexOf(':'));
                eachBoccRec.Effective_Start_Date__c     = contractIdProductId_EESDMap.get(eachMapKey);
                eachBoccRec.Effective_End_Date__c       = contractIdProductId_LEEDMap.get(eachMapKey);
                eachBoccRec.Marketing_Product_Name__c   = contractIdProductId_CEPDRecMap.get(eachMapKey).MARKETING_PRODUCT_NAME__c;
                eachBoccRec.Original_Contract_Id__c                 = contractId_MCHRecMap.get(eachMapKey.substring(0, eachMapKey.indexOf(':'))).Id;
                eachBoccRec.Product_ID__c           = contractIdProductId_CEPDRecMap.get(eachMapKey).MARKETING_PRODUCT_ID__c;
                eachBoccRec.Unique_Key__c           = eachMapKey;
            
                allBoccDataForUpsert.add(eachBoccRec);
                }
            }
            
            if(allBoccDataForUpsert.size() > 0)
                Upsert allBoccDataForUpsert Unique_Key__c;
    
    }
    
    // Method-5 : For deleting Expired Data
    public void deleteExpiredData(){
    
            // Delete Query
            delete [select Id from SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c 
                    where Effective_End_Date__c < Today or Area__c = null
                    limit 5000];
            
    }

    // Method-6 : For displaying Contract details on Case PageLayout
    public List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> allBoccDataForCasePage {get;set;}
    public Id getAccountIDFromCase;
    public SC_Sync_Contract_Eng_MrktgProd_Batch(ApexPages.StandardController Controller){
    
            //Setting the sort field & Controller
            sortField = 'Marketing_Product_Name__c';
            sortOrder = 'ASC';
            fromMethod = false;
            system.debug('Entering ');
            
            
            
            
    
            // Getting AccountId from Case Page
             getAccountIdFromCase = [select AccountId from case where Id = :ApexPages.currentPage().getParameters().get('id') limit 1].AccountId ;
            
            // Query to get the data for Related Account
            //allBoccDataForCasePage = [select Account__c,Area__c,Contract_ID__c,Effective_Start_Date__c,Effective_End_Date__c,Marketing_Product_Name__c, 
                                //Product_ID__c,Original_Contract_Id__c  from SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c 
                               // where Account__c = :getAccountIdFromCase order by Product_ID__c asc];
                                
            
              //String query ='select Account__c,Area__c,Contract_ID__c,Effective_Start_Date__c,Effective_End_Date__c,Marketing_Product_Name__c, Product_ID__c,Original_Contract_Id__c  from SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c where Account__c =\''+ getAccountIdFromCase+'\'';
                                
                   //query += ' Order by '+ String.escapeSingleQuotes(sortField) + ' ' + myOrder;
                   
                  // allBoccDataForCasePage=Database.query(query);
        
    }
    
    
    /* Method - 7 : This method check whether MCH record is synced for the particluar Engg product contract
     * If MCH record is synced then isContractNotsynced__c = false
     * If MCH record is not synced then isContractNotsynced__c = True(This will be marked as false in the next batch)
     */
    public void marketingProductContractCheck(List<Contract_Engineering_Product_Detail__c> allIncomingData, Map<string, Merge_Contract_Header__c> contractId_MCHRecMap){
        
        //List to store the Engg Product contract that need to be updated
        List<Contract_Engineering_Product_Detail__c> updateContractList = new List<Contract_Engineering_Product_Detail__c>();
        
        //Check for MCH record
        for(Contract_Engineering_Product_Detail__c eachRec : allIncomingData){
            if(contractId_MCHRecMap.get(eachRec.Contract_ID__c) == null ){
                eachRec.isContractNotsynced__c = True;
                updateContractList.add(eachRec);
            }
            else{
                if(eachRec.isContractNotsynced__c == True){
                    //if isContractNotsynced__c is marked as true in previous batch then update it to false if MCH record is synced
                    eachRec.isContractNotsynced__c = False;
                    updateContractList.add(eachRec);
                }
            }
        }
        if(updateContractList.size() > 0)
            Update updateContractList;
    }
    
     public ApexPages.standardSetController con{
        get{
            if(con == null)
            {
                Integer size = 5;
                con = new ApexPages.StandardSetController(allBoccDataForCasePage);
                con.setPageSize(size);
                Integer noOfRecords = con.getResultSize();
                //Debug
                System.debug('In standard set COntroller');
            }
            return con;
        }
        
        set;
    }
    public List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> getBoccDataForCasePage(){
    
        //Setting con=null to get refreshed data every time
        if(fromMethod)
        {
        con=null;
        
        }
        
        if(fromMethod)
        {
           fromMethod = false;
        
        }
        //Getting AccountId from Case Page
        //ID getAccountIdFromCase = [select AccountId from case where Id = :ApexPages.currentPage().getParameters().get('id') limit 1].AccountId ;
        
        //Query to get related Account Data
        String query ='select Account__c,Area__c,Contract_ID__c,Effective_Start_Date__c,Effective_End_Date__c,Marketing_Product_Name__c, Product_ID__c,Original_Contract_Id__c  from SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c where Account__c =\''+ getAccountIdFromCase+'\'';
        query += ' Order by '+ String.escapeSingleQuotes(sortField) + ' ' + sortOrder;
        
        system.debug(query);
        
        //Populate the list
        allBoccDataForCasePage=Database.query(query);
                   
                   
        if(fromMethod)
        {
           fromMethod = false;
        
        }
        
           
           
        List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c> lSc_BOCC = new List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c>();
        for(SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c sc_BOCC : (List<SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c>)con.getRecords())
            lSc_BOCC.add(sc_BOCC);
        
        
        return lSc_BOCC;
    }
    public Boolean hasNext{
        get{
            return con.getHasNext();
        }
        set;
    }
    public Boolean hasPrev{
        get{
            return con.gethasPrevious();
        }
        set;
    }
    public Integer getPageNumber{
        get{
            if(con.getResultSize()==0)
                return 0;
            else
                return con.getPageNumber();
        }
        set;
    }
    public Integer getTotalPageNumber{
        get{
            Integer totalPages = (Math.mod(con.getResultSize(),5) == 0) ? con.getResultSize()/5 :
                        con.getResultSize()/5 + 1;
            return totalPages;
        }
        set;
    }
    
    public void first(){
        con.first();
    }
    public void last(){
        con.last();
    }
    public void next(){
        con.next();
    }
    public void previous(){
        con.previous();
    }
}