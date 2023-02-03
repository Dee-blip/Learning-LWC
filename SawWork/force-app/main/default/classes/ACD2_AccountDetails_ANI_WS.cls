/***************************************************************************
 * Name             : ACD2_AccountDetails_ANI_WS
 * Created By       : Himanshu Kar
 * Created Date     : 07-Jul-2020
 * Purpose          : Main Akatec Webservice.
 * Test Class       : ACD2_Webservices_Test
 
 Last Modified BY   Last Modified Date  Purpose
 ----------------   ------------------  ---------
 Himanshu           07-Jul-2020         Initial Development
 Sharath            15 April 2020       Modified the class: Added null ERC filter.
                                        If there are multiple Account matches, return false
 ****************************************************************************
 

Input Parameters : CallGUID (string), ANI  

Use Cases:
----------
1. ANI -> 1 Contact -> 1 Account Found, No ERC - return false 
    (/services/apexrest/ACD2_AccountDetails_ANI_WS?ANI=+919999999999)
    
2. ANI -> Multiple Contact -> Multiple Account Found (ERC might or might not be the same) - return false 
    (/services/apexrest/ACD2_AccountDetails_ANI_WS?ANI=+918455845510)
    
3. ANI -> Multiple Contact -> 1 Account Found -> 1 ERC (common) - return true with details  
    (/services/apexrest/ACD2_AccountDetails_ANI_WS?ANI=+918455845555)
    
4. ANI -> 0 Contact - return false 
    (/services/apexrest/ACD2_AccountDetails_ANI_WS?ANI=+161727468281)
    
5. ANI -> 1 Contact -> 1 Account with ERC - return true with details 
    (/services/apexrest/ACD2_AccountDetails_ANI_WS?ANI=9448027217)    

*/ 

@RestResource(urlMapping='/ACD2_AccountDetails_ANI_WS/*')
global class ACD2_AccountDetails_ANI_WS 
{
    
    // Wrapper structure to be returned to TTEC
    global class ACD2_Akatec_Main_Wrapper
    { 
        
        string isSingleContactFound;    //  Return True is only 1 Contact Found. Else return false(For No / Multiple Contact)
        string isERCFound;              //  If ERC Found
        string Akam_Contact_Id;
        string Akam_Account_Id;
        string ERC_Number;
        string isPremiumAccount;
        string Account_Geo;
        List<string> allEntitledProducts;
        
        // Initializing with default value
        global ACD2_Akatec_Main_Wrapper()
        {
            
            isSingleContactFound    = 'false';
            isERCFound              = 'false';
            Akam_Contact_Id         = null;
            Akam_Account_Id         = null;
            ERC_Number              = null;
            isPremiumAccount        = 'false';
            Account_Geo             = null;
            allEntitledProducts     = new List<string>(); 
        }
    }
    
    @HttpGet
    global static ACD2_Akatec_Main_Wrapper getSupportTeamFromANI() 
    {
        
        // Step - 1 : Getting Input Parameter
        Datetime requestReceivedTime = DateTime.now();
        RestRequest req = RestContext.request;
        String originalInparam = req.params.get('ANI');
        String inparam = originalInparam;
        String callGUID = req.params.get('CallGUID').trim();
        
        // Step - 2 : Initialize the wrapper & Required variable Initialization
        ACD2_Akatec_Main_Wrapper ANIWrapperObj = new ACD2_Akatec_Main_Wrapper();
        List<list<SObject>> searchList = new List<list<SObject>>();      
        set<string> allERC = new set<string>();  
            
        // Step - 3 : If ANI is Blank, Then return false
        if(!String.isBlank(inparam))
        {
            //try catch block
            try
            {    
                inparam = ACD2_UtilClass.prepareANI(inparam);
                
                // Step - 4 : SOSL Query on Contact 
                searchList = [FIND :inparam in Phone FIELDS RETURNING CONTACT (Id, AKAM_Contact_ID__c, Account.AKAM_Account_ID__c, Account.ERC_Numeric__c, 
                                AccountId, Account.Akatec_Geography__c,Account.AKERC__c where Account.ERC_Numeric__c != null )];
    
                // Step - 5 : Getting Contact Data from SOSL Result             
                List<Contact> contactList = new List<Contact>();
                contactList = ((List<contact>)searchList[0]);
                
                // Step - 6 : If result is only 1 record with ERC then return true else return false for all use cases
                if(contactList.size() == 1)
                {
                    ANIWrapperObj.isSingleContactFound = 'true';
                    ANIWrapperObj.isERCFound        = 'true';
                    ANIWrapperObj.Akam_Contact_Id   = contactList.get(0).AKAM_Contact_ID__c;
                    ANIWrapperObj.Akam_Account_Id   = contactList.get(0).Account.AKAM_Account_ID__c;
                    ANIWrapperObj.ERC_Number        = contactList.get(0).Account.ERC_Numeric__c;
                    ANIWrapperObj.isPremiumAccount  = ACD2_UtilClass.isPremiumAccountCheck(new List<Id>{contactList.get(0).AccountId});
                    ANIWrapperObj.Account_Geo       = contactList.get(0).Account.Akatec_Geography__c;
                    ANIWrapperObj.allEntitledProducts = ACD2_UtilClass.getAllProducts(new List<Id>{contactList.get(0).AccountId});
                    
                } 
                
                // Logic if more than 1 result found
                else if (contactList.size() >1)
                {              
                    // Step - 7 : Loop for all Contact to get the Unique Account Id instead of ERC
                    for(Contact eachConRec : contactList)
                    {
                        allERC.add(eachConRec.AccountId);
                    }
                    
                    // Step - 8 : If Multiple Contacts tied to 1 Account, then return details without Contact Id Else return false
                    if(allERC.size() == 1)
                    {   
                        ANIWrapperObj.isSingleContactFound = 'true';
                        ANIWrapperObj.isERCFound        = 'true';
                        ANIWrapperObj.Akam_Account_Id   = contactList.get(0).Account.AKAM_Account_ID__c;
                        ANIWrapperObj.ERC_Number        = contactList.get(0).Account.ERC_Numeric__c;
                        ANIWrapperObj.isPremiumAccount  = ACD2_UtilClass.isPremiumAccountCheck(new List<Id>{contactList.get(0).AccountId});
                        ANIWrapperObj.Account_Geo       = contactList.get(0).Account.Akatec_Geography__c;
                        ANIWrapperObj.allEntitledProducts = ACD2_UtilClass.getAllProducts(new List<Id>{contactList.get(0).AccountId});
                    }
                }    
                
            }
            catch(Exception e)
            {
                ACD2_UtilClass.createLog(callGUID,'ACD2_AccountDetails_ANI_WS', 'ANI: '+originalInparam ,' Error Message: ' +e.getMessage()+ ' StackTrace: ' + e.getStackTraceString(),'Exception',requestReceivedTime );  
                ACD2_UtilClass.sendErrorMail(' 1. ANI = ' + inparam , e.getMessage(),e.getStackTraceString(),
                                             'ACD 2.0 Exception in - ACD2_AccountDetails_ANI_WS');
                return ANIWrapperObj;   
            }
            
        }
        ACD2_UtilClass.createLog(callGUID,'ACD2_AccountDetails_ANI_WS', 'ANI: '+originalInparam ,JSON.serialize(ANIWrapperObj),'Valid',requestReceivedTime);   
        return ANIWrapperObj;   
    }
      
}