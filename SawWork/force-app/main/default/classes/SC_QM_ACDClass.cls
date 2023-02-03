/*=====================================================================================================+
    Class name          :   SC_QM_ACDClass 
    Author              :   Supreeth,Sumukh,Himanshu
    Created             :   12-Feb-18
    Purpose             :   This class is used for processing ACD data from APIs for QM Tool. It is referenced in 
                            1. SC_QM_Page - VF Page 
                            2. SC_QM_TC - Test Class for QM Functinality
                            
                            
    Last Modified Developer     			Purpose            
    ============= ========================  =======
    14-APR-18     Supreeth,Sumukh,Himanshu  Initial Development(Jira Ticket# )
+=====================================================================================================*/
public class SC_QM_ACDClass {
    	
    	// 1. Variable for Summarize Agent Info
	public Agent_SummaryWrapperFromAPI_1 agent_SummaryRec{get;set;}
	
	//2. Variable for displaying all Agent Data
	public List<FinalAgentWrapperData> allAgentCombineData {get;set;}
    
    // Constructor for Extension class of VF Page
    public SC_QM_ACDClass(SC_QM_MainClass act){
        
    }
    
    // Default Constructor
    public SC_QM_ACDClass(){}
	
    	// Wrapper -1 : For All Agent Data from API-1(https://tools.bos01.corp.akamai.com/api/acd/report/skill/661)
	public class AgentWrapperFromAPI_1 {
	    
	    public String Login_ID; 			// Mapping Field From JSON = Login ID
	    public String Extn;				// Mapping Field From JSON = Extn
	    public String State;			// Mapping Field From JSON = State
	    public String Split_Skill;		// Mapping Field From JSON = Split/Skill
	    public String Time_sinceLoggedIn;	// Mapping Field From JSON = Login ID
	    public String Agent_Name;			// Mapping Field From JSON = Agent Name
	    
	    // Default Constructor
	    public AgentWrapperFromAPI_1(){}
	}
	
	// Wrapper -2 : For Agent Summary Data from API-1(https://tools.bos01.corp.akamai.com/api/acd/report/skill/661)
	public class Agent_SummaryWrapperFromAPI_1 {
	    
	    public String Staffed{get;set;} 		// Mapping Field From JSON = Staffed
	    public String Available{get;set;}		// Mapping Field From JSON = Available
	    public String Ringing{get;set;}		// Mapping Field From JSON = Ringing
	    public String ACD_Calls{get;set;}		// Mapping Field From JSON = ACD Calls
	    public String ACW{get;set;}			// Mapping Field From JSON = ACW
	    public String AUX_Work{get;set;}		// Mapping Field From JSON = AUX Work
	    public String Other{get;set;}		// Mapping Field From JSON = Other
	    
	    // Default Constructor
	    public Agent_SummaryWrapperFromAPI_1(){}
	}
	
	// Wrapper -3 : For All Agent Data from API-2(https://tools.bos01.corp.akamai.com/api/acd/agent/)
	public class AgentWrapperFromAPI_2 {
	    
	    public String acdg_type; 			// Mapping Field From JSON = acdg_type(UI : Type)
	    public String acdg_type2;			// Mapping Field From JSON = acdg_type2 (UI : Support Type)
	    public String acdg_label;			// Mapping Field From JSON = acdg_label (UI : Shift)
	    public String acda_ldap_id;		// Mapping Field From JSON = acda_ldap_id
	    public String acda_acd_login_id;	// Mapping Field From JSON = acda_acd_login_id
	    public String acda_first_name;		// Mapping Field From JSON = acda_first_name
	    public String acda_last_name;		// Mapping Field From JSON = acda_last_name
	    
	    // Default Constructor
	    public AgentWrapperFromAPI_2(){}
	}
	
	// Wrapper -4 : Combine All Agent Data from API-1 + API-2
	public class FinalAgentWrapperData {
	
	    public String Name{get;set;} // First Name + Last Name
	    public String Ldap_id{get;set;}
	    public String Login_ID{get;set;}
	    public String Extension{get;set;}
	    public String State{get;set;}
	    public String Skill{get;set;}
	    public String Time_sinceLoggedIn{get;set;}
	    public String Type{get;set;}
	    public String Support_Type{get;set;}
	    public String Shift{get;set;}
	    public String State_Color{get;set;}
	    
	}
	
	// Method -1 : Main Method to be invoked from VF Page
	public void getDatainApexForAPI_Main(){
		
		// List to store all Agent Wrapper Data from API-1 + API-2 + API-3
	    	AgentWrapperFromAPI_1[] allAgentInfo_1 = new List<AgentWrapperFromAPI_1>();
	    	AgentWrapperFromAPI_2[] allAgentInfo_2 = new List<AgentWrapperFromAPI_2>();
	    	
	    	// Get the ACD Data from API-1 + API-2 + API-3
			String ACDDataFromAPI_1 = Apexpages.currentPage().getParameters().get('getACD_API_1_Data');
        	String ACDDataFromAPI_2 = Apexpages.currentPage().getParameters().get('getACD_API_2_Data');
        	
        try{
        
        	// Call the Methods for JSON Parsing (API-1 + API-2 )
        	allAgentInfo_1 = getDatainApexForAPI_1(ACDDataFromAPI_1);
        	allAgentInfo_2 = getDatainApexForAPI_2(ACDDataFromAPI_2);
        	
        	// Deallocate the memory
        	ACDDataFromAPI_1 = null;
        	ACDDataFromAPI_2 = null;
        	
        	// Call the Merge Method for merging API-1 + API-2 data
        	mergeAgentData(allAgentInfo_1, allAgentInfo_2);
        }catch(Exception e){
       	}
        	//system.debug('....1....'+ agent_SummaryRec);
        	//system.debug('....2....'+ allAgentCombineData);
        	
	}
	
	// Method -2 : Method for Parsing data from API-1
    	public AgentWrapperFromAPI_1[] getDatainApexForAPI_1(String ACDDataFromAPI_1){
		
        	 // Calling parseAgentSummaryData method
        	 parseAgentSummaryData(ACDDataFromAPI_1.substring(0,ACDDataFromAPI_1.indexOf('\"agents')-1));
        	 
        	 // Substring to get only Agent Data
        	 ACDDataFromAPI_1 = '{' + ACDDataFromAPI_1.substring(ACDDataFromAPI_1.indexOf('\"agents'));
        	
        	// Create a JSON Parser for parsing
	    	JSONParser parser = JSON.createParser(ACDDataFromAPI_1);
	    	
	    	// List to store all Agent Wrapper Data
	    	AgentWrapperFromAPI_1[] allAgentInfo = new List<AgentWrapperFromAPI_1>();
	    	AgentWrapperFromAPI_1 eachAgentInfo;
            
            // Main Loop for Parsing
	    	while (parser.nextToken() != null) {
	  
		  // Start at the array 
		  if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
		
			// Loop for Each Agent Record
			while (parser.nextToken() != null) {
		    
			    //  For Start of the Record
			    if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
				  
				  // Initialize the eachAgentInfo variable	
				  eachAgentInfo = new AgentWrapperFromAPI_1();
				  
				  // Loop to iterate each Token for a Agent Record
				  while (parser.nextToken() != JSONToken.END_OBJECT) {
				  	
				  	// Field-1 : If Current Token = Agent Name, then Assign
				  	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Agent Name')) {
				  
				  		// Get the value.
                				parser.nextToken();
                        		eachAgentInfo.Agent_Name = parser.getText();
				  	}
				  	
				  	// Field-2 : If Current Token = Login Id, then Assign
				  	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Login ID')) {
				  
				  		// Get the value.
                				parser.nextToken();
                        		eachAgentInfo.Login_ID = parser.getText();
				  	}
				  	
				  	// Field-3 : If Current Token = Extn, then Assign
				  	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Extn')) {
				  
				  		// Get the value.
                				parser.nextToken();
                        		eachAgentInfo.Extn = parser.getText();
				  	}
				  	
				  	// Field-4 : If Current Token = State, then Assign
				  	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'State')) {
				  
				  		// Get the value.
                				parser.nextToken();
                        		eachAgentInfo.State = parser.getText();
				  	}
				  	
				  	
				  	// Field-5 : If Current Token = Split/Skill, then Assign
				  	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Split/Skill')) {
				  
				  		// Get the value.
                				parser.nextToken();
                        		eachAgentInfo.Split_Skill = parser.getText();
				  	}
				  	
				  	// Field-6 : If Current Token = Time, then Assign
				  	if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Time')) {
				  
				  		// Get the value.
                				parser.nextToken();
                        		eachAgentInfo.Time_sinceLoggedIn = parser.getText();
				  	}	
				  	
				  }	// End of While - End Obj for Each Token of Agent Record
				  
				  // Adding to Final List
				  allAgentInfo.add(eachAgentInfo);
				  
			    } // End of IF - Start Obj
			} // End of While - End Obj for Each Agent Record
		  } // End of IF - Start of Array
	    } // End Main loop 
	    
        //system.debug('Size of Agent List: ' + allAgentInfo.size());
        
        return allAgentInfo;
	}
	
	// Method -3 : Method for Parsing Summary data from API-1
	public void parseAgentSummaryData(string inputJson){
		
		// Truncating the Input
         	inputJson = '{'+inputJson.substring(inputJson.indexOf('\"Agents'), inputJson.indexOf('\"Calls Wa')-1)+'}';
		
		// Initializing the Wrapper Variable
		agent_SummaryRec = new Agent_SummaryWrapperFromAPI_1();
		
		// Create a JSON Parser for parsing
	    	JSONParser parser = JSON.createParser(inputJson);
	    	
	    	// Loop for Each Agent Record
		while (parser.nextToken() != null) {
		
			// Field-1 : If Current Token = Staffed, then Assign
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Staffed')) {
		  
				// Get the value.
				parser.nextToken();
				agent_SummaryRec.Staffed = parser.getText();
			}
			
			// Field-2 : If Current Token = Available, then Assign
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Available')) {
		  
				// Get the value.
				parser.nextToken();
				agent_SummaryRec.Available = parser.getText();
			}
			
			// Field-3 : If Current Token = Ringing, then Assign
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Ringing')) {
		  
				// Get the value.
				parser.nextToken();
				agent_SummaryRec.Ringing = parser.getText();
			}
			
			// Field-4 : If Current Token = ACD Calls, then Assign
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'ACD Calls')) {
		  
				// Get the value.
				parser.nextToken();
				agent_SummaryRec.ACD_Calls = parser.getText();
			}
			
			// Field-5 : If Current Token = ACW, then Assign
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'ACW')) {
		  
				// Get the value.
				parser.nextToken();
				agent_SummaryRec.ACW = parser.getText();
			}
			
			// Field-6 : If Current Token = AUX Work, then Assign
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'AUX Work')) {
		  
				// Get the value.
				parser.nextToken();
				agent_SummaryRec.AUX_Work = parser.getText();
			}
			
			// Field-7 : If Current Token = Other, then Assign
			if ((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'Other')) {
		  
				// Get the value.
				parser.nextToken();
				agent_SummaryRec.Other = parser.getText();
			}
		}
		
	}
	
	// Method -4 : Method for Parsing data from API-2
	public AgentWrapperFromAPI_2[] getDatainApexForAPI_2(String ACDDataFromAPI_2){
	
		// Parse entire JSON response.
    		JSONParser parser = JSON.createParser(ACDDataFromAPI_2);
    		
    		// List to store all Agent Wrapper Data
	    	AgentWrapperFromAPI_2[] allAgentInfo = new List<AgentWrapperFromAPI_2>();
	    	AgentWrapperFromAPI_2 eachAgentInfo;
	    	
    		while (parser.nextToken() != null) {
        
        		// Start at the array of invoices.
        		if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
            
            		while (parser.nextToken() != null) {
            		
            			if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
            			
            				eachAgentInfo = (AgentWrapperFromAPI_2)parser.readValueAs(AgentWrapperFromAPI_2.class);
            				allAgentInfo.add(eachAgentInfo);
            			} 
            		
            		} // End of Each Obj
            	}
            } // End of Main Loop
      	//System.debug('....Values are2 ..' + allAgentInfo.size() + '...'+ allAgentInfo);
      	return allAgentInfo;
	}
	
	
	// Method -5 : Merging data to Final Wrapper
	public void mergeAgentData(AgentWrapperFromAPI_1[] allAgentInfo_1, AgentWrapperFromAPI_2[] allAgentInfo_2 ){
	
		// Map to store Agent Login Id + other Info from API-1
		Map<string, AgentWrapperFromAPI_1> agentAPI_1_map = new Map<string, AgentWrapperFromAPI_1>();
		
		// Map to store Agent Login Id + other Info from API-2
		Map<string, AgentWrapperFromAPI_2> agentAPI_2_map = new Map<string, AgentWrapperFromAPI_2>();
		
		// Loop for API-1 data
		for(AgentWrapperFromAPI_1 eachAgentData : allAgentInfo_1){
		
			agentAPI_1_map.put(eachAgentData.Login_ID, eachAgentData);
		}
		
		// Loop for API-2 data
		for(AgentWrapperFromAPI_2 eachAgentData : allAgentInfo_2){
		
			agentAPI_2_map.put(eachAgentData.acda_acd_login_id, eachAgentData);
		}
		
		// Deallocating memory
		allAgentInfo_1 = null;
		allAgentInfo_2 = null;
		
		// Initializing Final Wrapper
		allAgentCombineData = new List<FinalAgentWrapperData>();
		FinalAgentWrapperData eachAgentData;
		
		// Loop for Combining the result
		for(string eachAgentLoginId : agentAPI_1_map.keyset()){
		
			eachAgentData = new FinalAgentWrapperData();
				
				// Get the Details from API-1
				eachAgentData.Login_ID 			= eachAgentLoginId;
				eachAgentData.Extension 		= agentAPI_1_map.get(eachAgentLoginId).Extn;
				eachAgentData.State 			= agentAPI_1_map.get(eachAgentLoginId).State;
				eachAgentData.Skill 			= agentAPI_1_map.get(eachAgentLoginId).Split_Skill;
				eachAgentData.Time_sinceLoggedIn 	= agentAPI_1_map.get(eachAgentLoginId).Time_sinceLoggedIn;
				eachAgentData.Name 			= agentAPI_1_map.get(eachAgentLoginId).Agent_Name;
				
				// Getting Additional Details from API-2
				if(agentAPI_2_map.get(eachAgentLoginId) != null){
					
					eachAgentData.Name 			= 	agentAPI_2_map.get(eachAgentLoginId).acda_first_name + ' ' +
												agentAPI_2_map.get(eachAgentLoginId).acda_last_name;
					eachAgentData.Ldap_id 			= agentAPI_2_map.get(eachAgentLoginId).acda_ldap_id;
					eachAgentData.Type 			= agentAPI_2_map.get(eachAgentLoginId).acdg_type;
					eachAgentData.Support_Type 		= agentAPI_2_map.get(eachAgentLoginId).acdg_type2;
					eachAgentData.Shift 			= agentAPI_2_map.get(eachAgentLoginId).acdg_label;
	
				}
				
				
				// Logic for State Color
				if(eachAgentData.State == 'AVAIL')
					eachAgentData.State_Color = '#4bca81';
				else if(eachAgentData.State == 'AUX')
					eachAgentData.State_Color = '#ff7f7f';
				else
					eachAgentData.State_Color = ' ';
			
				allAgentCombineData.add(eachAgentData);
			
		}
		
	}
    
    public void DisplayError(){
        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please Connect to VPN to get ACD Data'));
       	
        
        
    }
}