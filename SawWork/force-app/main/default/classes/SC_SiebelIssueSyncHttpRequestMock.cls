/******

Author: Sharath Prasanna
Created Date: 27th Aug 2020
Description: Mock HTTP generator for SC_SiebelIssueSync

Developer               Date                Jira            Description
Sharath Prasanna     27th Aug 2020        ESESP-3536    	Test Class
*/

@isTest
public class SC_SiebelIssueSyncHttpRequestMock implements HttpCalloutMock 
{
    public Boolean setError;
    
    public SC_SiebelIssueSyncHttpRequestMock(Boolean error) 
    {
        setError = error;
    }

    public HTTPResponse respond(HTTPRequest req) 
    {


    	// Create a fake response.
        Map<String, Object> responseMap = new Map<String, Object>();
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');

    	//This method mocks generating an access token
    	if(req.getMethod().equals('GET'))
    	{
    		responseMap.put('access_token', 'J1OieGGnuqWKitpvLEW8CDo4LI4YsJEwJJu6ujlO4BMa3PRp4G10nWA3gpFgK14b4Gg5dl05PTJl8re6ibbg1Q');
    	}
		
		else if(req.getMethod().equals('POST'))
    	{
            if(setError)
            {
                responseMap.put('Error','Invalid access token');    
            }
            else 
            {
                responseMap.put('activityId','12345678');    
            }    		
    	}
       
        res.setBody(JSON.serialize(responseMap));
        if(setError)
        {
            res.setStatusCode(400);    
        }
        else
        {
            res.setStatusCode(200);    
        }
        // return response.
        return res;
    }
}