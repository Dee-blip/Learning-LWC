global without sharing class AMI_ObjectHandler {

    public static string PURCHASE_OPERATION = AMI_UtilClass.getAMISettingValue('PurchaseOperation');

    public static List<AMI_Subscription__c> getSubscription(String subscriptionId){
        List<AMI_Subscription__c> result = [SELECT id,name,subscription_id__c, offer_id__c,plan_id__c,beneficiary_id__c,purchaser_id__c,beneficiary_email__c,purchaser_email__c,status__c,company__c FROM AMI_Subscription__c where subscription_Id__c = :subscriptionId ];
        return result;
    }

    public static void saveOperation(AMI_WebhookRequestModel requestData,AMI_OperationsDetailResponse operationResponse ){
        AMI_Subscription__c subscriptionObject = getSubscription(requestData.subscriptionId)[0];
        AMI_Operation__c operation = new AMI_Operation__c(
            Action__c = requestData.action,
            Subscription_Id__c = subscriptionObject.id,
            Operation_Id__c = requestData.id,
            Plan_Id__c = operationResponse.planId,
            Status__c = operationResponse.status,
            name = requestData.id
        );

        insert operation;
    }

    public static void saveSubscription(AMI_MainComponentResponseModel request){
        AMI_Subscription__c subscription = new AMI_Subscription__c(
            name = request.subscriptionId,
            subscription_id__c = request.subscriptionId,
            offer_id__c = request.offerId,
            plan_id__c = request.planId,
            beneficiary_id__c = request.beneficiary.puid,
            purchaser_id__c = request.purchaser.puid,
            beneficiary_email__c = request.beneficiary.emailId,
            purchaser_email__c = request.purchaser.emailId,
            status__c = request.saasSubscriptionStatus,
            company__c = request.beneficiary.companyName,
            Free_Trial_Included__c=request.isFreeTrial
        );

        insert subscription;

        AMI_Operation__c operation = new AMI_Operation__c(
            Action__c = PURCHASE_OPERATION,
            Subscription_Id__c = subscription.id,
            Plan_Id__c = request.planId,
            Status__c = request.saasSubscriptionStatus
        );

        insert operation;
    }
}