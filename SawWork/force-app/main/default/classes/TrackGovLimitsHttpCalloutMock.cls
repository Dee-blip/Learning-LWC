@isTest
public class TrackGovLimitsHttpCalloutMock implements HttpCalloutMock
{
    public HTTPResponse respond(HTTPRequest req)
    {
        HttpResponse response = new HttpResponse();
        String jsonResponse = null;
        response.setHeader('Content-Type', 'application/json');
        //jsonResponse = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"LookupFilter","records":[{"attributes":{"type":"LookupFilter","url":"/services/data/v33.0/tooling/sobjects/LookupFilter/0DG0f0000008sNHGAY"},"Id":"0DG0f0000008sNHGAY","Active":"true","SourceFieldDefinitionId":"Lead.00N0f00000FSN7a","CreatedDate:"2050-04-22T14:49:30.000Z"}]}';
        jsonResponse = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v33.0/tooling/sobjects/ValidationRule/03dA00000005iL2IAI"},"Id":"03dA00000005iL2IAI","CreatedDate":"2050-01-22T14:49:30.000Z"}]}';
        jsonResponse += '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"WorkflowRule","records":[{"attributes":{"type":"WorkflowRule","url":"/services/data/v33.0/tooling/sobjects/WorkflowRule/03dA00000005iL2IAI"},"Id":"03dA00000005iL2IAI","CreatedDate":"2050-04-22T14:49:30.000Z"}]}';
        response.setBody(jsonResponse);
        response.setStatusCode(200);
        return response; 
    }
}