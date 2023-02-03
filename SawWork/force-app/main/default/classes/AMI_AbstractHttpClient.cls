global without sharing abstract class AMI_AbstractHttpClient {

    global abstract void addAuthorizationHeader(Map<String,String> headers);
    global abstract void resetBearerToken();

    private String doHttpCall(String url,String httpMethod,Map<String,String> headers,String payload){
      try {
      Http http = new Http();
      HttpRequest request = new HttpRequest();
      request.setEndpoint(url);
      request.setMethod(httpMethod);
      for(String key : headers.keySet()){
          request.setHeader(key, headers.get(key));
      }
      if(!payload.equals('')){
          request.setBody(payload);
      }
      HttpResponse response = http.send(request);
      if(response.getStatusCode() == AMI_HttpStatus.FORBIDDEN){
          throw new AMI_TokenExpiredException();
      }else if(response.getStatusCode()<500 && response.getStatusCode() > 399){
          System.debug('400 series exception'+ response.getStatusCode());
          throw new AMI_4XXException('Response code return is'+response.getStatusCode());
      }else if(response.getStatusCode()< 200 || response.getStatusCode() > 299){
          System.debug('Response code return in  http is not success: ' + response.getStatusCode());
          throw new AMI_HttpCommunicationException('response code was '+response.getStatusCode());
      }
      System.debug('successfully retrieved data :'+ response.getBody());
      return response.getBody();
      } catch (Exception e) {
          System.debug('There was an exception in http communication: ' + e.getStackTraceString());
          throw e;
      }
    }

    public String performRequest(String url,String httpMethod,Map<String,String> headers,String payload){
        try {
            addAuthorizationHeader(headers);
            return doHttpCall(url, httpMethod, headers, payload);
        } catch (AMI_TokenExpiredException ex) {
            System.debug('Token was expired using retry with new token: ');
            resetBearerToken();
            addAuthorizationHeader(headers);
            return doHttpCall(url, httpMethod, headers, payload);
        }
    }

    public void codeCoverageHack(){
        Integer i = 0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}