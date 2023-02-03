/**
* @description       : ScJarvisPrechatControllerTest
* @author            : Vishnu Vardhan
* @group             : 
* @last modified on  : 01-24-2022
* @last modified by  : Vishnu Vardhan
* Modifications Log
* Ver   Date         Author           Modification
* 1.0   01-24-2022   Vishnu Vardhan   Initial Version
**/
@isTest
public class ScJarvisPrechatControllerTest {
    
    
    
    static Account crateAccount() {
        Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active');
        //Account accRec2 = new Account(Name='Test Account Jarvis 2',AKAM_Account_ID__c='Test-ABC-12Jarvis',Type='Brand - Active');
        insert accRec;
        return accRec;
    }
    
    static Contact createContact(Id accountId) {
        //Contact Setup
        Contact conRec = new Contact(AccountId = accountId, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True);
        conRec.Primary_Contact_Method__c = 'Phone';
        insert conRec;
        return conRec;
    }
    
    static User createCustomerUser(Id contactId) {
        
        User newUser = new User(
            profileId = '00e0f000000cOem', 
            username = 'test@example.com.akamai123', 
            email = 'test@example.com', 
            emailencodingkey = 'UTF-8', 
            localesidkey = 'en_US', 
            languagelocalekey = 'en_US', 
            timezonesidkey = 'America/Los_Angeles', 
            alias='nuser', 
            lastname='lastname', 
            FederationIdentifier = 'test' + contactId,
            contactId = contactId
        );
        insert newUser;   
        return newUser;
    }
    
    @IsTest
    static void testJarvisChat(){
        Account acc = crateAccount();
        Contact cnt = createContact(acc.Id);
        
        User sysAdmin = [select id from User where profile.name = 'System Administrator' and isactive = true limit 1];
        
        User custUser;
        
        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        //adminRec.Jarvis_IDM_Scope__c = 'network-services/issues/v1/issues/';
        insert adminRec;
        
        System.runAs(sysAdmin){
            custUser = createCustomerUser(cnt.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        Test.startTest();
        System.runAs(custUser) {
            ScJarvisPrechatController.getPreChatInfo('123');
        }
        Test.stopTest();
        
    }
    
    @IsTest
    static void getCaseId() {
        
        utilTestClass.createCustomSettings();
        
        
        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        //adminRec.Jarvis_IDM_Scope__c = 'network-services/issues/v1/issues/';
        insert adminRec;
        
        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        system.runAs(userRun){
            //Account Setup
            Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active');
            insert accRec;
            
            //Contact Setup
            Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True);
            insert conRec;
            
            Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
            Case caseRec= new Case(Subject = 'Test', akam_case_id__c='Jarvis Test 123', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email');
            insert caseRec;
            Case cs = [select akam_case_id__c, id from case where id = :caseRec.Id];
            
            try {
                ScJarvisPrechatController.getCaseId(cs.akam_case_id__c);
            } Catch( AuraHandledException ex) {
                
            }
            
        }
    }
    
    public class MockHttpResponse implements HttpCalloutMock {
        // Implement this interface method
        public HTTPResponse respond(HTTPRequest req) {
            // Optionally, only send a mock response for a specific endpoint
            // and method.
            // System.assertEquals('http://example.com/example/test', req.getEndpoint());
            // System.assertEquals('GET', req.getMethod());
            
            String mockRes = '{"messages":[{"type":"Availability", "message":{"results":[{"id":"5733F0000004F87QAE"},{"id":"5733F0000004F82QAE"}]}}]}';
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockRes);
            res.setStatusCode(200);
            return res;
        }
    }
}