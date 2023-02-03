@isTest
public class sObjectLimitsHttpCalloutMock implements HttpCalloutMock
{
	public HTTPResponse respond(HTTPRequest req)
    {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        String jsonResponse = null;
        //jsonResponse = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"EntityLimit","records":[{"attributes":{"type":"EntityLimit","url":"/services/data/v45.0/tooling/sobjects/EntityLimit/Contact.CustomFields"},"EntityDefinitionId":"Contact","Type":"CustomFields","Remaining":799,"Max":800}]}';
        jsonResponse = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"EntityLimit","records":[{"attributes":{"type":"EntityLimit","url":"/services/data/v45.0/tooling/sobjects/EntityLimit/Contact.CustomFields"},"EntityDefinitionId":"Contact","Type":"CustomFields","Remaining":799,"Max":800}]}';
        response.setBody(jsonResponse);
        response.setStatusCode(200);
        return response; 
    }
}