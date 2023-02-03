/******

Author: Sharath Prasanna
Created Date: 22nd Sep 2021
Description: Mock HTTP generator for Jarvis

Developer               Date                Jira            Description
Sharath Prasanna     22nd Sep 2021        ESESP-4356    	Test Class
*/
@isTest
public without sharing class SC_Jarvis_PermissionHttpRequestMock implements HttpCalloutMock 
{
    public SC_Jarvis_PermissionHttpRequestMock() 
    {

    }
    public HTTPResponse respond(HTTPRequest req) 
    {
    	// Create a fake response.
        Map<String, Object> responseMap = new Map<String, Object>();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

    	//This method mocks generating an access token
		if(req.getMethod().equals('GET') )
    	{
            responseMap.put('access_token', 'J1OieGGnuqWKitpvLEW8CDo4LI4YsJEwJJu6ujlO4BMa3PRp4G10nWA3gpFgK14b4Gg5dl05PTJl8re6ibbg1Q');
    	}
       
        res.setBody(JSON.serialize(responseMap));
        res.setStatusCode(200);    
        // return response.
        return res;
    }
}