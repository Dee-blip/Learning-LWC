/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR(4.4)    DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                                       
|  23-Dec-2014      Aditya Sonam    2637462     This is a support class for - SC_Autogen_ExistingCOB_Batch
|  23-Feb-2015      Aditya Sonam    2928180     Added condition for Existing Customer with single contract and new line item                 
|  07-May-2015      Aditya Sonam    2637462     Changes the logic to create case per Account and added case detail in description                              
+=====================================================================================================*/


public class SC_Autogen_ExistingCOB_Support_old{
    
    // Map to store Account and Detail Id for method 4
    static Map<Id,String> caseAccountDetailMap = new Map<Id,String>();
    
    // stores account id and Detail Effective start date      
    static Map<Id,Date> detailEffStrtDateDesc = new Map<Id,Date>();
             	    
  // Method to get all Active Contracts   
    public void mergedContractHeaderMethod(List<Account> allReturnAccount){
    
    	
    	List<Merge_Contract_Header__c> allReturnContracts = new list<Merge_Contract_Header__c>([Select Id,Account_Name__c,Is_COB_Created__c,Effective_Start_Date__c,Effective_End_Date__c,
    															 Name,Account_Name__r.Name,Account_Name__r.AKAM_Account_ID__c
    															 from Merge_Contract_Header__c where
    															 Locked__c = true and Active__c = true and 
    															 Cancellation_Date__c = Null and
    															 Contract_Transferred_To__c = Null and
    															 Effective_Start_Date__c <= Today and
    															 Effective_End_Date__c > Today and 
                                                                 Account_Name__c IN : allReturnAccount ]);
    															 
          
          main_ECOB_Method(allReturnContracts);
    }
    
    
    
    // Main Method
    public void main_ECOB_Method(List<Merge_Contract_Header__c> allReturnContracts){
        
        // Create a Set to store all Original Contract Ids
        set<Id> allOrgContractIds = new set<Id>();
        
        
         // Loop to Iterate the All Fetched Contract List to Set values for above 2 variables
         For(Merge_Contract_Header__c mcH : allReturnContracts){
            
            allOrgContractIds.add(mcH.Id);
           
         } 
       
        
         // Calling method fetchValidProduct
          List<String> productSet = new List<String>();
          productSet = fetchValidProduct();
              
                                
         //Fetching Contract Detail record based on the valid contract fetched in batch start method
          List<Merge_Contract_Detail__c> contractDetailList = new list<Merge_Contract_Detail__c>([Select Id,Original_contract_id__c,
                           Original_Detail_Id__c,Product__c,Product_Id__c,Effective_Start_Date__c,Effective_End_Date__c,
                           Original_contract_id__r.Account_Name__c,Original_contract_id__r.Account_Name__r.Name,
                           Original_contract_id__r.Account_Name__r.AKAM_Account_ID__c,Original_contract_id__r.Opportunity_Name__r.Name,
                           Original_contract_id__r.Opportunity_Name__r.AKAM_Opportunity_ID__c,Original_contract_id__r.Name,
                           Original_Contract_Id__r.createddate,Original_Contract_Id__r.Effective_Start_Date__c, Product_Changes_in_Last_24_Hrs__c 
                           from Merge_Contract_Detail__c
                           where  IS_Existing_COB__c = True and Effective_Start_Date__c <= Today and 
                           Effective_End_Date__c >= Today and Original_contract_id__c IN : allReturnContracts and Product_Id__c IN :productSet order by Effective_Start_Date__c desc]);
          
        // Fetching all details for which IS Existing Onboarding flag is false to to compare products from details whose IS Existing Onboarding = True
        List<Merge_Contract_Detail__c>  allContractProdList = new List<Merge_Contract_Detail__c>([Select Original_contract_id__c,Product_Id__c from Merge_Contract_Detail__c       
                                                                                                  where IS_Existing_COB__c = False and Original_contract_id__c IN :allReturnContracts]);
        String productStr = '';
        
        //Map to store Contract id and Product
        Map<Id,String> contractProductMap = new Map<Id,String>();
        
        If(allContractProdList.size()>0){
            
        // Loop to add all products related to a contract 
        For(Merge_Contract_Detail__c mc : allContractProdList){
        
			productStr = contractProductMap.get(mc.Original_contract_id__c);
			
			If(productStr == Null){
              
              	productStr = '';
              
              }
              
              productStr = productStr +','+ mc.Product_Id__c;
              
              contractProductMap.put(mc.Original_contract_id__c,productStr);            
            
           }
        }
      
              
         //Stores List of Contract associated with an Account 
          List<Merge_Contract_Header__c> listContractHeader;
                               
         //Stores the ContractDetail information for which the product value has changed to a new value or added        
          Map<Id,Merge_Contract_Detail__c> existContractDetailMap = new Map<Id,Merge_Contract_Detail__c>();
                 
         
         // Variables to stores the Valid Product,Prod Name, Detail and Eff Strt Date from Object Exist_Cust_Onbord_Products__c associated with a contract
             List<String> prodChangeList;
        
              
         // For each contract detail fetching Account and its Product, Product Name, Detail Id and Detail Eff Start Date
         
         for(Merge_Contract_Detail__c mcD : contractDetailList){
          
                     
             //List to store products from details whose Is Existing flag is false and are already present for a contract 
               prodChangeList = new list<String>();
              
              //Splitting the field Product_Changes_in_Last_24_Hrs__c and creating a list of products.
             if(mcD.Product_Changes_in_Last_24_Hrs__c != Null ){
                 
             		 mcD.Product_Changes_in_Last_24_Hrs__c = mcD.Product_Changes_in_Last_24_Hrs__c.replaceFirst(':','');
             		 
                     prodChangeList = mcD.Product_Changes_in_Last_24_Hrs__c.split(':');     
                       
              
         
                //Checking if the contract has multiple line items
                // Contract with multiple details has a product change
         
                   if(contractProductMap.containsKey(mcD.Original_Contract_Id__c) 
                      && !(contractProductMap.get(mcD.Original_Contract_Id__c).containsIgnoreCase(mcD.Product_Id__c))
                      && prodChangeList[0] != mcD.Product_Id__c){
                    
                         existContractDetailMap.put(mcD.Original_contract_id__r.Account_Name__c,mcD);
                       
                         setContractDetail(mcD);
                          
                         detailEffectStartDate(mcD);
                    
                   }
                 
           
                //Stores Contract and its details information for existing customer with Single contract 
                //Single contract with single line item and product change
                //contract with multiple line item and all line item updated
                    else if (!contractProductMap.containsKey(mcD.Original_Contract_Id__c)
                             && (prodChangeList[0] <> mcD.Product_Id__c || ( mcD.Original_Contract_Id__r.createddate < system.today() && prodChangeList[0] == mcD.Product_Id__c))) {
              
                          existContractDetailMap.put(mcD.Original_contract_id__r.Account_Name__c,mcD );
                          
                          setContractDetail(mcD);
                          
                          detailEffectStartDate(mcD);
                  }
            
                //store contract and its details for new detail added to an existing contract with multiple details
                //Contract with multiple line item has a new line item
                	 else if (contractProductMap.containsKey(mcD.Original_Contract_Id__c)
                             && !(contractProductMap.get(mcD.Original_Contract_Id__c).containsIgnoreCase(mcD.Product_Id__c))
                             && prodChangeList[0] == mcD.Product_Id__c) {
              
                          existContractDetailMap.put(mcD.Original_contract_id__r.Account_Name__c,mcD );
                          
                          setContractDetail(mcD);
                          
                          detailEffectStartDate(mcD);
                  }
             }                     
          }   
        SYSTEM.debug('------existContractDetailMap------'+existContractDetailMap);
           /*****........................Case Creation........................ ***/
         
        // Create Case method returns Id, and Date to Map caseId_ContrctEffStrdt_Map
        
        List<Case> createdCaseList = new List<Case>();
                              
         		createdCaseList = createCase(existContractDetailMap);
            
       
        
         // Deallocate memory for Phase-2 List
         existContractDetailMap.clear();
         
                
         /*****........................Task Creation........................ ***/
         
         if(createdCaseList.size() > 0){
            
            	// Calling for Task Creation
            	createTask(createdCaseList);
            	
            	// Calling for Contract Detail Info Record Creation
            	createContractDetailInfoObject(createdCaseList);
         }
         
         // Deallocate Memory
         createdCaseList.clear();
         
         
         
         /*****........................Update Contracts with Is_Existing_Contract = False........................ ***/
         
         
         updateAllContractDtl(contractDetailList);
         
         // Deallocate Memory
          contractDetailList.clear();
       
  }
                
       
       //Method 2: for Fetching Valid Product
       // Called from - main_ECOB_Method method
       
       public List<String> fetchValidProduct(){
       
       		List<String> productSet = new List<String>();
           
            For(Exist_Cust_Onbord_Product__c forEachProd : [Select Marketing_Prod_ID__c 
                                                            from Exist_Cust_Onbord_Product__c where Onboard_Flag__c = True]){
                                                            
                 productSet.add(forEachProd.Marketing_Prod_ID__c);
                
            }  
       
               return productSet;
       
       }
                      
      // Method - 3: Method for Case Creation
      // Called from - main_ECOB_Method method
      
      public List<case> createCase(Map<Id,Merge_Contract_Detail__c> existContractDetailMap){
    
        // List to store for Newly Created Case
        List<Case> newCaseList = new List<Case>();        
        
        // Case for each Record
        case eachCaserec;   
        
        // Setting Subject
        string setSubject;
        
        // Setting Description
        string setDescription;
        
        // Fetching Assignment Rule
        AssignmentRule assgnRule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
            
        // Fetching Case Record Types
        Id setRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
       // Id setRecordTypeId = rtMap.get('AMG').getRecordTypeId();
         
         Merge_Contract_Detail__c mcD;
         
         	// Loop for creating each Case
       	 	for(Id mcDId : existContractDetailMap.keySet()){
        
            // Initializing Merge_Contract_Detail__c
          		     mcD = existContractDetailMap.get(mcDId);
           
                            
           			 // Setting Case Subject 
           			 setSubject = 'Existing Customer : ' + mcD.Original_contract_id__r.Account_Name__r.Name + ' : Complete On-boarding Process';  
           			 setSubject = (setSubject.length() > 254) ? setSubject.substring(0,254) : setSubject;
            
           			 //Setting Case Description
          			  setDescription = 'Account Name: ' + mcD.Original_contract_id__r.Account_Name__r.Name + ' \n' +
                             			'Account Id: ' + mcD.Original_contract_id__r.Account_Name__r.AKAM_Account_ID__c ;
                             
            		  setDescription = (setDescription.length() > 31999) ? setDescription.substring(0,31999) : setDescription;
                            
                             
            		eachCaserec = new Case();
            		eachCaserec.setOptions(dmo);
            		eachCaserec.RecordTypeId            = setRecordTypeId;
           		    eachCaserec.AccountId               = mcD.Original_contract_id__r.Account_Name__c;
            		eachCaserec.Contract__c             = mcD.Original_contract_id__c;
            		eachCaserec.Service__c              = SC_Serv_ReqTyp_value__c.getValues('ECOB').ServiceVal__c;
            		eachCaserec.Request_Type__c         = SC_Serv_ReqTyp_value__c.getValues('ECOB').RequestTypeVal__c;
                	eachCaserec.Request_Sub_Type__c     = SC_Serv_ReqTyp_value__c.getValues('ECOB').Request_SubTypeVal__c ;
            		eachCaserec.Origin                  = 'Proactive';
            		eachCaserec.Severity__c             = '3';
            		eachCaserec.Do_Not_Show_in_Portal__c= true;
            		eachCaserec.Subject                 = setSubject;
            		eachCaserec.Description             = setDescription;
            		eachCaserec.ECOB_Details__c         = caseAccountDetailMap.get(mcD.Original_contract_id__r.Account_Name__c);
            
            // Add the case record to List
            newCaseList.add(eachCaserec);
                   	     	
          	
          }	
            
            	
            // Insert all Cases
            Insert newCaseList; 
                    
        
            //Calling ecobContractReport method from SC_CaseIssueClass class to update description field with Report Link
            SC_CaseIssueClass.ecobContractReport(newCaseList);
         
                     
            return newCaseList;
             
    }         
                                        
  // Create ECOB_Contract_Detail_Information__c 
  
   public void createContractDetailInfoObject(list<case> newCaseList){
   
   		  ECOB_Contract_Detail_Information__c ecobConDet  ;
         
   		  List<ECOB_Contract_Detail_Information__c> ecobConDetList = new List<ECOB_Contract_Detail_Information__c>();
   
          // Looping for each ECOB Case List  
          for (Case eachCase : newCaseList){
  
                 
             for( Id detailId : eachCase.ECOB_Details__c.split(',') ) {
                            
                  ecobConDet = new ECOB_Contract_Detail_Information__c();
                  ecobConDet.Case_ID__c = eachCase.Id ;
                  ecobConDet.Contract_Detail_Id__c = detailId;
                
                 // Adding record to the list 
                 ecobConDetList.add(ecobConDet);
             
             }
             
          }        
         // Inserting records in object ECOB_Contract_Detail_Information__c
            if(ecobConDetList.size() > 0 ){ 
             
             insert ecobConDetList; 
             
            }
   
   }
    
    		  
  //Method 4: Method to insert Account Id and related detail is which are valid for case creation in a Map
  //Called from Main Method
             
    public void setContractDetail(Merge_Contract_Detail__c contractDetail){
        
        
        // variable to detail Id's which are valid for case creation
        string detailId = caseAccountDetailMap.get(contractDetail.Original_contract_id__r.Account_Name__c);

        if(detailId == null){
        	
        	caseAccountDetailMap.put(contractDetail.Original_contract_id__r.Account_Name__c,contractDetail.Id);
        
        }
        
        else
        
        {     
        	detailId += ',' + contractDetail.Id;
        	
        	caseAccountDetailMap.put(contractDetail.Original_contract_id__r.Account_Name__c,detailId);
        	
        }
       
    }
    
    
    //Method 5: to get earliest effective start date of details
    //Called from main method
    
    public void detailEffectStartDate(Merge_Contract_Detail__c effdetail){
        
         date effstrtdate = detailEffStrtDateDesc.get(effdetail.Original_contract_id__r.Account_Name__c);
        
         if(effstrtdate ==  null){
            
            detailEffStrtDateDesc.put(effdetail.Original_contract_id__r.Account_Name__c,effdetail.Effective_Start_Date__c);           
        }
        
         else if(effstrtdate > effdetail.Effective_Start_Date__c ){
            
            detailEffStrtDateDesc.put(effdetail.Original_contract_id__r.Account_Name__c,effdetail.Effective_Start_Date__c);
        }
        
    }
    
    
    // Method - 6: Method for Task Creation
    // Called from - mmain_ECOB_Method method
    
    public void createTask(List<Case> createdCaseList){
    
           // Fetch the Data from Custom Setting - AutoGencase - Activity
            List<SC_Autogen_ExistingCOB_Activity__c>  allActivityValues = SC_Autogen_ExistingCOB_Activity__c.getall().values();
        
            // Fetch Default Task Owner from Custom Setting - SC_SupportEmail__c
            string getOwnerAlias = SC_SupportEmail__c.getValues('1').Default_Task_Owner__c;
        
            // Fetch User Id from User Alias
            List<User> userRec = new  List<User>();
        
            userRec = [select Id from user where alias = :getOwnerAlias limit 1];
            
            // Fetching Service Activity record Type from Task Obj
            //Map<String, Schema.RecordTypeInfo> rtMap = Task.sObjectType.getDescribe().getRecordTypeInfosByName();
        
            Id setRecordTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
            
            // List of Task which are going to create
            List<Task> allTaskInsertList = new List<Task>();
      
      	    // Task record used inside Loop for each Record
            Task newtask;
             
            // Loop for each Case Id
            for (case eachCaseRec : createdCaseList){
        
              // Loop for each Task Record from Custom setting
                for(integer i =0 ; i < allActivityValues.size() ; i ++){

                    newtask = new Task();
                    newtask.Subject                  =   allActivityValues[i].Activity_Name__c;
                    newtask.Description              =   allActivityValues[i].Activity_Detail__c;                                                            
                    newtask.Type__c                  =   'Task';
                    newtask.Status                   =   'Not Started';
                    newtask.WhatId                   =   eachCaseRec.Id;
                    newtask.OwnerId                  =   userRec[0].Id;
                    newtask.RecordTypeId             =   setRecordTypeId;
            
                    newtask.ActivityDate     		 = (allActivityValues[i].Activity_Due_date__c == '0') ?
                      								detailEffStrtDateDesc.get(eachCaseRec.AccountId) :
                      								system.today().addDays( Integer.valueOf(allActivityValues[i].Activity_Due_date__c));
            
                    // Adding to List
                    allTaskInsertList.add(newtask);
                }
           }
        
        	// Create Task
        	Insert allTaskInsertList;
    
       }        
              
      // Method - 7: Method for Updating all Contract Detail with IS ECOB Created = True
      // Called from - main_COB_Method method
      
     public void updateAllContractDtl(List<Merge_Contract_Detail__c> contractDetailList){
    
          // List to Update all Detail
          List<Merge_Contract_Detail__c> allReturnDetailUpdate = new List<Merge_Contract_Detail__c>();
        
          For(Merge_Contract_Detail__c mcDetail :contractDetailList){
        
           mcDetail.IS_Existing_COB__c = False;
           mcDetail.Old_Product_Id__c = '';
           mcDetail.Product_Changes_in_Last_24_Hrs__c  = '';
        
              allReturnDetailUpdate.add(mcDetail);        
        }
        
         // Update All Detail
         Update allReturnDetailUpdate;
      
    }
    
}