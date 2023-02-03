/*****************************************************************************
 * Developer    : Sharath Prasanna
 * Enhancement  : Helpdesk API ACD
 * Date         : 16th Jan 2020
 * Test Class   : ACD2_Webservices_Test
 ---------------------------------------------------
    Input Parameters : CallGUID (string), ANI
    
    Use Cases:
    ----------
    1. ANI -> No User found - return false
    (/services/apexrest/ACD2_UserDetails_ANI_WS?ANI=+18575005000)
    
    2. ANI -> 1 User found ->  - return true and the User information
    (/services/apexrest/ACD2_UserDetails_ANI_WS?ANI=9945565353)
    
    3. ANI -> Multiple Users  - return true and all the Users information
    (/services/apexrest/ACD2_UserDetails_ANI_WS?ANI=+18575005192)
    
 
 */ 
@RestResource(urlMapping='/ACD2_UserDetails_ANI_WS/*')
global class ACD2_UserDetails_ANI_WS 
{
    // Wrapper structure to be returned to Cisco
    global class HelpdeskResponseWrapper
    {
        String isContactFound;// true if found: false otherwise
        String isVIP; //true or false
        String ldap; //null if isContactFound is false 
        String AkAM_Contact_Id; // null if isContactFound is false 
        global HelpdeskResponseWrapper()
        {
            //default value is false
            isContactFound = 'false';
            isVIP = 'false';            
        }
    }

    @HttpGet
    global static HelpdeskResponseWrapper getListOutput() 
    {
        Datetime requestReceivedTime = DateTime.now();
        RestRequest req = RestContext.request;
        
        String originalInparam = req.params.get('ANI');
        String inparam = originalInparam;
        String callGUID = req.params.get('CallGUID');
        
        HelpdeskResponseWrapper helpdeskResponseWrapperObject = new HelpdeskResponseWrapper();

        if(!String.isBlank(inparam))
        {
            try
            {
                inparam = inparam.trim();
                inparam = ACD2_UtilClass.prepareANI(inparam);
                List<list<SObject>> searchList = new List<list<SObject>>();
                
                List<HelpdeskResponseWrapper> wrapperList = new List<HelpdeskResponseWrapper>();
                
                
                
                //sosl on Users. Filters on isActive and the Salesforce License. Ignores Community users
                searchList = [FIND :inparam in PHONE FIELDS RETURNING USER (Id, Name, Alias, Title, Akam_User_Id__c 
                                                                            WHERE IsActive = true
                             and profile.UserLicense.name in ('Chatter Only','Salesforce','Salesforce Platform'))];
                
                List<User> userList = new List<User>();
                
                userList = ((List<User>)searchList[0]);
                
                if(userList.size() == 1)
                {
                    helpdeskResponseWrapperObject = new HelpdeskResponseWrapper();        
                    helpdeskResponseWrapperObject.isContactFound = 'true';
                    
                    
                    Map <String,Boolean> userToVIPMap = ACD2_UtilClass.checkForVIPUser(userList);
                    
                    helpdeskResponseWrapperObject.ldap = userList.get(0).Alias;
                    helpdeskResponseWrapperObject.AkAM_Contact_Id = userList.get(0).Akam_User_Id__c;
                    helpdeskResponseWrapperObject.isVIP = userToVIPMap.get(userList.get(0).Id)?'true':'false';
                        
                }                
            }
            catch(Exception e)
            {
                ACD2_UtilClass.createLog(callGUID,'ACD2_UserDetails_ANI_WS', 'ANI: '+originalInparam ,' Error Message: ' +e.getMessage()+ ' StackTrace: ' + e.getStackTraceString(),'Exception',requestReceivedTime );
                ACD2_UtilClass.sendErrorMail(inparam, e.getMessage() ,e.getStackTraceString()  ,'ACD 2.0 Exception in ACD2_UserDetails_ANI_WS');
                return helpdeskResponseWrapperObject;
            }
            
        }
        ACD2_UtilClass.createLog(callGUID,'ACD2_UserDetails_ANI_WS', 'ANI: '+originalInparam ,JSON.serialize(helpdeskResponseWrapperObject),'Valid',requestReceivedTime);
        return helpdeskResponseWrapperObject;
    }
    
}