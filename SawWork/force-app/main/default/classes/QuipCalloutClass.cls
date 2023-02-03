public class QuipCalloutClass extends RestEasyClient{
    public static string namedCredential = GsmUtilClass.getGSMSettingValue('Quip_Named_Credential');
    public static string companyId = GsmUtilClass.getGSMSettingValue('Quip_CompanyId');
    
    public QuipCalloutClass() {
        super(new RestEasyClient.GenericAuthStrategy(namedCredential));
    }
    
    public QuipEventJSONToField getEvents(String cursor) {
        return getGetResult('admin/events/1/events/get?cursor='+cursor);
    }
    
    public String getCursor() {
        DateTime dt = System.now();
        Integer sinceTimestampInDays = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Quip_Event_Since_Timestamp_In_Days'));
        Integer untilTimestampInHours = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Quip_Event_Until_Timestamp_In_Hours'));
        Long nowMinusNHours = dt.addHours(-(untilTimestampInHours)).getTime()*1000;
        Long nowMinusNDays = dt.addDays(-(sinceTimestampInDays)).getTime()*1000;
        String eventTypes = GsmUtilClass.getGSMSettingValue('Quip_EventTypes');
        return getGetResult('admin/events/1/cursor/create?company_id='+companyId+'&since_timestamp='+nowMinusNDays+'&until_timestamp='+nowMinusNHours+'&event_types='+eventTypes).next_cursor;
    }
    
    public Map<String, String> getThreads(Set<String> threadIds) {
        Http h = new Http();
        String threadIdsJoined = String.join(new List<String>(threadIds), ',');
        HttpRequest hReq = buildGet('admin/threads/?company_id='+companyId+'&ids='+threadIdsJoined);
        HttpResponse res = h.send(hReq);
        Map<String, Object> allThreadDetails = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        Map<String, String> threadIdToLink= new Map<String, String>();
        if(!allThreadDetails.containsKey('error')){
            for(String threadId : allThreadDetails.keySet()) {
                Map<String, Object> threadDeets = (Map<String, Object>) allThreadDetails.get(threadId);
                if(threadDeets.containsKey('thread')){
                    Map<String, Object> threadDetailsMap =(Map<String,Object>) threadDeets.get('thread');
                    threadIdToLink.put(threadId, (String)threadDetailsMap.get('link'));
                    threadIdToLink.put((String)threadDetailsMap.get('document_id'), (String)threadDetailsMap.get('link'));
                    threadIdToLink.put((String)threadDetailsMap.get('id'), (String)threadDetailsMap.get('link'));
                }
            }
        }
        else{
            string errDescription = String.valueOf(allThreadDetails.get('error_description'));
            if(errDescription.contains('Invalid thread id') || errDescription.contains('Not authorized')){
                string invalidThreadId = errDescription.split(':')[1];
                invalidThreadId = invalidThreadId.trim();
                threadIds.remove(invalidThreadId);
                return getThreads(threadIds);
            }
        }
        return threadIdToLink;
    }
    
    public Map<String, String> getUsers(Set<String> userIds) {
        Http h = new Http();
        String userIdsJoined = String.join(new List<String>(userIds), ',');
        HttpRequest hReq = buildGet('users/?ids='+userIdsJoined);
        HttpResponse res = h.send(hReq);
        Map<String, Object> allUserDetails = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        Map<String, String> userIdToEmail= new Map<String, String>();
        for(String userId : allUserDetails.keySet())
        {
            Map<String, Object> threadDeets =(Map<String, Object>) allUserDetails.get(userId);
            if(!threadDeets.containsKey('error')){
                List<Object> emailList =(List<Object>) threadDeets.get('emails');
                if(emailList!=null && emailList.size()>0)
                    userIdToEmail.put(userId, (String)emailList[0]);
            }
        }
        return userIdToEmail;
    }
    
    public HttpRequest prepareSCIMRequest(String endPoint, String token, String body, String method){
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint);
        request.setMethod(method);
        request.setHeader( 'Authorization', 'Bearer ' + token );
        request.setBody(body);
        return request;
    }
    
    public String getValueFromResponseBody(String resBody, String key){
        string val = '';
        system.JSONParser parser = system.JSON.createParser(resBody);
        while (parser.nextToken() != system.JSONToken.END_OBJECT) {
            if (parser.getCurrentToken() == system.JSONToken.FIELD_NAME) {
                String text = parser.getText();
                if (parser.nextToken() != system.JSONToken.VALUE_NULL) {
                    if(text == key) {
                        val = parser.getText();
                        break;
                    }
                }
            }
        }
        return val;
    }
    
    public QuipEventJSONToField getGetResult(String urlParams) {
        Http h = new Http();
        HttpRequest hReq = buildGet(urlParams);
        HttpResponse res = h.send(hReq);
        String resBody = res.getBody();
        QuipEventJSONToField eventJsonToField = QuipEventJSONToField.parse(resBody);
        return eventJsonToField;
    }

    public Integer getPostResult(String apiType, Object reqBody)
    {
        Http h = new Http();
        HttpRequest hReq = buildPost(apiType, reqBody);
        HttpResponse res = h.send(hReq);
        populateCalloutLogs(hReq,res);
        return res.getStatusCode();
    }
    
    public HttpRequest buildGet(String apiType) {
        HttpRequest hRequest = buildHttpRequest(
            this.authStrategy.getConnectorDetails().Named_Credential__c+this.authStrategy.getConnectorDetails().Endpoint__c+apiType
            ,'GET'
            ,null
            ,'application/json');
        hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
        return hRequest;
    }

    public HttpRequest buildPost(String endpointWithoutHostWithQueryParams, Object reqBody)
    {
        HttpRequest hRequest = buildHttpRequest(
                this.authStrategy.getConnectorDetails().Named_Credential__c + endpointWithoutHostWithQueryParams
                ,'POST'
                ,reqBody
                ,'application/json');
        hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
        return hRequest;
    }

    public void populateCalloutLogs(HttpRequest hRequest, HttpResponse hResponse){
        Callout_Log__c callLog = new Callout_Log__c();
        
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
        
        callLog.Response_Body__c = hResponse.getBody();
        callLog.Response_Status__c = hResponse.getStatus();
        String responseHeaders = '';
        for(String key : hResponse.getHeaderKeys())
        {
            responseHeaders += key + ' : ' + hResponse.getHeader(key);
        }
        callLog.Response_Headers__c = responseHeaders;
        callLog.Response_Status_Code__c = hResponse.getStatusCode();
        
        try{
            insert callLog;
        }
        catch(Exception ex){
            Sawyer.saw(ex);
        }
    }
}