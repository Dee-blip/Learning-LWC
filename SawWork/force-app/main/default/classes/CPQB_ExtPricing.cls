@RestResource(urlMapping='/pricing/*')
global without sharing class CPQB_ExtPricing {

    @HttpPost
    @AuraEnabled(cacheable=true)
    // global static String postExternalPricing(List<String> productIds) {
    global static String postExternalPricing(String currencyValue, String customerType, String partnerTier, String partnerAccId, List<String> productIds) {
        System.debug('CPQB_ExtPricing | postExternalPricing');
        System.debug('method entered: '+Datetime.now().formatGMT('yyyyMMdd\'T\'HH:mm:ss SSS'));
        String geoset = 'WORLD';
        String totalResponse = '{"productDetails":[';
        Integer counter = 0;
        for (String prodId : productIds) {
            if(counter > 0) {
                totalResponse += ',';
            }

            CpqAPICalloutClass calloutObj = new CpqAPICalloutClass();
            String returnValue = calloutObj.getPricingDetails(prodId, currencyValue, customerType, geoset, partnerTier, partnerAccId);
            System.debug('Response: '+returnValue);
            System.debug('response received: '+Datetime.now().formatGMT('yyyyMMdd\'T\'HH:mm:ss SSS'));

            totalResponse += returnValue;
            counter++;
        }
        totalResponse += ']}';
        system.debug('totalResponse: '+totalResponse);
        return totalResponse;
    }
}