/**
* Generic email class to simplify email creation for other classes
* Test Class: 
* @author  Shashank Hegade
* @version 1.0
* @since   2020-09-09
*/

public without sharing class CPQ_SendEmailHelper {

    private Messaging.SingleEmailMessage message{private get; private set;}

    public class MailingInfo {

        public String subject;
        public String body;
        public List<string> toAddressList;

        public MailingInfo( String sub, String bodyInfo, List<String> toAddresses){
            subject = sub;
            body = bodyInfo;
            toAddressList = toAddresses;
        }
        
    }

    public CPQ_SendEmailHelper(String templateName, Id mergeId, List<String> toAddressesList) {

        EmailTemplate[] emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
                                       FROM EmailTemplate 
                                       WHERE name LIKE :templateName LIMIT 1];

        User targetUser = [SELECT Id, Name , Alias FROM User where Alias =:CPQ_Generic_Settings__c.getValues('targetUserAlias').CPQ_Value__c LIMIT 1];
        
        message = new Messaging.SingleEmailMessage();
        message.setTemplateId(emailTemplate[0].Id);
        message.setTargetObjectId(targetUser.Id);
        message.setSaveAsActivity(false);
        message.setToAddresses(toAddressesList);
        message.setTreatTargetObjectAsRecipient(false);
        message.setWhatId(mergeId);
    }

    public CPQ_SendEmailHelper( MailingInfo mailContent,Boolean isHtmlBody){

        message = new Messaging.SingleEmailMessage();
        message.toAddresses = mailContent.toAddressList;
        message.subject = mailContent.subject;
        if(isHtmlBody){
            message.htmlbody = mailContent.body;
        }
        else {
            message.plaintextbody = mailContent.body;
        }

    }

    public CPQ_SendEmailHelper(){
        message = new Messaging.SingleEmailMessage();
    }

    public Messaging.SingleEmailMessage getMessageObject(){
        return message;
    }
    public Messaging.SendEmailResult[] sendTheEmail(){
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results;
        try{
            results =  Messaging.sendEmail(messages, false);
        }
        catch(Exception e){
            CPQ_LogException newError = new CPQ_LogException('CPQ_SendEmailHelper: Error in sendTheEmail method', e).createErrorRecord(true);
        }
        return results;
    }

    public CPQ_SendEmailHelper setDefaultOrgWideId(set<string> emailId){

        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address IN:emailId];
        if ( owea.size() > 0 ) {
            message.setOrgWideEmailAddressId(owea.get(0).Id);
        }
        return this;
    }

    @future
    public static void sendTemplateBasedEmails(String templateName, List<Id> mergeIds, List<String> toAddressesList){

        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        EmailTemplate[] emailTemplate = [SELECT Id,Subject,Description,HtmlValue,DeveloperName,Body 
        FROM EmailTemplate 
        WHERE name LIKE :templateName LIMIT 1];

        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address IN:CPQSettings.getValues('defaultOrgWideEmail')];

        User targetUser = [SELECT Id, Name , Alias FROM User where Alias =:CPQSettings.getValue('targetUserAlias') LIMIT 1];

        for(Id item: mergeIds){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            if ( owea.size() > 0 ) {
                message.setOrgWideEmailAddressId(owea.get(0).Id);
            }
            message.setTemplateId(emailTemplate[0].Id);
            message.setTargetObjectId(targetUser.Id);
            message.setToAddresses(toAddressesList);
            message.setSaveAsActivity(false);
            message.setTreatTargetObjectAsRecipient(false);
            message.setWhatId(item);
            messages.add(message);
        }
        try{
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages, false);
        }
        catch(Exception e){
            CPQ_LogException newError = new CPQ_LogException('CPQ_SendEmailHelper: Error in sendTemplateBasedEmails method', e).createErrorRecord(true);
        }
    }

    public class FlowRequest{

        @invocableVariable
        public String body;

        @invocableVariable
        public String subject;

        @invocableVariable
        public Boolean isHtmlBody;

        @invocableVariable
        public List<String> toAddressList;

    }

    public class FlowResponse {

        @invocableVariable
        public Boolean isSuccess;
        
        @invocableVariable
        public String message;
        
    }


    @invocableMethod(label = 'Send Email')
    public static List<FlowResponse> sendEmail(List<FlowRequest> requests){

        List<FlowResponse> responseList = new List<FlowResponse>();
        List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
        for (FlowRequest curRequest : requests){
            MailingInfo emailContent = new MailingInfo( curRequest.subject, curRequest.body, curRequest.toAddressList);
            Messaging.SingleEmailMessage message = new CPQ_SendEmailHelper(emailContent, curRequest.isHtmlBody).getMessageObject();
            mailList.add(message);
        }
        if (mailList != NULL && mailList.size() > 0){
            try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(mailList,false);

                FlowResponse thisResponse = new FlowResponse();
                thisResponse.isSuccess = true;
                thisResponse.message = 'Email Sent Successfully!!!';
                responseList.add(thisResponse);

            } catch (Exception e){
                FlowResponse thisResponse = new FlowResponse();

                thisResponse.isSuccess = false;
                thisResponse.message = e.getMessage();
                responseList.add(thisResponse);

                CPQ_LogException newError = new CPQ_LogException('CPQ_SendEmailHelper: Error in SendEmail method', e).createErrorRecord(true);
                
            }
        }

        return responseList;

    }
}