/*
Author          : Tejaswini
Description     : Test class for Bigpanda classes

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
05 Jan 2022             Tejaswini                ESESP-6008                   Http Request callout mock class for SC_BigPanda_TC
------------------------------------------------------------------------------------------------------------------
*/
@isTest
public without sharing class SC_BigPanda_HttpRequestMock_TC implements HttpCalloutMock {
    public SC_BigPanda_HttpRequestMock_TC() {

    }

    public HTTPResponse respond(HTTPRequest req) 
    {
        String successCodes = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE MasterLabel = 'BigPanda_Success_Code' LIMIT 1].Value_Text__c;
    	// Create a fake response.
        Map<String, Object> responseMap = new Map<String, Object>();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

    	//This method mocks generating an access token
    	if(req.getMethod().equals('GET'))
    	{
    		responseMap.put('access_token', 'J1OieGGnuqWKitpvLEW8CDo4LI4YsJEwJJu6ujlO4BMa3PRp4G10nWA3gpFgK14b4Gg5dl05PTJl8re6ibbg1Q');
    	}
		
		if(req.getMethod().equals('POST'))
    	{
            responseMap.put('Request Response','Success');    
    	}
       
        res.setBody(JSON.serialize(responseMap));
        res.setStatus('success');
        res.setStatusCode(200);    
        // return response.
        return res;
    }
}