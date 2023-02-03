global without sharing class AMI_EventLogger {
    

    public Static final String SUCCESS ='SUCCESS';
    public Static final String FAILURE ='FAILURE';

    public Static final String LANDING_PAGE_EVENT_NAME = 'LANDING_PAGE';
    public Static final String LANDING_PAGE_SUBMISSION_EVENT_NAME = 'LANDING_PAGE_SUBMISSION';
    public Static final String WEBHOOK_OPERATIONS_EVENT_NAME = 'WEBHOOK_OPERATIONS';

    public void logLandingPageSuccessFulEvent(AMI_MainComponentResponseModel mainComponentResponseModel){
        Map<String,String> eventMap = new Map<String,String>();
        eventMap.put('subscriptionName', mainComponentResponseModel.name);
        eventMap.put('Subscritpion_DETAILS', Json.serialize(mainComponentResponseModel));
        logEvent(LANDING_PAGE_EVENT_NAME, SUCCESS, mainComponentResponseModel.subscriptionId, eventMap);
    }

    public void logLandingPageFailureEvent(String apiToken){
        Map<String,String> eventMap = new Map<String,String>();
        eventMap.put('apiToken', apiToken);
        logEvent(LANDING_PAGE_EVENT_NAME, FAILURE, null, eventMap);
    }

    public void logSubscriptionSubmissionSuccessEvent(AMI_MainComponentResponseModel mainComponentResponseModel){
        Map<String,String> eventMap = new Map<String,String>();
        eventMap.put('subscriptionName', mainComponentResponseModel.name);
        eventMap.put('Subscritpion_DETAILS', Json.serialize(mainComponentResponseModel));
        logEvent(LANDING_PAGE_SUBMISSION_EVENT_NAME, SUCCESS, mainComponentResponseModel.subscriptionId, eventMap);
    }

    public void logSubscriptionSubmissionFailureEvent(AMI_MainComponentResponseModel mainComponentResponseModel){
        if(mainComponentResponseModel != null){
            Map<String,String> eventMap = new Map<String,String>();
            eventMap.put('Reason', 'Duplicate submission of id : '+mainComponentResponseModel.subscriptionId);
            logEvent(LANDING_PAGE_SUBMISSION_EVENT_NAME, FAILURE, mainComponentResponseModel.subscriptionId, eventMap);
        }else {
            Map<String,String> eventMap = new Map<String,String>();
            eventMap.put('Reason', 'NA');
            logEvent(LANDING_PAGE_SUBMISSION_EVENT_NAME, FAILURE, null, eventMap);
        }
    }

    public void logWebHookSuccessOperation(AMI_WebhookRequestModel webHookRequest,
    AMI_OperationsDetailResponse operationDetailResponse){
            Map<String,String> eventMap = new Map<String,String>();
            eventMap.put('Request_received', Json.serialize(webHookRequest));
            eventMap.put('Operation_Type', webHookRequest.action);
            eventMap.put('planId', operationDetailResponse.planId);
            eventMap.put('offerId', operationDetailResponse.offerId);
            logEvent(WEBHOOK_OPERATIONS_EVENT_NAME, SUCCESS, webHookRequest.subscriptionId, eventMap);
    }

    public void logWebHookFailureOperation(AMI_WebhookRequestModel webHookRequest,String requestInString){
    
        if(webHookRequest != null){
            Map<String,String> eventMap = new Map<String,String>();
            eventMap.put('Request_received', Json.serialize(webHookRequest));
            eventMap.put('Operation_Type', webHookRequest.action);
            logEvent(WEBHOOK_OPERATIONS_EVENT_NAME, FAILURE, webHookRequest.subscriptionId, eventMap);
        }else {
            Map<String,String> eventMap = new Map<String,String>();
            eventMap.put('Request_received', requestInString);
            logEvent(WEBHOOK_OPERATIONS_EVENT_NAME, FAILURE, null, eventMap);
        }
    }

    private void logEvent(String eventName,String status,String subscriptionId,Map<String,String> keyValuePair) {
        
        AMI_EVENTS__c event = new AMI_EVENTS__c(
            name = eventName,
            Subscription_Id__c = subscriptionId,
            STATUS__c = status
        );

        insert event;

        String insertedEventId = event.id;

        List<AMI_EVENT_DATA__c> eventDataList = new List<AMI_EVENT_DATA__c>();
        
        for(String key : keyValuePair.keySet()){
            AMI_EVENT_DATA__c eventData = new AMI_EVENT_DATA__c(
                Name = key,
                VALUE__c = keyValuePair.get(key),
                EVENT_ID__c = event.id
            );

            eventDataList.add(eventData);
        }
      
        Database.insert(eventDataList);
    }
}