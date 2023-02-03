global without sharing class AMI_SaasLoginHttpClient extends AMI_AbstractHttpClient{
    public static String microsoftLoginUrl = AMI_UtilClass.getAMISettingValue('MicrosoftLoginUrl');
    public static AMI_Credential__c credentials = null;

   public override void addAuthorizationHeader(Map<String,String> headers){
       //do nothing as there is no token creation here
    }

    public override void resetBearerToken(){
        //do nothing as there is no token creation here
    }

    public static void setupAMICredentials(){
        credentials = AMI_UtilClass.getAMICredentials();
    }

     public String getBearerTokenForSaasApiCalls(){
      if(credentials == null) {
          setupAMICredentials();
      }
      //System.debug(LoggingLevel.debug,'credentials ' + credentials);
      String endPoint = AMI_SaasLoginHttpClient.microsoftLoginUrl+'/' + credentials.Tenant_Id__c + '/oauth2/token';
      Map<String,String> headers = new Map<String,String>();
      headers.put(AMI_HttpConstants.CONTENT_TYPE, AMI_HttpConstants.FORM_ENCODED_HEADER);
      String payload = 'client_id='+EncodingUtil.urlEncode(credentials.Client_ID__c,'UTF-8')+'&client_secret='+EncodingUtil.urlEncode(credentials.Client_Secret__c,'UTF-8')+'&Resource='+EncodingUtil.urlEncode(credentials.Resource_ID__c,'UTF-8')+'&grant_type=client_credentials';
      String apiResponse = performRequest(endPoint, AMI_HttpConstants.HTTP_POST_METHOD, headers, payload);
      //System.debug(LoggingLevel.debug,'apiResponse ' + apiResponse);
      AMI_AuthorizationResponse authResponse = (AMI_AuthorizationResponse) JSON.deserialize(apiResponse, AMI_AuthorizationResponse.class);
      //System.debug(LoggingLevel.debug,'AUTHRESPONSE ' + authResponse);
      //System.debug('Access token retrived is: ' + authResponse.getAccessToken());
     return authResponse.access_token;
    }
}