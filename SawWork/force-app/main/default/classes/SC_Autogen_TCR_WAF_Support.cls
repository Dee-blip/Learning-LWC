/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR		DESCRIPTION                                                       

|  ===========      =========       =======     ============
                                                       
|  23-APR-2014      Himanshu Kar    2556174     This is a support class for - SC_Autogen_TCR_WAF_Batch
   28-JUL-2014      Himanshu Kar    2637489  	Removed Hard Coding Geo Values 
|  20-JAN-2015	  	Himanshu Kar	2892414     Optimize the Code to accomodate more autogen Use Case  
   29-JAN-2015	  	Himanshu Kar	2845434     Added SAAS Use Case 
|  20-APR-2015      Himanshu Kar    2957996		Added Configuration approach to decide whether Job will run or not                                 
|  11-Mar-2016      Sonia           3320211     GDRAT-to-DGRAT reorg: AMG functionality fixes - Replaced all Geography checks to use the custom setting
                 
+=====================================================================================================*/

public class SC_Autogen_TCR_WAF_Support{

      // List to store all Cases to be Created
      public static List<Case> caseCreateList = new List<Case>();

      public static SC_DGRAT_Reorg_Mapping__c DGRATMapping =  SC_DGRAT_Reorg_Mapping__c.getInstance();    
        
      // Fetching Assignment Rule
      public AssignmentRule assgnRule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
            
      // Method - 1: Main method for TCR and WAF Calculation
      // Called from - SC_Autogen_TCR_WAF_Batch Class
      public void main_TCR_WAF_Method(List<Merge_Contract_Header__c> allReturnContracts){
        
            // Set to store TCR Product Id values
            set<string> allTCRProd = new set<string>();
            
            // Set to store WAF Product Id values
            set<string> allWAFProd = new set<string>();
            
            // Set to store SAAS Product Id values
            set<string> allSAASProd = new set<string>();
            
            // Set to Store all Use Case Products
            set<string> allUsecaseProd = new set<string>();
            
            // boolean for storing Returned Result from AddAll Method
            boolean returnFlag = false;
            
          /****  Adding Values for All Product Lists  ****/
          // 1. For TCR Product
          if(SC_Autogen_Job_Enable_Disable__c.getValues('TCR').IsActive__c){
              	
              	returnFlag = allTCRProd.addAll(SC_TCR_WAF_ProdList__c.getValues('TCR').Product_Id__c.split(','));
          		returnFlag = allUsecaseProd.addAll(allTCRProd);
          }
          
          // 2. For WAF Product
          if(SC_Autogen_Job_Enable_Disable__c.getValues('WAF').IsActive__c){
          
              	returnFlag = allWAFProd.addAll(SC_TCR_WAF_ProdList__c.getValues('WAF').Product_Id__c.split(','));
          		returnFlag = allUsecaseProd.addAll(allWAFProd);
          }
          
          // 3. For SAAS Product
          if(SC_Autogen_Job_Enable_Disable__c.getValues('SAAS').IsActive__c){
            
              	returnFlag = allSAASProd.addAll(SC_TCR_WAF_ProdList__c.getValues('SAAS').Product_Id__c.split(','));
              	returnFlag = allUsecaseProd.addAll(allSAASProd);
          }
            
            // List to store all TCR Contracts
        	List<Merge_Contract_Detail__c> contractLineList_TCR = new List<Merge_Contract_Detail__c>();
        
        	// List to store all WAF Contracts
        	List<Merge_Contract_Detail__c> contractLineList_WAF = new List<Merge_Contract_Detail__c>();
        	
        	// List to store all SAAS Contracts
        	List<Merge_Contract_Detail__c> contractLineList_SAAS = new List<Merge_Contract_Detail__c>();
        	
        	// List to store all Contracts - For all Use Cases 
        	List<Merge_Contract_Detail__c> contractLineList_ALL = new List<Merge_Contract_Detail__c>(); 
        
        	// Query to fetch all Contract Line Items - For All Use Cases
            if(allUsecaseProd.size() > 0){
        
            	contractLineList_ALL = [Select id,Name,Effective_Start_Date__c,Original_Contract_Id__c ,Effective_End_Date__c,
                            			Original_Contract_Id__r.Account_Name__r.Name,
                            			Original_Contract_Id__r.Account_Name__r.Geography_Formula__c,
                            			Original_Contract_Id__r.Account_Name__c,Product_Id__c,
                            			Original_Contract_Id__r.Account_Name__r.AKAM_Account_ID__c
                        		from Merge_Contract_Detail__c
                        		where Original_Contract_Id__c In :allReturnContracts and
                          			Effective_Start_Date__c <= Today and
                          			Effective_End_Date__c >= Today and
                          			Effective_Start_Date__c <> null and
                          			Effective_End_Date__c <> null and
                          			Product_Id__c in :allUsecaseProd
                        		];
        	}
        
        	// Loop for each Line Item with the Product ID
            for(Merge_Contract_Detail__c eachLineRec : contractLineList_ALL){
            
            	// Setting TCR Contract List
                if(allTCRProd.contains(eachLineRec.Product_Id__c)){
        
                        contractLineList_TCR.add(eachLineRec);
                }
    
                // Setting WAF Contract List
                else if(allWAFProd.contains(eachLineRec.Product_Id__c)){
        
                        contractLineList_WAF.add(eachLineRec);
                }
      		
                // Setting SAAS Contract List
                else if(allSAASProd.contains(eachLineRec.Product_Id__c)){
        
                        contractLineList_SAAS.add(eachLineRec);
                }
            
            }
        
		// deallocate Memory
		allTCRProd.clear();
		allWAFProd.clear();
		allSAASProd.clear();
		allUsecaseProd.clear();
		contractLineList_ALL.clear();
	  
		// Call to TCR Calculation Method
		if(contractLineList_TCR.size() > 0)
			TCR_Calculation(contractLineList_TCR);
		
		// Call to WAF Calculation Method
		if(contractLineList_WAF.size() > 0)
			WAF_Calculation(contractLineList_WAF);
			
		// Call to SAAS Calculation Method
		if(contractLineList_SAAS.size() > 0)
			SAAS_Calculation(contractLineList_SAAS);
		
		// deallocate Memory
		contractLineList_TCR.clear();
		contractLineList_WAF.clear();
		contractLineList_SAAS.clear();
		
		// Insert Case
		if(caseCreateList.size() > 0)
			Insert caseCreateList;
		
		// deallocate Memory
		caseCreateList.clear();
    
        }
        
        // Method - 2: Method for TCR Calculation
    	// Called from - main_TCR_WAF_Method method
        public void TCR_Calculation(List<Merge_Contract_Detail__c> contractLineList_TCR){
        
            // Map to store Original Contract ID(Header) - Contract Line with Earliest Effective Start Date
        	Map<Id,Merge_Contract_Detail__c> org_ContractId_EffectiveStrtDtMap = new Map<Id,Merge_Contract_Detail__c>();
        
        	// Phase:1 - Call to effectiveStrtdtCalc method for Earliest Effective Start Date Calculation
        	org_ContractId_EffectiveStrtDtMap = effectiveStrtdtCalc(contractLineList_TCR);
        
        	// deallocate Memory
        	contractLineList_TCR.clear();
        
        	// Phase:2 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
        	if(org_ContractId_EffectiveStrtDtMap.size() > 0){
            	CaseCalculation(org_ContractId_EffectiveStrtDtMap,'TCR');
        	}
        
        	// deallocate Memory
        	org_ContractId_EffectiveStrtDtMap.clear();
        
        }
        
        // Method - 3: Method for Earliest Effective Start Date Calculation
    	// Called from - TCR_Calculation, WAF_Calculation method
        public Map<Id,Merge_Contract_Detail__c> effectiveStrtdtCalc(List<Merge_Contract_Detail__c> contractLineList_TCR_WAF){
        
            // Map to store Original Contract ID(Header) - Contract Line with Earliest Effective Start Date
        	Map<Id,Merge_Contract_Detail__c> org_ContractId_EffectiveStrtDtMap = new Map<Id,Merge_Contract_Detail__c>();
        
        	// Loop for each Line
        	for(Merge_Contract_Detail__c eachContractLine : contractLineList_TCR_WAF){
        
            	// If Map has null value for the Contract, then add value to it. Else compare the Date
            	if(org_ContractId_EffectiveStrtDtMap.get(eachContractLine.Original_Contract_Id__c) == null){
            
                		org_ContractId_EffectiveStrtDtMap.put(eachContractLine.Original_Contract_Id__c,eachContractLine);
            	}
            	else
            	{
                		if(org_ContractId_EffectiveStrtDtMap.get(eachContractLine.Original_Contract_Id__c).Effective_Start_Date__c > eachContractLine.Effective_Start_Date__c){
                
                    		org_ContractId_EffectiveStrtDtMap.put(eachContractLine.Original_Contract_Id__c,eachContractLine);
                		}
            	}
        	}
        
        	// Return Calculated Map
        	return org_ContractId_EffectiveStrtDtMap;
        }
        
    // Method - 4: Method for Calculating Case Creation Criteria
    // Called from - TCR_Calculation, WAF_Calculation method
    public void CaseCalculation(Map<Id,Merge_Contract_Detail__c> org_ContractId_EffectiveStrtDtMap, string useCase){
    
        // Map to store Contract Line - Case Title 
        Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
        
        // variable for Case Creation Date Calculation
        Date caseCreationCalcDt ;
        
        // Get the Initial Case Creation Time from Custom Setting.If TCR then E.S.D + 5 Months. If WAF then on same day
        Integer initialFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues(useCase).Initial_Freq__c);
        
        // Get the Subsequent Case Creation Time from Custom Setting
        Integer subseqntFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues(useCase).Subsequent_Freq_in_Months__c);
        
                
        // Loop for Each Contract 
        for(Id eachContractId : org_ContractId_EffectiveStrtDtMap.keyset()){
        
            // Assigning Effective Start Date to variable
            caseCreationCalcDt = org_ContractId_EffectiveStrtDtMap.get(eachContractId).Effective_Start_Date__c;
            
            // Adding Initial Frequency to caseCreationCalcDt
            caseCreationCalcDt = caseCreationCalcDt.addMonths(initialFreq);
            
            while(caseCreationCalcDt <= org_ContractId_EffectiveStrtDtMap.get(eachContractId).Effective_End_Date__c){
                
                if(caseCreationCalcDt == System.Today()){
                
                    // Add to Case Creation Map 
                    contractLine_CaseTitleMap.put(org_ContractId_EffectiveStrtDtMap.get(eachContractId),'Technical Config Review');
                    
                    break;
                }
                
                // Add Months for Next Occurance
                caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreq);
                
            }
        }
        
        //Call to Case Creation Method
        if(contractLine_CaseTitleMap.size() > 0)
            caseCreation(contractLine_CaseTitleMap,useCase);
            
    }
    
    	  // Method - 5: Method for WAF Calculation
    	  // Called from - main_TCR_WAF_Method method
        public void WAF_Calculation(List<Merge_Contract_Detail__c> contractLineList_WAF){
        
            // Map to store Original Contract ID(Header) - Contract Line with Earliest Effective Start Date
        	Map<Id,Merge_Contract_Detail__c> org_ContractId_EffectiveStrtDtMap = new Map<Id,Merge_Contract_Detail__c>();
        	
        	// Map to store Contract Line - Case Title 
          	Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
        
        	// Phase:1 - Call to effectiveStrtdtCalc method for Earliest Effective Start Date Calculation
        	org_ContractId_EffectiveStrtDtMap = effectiveStrtdtCalc(contractLineList_WAF);
        
        	// deallocate Memory
        	contractLineList_WAF.clear();
        
        	// Phase:2 - Call to CaseCalculation method for checking Case Creation Criteria are met or not
        	if(org_ContractId_EffectiveStrtDtMap.size() > 0){
            	CaseCalculation(org_ContractId_EffectiveStrtDtMap,'WAF');
        	}
        
        	// deallocate Memory
        	org_ContractId_EffectiveStrtDtMap.clear();
        }
        
        // Method - 6: Method for SAAS Calculation
    	// Called from - main_TCR_WAF_Method method
        public void SAAS_Calculation(List<Merge_Contract_Detail__c> contractLineList_SAAS){
        
        	// Map to store Contract Line - Case Title 
          	Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap = new Map<Merge_Contract_Detail__c,string>();
          	
          	// variable for Case Creation Date Calculation
        	Date caseCreationCalcDt ;
        	
        	// Get the Subsequent Case Creation Time from Custom Setting
        	Integer subseqntFreq = Integer.valueOf(SC_Autogen_Case_Freq__c.getValues('SAAS').Subsequent_Freq_in_Months__c);
        
        	// Phase:1 - Checking whether the Contract meets case creation criteria or not
        	// Loop for Each Contract 
		  for(Merge_Contract_Detail__c eachContractRec : contractLineList_SAAS){
	  
			// Assigning Effective Start Date to variable
			caseCreationCalcDt = eachContractRec.Effective_Start_Date__c.addMonths(subseqntFreq);
		
			while(caseCreationCalcDt <= eachContractRec.Effective_End_Date__c){
		    
			    if(caseCreationCalcDt == System.Today()){
		    
				  // Add to Case Creation Map 
				  contractLine_CaseTitleMap.put(eachContractRec,'SaaS Provider Option User Review Bi-Annual Review');
			  
				  break;
			    }
		    
			    // Add Months for Next Occurance
			    caseCreationCalcDt = caseCreationCalcDt.addMonths(subseqntFreq);
		    
			}
		  }
        
        	// deallocate Memory
        	contractLineList_SAAS.clear();
        
        	// Phase:2 - Call to Case creation method 
        	if(contractLine_CaseTitleMap.size() > 0){
            	caseCreation(contractLine_CaseTitleMap,'SAAS');
        	}
        
        	// deallocate Memory
        	contractLine_CaseTitleMap.clear();
        }
        
        // Method - 7: Method for Case Creation 
    	// Called from - CaseCalculation method
        public void caseCreation(Map<Merge_Contract_Detail__c,string> contractLine_CaseTitleMap, string useCase){
        
            // Fetching Record Types for Case Object
            Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id setRecordTypeId ;
            
            // Case for each Record
            case eachCaserec; 
            
            // Setting DML Options
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
            dmo.EmailHeader.TriggerUserEmail = true;
            
            // Loop for each Contract Line for Case Creation
            for(Merge_Contract_Detail__c eachCntrctLnRec : contractLine_CaseTitleMap.keyset()){
            
                	// Setting RecordType 
                	setRecordTypeId = recordTypeCalculation(eachCntrctLnRec,useCase,rtMap);
                  
                  	// Setting all Case Parameters                     
                	eachCaserec = new Case();
                	eachCaserec.setOptions(dmo);
                	
                	eachCaserec.RecordTypeId            = setRecordTypeId;
                	eachCaserec.AccountId               = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__c;
                	eachCaserec.Contract__c             = eachCntrctLnRec.Original_Contract_Id__c;
                	eachCaserec.Service__c              = serviceCalculation(useCase, rtMap, setRecordTypeId, eachCntrctLnRec);
                	eachCaserec.Request_Type__c         = RequestTypeCalculation(useCase, rtMap, setRecordTypeId, eachCntrctLnRec);
                    eachCaserec.Severity__c             = '3';
                    eachCaserec.Do_Not_Show_in_Portal__c= true;
                    eachCaserec.Subject                 = subjectCalculation(contractLine_CaseTitleMap.get(eachCntrctLnRec), eachCntrctLnRec, useCase);
                    eachCaserec.Description             = descriptionCalculation(useCase, eachCntrctLnRec);
                    eachCaserec.Contract_Detail__c      = eachCntrctLnRec.Name;
                    eachCaserec.origin                  = originCalculation(useCase, rtMap, setRecordTypeId);
			eachCaserec.Work_Type__c		= 'Proactive';
                	eachCaserec.Autogen_UseCase__c	    = useCase;
            
            	if(useCase == 'SAAS')
            		eachCaserec.Request_Sub_Type__c  = 'Customer Review Done - Contract Revised';
            		
            	// Adding Case Record to List
            	caseCreateList.add(eachCaserec);
            
            }
            
            
        }
        
        // Method - 8: Method for RecordType Calculation
        // Called from - caseCreation method
        public Id recordTypeCalculation (Merge_Contract_Detail__c eachCntrctLnRec, string useCase, Map<String, Schema.RecordTypeInfo> rtMap){
      
            // variable to store Account Geography
            string accountGeo;
            
            // Stores the Calculated RecordType
            Id setRecordTypeId ;
            
            accountGeo = eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Geography_Formula__c;
            
            // If UseCase = WAF, recordType = AMG else
            // If UseCase = TCR and Account Geo = APJ/EMEA ,then recordType = AMG else recordType = PS
            setRecordTypeId = (useCase == 'WAF') || (useCase == 'TCR' && accountGeo <> Null &&
            (DGRATMapping.Geography_APJ__c.containsIgnoreCase(accountGeo) || DGRATMapping.Geography_EMEA__c.containsIgnoreCase(accountGeo))) ?
                            rtMap.get('AMG').getRecordTypeId() :
                            rtMap.get('Professional Services').getRecordTypeId();
            
            // If UseCase = SAAS, recordType = AMG                
            if(useCase == 'SAAS')
            	setRecordTypeId = rtMap.get('AMG').getRecordTypeId();
                            
            return setRecordTypeId;
        }
        
        // Method - 9: Method for Service Calculation
        // Called from - caseCreation method
        public string serviceCalculation (string useCase, Map<String, Schema.RecordTypeInfo> rtMap,Id setRecordTypeId, Merge_Contract_Detail__c eachCntrctLnRec){
      
          	// variable for setting service
      	string setServiceval = null;
      	
      	if( (useCase == 'TCR' || useCase == 'WAF') && setRecordTypeId == rtMap.get('AMG').getRecordTypeId()){
     
              	setServiceval = SC_Serv_ReqTyp_value__c.getValues('AMG').ServiceVal__c;
            }
            else if( (useCase == 'TCR' || useCase == 'WAF') ){
     
              	setServiceval = SC_Serv_ReqTyp_value__c.getValues('TCR-Category1').ServiceVal__c;
            }
            else
            {
            	setServiceval = SC_Serv_ReqTyp_value__c.getValues(useCase).ServiceVal__c;
            }
            
            return setServiceval;
      	
        }
        
        // Method - 10: Method for request Type Calculation
        // Called from -  caseCreation method
        public string RequestTypeCalculation (string useCase, Map<String, Schema.RecordTypeInfo> rtMap,Id setRecordTypeId, Merge_Contract_Detail__c eachCntrctLnRec){
      
          	// variable for setting RequestType
            string setReqTypeval;
            
            if( (useCase == 'TCR' || useCase == 'WAF') && setRecordTypeId == rtMap.get('AMG').getRecordTypeId()){
     
              	setReqTypeval = SC_Serv_ReqTyp_value__c.getValues('AMG').RequestTypeVal__c;
            }
            else if( (useCase == 'TCR' || useCase == 'WAF') ){
     
              	setReqTypeval = SC_Serv_ReqTyp_value__c.getValues('TCR-Category1').RequestTypeVal__c;
            }
            else
            {
            	setReqTypeval = SC_Serv_ReqTyp_value__c.getValues(useCase).RequestTypeVal__c;
            }
            
            return setReqTypeval;
            
        }
        
        // Method - 11: Method for Subject Calculation
        // Called from - caseCreation method
        public string subjectCalculation(string caseTitle, Merge_Contract_Detail__c eachCntrctLnRec, string useCase){
      
          	// Setting Subject
            string setSubject ;
            	
            setSubject = caseTitle + ' : ' + eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.Name;
            setSubject = (setSubject.length() > 254) ? setSubject.substring(0,254) : setSubject;
            
            return setSubject;
            
        }
        
        // Method - 12: Method for Description Calculation
        // Called from - caseCreation method
        public string descriptionCalculation(string useCase, Merge_Contract_Detail__c eachCntrctLnRec){
      
          	// Setting Subject
            string setDescription;
            
            setDescription = 'This notification states that it is time to conduct a Technical Configuration Review.\n' +
                        'If a Technical Configuration Review has been conducted within the last six months or ' + 
                        'the Customer has conducted more than their contracted limit within the year ' +
                        '(which is 2 by default) please close this case.\n' +
                        'Otherwise, please notify the Professional Services Team on the account that it ' +
                        'is time to conduct a Technical Configuration Review, by following the ' +
                        '“Technical Configuration Review Request” process located here:\n' +
                        'https://agora.akamai.com/wiki/Contacting_Professional_Services_Process#Request_Process';
                        
            if(useCase == 'SAAS')
            {
            	setDescription = 'Account Id: '+ eachCntrctLnRec.Original_Contract_Id__r.Account_Name__r.AKAM_Account_ID__c +
            				'\n Contract Original Start Date: ' + eachCntrctLnRec.Effective_Start_Date__c +
            				'\n Original Contract Id for Detail: ' + eachCntrctLnRec.Name +
            				'\n Please refer to the review process: \n'+
            				'https://agora.akamai.com/wiki/Service_and_Support/Products/SaaS_Provider_Option';
            }
                        
            return setDescription;
            
        }
        
        // Method - 13: Method for Origin Calculation
        // Called from - caseCreation method
        public string originCalculation(string useCase,Map<String, Schema.RecordTypeInfo> rtMap,Id setRecordTypeId){
      	
      		string setOrigin = null;
      		
      		if(setRecordTypeId == rtMap.get('Technical').getRecordTypeId() || setRecordTypeId == rtMap.get('AMG').getRecordTypeId())
      			setOrigin = 'Autogen';
      		
      		return setOrigin;	
      }

}