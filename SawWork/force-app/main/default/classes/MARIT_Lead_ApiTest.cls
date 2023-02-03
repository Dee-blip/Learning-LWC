@isTest
public class MARIT_Lead_ApiTest {
    
    private static Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
    @testSetup static void dataSetup() {
        Account account = utilTestClass.CreateAccount('Test_Account');
        insert account;
        
        User marketoIntegration = [select id from user where profile.name='Marketo Integration' and isactive=true limit 1];
        System.runAs(marketoIntegration){
            Lead l = new Lead();
            l.RecordTypeId = marketoRecordTypeId;
            l.email = 'testApi@akamai.com.invalid';
            l.Associated_Account__c = account.Id;
            l.Status = 'New';
            l.firstname = 'Test';
            l.lastname = 'AccountMatchTest2';
            l.Company = 'Test Company';
            insert l;
        }
    }

    @isTest static void testApi(){
        
        RestRequest request = new RestRequest();
        RestResponse response = new RestResponse();
        request.requestUri ='/services/apexrest/lead/convert';
        request.httpMethod = 'POST';
        
        //Valid conversion
        request.addParameter('email', 'testApi@akamai.com.invalid');
		RestContext.request = request;
        RestContext.response = response;
        MARIT_Lead_Api.convertLead();
        System.assertEquals(200, response.statusCode);
        Lead l = [Select id,convertedcontactId from Lead where email = 'testApi@akamai.com.invalid' limit 1];
        System.assertEquals(200, response.statusCode);
        System.assertNotEquals(l.convertedcontactId,null);
		
        //email is null
        request.addParameter('email', null);
		RestContext.request = request;
        RestContext.response = response;
        MARIT_Lead_Api.convertLead();
        System.assertEquals(400, response.statusCode);
        
        // No marketo lead in new/In process
        request.addParameter('email', 't@t.c');
		RestContext.request = request;
        RestContext.response = response;
        MARIT_Lead_Api.convertLead();
        System.assertEquals(400, response.statusCode);
        
	}
}