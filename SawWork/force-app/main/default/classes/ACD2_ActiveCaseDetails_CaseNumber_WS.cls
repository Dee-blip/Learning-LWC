/***************************************************************************
* Name 			: ACD2_ActiveCaseDetails_CaseNumber_WS
* Created By 	: Vamsee S
* Created Date 	: 07-Feb-2020
* Purpose 		: Case Details Webservice.
* Test Class	: ACD2_Webservices_Test
---------------------------------------------------
Last Modified BY 	Last Modified Date 		Purpose
---------------------------------------------------
Vamsee S 			07-Feb-2020 			Initial Development
****************************************************************************

Input Parameters 	: CallGUID(String), CaseNumber(String)
Output Parameters	: isActiveCaseFound(String), OwnerId(String)


Use Cases:
----------
1. CaseNumber -> 3874178 -> Active Case Found, Owner is an User
(/services/apexrest/ACD2_ActiveCaseDetails_CaseNumber_WS?CaseNumber=3874178)

2. CaseNumber -> 3874177 -> Active Case Found, Owner is a Queue
(/services/apexrest/ACD2_ActiveCaseDetails_CaseNumber_WS?CaseNumber=3874177)

3. CaseNumber -> 3874184 -> Case is Closed
(/services/apexrest/ACD2_ActiveCaseDetails_CaseNumber_WS?CaseNumber=3874184)

4. CaseNumber -> 4567890 - No Case Found
(/services/apexrest/ACD2_ActiveCaseDetails_CaseNumber_WS?CaseNumber=4567890)

5. Casnumber -> ''
(/services/apexrest/ACD2_ActiveCaseDetails_CaseNumber_WS?CaseNumber=)
*/

@RestResource(urlMapping='/ACD2_ActiveCaseDetails_CaseNumber_WS/*')
Global class ACD2_ActiveCaseDetails_CaseNumber_WS {
    
    // Wrapper structure to be returned to Cisco
	global class CaseDetailsResponseWrapper{
		String isActiveCaseFound ;// true if found: false otherwise
		String OwnerId; //Case Owner if found: null otherwise 
		//default value is false
        global CaseDetailsResponseWrapper(){
            isActiveCaseFound  = 'false';
            OwnerId = null;    
        }
	}
    
    @HttpGet
    global static CaseDetailsResponseWrapper getListOutput() {
        
        Datetime requestReceivedTime = DateTime.now();
        RestRequest req = RestContext.request;
        
        String inparam = req.params.get('CaseNumber');
        String callGUID = req.params.get('CallGUID');
        
        CaseDetailsResponseWrapper responseObject = new CaseDetailsResponseWrapper();
        if(!String.isBlank(inparam)){
            Try
            {
                inparam = inparam.trim();
                
                String AKAM_Case_Number = 'F-CS-'+String.valueOf(inparam);
				String AKAM_Case_Number_DR = 'FD-CS-'+String.valueOf(inparam);
                
                List<Case> caseList = [SELECT Id, Owner.Alias, Isclosed, Status FROM Case 
                                       WHERE (AKAM_Case_Id__c = :AKAM_Case_Number OR AKAM_Case_Id__c = :AKAM_Case_Number_DR) ORDER BY AKAM_Created_Date__c Desc LIMIT 1];
                
                if(caseList.size() == 1){
                    responseObject.isActiveCaseFound  = 'true';
                    //ACD2-171 - When Case is Closed return Isactivecase = true and Ownerid = null
                    if(caseList[0].Status.Contains('Closed') || caseList[0].Isclosed == True)
                        responseObject.OwnerId = null;
                    else if(String.valueOf(caseList[0].ownerId).startsWith('005'))
                        responseObject.OwnerId = caseList[0].Owner.Alias;
                }
            }
            catch(Exception e)
            {
                ACD2_UtilClass.sendErrorMail(inparam, e.getMessage(),e.getStackTraceString(),'ACD 2.0 Exception in ACD2_ActiveCaseDetails_CaseNumber_WS');
                ACD2_UtilClass.createLog(callGUID,'ACD2_ActiveCaseDetails_CaseNumber_WS', 'CaseNumber: '+inparam , ' Error Message : '+e.getMessage() + ' StackTrace: '+ e.getStackTraceString(), 'Exception',requestReceivedTime);
                return responseObject;
        
            }
        }
        
        ACD2_UtilClass.createLog(callGUID,'ACD2_ActiveCaseDetails_CaseNumber_WS', 'CaseNumber: '+inparam ,JSON.serialize(responseObject), 'Valid',requestReceivedTime);  
        return responseObject;
   }

}