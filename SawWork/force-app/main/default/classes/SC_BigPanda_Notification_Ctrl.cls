/***
Author          : Vikas/Tejaswini
Description     : Controller to get webhook notification from sites

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
09 Nov 2021             Vikas/Tejaswini             ESESP-6008                  Initial Development, Rest class for webhook
------------------------------------------------------------------------------------------------------------------
***/
@RestResource(urlMapping='/bigpandaWebhookNotification')
global class SC_BigPanda_Notification_Ctrl {
    @HttpGet
    global static String doGet() {
        String id = RestContext.request.params.get('id');
        return 'The Id of the Bigpanda incident is ' + id;
    }
    
    public class BigpandaWebhookNotificationException extends Exception {}
    
    @HttpPost
    global static void doPost () {
        RestRequest request;
        String requestBody ='';
        String method = 'POST';
        Id recordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Inbound Request').getRecordTypeId();
        SC_Utility__mdt  mdt = SC_Utility__mdt.getInstance('BigPanda_Post_Webhook_URL');
        String  endPoint = mdt.Value__c;
        System.debug('the bpEndPoint is: '+endPoint);
        //String endPoint ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/webhooknotifications';
        Map<String,Object> incidentTagsMapObjects = new Map<String,Object>();
        Boolean invalidAppKey = false;
        
        try{
            request = RestContext.request;
            system.debug('The request is: '+request);
            system.debug('The request headers is: '+request.headers.get('x-bp-app-key'));
            String bpHeaderAppKey = request.headers.get('x-bp-app-key');
            Id profileId = [SELECT Id FROM Profile WHERE name = 'System Administrator'].Id;
            SC_Salesforce_Dash_Credentials__c sfdCred = SC_Salesforce_Dash_Credentials__c.getInstance(profileId);
            if(sfdCred.BP_Header_Secret__c ==null || bpHeaderAppKey != sfdCred.BP_Header_Secret__c )
            {
                invalidAppKey = true;
            }
            requestBody = request.requestBody.toString ().replace('\uFEFF', '');
            system.debug('The requestBody is: '+requestBody);
            
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(requestBody);
            incidentTagsMapObjects = (Map<String,Object>) results.get('incident');
            system.debug('incidentTagsMapObjects : '+incidentTagsMapObjects.get('id'));
        }
        catch(Exception e)
        {
            System.debug('Exception is'+e.getMessage());  
        } 
        
        if(requestBody!=null)
        {
            Salesforce_BigPanda_Log__c sfbpLog = new Salesforce_BigPanda_Log__c();
            sfbpLog.RecordTypeId = recordTypeId;
            sfbpLog.Request_Endpoint__c = endpoint;
            sfbpLog.Request_Method__c = method;
            sfbpLog.Request_Body__c = requestBody;
            sfbpLog.Do_Not_Retry__c = false;
            sfbpLog.Number_of_Tries__c = 1;
            sfbpLog.Flow_Name__c = 'post_webhookNotificationsSub_Flow';
            sfbpLog.Action__c = 'Share Incident';
            sfbpLog.Incident_Id__c = String.valueOf(incidentTagsMapObjects.get('id'));
            //sfbpLog.Unique_Indentifier_Text__c = 'Share Incident-post_webhookNotificationsflow-'+String.valueOf(incidentTagsMapObjects.get('id'));
            if(invalidAppKey)
            {
                sfbpLog.Response_Body__c = 'Invalid App Key';
                sfbpLog.Response_Status_Code__c = 403;
                sfbpLog.Response_Status__c = 'Authentication Failed.';
                sfbpLog.Status__c = 'Failed';
                sfbpLog.Do_Not_Retry__c = true;
            }
            
            insert sfbpLog;
            
            system.debug('endpoint : '+endpoint);
            
            if(!invalidAppKey)
            {
                System.enqueueJob(new SC_BigPandaAPI(endpoint, method,requestBody, sfbpLog));
            }
        }
    }
    
    public static String getAccessToken(){

        SC_Utility__mdt  mdt = SC_Utility__mdt.getInstance('BigPanda_Client_Scope');
        String  scope = mdt.Value__c;
        System.debug('the scope is: '+scope);

        Http http = new Http();
        HttpRequest request = new HttpRequest();         
        HttpResponse response = new HttpResponse();   
        
        //create the Http Request
       	request.setEndpoint('callout:Mule_Access_Token' + '/oauth2/token');
        request.setMethod('GET');
        request.setHeader('client_id', '{!$Credential.UserName}');
        request.setHeader('client_secret', '{!$Credential.Password}');
        request.setHeader('Content-Type','application/json');
        request.setHeader('grant_type', 'client_credentials');
        request.setHeader('scope', scope);        
        system.debug('request : '+request);
    
        //Get the response
        response = http.send(request);  
        system.debug('response : '+response);
    
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());  
        System.debug('the results are: '+results);
        String accessToken = (String) results.get('access_token');   
        system.debug('accessToken : '+accessToken);

        return accessToken;
    }
}