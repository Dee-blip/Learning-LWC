global without sharing class AMI_EmailHandler {
    public static String NEW_PURCHASE_TEMPLATE_NAME = 'NEW PURCHASE REQUEST';

    public static String ACKNOWLEDGEMENT_EMAIL_TEMPLATE_NAME = 'ACKNOWLEDGMENT EMAIL';

    public static String AKAMAI_MARKETPLACE_ADDRESS = AMI_UtilClass.getAMISettingValue('emailSender');

    public static String recipentAddress = AMI_UtilClass.getAMISettingValue('emailRecipients');

    public void sendNewPurchaseRequest(AMI_MainComponentResponseModel request){
       EmailTemplate template = getEmailTemplateObject(NEW_PURCHASE_TEMPLATE_NAME);
       String mobileNumber = request.beneficiary.mobilePhone;
       if(mobileNumber == null || mobileNumber == '') {
           mobileNumber='N/A';
       }
       Boolean freeTrial = request.isFreeTrial;
       String freeTrialIncluded;
       if(freeTrial == null || !freeTrial){
          freeTrialIncluded='NO';
       }else {
          freeTrialIncluded='YES';
       }
       List<Object> parameters = new List<Object>
       {
       request.offerId,
       request.planId,
       request.subscriptionId,
       request.beneficiary.companyName,

       request.beneficiary.givenName,
       request.beneficiary.surname,
       request.beneficiary.emailId,
       request.beneficiary.jobTitle,
       mobileNumber,
       String.join(request.beneficiary.businessPhones, ','),
       request.beneficiary.streetAddress,
       request.beneficiary.city,
       request.beneficiary.state,
       request.beneficiary.country,
       request.beneficiary.postalCode,
       request.term.termUnit,
       request.name,
       freeTrialIncluded} ;
       String body = String.format(template.htmlvalue, parameters);
       sendEmailGeneric(template.subject,body);
       sendConfirmationEmailToEndUser(request);
    }

    public void sendConfirmationEmailToEndUser(AMI_MainComponentResponseModel request) {
        EmailTemplate template = getEmailTemplateObject(ACKNOWLEDGEMENT_EMAIL_TEMPLATE_NAME);
        String name = request.beneficiary.givenName + ' '+request.beneficiary.surname;
        name=name.trim();
        List<Object> parameters = new List<Object>
       {name,
       request.name};
       String body = String.format(template.htmlvalue, parameters);

       List<Object> subjectParameters = new List<Object>{request.name};
       String subject = String.format(template.subject, subjectParameters);
        sendAcknolwedgementEmail(subject,body,request);
    }

    public void sendUpdateOperationEmail(AMI_WebhookRequestModel requestData,AMI_Subscription__c subscription,
                                               AMI_OperationsDetailResponse operationResponse){
        EmailTemplate template = getEmailTemplateObject(requestData.action.toUpperCase() +' REQUEST');
        List<Object> parameters = new List<Object>
       {requestData.subscriptionId,
       operationResponse.offerId,
       operationResponse.planId,
       subscription.company__c,
       requestData.id};
       String body = String.format(template.htmlvalue, parameters);
       sendEmailGeneric(template.subject,body);
    }

    public static EmailTemplate getEmailTemplateObject(String name){
        return [select id,name,subject,body,htmlvalue from EmailTemplate where name =:name];
    }

    public static void sendEmailGeneric(String subject,String body) {
        List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setToAddresses(recipentAddress.split(';'));
        mailingList.add(mail);
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mailingList);
    }

    public static void sendAcknolwedgementEmail(String subject,String body,AMI_MainComponentResponseModel request){

        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :AKAMAI_MARKETPLACE_ADDRESS];

        List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject(subject);
        mail.setHtmlBody(body);
        mail.setToAddresses(new List<String> {request.beneficiary.emailId});
        mailingList.add(mail);
        if ( owea.size() > 0 ) {
            mail.setOrgWideEmailAddressId(owea.get(0).Id);
         }
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mailingList);
    }
}