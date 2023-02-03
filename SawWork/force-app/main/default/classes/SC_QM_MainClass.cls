/*=====================================================================================================+
    Class name          :   SC_QM_MainClass 
    Author              :   Supreeth,Sumukh,Himanshu
    Created             :   12-Feb-18
    Purpose             :   This is a Main class for QM Tool. It is referenced in 
                            1. SC_QM_Page - VF Page 
                            2. SC_QM_TC - Test Class for QM Functinality
                            
                            
    Last Modified Developer     			Purpose            
    ============= ========================  =======
    14-APR-18     Supreeth,Sumukh,Himanshu  Initial Development(Jira Ticket# )
+=====================================================================================================*/

public class SC_QM_MainClass {

	/* .....List of Class Variables to be used in Page .....*/
	
	// 1. For Displaying all the Cases
	public List<CaseWrapper> CasesWrapperList {get;set;}
	
	// 2. For Displaying all Service Incident Data
	public List<BMCServiceDesk__Incident__c> IncidentList {get;set;}
	
	// 3. List for All the Support Level
	public List<SupportLevelWrapper> allSupportLevels {get;set;}
	
	// 4. List for All the Queue Names
	public  List<QueueWrapper> allQueues {get;set;}
	
	// 5. List for All the Geography
	public  List<GeoWrapper> allGeography {get;set;}
	
    	// 6. Variable to get Total Case Count
    	public  Integer totalCaseCount {get;set;}
    	
    	// 7. Variable to get Total SI Count
    	public  Integer totalSICount {get;set;}
    	
    	// 8. Variable to store all Config Properties
    	public configSettingWrapper configSettingWrapperUI {get;set;}
    	
    	// 9. Map to store Filter Criteria + All UI Values (Used for Upsert Purpose)
    	public static map<string,string> filterCriteria_allLabelValuesMap = new map<string,string>();
    
    	// 10. Variable to store List of Americas geo values which not contains Americas
    	public List<string> allAmericasGeo = new List<string>();
    	
    	// 11. Variable used to Play sound or not for Missing SLA
    	public  string playSoundSLA {get;set;}
    	
      
      // Wrapper - 1 : For Case Data
	public class CaseWrapper{
        	
        	public Case eachCaseRec {get;set;}			// For Case Record
        	public boolean isTransitionCase {get;set;}	// Flag to determine Whether Transition Case or Not
        	public boolean isKONACase {get;set;}		// Flag to determine Whether Kona Case or Not
        	public boolean isSLAFlashEnabled {get;set;}	// Flag to determine whether flash to be Enabled for Case which is going 
        									// to violated
        	public string SLA {get;set;}				// Stores SLA
        	public string SLA_Color {get;set;}			// Stores SLA Color
        	public string TSE_Primary {get;set;}		// Stores Primary Technical Support from Account Team
        	public string TSE_Secondary {get;set;}		// Stores Secondary Technical Support from Account Team
        	public string TSE_Other {get;set;}			// Stores Other Technical Support from Account Team
      }
      
      // Wrapper - 2 : For Support Level
	public class SupportLevelWrapper{
	
		public string labelName {get;set;}		// Stores Support Level Name
		public string mappingValue {get;set;}	// Stores corresponding Mapping Value
		public boolean isSeleted {get;set;}		// Flag to determine whether selected by user by user or not
	}
	
	// Wrapper - 3 : For Queue
	public class QueueWrapper{
	
		public string labelName {get;set;}		// Stores Queue Name
		public string mappingValue {get;set;}	// Stores corresponding Mapping Value
		public boolean isSeleted {get;set;}		// Flag to determine whether selected by user by user or not
	}
	
	// Wrapper - 3 : For Geography
	public class GeoWrapper{
	
		public string labelName {get;set;}		// Stores Geography Name
		public string mappingValue {get;set;}	// Stores corresponding Mapping Value
		public boolean isSeleted {get;set;}		// Flag to determine whether selected by user by user or not
	}
	
	// Wrapper - 4 : For all Config Setting for QM Tool
	public class configSettingWrapper{
	
		public integer Autorefresh_Interval_SI {get;set;}		// Stores Autorefresh Time for SI Dashboard
		public integer Autorefresh_Interval_Case {get;set;}		// Stores Autorefresh Time for Case Dashboard
		public integer Autorefresh_Interval_ACD {get;set;}		// Stores Autorefresh Time for ACD Dashboard
		public string Cometd_API_Version {get;set;}			// Stores Cometd API Version
		public string Section_Header_Color {get;set;}			// Stores Section Header Color for Dashboard
		public string SLA_Green_Color {get;set;}				// Stores SLA Green Color
		public string SLA_Red_Color {get;set;}				// Stores SLA Red Color
		public string CMP_QueueId {get;set;}
		
	}
      
      // Default Constructor
      public SC_QM_MainClass(){
      	
        	// Step - 1 : Calling retrieveConfigValues Method for setting Config Values
        	retrieveConfigValues();
        	
        	// Step - 2 : For Getting Americas Geo values other than contains Americas
          if(Test.isRunningTest()){
              allAmericasGeo.add('Carrier Americas');
          }
          else
          {
             for(string eachAmericas : SC_DGRAT_Reorg_Mapping__c.getInstance().Geography_AMERICAS__c.split(',')){
		    	if(!eachAmericas.containsIgnoreCase('Americas') )
			  		allAmericasGeo.add(eachAmericas.trim());
			} 
          }
          
          	// Step - 3 : Calling Initialize Method
      	initializeUserData();
      	
      	// Call Service Incident Method to get all SI
      	getAllServiceIncidents();
      	
      	
      }
      
      // Method - 1 : for Retrieving all the Config properties values from SC_QM_CofigSetting__mdt
      public void retrieveConfigValues(){
      
      	configSettingWrapperUI = new configSettingWrapper();
      	
      	SC_QM_CofigSetting__mdt configRec = [select Id,Autorefresh_Interval_ACD__c,Autorefresh_Interval_Case__c,Autorefresh_Interval_SI__c,
      							Cometd_API_Version__c,Section_Header_Color__c,SLA_Green_Color__c,SLA_Red_Color__c,CMP_Queue_Id__c 
      							from SC_QM_CofigSetting__mdt where MasterLabel = 'SC_QM_Config' limit 1];
      	// Assigning Values
      	configSettingWrapperUI.Autorefresh_Interval_ACD 	= integer.valueOf(configRec.Autorefresh_Interval_ACD__c);
      	configSettingWrapperUI.Autorefresh_Interval_Case 	= integer.valueOf(configRec.Autorefresh_Interval_Case__c);
      	configSettingWrapperUI.Autorefresh_Interval_SI 		= integer.valueOf(configRec.Autorefresh_Interval_SI__c);
      	configSettingWrapperUI.Cometd_API_Version 		= configRec.Cometd_API_Version__c;
      	configSettingWrapperUI.Section_Header_Color 		= configRec.Section_Header_Color__c;
      	configSettingWrapperUI.SLA_Green_Color 			= configRec.SLA_Green_Color__c;
      	configSettingWrapperUI.SLA_Red_Color 			= configRec.SLA_Red_Color__c;
      	configSettingWrapperUI.CMP_QueueId				= configRec.CMP_Queue_Id__c;
      	
      }
      
      // Method - 1 : for calculating all the Support Levels
      public string getAllFilteredValues(){
      
      	// Variable to store the return Query String for Filter Support Level + Queue + Geo
      	string filteredQueryString;
      	
      	// Step -1 : Initialize all the List variables
      	allSupportLevels 	= new List<SupportLevelWrapper>();
      	allQueues 		= new List<QueueWrapper>();
      	allGeography 	= new List<GeoWrapper>();
      	
      	SupportLevelWrapper eachSLWrapperRec;
      	QueueWrapper eachQueueWrapperRec;
      	GeoWrapper eachGeoWrapperRec;
      	
      	List<string> getSupportLevel_fromMDT 	= new List<string>(); 
      	List<string> getQueue_fromMDT 		= new List<string>(); 
      	List<string> getGeography_fromMDT 	= new List<string>(); 
      	
      	// Step - 2 : Query to Get all Support Levels
      	for(SC_QM_SupportLevel_Mapping__mdt eachSupportLevel : 
      					[select MasterLabel,Mapping_Values__c,DeveloperName from SC_QM_SupportLevel_Mapping__mdt 
      					order by MasterLabel asc]) {
      		
      		eachSLWrapperRec = new SupportLevelWrapper();
      		eachSLWrapperRec.labelName = eachSupportLevel.MasterLabel;
      		eachSLWrapperRec.mappingValue = eachSupportLevel.Mapping_Values__c;
      		eachSLWrapperRec.isSeleted = true;
      		
        		allSupportLevels.add(eachSLWrapperRec);
        		
        		getSupportLevel_fromMDT.add(eachSupportLevel.Mapping_Values__c);						
      	}
      	
      	// Assigning Values to Map ()
      	filterCriteria_allLabelValuesMap.put('Support Level', string.join(getSupportLevel_fromMDT,','));

      	
      	// Step - 3 : Query to Get all Queues
      	for(SC_QM_Queue_Mapping__mdt eachQueue : [select MasterLabel,Mapping_Values__c from SC_QM_Queue_Mapping__mdt 
      								order by MasterLabel asc]) {
      		
      
        		eachQueueWrapperRec = new QueueWrapper();
      		eachQueueWrapperRec.labelName = eachQueue.MasterLabel;
      		eachQueueWrapperRec.mappingValue = eachQueue.Mapping_Values__c;
      		eachQueueWrapperRec.isSeleted = true;
      		
        		allQueues.add(eachQueueWrapperRec);
        		
        		getQueue_fromMDT.add(eachQueue.Mapping_Values__c);						
      	}
      	// Assigning Values to Map
      	filterCriteria_allLabelValuesMap.put('Queue', string.join(getQueue_fromMDT,','));
      	
      	
      	// Step - 4 : Query to Get all Geography
      	for(SC_QM_Geography_Mapping__mdt eachGeo : [select MasterLabel,DeveloperName from SC_QM_Geography_Mapping__mdt 
      									order by MasterLabel asc]) {
      		
      		eachGeoWrapperRec = new GeoWrapper();
      		eachGeoWrapperRec.labelName = eachGeo.MasterLabel;
      		eachGeoWrapperRec.mappingValue = eachGeo.DeveloperName;
      		eachGeoWrapperRec.isSeleted = true;
      		
        		allGeography.add(eachGeoWrapperRec);
        		
        		getGeography_fromMDT.add(eachGeo.DeveloperName);
        	}
      	// Assigning Values to Map
      	filterCriteria_allLabelValuesMap.put('Geo', string.join(getGeography_fromMDT,','));

		eachSLWrapperRec = new SupportLevelWrapper();
		eachQueueWrapperRec = new QueueWrapper();
		eachGeoWrapperRec = new GeoWrapper();
		     	
      	// Step - 5 : Calling Generating Query String Method 
      	filteredQueryString = generateQueryStringForFilteredValues(getSupportLevel_fromMDT, getQueue_fromMDT, getGeography_fromMDT);
      	
      	// Step - 6 : Return
      	return filteredQueryString;
      }
      
      // Method - 2 : for Generating Query String for Support Levels
      public string generateQueryStringForFilteredValues(List<string> uniqueSupportLevels,List<string> uniqueQueues,
      								List<string> uniqueGeography){
      
      	// Variable to store the return Query String for Filter Support Level + Queue + Geo
      	string filteredQueryString = 'AND (';
      	
      	// 1. Iterate Support Levels
      	for(Integer iterator = 0 ; iterator < uniqueSupportLevels.size() ; iterator++)
            {	
                if(iterator == 0)
                    filteredQueryString += ' Support_Level__c' + ' like \'%' + uniqueSupportLevels[iterator] + '%\'';
                else
                    filteredQueryString += ' OR ' + 'Support_Level__c'+ ' like \'%'+ uniqueSupportLevels[iterator]+'%\'';
            }
            
            filteredQueryString += 'OR Support_Level__c = null OR Support_Level__c = \'None\') AND (';
          
      	
      	// 2. Iterate Queues
      	filteredQueryString += ' OwnerId IN (';
      	for(Integer iterator = 0 ; iterator < uniqueQueues.size() ; iterator++)
            {	
                if(iterator == 0)
                    filteredQueryString += '  \'' + uniqueQueues[iterator] + '\'';
                else
                    filteredQueryString += ' , ' + '  \'' + uniqueQueues[iterator]+ '\'';
            }
      	filteredQueryString += ')) AND (';
      	
      	// 3. Iterate Geo
      	for(Integer iterator = 0 ; iterator < uniqueGeography.size() ; iterator++)
            {	
                if(iterator == 0)
                    filteredQueryString += ' Support_Geography__c' + ' like \'%' + uniqueGeography[iterator] + '%\'';
                else
                    filteredQueryString += ' OR ' + 'Support_Geography__c'+ ' like \'%'+ uniqueGeography[iterator]+'%\'';
            }
            
            
            // Additional Logic for America Geo
            if(uniqueGeography.contains('Americas') ){
            	
            	for(string eachAmerica : allAmericasGeo)
            		filteredQueryString += ' OR ' + 'Support_Geography__c'+ ' like \'%'+ eachAmerica +'%\'';
            }
            filteredQueryString += ')';
            return filteredQueryString;
      }
      
      
      // Method - 4 : For Getting all the Cases
      public string getAllCases (string filteredQueryString, boolean isFirstTimeUser){
      
      	// 1. List to store all the Cases
      	List<Case> allCaseList = new List<Case>();
      	
      	// 2. Map to store Account Id + Team Role - Team Member Name
      	Map<string,string> accountIdTeamRole_NameMap;
      	
      	// Step - 1 : variable to set the final Case Query
      	string finalCaseQuery = 'Select Id,description,AKAM_Case_ID__c,Account.Name,Subject,Severity__c,' + 
      					'Support_Level__c,createddate,OwnerId,Case_Assignment_Using_Active_Rules__c,Case_Prod_Name__c,' + 
      					'Support_Geography__c,Account.Division__c,AccountId,Owner.Name,Age_days__c,has_active_transition__c,' + 
      					'(select TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false) ' + 
      					'from Case where Id != null and status != \'Closed\' ';
      	
      	// Step - 2 : if Existing User, then Get the Case Query directly else design the Case Query
      	if(isFirstTimeUser == false){
      		finalCaseQuery = filteredQueryString;
      	}
      	else
      	{
      		finalCaseQuery += filteredQueryString;
      		finalCaseQuery += ' order by Severity__c ASC,createddate ASC limit 1000';
      		
      	}
      	System.debug('Case Query =' +finalCaseQuery);
      	
      	// Step - 2 : Query on Case Object
      	allCaseList = Database.query(finalCaseQuery);
          
      	System.debug('Case List =' +allCaseList);
      	// Step - 3 : Get All the Account Team Member Details
      	accountIdTeamRole_NameMap = getAccountTeamDetails(allCaseList);
      	
      	// Step - 4 : Assigning total case count
      	totalCaseCount = allCaseList.size();
      	
      	// Step - 5 : Call to CaseWrapperDesign Method
      	caseWrapperDesign(allCaseList, accountIdTeamRole_NameMap);
      	
      	allCaseList.clear();
      	accountIdTeamRole_NameMap.clear();
      	
      	return finalCaseQuery;
      }
      
      // Method - 5 : For Getting Account Team Member Details
      public Map<string,string> getAccountTeamDetails(List<Case> allCaseList){
      
      	// Map to store Account Id + Team Role - Team Member Name
      	Map<string,string> accountIdTeamRole_NameMap = new Map<string,string>();
      	
      	// set to store all Unique Account Ids
      	set<Id> uniqueAccountIds = new set<Id>();
      	
      	// String for Map Key & Value
      	string mapKey;
      	string mapValue;
      	
      	// Loop for all the Cases
      	for(case eachCaseRec : allCaseList){
      	
      		uniqueAccountIds.add(eachCaseRec.AccountId);
      	}
      	
      	// If Size > 0, then Query
      	if(uniqueAccountIds.size() > 0){
      	
			// Query On Account Team Member
			for(AccountTeamMember eachMember : [select AccountId,TeamMemberRole,User.Name from AccountTeamMember where 
									TeamMemberRole IN ('Technical Support - Primary', 'Technical Support - Secondary',
									'Technical Support - Other') and AccountId IN :uniqueAccountIds ] ){
				
				mapKey = eachMember.AccountId + '-' + eachMember.TeamMemberRole;
				
				if(accountIdTeamRole_NameMap.get(mapKey) == null){
				
					mapValue = eachMember.User.Name;	
				}
				else
				{
					mapValue = accountIdTeamRole_NameMap.get(mapKey) + ',' + eachMember.User.Name;
				}
				
				accountIdTeamRole_NameMap.put(mapKey, mapValue);						
			}
      	}
      	uniqueAccountIds.clear();
      	
      	return accountIdTeamRole_NameMap;
      }
    
    public PageReference test() {
            return null;
        }
	    		
         
      // Method - 6 : For Designing the Case Wrapper Data
      public void caseWrapperDesign(List<case> allCaseList, Map<string,string> accountIdTeamRole_NameMap){
      
      	// Variable for Individual Case Wrapper record
      	CaseWrapper eachCaseWrapperRec;
      	CasesWrapperList = new List<CaseWrapper>();
      	
      	// Assigning default value
      	playSoundSLA = 'false';
      	
      	// variable for SLA
      	string milestoneSLA;
      	
      	// Loop for all the Cases
      	for(case eachCaserec : allCaseList){
      	
      		milestoneSLA = null;
            
            // Modifying the Case Desc to escape new Line, ',"
            if (eachCaserec.Description != null){
              
                eachCaserec.Description = eachCaserec.Description.replace('\r\n', '<br/>');
                eachCaserec.Description = eachCaserec.Description.replace('\'', '\\x27');
                eachCaserec.Description = eachCaserec.Description.replace('\'\'', '\\x22');
               
            }
      		
      		// Initializing Wrapper Variable with default values
      		eachCaseWrapperRec = new CaseWrapper();
      		eachCaseWrapperRec.SLA = '';
      		eachCaseWrapperRec.SLA_Color = ' ';
      		eachCaseWrapperRec.isSLAFlashEnabled = false;
      		
      		// Assigning Case record
      		eachCaseWrapperRec.eachCaseRec = eachCaserec;
      		
      		// For transition Case
      		eachCaseWrapperRec.isTransitionCase = eachCaserec.has_active_transition__c;
      		
      		// For Bocc Case or Kona Case Case_Prod_Name__c
      		eachCaseWrapperRec.isKONACase = (eachCaserec.Case_Prod_Name__c != null && 
      							   eachCaserec.Case_Prod_Name__c.contains('Managed Kona')) ? true : false;   
      		// TSE Details
      		eachCaseWrapperRec.TSE_Primary = (accountIdTeamRole_NameMap.get(eachCaserec.AccountId+ '-' + 'Technical Support - Primary'));
      		eachCaseWrapperRec.TSE_Secondary = (accountIdTeamRole_NameMap.get(eachCaserec.AccountId+ '-' + 'Technical Support - Secondary'));
      		eachCaseWrapperRec.TSE_Other = (accountIdTeamRole_NameMap.get(eachCaserec.AccountId+ '-' + 'Technical Support - Other'));
      		
      		// Milestone Details
      		if(eachCaserec.CaseMilestones.size() > 0 && eachCaserec.CaseMilestones != Null){
      		
      			milestoneSLA = eachCaserec.CaseMilestones[0].TimeRemaininginMins;
      			calucateSLADetails(milestoneSLA, eachCaserec.CaseMilestones[0].TargetDate, eachCaseWrapperRec); 
      		}
      		
      		// Adding to Wrapper List
      		CasesWrapperList.add(eachCaseWrapperRec);
      	}
          System.debug('Case Wrapper List= '+CasesWrapperList);
      }
      
      // Method - 7 : For calculation SLA & SLA Color
      public void calucateSLADetails(string SLAValue, DateTime milestoneTargetDate , CaseWrapper eachCaseWrapperRec){
      
      	// Convert to Integer Value
		Integer getMinuteValue;
		
		if(SLAValue == '00:00'){ // Means already violated & Calculate the overdue
		
			getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - system.now().getTime()/1000/60) );
			eachCaseWrapperRec.SLA = '-'+ (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
		}
		else
		{
		 	getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
		 	eachCaseWrapperRec.SLA = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
		}
		
		// For SLA Color
		if(getMinuteValue > 10 && getMinuteValue <= 20)
			eachCaseWrapperRec.SLA_Color = configSettingWrapperUI.SLA_Green_Color; // Set Greenish yellow 
			
		else if (getMinuteValue <= 10 && getMinuteValue > 0){
		
			eachCaseWrapperRec.SLA_Color = configSettingWrapperUI.SLA_Red_Color; // Set Red 
			eachCaseWrapperRec.isSLAFlashEnabled = true; // Enable the Flash
			playSoundSLA = 'true';
		}
		else if (getMinuteValue <= 0)
			eachCaseWrapperRec.SLA_Color = configSettingWrapperUI.SLA_Red_Color; // Set Red
		
      }
      
      // Method - 8 : For Designing Service Incident Data
      public void getAllServiceIncidents(){
      
      	IncidentList = new List<BMCServiceDesk__Incident__c>();
      	
      	ID getSIRecordtypeId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
      	
       /*IncidentList=[select Id,Name,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Service_Request_Title__c,BMCServiceDesk__FKImpact__r.Name,
      			BMCServiceDesk__FKStatus__r.Name,SI_GSS_Inc_Manager_BIL__r.Name,SI_OutageStart__c 
      			from BMCServiceDesk__Incident__c order by lastmodifieddate desc LIMIT 10];*/
      		IncidentList = [select Id,Name,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Service_Request_Title__c,BMCServiceDesk__FKImpact__r.Name,
      				BMCServiceDesk__FKStatus__r.Name,SI_GSS_Inc_Manager_BIL__r.Name,SI_OutageStart__c 
      				from BMCServiceDesk__Incident__c 
      				where BMCServiceDesk__FKStatus__r.Name = 'IN PROGRESS' and 
      				recordTypeId = :getSIRecordtypeId and 
      				Createddate = LAST_N_DAYS:7
      				order by BMCServiceDesk__FKImpact__r.Name asc,lastmodifieddate desc ]; 
          
          // Changing Case for Severity and Status
          for(BMCServiceDesk__Incident__c eachSIRec : IncidentList){
              
              eachSIRec.BMCServiceDesk__FKImpact__r.Name = eachSIRec.BMCServiceDesk__FKImpact__r.Name.toLowerCase().capitalize();  
              eachSIRec.BMCServiceDesk__FKStatus__r.Name = eachSIRec.BMCServiceDesk__FKStatus__r.Name.toLowerCase().capitalize();  
          }			
      	totalSICount = IncidentList.size();
      }
      
      // Method - 9 : Check whether Logged In User is a first time or Existing
      public void initializeUserData(){
      
      	// Get the Logged In User Details
      	List<SC_QM_User_Filter__c> getUserDataFromDB = new List<SC_QM_User_Filter__c>();
      	getUserDataFromDB = [select User_Id__c,Support_Level__c,Queue__c,Geography__c,Query_String__c 
      				   from SC_QM_User_Filter__c 
      				   where User_Id__c = :UserInfo.getUserId() limit 1];
      	
      	// Variable to store the return Query String for Filter Support Level + Queue + Geo
      	string filteredQueryString;
      	
      	// Variable to get the Case Query
      	string getCaseQuery;
      	
      	// If Data is null, then its a first time user
          if(getUserDataFromDB.size() == 0||getUserDataFromDB[0].Query_String__c==null){
      	
      		// Step - 1 : Call Support Level Calculation Method
      		filteredQueryString = getAllFilteredValues();
      		
      		//system.debug('...Query string='+filteredQueryString);
      		
      		// Step - 2 : Call Case Method for retrieving all the Cases
      		getCaseQuery = getAllCases(filteredQueryString, true);
      		
      	}
      	// process Existing User
      	else
      	{
      		processExistingUserDetails(getUserDataFromDB[0]);
      	}
      		
      }
      
     // Method - 10: processing Existing User Details
      public void processExistingUserDetails(SC_QM_User_Filter__c getUserDataFromDB){
      
      	// variable to store the unique Filter values
      	List<string> uniqueSupportLevels = new List<string>(); 
      	List<string> uniqueQueues = new List<string>();
      	List<string> uniqueGeography = new List<string>();
      	
      	// Map to store Filter Value - Label Names
      	Map<string,string> filterValue_LabelMap = new Map<string,string>();
      	
      	// Step -1 : Assigning the Values
      	if(getUserDataFromDB.Support_Level__c != null)
      		uniqueSupportLevels 	= getUserDataFromDB.Support_Level__c.split(',');
      	
      	if(getUserDataFromDB.Queue__c != null)
      		uniqueQueues		= getUserDataFromDB.Queue__c.split(',');
      	
      	if(getUserDataFromDB.Geography__c != null)
      		uniqueGeography		= getUserDataFromDB.Geography__c.split(',');
      	
      	
      	
      	// Step -2 : Initialize all the List variables
      	allSupportLevels = new List<SupportLevelWrapper>();
      	allQueues = new List<QueueWrapper>();
      	allGeography = new List<GeoWrapper>();
      	
      	SupportLevelWrapper eachSLWrapperRec;
      	QueueWrapper eachQueueWrapperRec;
      	GeoWrapper eachGeoWrapperRec;
      	
      	// Step - 3 : Get all the Support Levels and Assign to Support Level UI Variable
      	for(SC_QM_SupportLevel_Mapping__mdt eachSupportLevel : 
      					[select MasterLabel,Mapping_Values__c,DeveloperName from SC_QM_SupportLevel_Mapping__mdt 
      					order by MasterLabel asc]) {
      		
        		filterValue_LabelMap.put(eachSupportLevel.Mapping_Values__c, eachSupportLevel.MasterLabel);
        								
      	}
      	
      	for(string eachSupportVal : filterValue_LabelMap.keyset()){
      	
      		eachSLWrapperRec = new SupportLevelWrapper();
      		eachSLWrapperRec.labelName = filterValue_LabelMap.get(eachSupportVal);
      		eachSLWrapperRec.mappingValue = eachSupportVal;
      		eachSLWrapperRec.isSeleted = (uniqueSupportLevels.contains(eachSupportVal)) ? true : false;
      		
      		allSupportLevels.add(eachSLWrapperRec);
      			
      	}
      	
      	filterValue_LabelMap.clear();
      	uniqueSupportLevels.clear();
      	
      	// Step - 4: Get all the Queues and Assign to Queue UI Variable
      	for(SC_QM_Queue_Mapping__mdt eachQueue : [select MasterLabel,Mapping_Values__c from SC_QM_Queue_Mapping__mdt order by MasterLabel asc]) {	
      		
        		filterValue_LabelMap.put(eachQueue.Mapping_Values__c,eachQueue.MasterLabel);	

      	}
      	
      	for(string eachQueueVal : filterValue_LabelMap.keyset()){
      	
      		eachQueueWrapperRec = new QueueWrapper();
      		eachQueueWrapperRec.labelName = filterValue_LabelMap.get(eachQueueVal);
      		eachQueueWrapperRec.mappingValue = eachQueueVal;
      		eachQueueWrapperRec.isSeleted = (uniqueQueues.contains(eachQueueVal)) ? true : false;
      		
        		allQueues.add(eachQueueWrapperRec);				
      		
      	}
      	filterValue_LabelMap.clear();
      	uniqueQueues.clear();
      	
      	// Step - 5 : Get all the Geo and Assign to Geo UI Variable
      	for(SC_QM_Geography_Mapping__mdt eachGeo : [select MasterLabel,DeveloperName from SC_QM_Geography_Mapping__mdt order by MasterLabel asc]) {
      		
			filterValue_LabelMap.put(eachGeo.DeveloperName,eachGeo.MasterLabel);
								
      	}
      	for(string eachGeoVal : filterValue_LabelMap.keyset()){
      		
      		eachGeoWrapperRec = new GeoWrapper();
      		eachGeoWrapperRec.labelName = filterValue_LabelMap.get(eachGeoVal);
      		eachGeoWrapperRec.mappingValue = eachGeoVal;
      		eachGeoWrapperRec.isSeleted = (uniqueGeography.contains(eachGeoVal)) ? true : false;
      		
        		allGeography.add(eachGeoWrapperRec);
      	}
      	filterValue_LabelMap.clear();
      	uniqueGeography.clear();
      	
      	// Step - 6 :  Call the Case Method
      	string getCaseQuery = getAllCases(getUserDataFromDB.Query_String__c, false);
      	
      }
      
     // Method - 11: Method to be invoked on clicking on "Save Filter" button from UI
      public void applyFilter(){
      	
      	String SupportLevelParam_UI 	= Apexpages.currentPage().getParameters().get('SLName');
      	String QueueParam_UI 		= Apexpages.currentPage().getParameters().get('QueueName');
      	String GeographyParam_UI 	= Apexpages.currentPage().getParameters().get('GeographyName');
      	
      	//system.debug('...param1...'+ SupportLevelParam_UI);
          	//system.debug('...param2...'+ QueueParam_UI); 
          	//system.debug('...param3...'+ GeographyParam_UI);
          
          
         
      	// variable to store the unique Filter values
      	List<string> uniqueSupportLevels = new List<string>(); 
      	List<string> uniqueQueues = new List<string>();
      	List<string> uniqueGeography = new List<string>();
      	
      	// Step - 3 : Designing the Map
      	filterCriteria_allLabelValuesMap.clear();
      	
      	
      	// Step - 1 : Logic for Deriving Support Levels
      	if(SupportLevelParam_UI != null && SupportLevelParam_UI != ''){
      	
      		SupportLevelParam_UI = SupportLevelParam_UI.substring(1,SupportLevelParam_UI.length());
      		uniqueSupportLevels = SupportLevelParam_UI.split(',');
      		filterCriteria_allLabelValuesMap.put('Support Level', string.join(uniqueSupportLevels,','));
      	}
      	else
      	{
      		for(SC_QM_SupportLevel_Mapping__mdt eachSupportLevel : 
      					[select Mapping_Values__c,DeveloperName from SC_QM_SupportLevel_Mapping__mdt 
      					order by DeveloperName desc]) {
      		
        			uniqueSupportLevels.add(eachSupportLevel.Mapping_Values__c);
        								
      		}
      		filterCriteria_allLabelValuesMap.put('Support Level', '');
      		
      	}
      	
      	// Step - 2 : Logic for Deriving Queues
      	if(QueueParam_UI != null && QueueParam_UI != ''){
      	
      		QueueParam_UI = QueueParam_UI.substring(1,QueueParam_UI.length());
      		uniqueQueues = QueueParam_UI.split(',');
      		filterCriteria_allLabelValuesMap.put('Queue', string.join(uniqueQueues,','));
      	}
      	else
      	{
      		for(SC_QM_Queue_Mapping__mdt eachQueue : [select Mapping_Values__c from SC_QM_Queue_Mapping__mdt]) {	
      		
        			uniqueQueues.add(eachQueue.Mapping_Values__c);	

      		}
      		filterCriteria_allLabelValuesMap.put('Queue', '');
      	}
      	
		// Step - 3 : Logic for Deriving Geo
      	if(GeographyParam_UI != null && GeographyParam_UI != ''){
      	
      		GeographyParam_UI = GeographyParam_UI.substring(1,GeographyParam_UI.length());
      		uniqueGeography = GeographyParam_UI.split(',');
      		filterCriteria_allLabelValuesMap.put('Geo', string.join(uniqueGeography,','));
      	}
      	else
      	{
      		for(SC_QM_Geography_Mapping__mdt eachGeo : [select DeveloperName from SC_QM_Geography_Mapping__mdt]) {
      		
				uniqueGeography.add(eachGeo.DeveloperName);
								
      		}
      		filterCriteria_allLabelValuesMap.put('Geo', '');
      	}
      	
      	//system.debug('...1...'+ uniqueSupportLevels);
      	//system.debug('...2...'+ uniqueQueues);
      	//system.debug('...3...'+ uniqueGeography);
      	
      	// Step - 1 : string to get Query Filter Conditions
      	string filteredQueryString = generateQueryStringForFilteredValues(uniqueSupportLevels,uniqueQueues,uniqueGeography);
      												
      	// Step - 2 : Variable to get the Case Query
      	string getCaseQuery = getAllCases(filteredQueryString, true);
      	
	
      	// Step - 4 : Upsert to Database
      	upsertUserDetails(getCaseQuery, UserInfo.getUserId());
      	
  
      }
      
      // Method - 12 : Method for Upserting to SC_QM_User_Filter__c
      public void upsertUserDetails(string getCaseQuery, string getUserId){
      
      	SC_QM_User_Filter__c upsertUserData = new SC_QM_User_Filter__c();
      	upsertUserData.User_Id__c		= getUserId;
      	upsertUserData.Support_Level__c	= filterCriteria_allLabelValuesMap.get('Support Level');
      	upsertUserData.Queue__c			= filterCriteria_allLabelValuesMap.get('Queue');
      	upsertUserData.Geography__c		= filterCriteria_allLabelValuesMap.get('Geo');
      	upsertUserData.Query_String__c	= getCaseQuery;
      	
      	try{
      		upsert upsertUserData User_Id__c;	
      	}catch(exception e){}
      }
      
      // Method - 13: Method to be invoked on clicking on "Reset" button from UI
      public Pagereference resetAllFilter(){
      	
      	// Step - 1 : deleting the Existing Entry for the Current User
      	delete [select Id from SC_QM_User_Filter__c where User_Id__c = :UserInfo.getUserId()];
      	
      	// Step - 2 : Call initializeUserData Method
      	initializeUserData();
      	
      	return null;
      }
      
      // Method - 14: Method to be invoked on clicking on "refresh" button from UI
      public Pagereference refreshPage(){
      
          	initializeUserData();
      	
      	return null;
      }
     
}