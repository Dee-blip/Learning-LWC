/**
   @author: Nagaraj Desai
   SFDC-2587 : Formalize Partner Order Cancellation
 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj Desai    15/Apr/18        Added this class for SFDC-2587.
   =========================
   Related Test Class: PartnerOrderCancellationTriggerTestClass
 **/
public with sharing class PartnerOrderCancellation_TriggerClass {
        public PartnerOrderCancellation_TriggerClass() {
        }

        private static Boolean addAdditionalDataHasRun = false;
        private static Boolean handleEmailFunctionalityHasRun = false;

        private static User currentUser;
        private static String toAddress;
        private static String ccAddressString;

        public static User getCurrentUserDetails() {
                return [SELECT Id, ContactId, Contact.AccountId, Contact.Account.Name, Contact.Account.POA_Email_List__c FROM User WHERE Id = : UserInfo.getUserId()];
        }

        public static void setStaticVariables() {
                currentUser = getCurrentUserDetails();
                toAddress = GsmUtilClass.getPRMSettingValue('PartnerOrderCancellation_ToAddresses');
                ccAddressString = GsmUtilClass.getPRMSettingValue('PartnerOrderCancellation_CCAddresses');
        }

        public static void addAdditionalData(List<Partner_Order_Cancellation_Details__c> listOfPOCD) {
                if(addAdditionalDataHasRun) {
                        return;
                }
                setStaticVariables();

                String generalEmailRecipients = '';
                if(toAddress != null && toAddress != '') {
                        generalEmailRecipients = toAddress;
                }
                if(ccAddressString != null && ccAddressString != '') {
                        generalEmailRecipients += ', ' + ccAddressString;
                }

                for(Partner_Order_Cancellation_Details__c eachPOCD : listOfPOCD) {
                        eachPOCD.Reseller_Account__c = currentUser.Contact.AccountId;
                        String particularEmailRecipients = generalEmailRecipients;
                        if(currentUser.Contact.Account.POA_Email_List__c != null && currentUser.Contact.Account.POA_Email_List__c != '') {
                                particularEmailRecipients += ', ' + currentUser.Contact.Account.POA_Email_List__c;
                        }
                        if(eachPOCD.Opted_For_Email_Copy__c && UserInfo.getUserEmail() != null && UserInfo.getUserEmail() != '') {
                                particularEmailRecipients += ', ' + String.valueOf(UserInfo.getUserEmail());
                        }
                        eachPOCD.Email_Recipients__c = particularEmailRecipients;
                }
                addAdditionalDataHasRun = true;
        }

        public static void handleEmailFunctionality(List<Partner_Order_Cancellation_Details__c> listOfPOCD) {
                if(handleEmailFunctionalityHasRun) {
                        return;
                }
                EmailTemplate POCDTemplate = [SELECT Id FROM EmailTemplate WHERE DeveloperName = : GsmUtilClass.getPRMSettingValue('Partner_Order_Cancellation_EmailTemplate')];
                if(POCDTemplate != null) {
                        List<Messaging.SingleEmailMessage> listOfMails = new List<Messaging.SingleEmailMessage>();

                        for(Partner_Order_Cancellation_Details__c eachPOCD : listOfPOCD) {

                                String poaEmailList;
                                if(currentUser.Contact.Account.POA_Email_List__c != null && currentUser.Contact.Account.POA_Email_List__c != '') {
                                        poaEmailList = currentUser.Contact.Account.POA_Email_List__c;
                                }
                                List<String> ccAddressList = ccAddressString.Split(',');
                                if(poaEmailList != null && poaEmailList != '') {
                                        ccAddressList.addAll(poaEmailList.split(','));
                                }
                                if(eachPOCD.Opted_For_Email_Copy__c && UserInfo.getUserEmail() != null && UserInfo.getUserEmail() != '') {
                                        ccAddressList.add(UserInfo.getUserEmail());
                                }
                                Messaging.SingleEmailMessage eachMail = new Messaging.SingleEmailMessage();
                                eachMail.setTargetObjectId(currentUser.ContactId);
                                eachMail.setTreatTargetObjectAsRecipient(false);
                                eachMail.setTemplateId(POCDTemplate.Id);
                                eachMail.setToAddresses(new String[] {toAddress});
                                eachMail.setCCAddresses(ccAddressList);
                                eachMail.setWhatId(eachPOCD.Id);
                                eachMail.setSaveAsActivity(false);
                                listOfMails.add(eachMail);

                        }

                        Messaging.SendEmailResult[] resultMail = new Messaging.SendEmailResult[] {};
                        resultMail = Messaging.sendEmail(listOfMails);

                        if( resultMail.size() > 0) {
                                if (!resultMail[0].isSuccess()) {
                                        String errorMessage = 'There was some issue sending mail :' + resultMail[0].getErrors().get(0).getMessage();
                                        Error_log__c erroLog = new Error_log__c(Name = 'PartnerOrderCancellation_TriggerClass EMAIL TEMPLATE Error', Class__c = 'PartnerOrderCancellation_TriggerClass',Error_Message__c = errorMessage);
                                        insert erroLog;
                                }
                        }

                }
                else {
                        Error_log__c erroLog = new Error_log__c(Name = 'PartnerOrderCancellation_TriggerClass EMAIL TEMPLATE Error', Class__c = 'PartnerOrderCancellation_TriggerClass',Error_Message__c = 'Partner_Order_Cancellation_EmailTemplate Not Found');
                        insert erroLog;
                }

                handleEmailFunctionalityHasRun = true;
        }
}