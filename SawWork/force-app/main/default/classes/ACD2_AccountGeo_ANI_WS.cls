/***************************************************************************
 * Developer: Sharath Prasanna
 * Enhancement: SOCC API ACD
 * Date: 12th Feb 2020
 * Test Class   : ACD2_Webservices_Test
---------------------------------------------------
    Input Parameters : CallGUID (string), ANI
    
    Use Cases:
    ----------
    1. ANI -> No Contact found - get the country code to geo mapping -> 1 geo match found -> return true and the geo name
    (/services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+91845584551000)
    
    2. ANI -> No Contact found - get the country code to geo mapping -> no geo match found -> return false and Others geo
    (/services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+991845584551000)

    3. ANI -> No Contact found - get the country code to geo mapping -> Multiple geo matches found -> Return the first matched Geo
    (/services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+161727468281)

    4. ANI -> 1 Contact found ->  return true and the Account Support Geo field value
    (/services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+918455845510)
    
    5. ANI -> Multiple Contacts found  -> select the latest modified contact -> return true and the Account Support Geo field value
    (services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+918455845555)
    
    6. ANI -> Contact found -> Americas Geo
    (/services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+918880050006)

    7. ANI -> Contact found -> EMEA Geo
    (services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+918455845510)

    8. ANI -> Contact found -> APJ Geo
    (/services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+79941234567)

    9. ANI -> Contact found -> Japan
    (/services/apexrest/ACD2_AccountGeo_ANI_WS?ANI=+919341234925)

 */ 
@RestResource(urlMapping='/ACD2_AccountGeo_ANI_WS/*')
global class ACD2_AccountGeo_ANI_WS
{
    // Wrapper structure to be returned to Cisco
    global class SOCCResponseWrapper
    {
        String isGeographyFound;// true if geography match is found found: false otherwise
        String geography; // if isGeographyFound is false, UNK and geography value otherwise
        
        global SOCCResponseWrapper()
        {
            isGeographyFound = 'false';
            geography = 'Others';
        }
    }

    @HttpGet
    global static SOCCResponseWrapper getGeographyOutput() 
    {
        Datetime requestReceivedTime = DateTime.now();
        RestRequest req = RestContext.request;

        String originalInparam = req.params.get('ANI');
        String inparam = originalInparam;
        String callGUID = req.params.get('CallGUID');

        SOCCResponseWrapper sOCCResponseWrapperObject = new SOCCResponseWrapper();

        if(!String.isBlank(inparam))
        {
            try
            {
                inparam = inparam.trim();
                inparam = ACD2_UtilClass.prepareANI(inparam);
                
                List<list<SObject>> searchList = new List<list<SObject>>();
                                
                searchList = [FIND :inparam in PHONE FIELDS RETURNING CONTACT 
                              (Id,Account.SOCC_Geography__c , lastmodifieddate order by lastmodifieddate desc)];
                
                List<Contact> contactList = new List<Contact>();
                contactList = ((List<Contact>)searchList[0]);
                
                sOCCResponseWrapperObject.geography = contactList.size() == 0? 
                    ACD2_UtilClass.getCountryCodeGeo(inparam) :contactList.get(0).Account.SOCC_Geography__c;
        
                sOCCResponseWrapperObject.isGeographyFound = sOCCResponseWrapperObject.geography != 'Others'?'true' : 'false';
                
            }
            catch(Exception e)
            {
                ACD2_UtilClass.createLog(callGUID,'ACD2_AccountGeo_ANI_WS', 'ANI: '+originalInparam ,' Error Message: ' +e.getMessage()+ ' StackTrace: ' + e.getStackTraceString(),'Exception',requestReceivedTime );  
                ACD2_UtilClass.sendErrorMail(inparam,e.getMessage(),e.getStackTraceString(),'ACD 2.0 Exception in ACD2_AccountGeo_ANI_WS');
                return sOCCResponseWrapperObject;
            }
            
        }
        
        ACD2_UtilClass.createLog(callGUID,'ACD2_AccountGeo_ANI_WS', 'ANI: '+originalInparam ,JSON.serialize(sOCCResponseWrapperObject),'Valid',requestReceivedTime);  
        return sOCCResponseWrapperObject;
    }
    
}