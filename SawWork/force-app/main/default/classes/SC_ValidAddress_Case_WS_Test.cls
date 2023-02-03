/*=====================================================================================================+
    Author              :   Aravind Perichiappan
    Created             :   13-May-2021
    Purpose             :   Test Class for SC_ValidAddress_Case_WS
+=====================================================================================================*/
@isTest
public class SC_ValidAddress_Case_WS_Test
{
    @testSetup static void setup()
    {
        utilTestClass.createCustomSettings();
        insert new Case(AuthorizedContacts__c='test@example.org',Do_Not_Show_in_Portal__c=false);
    }
    
    @isTest static void testPost()
    {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = '/services/apexrest/SC_ValidAddress_Case_WS';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/json');
        String akamCaseId = [SELECT Akam_Case_Id__c from Case Limit 1].Akam_Case_Id__c;
        req.requestBody = Blob.valueOf('{"caseId": "' + akamCaseId + '", "to": "test@akamai.com.invalid,test@example.com", "cc": "test@akamai.com.invalid,test@example.org", "bcc": "test@akamai.com.invalid,test@example.com"}');
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        String validationResult = SC_ValidAddress_Case_WS.validateAddress();
        Test.stopTest();

        System.assertEquals('unauthorized - test@example.com, test@example.com', validationResult);
    }
}