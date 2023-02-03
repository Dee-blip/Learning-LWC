@RestResource(urlMapping='/saas/subscriptions/update/*')
global without sharing class AMI_SaasWebHookRestAPI {

    @HttpPost
    global static void updateSubscriptionStatus(){
        AMI_EventLogger eventLogger = new AMI_EventLogger();
       RestRequest req = RestContext.request;
       Blob body = req.requestBody;
       String requestString = body.toString();
       RestResponse res = RestContext.response;
       AMI_WebhookRequestModel requestData = null;
       try{
           requestData = (AMI_WebhookRequestModel)JSON.deserialize(requestString,AMI_WebhookRequestModel.class);
           AMI_SaasRequestHandlerService requestHandler = new AMI_SaasRequestHandlerService();
           AMI_OperationsDetailResponse operationDetailResponse = requestHandler.updateNewOperation(requestData);
           res.statusCode=200;
           eventLogger.logWebHookSuccessOperation(requestData,operationDetailResponse);
       }catch(Exception e){
           System.debug('exception occured while updating operation');
           eventLogger.logWebHookFailureOperation(requestData,requestString);
           res.statusCode=200;
       }
    }
}