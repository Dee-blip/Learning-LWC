/*
Author          : Tejaswini/Vikas
Description     : Controller for Connecting to BigPanda

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
13 Dec 2021             Tejaswini/Vikas             ESESP-6008                   Initial Development
------------------------------------------------------------------------------------------------------------------
*/
public class SC_BigPandaAPI implements Queueable, Database.AllowsCallouts{
    String bpEndPoint;
    String method;
    //String accessToken;
    String requestBody;
    
    HttpRequest request;
    HttpResponse response;
    Integer responseStatusCode=0;
    String responseBody;
    String responseStatus;
    String responseMessage;
    Salesforce_BigPanda_Log__c sfbpLog;
    
    public SC_BigPandaAPI(String bpEndPoint, String method,String requestBody, Salesforce_BigPanda_Log__c sfbpLog){
        this.bpEndPoint = bpEndPoint;
        this.method = method;
        this.requestBody = requestBody;
        this.sfbpLog = sfbpLog;
    }
   
    public void execute (QueueableContext context){
        Boolean isTokenExpired=false;
        System.debug('inside the execute block of SC_BigpandaAPI class');
      
        //String accessToken = SC_BigPanda_Case_Modal_Ctrl.getAccessToken();
        Id profileId = [SELECT Id FROM Profile WHERE name = 'System Administrator'].Id;
        SC_Salesforce_Dash_Credentials__c sfdCred = SC_Salesforce_Dash_Credentials__c.getInstance(profileId);
        String accessToken;
        if(sfdCred.Access_Token__c!=null)
        {
            accessToken = sfdCred.Access_Token__c;
        }
        else{
            isTokenExpired = true;
            accessToken = SC_BigPanda_Notification_Ctrl.getAccessToken();                        
        }
        
        System.debug('the access token is: '+accessToken);

        System.debug('Inside SC_BigPandaAPI Queueable execute() method:');
        String successCodes = '';
        SC_Utility__mdt  mdt = SC_Utility__mdt.getInstance('BigPanda_Success_Code');
        successCodes = mdt.Value_Text__c;
        System.debug('the successCodes is: '+successCodes);

        String specialMsg = '';
        String specialSuccessCode ='';
        SC_Utility__mdt  mdt2 = SC_Utility__mdt.getInstance('BigPanda_Special_Success_Code');
        specialSuccessCode = mdt2.Value_Text__c;
        specialMsg = mdt2.Value__c;
        System.debug('the specialSuccessCode is: '+specialSuccessCode);
        System.debug('the specialMsg is: '+specialMsg);

        request = new HttpRequest();  
        
        request.setEndpoint(bpEndPoint);
        request.setMethod(method);
        if(method=='POST')
        {
            request.setBody(requestBody);
        }        
        request.setHeader('access_token', accessToken);
        request.setHeader('Content-Type','application/json');
        request.setClientCertificateName('EAA_KMI_Signed_Certificate');
        
        response = new Http().send(request);        
        system.debug('response : '+response);

        responseBody = response.getBody();
        system.debug('responseBody : '+responseBody);
        Map<String, Object> results;

        if(String.isNotBlank(responseBody) || String.isNotEmpty(responseBody))
        {
            results = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            if(response.getStatusCode()== 403 && results.get('detail')=='OAuth Authentication failed')
            {
                isTokenExpired = true;
                accessToken = SC_BigPanda_Notification_Ctrl.getAccessToken();
                        
                request.setHeader('access_token', accessToken);
                response = new Http().send(request);
                system.debug('The response : '+response);

                responseBody = response.getBody();
                system.debug('The responseBody : '+responseBody);

            }
        }
        
        System.debug('Outside the auth failure if block');
        
        if(String.isNotBlank(responseBody) || String.isNotEmpty(responseBody))
        {
            results = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

            responseMessage = String.valueOf(results.get('message'));
            System.debug('the message is: '+results.get('message'));
    
            responseStatus = String.valueOf(results.get('status'));
            System.debug('the status is: '+results.get('status'));
    
            responseStatusCode = Integer.valueOf(results.get('statusCode'));
            System.debug('the status code is: '+results.get('statusCode'));
        }
        else{

            responseStatusCode = response.getStatusCode();
            System.debug('the status code is: '+responseStatusCode);

            responseStatus = response.getStatus();
            System.debug('the status is: '+responseStatus);
        
        }
                
        
        sfbpLog.Response_Status_Code__c = responseStatusCode;
        
        sfbpLog.Response_Body__c = responseBody;
        sfbpLog.Response_Status__c = responseStatus;
        //sfbpLog.Number_of_Tries__c ++ ;

        System.debug('Number of tries: '+sfbpLog.Number_of_Tries__c);

        System.debug('the successcodes is: '+successCodes);
        System.debug('the responseStatusCode is: '+String.valueOf(responseStatusCode));
        String responseCode;
        if(String.valueOf(responseStatusCode)==null)
        {
            responseCode='test';
        }
        else{
            responseCode = String.valueOf(responseStatusCode);
        }
        
        if(successCodes.contains(/*String.valueOf(responseStatusCode)*/responseCode)){
            sfbpLog.Status__c = 'Success';
        }
        else if(specialSuccessCode.contains(responseCode) && responseMessage.contains(specialMsg)/*responseMessage.contains('resolved')*/)
        {
            sfbpLog.Status__c = 'Success';
        }
        else{
            sfbpLog.Status__c = 'Failed';
        }

        try
        {
            update sfbpLog;
        }
        catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }

        //Update the custom setting
        if(isTokenExpired==true)
        {
            sfdCred.Access_Token__c = accessToken;
            try
            {
                update sfdCred;
            }
            catch(Exception e)
            {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
        
    }
}