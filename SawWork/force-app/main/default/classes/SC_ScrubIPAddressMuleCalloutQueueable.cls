/*
Author          : Vandhana Krishnamurthy
Description     : Callout to sc-ip-scrubbing-api Mule App

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
1 June 2022             Vandhana Krishnamurthy    ESESP-6457                   SC IP Scrubbing
------------------------------------------------------------------------------------------------------------------
*/
public class SC_ScrubIPAddressMuleCalloutQueueable implements Queueable, Database.AllowsCallouts
{   
    public SC_ScrubIPAddressMuleCalloutQueueable()
    { }
   
    public void execute (QueueableContext context)
    {
        System.debug('Inside SC_ScrubIPAddressMuleCalloutQueueable execute method');
        
        // -------------------------------------- MULE FLOW -------------------------------------- 
        // Code to call the mule process using http callout
        SC_Utility__mdt  mdt = SC_Utility__mdt.getInstance('IPScrub_Client_Scope');
        SC_Utility__mdt  muleEndpointMdt = SC_Utility__mdt.getInstance('URL_for_Mule_Endpoint');
        String  scope = mdt.Value__c;
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();         
        HttpResponse response = new HttpResponse();   
        
        //HTTP Request for OAuth Token
        request.setEndpoint('callout:IP_Scrub_Mule_Access_Token' + '/oauth2/token');
        request.setMethod('GET');
        request.setHeader('client_id', '{!$Credential.UserName}');
        request.setHeader('client_secret', '{!$Credential.Password}');
        request.setHeader('Content-Type','application/json');
        request.setHeader('grant_type', 'client_credentials');
        request.setHeader('scope', scope);        
        system.debug('request : '+request);
        
        //Get the response
        response = http.send(request);  
        //system.debug('response : '+response);
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());  
        //System.debug('the results are: '+results);
        String accessToken = (String) results.get('access_token');   
        
        //system.debug('accessToken : '+accessToken);
        
        Http httpCallMule = new Http();
        HttpRequest requestToCallMule = new HttpRequest();         
        HttpResponse responseOfMule = new HttpResponse();   
        
        //create the Http Request
        requestToCallMule.setEndpoint(muleEndpointMdt.Value_Text__c+'/sc-ip-scrubbing-api/scrubMainFlowBulk');
        requestToCallMule.setMethod('GET');       
        requestToCallMule.setHeader('access_token', accessToken);
        requestToCallMule.setHeader('Content-Type','application/json');
        requestToCallMule.setClientCertificateName('EAA_KMI_Signed_Certificate');
        
        system.debug('requestToCallMule : '+requestToCallMule); 
        
        responseOfMule = httpCallMule.send(requestToCallMule);  
        //system.debug('responseOfMule : '+responseOfMule);
    }
}