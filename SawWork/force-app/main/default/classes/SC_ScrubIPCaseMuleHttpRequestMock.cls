@isTest
global class SC_ScrubIPCaseMuleHttpRequestMock implements HttpCalloutMock 
{
    global HTTPResponse respond(HTTPRequest req) 
    {
        Map<String, Object> responseMap = new Map<String, Object>();
        HttpResponse res = new HttpResponse();

    	//This method mocks generating an access token
    	if(req.getMethod().equals('GET'))
    	{
    		responseMap.put('access_token', 'J1OieGGnuqWKitpvLEW8CDo4LI4YsJEwJJu6ujlO4BMa3PRp4G10nWA3gpFgK14b4Gg5dl05PTJl8re6ibbg1Q');
    	}
		
        // Set response values, and
        res.setHeader('Content-Type', 'application/json');
        res.setBody(JSON.serialize(responseMap));
        res.setStatusCode(200);

        // return response.
        return res;
    }
}