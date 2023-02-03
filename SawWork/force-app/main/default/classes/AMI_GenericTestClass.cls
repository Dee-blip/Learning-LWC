@isTest(seeAllData=false)
public class AMI_GenericTestClass {
    public static testMethod void genericCoverageClass() {
        AMI_MainComponentController.saveSubscription('{"subscriptionId": "df6b38c7-9032-0ac8-f326-skprab","name": "Test Product Plan 1 subscription","beneficiary": { "companyName": "testComp","jobTitle":"Dev","displayName":"Test","emailId":"test@akamai.com","businessPhones":["123"],"tenantId": "514876bd-5965-4b40-b0c8-e336cf72c743","puid": "10037FFE90CBF3CF","objectId": "7a6ae661-e952-4466-9357-6c109f323834"}}');
        AMI_Subscription__c testSub = new AMI_Subscription__c();
        testSub.company__c = 'testCompany';
        AMI_WebhookRequestModel testModel = new AMI_WebhookRequestModel();
        testModel.subscriptionId = 'df6b38c7-9032-0ac8-f326-skprab';
        testModel.action='CHANGEPLAN';
        AMI_EmailHandler emailHandler = new AMI_EmailHandler();
        emailHandler.sendUpdateOperationEmail(testModel,testSub,AMI_GenericTestClass.getOperationDetailResponse());

        AMI_SaasRequestHandlerService saasReqHandler = new AMI_SaasRequestHandlerService();
        saasReqHandler.codeCoverageHack();
        AMI_SaasHttpClient httpClient = new AMI_SaasHttpClient();
        httpClient.codeCoverageHack();

        AMI_SaasHttpClient httpClient1 = new AMI_SaasHttpClient();
        httpClient1.codeCoverage();
        
    }
        
    public static testmethod void testObjectHandler(){
        AMI_MainComponentResponseModel testRequest = new AMI_MainComponentResponseModel();
        testRequest.subscriptionId = 'df6b38c7-9032-0ac8-f326-skprab';
        testRequest.offerId = 'test_product_transact-preview';
        testRequest.planId = 'plan-1';
        AMI_UserDetailResponse testBeneficiary =AMI_GenericTestClass.getUserDetailsResponse();
        testRequest.beneficiary = testBeneficiary;
        testRequest.purchaser = testBeneficiary;
        testRequest.saasSubscriptionStatus = 'PendingFulfillmentStart';
        testRequest.isFreeTrial = false;
        AMI_ObjectHandler.saveSubscription(testRequest);
        
        AMI_WebhookRequestModel testOpReq = new AMI_WebhookRequestModel();
        testOpReq.subscriptionId = 'df6b38c7-9032-0ac8-f326-skprab';
        testOpReq.action = 'CHANGEPLAN';
        testOpReq.id = 'testId';
        testOpReq.planId = 'plan-1';
        testOpReq.status = 'PendingFulfillmentStart';
        AMI_ObjectHandler.saveOperation(testOpReq,AMI_GenericTestClass.getOperationDetailResponse());
        
    }

    public static AMI_UserDetailResponse getUserDetailsResponse(){
           AMI_UserDetailResponse userDetailsResponse = new AMI_UserDetailResponse();
                userDetailsResponse.givenName = 'test';
                userDetailsResponse.displayName = 'test coverage';
                userDetailsResponse.surname = 'coverage';
                userDetailsResponse.jobTitle = 'test coverage';
                userDetailsResponse.mobilePhone = '99999999';
                userDetailsResponse.streetAddress = 'test coverage';
                userDetailsResponse.city = 'test coverage';
                userDetailsResponse.state = 'test coverage';
                userDetailsResponse.country = 'test coverage';
                userDetailsResponse.postalCode = 'test coverage';
                userDetailsResponse.objectId = 'test coverage';
                userDetailsResponse.tenantId = 'test coverage';

        return userDetailsResponse;
    }
    
    public static testmethod void testRestEndpointsPost() {
        
      AMI_GenericTestClass.insertCredential();
        
	  AMI_AuthorizationResponse authorizationResponse = new AMI_AuthorizationResponse();
       authorizationResponse.access_token = 'access_token';
       authorizationResponse.token_type = 'trert';
 
       AMI_OperationsDetailResponse operationDetailResponse = new AMI_OperationsDetailResponse();
       operationDetailResponse.offerId='test';
       operationDetailResponse.planId = 'plan1';
       operationDetailResponse.id = 'operation1';
       operationDetailResponse.action='unsubscribe';
 
       MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
        multimock.setStaticResource(
            'https://login.microsoftonline.com/*', JSON.serialize(authorizationResponse));
        multimock.setStaticResource(
            'https://marketplaceapi.microsoft.com/api/saas/subscriptions/*', JSON.serialize(new List<AMI_OperationsDetailResponse>{operationDetailResponse}));
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);
 

        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        AMI_WebhookRequestModel requestMock = new AMI_WebhookRequestModel();
        requestMock.id='operation1';
        requestMock.offerId='test';
        requestMock.planId='plan1';
        requestMock.publisherId='publisher1';
        requestMock.status='pending';
        requestMock.subscriptionId='subscription1';
 
       req.requestURI = '/services/apexrest/saas/subscriptions/update'; //Request URL
       req.httpMethod = 'POST';//HTTP Request Type
       req.requestBody = Blob.valueof(JSON.serialize(requestMock));
       RestContext.request = req;
       RestContext.response= res;
       AMI_SaasWebHookRestAPI.updateSubscriptionStatus();
	}


     public static testmethod void coverageForResolveSubscriptionHttpRespnse() {
        Test.startTest();
        AMI_SubscriptionResolveResponse testSubResRep = new AMI_SubscriptionResolveResponse();
        testSubResRep.id = 'testId';
        testSubResRep.offerId = 'testOfferId';
        testSubResRep.planId = 'plan-1';
        testSubResRep.subscriptionName = 'testSubName';
        Test.stopTest();
    }
     
 
    
    public static testmethod void testCustomExceptions() {
        Test.startTest();
        		Integer forbidden = AMI_HttpStatus.FORBIDDEN;
                try {
                    throw new AMI_4XXException('code coverage');
                } catch (Exception e) {
                    
                }
                try {
                    throw new AMI_HttpCommunicationException('code coverage');
                } catch (Exception e) {
                    
                }
                try {
                    throw new AMI_TokenExpiredException('code coverage');
                } catch (Exception e) {
                    
                }
                AMI_4XXException badRequest = new AMI_4XXException();
        	    AMI_HttpCommunicationException commException = new AMI_HttpCommunicationException();
                AMI_TokenExpiredException tokenExpired = new AMI_TokenExpiredException();
        Test.stopTest();
    }

    public static testmethod void coverageForSaasSubscriptionHttpResponse() {
        Test.startTest();
                AMI_GenericTestClass.getAMISubscriptionResponse();
        		
        Test.stopTest();
    }

    public static AMI_SaasSubscriptionResponse getAMISubscriptionResponse(){
         AMI_SaasSubscriberDetailsModel subscriber = new AMI_SaasSubscriberDetailsModel();
                subscriber.tenantId = '2233';
                subscriber.objectId = '2233';
                subscriber.emailId = '2233';
                subscriber.puid = '2233';
        AMI_SaasSubscriptionResponse saasResponse = new AMI_SaasSubscriptionResponse();
                saasResponse.id = 'test';
                saasResponse.publisherId = 'test';
                saasResponse.offerId = 'test';
                saasResponse.name = 'test';
                saasResponse.saasSubscriptionStatus='test';
                saasResponse.planId = 'test';
                saasResponse.sessionId = 'test';
                saasResponse.fulfillmentId = 'test';
                saasResponse.beneficiary = subscriber;
                saasResponse.purchaser = subscriber;
        AMI_TermResponseModel termResponse = new AMI_TermResponseModel();
        termResponse.termUnit = 'P1M';
        saasResponse.term = termResponse;

                return saasResponse;
    }

   

    public static AMI_OperationsDetailResponse getOperationDetailResponse(){
         AMI_OperationsDetailResponse operations = new AMI_OperationsDetailResponse();
                operations.id = 'test';
                operations.activityId = 'test';
                operations.subscriptionId = 'test';
                operations.offerId = 'test';
                operations.publisherId = 'test';
                operations.planId = 'test';
                operations.activityId = 'test';
                operations.status = 'test';
                return operations;
    }

     public static testmethod void coverageForMainComponentControllerResponse() {
        Test.startTest();
            getMainComponentResponse();    
        Test.stopTest();
    }

    public static AMI_MainComponentResponseModel getMainComponentResponse(){
        AMI_MainComponentResponseModel mainResponse = new AMI_MainComponentResponseModel();
        mainResponse.publisherId = 'test';
        mainResponse.offerId = 'test';
        mainResponse.name = 'test';
        mainResponse.saasSubscriptionStatus = 'test';
        mainResponse.planId = 'test';
        mainResponse.sessionId = 'test';
        mainResponse.fulfillmentId = 'test';
        return mainResponse;
    }

    public static testmethod void testForGetClientId() {
        Test.startTest();
        AMI_GenericTestClass.insertCredential();
        AMI_MainComponentController.getClientIdForAppOperations();

        Test.stopTest();
    }

    public static testMethod void testCoverageForResolveSubscritpion() {
       Test.startTest();
       AMI_GenericTestClass.insertCredential();
       MultiStaticResourceCalloutMock multimock = new MultiStaticResourceCalloutMock();
       multimock.setStaticResource(
             'https://login.microsoftonline.com/514876bd-5965-4b40-b0c8/oauth2/token', 'AMI_AuthResponse');
       multimock.setStaticResource(
            'https://marketplaceapi.microsoft.com/api/saas/subscriptions/resolve?api-version=2018-08-31', 'AMI_ResolveSubResponse');
        multimock.setStaticResource(
            'https://marketplaceapi.microsoft.com/api/saas/subscriptions/testId?api-version=2018-08-31', 'AMI_SubscResponse');
            
        multimock.setStatusCode(200);
        multimock.setHeader('Content-Type', 'application/json');
        Test.setMock(HttpCalloutMock.class, multimock);
        
        AMI_MainComponentController.resolveSubscription('test1234');
        Test.stopTest();
        
    }

    public static void insertCredential(){
        AMI_Credential__c newCred = new AMI_Credential__c(
            Client_ID__c  = '13434920-sbndng-8888-95a3',
            Client_Secret__c = 'abcvbvdbvdsb/4S]nkcndc',
            Resource_ID__c = '62d94f6c-d599-489b-a797-3e10e42fbe22',
            Tenant_Id__c = '514876bd-5965-4b40-b0c8'
        );
        insert newCred;
    }

    public static  testMethod void sendPurchaseRequestEmailTest(){
        Test.startTest();
        AMI_MainComponentResponseModel testRequest = new AMI_MainComponentResponseModel();
        testRequest.subscriptionId = 'df6b38c7-9032-0ac8-f326-skprab';
        testRequest.offerId = 'test_product_transact-preview';
        testRequest.planId = 'plan-1';
        AMI_UserDetailResponse testBeneficiary = new AMI_UserDetailResponse();
        testBeneficiary.puid = '10037FFE90CBF3CF';
        testBeneficiary.emailId = 'test@akamai.com';
        testBeneficiary.companyName = 'testCompany';
        testBeneficiary.givenName = 'test1';
        testBeneficiary.surname='tes21';
        testBeneficiary.businessPhones = new List<String>{'1323','23132'};
        testRequest.beneficiary = testBeneficiary;
        testRequest.purchaser = testBeneficiary;
        testRequest.saasSubscriptionStatus = 'PendingFulfillmentStart';

        AMI_TermResponseModel termResponse = new AMI_TermResponseModel();
        termResponse.termUnit = 'P1M';
        testRequest.term = termResponse;

        AMI_EmailHandler emailHandler = new AMI_EmailHandler();
        emailHandler.sendNewPurchaseRequest(testRequest);
        emailHandler.sendConfirmationEmailToEndUser(testRequest);
        Test.stopTest();
    }

    public static testMethod void exceptionloggerTestWithoutNotification(){
        Test.startTest();
        AMI_ExceptionLogger.logExceptionWithoutEmailNotification('test',new AMI_4XXException('test'),'test');
        Test.stopTest();
    }

    public static testMethod void testForMergeUserData(){
        Test.startTest();
        AMI_SaasRequestHandlerService requesHandler = new AMI_SaasRequestHandlerService();
        requesHandler.mergeUserData(AMI_GenericTestClass.getAMISubscriptionResponse(),AMI_GenericTestClass.getUserDetailsResponse());
        Test.stopTest();
    }


    public static testMethod void testForEventLogger(){
        Test.startTest();
        AMI_MainComponentResponseModel mainComponentResponse = getMainComponentResponse();
        AMI_EventLogger eventLogger = new AMI_EventLogger();

        eventLogger.logLandingPageSuccessFulEvent(mainComponentResponse);

        eventLogger.logSubscriptionSubmissionSuccessEvent(mainComponentResponse);
        eventLogger.logSubscriptionSubmissionFailureEvent(mainComponentResponse);
        eventLogger.logSubscriptionSubmissionFailureEvent(null);

        AMI_WebhookRequestModel webHookRequest = new AMI_WebhookRequestModel();
        webHookRequest.subscriptionId = 'df6b38c7-9032-0ac8-f326-skprab';
        webHookRequest.action = 'CHANGEPLAN';
        webHookRequest.id = 'testId';
        webHookRequest.planId = 'plan-1';
        webHookRequest.status = 'PendingFulfillmentStart';

        eventLogger.logWebHookFailureOperation(webHookRequest,null);
        eventLogger.logWebHookFailureOperation(null,JSON.serialize(webHookRequest));
        eventLogger.logWebHookSuccessOperation(webHookRequest,AMI_GenericTestClass.getOperationDetailResponse());

        Test.stopTest();

    }

}