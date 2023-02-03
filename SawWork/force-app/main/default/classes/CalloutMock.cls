@isTest
public class CalloutMock implements HttpCalloutMock {
    // TODO allow blob for body

    public class Response implements HttpCalloutMock {
        protected Integer code;
        protected String status;
        protected String bodyAsString;
        protected Map<String, String> responseHeaders;

        public Response(String responseType)
        {
            API_Responses__mdt apiResponse = [select Response_Body__c, Response_Headers__c, Response_Status__c, Response_Status_Code__c from API_Responses__mdt where DeveloperName=:responseType];
            this.code = Integer.valueOf(apiResponse.Response_Status_Code__c);
            this.status = apiResponse.Response_Status__c;
            this.bodyAsString = apiResponse.Response_Body__c;
            this.responseHeaders = (apiResponse.Response_Headers__c!=null) ? (Map<String,String>) JSON.deserialize(apiResponse.Response_Headers__c, Map<String,String>.class) : null;
        }


        public HttpResponse respond(HttpRequest req) 
        {

            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.code);
            res.setStatus(this.status);
            res.setBody(this.bodyAsString);

            if (this.responseHeaders != null)
                for (String k : responseHeaders.keyset())
                    res.setHeader(k, responseHeaders.get(k));

            return res;
        }
    }


    public List<CalloutMock.Response> responses = new List<CalloutMock.Response>();

    public CalloutMock(List<String> responseTypes) 
    {
        for(String responseType : responseTypes)
        {
            this.responses.add(new CalloutMock.Response(responseType));
        }
    }

    public CalloutMock(String responseType)
    {
        this(responseType.contains(',') ? responseType.split(',') : new List<String>{responseType});
    }



    public HttpResponse respond(HttpRequest req) {
        if (req.getEndPoint().contains('EXCEPTION')) throw new MockException('Mock Exception');

        HttpCalloutMock mock = responses.remove(0);
        if (mock == null) throw new MockException('This mock does not exist');
        return mock.respond(req);
    }

    public class MockException extends Exception {}
}