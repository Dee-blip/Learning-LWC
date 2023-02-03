/***
    SC_ScrubIPCaseNotesHttpRequestMockClass
    @author Sandeep Naga
    @Description : 


    @History
    --Developer           --Date            --Change
    Sandeep Naga      29th March 2019    Creation of mocj http callout test class
*/

@isTest
global class SC_ScrubIPCaseNotesHttpRequestMockClass implements HttpCalloutMock {
	// Error Flag
    public Boolean errorFlg { get; set; }
 
    public SC_ScrubIPCaseNotesHttpRequestMockClass(Boolean errFlg) {
        this.errorFlg = errFlg;
    }

    global HTTPResponse respond(HTTPRequest req) {

    	// Send a communication error when the Error flag is true 
        if (this.errorFlg) {
            throw new System.CalloutException('Communication Error');
        }


    	//Check for the Endpoint and Request METHOD (Fetched from hostname and notes of respective custom setting)
    	//System.assert(req.getEndpoint().contains('dash-ext.akamai.com/casemanagement/v2/removenotesip'));

    	// Create a fake response.
        Map<String, Object> responseMap = new Map<String, Object>();
        HttpResponse res = new HttpResponse();

    	//This method mocks generating an access token
    	if(req.getMethod().equals('GET'))
    	{
    		responseMap.put('access_token', 'J1OieGGnuqWKitpvLEW8CDo4LI4YsJEwJJu6ujlO4BMa3PRp4G10nWA3gpFgK14b4Gg5dl05PTJl8re6ibbg1Q');
    	}
		
		else if(req.getMethod().equals('POST'))
    	{
    		responseMap.put('Casses response','Successfull');
    	}

        
       
        // Set response values, and
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(responseMap));
        res.setStatusCode(200);

        // return response.
        return res;
    }

}