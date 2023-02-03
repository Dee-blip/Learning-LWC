global class SC_Sync_Contract_Header_Detail_Batch implements Database.Batchable<SObject>, Database.stateful {

    Public String batchQuery = Null;
    
    // Setting Error Message
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
       							 'Batch Class Name = SC_Sync_Contract_Header_Detail_Batch\n' + 
                                 		'Support Class Name = SC_Sync_Contract_Header_Support\n' +
                                 		'Method Name = HeaderSyncMethod\n';
    
    // Flag to determine whether Header Job to be invoked or Detail Job
    public boolean IsHeaderFlag = false;
    
    // Flag to determine whether Header Job to be invoked or Detail Job
    public boolean IsRUSJobRun = false;
    
    // Flag to determine Whether 1stTime run or Subsequent Run
    public boolean IsFirstRun = false;
    
    // Variable to store Last time Run Value
    public DateTime lastRun;
    
    //Normal Execution Query for Contract Header
    public String Contract_Header_Query;
    
    //Normal Execution Query for Contract Detail
    public String Contract_Detail_Query;
    
    //Test Class Query
    public String Test_Contract_HD_Detail_Query ; 
    
    // Constructor of Batch Class
    Public SC_Sync_Contract_Header_Detail_Batch(boolean isHeader, boolean IsRUSJobRun){
    
    		this.IsHeaderFlag = isHeader;
    		this.IsRUSJobRun  = IsRUSJobRun;
    	
    		// If it is a Header Call then set the Header Query else set the Detail Query
    		if(isHeader){
    		
    			if(SC_SupportEmail__c.getValues('1').Last_Contract_Header_Synch_Job_Run__c == null){
    			
				this.IsFirstRun = true;
				this.Contract_Header_Query = 'select Id,IS_COB_Created__c,Name,Original_Contract_ID__c' + 
				                             ' from Merge_Contract_Header__c where Original_Contract_ID__c <> null';
				
			}
			else
			{
				this.lastRun = SC_SupportEmail__c.getValues('1').Last_Contract_Header_Synch_Job_Run__c;
				this.Contract_Header_Query = 'select Id,IS_COB_Created__c,Name,Original_Contract_ID__c' + ' from Merge_Contract_Header__c'
									+ ' where Original_Contract_ID__c <> null and lastmodifieddate >= :lastRun';
				
			}
			
			// Setting Test Class Query for Header
			this.Test_Contract_HD_Detail_Query = 'select Id,IS_COB_Created__c,Name,Original_Contract_ID__c' +
        								' from Merge_Contract_Header__c' +
                                               		' order by Createddate Limit 50';
		
    		}
    		else
    		{
			if(SC_SupportEmail__c.getValues('1').Last_Contract_Detail_Synch_Job_Run__c == null){
		
				this.IsFirstRun = true;
				this.Contract_Detail_Query = 'select Id,Name,AKAM_Created_Date__c,lastmodifieddate,Effective_End_Date__c,Effective_Start_Date__c,'+
									'IS_COB_Created__c,IS_Existing_COB__c,Original_Contract_ID__c,'+
									'Product_Id__c,Product_Changes_in_Last_24_Hrs__c,Original_Detail_ID__c,Product__c'+
									' from Merge_Contract_Detail__c where Original_Detail_ID__c <> null';
			}
			else
			{
				this.lastRun = SC_SupportEmail__c.getValues('1').Last_Contract_Detail_Synch_Job_Run__c;
				this.Contract_Detail_Query = 'select Id,Name,AKAM_Created_Date__c,lastmodifieddate,Effective_End_Date__c,Effective_Start_Date__c,'+
												'IS_COB_Created__c,IS_Existing_COB__c,Original_Contract_ID__c,'+
												'Product_Id__c,Product_Changes_in_Last_24_Hrs__c,Original_Detail_ID__c,Product__c'+
												' from Merge_Contract_Detail__c' +
												' where Original_Detail_ID__c <> null and lastmodifieddate >= :lastRun';
			}
			
			// Setting Test Class Query for Detail
			this.Test_Contract_HD_Detail_Query = 'select Id,Name,AKAM_Created_Date__c,lastmodifieddate,Effective_End_Date__c,Effective_Start_Date__c,'+
									'IS_COB_Created__c,IS_Existing_COB__c,Original_Contract_ID__c,'+
									'Product_Id__c,Product_Changes_in_Last_24_Hrs__c,Original_Detail_ID__c,Product__c'+
									' from Merge_Contract_Detail__c where Original_Detail_ID__c <> null' +
									' order by Createddate Limit 50';
    		
    		}
    }
   
 	
    
    
    
    /*@Method <This method gets executed acutomatically when the batch job is started.>*/ 
   global Database.QueryLocator start(Database.BatchableContext BC){
   
        batchQuery = (IsHeaderFlag == True) ? Contract_Header_Query : Contract_Detail_Query;
       
        batchQuery = (System.Test.isRunningTest()) ? Test_Contract_HD_Detail_Query : batchQuery;
        
        // Update the Custom Setting Value with Current Time Stamp for Last Run
        if(IsHeaderFlag){
        
        	SC_SupportEmail__c heraderUpdate = SC_SupportEmail__c.getValues('1');
        	heraderUpdate.Last_Contract_Header_Synch_Job_Run__c = system.now();
        	Update heraderUpdate;
        }
        else
        {
        	SC_SupportEmail__c detailUpdate = SC_SupportEmail__c.getValues('1');
        	detailUpdate.Last_Contract_Detail_Synch_Job_Run__c = system.now();
        	Update detailUpdate;
        }
        
        return Database.getQueryLocator(batchQuery);
   }
   
   global void execute(Database.BatchableContext BC, list<SObject> scope){
   
   		string errHdr = ' ******* ';
   
   		// List to store all Incoming Contract Header
   		list<Merge_Contract_Header__c> allContractHeader = new list<Merge_Contract_Header__c>();
   		
   		// List to store all Incoming Contract Detail
   		list<Merge_Contract_Detail__c> allContractDetail = new list<Merge_Contract_Detail__c>();
   		
   		// Type Casting Header and Detail List
   		if(IsHeaderFlag){
   		
   			allContractHeader = (Merge_Contract_Header__c[]) scope ;
   			HeaderSyncMethod(allContractHeader);
   		
   		} 
   		else
   		{
   			allContractDetail = (Merge_Contract_Detail__c[]) scope ;
   			DetailSyncMethod(allContractDetail);
   		}  		
     }
     
      global void finish(Database.BatchableContext BC){
          
        // If Header is true, then call for Detail Synch
      	if(IsHeaderFlag){
      	
      		SC_Sync_Contract_Header_Detail_Batch detailBatch = new SC_Sync_Contract_Header_Detail_Batch(false,IsRUSJobRun);
			database.executebatch(detailBatch,200);
      	}
      	// Check for Logic in Detail 
      	else
      	{   		
      		// Check if IsRUSJobRun = true, then call RUS Job
      		if(IsRUSJobRun){
      		
      			// Calling SC_Autogen_RUS_PPSM_QBR_Batch class
       			Database.executebatch(new SC_Autogen_RUS_PPSM_QBR_Batch ()); 
            // Calling SC_Autogen_PLUS_ADVANCED_Batch class
            Database.executebatch(new SC_Autogen_PLUS_ADVANCED_Batch ());
      		}
      	}
      }
      
    // Called from trigger SC_Sync_Contract_Detail 
    public void DetailSyncMethod(List<Merge_Contract_Detail__c> allContractDetail){
        
        //Map to store Original_Detail_ID__c + Contract Line record
        Map<string,Merge_Contract_Detail__c > orgDetId_MCDMap = new Map<string,Merge_Contract_Detail__c >();
        
        // List for Upsert ACHD records
        List<Autogen_Contract_Header_Detail__c> ACHDListforUpsert_Detail = new List<Autogen_Contract_Header_Detail__c>();
        
        //Stores the Record Rype Id for Record Type Name 'Line'
        Id RecordTypeIDDetail = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Line').getRecordTypeId();
        
        //Creating Instance
        Autogen_Contract_Header_Detail__c  conDetail ;
        
        // Loop to set orgDetId_MCDMap variable(To make sure that Unique Original Detail Ids are coming)
        for(Merge_Contract_Detail__c forEachDetail : allContractDetail){
        
        	if(forEachDetail.Original_Detail_Id__c <> null)
        		orgDetId_MCDMap.put(forEachDetail.Original_Detail_Id__c, forEachDetail);
        }
        
        
	 for(Merge_Contract_Detail__c forEachDetail : orgDetId_MCDMap.values()){
	
		  //Initialiazing Object
		  conDetail = new Autogen_Contract_Header_Detail__c ();
		  
		  //Setting values for each field 
		  conDetail.Original_Detail_Id__c = forEachDetail.Original_Detail_Id__c;
		  conDetail.AKAM_Created_Date__c = forEachDetail.AKAM_Created_Date__c;
		  conDetail.Parent_Contract_Header__c = forEachDetail.Original_Contract_Id__c;
		  conDetail.Parent_Contract_Detail__c   = forEachDetail.Id;
		  conDetail.Effective_Start_Date__c = forEachDetail.Effective_Start_Date__c;
		  conDetail.Effective_End_Date__c =  forEachDetail.Effective_End_Date__c ;
		  conDetail.Product__c  = forEachDetail.Product_Id__c;
          conDetail.Marketing_Product_Name__c = forEachDetail.Product__c;// Added as part of CR 3118481
		  conDetail.RecordTypeID = RecordTypeIDDetail;
         
		  
		  // Setting the Values for 1st time run
		  if(IsFirstRun){
		  
		  	conDetail.IS_Existing_COB__c 				= forEachDetail.IS_Existing_COB__c;
                  conDetail.Product_Changes_in_Last_24_Hour__c 	= forEachDetail.Product_Changes_in_Last_24_Hrs__c;
                  conDetail.IS_COB_Created__c 				= forEachDetail.IS_COB_Created__c;
                    
		  }
		  
		  //adding records to list contDetailList
		  ACHDListforUpsert_Detail.add(conDetail);
	    }
	
		try{
		
	   		//Upserting records in object Autogen_Contract_Header_Detail__c based on external key Original_Detail_ID__c
	    		upsert ACHDListforUpsert_Detail Original_Detail_ID__c ;  
	    	}
	    	catch(Exception e)
        	{
            
                    errorMessage += '\n'+e.getMessage();
                    SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
                    sc_COBSupportCls.senEmailForError('Exception in Autogen Contract Synch Job', errorMessage);
            }         
           
   }
    
    // Method to sync all Header  
    // Called from trigger SC_Sync_Contract_Header
    public void HeaderSyncMethod(List<Merge_Contract_Header__c> allContractHeader){
        
        //Map to store Original_Header_ID__c + Contract Header record
        Map<string,Merge_Contract_Header__c > orgHdId_MCHMap = new Map<string,Merge_Contract_Header__c >();
        
        // List for Upsert ACHD records
        List<Autogen_Contract_Header_Detail__c> ACHDListforUpsert_Header = new List<Autogen_Contract_Header_Detail__c>();
        
        //Stores the Record Rype Id for Record Type Name 'Header'
        Id RecordTypeIDHeader = Autogen_Contract_Header_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Header').getRecordTypeId();
        
        //Creating Instance
        Autogen_Contract_Header_Detail__c  conHeader ;
        
        // Loop to set orgHdId_MCHMap variable(To make sure that Unique Original Contract Ids are coming)
        for(Merge_Contract_Header__c forEachHeader : allContractHeader){
        
        	if(forEachHeader.Original_Contract_ID__c <> null)
        		orgHdId_MCHMap.put(forEachHeader.Original_Contract_ID__c, forEachHeader);
        }
        
	  for(Merge_Contract_Header__c forEachHeader : orgHdId_MCHMap.values()){
	    
	    	//Initialiazing Object
	    	conHeader = new Autogen_Contract_Header_Detail__c ();
	    
	    	//Setting values for each field
	    	conHeader.Original_Header_ID__c    	= forEachHeader.Original_Contract_ID__c;
	    	conHeader.Parent_Contract_Header__c = forEachHeader.Id;
	    	conHeader.RecordTypeID 			= RecordTypeIDHeader;
	    	
	    	// Setting the Values for 1st time run
		if(IsFirstRun){
		  
                  conHeader.IS_COB_Created__c 	= forEachHeader.IS_COB_Created__c;
                    
		}
	   
	    	//adding records to list contDetailList
	    	ACHDListforUpsert_Header.add(conHeader);
	  }
        
        	try {
        	
            	//Upserting records in object Autogen_Contract_Header_Detail__c based on external key Original_Header_ID__c
             	upsert ACHDListforUpsert_Header Original_Header_ID__c  ;
            }
        	catch(Exception e)
        	{
            
                    errorMessage += '\n'+e.getMessage();
                    SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
                    sc_COBSupportCls.senEmailForError('Exception in Autogen Contract Synch Job', errorMessage);
            }  
   } 
     
    
}