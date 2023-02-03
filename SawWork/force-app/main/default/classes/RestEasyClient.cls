public virtual class RestEasyClient
{
    protected AuthorizationStrategy authStrategy;
    /*
    private Map<String, String> m_params = new Map<String, String>();
    public static final String REQUEST_METHOD_DELETE = 'DELETE';
    public static final String REQUEST_METHOD_GET = 'GET';
    public static final String REQUEST_METHOD_POST = 'POST';
    public static final String REQUEST_METHOD_PUT = 'PUT';

    //Header statics
    public static final String HTTP_HEADER_AUTHORIZATION = 'Authorization';
    public static final String HTTP_HEADER_CONTENT_DISPOSITION = 'Content-Disposition';
    public static final String HTTP_REQUEST_PARAMETER_PREFIX = '?';
    public static final String HTTP_REQUEST_PARAMETER_SEPARATOR = '=';
    public static final String HTTP_REQUEST_ENDPOINT_SEPARATOR = '&';
    public static final String CHARSET_UTF8 = 'UTF-8';

    */
    public static final String HTTP_HEADER_CONTENT_LENGTH = 'Content-Length';
    public static final String HTTP_HEADER_CONTENT_TYPE = 'Content-Type';


    public Interface AuthorizationStrategy
    {
        HttpRequest setAuthHeaders(HttpRequest req);
        API_Connector_Object__c getConnectorDetails();

    }

    public virtual Class GenericAuthStrategy implements AuthorizationStrategy
    {
        protected API_Connector_Object__c connector;

        public GenericAuthStrategy(String namedCredential)
        {
            connector = [select Name, Access_Token__c, API_Version__c, Client_ID__c, Client_Secret__c, Client_Token__c, Crypto_Algorithm__c, Endpoint__c, Grant_Type__c, Refresh_Token__c, Time_format__c,Host__c, Moniker__c, Named_Credential__c, Timeout__c  from API_Connector_Object__c where Name= :namedCredential];
        }

        public virtual HttpRequest setAuthHeaders(HttpRequest req)
        {
            // this will handle basic auth if you set it in the named credential
            return req;
        }
        public virtual API_Connector_Object__c getConnectorDetails()
        {
            return this.connector;
        }
    }


    public RestEasyClient(AuthorizationStrategy authStrategyParam)
    {
        this.authStrategy = authStrategyParam;
    }



    public HttpRequest buildHttpRequest(String endPoint, String requestMethod, Object requestBody, String httpContentType)
    {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod(requestMethod);


        if (requestBody!= null)
        {
            if (requestBody instanceOf Blob)
            {
                Blob bodyBlob = (Blob)requestBody;
                req.setBodyAsBlob(bodyBlob);
                req.setHeader(HTTP_HEADER_CONTENT_LENGTH, String.valueOf(bodyBlob.size()));
            }
            else
            {
                String bodyStr = JSON.serialize(requestBody);
                req.setBody(bodyStr);
                req.setHeader(HTTP_HEADER_CONTENT_LENGTH, String.valueOf(bodyStr.length()));
            }

            req.setHeader(HTTP_HEADER_CONTENT_TYPE, httpContentType);
        }
        req = authStrategy.setAuthHeaders(req);
        return req;
    }
    /*

       // UNDER DEVELOPMENT
    public Object parse(HttpResponse response, System.Type deserializerClass)
    {
        return JSON.deserialize(response.getBody(), deserializerClass);
    }


    public Object executeAndParseResponse(String endPoint, String requestMethod, Object requestBody, String httpContentType, System.Type deserializerClass)
    {
        HttpResponse httpResponse = execute(endPoint, requestMethod, requestBody, httpContentType);
        return parse(httpResponse, deserializerClass);
    }

    public HttpResponse execute(String endPoint, String requestMethod, Object requestBody, String httpContentType)
    {
        HttpRequest httpRequest = buildHttpRequest(endPoint, requestMethod, requestBody, httpContentType);

        HttpResponse httpResponse = new Http().send(httpRequest);
        Integer statusCode = httpResponse.getStatusCode();
        String status = httpResponse.getStatus();
        if (statusCode >= 400)
        {
            throw new CustomException(statusCode+':'+ status);
        }

        return httpResponse;
    }

    private String createEndpoint(String endPoint)
    {

        Set<String> keys = m_params.keySet();
        if (keys.size() > 0)
        {
            endpoint += HTTP_REQUEST_PARAMETER_PREFIX;

            for (String key : keys)
            {
                String param = (String)m_params.get(key);
                if (param != null)
                {
                    endpoint += key;
                    endpoint += HTTP_REQUEST_PARAMETER_SEPARATOR;
                    endpoint += EncodingUtil.urlEncode(param, CHARSET_UTF8);
                    endpoint += HTTP_REQUEST_ENDPOINT_SEPARATOR;
                }
            }
        }

        if (endpoint.endsWith(HTTP_REQUEST_ENDPOINT_SEPARATOR))
        {
            endpoint = endpoint.substring(0, endpoint.length() - 1);
        }

        return endpoint;
    }



    public Object callPUTAndParse(String endPoint, Object requestBody, String httpContentType, System.Type deserializerClass)
    {
        return executeAndParseResponse(endPoint, 'PUT', requestBody, httpContentType, deserializerClass);
    }

    @TestVisible
    public RestEasyClient addParam(String name, Boolean param)
    {
        m_params.put(name, String.valueOf(param));
        return this;
    }

    @TestVisible
    public RestEasyClient addParam(String name, Integer param)
    {
        m_params.put(name, String.valueOf(param));
        return this;
    }

    @TestVisible
    public RestEasyClient addParam(String name, Long param)
    {
        m_params.put(name, String.valueOf(param));
        return this;
    }

    @TestVisible
    public RestEasyClient addParam(String name, String param)
    {
        m_params.put(name, param);
        return this;
    }
    */

}