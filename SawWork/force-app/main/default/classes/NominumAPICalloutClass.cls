public class NominumAPICalloutClass extends RestEasyClient{

    public NominumAPICalloutClass()
    {
        super(new RestEasyClient.GenericAuthStrategy(!Test.isRunningTest() ?GSMSettings.getValue('NominumInstanceName'):'NominumSQAForTestClass'));
    }

    public String isCurrencyValid(String curCode)
    {
        return getGetResult('getcurrencyisocode?currencyisocode='+curCode);
    }

    public String getNominumUserId(String userId)
    {
        return getGetResult('getuserid?userid='+userId);
    }

    public String getRecordTypeId(String recordTypeName)
    {
        return getGetResult('getrecordtypeid?recordtypename='+recordTypeName);
    }

    public String getQuoteId(String opportunityId)
    {
        return getGetResult('getquoteid?opportunityid='+opportunityId);
    }

    public String getGetResult(String urlParams)
    {
        Http h = new Http();
        HttpRequest hReq = buildGet(urlParams);
        HttpResponse res = h.send(hReq);


        system.debug(LoggingLevel.Error, 'RESPONSE_BODY'+res.getBody());
        APIResponse ar = (APIResponse)JSON.deserialize(res.getBody(), APIResponse.class);
        //log it asynchronously before deserialising the response
        //new Promise(new CalloutLog(hReq, res)).execute();
        if(ar.booleanResponse)
            return ar.resultId;
        else
            return ar.responseMessage;
    }

    public String getPostResult(String apiType, Object reqBody)
    {
        Http h = new Http();
        HttpRequest hReq = buildPost(apiType, reqBody);

        HttpResponse res = h.send(hReq);

        APIResponse ar = (APIResponse)JSON.deserialize(res.getBody(), APIResponse.class);

        // TODO - log POST calls
        // log it asynchronously before deserialising the response
        new Promise(new CalloutLog(hReq, res)).execute();
        if(ar.booleanResponse)
            return ar.resultId;
        else
            return ar.responseMessage;
    }

    public String createAccount(Object reqBody)
    {
        return getPostResult('createaccount', reqBody);
    }


    public String createOpportunity(Object reqBody)
    {
        return getPostResult('createopportunity', reqBody);
    }

    public String createQuote(Object reqBody)
    {
        return getPostResult('createquote', reqBody);
    }

    public HttpRequest buildGet(String apiType)
    {
        HttpRequest hRequest = buildHttpRequest(
                this.authStrategy.getConnectorDetails().Named_Credential__c+this.authStrategy.getConnectorDetails().Endpoint__c+apiType
                ,'GET'
                ,null
                ,'application/json');
        hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
        return hRequest;
    }

    public HttpRequest buildPost(String apiType, Object reqBody)
    {
        HttpRequest hRequest = buildHttpRequest(
                this.authStrategy.getConnectorDetails().Named_Credential__c+this.authStrategy.getConnectorDetails().Endpoint__c+apiType
                ,'POST'
                ,reqBody
                ,'application/json');
        hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
        return hRequest;

    }

    public class APIResponse
    {
        @AuraEnabled
        public boolean booleanResponse{get;set;}
        @AuraEnabled
        public string responseMessage{get;set;}
        @AuraEnabled
        public Id resultId {get;set;}
        @AuraEnabled
        public string link {get;set;}

        public APIResponse(Boolean bResponse)
        {
            booleanResponse = bResponse;
        }

        public APIResponse(String errorMessage)
        {
            booleanResponse = false;
            responseMessage = errorMessage;
        }

        public APIResponse(Id cId)
        {
            booleanResponse = true;
            resultId= cId;
        }
    }
}