public with sharing class SearchAkamaiCommunityResultPageCtrl {
    
    public static String getAccessToken(){
        Customer_Community_Search_Config__c muleConfig = Customer_Community_Search_Config__c.getValues('MuleAccessTokenEndpoint'); //get config data from custom settings
        String accessToken = '';
        Http http = new Http(); //compose https GET request
        HttpRequest request = new HttpRequest();
        List<String> queryParamsKey = muleConfig.Query_Params__c.split(';');
        List<String> queryParamsValues = muleConfig.Query_Param_Values__c.split(';');
        String queryParam = '?' + queryParamsKey.get(0)+'='+ queryParamsValues.get(0) + '&' + queryParamsKey.get(1)+'='+queryParamsValues.get(1);
        request.setEndpoint('callout:Community_Search'+ queryParam);
        request.setMethod(muleConfig.Method__c);

        try{
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200) {    
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());    
                accessToken = (String) results.get('access_token'); //access token from mule
            }
            else{
               return 'Error:' + response.getStatusCode() + ':' + response.getStatus(); 
            }  
        }
        catch(Exception ex){
            System.debug(LoggingLevel.ERROR, handleException(ex));
            return null;
        }
        
        return accessToken;
    }

    @AuraEnabled(cacheable=true)
    public static String getUser(){
        Id profileId = userinfo.getProfileId();
        String profileName=[Select Name from Profile where Id=:profileId].Name;
        Map<String, String> userDetails = new Map<String, String>();
        userDetails.put('Id',UserInfo.getUserId() );
        userDetails.put('userName', UserInfo.getName());
        userDetails.put('profileName',profileName);
        return JSON.serialize(userDetails);
    }

    @AuraEnabled(cacheable=false)
    public static String getSearchResponse(String body, String apiName){
        String result = '';
        Customer_Community_Search_Config__c searchConfig; //get config data from custom settings
        Http http = new Http();
        HttpRequest request = new HttpRequest(); //compose https GET request
        String errorMsg = 'Unable to get results. Please try again';
        
        String accessToken = getAccessToken(); //get access token
        if(accessToken == null || accessToken.startsWithIgnoreCase('Error:')){
            return 'Invalid Access Token. Please Contact Your Administrator';
        }
        
        if(apiName == 'results' || apiName == 'audit'){
            searchConfig = Customer_Community_Search_Config__c.getValues('SearchQueryEndpoint');
            request.setHeader('Content-Type','application/json;charset=UTF-8');
        }
        
        List<String> queryParamsKey = searchConfig.Query_Params__c.split(';');
        String endpointURL = searchConfig.Base_URL__c + searchConfig.Resource_Path__c + '?' + queryParamsKey.get(0)+'='+UserInfo.getUserId();
        request.setEndpoint(endpointURL);
        request.setMethod(searchConfig.Method__c);
        request.setHeader('access_token',accessToken);
        request.setClientCertificateName(searchConfig.Cert_Name__c);
        request.setBody(body);
        
        try{
            HttpResponse response = http.send(request);
            if(response.getStatusCode() == 200) {
                result = response.getBody(); //get response
            }
            else{
               return errorMsg+ '\n'+ response.getStatusCode() + ':' + response.getStatus(); 
            } 
        }
        catch(Exception ex){
            System.debug(LoggingLevel.ERROR, handleException(ex));
            return errorMsg+'\n'+ex.getMessage();
        }
        return result;
    }
    
    public static String handleException(Exception ex){
        return 'Message: '+ ex.getMessage() + ' StackTrace: '+ex.getStackTraceString(); 
    }

}