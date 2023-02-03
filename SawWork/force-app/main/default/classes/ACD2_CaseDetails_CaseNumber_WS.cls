/***************************************************************************
* Name 			: ACD2_CaseDetails_CaseNumber_WS
* Created By 	: Vamsee S
* Created Date 	: 07-Feb-2020
* Purpose 		: Case Details Webservice.
* Test Class	: ACD2_Webservices_Test
---------------------------------------------------
Last Modified BY 	Last Modified Date 		Purpose
---------------------------------------------------
Vamsee S 			07-Feb-2020 			Initial Development
****************************************************************************

Input Parameters 	: CallGUID (string), CaseNumber
Output Parameters	: isCaseFound(String), OwnerId(String), allAgentIds(List of Strings)

Use Cases:
----------

1. CaseNumber -> 3874182 -> Case Found, Owner is an User, Account (With Support team) on Case is not blank
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=3874182)

2. CaseNumber -> 3874183 -> Case Found, Owner is a Queue, Account (With Support team) on Case is not blank
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=3874183)

3. CaseNumber -> 3874179 -> Case Found, Owner is an User, Account (Without Support Team) on Case is not blank
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=3874179)

4. CaseNumber -> 3874181 -> Case Found, Owner is a Queue, Account (Without Support Team) on Case is not blank
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=3874181)

5. CaseNumber -> 4567890 - No Case Found
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=4567890)

6. Casenumber -> ''
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=)

7. CaseNumber -> 3874177 -> Case Found, Owner is a Queue, Account on Case is blank
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=3874177)

8. CaseNumber -> 3874178 -> Case Found, Owner is an User, Account on Case is blank
(/services/apexrest/ACD2_CaseDetails_CaseNumber_WS?CaseNumber=3874178)

*/

@RestResource(urlMapping='/ACD2_CaseDetails_CaseNumber_WS/*')
Global class ACD2_CaseDetails_CaseNumber_WS {
    
    // Wrapper structure to be returned to Cisco
	global class CaseDetailsResponseWrapper{
		String isCaseFound;// true if found: false otherwise
		String OwnerId; //Case Owner if found: null otherwise 
		List<String> allAgentIds; // Technical Primary, Secondary and Others
        //default value is false
        global CaseDetailsResponseWrapper(){
            isCaseFound = 'false';
            OwnerId = null;    
            allAgentIds = new List<String>();
        }
	}
    
    @HttpGet
    global static CaseDetailsResponseWrapper getListOutput() {
        
        RestRequest req = RestContext.request;
        Datetime requestReceivedTime = DateTime.now();
        
        String inparam = req.params.get('CaseNumber');
        String callGUID = req.params.get('CallGUID');
		
        CaseDetailsResponseWrapper responseObject = new CaseDetailsResponseWrapper();        
        
        if(!String.isBlank(inparam)){
            Try
            {
                inparam = inparam.trim();
                
                String AKAM_Case_Number = 'F-CS-'+String.valueOf(inparam);
                String AKAM_Case_Number_DR = 'FD-CS-'+String.valueOf(inparam);
                
                List<Case> caseList = [SELECT Id, OwnerId, Owner.Alias, AccountId FROM Case 
                                       WHERE (AKAM_Case_Id__c = :AKAM_Case_Number OR AKAM_Case_Id__c = :AKAM_Case_Number_DR) ORDER BY AKAM_Created_Date__c Desc LIMIT 1];
                
                if(caseList.size() == 1){
                    responseObject.isCaseFound = 'true';
                    if(String.valueOf(caseList[0].ownerId).startsWith('005'))
                        responseObject.OwnerId = caseList[0].Owner.Alias;
                    responseObject.allAgentIds = ACD2_UtilClass.getTechnicalSupportTeam(caseList[0].AccountId);
                }
            }
            Catch(Exception e)
            {
                ACD2_UtilClass.sendErrorMail(inparam, e.getMessage(),e.getStackTraceString(),'ACD 2.0 Exception in ACD2_CaseDetails_CaseNumber_WS');
                ACD2_UtilClass.createLog(callGUID,'ACD2_CaseDetails_CaseNumber_WS', 'CaseNumber: '+inparam , ' Error Message: '+e.getMessage() + ' StackTrace: '+ e.getStackTraceString(), 'Exception', requestReceivedTime);  
        		return responseObject;
            }
        }
        ACD2_UtilClass.createLog(callGUID,'ACD2_CaseDetails_CaseNumber_WS', 'CaseNumber: '+inparam ,JSON.serialize(responseObject), 'Valid', requestReceivedTime);  
        return responseObject;
   }

}