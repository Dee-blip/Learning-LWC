/*---------------------------------------------------------------------------------
    Class name          :   SC_SI_HomePageControllor
    Test Class          :   
    Author              :   Vishnu Sharma / Himanshu 
    Created             :   05-Jul-20
    JIRA                :   ESESP-3015
    Purpose             :   Incident Management App Home Page
             
    Last Modified         Developer                           Purpose            
    ============= ========================         			  ==========
    24-Aug-2020     Vishnu Sharma  / Himanshu                 Initial Version
	Test Class : SC_SI_HomePageController_Test
* --------------------------------------------------------------------------------*/
public without sharing class SC_SI_HomePageControllor {
    
    /****************** Class Level Variables ***************************/
    // Map to store Status UI + Backend Value
 	public static Map<string,string> StatusValueMap;
        
    // Map to store Severity UI + Backend Value
 	public static Map<string,string> SeverityValueMap;
        
    // Map to store Queue UI + Backend Value
 	public static Map<string,string> QueueValueMap;
 	
 	// Map to store SectionName + BaseQuery
 	public static Map<string,string> sectionName_baseQueryMap;
 	
 	// Map to store Severity Name + css Class Name
 	public static Map<string,string> severityName_cssClassMap;
 	
 	// Map to store Incident Backend Status + UI Status
 	public static Map<string,string> Status_Backend_UIMap;
        
    
 	/****************** Wrapper Class Structures ***************************/
 	// Outer Wrapper Class to be returned to Home Page	
 	public class OuterwrapperClass{
 	
 		// Checking Logged in User is IRAPT or not
 		public boolean isIRAPTUser;
 		
 		// Wrapper to store Status Name + Selected Value
 		public List<FilterDropDownrapperClass> FilterStatus_SelectedvalueWrp;
        
        // Wrapper to store Severity Name + Selected Value
 		public List<FilterDropDownrapperClass> FilterSeverity_SelectedvalueWrp;
 		
 		// Wrapper to store Queue Name + Selected Value
 		public List<FilterDropDownrapperClass> FilterQueue_SelectedvalueWrp;
 		
 		// Data for My Open Incident / Incident Requested Section
 		public List<IncidentWrapperClass> incidentList_myOpenIncidents;
 		
 		// Data for Incidents in Queue Section
 		public List<IncidentWrapperClass> incidentList_IncidentsInQueue;
 		
 		// Data for All Open Incidents
 		public List<IncidentWrapperClass> incidentList_AllOpenIncidents;
          
        
        // Default Constructor
        public OuterwrapperClass(){ 
            
            FilterStatus_SelectedvalueWrp 	= new List<FilterDropDownrapperClass>();
            FilterSeverity_SelectedvalueWrp = new List<FilterDropDownrapperClass>();
            FilterQueue_SelectedvalueWrp	= new List<FilterDropDownrapperClass>();
            incidentList_myOpenIncidents 	= new List<IncidentWrapperClass>();
            incidentList_IncidentsInQueue	= new List<IncidentWrapperClass>();
            incidentList_AllOpenIncidents	= new List<IncidentWrapperClass>();
        }
        
     }
     
     // Wrapper Class for Incident Data
     public class IncidentWrapperClass{       
		public string Id; 			// Mapping - Id
     	public string Incident_ID; 	// Mapping - Name
     	public string Title;		// Mapping - Title__c
     	public string Status;		// Mapping - Status__c
		public string Impact; 		// Mapping - Severity__c
		public string ImpactClass; 
     	public string OwnerName;	// Mapping - Owner.Name
     	public string Incident_Requested_By; // Mapping - Incident_Requested_By__r.Name
		 public string TIM; 			// Mapping - TIM_IC__r.Name
		 public string Age;				// Mapping - Age
     	public DateTime Createddate; 	// Mapping - createdDate
     	
     	public boolean isTransitionExist; 		// True if Transition Exists
		public string transitionDescription; 	// Mapping - SC_SI_Notes__c+ SC_SI_Suggested_BIL__r.Nmae
		public string suggestedBIL;  
     	public string targetShift; 				// Mapping - SC_SI_Target_Shift__c
     	public string wakeUpTime; 				// Mapping - SC_SI_Future_Trigger_Time__c
     	
     	public string CreatedDate_Text; // Storing Format value of created Date
     	
 		public boolean hideEditAccess; // If Logged In User has Edit Access to SI Record
 		
		 public string SI_recordLink; // SI record Link for Navigation
		 
		 public string transitionFlagVisible; // SI record Link for Navigation
     	
     	// Default Constructor
     	public IncidentWrapperClass(){
     		
     		 isTransitionExist = false;
			 hideEditAccess = false;
			 transitionFlagVisible = 'slds-hide';
     	}    	
     
     } 
     
     // Wrapper Class for FilterDropDown
     public class FilterDropDownrapperClass{ 
     
     	public string UI_Value; // To Store UI Name
     	public boolean isEnabled; // To Display Value or not
     	
     	// Default Constructor
     	public FilterDropDownrapperClass(){
     		isEnabled = true;
     	} 
	 }
	 
	     
     // Wrapper Class for For Storing Data in JSON
     public class StoreFilterDataWrapperClass{ 
     
     	public List<string> Status;  	// For all Selected Status for Query generation
     	public List<string> Severity;	// For all Selected Severity for Query generation
     	public List<string> Queue; 		// For all Selected Queue for Query generation
     	public List<FilterDropDownrapperClass> FilterStatusUI_save;		// For UI dropdown Mapping
     	public List<FilterDropDownrapperClass> FilterSeverityUI_save;	// For UI dropdown Mapping
     	public List<FilterDropDownrapperClass> FilterQueueUI_save;		// For UI dropdown Mapping
     	
     	
     	// Default Constructor
     	public StoreFilterDataWrapperClass(){
     		Status = new List<string>();
     		Severity = new List<string>();
     		Queue = new List<string>(); 
     		FilterStatusUI_save = new List<FilterDropDownrapperClass>();
     		FilterSeverityUI_save = new List<FilterDropDownrapperClass>();
     		FilterQueueUI_save = new List<FilterDropDownrapperClass>();
     		
     	} 
     }
     
     // Method - 1 : Main Method to be called from Home Page during Page Load
    @AuraEnabled
    public static string getHomePageData(boolean isFirstTimeLoad, string sectionName) {
        
        // List variables for Query Calculation
         List<string> allStatusFromWrp = new List<string>();
         List<string> allSeverityFromWrp = new List<string>();
         List<string> allQueueFromWrp = new List<string>();
          
        // Instantiating Outer Wrapper
        OuterwrapperClass returnHomePageData = new OuterwrapperClass();        
        
        // Step - 1 (Common) : Calling Init Method for Data Setup
        initialDataSetup(returnHomePageData);
        
        // Step - 2 : Converting wrapper value to List for calculation     
        convertWrpToList(returnHomePageData, allStatusFromWrp,  allSeverityFromWrp, allQueueFromWrp);
        
        // Step - 3 (Common) : Getting isIRAPT Value
        string isIRAPTUserValue = (returnHomePageData.isIRAPTUser) ? 'IRAPT' : 'NonIRAPT';
        
        // For Query
        string getQuery; 
        
        // Use Case - 1 : Non - IRAPT User Logged IN + First Time
        if(isFirstTimeLoad && isIRAPTUserValue == 'NonIRAPT'){
        
        	// Generate Query and get Data for My Open Incident Section
        	getQuery = generateQuery(isIRAPTUserValue, 'My Open Incidents',allStatusFromWrp, allSeverityFromWrp, allQueueFromWrp);
        	getIncidentData(isIRAPTUserValue,getQuery, 'My Open Incidents', returnHomePageData,allStatusFromWrp, allSeverityFromWrp,allQueueFromWrp); 
        }
        
        // Use Case - 2 : IRAPT User Logged IN + First Time
        else if(isFirstTimeLoad && isIRAPTUserValue == 'IRAPT'){
        
        	// Generate Query and get Data for My Open Incident Section
        	getQuery = generateQuery(isIRAPTUserValue, 'My Open Incidents',allStatusFromWrp, allSeverityFromWrp, allQueueFromWrp);
        	getIncidentData(isIRAPTUserValue,getQuery, 'My Open Incidents', returnHomePageData,allStatusFromWrp, allSeverityFromWrp,allQueueFromWrp); 
			
			// Getting Save Filter Data
			retrieveFilterData(returnHomePageData,allStatusFromWrp, allSeverityFromWrp, allQueueFromWrp);
			
			// Generate Query and get Data for Incidents In Queue Section
			getQuery = generateQuery(isIRAPTUserValue, 'Incidents In Queue',allStatusFromWrp, allSeverityFromWrp, allQueueFromWrp);
			getIncidentData(isIRAPTUserValue,getQuery, 'Incidents In Queue', returnHomePageData,allStatusFromWrp, allSeverityFromWrp,allQueueFromWrp); 
        }
  
		else if(!isFirstTimeLoad){
			
			// Getting Save Filter Data
			if(sectionName == 'Incidents In Queue'){
				retrieveFilterData(returnHomePageData,allStatusFromWrp, allSeverityFromWrp, allQueueFromWrp);
			}
        
        	// Generate Query and get Data for My Open Incident Section
        	getQuery = generateQuery(isIRAPTUserValue, sectionName,allStatusFromWrp, allSeverityFromWrp, allQueueFromWrp);
			getIncidentData(isIRAPTUserValue,getQuery, sectionName, returnHomePageData,allStatusFromWrp, allSeverityFromWrp,allQueueFromWrp); 
        }
		
        return JSON.serialize(returnHomePageData);
    } 
    
    
    
    // Method - 2 : to check if logged-in user is IRAPT User
    public static void initialDataSetup(OuterwrapperClass returnHomePageData) {
        
        // Setting isIRAPT User Value
        returnHomePageData.isIRAPTUser = getUserDetails();
        
        StatusValueMap 				= new Map<string,string>();
        SeverityValueMap 			= new Map<string,string>();
        QueueValueMap 				= new Map<string,string>();
		sectionName_baseQueryMap 	= new Map<string,string>();
		severityName_cssClassMap    = new Map<string,string>();
		Status_Backend_UIMap		= new Map<string,string>();

        
        // Adding All Values to Wrapper List for Position - 1
        FilterDropDownrapperClass eachWrp = new FilterDropDownrapperClass();
        eachWrp.UI_Value = 'All';
        returnHomePageData.FilterStatus_SelectedvalueWrp.add (eachWrp);
        
        eachWrp = new FilterDropDownrapperClass();
        eachWrp.UI_Value = 'All';
        returnHomePageData.FilterSeverity_SelectedvalueWrp.add (eachWrp);
        
        eachWrp = new FilterDropDownrapperClass();
        eachWrp.UI_Value = 'All Queues';
        returnHomePageData.FilterQueue_SelectedvalueWrp.add (eachWrp);
            
        // Query on Custom Metadata to set Status,Impact & Queue Map       
        for(SC_SI_IRAPT_Homepage__mdt iteratedHomePageMetadata : [SELECT SC_SI_Type__c,SC_SI_UI_Value__c,SC_SI_Backend_Value__c,SC_SI_Sequence__c  
        															from SC_SI_IRAPT_Homepage__mdt 
        															order by SC_SI_Sequence__c asc]){
        															  
            // Condition for adding to Map
            switch on iteratedHomePageMetadata.SC_SI_Type__c {
			   when 'Status' {
			   		eachWrp = new FilterDropDownrapperClass();
					eachWrp.UI_Value = iteratedHomePageMetadata.SC_SI_UI_Value__c;
					returnHomePageData.FilterStatus_SelectedvalueWrp.add (eachWrp);
                	StatusValueMap.put(iteratedHomePageMetadata.SC_SI_UI_Value__c,iteratedHomePageMetadata.SC_SI_Backend_Value__c);
			   }
			   when 'Severity' {
				   	eachWrp = new FilterDropDownrapperClass();
					eachWrp.UI_Value = iteratedHomePageMetadata.SC_SI_UI_Value__c;
					returnHomePageData.FilterSeverity_SelectedvalueWrp.add (eachWrp);
                	SeverityValueMap.put(iteratedHomePageMetadata.SC_SI_UI_Value__c,iteratedHomePageMetadata.SC_SI_Backend_Value__c);
			   }
			   when 'Queue' {
				   	eachWrp = new FilterDropDownrapperClass();
					eachWrp.UI_Value = iteratedHomePageMetadata.SC_SI_UI_Value__c;
					returnHomePageData.FilterQueue_SelectedvalueWrp.add (eachWrp);
                	QueueValueMap.put(iteratedHomePageMetadata.SC_SI_UI_Value__c,iteratedHomePageMetadata.SC_SI_Backend_Value__c); 
			   }
			} // End of Switch
			
            
        } // End of For Loop
        
        
        // Designing the Map for each Query
        sectionName_baseQueryMap.put('IRAPT-My Open Incidents','ownerId ='+'\''+UserInfo.getUserId()+'\'' );
        sectionName_baseQueryMap.put('IRAPT-Incidents In Queue','Name != null');
        sectionName_baseQueryMap.put('IRAPT-All Open Incidents','SI_Incident_Requested_Date__c = LAST_N_DAYS:60 AND owner.name NOT IN ('+'\''+'SERVICE_INCIDENTS_QUEUE'+'\','+'\''+'ATS_IRAPT_TRANSITION_QUEUE'+'\')');
        sectionName_baseQueryMap.put('NonIRAPT-My Open Incidents','Incident_Requested_By__c ='+'\''+UserInfo.getUserId()+'\'');
        sectionName_baseQueryMap.put('NonIRAPT-Incidents In Queue','Name != null');
        sectionName_baseQueryMap.put('NonIRAPT-All Open Incidents','SI_Incident_Requested_Date__c = LAST_N_DAYS:60 AND owner.name NOT IN ('+'\''+'SERVICE_INCIDENTS_QUEUE'+'\','+'\''+'ATS_IRAPT_TRANSITION_QUEUE'+'\')');  
        
        // Calling AdditionalDataSetup Method
        AdditionalDataSetup();
    } 
    
    // Method - 3 : To set the severityName_cssClassMap, Status_Backend_UIMap 
    public static void AdditionalDataSetup(){
    
    	// Designing Map for Severity + Css Class Name
       	severityName_cssClassMap.put('Severity 1', 'slds-theme_shade slds-theme_alert-texture Sev1');
		severityName_cssClassMap.put('Severity 2', 'slds-theme_shade slds-theme_alert-texture Sev2');
		severityName_cssClassMap.put('Severity 3', 'slds-theme_shade slds-theme_alert-texture Sev3');
		severityName_cssClassMap.put('Severity 4', 'slds-theme_shade slds-theme_alert-texture Sev4'); 
		
		// Designing Map for Status Backend Value + UI Value
		Status_Backend_UIMap.put('Incident Request', 'Incident Request');
		Status_Backend_UIMap.put('1: In Progress', 'In Progress');
		Status_Backend_UIMap.put('2: Impact Mitigated', 'Impact Mitigated');
		Status_Backend_UIMap.put('3: Resolved', 'Resolved');   

    }
    
    // Method - 4 : to check if logged-in user is IRAPT User
    public static Boolean getUserDetails() {
        
        return  [Select Id ,SC_SI_IRAPT_User__c from User where Id =:UserInfo.getUserId()].SC_SI_IRAPT_User__c;
    } 
    
    // Method - 5 : Converting Wrapper Data to List
    public static void convertWrpToList(OuterwrapperClass returnHomePageData,List<string> allStatusFromWrp, List<string> allSeverityFromWrp,
    									List<string> allQueueFromWrp){
    
    	// Loop for all Status
    	for(FilterDropDownrapperClass eachStatusWrpRec : returnHomePageData.FilterStatus_SelectedvalueWrp){
    	
    		allStatusFromWrp.add(eachStatusWrpRec.UI_Value);
    	}
    	
    	// Loop for all Severity
    	for(FilterDropDownrapperClass eachStatusWrpRec : returnHomePageData.FilterSeverity_SelectedvalueWrp){
    	
    		allSeverityFromWrp.add(eachStatusWrpRec.UI_Value);
    	}
    	
    	// Loop for all Queues
    	for(FilterDropDownrapperClass eachStatusWrpRec : returnHomePageData.FilterQueue_SelectedvalueWrp){
    	
    		allQueueFromWrp.add(eachStatusWrpRec.UI_Value);
    	}
    }
    
    // Method - 6 : Generate base Query based on Loggedin user and Section
    public static string generateQuery(string isIRAPTUserValue, string SectionName, List<string> allSelectedStatus, 
    									List<string> allSelectedSeverity, List<string> allSelectedQueue) {
        
       	// Design the Base Query
        string getBaseQuery = 'Select Id,Name,Title__c,Severity__c,Status__c,Incident_Requested_By__c,Incident_Requested_By__r.Name,Owner.Name,TIM_IC__r.Name,createdDate,SI_Incident_Requested_Date__c,CreatedById,SC_SI_Age__c ' +'From SC_SI_Service_Incident__c where ' ;
        getBaseQuery += sectionName_baseQueryMap.get(isIRAPTUserValue + '-' + SectionName);
        
        // Get the Final Query
		string getFinalQuery = getFinalQuery (SectionName,getBaseQuery,allSelectedStatus,allSelectedSeverity,allSelectedQueue);
		
        
        return getFinalQuery;
    } 
    
    // Method - 7 : Design the Final Query Based on Filter
    public static string getFinalQuery(string SectionName, string baseQuery, List<string> allSelectedStatus, List<string> allSelectedSeverity, 
    									List<string> allSelectedQueue) {
		
		// If Only Transition Queue selected, do not query as it will be handled in separate Transition Query
		if(allSelectedQueue.size() == 1 && allSelectedQueue.contains('Transition Queue'))
			return null;
		  
		   
        // 1. Logic for Status Value
        baseQuery += ' AND Status__c IN (';
        if(allSelectedStatus.contains('All')){
        
        	for(string eachStatus : StatusValueMap.keyset()){
				if(SectionName == 'All Open Incidents' && eachStatus == 'Incident Request')
					continue;
					baseQuery += '\'' + StatusValueMap.get(eachStatus) + '\'' + ',';
			}		
        }
        else{
			
			for(string eachStatus : allSelectedStatus){
			
				baseQuery += '\'' + StatusValueMap.get(eachStatus) + '\'' + ',';
			}
        }
        baseQuery = baseQuery.substring(0,baseQuery.length() - 1) + ')';
        
        // 2. Logic for Severity Value
        baseQuery += ' AND Severity__c IN (Null,';
        if(allSelectedSeverity.contains('All')){
        
        	for(string eachSeverity : SeverityValueMap.keyset()){
        	
				baseQuery += '\'' + SeverityValueMap.get(eachSeverity) + '\'' + ',';
			}	
        }
        else{
			
			for(string eachSeverity : allSelectedSeverity){
			
				baseQuery += '\'' + SeverityValueMap.get(eachSeverity) + '\'' + ',';
			}
        }
        baseQuery = baseQuery.substring(0,baseQuery.length() - 1) + ')';
        
        // 3. Logic for Queue Value
        if(SectionName == 'Incidents In Queue'){
			
			baseQuery += ' AND Owner.Name IN (';
			
			if(allSelectedQueue.contains('All Queues')){
		
				for(string eachQueue : QueueValueMap.keyset()){
					
					// By passing Transition Queue
					if(eachQueue == 'Transition Queue')
						continue;
			
					baseQuery += '\'' + QueueValueMap.get(eachQueue) + '\'' + ',';
				}	
				
			}
			else{
			
				for(string eachQueue : allSelectedQueue){
			
					// By passing Transition Queue
					if(eachQueue == 'Transition Queue')
						continue;
						
					baseQuery += '\'' + QueueValueMap.get(eachQueue) + '\'' + ',';
				}
			}
			baseQuery = baseQuery.substring(0,baseQuery.length() - 1) + ')';
			
		}
       	
       	// Adding Order By Clause
       	baseQuery += (SectionName == 'All Open Incidents') ? ' order by Name asc' : ' order by Name desc';
       	baseQuery += ' limit 1000';
       	
       	// Return the Base Query
        return baseQuery;
    } 
    
    // Method - 8 : Query on SI and setup the Wrapper Data
    public static void getIncidentData(string isIRAPTUserValue, string getQuery, string SectionName, OuterwrapperClass returnHomePageData,List<string> allStatus,List<string> allSeverity, List<string> allQueue){
    	
    	// Storing all Incident Ids for querying Transition data
    	set<ID> allIncidentIds = new set<ID>();
    	IncidentWrapperClass eachSIWrpRec;
    	
    	// Query on Incident
		if(getQuery != null && getQuery != ''){
			
			for(SC_SI_Service_Incident__c eachSIRec : Database.query(getQuery)){
			
				eachSIWrpRec = new IncidentWrapperClass();
				eachSIWrpRec.Id =  eachSIRec.Id;
				eachSIWrpRec.Incident_ID =  eachSIRec.Name;
				eachSIWrpRec.Title =  eachSIRec.Title__c;
				eachSIWrpRec.Status =  Status_Backend_UIMap.get(eachSIRec.Status__c);
				eachSIWrpRec.Impact =  eachSIRec.Severity__c;			
				eachSIWrpRec.ImpactClass = severityName_cssClassMap.get(eachSIRec.Severity__c) != null ?
											severityName_cssClassMap.get(eachSIRec.Severity__c) : 'slds-theme_shade slds-theme_alert-texture';
											
				eachSIWrpRec.OwnerName = (eachSIRec.Owner.Name == 'SERVICE_INCIDENTS_QUEUE') ? 'Incident Queue' : eachSIRec.Owner.Name;
				switch on eachSIRec.Owner.Name {
					when 'SERVICE_INCIDENTS_QUEUE' {
							eachSIWrpRec.OwnerName = 'Incident Queue';
					}
					when 'ATS_IRAPT_TRANSITION_QUEUE' {
							eachSIWrpRec.OwnerName = 'Transition Queue';
					}
					when else {
							eachSIWrpRec.OwnerName = eachSIRec.Owner.Name;
					}
				}
				eachSIWrpRec.Incident_Requested_By =  eachSIRec.Incident_Requested_By__r.Name;
				eachSIWrpRec.TIM =  eachSIRec.TIM_IC__r.Name;
				eachSIWrpRec.Createddate =  eachSIRec.SI_Incident_Requested_Date__c; 
				eachSIWrpRec.CreatedDate_Text = eachSIRec.SI_Incident_Requested_Date__c.format();
				eachSIWrpRec.Age = eachSIRec.SC_SI_Age__c;
				eachSIWrpRec.hideEditAccess = (isIRAPTUserValue != 'IRAPT' && ((eachSIWrpRec.Status == 'Incident Request' && eachSIRec.Incident_Requested_By__c != UserInfo.getUserId()) || eachSIWrpRec.Status != 'Incident Request')) ? true: false;
				eachSIWrpRec.SI_recordLink = '/' + eachSIRec.Id;
				
				allIncidentIds.add(eachSIRec.ID);
				
				// Dynamically Adding to Wrapper
				switch on SectionName {
					when 'My Open Incidents' {
							returnHomePageData.incidentList_myOpenIncidents.add(eachSIWrpRec);
					}
					when 'Incidents In Queue' {
							returnHomePageData.incidentList_IncidentsInQueue.add(eachSIWrpRec);
					}
					when 'All Open Incidents' {
							returnHomePageData.incidentList_AllOpenIncidents.add(eachSIWrpRec);
					}
				} // End of Switch
			} // End of Loop
		}
    	
    	// Setting Transition Data for Section - 2
    	if(SectionName == 'Incidents In Queue' && allQueue.contains('Transition Queue')){
			

			for(SC_SI_Transition_Request__c eachTransitionRec :Database.query(getTransitionQuery(allStatus,allSeverity)) ){											
				
				eachSIWrpRec = new IncidentWrapperClass();
				eachSIWrpRec.Id =  eachTransitionRec.SC_SI_Service_Incident__c;
				eachSIWrpRec.Incident_ID =  eachTransitionRec.SC_SI_Service_Incident__r.Name;
				eachSIWrpRec.Title =  eachTransitionRec.SC_SI_Service_Incident__r.Title__c;
				eachSIWrpRec.Status =  Status_Backend_UIMap.get(eachTransitionRec.SC_SI_Service_Incident__r.Status__c);
				eachSIWrpRec.Impact =  eachTransitionRec.SC_SI_Service_Incident__r.Severity__c;
				eachSIWrpRec.ImpactClass = severityName_cssClassMap.get(eachSIWrpRec.Impact) != null ?
											severityName_cssClassMap.get(eachSIWrpRec.Impact) : 'slds-theme_shade slds-theme_alert-texture';
											
											
				eachSIWrpRec.OwnerName =  (eachTransitionRec.SC_SI_Service_Incident__r.Owner.Name == 'ATS_IRAPT_TRANSITION_QUEUE') ? 
											'Transition Queue' : eachTransitionRec.SC_SI_Service_Incident__r.Owner.Name;
				eachSIWrpRec.Incident_Requested_By =  eachTransitionRec.SC_SI_Service_Incident__r.Incident_Requested_By__r.Name;
				eachSIWrpRec.TIM =  eachTransitionRec.SC_SI_Service_Incident__r.TIM_IC__r.Name;
				eachSIWrpRec.CreatedDate_Text =  eachTransitionRec.SC_SI_Service_Incident__r.SI_Incident_Requested_Date__c.format(); 
				eachSIWrpRec.Createddate = eachTransitionRec.SC_SI_Service_Incident__r.SI_Incident_Requested_Date__c;
				eachSIWrpRec.Age = eachTransitionRec.SC_SI_Service_Incident__r.SC_SI_Age__c;
				
			
				eachSIWrpRec.isTransitionExist = true; 		
				eachSIWrpRec.transitionDescription = eachTransitionRec.SC_SI_Notes__c;
				eachSIWrpRec.suggestedBIL = (eachTransitionRec.SC_SI_Suggested_BIL__c != null) ? eachTransitionRec.SC_SI_Suggested_BIL__r.Name : 'N/A';
				//eachSIWrpRec.transitionDescription = (eachTransitionRec.SC_SI_Suggested_BIL__c != null) ? (eachSIWrpRec.transitionDescription + eachTransitionRec.SC_SI_Suggested_BIL__r.Name) : (eachSIWrpRec.transitionDescription + 'N/A');
					
				eachSIWrpRec.targetShift = eachTransitionRec.SC_SI_Target_Shift__c; 				
				eachSIWrpRec.wakeUpTime = eachTransitionRec.SC_SI_Future_Trigger_Time__c.format(); 
				eachSIWrpRec.SI_recordLink = '/' + eachTransitionRec.SC_SI_Service_Incident__c;	
				eachSIWrpRec.transitionFlagVisible = 'btn';
			
				returnHomePageData.incidentList_IncidentsInQueue.add(eachSIWrpRec);			
														
			}
    	}
    
    }
    
    // Method - 9 : Generate Transition Query
    public static string getTransitionQuery(List<string> allStatus,List<string> allSeverity){
    
    	String transitionQuery = 'Select SC_SI_Notes__c,SC_SI_Target_Shift__c,SC_SI_Future_Trigger_Time__c,SC_SI_Suggested_BIL__c,SC_SI_Suggested_BIL__r.Name,SC_SI_Service_Incident__r.Name,SC_SI_Service_Incident__r.Title__c, SC_SI_Service_Incident__r.Status__c,SC_SI_Service_Incident__r.Severity__c, SC_SI_Service_Incident__r.Owner.Name,SC_SI_Service_Incident__r.Incident_Requested_By__r.Name,SC_SI_Service_Incident__r.Incident_Requested_By__c, SC_SI_Service_Incident__r.TIM_IC__r.Name,SC_SI_Service_Incident__r.Createddate,SC_SI_Service_Incident__c,SC_SI_Service_Incident__r.SI_Incident_Requested_Date__c,SC_SI_Service_Incident__r.SC_SI_Age__c from SC_SI_Transition_Request__c where  SC_SI_Service_Incident__r.Owner.Name ='+'\'ATS_IRAPT_TRANSITION_QUEUE\''+' and SC_SI_Completed__c = false ';
		
		// 1. Logic for Status Value
		transitionQuery += ' AND SC_SI_Service_Incident__r.Status__c IN (';
		if(allStatus.contains('All')){
		
			for(string eachStatus : StatusValueMap.keyset()){
			
				transitionQuery += '\'' + StatusValueMap.get(eachStatus) + '\'' + ',';
			}	
		}
		else{
			
			for(string eachStatus : allStatus){
			
				transitionQuery += '\'' + StatusValueMap.get(eachStatus) + '\'' + ',';
			}
		}
		transitionQuery = transitionQuery.substring(0,transitionQuery.length() - 1) + ')';
		
		// 2. Logic for Severity Value
		transitionQuery += ' AND SC_SI_Service_Incident__r.Severity__c IN (Null,';
		if(allSeverity.contains('All')){
		
			for(string eachSeverity : SeverityValueMap.keyset()){
			
				transitionQuery += '\'' + SeverityValueMap.get(eachSeverity) + '\'' + ',';
			}	
		}
		else{
			
			for(string eachSeverity : allSeverity){
			
				transitionQuery += '\'' + SeverityValueMap.get(eachSeverity) + '\'' + ',';
			}
		}
		transitionQuery = transitionQuery.substring(0,transitionQuery.length() - 1) + ')';
		transitionQuery = transitionQuery+' order by SC_SI_Future_Trigger_Time__c asc';
		
		return transitionQuery;
    }
    
    // Method - 10 : Method to return Filter Data after Clicking on Filter + Refresh Button 
    @AuraEnabled
    public static string getFilterData(boolean isIRAPTUser, string SectionName, List<string> allSelectedStatus, 
    									List<string> allSelectedSeverity, List<string> allSelectedQueue){
    
    	// Instantiating Outer Wrapper - To Clear the memory for unwanted Data
        OuterwrapperClass returnHomePageData = new OuterwrapperClass();
        initialDataSetup(returnHomePageData);
        
    	// Step - 1 : Getting isIRAPT Value
        string isIRAPTUserValue = (isIRAPTUser) ? 'IRAPT' : 'NonIRAPT';
        
        // Generate Query and get Data for My Open Incident Section
        string getQuery = generateQuery(isIRAPTUserValue, SectionName,allSelectedStatus, allSelectedSeverity, allSelectedQueue);
        getIncidentData(isIRAPTUserValue,getQuery, SectionName, returnHomePageData,allSelectedStatus, allSelectedSeverity,allSelectedQueue); 
        	
        return JSON.serialize(returnHomePageData);
    }
    
    // Method - 11: For Saving the Filter
    @AuraEnabled
    public static string saveFilterData(boolean isIRAPTUser, List<string> allSelectedStatus, List<string> allSelectedSeverity, 
    									List<string> allSelectedQueue, string json_status, string json_severity,string json_queue){
		// Instantiating Outer Wrapper - To Clear the memory for unwanted Data
        OuterwrapperClass returnHomePageData = new OuterwrapperClass();
        
    	// Step - 1 : Getting isIRAPT Value
        string isIRAPTUserValue = (isIRAPTUser) ? 'IRAPT' : 'NonIRAPT';
        initialDataSetup(returnHomePageData);
        
        // Generate Query and get Data for My Open Incident Section
        string getQuery = generateQuery(isIRAPTUserValue, 'Incidents In Queue',allSelectedStatus, allSelectedSeverity, allSelectedQueue);
        getIncidentData(isIRAPTUserValue,getQuery, 'Incidents In Queue', returnHomePageData,allSelectedStatus, allSelectedSeverity,allSelectedQueue); 
        
        // Designing Store Wrapper
        StoreFilterDataWrapperClass storeWrp = new StoreFilterDataWrapperClass();
        storeWrp.Status = allSelectedStatus;
        storeWrp.Severity = allSelectedSeverity;
		storeWrp.Queue = allSelectedQueue;
		
        storeWrp.FilterStatusUI_save = (List<SC_SI_HomePageControllor.FilterDropDownrapperClass> )JSON.deserialize(
        								json_status, SC_SI_HomePageControllor.FilterDropDownrapperClass[].class);
     	storeWrp.FilterSeverityUI_save = (List<SC_SI_HomePageControllor.FilterDropDownrapperClass> )JSON.deserialize(
        								json_severity, SC_SI_HomePageControllor.FilterDropDownrapperClass[].class);
     	storeWrp.FilterQueueUI_save = (List<SC_SI_HomePageControllor.FilterDropDownrapperClass> )JSON.deserialize(
        								json_queue, SC_SI_HomePageControllor.FilterDropDownrapperClass[].class);
        
        // Upsert to Database
        SC_User_Filter__c newFilterRec = new SC_User_Filter__c();
		newFilterRec.RecordTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('IRAPT').getRecordTypeId();
		newFilterRec.Unique_ID__c = UserInfo.getUserId()+'-'+Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('IRAPT').getRecordTypeId();
		newFilterRec.Query_String__c = getQuery;
		newFilterRec.Filter_Values__c = JSON.serialize(storeWrp);
		upsert newFilterRec Unique_ID__c;
                                    
        return JSON.serialize(returnHomePageData);
	}
	
	// Method - 12 : For Retrieve the Filter Data
	@AuraEnabled
    public static void retrieveFilterData(OuterwrapperClass returnHomePageData, List<string> allStatusFromWrp, List<string> allSeverityFromWrp, 
    											List<string> allQueueFromWrp){
													
    	// To Get UniqueID for Logged In User
    	string Unique_ID = UserInfo.getUserId()+'-'+
    						Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('IRAPT').getRecordTypeId();
    	
    	// Get the Saved data
    	List<SC_User_Filter__c> filterRec = new List<SC_User_Filter__c>();
    	filterRec = [select Filter_Values__c from SC_User_Filter__c where Unique_ID__c = :Unique_ID limit 1];
    	
    	// If record exist, then Setup the List else return false
    	if(filterRec.size() == 1){
    	
    		// Deserializing 2-Level Wrapper
			SC_SI_HomePageControllor.StoreFilterDataWrapperClass cls = (SC_SI_HomePageControllor.StoreFilterDataWrapperClass )JSON.deserialize
																		(filterRec[0].Filter_Values__c, 
																		SC_SI_HomePageControllor.StoreFilterDataWrapperClass.class); 
			
			// Clear the value as default will be set in initial Data setup method
			allStatusFromWrp.clear();
			allSeverityFromWrp.clear();
			allQueueFromWrp.clear();
			returnHomePageData.FilterStatus_SelectedvalueWrp.clear();
			returnHomePageData.FilterSeverity_SelectedvalueWrp.clear();
			returnHomePageData.FilterQueue_SelectedvalueWrp.clear();		
			
			// Setting the List for Querying the Data				
			allStatusFromWrp.addAll(cls.Status);
			allSeverityFromWrp.addAll(cls.Severity);
			allQueueFromWrp.addAll(cls.Queue);
			
			// Setting the Outer Wrapper Variable to display in UI		
			returnHomePageData.FilterStatus_SelectedvalueWrp 	= 	cls.FilterStatusUI_save;
			returnHomePageData.FilterSeverity_SelectedvalueWrp 	= 	cls.FilterSeverityUI_save;
			returnHomePageData.FilterQueue_SelectedvalueWrp 	= 	cls.FilterQueueUI_save;		
														
			
		}		
    	
	}  
	
	 // Method - 13 : to update owner for assignment functionality on home page. 
	 @AuraEnabled
	 public static String updateOwner(Id incidentToAssign) {
		 
		 try{
			 SC_SI_Service_Incident__c incidentUpdate = new SC_SI_Service_Incident__c(Id = incidentToAssign,
															ownerId = UserInfo.getUserId(),
															Validation_Override__c = true);
			 update incidentUpdate;
			 return 'Success';
		 
		 }
		 catch(Exception e){
		 	return 'Error While Assigning : ' + e.getMessage();
		 } 
		
	 }
	 
	
	
   
}