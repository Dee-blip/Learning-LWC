global without sharing class AMI_MainComponentController {

    public Static String SUCCESS ='SUCCESS';
    public Static String FAILURE ='FAILURE';
    
    @AuraEnabled
    public static String resolveSubscription(String apiToken){

        AMI_EventLogger eventLogger = new AMI_EventLogger();

        AMI_MainComponentResponseBuilder responseBuilder = new AMI_MainComponentResponseBuilder();
        try {
              System.debug('api Token is :'+apiToken);
              AMI_SaasRequestHandlerService requestHandler = new AMI_SaasRequestHandlerService();
              AMI_MainComponentResponseModel response = requestHandler.resolveSubscription(apiToken);
              String responseString = JSON.serialize(response);
              eventLogger.logLandingPageSuccessFulEvent(response);
              return responseBuilder.getUIControllerObject (AMI_MainComponentController.SUCCESS,responseString);
        } catch (Exception e) {
            eventLogger.logLandingPageFailureEvent(apiToken);
            return responseBuilder.getUIControllerObject (AMI_MainComponentController.FAILURE,responseBuilder.generateGenericExceptionObject(e));
        }
    }

    @AuraEnabled
    public static String saveSubscription(String request){
        AMI_EventLogger eventLogger = new AMI_EventLogger();
        AMI_MainComponentResponseBuilder responseBuilder = new AMI_MainComponentResponseBuilder();
        AMI_MainComponentResponseModel jsonRequest = null;
        try{
             jsonRequest = (AMI_MainComponentResponseModel) JSON.deserialize(request, AMI_MainComponentResponseModel.class);
             AMI_SaasRequestHandlerService requestHandler = new AMI_SaasRequestHandlerService();
             requestHandler.saveNewSubscription(jsonRequest);

             eventLogger.logSubscriptionSubmissionSuccessEvent(jsonRequest);
             return responseBuilder.getUIControllerObject (AMI_MainComponentController.SUCCESS,'');
        }catch(Exception e){
            eventLogger.logSubscriptionSubmissionFailureEvent(jsonRequest);
            return responseBuilder.getUIControllerObject (AMI_MainComponentController.FAILURE,responseBuilder.generateGenericExceptionObject(e));
        }
    }

    @AuraEnabled
    public static string getClientIdForAppOperations(){
        AMI_MainComponentResponseBuilder responseBuilder = new AMI_MainComponentResponseBuilder();
        try {
            String clientId = AMI_UtilClass.getAMICredentials().Client_ID__c;
            return responseBuilder.getUIControllerObject (AMI_MainComponentController.SUCCESS,clientId);
        } catch (Exception e) {
            return responseBuilder.getUIControllerObject (AMI_MainComponentController.FAILURE,responseBuilder.generateGenericExceptionObject(e));
        }
    }
}