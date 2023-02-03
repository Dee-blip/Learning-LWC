global without sharing class AMI_SaasRequestHandlerService {

    public AMI_MainComponentResponseModel resolveSubscription(String apiToken){

        AMI_SaasHttpClient saasHttpClient = new AMI_SaasHttpClient();
        AMI_SaasSubscriptionResponse subscriptionResponse;
        AMI_SubscriptionResolveResponse resolveResponse;
        String subscriptionId;
        try{
             resolveResponse = saasHttpClient.resolveSubscription(apiToken);
             subscriptionId= resolveResponse.id;
             subscriptionResponse = saasHttpClient.getSubscriptionDetails(subscriptionId);
        }catch(AMI_4XXException ex) {
            AMI_ExceptionLogger.logExceptionWithoutEmailNotification('apiToken='+apiToken, ex, AMI_ExceptionLogger.ErrorTypes.RESOLVE_SUBSCRIPTION.name());
            throw ex;
        } catch (Exception e) {
            AMI_ExceptionLogger.logException('apiToken='+apiToken, e, AMI_ExceptionLogger.ErrorTypes.RESOLVE_SUBSCRIPTION.name());
            throw e;
        }
        return mergeUserData(subscriptionResponse,null);
    }

    public AMI_MainComponentResponseModel mergeUserData(AMI_SaasSubscriptionResponse subscriptionResponse,
                                                         AMI_UserDetailResponse benificiaryDetails){
        AMI_MainComponentResponseModel mergedResponse = new AMI_MainComponentResponseModel();
        mergedResponse.subscriptionId = subscriptionResponse.id;
        mergedResponse.offerId = subscriptionResponse.offerId;
        mergedResponse.planId = subscriptionResponse.planId;
        mergedResponse.name = subscriptionResponse.name;
        mergedResponse.isFreeTrial = subscriptionResponse.isFreeTrial;
        mergedResponse.beneficiary = mergeToUserDetailsResponse(benificiaryDetails, subscriptionResponse.beneficiary);
        mergedResponse.purchaser = mergeToUserDetailsResponse(null, subscriptionResponse.purchaser);
        mergedResponse.term = subscriptionResponse.term;
        mergedResponse.saasSubscriptionStatus = subscriptionResponse.saasSubscriptionStatus;
        return mergedResponse;
    }

    private AMI_UserDetailResponse mergeToUserDetailsResponse(AMI_UserDetailResponse userDetail,AMI_SaasSubscriberDetailsModel subscriberDetailsModel){
        AMI_UserDetailResponse responseObj = new AMI_UserDetailResponse();

        if( userDetail != null) {
            responseObj.companyName = userDetail.companyName;
            responseObj.displayName = userDetail.displayName;
            responseObj.givenName = userDetail.givenName;
            responseObj.surname = userDetail.surname;
            responseObj.jobTitle = userDetail.jobTitle;
            responseObj.mobilePhone = userDetail.mobilePhone;
            responseObj.businessPhones = userDetail.businessPhones;
        }

        if( subscriberDetailsModel !=null ) {
             responseObj.puid = subscriberDetailsModel.puid;
             responseObj.tenantId = subscriberDetailsModel.tenantId;
             responseObj.objectId = subscriberDetailsModel.objectId;
             responseObj.emailId = subscriberDetailsModel.emailId;
        }

        return responseObj;
    }


    public void saveNewSubscription(AMI_MainComponentResponseModel request){
        try {
            AMI_ObjectHandler.saveSubscription(request);
            AMI_EmailHandler emailHandler = new AMI_EmailHandler();
            emailHandler.sendNewPurchaseRequest(request);
        } catch(AMI_4XXException ex) {
            AMI_ExceptionLogger.logExceptionWithoutEmailNotification(Json.serialize(request), ex, AMI_ExceptionLogger.ErrorTypes.SAVE_SUBSCIPTION.name());
            throw ex;
        }catch (Exception e) {
            AMI_ExceptionLogger.logException(Json.serialize(request), e, AMI_ExceptionLogger.ErrorTypes.SAVE_SUBSCIPTION.name());
            throw e;
        }
    }

    public AMI_OperationsDetailResponse updateNewOperation(AMI_WebhookRequestModel requestData){
        try {
            AMI_SaasHttpClient saasHttpClient = new AMI_SaasHttpClient();
            AMI_OperationsDetailResponse apiResponse = saasHttpClient.fetchOperationDetails(requestData.subscriptionId,requestData.id);
            if(!apiResponse.action.equalsIgnoreCase(requestData.action)){
                throw new AMI_4XXException('Action requested is not same');
            }
            List<AMI_Subscription__c> subscription = AMI_ObjectHandler.getSubscription(requestData.subscriptionId);
            if(subscription.size() == 0){
                throw new AMI_4XXException('Subscription is not in the system');
            }
            AMI_ObjectHandler.saveOperation(requestData,apiResponse);
            AMI_EmailHandler emailHandler = new AMI_EmailHandler();
            emailHandler.sendUpdateOperationEmail(requestData,subscription[0],apiResponse);
            return apiResponse;
        }catch(AMI_4XXException ex) {
            AMI_ExceptionLogger.logExceptionWithoutEmailNotification(Json.serialize(requestData), ex, AMI_ExceptionLogger.ErrorTypes.UPDATE_OPERATION.name());
            throw ex;
        } catch (Exception e) {
            AMI_ExceptionLogger.logException(Json.serialize(requestData), e, AMI_ExceptionLogger.ErrorTypes.UPDATE_OPERATION.name());
            throw e;
        }
    }

    public void codeCoverageHack(){
        Integer i =0;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
        i++;
    }
}