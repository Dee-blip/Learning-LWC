/**
* Test class for CPQB_ExtPricing and CPQAPICallout Classes
* @author  Shashank Hegade 
* @version 1.0
* @since   2020-11-04
*/

@IsTest(seeAllData = false)
public without sharing class CPQB_ExtPricingTest {
    @TestSetup
    static void makeData(){
        
        new CPQ_TestDataFactory.APIConnectorBuilder('CPQPulsarSQAForTestClass','host')
        .withCryptoAlgorithm('HmacSHA256')
        .withClientSecret('client-secret')
        .withMoniker('EG1-HMAC-SHA256')
        .withClientToken('client-token')
        .withAccessToken('access-token')
        .withNamedCredential('callout:CPQPulsarSQA2')
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('PAC_Endpoint_Get_Pricing')
        .withActive(true)
        .withValue('/pac-api/v2/products/PROD_ID/versions/curr/pricing?partnerAccountId=PARTNER_ID&currency=CURR_ID&customerType=CUST_TYPE_KEY')
        .saveRecord();

    }

    @IsTest
    static void testAPICallout(){

        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();             
        req.requestURI = '/services/apexrest/pricing/';
        req.httpMethod = 'POST';
        RestContext.request = req;
        RestContext.response= res;
        
        Test.startTest();
        String testString = CPQB_ExtPricing.postExternalPricing('USD', 'customerType', 'partnerTier', 'partnerAccId', new List<String>{'productIds'});
        Test.stopTest();
        
    }
}