public class CalloutLog implements Promise.Deferred
{
    private Callout_Log__c cLog;

    public CalloutLog(HttpRequest hRequest, HttpResponse hResponse)
    {
        cLog = new Callout_Log__c();
        cLog = populateLog(hRequest, cLog);
        cLog = populateLog(hResponse, cLog);
    }

    private Callout_Log__c populateLog(HttpRequest hRequest, Callout_Log__c callLog)
    {
        callLog.Request_Body__c = hRequest.getBody();
        String requestHeaders = String.format(
                'Authorization : {0}, Content-Type : {1}',
                new List<String>{
                    hRequest.getHeader('Authorization'),
                    hRequest.getHeader('Content-Type')
                }
                );
        callLog.Request_Headers__c = requestHeaders;
        callLog.Request_Method__c = hRequest.getMethod();
        callLog.Request_URI__c = hRequest.getEndpoint();
        return callLog;
    }

    private Callout_Log__c populateLog(HttpResponse hResponse, Callout_Log__c callLog)
    {
        callLog.Response_Body__c = hResponse.getBody();
        callLog.Response_Status__c = hResponse.getStatus();
        String responseHeaders = '';
        for(String key : hResponse.getHeaderKeys())
        {
            responseHeaders += key + ' : ' + hResponse.getHeader(key);
        }
        callLog.Response_Headers__c = responseHeaders;
        callLog.Response_Status_Code__c = hResponse.getStatusCode();
        return callLog;
    }


    public CalloutLog(HttpResponse hResponse)
    {
        cLog = new Callout_Log__c();
        cLog = populateLog(hResponse, cLog);
    }
    public CalloutLog(HttpRequest hRequest)
    {
        cLog = new Callout_Log__c();
        cLog = populateLog(hRequest, cLog);
    }

    public Object resolve(Object incomingObject)
    {
        System.Debug(LoggingLevel.Error, 'AGH_D incomingObject:'+incomingObject);
        if(incomingObject!=null)
        {
            // upsert with response
            cLog.Id = (id)incomingObject;

            System.Debug(LoggingLevel.Error, 'AGH_D before upsert'+cLog);
            upsert cLog;
        }
        else
        {
            // insert
            insert cLog;
            System.Debug(LoggingLevel.Error, 'AGH_D after cLog insertion'+cLog);
            return cLog.Id;
        }
        return null;
    }


}