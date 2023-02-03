/***************************************************************************
 * Name             : ACD2_AccountTeam_ProductERC_WS
 * Created By       : Himanshu Kar
 * Created Date     : 07-Jul-2020
 * Purpose          : return List Of Agents for corresponding ERC / Product.
 * Test Class		: ACD2_Webservices_Test
 
 Last Modified BY   Last Modified Date  Purpose
 ----------------   ------------------  ---------
 Himanshu		    07-Jul-2020			Initial Development
 ****************************************************************************
 
Input Parameters : CallGUID (string), ERC NUmber, Product Name  

Use Cases:
----------
1. ERC NUmber = null & ProductName != null  - return false 
	(/services/apexrest/ACD2_AccountTeam_ProductERC_WS?ERC_Number=&ProductName=Media)
	
2. ERC NUmber != null & ProductName = null  - return List of Agents   
	(/services/apexrest/ACD2_AccountTeam_ProductERC_WS?ERC_Number=1234&ProductName=)
	
3. ERC NUmber = null & ProductName = null - return false  
	(/services/apexrest/ACD2_AccountTeam_ProductERC_WS?ERC_Number=&ProductName=)
	
4. ERC NUmber != null & ProductName != null - return List of Agents 
	(/services/apexrest/ACD2_AccountTeam_ProductERC_WS?ERC_Number=1234&ProductName=Media)
	
5. ERC NUmber = 98765 & ProductName = Media - return false as ERC does not Exist
	(/services/apexrest/ACD2_AccountTeam_ProductERC_WS?ERC_Number=98765&ProductName=Media)
	
6. ERC NUmber = 223 & ProductName = Media1 - return List of Agents not by priority as product does not exist
	(/services/apexrest/ACD2_AccountTeam_ProductERC_WS?ERC_Number=1234&ProductName=Media1)		
	

*/ 

@RestResource(urlMapping='/ACD2_AccountTeam_ProductERC_WS/*')
global class ACD2_AccountTeam_ProductERC_WS 
{
    
    // Wrapper structure to be returned to TTEC
    global class ACD2_AccountTeam_ProductERC_Wrapper
    { 
		List<string> allAgentDetails;
        
        // Initializing with default value
        global ACD2_AccountTeam_ProductERC_Wrapper()
        {
            
            allAgentDetails		= new List<string>(); 
        }
    }
    
    @HttpGet
    global static ACD2_AccountTeam_ProductERC_Wrapper getAgentDetailsFromProduct() 
    {
        
        // Step - 1 : Getting Input Parameter
        Datetime requestReceivedTime = DateTime.now();
        RestRequest req = RestContext.request;
        String getERCNumber = req.params.get('ERC_Number').trim();
        String getProductName = req.params.get('ProductName').trim();
        String callGUID = req.params.get('CallGUID').trim();
        String input = '1. ERC : ' + getERCNumber + ' , Product Name :' + getProductName;	
        
        // Step - 2 : Map to store mapping of Input Product vs Actual ProductName
        //Map<string,string> inputProd_ActualProdmap = new map<string,string>{'Media' => 'AkaTec - Media', 'Enterprise' => 'AkaTec - Enterprise',
                                                                               // 'Web Experience' => 'AkaTec - Web Experience'};
        // Step - 3 : Initialize the wrapper & Required variable Initialization
        ACD2_AccountTeam_ProductERC_Wrapper returnWrp = new ACD2_AccountTeam_ProductERC_Wrapper();
        string getActualProdname;
        List<string> allAgentDetails = new List<string>();
        
        // Step - 4 : If ERC is null, then return false
        if(!String.isBlank(getERCNumber))
        {        	
            try
            {     
                    // Step - 5 : Getting Actual Product Name
                    //getActualProdname = inputProd_ActualProdmap.get(getProductName);
                    
                    // Step - 6 : Calling Method to get List of Agents and then return
                    allAgentDetails = getSupportTeamFromERC(getERCNumber,getProductName);
                    returnWrp.allAgentDetails.addAll(allAgentDetails);  
            }
            catch(Exception e)
            {
                ACD2_UtilClass.createLog(callGUID,'ACD2_AccountTeam_ProductERC_WS', input ,' Error Message: ' +e.getMessage()+ ' StackTrace: ' + e.getStackTraceString(),'Exception',requestReceivedTime );
                ACD2_UtilClass.sendErrorMail(input, e.getMessage(),e.getStackTraceString(),'ACD 2.0 Exception in - ACD2_AccountTeam_ProductERC_WS');
                return returnWrp;        
            }
            
        }
        
            
        ACD2_UtilClass.createLog(callGUID,'ACD2_AccountTeam_ProductERC_WS', input ,JSON.serialize(returnWrp),'Valid',requestReceivedTime);  

		return returnWrp;        
    }
    
    // Method for getting All Agent Names
    private static List<string> getSupportTeamFromERC (string inputERC, string ProdName){
    
    	// Map to Store Priority No + Agent List
    	//1- TSP + Product Match, 1- TSS + Product Match,3- TSO + Product Match,4- TSP + not Product Match,5- TSP + not Product Match,
    	//6- TSP + not Product Match,
    	Map<Integer, List<string>> priorityNo_agentListMap = new Map<Integer, List<string>>{
            												1 => new List<string>(), 2 => new List<string>(),
    														3 => new List<string>(), 4 => new List<string>(),
    														5 => new List<string>(), 6 => new List<string>()};
    	// Variable to return 
    	List<string> allAgentDetailsReturn = new List<string>();
    	
    	List<string> allAgentDetails = new List<string>();
    	List<TS_TeamMember__c> allTeamMembers = new List<TS_TeamMember__c>();
    	
    	// Loop to get all Team Members
    	allTeamMembers = [SELECT Team_Member__r.Alias,Role__c,Team_Member__r.ACD2_Support_Team_Skill__c  
    										FROM TS_TeamMember__c 
    										WHERE TS_Support_Team__c IN (SELECT TS_Support_Team__c FROM TS_TeamAccount__c WHERE 
    																	Team_Account__r.ERC_Numeric__c = :inputERC) 
                                            AND Team_Member__r.isActive = True 
                                            AND Team_Member__r.ACD2_Support_Team_Skill__c  != null 
                                            ORDER BY ACD2_Support_Order__c ];
    	
    	// If Product = null, just Add to List, Else do the prioritization	
		if(ProdName == null && allTeamMembers.size() > 0){
			
			for(TS_TeamMember__c eachMember : allTeamMembers){
				
				allAgentDetails.add(eachMember.Team_Member__r.Alias);
			}
		}
		else{
		
			for(TS_TeamMember__c eachMember : allTeamMembers){
				System.debug('--eachMember--'+eachMember.Team_Member__r.ACD2_Support_Team_Skill__c);
				allAgentDetails = new List<string>();
				
				// Priority - 1
				if(eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.contains(ProdName) && eachMember.Role__c == 'Technical Support - Primary'){
					allAgentDetails = priorityNo_agentListMap.get(1);
                    allAgentDetails.add(eachMember.Team_Member__r.Alias);
                    priorityNo_agentListMap.put(1, allAgentDetails);
				}
                // Priority - 2
				else if(eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.contains(ProdName) && eachMember.Role__c == 'Technical Support - Secondary'){
					allAgentDetails = priorityNo_agentListMap.get(2);
                    allAgentDetails.add(eachMember.Team_Member__r.Alias);
                    priorityNo_agentListMap.put(2, allAgentDetails);
				}
                // Priority - 3
				else if(eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.contains(ProdName) && eachMember.Role__c == 'Technical Support - Other'){
					allAgentDetails = priorityNo_agentListMap.get(3);
                    allAgentDetails.add(eachMember.Team_Member__r.Alias);
                    priorityNo_agentListMap.put(3, allAgentDetails);
				}
                // Priority - 4
				else if((!eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.contains(ProdName)) && eachMember.Role__c == 'Technical Support - Primary'){
					allAgentDetails = priorityNo_agentListMap.get(4);
                    allAgentDetails.add(eachMember.Team_Member__r.Alias);
                    priorityNo_agentListMap.put(4, allAgentDetails);
				}
                // Priority - 5
				else if((!eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.contains(ProdName)) && eachMember.Role__c == 'Technical Support - Secondary'){
					allAgentDetails = priorityNo_agentListMap.get(5);
                    allAgentDetails.add(eachMember.Team_Member__r.Alias);
                    priorityNo_agentListMap.put(5, allAgentDetails);
				}
                // Priority - 6
				else if((!eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.contains(ProdName)) && eachMember.Role__c == 'Technical Support - Other'){
					allAgentDetails = priorityNo_agentListMap.get(6);
                    allAgentDetails.add(eachMember.Team_Member__r.Alias);
                    priorityNo_agentListMap.put(6, allAgentDetails);
				}
			}
            
            allAgentDetails = new List<string>();
            
            // 2nd Loop for adding All Members to Agent List
            for(Integer mapKey : priorityNo_agentListMap.keyset()){
                //system.debug('mapKey: ' + mapKey + 'priorityNo_agentListMap: ' + priorityNo_agentListMap.get(mapKey));
                allAgentDetails.addALL(priorityNo_agentListMap.get(mapKey)); 
            }
            
		}
        //system.debug('allAgentDetails: ' + allAgentDetails);
        // Calling retun10Agents Method
        retun10Agents(allAgentDetails, allAgentDetailsReturn);
        
        // Finally Adding to Main return List for limiting to 10
        return allAgentDetailsReturn;
    } 
    
    // Method for removing Duplicate Agent Name and return max 10 Agent Names
    private static void retun10Agents( List<string> allAgentDetails, List<string> allAgentDetailsReturn) {
    	
        // List to store all the Unique Agent name as per Priority. Do not use set as it will sort asc
        List<string> allUniqueAgents = new List<string>();
        
        // Loop for adding Unique Values
        for(string eachAgentName : allAgentDetails){
            
            if(!allUniqueAgents.contains(eachAgentName))
                allUniqueAgents.add(eachAgentName);
        }
        
        // Limiting to 10 Agents 
    	if(allUniqueAgents.size() > 10){
    	
    		// LImiting to 10 Agents for return
            for(integer i=0; i < 9 ; i++)
            	allAgentDetailsReturn.add(allUniqueAgents[i]);
    	}
        else{
         	allAgentDetailsReturn.addAll(allUniqueAgents);   
        }
    }
}