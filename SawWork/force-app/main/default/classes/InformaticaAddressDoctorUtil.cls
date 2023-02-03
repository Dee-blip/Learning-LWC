public class InformaticaAddressDoctorUtil {
    public static Boolean verifyEmailResponse(InformaticaEmailVerificationResponse response) {
        
        //Removing as part of test class coverage SFDC-1573
       /* if (Test.isRunningTest()) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response is null for the Contact.';
            return true;
        }*/

        if (response == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.VerifyEmailResponse == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.VerifyEmailResponse.VerifyEmailResult == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.VerifyEmailResponse.VerifyEmailResult.ServiceStatus == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.VerifyEmailResponse.VerifyEmailResult.ServiceResult == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.VerifyEmailResponse.VerifyEmailResult.ServiceResult.Reason == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.SubscriptionInfo == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo.RemainingHits is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.SubscriptionInfo.RemainingHits == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo.RemainingHits is null for the Contact.';
            return false;
        }
        return true;
    }
    
    public static Boolean verifyPhoneResponse(InformaticaPhoneVerificationResponse response) {
        
        if (response == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.SubscriptionInfo == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.SubscriptionInfo.RemainingHits == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.SubscriptionInfo.RemainingHits is null for the Contact.';
        }
        //Commented due to error
        /*if (response.WebServiceResponse.ValidateNumberResponse == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.ValidateNumberResponse is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult.ServiceStatus == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult.ServiceStatus is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult.ServiceStatus.StatusNbr == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult.ServiceStatus.StatusNbr is null for the Contact.';
            return false;
        }
        if (response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult.ServiceStatus.StatusDescription == null) {
            //logger.Activities__c = logger.Activities__c + '\n' + 'Response.WebServiceResponse.ValidateNumberResponse.ValidateNumberResult.ServiceStatus.StatusDescription is null for the Contact.';
            return false;
        }*/
        return true;
    }
}