/*=====================================================================================================+
Class name          :   SC_DD_ProcessPreDealData_Batch
Author              :   Himanshu,Vishnu,Vamsee
Created             :   10-Mar-20
Purpose             :   For Preprocessing of Data for each Account.  
                        Called From - SC_DD_ProcessODIDataJob (Batch Class)
Test Class          :   SC_DD_DealDeskTest

Last Modified Developer                 Purpose             
============= ========================  =======
10-Mar-20     Himanshu,Vishnu,Vamsee    Initial Development(Jira Ticket# FFPSA-850) 
Database.executeBatch(new SC_DD_ProcessPreDealData_Batch('15R-3LPL'));
12-Mar-21   Vishnu Vardhan     ESESP-4937      GRAZT changes
+=====================================================================================================*/


global class SC_DD_ProcessPreDealData_Batch implements Database.Batchable<sObject>, Database.stateful,Database.AllowsCallouts{
  
    // .........Stateful Interface for - Error Variables, AllowsCallouts Interface for - Webservice Query............
      
    // Instantiating Support Class
    SC_DD_ProcessPreDealData_Support supportClass = new SC_DD_ProcessPreDealData_Support();
    
    // Batch Query Variable
    public string batchQuery = supportClass.accountBatchQuery; 
    
    // Error Message Variable (key = Account Id, Value = Error Message)
    public string errorMessage =  'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                              'Batch Class Name = SC_DD_ProcessPreDealData_Batch\n\n' ;
    
    // Variable to count the no of Errors                        
    public integer noOfErrors = 0;
    string LimitDetails;
    
    public string AKAM_Account_Id;
    
    //................. List of Variables for Pre Processing (Used every time in Execute Method)..................
    
    // data set from dataload will be of previous month/Month specified in the custom setting, hence taking end date as last day of previous month
    // and start date will be 1 year older than end date
    
    
    Date END_DATE;
    
    Date START_DATE;
    
    // Key = Marketing Product Id , Value = GSS Service Product  For PS data
    Map<String, String> PS_MktProdId_ServcProdMap = new Map<String, String>(); 
    
    // Key = Support Level , Value = List of GSS Service Product  For Akatec data
    Map<String, List<String>> AKATEC_SuppLevel_ServcProdMap = new Map<String, List<String>>();  
   
    // Key = Case Product , Value = List of GSS Service Product  For SOCC data
    Map<String, List<String>> SOCC_CaseProd_ServcProdMap = new Map<String, List<String>>(); 
    
    // Key = Cost Key , Value = Per Head Cost
  Map<String, Decimal> costDataMap = new Map<String, Decimal>(); 
  
  // Key = Task Type , Value = LOE in Min
  Map<String, Decimal> TaskType_LOEMap = new Map<String, Decimal>(); 
    
    // For Storing All GSS product names (No Product Type to be considered for SOA,Standard & Managed Integration)
    public set<string> allGSSProducts = new set<string>();
    
    //Key = MRR Prod Name, Value = GSS Service Product  For Customer MRR
    Map<String, String> MRR_Prod_ServcProdMap = new Map<String, String>(); 
    
    // Parameterized Constructor (If you want to run for single Account pass the Account else Pass null)
    public SC_DD_ProcessPreDealData_Batch(string Account_id){
        
        SC_DD_Utility__c DDSetting = SC_DD_Utility__c.getValues('DD Setting');
      if(DDSetting.End_date__c != null){
        END_DATE = DDSetting.End_date__c;
      }
      else{
        END_DATE = System.today().addDays(-System.today().day());
      }
        START_DATE = END_DATE.addYears(-1);
        if(Account_id != null){
            AKAM_Account_Id = Account_id;
            Delete [SELECT Id FROM SC_DD_Customer_PreDeal_Data__c WHERE Akam_Account_ID__c =: Account_id];
            batchQuery = batchQuery + ' and AKAM_Account_Id__c =\'' + Account_id + '\'';
        }
        
         
        if(System.Test.isRunningTest()){
            batchQuery += ' LIMIT 50';
            START_DATE = System.today().addDays(-1);
            END_DATE = System.today().addDays(1);
        }
        
        // Call to initialize Method     
        supportClass.initializedata(PS_MktProdId_ServcProdMap, AKATEC_SuppLevel_ServcProdMap, SOCC_CaseProd_ServcProdMap,
                    costDataMap, TaskType_LOEMap, allGSSProducts, MRR_Prod_ServcProdMap);
    }

  // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator(batchQuery);
        
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
       
        string errHdr = ' ******* ';
        
        // 1. For Storing all Akam Account Ids for Calculation
        List<string> accIds = new List<string>();
          
        // 2. Map key = Akam Account ID + GSS Product, Value = PS Details including Budget Hour
        Map<string,SC_DD_ProcessPreDealData_Support.PSWrapper> accountprod_psdetailsMap 
                      = new Map<string,SC_DD_ProcessPreDealData_Support.PSWrapper>();
                      
        // 3. Map Key = Akam Account Id + GSS Product, Value = List<Case>
        Map<string, List<Case>> Akatec_AccountProd_CaseListMap = new Map<string, List<Case>>();
        
        // 4. For Storing all Ownerids for Akatec & SOCC data
        set<Id> allOwnerIds = new set<Id>();
        
        // 5.  Map Key = Akam Account Id + GSS Product, Value = List<Task>
        Map<string, List<Task>> SOCC_AccountProd_TaskListMap = new Map<string, List<Task>>();
        
        // 6. Map Key = UserId, Value = User Rec, reason is we have to check Department for SOCC
        Map<Id, User> userId_CostKeyMap = new Map<Id, User>();
        
        // 7.  Map Key = Akam Account Id + GSS Product, Value = List<SC_DD_Revenue__c>
        Map<string, List<SC_DD_Revenue__c>> Revenue_AccountProd_RevListMap = new Map<string, List<SC_DD_Revenue__c>>();
        
        Map<string, double> MRR_AccountProd_Revenue = new Map<string, double>();
        
        // 9. Final List to insert Pre Deal Data
        List<SC_DD_Customer_PreDeal_Data__c> preDealInsertList = new List<SC_DD_Customer_PreDeal_Data__c>();
        SC_DD_Customer_PreDeal_Data__c eachPreDealrec;
        string mapKey;
        
        // 10. For Storing GRAZT value for Account
        string GRAZTValue;
        
        List<string> filterAccountPS = new List<string>();
        
       // Step - 1 : Taking the Current Account for Calculation
       List<Account> accountList = (Account[]) scope;
       for(Account acc: accountList) {
            accIds.add(acc.Akam_Account_Id__c);
        }
        system.debug('---accIds----'+accIds);
        
       
        
        try {
          system.debug('---START_DATE---'+START_DATE);
            system.debug('---END_DATE---'+END_DATE);
      // Step - 2 : Get all PS Data for relevant Accounts
      accountprod_psdetailsMap = supportClass.getAllPSData(accIds,ps_MktProdId_ServcProdMap,START_DATE,END_DATE,costDataMap,filterAccountPS );
      
          system.debug('--filterAccountPS--'+filterAccountPS);
      
            // Step - 3 : Get all Akatec Case Data for relevant Accounts
      supportClass.getAllAkatecCases(filterAccountPS, AKATEC_SuppLevel_ServcProdMap, START_DATE, END_DATE, Akatec_AccountProd_CaseListMap, allOwnerIds);
     
      // Step - 4 : Get all SOCC Case Data for relevant Accounts
      supportClass.getAllSOCCCases(filterAccountPS, SOCC_CaseProd_ServcProdMap, START_DATE, END_DATE, SOCC_AccountProd_TaskListMap, TaskType_LOEMap,
                  allOwnerIds);
     
      // Step - 5 : Query on User to get Cost Key
      supportClass.getCostkey_Owners(allOwnerIds, userId_CostKeyMap);
            
            allOwnerIds.clear();
  
      // Step - 6 : Get Revenue Data for  relevant Accounts
      supportClass.getRevenueData(accIds, Revenue_AccountProd_RevListMap);
        
          // Step - 7 : Get Customer MRR for  relevant Accounts
      supportClass.getCustomerMRRData(accIds, MRR_Prod_ServcProdMap, MRR_AccountProd_Revenue);
      
                
        // Step - 7 (Final Calculation) : Loop for each Account
        for(Account acc: accountList) {
          GRAZTValue = acc.TERR_HIER_1__c + '-' + acc.TERR_HIER_2__c + '-' + acc.TERR_HIER_3__c + '-' + 
                  acc.TERR_HIER_4__c + '-' + acc.TERR_HIER_5__c;
                  
          // Step - 8 : Loop for each GSS Product
          for(string eachGSSProduct : allGSSProducts){
            
                     
            // Step - 9 : Instantiate PreDeal Object
            eachPreDealrec = new SC_DD_Customer_PreDeal_Data__c(Akam_Account_ID__c = acc.Akam_Account_Id__c, 
                                      Product_name__c    = eachGSSProduct, 
                                      Account_DGRAT__c = GRAZTValue,
                                      Status__c = 'InActive');
            mapKey = acc.Akam_Account_Id__c + '-' + eachGSSProduct;
                    
                    //Customer MRR Value
                    eachPreDealrec.Current_Customer_Role_MRR__c  = (MRR_AccountProd_Revenue.get(mapKey) != null ? MRR_AccountProd_Revenue.get(mapKey) : 0);
                    
                    //Budget Hour Calculation
            if(accountprod_psdetailsMap.get(mapKey) != null && accountprod_psdetailsMap.get(mapKey).budgetHour_currPSProj > 0)
              eachPreDealrec.PS_Budget_Hour__c = accountprod_psdetailsMap.get(mapKey).budgetHour_currPSProj;
            
                    
            // Step - 10 :  If PS Cost > 0, then call all cost calculation
            if(accountprod_psdetailsMap.get(mapKey) != null && accountprod_psdetailsMap.get(mapKey).deliveryCost_Total > 0){
                        System.debug('---PS Delivery Cost is more than zero--');
              
                        // Step - 11 : Call to PS Calculation Method
            supportClass.PS_Calculation(accountprod_psdetailsMap.get(mapKey), eachPreDealrec);  
            
            // Step - 12 : Call to Akatec Calculation Method
            if(Akatec_AccountProd_CaseListMap.get(mapKey) != null){
                            system.debug('--inside akatec--');
            supportClass.Akatec_Calculation(Akatec_AccountProd_CaseListMap.get(mapKey), 
                          accountprod_psdetailsMap.get(mapKey).filteredPSMonths, costDataMap,
                          userId_CostKeyMap, eachPreDealrec);
            }
          
                        
            // Step - 13 : Call to SOCC Calculation Method
            if(SOCC_AccountProd_TaskListMap.get(mapKey) != null){
            supportClass.SOCC_Calculation(SOCC_AccountProd_TaskListMap.get(mapKey), accountprod_psdetailsMap.get(mapKey).filteredPSMonths,
                          costDataMap, userId_CostKeyMap, TaskType_LOEMap, eachPreDealrec);
            }
          
          
            // Step - 14 : Call to Revenue Calculation Method 
            supportClass.Revenue_Calculation(Revenue_AccountProd_RevListMap.get(mapKey),
                              accountprod_psdetailsMap.get(mapKey).filteredPSMonths,eachPreDealrec);
              
              
            }
            else{
            
                
              // Step - 16 : Call to Revenue Calculation Method
              supportClass.Revenue_Calculation(Revenue_AccountProd_RevListMap.get(mapKey),
                            new set<Integer>(),eachPreDealrec);
            }
                    
            //system.debug('..Pre deal11='+preDealInsertList);
            
            // Step - 17 :Add to Final Insert List of Pre Deal Data
            preDealInsertList.add(eachPreDealrec);
            
          } // End Loop for Product
          
        } // End Loop for Account
       //system.debug('..Pre deal='+preDealInsertList);
       
           accountprod_psdetailsMap.clear();
      Akatec_AccountProd_CaseListMap.clear();
      allOwnerIds.clear();
      SOCC_AccountProd_TaskListMap.clear();
      userId_CostKeyMap.clear();
      Revenue_AccountProd_RevListMap.clear();
      MRR_AccountProd_Revenue.clear();
        
          // Step - 18 :Finally Inserting
          Insert preDealInsertList;
          
          LimitDetails = 'CPU Time(In Millisec)='+Limits.getCpuTime() + '-- CPU Time(Limit) ='+Limits.getLimitCpuTime() + '-- ' +
            'Heap Size used(in KB) ='+ Limits.getHeapSize()/1024 + '-- Heap Size Limit = ' + Limits.getLimitHeapSize()/1024 + '--' +
            'Total SOQL Rows ='+ Limits.getQueryRows() + '\n';
            
       errorMessage += '----------------------------Heap Size Details---------------------\n'+ LimitDetails +'\n--------------------------Heap size details end----------------\n';
            
    }catch(exception e){
    
      noOfErrors += 1;
            errorMessage += 'Account ID'+ accIds +'\n';
      errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                      + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                      + '\n' + errHdr + '\n';
            LimitDetails = 'CPU Time(In Millisec)='+Limits.getCpuTime() + '-- CPU Time(Limit) ='+Limits.getLimitCpuTime() + '-- ' +
            'Heap Size used(in KB) ='+ Limits.getHeapSize()/1024 + '-- Heap Size Limit = ' + Limits.getLimitHeapSize() + '--' +
            'Total SOQL Rows ='+ Limits.getQueryRows() + '\n';
            system.debug('hhh'+LimitDetails);
    }
        
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC){
        
        
        
        string setEmailSub = 'Exception: In Batch Job - SC_DD_ProcessPreDealData_Batch. # Of Errors : '+noOfErrors;
        
            
        SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
        sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
       
        
        // Step - 2 : Updating Custom Setting not to display any Data in UI
        SC_DD_Utility__c DDSetting = [SELECT Id,UI_Status__c FROM SC_DD_Utility__c WHERE Name = 'DD Setting' LIMIT 1];
        DDSetting.UI_Status__c = 'Processing';
        Update DDSetting;
        
        if(AKAM_Account_Id != null){
            List<SC_DD_Customer_PreDeal_Data__c> dealList = new List<SC_DD_Customer_PreDeal_Data__c>();
            for(SC_DD_Customer_PreDeal_Data__c eachDealData : [SELECT Id, Status__c FROM SC_DD_Customer_PreDeal_Data__c WHERE Akam_Account_ID__c =:AKAM_Account_Id AND Status__c = 'Inactive']){
                eachDealData.Status__c = 'Active';
                dealList.add(eachDealData);
            }
            if(dealList.size() > 0)
                Update dealList;
        }
        else{
            // Step - 3 : Calling Job to Delete Active Data & Update Status = Active for PreDeal Object
          Database.executebatch(new SC_DD_ProcessODIDataJob(false),2000);
        }
        
  }
  
    
}