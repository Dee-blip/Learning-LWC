@isTest
global class TrialsMockSAResponseGenerator implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        JSONGenerator responseJSON = JSON.createGenerator(true);
        
        responseJSON.writeStartObject(); 
            responseJSON.writeStringField('recordId', 'a90kmkko1');
            
            responseJSON.writeFieldName('receivedJSON');
           
            responseJSON.writeStartArray();
                responseJSON.writeStartObject();
                    responseJSON.writeFieldName('tranSummary');
                        responseJSON.writeStartObject();
                        responseJSON.writeStringField('numUrls', '1');
                        responseJSON.writeStringField('totalBytes', '1430');
                        responseJSON.writeStringField('regionId', '123');
                        responseJSON.writeStringField('transactionTime', '100');
                        responseJSON.writeStringField('hasErrors', '257');
                        responseJSON.writeStringField('numPages', '1');
                responseJSON.writeEndObject();
        
                responseJSON.writeStringField('regionId', '13275');
                responseJSON.writeStringField('regionName', 'Queretaro,Uninet SA');
                responseJSON.writeStringField('testType', 'tran');

                responseJSON.writeFieldName('pages');
                    responseJSON.writeStartArray();
                    responseJSON.writeStartObject();
                        responseJSON.writeFieldName('pageObjects');
                            responseJSON.writeStartArray();
                            responseJSON.writeStartObject();
                                responseJSON.writeStringField('path', 'https');
                                responseJSON.writeStringField('protocol', 'https');
                                responseJSON.writeStringField('port', '123');
                                responseJSON.writeStringField('objectType', 'b');
                                responseJSON.writeStringField('serverIp', '74.125.227.177');
                                responseJSON.writeStringField('isConnectionAlive', '1');
                                responseJSON.writeStringField('contentLen', 'https');
                                responseJSON.writeStringField('checkSum', 'https');
                                responseJSON.writeStringField('dnsTime', '123');
                                responseJSON.writeStringField('handshakeTime', 'b');
                                responseJSON.writeStringField('dataStartTime', '74.125.227.177');
                                responseJSON.writeStringField('dataDownloadTime', '1');
                                responseJSON.writeStringField('totalTime', 'https');
                                responseJSON.writeStringField('isReconnect', 'https');
                                responseJSON.writeStringField('connectTime', '123');
                                responseJSON.writeStringField('errorCode', 'b');
                                responseJSON.writeStringField('startTime', '74.125.227.177');
                                responseJSON.writeStringField('responseCode', '1');
                                responseJSON.writeStringField('domain', 'www.google.com');
                            responseJSON.writeEndObject();
                            responseJSON.writeEndArray();
                
                responseJSON.writeFieldName('pageSummary');
                    responseJSON.writeStartObject();
                        responseJSON.writeStringField('totalBaseUrls', '1');
                        responseJSON.writeStringField('domLoading', '1430');
                        responseJSON.writeStringField('domComplete', '123');
                        responseJSON.writeStringField('loadEventStartTime', '100');
                        responseJSON.writeStringField('loadEventEndTime', '257');
                        responseJSON.writeStringField('totalUrls', '1');
                        responseJSON.writeStringField('totalBytes', '1');
                        responseJSON.writeStringField('stepNum', '1430');
                        responseJSON.writeStringField('totalDownloadTime', '123');
                        responseJSON.writeStringField('baseDownloadTime', '100');
                        responseJSON.writeStringField('hasErrors', '257');
                    responseJSON.writeEndObject();
                responseJSON.writeEndObject();
                responseJSON.writeEndArray();
                

    responseJSON.writeEndObject();
    responseJSON.writeEndArray();
    system.debug('###' + responseJSON.getAsString());
    res.setBody(responseJSON.getAsString());
    res.setStatusCode(200);
    res.setStatus('OK');
    return res;
        //return null;
    }
    
    global HTTPResponse responseForProvisioningSuccess(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        JSONGenerator responseJSON = JSON.createGenerator(true);
        
        responseJSON.writeStartObject();
            responseJSON.writeStringField('message', '1');
            responseJSON.writeStringField('success', 'true');
            responseJSON.writeStringField('data', '123');
       responseJSON.writeEndObject();     
   
        res.setBody(responseJSON.getAsString());
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
    
    global HTTPResponse responseForProvisioningFailure(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        JSONGenerator responseJSON = JSON.createGenerator(true);
        
        responseJSON.writeStartObject();
            responseJSON.writeStringField('message', '1');
            responseJSON.writeStringField('success', 'false');
            responseJSON.writeStringField('data', '123');
       responseJSON.writeEndObject();     
   
        res.setBody(responseJSON.getAsString());
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
    
    global HTTPResponse responseForInstantCheckSuccess(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        JSONGenerator responseJSON = JSON.createGenerator(true);
        res.setBody(responseJSON.getAsString());
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
    
    global HTTPResponse responseForInstantCheckFailure(HTTPRequest req){
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        JSONGenerator responseJSON = JSON.createGenerator(true);
        res.setBody(responseJSON.getAsString());
        res.setStatusCode(200);
        res.setStatus('OK');
        return res;
    }
}