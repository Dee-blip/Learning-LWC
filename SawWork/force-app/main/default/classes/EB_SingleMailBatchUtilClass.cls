/* ========================================================================
    Author: Kunal Sharma
    Description: Util class for single email sending functionality.
    Created Date : 19/MARCH/2015
    ======================================================================== */
global class EB_SingleMailBatchUtilClass {
    public static integer batchSize = Integer.valueOf(EBCS_Application__c.getInstance('SingleMailBatchJobSize').Value__c);
    public static void sendSingleEmailToMailerContacts(List<EB_AkaMContact__c> lContactsToSendEmail,
                                                       String orgWideEmailId){
        List<Messaging.SingleEmailMessage> lContactsForSingleMail = new List<Messaging.SingleEmailMessage>();
        List<EB_AkaMContact__c> lContactsToUpdateStatus = new List<EB_AkaMContact__c>();
        List<Messaging.SendEmailResult> lSendEmailResults = new List<Messaging.SendEmailResult>();
        List<String> lBCCAddresses = new List<String>();
        List<String> lCCAddresses = new List<String>();

        for(EB_AkaMContact__c varContactToSendEmail :lContactsToSendEmail){
            Messaging.SingleEmailMessage objForSingleMail = new Messaging.SingleEmailMessage();

            varContactToSendEmail.EB_Status__c = 'In-Process';

            objForSingleMail.setTemplateId(varContactToSendEmail.EB_TemplateId__c);
            objForSingleMail.setOrgWideEmailAddressId(orgWideEmailId);
            objForSingleMail.setSaveAsActivity(false);
            objForSingleMail.setWhatId(varContactToSendEmail.Id);
            objForSingleMail.setTargetObjectId(varContactToSendEmail.EB_Contact__c);
            lCCAddresses = EB_UtilEmailNotification.getCcList(varContactToSendEmail.EB_AkaMAccount__c);
            lBCCAddresses = EB_UtilEmailNotification.getBccList(varContactToSendEmail.EB_AkaMAccount__c);


            if((lBCCAddresses!=null) && (lBCCAddresses.size() > 0)){
                objForSingleMail.setBccAddresses(lBCCAddresses);
            }

            if((lCCAddresses!=null) && (lCCAddresses.size() > 0)){
                objForSingleMail.setCcAddresses(lCCAddresses);
            }
            lContactsToUpdateStatus.add(varContactToSendEmail);
            lContactsForSingleMail.add(objForSingleMail);
        }
        try{
            update lContactsToUpdateStatus;
        }

        catch(exception e){
			sendMailOnException(e,'EB_SingleMailBatchUtilClass','sendSingleEmailToMailerContacts');
        }

        lSendEmailResults = Messaging.sendEmail(lContactsForSingleMail,false );
        Map<Id,String> mMailerContactError = getStatusOfEmailNotification(lSendEmailResults,lContactsToSendEmail);
        updateMailerContactRecs(mMailerContactError,lContactsToSendEmail);
        createExceptionRecs(mMailerContactError,lContactsToSendEmail);

    }

    public static void createExceptionRecs(Map<Id,String> mMailerContactError,
                                           List<EB_AkaMContact__c> lContactsForSingleMail){
        List<EB_MailerException__c> lMailerException = new List<EB_MailerException__c>();
        for(EB_AkaMContact__c varContactForSingleMail :lContactsForSingleMail){
            if(mMailerContactError.containsKey(varContactForSingleMail.Id)){
                EB_MailerException__c objMailerException = new EB_MailerException__c();
                objMailerException.EB_Mailer__c = varContactForSingleMail.EB_AkaMAccount__r.EB_AkaMailer__r.Id;
                objMailerException.Exception_Message__c = mMailerContactError.get(varContactForSingleMail.Id) ;
                objMailerException.EB_Type__c = 'Exception';
                lMailerException.add(objMailerException);
            }
        }
        
        try{
        	insert lMailerException;
        }
        catch(Exception e){
        	sendMailOnException(e,'EB_SingleMailBatchUtilClass','createExceptionRecs');                                                  		                               
        }
    }

    public static void updateMailerContactRecs(Map<Id,String> mMailerContactError,
                                               List<EB_AkaMContact__c> lContactsForSingleMail){
        List<EB_AkaMContact__c> lAkamContactsToUpdate = new List<EB_AkaMContact__c>();

        for(EB_AkaMContact__c varContactForSingleMail :lContactsForSingleMail){
            if(mMailerContactError.containsKey(varContactForSingleMail.Id)){
                varContactForSingleMail.EB_Status__c = 'Failed';
            }
            else{
                varContactForSingleMail.EB_Status__c = 'Processed';
            }
            lAkamContactsToUpdate.add(varContactForSingleMail);
        }
        try{                                           
        	update lAkamContactsToUpdate;
        }
        catch(Exception e){
        	sendMailOnException(e,'EB_SingleMailBatchUtilClass','updateMailerContactRecs');                                               
        }
    }

    public static Map<Id,String> getStatusOfEmailNotification(List<Messaging.SendEmailResult> lSendEmailResults,
                                                              List<EB_AkaMContact__c> lContactsForSingleMail){
        Map<Id,String> mMailerContactError = new Map<Id, String>();
        for(integer i=0; i < lSendEmailResults.size(); i++){
            if(!lSendEmailResults.get(i).success){
                mMailerContactError.put(lContactsForSingleMail.get(i).Id,lSendEmailResults.get(i).getErrors().get(0).getMessage());
            }
        }
        return mMailerContactError;
    }

    WebService static string submitBatchJob(String mailerId, boolean isRetryAttempt){
        String validateResult = '';
		System.debug('### Mailer And Retry ' + mailerId + ' ' + isRetryAttempt);
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        akamMailer = [SELECT Email_Template__r.EB_SFEmailTemplateId__c,EB_Operation__c,EB_OperationStatus__c,
                      EB_OperationProcessedCount__c,EB_CalcWarningCount__c, EB_CalcWarningMessage__c, EB_PickForLaterBatch__c,
                      EB_CountToAddresses__c, EB_DoNotScheduleAgain__c FROM EB_AkaMailer__c WHERE Id = :mailerId];

        if(akamMailer.EB_OperationProcessedCount__c == 0)
        {
            validateResult = EB_UtilEmailNotification.validateDataForSendEmail(mailerId);
        }
        if(validateResult == ''){
            if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND
                 (Status = 'Processing' OR Status = 'Preparing') ] < 5){
            	Database.executeBatch(new EB_SingleMailBatchClass(mailerId), batchSize);
            }
            
        }
        else{
            return 'The Email Id for one of the Contacts is blank OR the Email Template being used is deleted or Issue Start or End Date/Time or Akamai Impacted Product is/are missing.';
        }
        return '';
      }

 

    WebService static string changeMailerContactsStatusToFail(String mailerId){
        system.debug('### ' + System.Test.isRunningTest() + ' ' + mailerId);
	Id readOnlyRTId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('ReadOnly_SingleMail').getRecordTypeId();
        List<EB_AkaMContact__c> lMailerContactToChangeStatus = new List<EB_AkaMContact__c>();

        List<EB_AkaMailer__c> lMailerToMarkUser = new List<EB_AkaMailer__c>();
  

        lMailerToMarkUser = [SELECT Id, EB_ManuallyFailMailer__c, RecordTypeId,
                             EB_UserWhoMarkedTheMailer__c, EB_Operation__c,EB_FailedCount__c ,EB_ProcessedCount__c ,
                             EB_TotalAccounts__c ,Follow_Up__c 
                             FROM EB_AkaMailer__c WHERE Id = :mailerId];
        for(EB_AkaMailer__c objAkamMailer : lMailerToMarkUser){
            objAkamMailer.EB_ManuallyFailMailer__c = true;
        }
        try{
            update lMailerToMarkUser;
        }

        catch(Exception e){
			sendMailOnException(e,'EB_SingleMailBatchUtilClass','changeMailerContactsStatusToFail');
        }

        lMailerContactToChangeStatus = [SELECT Id, EB_Status__c,
                                        EB_AkaMAccount__r.EB_AkaMailer__r.EB_UserWhoMarkedTheMailer__c
                                        FROM EB_AkaMContact__c
                                        WHERE EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :mailerId
                                        AND EB_Status__c = 'New'];
        for(EB_AkaMContact__c objMailerContact :lMailerContactToChangeStatus){
            objMailerContact.EB_Status__c = 'Failed';
        }
        try{
            update lMailerContactToChangeStatus;
        }

        catch(Exception e){
			sendMailOnException(e,'EB_SingleMailBatchUtilClass','changeMailerContactsStatusToFail');
        }
		Integer failedAccount = [SELECT count() FROM EB_AkaMAccount__c WHERE EB_AkaMailer__r.Id = :mailerId 
                                 AND EB_Status__c = 'Failed'];
        
        for(EB_AkaMailer__c objAkamMailer : lMailerToMarkUser){
            objAkamMailer.EB_ManuallyFailMailer__c = true;
            objAkamMailer.EB_UserWhoMarkedTheMailer__c = UserInfo.getUserId();
            objAkamMailer.EBValidationOverride__c = true;
            objAkamMailer.EB_Operation__c = 'SendMails';
            objAkamMailer.EB_FailedCount__c = failedAccount;
            objAkamMailer.RecordTypeId = readOnlyRTId;
            system.debug('### Details ' + objAkamMailer);
			//system.assertEquals(1, 2);
        }
        try{
            update lMailerToMarkUser;
        }

        catch(Exception e){
			sendMailOnException(e,'EB_SingleMailBatchUtilClass','changeMailerContactsStatusToFail');
        }

        return '';
    }
    
    public static void sendMailOnException(Exception exceptionMessage, 
                                    String className, String methodName){
        List<String> lEmailAddress = new List<String>{'sc-dev@akamai.com'};
        String subject = 'Exception in Class ' + className + ' :: ' + methodName ;
        String bodyOfEmail = exceptionMessage.getMessage() + '\n' + exceptionMessage.getStackTraceString();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(lEmailAddress);
        mail.subject = subject;
        mail.plainTextBody = bodyOfEmail;
        List<Messaging.SendEmailResult> lResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
    }

}