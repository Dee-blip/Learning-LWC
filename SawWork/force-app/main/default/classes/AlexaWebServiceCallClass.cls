/** Sonali Tandon - 4/02/2016 - SFDC-246- CR 3262841
AlexaWebServiceCallClass that calls alexa web service.
Called from CronPopulateAccountFocusAttributeClass job to calculate Focus__c attribute on Account to run once a momth. Focus is calculated based outside and inside traffic of primary country.
 Traffic data is consumed from Alexa Web Services.

 **/

public class AlexaWebServiceCallClass {
    
    private static Map<string,string> alexaMap = GsmUtilClass.getGsmSettingKeyValue('Alexa_'); //SFDC-2391

    private  final String ACTION_NAME = alexaMap.get('Alexa_ActionName'); //SFDC-2391
    private  final String RESPONSE_GROUP_NAME = alexaMap.get('Alexa_ResponseGroupName'); //SFDC-2391
    private  final String SERVICE_HOST = alexaMap.get('Alexa_ServiceHost'); //SFDC-2391
    private  final String AWS_BASE_URL = 'http://' + SERVICE_HOST + '/?';
    private  final String HASH_ALGORITHM = alexaMap.get('Alexa_HashAlgorithm'); //SFDC-2391
    private  final String DATEFORMAT_AWS = 'yyyy-MM-dd\'T\'HH:mm:ss\'Z\'';
    private  final String ACCESS_KEY_ID = alexaMap.get('Alexa_AccessKeyId'); //SFDC-2391
    private  final String SECRET_ACCESS_KEY = alexaMap.get('Alexa_SecretAccessKey'); //SFDC-2391
    
  List<CronPopulateAccountFocusAttributeClass.DataWrapper> listOfDataWrappers  = new List<CronPopulateAccountFocusAttributeClass.DataWrapper>();
  
  public AlexaWebServiceCallClass(List<CronPopulateAccountFocusAttributeClass.DataWrapper> listOfDataWrappers)
    {
      this.listOfDataWrappers = listOfDataWrappers;
      
    }

    public HttpResponse makeRequest(String uri)
    {
      Http http = new Http();
      HttpRequest request = new HttpRequest();
      HttpResponse response = new HttpResponse();
      
       if (Test.isRunningTest()) {
              HttpResponse resTest = new HttpResponse();
              if(!uri.contains(EncodingUtil.urlEncode('no website', 'UTF-8')))
              {
                resTest.setStatusCode(200);
                String body = dummyResponseBody(200);
                System.debug('Response Body is :');
                if(body!=null)
                   resTest.setBody(body);
              }
              else
              {
                resTest.setStatusCode(403);
                String body = dummyResponseBody(403);
                System.debug('Response Body is :');
                if(body!=null)
                  resTest.setBody(body);   
              }
               return resTest;
      }
      request.setEndpoint(uri);
      request.setMethod('GET');
      
      response = http.send(request);
    
      System.debug('Response status:' + response.getStatusCode());
      System.debug('The response body is:'+response.getBody());
          
      return response;
         
    }


    public String generateSignature(String data) {

        String result;
        Blob mac = crypto.generateMac(HASH_ALGORITHM,Blob.valueOf(data), Blob.valueOf(SECRET_ACCESS_KEY));
        result = EncodingUtil.base64Encode(mac);

        return result;
    }


    public String buildQuery() 
    {
      String timeStamp = Datetime.now().formatGMT(DATEFORMAT_AWS);

        // arrange params in ascending order of key 
        Map<String, String> queryParams = new Map<String, String>();
        queryParams.put('AWSAccessKeyId', ACCESS_KEY_ID);
        queryParams.put('Action', ACTION_NAME);
        queryParams.put('Shared.ResponseGroup', RESPONSE_GROUP_NAME);
        queryParams.put('SignatureMethod', HASH_ALGORITHM);
        queryParams.put('SignatureVersion', '2');
        queryParams.put('Timestamp', timeStamp);
      
        Integer count = 1;
        for(CronPopulateAccountFocusAttributeClass.DataWrapper data : listOfDataWrappers)
        {
          queryParams.put('UrlInfo.'+ count+ '.Url', data.website);
          count++;
        }

        String query = '';
        Boolean first = true;
        for (String name : queryParams.keySet()) {
            if (first)
                first = false;
            else
                query += '&';

            query += name + '=' + EncodingUtil.urlEncode(queryParams.get(name), 'UTF-8');
        }

        return query;
    }


    public HttpResponse startWebserviceCall()
    {

      try{

        String query = buildQuery();
        System.debug('query' + query);

        String toSign = 'GET' + '\n' + SERVICE_HOST + '\n' + '/' + '\n' + query;
        System.debug('toSign' + toSign);


        String signature = generateSignature(toSign);
        System.debug('signature' + signature);

        String uri = AWS_BASE_URL + query + '&Signature=' +
                EncodingUtil.urlEncode(signature, 'UTF-8');

        HttpResponse response = makeRequest(uri);

        if(response!= null)
           return  response;
      }

      catch(Exception e)
      {
        HttpResponse resError = new HttpResponse();
        resError.setStatusCode(-2);
        resError.setBody(e.getStackTraceString());
        return resError;

      }
      
      return null;

    }


    public String dummyResponseBody(Integer pstatusCode)
    {
      if(pstatusCode == 200)
      {
        return ' <?xml version="1.0"?>' + 
              ' <aws:UrlInfoResponse xmlns:aws="http://alexa.amazonaws.com/doc/2005-10-05/"><aws:Response xmlns:aws="http://awis.amazonaws.com/doc/2005-07-11"><aws:OperationRequest><aws:RequestId>e53ad351-84ff-205a-e106-f6fbb130c1bb</aws:RequestId></aws:OperationRequest><aws:UrlInfoResult><aws:Alexa>' + 
                  ' <aws:TrafficData>' + 
                  ' <aws:DataUrl type="canonical">cjpowercast.co.kr/</aws:DataUrl>' + 
                  ' <aws:RankByCountry/>' + 
                  ' </aws:TrafficData>' + 
              '</aws:Alexa></aws:UrlInfoResult><aws:ResponseStatus xmlns:aws="http://alexa.amazonaws.com/doc/2005-10-05/"><aws:StatusCode>Success</aws:StatusCode></aws:ResponseStatus></aws:Response><aws:Response xmlns:aws="http://awis.amazonaws.com/doc/2005-07-11"><aws:OperationRequest><aws:RequestId>e53ad351-84ff-205a-e106-f6fbb130c1bb</aws:RequestId></aws:OperationRequest><aws:UrlInfoResult><aws:Alexa>' + 
             
           '<aws:TrafficData>' + 
              '<aws:DataUrl type="canonical">mobage.com/</aws:DataUrl>' + 
              ' <aws:RankByCountry/>' + 
                    '<aws:Country Code="US">' + 
                  '<aws:Rank>373305</aws:Rank>' + 
                  '<aws:Contribution>' + 
                  ' <aws:PageViews>17.2%</aws:PageViews>' + 
                  ' <aws:Users>14.2%</aws:Users>' + 
                  '</aws:Contribution>' + 
                  '</aws:Country>' + 
                  ' <aws:Country Code="JP">' + 
                  '<aws:Rank/>' + 
                  '<aws:Contribution>' + 
                  ' <aws:PageViews>78.7%</aws:PageViews>' + 
                  ' <aws:Users>85.4%</aws:Users>' + 
                  '</aws:Contribution>' + 
                  '</aws:Country>' +
              ' <aws:RankByCountry/>' + 
              ' </aws:TrafficData>' + 
              '</aws:Alexa></aws:UrlInfoResult><aws:ResponseStatus xmlns:aws="http://alexa.amazonaws.com/doc/2005-10-05/"><aws:StatusCode>Success</aws:StatusCode></aws:ResponseStatus></aws:Response><aws:Response xmlns:aws="http://awis.amazonaws.com/doc/2005-07-11"><aws:OperationRequest><aws:RequestId>02ee59a0-fcdc-db58-461a-0ef46f749438</aws:RequestId></aws:OperationRequest><aws:UrlInfoResult><aws:Alexa>' +

              '<aws:TrafficData>' + 
              '<aws:DataUrl type="canonical">dwamedia.com/</aws:DataUrl>' + 
              ' <aws:RankByCountry/>' + 
                    '<aws:Country Code="US">' + 
                  '<aws:Rank>749387</aws:Rank>' + 
                  '<aws:Contribution>' + 
                  ' <aws:PageViews>21.1%</aws:PageViews>' + 
                  ' <aws:Users>14.2%</aws:Users>' + 
                  '</aws:Contribution>' + 
                  '</aws:Country>' + 
                  ' <aws:Country Code="O">' + 
                  '<aws:Rank/>' + 
                  '<aws:Contribution>' + 
                  ' <aws:PageViews>78.7%</aws:PageViews>' + 
                  ' <aws:Users>85.4%</aws:Users>' + 
                  '</aws:Contribution>' + 
                  '</aws:Country>' +
              ' <aws:RankByCountry/>' + 
              ' </aws:TrafficData>' + 
              '</aws:Alexa></aws:UrlInfoResult><aws:ResponseStatus xmlns:aws="http://alexa.amazonaws.com/doc/2005-10-05/"><aws:StatusCode>Success</aws:StatusCode></aws:ResponseStatus></aws:Response><aws:Response xmlns:aws="http://awis.amazonaws.com/doc/2005-07-11"><aws:OperationRequest><aws:RequestId>02ee59a0-fcdc-db58-461a-0ef46f749438</aws:RequestId></aws:OperationRequest><aws:UrlInfoResult><aws:Alexa>' +
        
              '<aws:TrafficData>' + 
              '<aws:DataUrl type="canonical">hitachi-hitec.com/</aws:DataUrl>' + 
              ' <aws:RankByCountry/>' + 
                    '<aws:Country Code="JP">' + 
                  '<aws:Rank>749387</aws:Rank>' + 
                  '<aws:Contribution>' + 
                  ' <aws:PageViews>100.0%</aws:PageViews>' + 
                  ' <aws:Users>100.0%</aws:Users>' + 
                  '</aws:Contribution>' + 
                  '</aws:Country>' + 
               ' <aws:RankByCountry/>' + 
              ' </aws:TrafficData>' + 
              ' </aws:Alexa></aws:UrlInfoResult><aws:ResponseStatus xmlns:aws="http://alexa.amazonaws.com/doc/2005-10-05/"><aws:StatusCode>Success</aws:StatusCode></aws:ResponseStatus></aws:Response></aws:UrlInfoResponse>';
             
      }

      else 
      {
        return ' <?xml version="1.0"?>' + 
          '<Response>' +
          '<Errors>' +
          '<Error>' +
          '<Code>SignatureDoesNotMatch</Code>'+
          '<Message>The request signature we calculated does not match the signature you provided. Check your AWS Secret Access Key and signing method. Consult the service documentation for details.</Message>' +
          '</Error>'+
          '</Errors>'+
          '<RequestID>8633640b-a53e-cd93-ef56-97868b663e0a</RequestID>'+
          '</Response>';        
  
      }

      return null;
  }
}