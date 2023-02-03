/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR/JIRA     DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                                       
|  22-May-2017      Aditya Sonam    ESESP-584   This is a support class for - SC_Autogen_PIVC_Batch
|  31-Jan-2018      Vamsee S    ESESP-613 Removed PIVC Autogen Case Creation (Commented out the complete code)
+=====================================================================================================*/

public class SC_Autogen_PIVC_Support{
    
    Public SC_Autogen_PIVC_Support(){
        
    }
  /*
    public static SC_DGRAT_Reorg_Mapping__c DGRATMapping =  SC_DGRAT_Reorg_Mapping__c.getInstance();
    
    // List to store for Newly Created Case
    public static List<Case> newCaseList = new List<Case>();
    
    // Method to get all Active Contracts   
    public void mergePIVCMethod(List<Account> allReturnAccount){
      
        // List#2 - To Store PIVC Contracts (All the Contracts with Future ESD)
      List<Merge_Contract_Header__c> PIVC_ContractList = new List<Merge_Contract_Header__c>();
      
      // List#3 - To Store all The Contracts
      List<Merge_Contract_Header__c> all_ContractList = new List<Merge_Contract_Header__c>();
  
  
      all_ContractList = [Select Id,Account_Name__c,Is_COB_Created__c,Effective_Start_Date__c,Effective_End_Date__c,
                             Name,Account_Name__r.Name,Account_Name__r.AKAM_Account_ID__c,Account_Name__r.Geography_Formula__c,
                             AKAM_Created_Date__c
                             from Merge_Contract_Header__c 
                             where
                             Locked__c = true and Active__c = true and 
                             Cancellation_Date__c = Null and
                             Contract_Transferred_To__c = Null and
                             Effective_End_Date__c > Today and 
                             AKAM_Created_Date__c <> null and
                             Account_Name__c IN : allReturnAccount 
                             order by AKAM_Created_Date__c asc];
        
        // Loop for Filter Out ECOB Contracts
        for(Merge_Contract_Header__c eachEcobRec : all_ContractList){
          
            // Adding To PIVC List
            if(eachEcobRec.Account_Name__r.Geography_Formula__c <> null && DGRATMapping.Geography_APJ__c.containsIgnoreCase(eachEcobRec.Account_Name__r.Geography_Formula__c)){         
              PIVC_ContractList.add(eachEcobRec); 
            } 
      }
        // Calling for PIVC Calculation
        if(SC_Autogen_Job_Enable_Disable__c.getValues('PIVC').IsActive__c){
        
          PIVC_Calculation(PIVC_ContractList);
        }
        // Insert the Cases
        if(newCaseList.size() > 0)
          Insert newCaseList;
  }
    
    public void PIVC_Calculation(List<Merge_Contract_Header__c> allReturnContracts){

      // Fetching Detail RecordType for - Autogen_Contract_Header_Detail__c Object
        Id getAccountLevelRecordTypeId = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('AccountLevel').getRecordTypeId();
      
      // Set to Store all Unique Account Ids
      set<Id> allAccountIds = new set<Id>();
  
          // Set to Store all Qualified Account Ids for Effective Date Calculation
          set<Id> allQualifiedAccountIds = new set<Id>();
          
          // Set to Store all Account Ids for for Case Creation
          set<Id> allAccountIds_CaseCreation = new set<Id>();
          
          // Map to Store AccountId - First Createddate for Contract 
          Map<Id,Date> AccountId_ContrctHdCreateddateMap = new Map<Id,Date>();
          
          // Map to store Account Id - ACHD record with RecordType = AccountLevel
          Map<Id,Autogen_Contract_Header_Detail__c> AccountId_ACHDRecMap = new Map<Id,Autogen_Contract_Header_Detail__c>(); 
          
          // List to Store for Update Of ACHD Account Level Records
          List<Autogen_Contract_Header_Detail__c> ACHDListForUpdate = new List<Autogen_Contract_Header_Detail__c>();
          
          // Loop for each fetched Contract Header
          for (Merge_Contract_Header__c eachHeaderRec : allReturnContracts){
          
            //1. Setting allAccountIds set
            allAccountIds.add(eachHeaderRec.Account_Name__c);
            
            //2. Setting AccountId_ContrctHdCreateddateMap Map
            AccountId_ContrctHdCreateddateMap.put(eachHeaderRec.Account_Name__c,eachHeaderRec.AKAM_Created_Date__c.date());
          }
      
      // Query on ACHD Object for AccountLevel Records
      for(Autogen_Contract_Header_Detail__c eachACHD_AccountRec : [select Id,Parent_Account__c,IS_PIVC_Created__c,
                      Next_PIVC_Creation_Date__c,
                                                                    Parent_Contract_Header__r.Name,
                                  Parent_Contract_Header__c,Parent_Account__r.Name,
                                  Parent_Account__r.AKAM_Account_ID__c,
                                  Parent_Contract_Header__r.Effective_Start_Date__c 
                                from Autogen_Contract_Header_Detail__c 
                                where RecordTypeId = :getAccountLevelRecordTypeId and 
                                Parent_Account__c In :allAccountIds]){
                      
          // Setting AccountId_ACHDRecMap Map
          AccountId_ACHDRecMap.put(eachACHD_AccountRec.Parent_Account__c, eachACHD_AccountRec);                       
      }
  
      Autogen_Contract_Header_Detail__c eachACHDRec;
  
      // Get the Subsequent Case Creation Time from Custom Setting
       Integer PIVCFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues('PIVC').Subsequent_Freq_in_Days__c);
        
      // Loop for each Account
      for(Id eachAccountId : AccountId_ContrctHdCreateddateMap.keyset()){
  
      eachACHDRec = AccountId_ACHDRecMap.get(eachAccountId);
    
      // Condition-1 (If no PIVC record is there, then proceed for calculation)
      if( eachACHDRec == null){
    
        allQualifiedAccountIds.add(eachAccountId);
      }
            
      // Condition-2 (If PIVC Created = false and Next_PIVC_Creation_Date__c != null, then check with Today)
      else if(eachACHDRec.IS_PIVC_Created__c == false && eachACHDRec.Next_PIVC_Creation_Date__c <> null){
    
        // Check with Today
        if(eachACHDRec.Next_PIVC_Creation_Date__c.addDays(PIVCFreq) == system.today()){
        
        // Set the PIVC Flag = true
        eachACHDRec.IS_PIVC_Created__c = true;
        
        // Adding Account Id for Case Creation
        allAccountIds_CaseCreation.add(eachAccountId);
        
        // Add for case calculation
        ACHDListForUpdate.add(eachACHDRec );
      }
    } 
  }
  
    // If no PIVC record is there, then call the method to calculate and create PIVC record on ACHD Object
    if(allQualifiedAccountIds.size() > 0){
  
      // Call to calculateLatestContract_1stday_Account method for calculation
      calculateLatestContract_1stday_Account(allReturnContracts, allQualifiedAccountIds,AccountId_ContrctHdCreateddateMap,
                  getAccountLevelRecordTypeId);
    }
  
    // If any Record is there for Case Creation, then call the method
    if(ACHDListForUpdate.size() > 0){
  
      // Call the method for Case Creation and ACHD Update
      caseCreation_ACHDUpdate(ACHDListForUpdate,allAccountIds_CaseCreation);
    }
}

    // Method for Calculating Latest contract for the 1st Day for an Account
    public void calculateLatestContract_1stday_Account(List<Merge_Contract_Header__c> allReturnContracts,
                                set<Id> allQualifiedAccountIds,
                                Map<Id,Date> AccountId_ContrctHdCreateddateMap,
                                Id getAccountLevelRecordTypeId){
      // List to store all ACHD records for Insert
      List<Autogen_Contract_Header_Detail__c> allACHDListforInsert = new List<Autogen_Contract_Header_Detail__c>();
      
      // Map to store Account Id - Latest Contract
      Map<Id,Merge_Contract_Header__c> AccountId_LatestContractMap = new Map<Id,Merge_Contract_Header__c>();
      
      // Variable to store the 1st Contract creation date out of Multiple Contracts for the same day
      Date firstContractCreationDate;
      
      // ACHD Record Variable
      Autogen_Contract_Header_Detail__c eachACHDrecordAccountLeval;
      
      // Loop for each fetched Contract Header 
      for (Merge_Contract_Header__c eachHeaderRec : allReturnContracts){
      
        firstContractCreationDate = AccountId_ContrctHdCreateddateMap.get(eachHeaderRec.Account_Name__c);
        
        // If the Set contains the Account Id, then calculation should be done
        if(allQualifiedAccountIds.contains(eachHeaderRec.Account_Name__c)){
        
          // If Map does not have entry, then Put the value else check for last created contract for the same day
          if( AccountId_LatestContractMap.get(eachHeaderRec.Account_Name__c) == null)
            AccountId_LatestContractMap.put(eachHeaderRec.Account_Name__c,eachHeaderRec);
          
          else if (eachHeaderRec.AKAM_Created_Date__c.date() == firstContractCreationDate && 
             eachHeaderRec.AKAM_Created_Date__c > AccountId_LatestContractMap.get(eachHeaderRec.Account_Name__c).AKAM_Created_Date__c
            ){
            
            AccountId_LatestContractMap.put(eachHeaderRec.Account_Name__c,eachHeaderRec); 
          }
        }
      }
      
      // Loop for all the Qualified Accounts for which new record to be created in ACHD Object
      for(Id eachAccountId : AccountId_LatestContractMap.keyset()){
      
        // Instantiating ACHD Record
        eachACHDrecordAccountLeval = new Autogen_Contract_Header_Detail__c();
        eachACHDrecordAccountLeval.Parent_Account__c      = eachAccountId;
        eachACHDrecordAccountLeval.Parent_Contract_Header__c  = AccountId_LatestContractMap.get(eachAccountId).Id;
        eachACHDrecordAccountLeval.RecordTypeId         =   getAccountLevelRecordTypeId;
        
        // Adding to Insert List
        allACHDListforInsert.add(eachACHDrecordAccountLeval);
      }
      
      // Inserting to Database
      if(allACHDListforInsert.size() > 0)
        Insert allACHDListforInsert;
      
      
    }
    
    // Method for Setting Case Parameter for Case Creation + Update ACHD Records
    public void caseCreation_ACHDUpdate(List<Autogen_Contract_Header_Detail__c> ACHDListForUpdate, set<Id> allAccountIds_CaseCreation){
    
      // Map to Store Account Id + Sales - Primary
      Map<Id,string> accountId_SalesPrimaryMap = new Map<Id,string>();
      
      // For Each Case Record
      Case eachPIVCCase;
      
      // Getting PIVC Service Value
      string PIVC_ServiceVal = SC_Serv_ReqTyp_value__c.getValues('PIVC').ServiceVal__c;
      
      // Getting PIVC Request Type Value
      string PIVC_ReqTypeVal = SC_Serv_ReqTyp_value__c.getValues('PIVC').RequestTypeVal__c;
        
        // For setting the PIVC Report Link(Call to SC_PIVCReportPage)
        string reportLink;
      
      // Setting Assignment Rule
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true;
      dmo.EmailHeader.TriggerUserEmail = true;
      
      // Loop to set accountId_SalesPrimaryMap
      for(AccountTeamMember salesTeamMember : [select Id,AccountId,User.Name from AccountTeamMember where 
                          AccountId In :allAccountIds_CaseCreation and
                          TeamMemberRole = 'Technical Sales - Primary']){
                    
        accountId_SalesPrimaryMap.put(salesTeamMember.AccountId, salesTeamMember.User.Name);            
      }
      
      // Loop for Setting Case Parameters
      for(Autogen_Contract_Header_Detail__c eachPIVC_ACHDrecord : ACHDListForUpdate){
      
            // Setting report Link
            reportLink = URL.getSalesforceBaseUrl().toExternalForm() + '/apex/SC_PIVCReportPage?AccountId='+
                     eachPIVC_ACHDrecord.Parent_Account__c + '&AccountName='+
                     eachPIVC_ACHDrecord.Parent_Account__r.Name +
                     '&OrgContractId=' + eachPIVC_ACHDrecord.Parent_Contract_Header__r.Name;
            
        eachPIVCCase = new Case();
        eachPIVCCase.setOptions(dmo);
        eachPIVCCase.Autogen_UseCase__c     = 'PIVC';
        eachPIVCCase.RecordTypeId       = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        eachPIVCCase.AccountId          = eachPIVC_ACHDrecord.Parent_Account__c;
        eachPIVCCase.Contract__c        = eachPIVC_ACHDrecord.Parent_Contract_Header__c;
        eachPIVCCase.Service__c         = PIVC_ServiceVal;
        eachPIVCCase.Request_Type__c        = PIVC_ReqTypeVal;
        eachPIVCCase.Request_Sub_Type__c      = 'N/A - Not Applicable';
        eachPIVCCase.origin         = 'Proactive';
        eachPIVCCase.Severity__c                = '3';
              eachPIVCCase.Do_Not_Show_in_Portal__c   = true;
            eachPIVCCase.Subject          = 'Complete PIVC : ' + eachPIVC_ACHDrecord.Parent_Account__r.Name;
              eachPIVCCase.Description          = 'Account Name : ' + eachPIVC_ACHDrecord.Parent_Account__r.Name +
                                    '\n' + 'Account Id : ' +  eachPIVC_ACHDrecord.Parent_Account__r.AKAM_Account_ID__c + 
                                    '\n' + 'Contract Original Start Date :' + 
                                    eachPIVC_ACHDrecord.Parent_Contract_Header__r.Effective_Start_Date__c + 
                                    '\n' + 'Technical Sales – Primary : ' + 
                                    accountId_SalesPrimaryMap.get(eachPIVC_ACHDrecord.Parent_Account__c)
                                  + '\n\n Click the below Link to see all The Contracts\n'
                                  + reportLink; 
                eachPIVCCase.Work_Type__c   = 'Proactive';
                                  
      
            // Adding to Case Creation List
            newCaseList.add(eachPIVCCase);
        }
      
        // Update the List
        Update ACHDListForUpdate;
        }*/
  }