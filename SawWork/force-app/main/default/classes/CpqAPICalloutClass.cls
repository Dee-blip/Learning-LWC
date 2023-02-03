public class CpqAPICalloutClass extends RestEasyClient{
    public CpqAPICalloutClass() {
        // super(new CPQAkamaiEdgeAuthStrategy('PulsarEnvironmentConnectorName'));
        
        super(new AkamaiEdgeAuthStrategy(!Test.isRunningTest() ? (CPQ_UtilityClass.isSandbox() ? CPQSettings.getValue('CPQPulsarEnvConnectorName_Sandbox') : CPQSettings.getValue('CPQPulsarEnvConnectorName')) :'CPQPulsarSQAForTestClass'));
        
    }
    public String getCarrierPricingDetails(String prodId, String currencyValue, String customerType, String geoset, String partnerTier,String pacEndpointGetPricing) {
        
                return getGetResult((pacEndpointGetPricing)
                .replaceAll('PROD_ID',prodId)
                .replaceAll('PARTNER_ID','')
                .replaceAll('CURR_ID',currencyValue)
                .replaceAll('CUST_TYPE_KEY',customerType));
       
    }
    public String getPricingDetails(String prodId, String currencyValue, String customerType, String geoset, String partnerTier, String partnerAccId) {
        // return getGetResult(CPQSettings.getValue('PAC_Endpoint_Get_Pricing')
        //         .replaceAll('PROD_ID', prodId)
        //         .replaceAll('CURR_ID', currencyValue)
        //         .replaceAll('CUST_TYPE_KEY', customerType)
        //         .replaceAll('GEOSET_KEY', geoset)
        //         .replaceAll('PRICEPOINT_KEY', partnerTier));
        return getGetResult(CPQSettings.getValue('PAC_Endpoint_Get_Pricing')
                .replaceAll('PROD_ID', prodId)
                .replaceAll('PARTNER_ID', partnerAccId)
                .replaceAll('CURR_ID', currencyValue)
                .replaceAll('CUST_TYPE_KEY', customerType));
    }

    public String getGetResult(String urlParams) {
        Http http = new Http();
        if(urlParams.contains(' ')){
            urlParams = urlParams.replaceAll(' ', '%20');
        }

        try{
            HttpRequest hReq = buildGet(urlParams);
            HttpResponse res = http.send(hReq);
            return res.getBody();
        } catch (Exception e) {
            CPQ_LogException.logInformation('An exception occured while making the request: '+e);
            return '{"status":404}';
        }

    }

    public HttpRequest buildGet(String endpointWithoutHostWithQueryParams)
    {
        HttpRequest hRequest = buildHttpRequest(
                this.authStrategy.getConnectorDetails().Named_Credential__c + endpointWithoutHostWithQueryParams
                ,'GET'
                ,null
                ,'application/json');
        hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
        // hRequest.setHeader('Accept', '*/*');
        return hRequest;
    }

    public String getAttributeDetails(String prodId) {
        return getGetResult(CPQSettings.getValue('PAC_Endpoint_Get_Attributes')
                .replaceAll('PROD_ID', prodId));

    }
    

    public String getSectionsDetails(String prodId, String customerType, String geoset) {
        return getGetResult(CPQSettings.getValue('PAC_Endpoint_Get_Sections')
                .replaceAll('PROD_ID', prodId)
                .replaceAll('CUST_TYPE_KEY', customerType));

    }


    public String getLiteratureDetails(String prodId) {
        return getGetResult(CPQSettings.getValue('PAC_Endpoint_Get_Literature')
                .replaceAll('PROD_ID', prodId));

    }

    public String getPostResult(String urlParams,  Object requestBody){

        Http http = new Http();
        if(urlParams.contains(' ')){
            urlParams = urlParams.replaceAll(' ', '%20');
        }
        try{

            HttpRequest hRequest = buildHttpRequest(this.authStrategy.getConnectorDetails().Named_Credential__c +  
                                                    urlParams, 
                                                    'POST', 
                                                    requestBody, 
                                                    'application/json'
                                                );
                                            
            hRequest.setTimeout(Integer.valueOf(this.authStrategy.getConnectorDetails().Timeout__c));
            CPQ_LogException.logInformation('hRequest: '+hRequest);
            HttpResponse res = http.send(hRequest);
            return res.getBody();
        }
        catch(Exception e){
            
            return '{"status":404}';

        }

    }

    public String postProductCodes(Object requestBody){
        return getPostResult(CPQSettings.getValue('PAC_Endpoint_Get_Products'), requestBody);
    }
}