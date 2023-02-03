/*=====================================================================================================+
Class name          :   SC_DD_ProcessPreDealData_Support
Author              :   Himanshu,Vishnu,Vamsee
Created             :   10-Mar-20
Purpose             :   This is the Utility Class for Deal Desk Functionality. Used in 
                        LC - 
                        Class - SC_DD_ProcessPreDealDataBatch
Test Class          :   SC_DD_DealDeskTest

Last Modified Developer                 Purpose             
============= ========================  =======
10-Mar-20     Himanshu,Vishnu,Vamsee    Initial Development(Jira Ticket# ESESP- ) 
12-12-201     Vishnu Vardhan            ESESP-4937      GRAZT changes

Database.executeBatch(new SC_DD_ProcessPreDealData_Batch('1-HS6AP'));
+=====================================================================================================*/

Public class SC_DD_ProcessPreDealData_Support{

    // Query - 1 : For Account Batch
    public String accountBatchQuery = 'SELECT Id,Akam_Account_Id__c,TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c FROM Account WHERE account_Status__c like \'%Active\''+
                                ' AND (NOT account_Status__c LIKE \'%Inactive\') AND (not name LIKE \'%Akamai%\') AND (NOT account_Status__c LIKE \'%Akamai Internal\') ';
    
    
    public class PSWrapper{
        decimal PS_Hours;
        public decimal deliveryCost_Total;
        decimal PS_PerHour_Cost;
        decimal PS_Hours_AvgMonthly;
        public decimal budgetHour_currPSProj;
        decimal PS_Non_Billable_Hours_c;
        decimal avg_monthly_NonBillHours;
        public set<Integer> filteredPSMonths;
        
        PSWrapper(){
            PS_Hours                    = 0;
            deliveryCost_Total          = 0;
            PS_PerHour_Cost             = 0;
            PS_Hours_AvgMonthly         = 0;
            budgetHour_currPSProj       = 0; // need to check
            PS_Non_Billable_Hours_c     = 0;
            avg_monthly_NonBillHours    = 0; 
            filteredPSMonths            = new set<Integer>();
        }
    }
    
    // Method - 1 : For Initializing Data
    public void initializedata (Map<String, String> PS_MktProdId_ServcProdMap, Map<String, List<String>> AKATEC_SuppLevel_ServcProdMap,
                                Map<String, List<String>> SOCC_CaseProd_ServcProdMap, Map<String, Decimal> costDataMap, 
                                Map<String, Decimal> TaskType_LOEMap, set<string> allGSSProducts, Map<String, String> mrr_Prod_ServcProdMap){
        
        List<String> mapValues;
        
        // 1. Loop for all Mapping Data
        for(SC_DD_Mapping__c eachMappingRec :   [SELECT Id, RecordType.Name, Product__r.Name, Support_Level__c, Case_Product__c, Customer_MRR_Name__c, 
                                                Parent_GSS_Product__r.Full_Name__c FROM SC_DD_Mapping__c WHERE End_of_Life__c = False]){
            
            // For PS Mapping
            if(eachMappingRec.recordType.Name == 'Professional Service'){   
                PS_MktProdId_ServcProdMap.put(eachMappingRec.Product__r.Name, eachMappingRec.Parent_GSS_Product__r.Full_Name__c);
            }
            
            // For Akatec Mapping
            else if(eachMappingRec.recordType.Name == 'Akatec') {               
                mapValues = (AKATEC_SuppLevel_ServcProdMap.get(eachMappingRec.Support_Level__c) == null) ? new List<String>() :
                                AKATEC_SuppLevel_ServcProdMap.get(eachMappingRec.Support_Level__c);
                mapValues.add(eachMappingRec.Parent_GSS_Product__r.Full_Name__c);
                AKATEC_SuppLevel_ServcProdMap.put(eachMappingRec.Support_Level__c, mapValues);
            }
            
            // For SOCC Mapping
            else if(eachMappingRec.recordType.Name == 'SOCC - Case Product') {  
                mapValues = (SOCC_CaseProd_ServcProdMap.get(eachMappingRec.Case_Product__c) == null) ? new List<String>() :
                                SOCC_CaseProd_ServcProdMap.get(eachMappingRec.Case_Product__c);
                mapValues.add(eachMappingRec.Parent_GSS_Product__r.Full_Name__c);
                SOCC_CaseProd_ServcProdMap.put(eachMappingRec.Case_Product__c, mapValues);
            }
                                                    
            //For Customer MRR
            else if(eachMappingRec.recordType.Name == 'Customer MRR'){
                mrr_Prod_ServcProdMap.put(eachMappingRec.Customer_MRR_Name__c, eachMappingRec.Parent_GSS_Product__r.Full_Name__c);
            }

        }
        
        // 2. For Cost Data
        for(SC_DD_Department_Cost__c eachCostrec : [SELECT Cost_Key__c,Cost_Per_Hour__c FROM SC_DD_Department_Cost__c 
                                                    WHERE Status__c = 'Active']){
            costDataMap.put(eachCostrec.Cost_Key__c , eachCostrec.Cost_Per_Hour__c);                                            
        }   
        
        // 3. For Getting All GSS Service products
        for(SC_DD_GSSServiceProduct__c eachGSSprod : [SELECT Full_name__c FROM SC_DD_GSSServiceProduct__c 
                                                      WHERE Is_Service_Support_Product__c = true AND Is_Active__c = true]){
            allGSSProducts.add(eachGSSprod.Full_name__c);                                   
        }   
        
        // 4. For Getting SOCC Task LOE
        for(SC_DD_SOCC_ConfigTask__mdt tskMd: [SELECT MasterLabel, LOE_Mins__c FROM SC_DD_SOCC_ConfigTask__mdt]) {
            TaskType_LOEMap.put(tskMd.MasterLabel, tskMd.LOE_Mins__c);
        }                               
    
    }
    
    // Method - 2 : To Get All PS Data
    public Map<string,PSWrapper> getAllPSData(List<string> accIds, Map<String, String> ps_MktProdId_ServcProdMap, Date START_DATE, 
                                                Date END_DATE, Map<String, Decimal> costDataMap, List<string> filterAccountPS ){
         
         String getServProdName;
         String getAkamAccountId;
         Map<string,List<pse__Timecard__c>> accServprod_timeCardList = 
                                                    new Map<string,List<pse__Timecard__c>>();   
         Map<string,Decimal>  accServprod_BudgetHoursMap = new  Map<string,Decimal>();                                      
         string mapKey;
         List<pse__Timecard__c> mapvalues;
         
         Set<String> filterAccountPSSet = new Set<String>();
         // designing Return map
         Map<string,PSWrapper> returnMap = new Map<string,PSWrapper>();                                           
         PSWrapper eachPSWrapRec;
         decimal getCostkey;
         
         // Loop - 1 : Setting accServprod_timeCardList Values                                           
         for(pse__Timecard__c psRec: getPSData(accIds, ps_MktProdId_ServcProdMap.keyset(), START_DATE, END_DATE)) {
                
             // To prepare AccountID+ServiceProduct
             getServProdName = ps_MktProdId_ServcProdMap.get(psRec.pse__assignment__r.project_contract_line_item__r.contract_detail__r.product_id__c);
             getAkamAccountId = psRec.pse__assignment__r.pse__Project__r.pse__Account__r.akam_account_id__c;
             mapKey = getAkamAccountId + '-' + getServProdName;
             
             //Adding Vales to the map  
             mapValues = (accServprod_timeCardList.get(mapKey) == null) ? new List<pse__Timecard__c>() :
             accServprod_timeCardList.get(mapKey);
             mapvalues.add(psRec);
             accServprod_timeCardList.put(mapKey, mapvalues);
        } 
          
        // 2nd Loop - Calculating & creating Wrapper Data
        for(string eachAccservProdkey : accServprod_timeCardList.keyset()){
            eachPSWrapRec = new PSWrapper();
               
            // Loop for each Value and calculate PS Values
            for(pse__Timecard__c psRec : accServprod_timeCardList.get(eachAccservProdkey)){
                
                //Check for Unit Price for Integration Products
                if(!((eachAccservProdkey.contains('Managed Integration') || eachAccservProdkey.contains('Standard Integration'))
                     && psRec.pse__assignment__r.project_contract_line_item__r.contract_detail__r.Unit_Price__c <= 0)){       
                    
                        getCostkey = costDataMap.get(psRec.pse__assignment__r.pse__Resource__r.pse__Salesforce_User__r.Cost_Key__c); 
                        eachPSWrapRec.filteredPSMonths.add(integer.valueOf(psRec.SC_DD_Year_Month__c));
                        
                        //Calculate Billable Hours 
                        if(psRec.pse__Timecard_Header__r.pse__Billable__c == true){
                            if(getCostkey > 0){
                                eachPSWrapRec.PS_Hours += psRec.pse__Total_Hours__c;
                                eachPSWrapRec.deliveryCost_Total += psRec.pse__Total_Hours__c * getCostkey;
                            }
                        }
                        //Calculate non-Billable Hours    
                        else {
                            eachPSWrapRec.PS_Non_Billable_Hours_c += psRec.pse__Total_Hours__c;  
                        }    
                    }
            }  
            // Calculate Additional Values    
            eachPSWrapRec.PS_PerHour_Cost = (eachPSWrapRec.PS_Hours == 0) ? 0: eachPSWrapRec.deliveryCost_Total / eachPSWrapRec.PS_Hours;
            eachPSWrapRec.PS_Hours_AvgMonthly = (eachPSWrapRec.filteredPSMonths.size() == 0) ? 0: eachPSWrapRec.PS_Hours / eachPSWrapRec.filteredPSMonths.size();
            eachPSWrapRec.avg_monthly_NonBillHours = (eachPSWrapRec.filteredPSMonths.size() == 0) ? 0: eachPSWrapRec.PS_Non_Billable_Hours_c / eachPSWrapRec.filteredPSMonths.size();
            
            // Adding to Filter Account Variable if PS Cost > 0
            if(eachPSWrapRec.deliveryCost_Total > 0){
                system.debug('--vamsee--'+eachAccservProdkey.substring(0,eachAccservProdkey.lastindexof('-') - 1));
                filterAccountPSSet.add(eachAccservProdkey.substring(0,eachAccservProdkey.lastindexof('-')));
            }
                
            // Adding to Return Map
            returnMap.put(eachAccservProdkey,eachPSWrapRec);
        }
            filterAccountPS.addall(filterAccountPSSet);
            //system.debug('---filterAccountPS-outside--'+filterAccountPS);
            filterAccountPSSet.clear();
            
                            
        // Step - 3 : Get Budget Data
        getBudgetHours(accIds,ps_MktProdId_ServcProdMap,accServprod_BudgetHoursMap);
            
            // Step - 4 : Loop for Budget Data(reason is this is independent of PS Data. If No PS Data but Budget exists, we will display)
            for(string eachAccservProdkey : accServprod_BudgetHoursMap.keyset()){
                system.debug('--inside for--');
                eachPSWrapRec = (returnMap.get(eachAccservProdkey) != null) ? returnMap.get(eachAccservProdkey) : new PSWrapper();
                eachPSWrapRec.budgetHour_currPSProj = accServprod_BudgetHoursMap.get(eachAccservProdkey);
                system.debug('--budgetHour_currPSProj--'+eachPSWrapRec.budgetHour_currPSProj);
                returnMap.put(eachAccservProdkey,eachPSWrapRec);
            }
         accServprod_BudgetHoursMap.clear();
         accServprod_timeCardList.clear();
         //mapvalues.clear();
         return returnMap;                          
    }
    
    //  Method - 3 : To Get All Akatec Data
    public void getAllAkatecCases(List<string> accIds, Map<String, List<String>> AKATEC_SuppLevel_ServcProdMap, Date START_DATE, 
                                    Date END_DATE, Map<string, List<Case>> Akatec_AccountProd_CaseListMap, set<Id> allOwnerIds){
    
        string mapKey;
        List<Case> mapValues;
        List<Case> akatecCases;
                      
        // Owner.Type filter doesn't work in test execution, so bypassing it ONLY for test execution                           
        if(Test.isRunningTest()) {
            akatecCases = [SELECT Account.AKAM_Account_Id__c, Support_Level__c, Task_LOE__c, SC_DD_Year_Month__c,OwnerId FROM case WHERE 
                                Recordtype.Name = 'Technical' AND isClosed = true AND //Owner.Type = 'User'
                                Account.AKAM_Account_Id__c IN :accIds AND Task_LOE__c > 0 AND 
                                Support_Level__c IN :AKATEC_SuppLevel_ServcProdMap.keyset() AND 
                                AKAM_Created_Date__c > :START_DATE AND AKAM_Created_Date__c <= :END_DATE];                    
        }
        else {
            akatecCases = [SELECT Account.AKAM_Account_Id__c, Support_Level__c, Task_LOE__c, SC_DD_Year_Month__c,OwnerId FROM case WHERE 
                                Recordtype.Name = 'Technical' AND Owner.Type = 'User' AND isClosed = true AND
                                Account.AKAM_Account_Id__c IN :accIds AND Task_LOE__c > 0 AND 
                                Support_Level__c IN :AKATEC_SuppLevel_ServcProdMap.keyset() AND 
                                AKAM_Created_Date__c > :START_DATE AND AKAM_Created_Date__c <= :END_DATE];
            
        }
        
        // Step - 1 : Query to get all Akatec Cases
        for(Case eachCaserec : akatecCases){

            // Loop for each Service product for a Support Level - reason is same Support Level exist for Many GSS products
            for(string eachGSSprod : AKATEC_SuppLevel_ServcProdMap.get(eachCaserec.Support_Level__c)){
                mapKey = eachCaserec.Account.AKAM_Account_Id__c + '-' + eachGSSprod;
                mapValues = (Akatec_AccountProd_CaseListMap.get(mapKey) == null) ? new List<Case>() :
                Akatec_AccountProd_CaseListMap.get(mapKey);
                mapvalues.add(eachCaserec);
                Akatec_AccountProd_CaseListMap.put(mapKey, mapvalues);
            }
                
            // Adding All Owner IDs to query later to Get User Cost Key
            allOwnerIds.add(eachCaserec.OwnerId);   
            //mapValues.clear();
        }
    }
    
    //  Method - 4 : To Get All SOCC Data
    public void getAllSOCCCases(List<string> accIds, Map<String, List<String>> SOCC_CaseProd_ServcProdMap, Date START_DATE, Date END_DATE, 
                                Map<string, List<Task>> SOCC_AccountProd_TaskListMap, Map<String, Decimal> TaskType_LOEMap, 
                                set<Id> allOwnerIds){
    
        string mapKey;
        List<Task> mapValues;
            
        //Step - 1 : Query to get all SOCC Cases
        for(Case eachCaserec : getSOCCDataFromWebService(accIds, SOCC_CaseProd_ServcProdMap.keyset(), TaskType_LOEMap.keyset(), START_DATE, END_DATE)) {
                
            //Step - 2 : Loop for each task for a Case
            for(Task eachtaskRec : eachCaserec.Tasks){
                
                //Loop for each Service product for a Case Product - reason is same Case Product exist for Many GSS products
                for(string eachGSSprod : SOCC_CaseProd_ServcProdMap.get(eachCaserec.Case_Product__r.name)){
                
                    mapKey = eachCaserec.AKAM_Account_Id__c + '-' + eachGSSprod;
                    mapValues = (SOCC_AccountProd_TaskListMap.get(mapKey) == null) ? new List<Task>() :
                                        SOCC_AccountProd_TaskListMap.get(mapKey);
                    mapvalues.add(eachtaskRec);
                    SOCC_AccountProd_TaskListMap.put(mapKey, mapvalues);
                
                }   //End of 3rd Loop
                
                //Adding All Owner IDs to query later to Get User Cost Key
                allOwnerIds.add(eachtaskRec.OwnerId);   
            
            } //End of 2nd Loop
            
        } //End of 1st Loop   
        
        //mapValues.clear();
           
    }
    
    // Method - 5 : Query On User to get Cost Key -- Cost_Key__c
    public void getCostkey_Owners(set<Id> allOwnerIds, Map<Id,User> userId_CostKeyMap){
        for(User eachUsrRec : [SELECT Id,Cost_Key__c,Department FROM User WHERE ID IN :allOwnerIds]){
            userId_CostKeyMap.put(eachUsrRec.ID, eachUsrRec);
        }
    }
    
    // Method - 5 : Getting Revenue Data
    public void getRevenueData(List<string> accIds, Map<string, List<SC_DD_Revenue__c>> Revenue_AccountProd_RevListMap){
    
        string mapKey;
        List<SC_DD_Revenue__c> mapValues;
        
        // Loop for each revenue records
        for(SC_DD_Revenue__c eachRevenuerec : [SELECT Akam_Account_ID__c, GSS_Product__c, CC_Budget_Rate__c, Year_Month__c 
                                                FROM SC_DD_Revenue__c WHERE Akam_Account_ID__c in :accIds  // added account filter - Vishnu
                                                                            and Status__c = 'Active']){
        
            mapKey = eachRevenuerec.Akam_Account_ID__c + '-' + eachRevenuerec.GSS_Product__c;   
            mapValues = (Revenue_AccountProd_RevListMap.get(mapKey) == null) ? new List<SC_DD_Revenue__c>() :
                                        Revenue_AccountProd_RevListMap.get(mapKey);
            mapvalues.add(eachRevenuerec);
            Revenue_AccountProd_RevListMap.put(mapKey, mapvalues);
        }
        //mapValues.clear();
    }
    
    //Method - 6 : Customer MRR Data
    public void getCustomerMRRData(List<string> accIds, Map<String, String> MRR_Prod_ServcProdMap, Map<String, Double>MRR_AccountProd_Revenue){
        
        string mapKey;
        for(SC_DD_Customer_MRR__c eachMRR :[SELECT Akam_Account_ID__c, USD_Revenue__c, Product__c 
                                            FROM SC_DD_Customer_MRR__c WHERE 
                                            Akam_Account_ID__c IN :accIds and // Added Account Filter - Vishnu
                                            Status__c = 'Active']){ 
            mapKey = eachMRR.Akam_Account_ID__c + '-' + MRR_Prod_ServcProdMap.get(eachMRR.Product__c); 
            MRR_AccountProd_Revenue.put(mapKey, double.valueOf(eachMRR.USD_Revenue__c));
        }
    }
    
    // Method - 6 : Populating Pre Deal Data for PS
    public void PS_Calculation(PSWrapper PSwrpRec, SC_DD_Customer_PreDeal_Data__c eachPreDealrec ){
    
        eachPreDealrec.PS_Hours__c                          = PSwrpRec.PS_Hours;
        eachPreDealrec.PS_Non_Billable_Hours__c             = PSwrpRec.PS_Non_Billable_Hours_c;
        eachPreDealrec.PS_Avg_Monthly_NonBillable_Hour__c   = PSwrpRec.avg_monthly_NonBillHours;
        eachPreDealrec.PS_Delivery_Cost__c                  = PSwrpRec.deliveryCost_Total;
        eachPreDealrec.PS_PerHour_Cost__c                   = PSwrpRec.PS_PerHour_Cost;
        eachPreDealrec.PS_Hour_Monthly__c                   = PSwrpRec.PS_Hours_AvgMonthly;
        eachPreDealrec.PS_No_Of_Months__c                   = PSwrpRec.filteredPSMonths.size();
    }
    
    // Method - 7 : Populating Pre Deal Data for Akatec
    public void Akatec_Calculation(List<Case> caseList, set<Integer> filteredPSMonths, Map<String, Decimal> costDataMap,
                                     Map<Id, User> userId_CostKeyMap, SC_DD_Customer_PreDeal_Data__c eachPreDealrec ){
    
        // Getting Per Hour Cost from Cost Data
        Decimal getPerHourCost;
        
        // For Storing months for which Akatec data exists from PS Filtered Months
        //set<Decimal> noOfAkatecMonth = new set<Decimal>();
        
        // Defaulting to 0, for all Akatec data
        eachPreDealrec.AkaTec_LOE_Hours__c              = 0;    // For Akatec LOE Hours
        eachPreDealrec.Akatec_LOE_Delivery_Cost__c      = 0;    // For Akatec LOE Delivery Cost
        eachPreDealrec.Akatec_PerHour_Cost__c           = 0;    // For Akatec Per Hour Cost
        eachPreDealrec.Akatec_Monthly_Avg_Hour__c       = 0;    // For Akatec Per Monthly Cost
        
        // Loop for all the Case Data
        if(caseList != null){
            for(Case eachCase : caseList){
                // If Case Data matches with Filtered PS Months, then consider
                if(filteredPSMonths.contains(integer.valueOf(eachCase.SC_DD_Year_Month__c))){
                    eachPreDealrec.AkaTec_LOE_Hours__c += eachCase.Task_LOE__c ;
                    getPerHourCost = costDataMap.get(userId_CostKeyMap.get(eachCase.OwnerId).Cost_Key__c);
                    
                    // Check if Cost Data present 
                    if(getPerHourCost != null)
                        eachPreDealrec.Akatec_LOE_Delivery_Cost__c += (eachCase.Task_LOE__c) * getPerHourCost;
                    
                    
                }
            }
        }
        
        // To Handle situation where no Akatec data exist for Filtered revenue Month
        if(eachPreDealrec.AkaTec_LOE_Hours__c > 0){
            // Below Two Calculation are on aggregate Level
            eachPreDealrec.Akatec_PerHour_Cost__c = eachPreDealrec.Akatec_LOE_Delivery_Cost__c / eachPreDealrec.AkaTec_LOE_Hours__c;
            eachPreDealrec.Akatec_Monthly_Avg_Hour__c = eachPreDealrec.AkaTec_LOE_Hours__c / filteredPSMonths.size();
            
        }
        //noOfAkatecMonth.clear();
    }
    
    // Method - 7 : Populating Pre Deal Data for Akatec
    public void SOCC_Calculation(List<Task> TaskList, set<Integer> filteredPSMonths, Map<String, Decimal> costDataMap,
                                     Map<Id, User> userId_CostKeyMap, Map<String, Decimal> TaskType_LOEMap,
                                     SC_DD_Customer_PreDeal_Data__c eachPreDealrec ){
        
        // Getting Per Hour Cost from Cost Data
        Decimal getPerHourCost;
        
        // For Storing months for which SOCC data exists from PS Filtered Months
        //set<Decimal> noOfSOCCMonth = new set<Decimal>();
        
        // Defaulting to 0, for all SOCC data
        eachPreDealrec.SOCC_LOE_Hours__c            = 0;    // For SOCC LOE Hours
        eachPreDealrec.SOCC_LOE_Delivery_Cost__c    = 0;    // For SOCC LOE Delivery Cost
        eachPreDealrec.SOCC_PerHour_Cost__c         = 0;    // For SOCC Per Hour Cost
        eachPreDealrec.SOCC_AvgHour_Monthly__c      = 0;    // For SOCC Per Monthly Cost
        
        //Variable to store Year Month of AKAM Modified Date
        Integer yearMonth;
        
        // Loop for all the Case Data
        if(TaskList != null){
            for(Task eachTaskRec : TaskList){
                yearMonth = getYearMonth(eachTaskRec.AKAM_Modified_Date__c);
                
                 // If Case Data matches with Filtered PS Months, then consider and User Department = SOC
                if(filteredPSMonths.contains(yearMonth) && 
                userId_CostKeyMap.get(eachTaskRec.OwnerId).Department != null && 
                userId_CostKeyMap.get(eachTaskRec.OwnerId).Department.contains('Security Services - SOC')){
            
                    getPerHourCost = costDataMap.get(userId_CostKeyMap.get(eachTaskRec.OwnerId).Cost_Key__c);
                    
                    // Check if Cost Data present for the Owner's Department
                    if(getPerHourCost != null){
                        eachPreDealrec.SOCC_LOE_Hours__c += TaskType_LOEMap.get(eachTaskRec.Type__c) / 60;
                        eachPreDealrec.SOCC_LOE_Delivery_Cost__c += (TaskType_LOEMap.get(eachTaskRec.Type__c) / 60) * getPerHourCost;
                    }
                
                    //noOfSOCCMonth.add(yearMonth); 
                }
            }
        }
                                         
        // To Handle situation where no SOCC data exist for Filtered revenue Month
        if(eachPreDealrec.SOCC_LOE_Hours__c > 0){
            // Below Two Calculation are on aggregate Level
            eachPreDealrec.SOCC_PerHour_Cost__c = eachPreDealrec.SOCC_LOE_Delivery_Cost__c / eachPreDealrec.SOCC_LOE_Hours__c;
            eachPreDealrec.SOCC_AvgHour_Monthly__c = eachPreDealrec.SOCC_LOE_Hours__c / filteredPSMonths.size();
            
        }
        //noOfSOCCMonth.clear();
    }
    
    // Method - 8 : Populating Pre Deal Data for Akatec
    public void Revenue_Calculation(List<SC_DD_Revenue__c> revenueList,set<Integer> filteredPSMonths, 
                                    SC_DD_Customer_PreDeal_Data__c eachPreDealrec ){
        
        // For Storing months for which Revenue Data Exist
        set<Decimal> noOfRevMonths = new set<Decimal>();
        
        // For Storing months for which Revenue data exists from PS Filtered Months
        set<Decimal> noOfFilteredRevMonths = new set<Decimal>();
        
        // Defaulting to 0, for all Revenue data                            
        eachPreDealrec.Total_Revenue_All_Months__c          = 0;
        eachPreDealrec.Revenue_Months__c                  = 0;
        eachPreDealrec.Total_Revenue_Filtered_Months__c     = 0;
        eachPreDealrec.Revenue_Monthly_Avg__c               = 0;
        eachPreDealrec.Filtered_Revenue_Months__c           = 0;    
        
        // Loop for all the Revenue Data
        if(revenueList != null){
            for(SC_DD_Revenue__c eachRevrec : revenueList){
                
                eachPreDealrec.Total_Revenue_All_Months__c += eachRevrec.CC_Budget_Rate__c;
                noOfRevMonths.add(eachRevrec.Year_Month__c);
            
                // If Revenue Data matches with Filtered PS Months, then consider
                if(filteredPSMonths.size() > 0 && filteredPSMonths.contains(Integer.valueOf(eachRevrec.Year_Month__c))){
                    eachPreDealrec.Total_Revenue_Filtered_Months__c += eachRevrec.CC_Budget_Rate__c;
                    noOfFilteredRevMonths.add(eachRevrec.Year_Month__c);
                }
            }
        }
        
        eachPreDealrec.Filtered_Revenue_Months__c = noOfFilteredRevMonths.size();
        eachPreDealrec.Revenue_Months__c = noOfRevMonths.size();
        
        // If Filtered rev exists, then calculate
        if(eachPreDealrec.Total_Revenue_Filtered_Months__c  > 0 && noOfFilteredRevMonths.size() > 0)
            eachPreDealrec.Revenue_Monthly_Avg__c   = eachPreDealrec.Total_Revenue_Filtered_Months__c  / noOfFilteredRevMonths.size();
                                        
                                        
         noOfRevMonths.clear();
         noOfFilteredRevMonths.clear();
    }
    
    // Method - 9 : Converting List Values to String
    public String listToINCondition(list<String> listCond) {
        return '(\'' + String.join(listCond, '\',\'') + '\')';
    }
    
    // Method - 10 : Converting Set Values to String
    public String setToINCondition(set<String> setCond) {
        return listToINCondition(new List<String>(setCond));
    }
    
     // Method - 11 : Get PS Data
     public List<pse__Timecard__c> getPSData(List<string> accIds, Set<String> mktProdIds, Date startDate, Date endDate){
        system.debug('--startDate--'+startDate);
        system.debug('--endDate--'+startDate);         
        string PSquery = 'SELECT pse__Total_Hours__c, pse__Timecard_Header__r.pse__Billable__c, pse__assignment__r.pse__Project__r.pse__Account__r.akam_account_id__c, '
                + 'pse__assignment__r.pse__Resource__r.pse__Salesforce_User__r.Cost_Key__c, pse__assignment__r.project_contract_line_item__r.contract_detail__r.Unit_Price__c, '
                + 'pse__assignment__r.project_contract_line_item__r.contract_detail__r.product_id__c, SC_DD_Year_Month__c '
                + 'FROM pse__Timecard__c WHERE pse__Total_Hours__c > 0 AND pse__project__r.pse__account__r.Akam_Account_Id__c IN ' + listToINCondition(accIds)
                + ' AND pse__Timecard_Header__r.pse__Status__c IN (\'Submitted\',\'Approved\',\'Approver Level 1\') AND pse__start_Date__c > ' + String.valueOf(startDate) + ' AND pse__start_Date__c <= ' + String.valueOf(endDate) + ' AND '
                + 'pse__assignment__r.project_contract_line_item__r.contract_detail__r.product_id__c IN ' + setToINCondition(mktProdIds); 
        
        System.debug('--PSquery--'+PSquery);
        return database.query(PSquery);
     }
     
     // Method - 12 : Get SOCC Data from Webservice Query
     public List<Case> getSOCCDataFromWebService(List<String> akamAccIds, Set<String> prodIds, Set<String> taskTypes, Date startDate, Date endDate) {
            
            String startDateTime = ((Datetime)startDate).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
            String endDateTime = ((Datetime)endDate).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
            String caseStartTime = ((Datetime)startDate.addMonths(-6)).format('yyyy-MM-dd\'T\'hh:mm:ss\'z\'');
         
            string SOCCquery = 'SELECT Case.AccountId, Case_Product__r.Name, AKAM_Account_ID__c, '
            + '(SELECT Type__c, AKAM_Modified_Date__c,OwnerId FROM Tasks WHERE AKAM_Modified_Date__c > ' + startDateTime + ' AND AKAM_Modified_Date__c < ' + endDateTime + ' AND Type__c IN '+ setToINCondition(taskTypes) + ' ) FROM Case '
            + 'WHERE Recordtype.Name = \'Managed Security\' AND AKAM_Created_Date__c >' + caseStartTime 
            + 'AND Account.AKAM_Account_Id__c in '+ listToINCondition(akamAccIds)  
            + 'AND Case_Product__r.Name in '+ setToINCondition(prodIds);
         
       //return (List<Case>)JSON.deserializeStrict(webServiceCls.runWebQuery(SOCCquery), List<Case>.class); 
       return database.query(SOCCquery);            
    }
    
    // Method - 13 : Query to Get Budget Hour from PS
    public void getBudgetHours(List<String> accIds, map<String, String> ps_MktProdId_ServcProdMap, 
                                Map<string,Decimal> accServprod_BudgetHoursMap){
        String getServProdName;
        String getAkamAccountId;
        string mapKey;
        Decimal mapvalue;
         
        // Query On Project Contract Line Item
        for(project_contract_Line_item__c eachPCL : [SELECT contract_detail__r.Product_Id__c, Project__r.pse__Account__r.Akam_Account_Id__c, 
                                                        Project__r.Ongoing_Project_Recurring_Planned_Hour__c 
                                                        FROM project_contract_Line_item__c 
                                                        WHERE Project__r.pse__Account__r.akam_account_id__c in :accIds
                                                        AND contract_detail__r.Product_Id__c IN :ps_MktProdId_ServcProdMap.keyset() AND 
                                                        Project__r.pse__stage__c != 'Closed' AND Project__r.Ongoing_Project_Recurring_Planned_Hour__c > 0 AND
                                                        project__R.pse__project_manager__r.name != 'PSA User']){
        
                //Generate Key for the map
                getServProdName = ps_MktProdId_ServcProdMap.get(eachPCL.contract_detail__r.Product_Id__c);
                getAkamAccountId = eachPCL.Project__r.pse__Account__r.Akam_Account_Id__c;
                mapKey = getAkamAccountId + '-' + getServProdName;
                
                //Initializing the Budget Hours Value 
                mapvalue = (accServprod_BudgetHoursMap.get(mapKey) == null) ? 0 : accServprod_BudgetHoursMap.get(mapKey);
                mapvalue += eachPCL.Project__r.Ongoing_Project_Recurring_Planned_Hour__c;
                accServprod_BudgetHoursMap.put(mapKey, mapvalue);
                                                            system.debug('-accServprod_BudgetHoursMap---'+accServprod_BudgetHoursMap);
            }
        }
    
    //Method - 14 : Extract YYYYMM from DateTime field.
    public Integer getYearMonth(Datetime inputDate){
        String yearMonth =  string.valueOf(inputDate.year()) + 
                            (inputDate.Month() > 9 ? string.valueOf(inputDate.Month()) : 
                                                    '0' + string.valueOf(inputDate.Month()));
        return Integer.valueOf(yearMonth);
    }
    
}