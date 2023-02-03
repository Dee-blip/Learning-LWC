/* ========================================================================
    Author: Kunal Sharma
    Description: Batch Class for sending single mails for Customer Notification Application.
    Created Date : 19/MARCH/2015
    ======================================================================== */
global class EB_SingleMailBatchClass implements
    Database.Batchable<SObject>, Database.Stateful, System.Schedulable {

    global EB_AkaMailer__c objAkamMailerToUpdate;

    global final string mailerId;


    global static boolean isTestCall = System.Test.isRunningTest();
    global static boolean isFirstRun = true;

    global static string errorString = 'Class: EB_SingleMailBatchClass \n';
    global static string validateResult = '';
    global static string useOrgWideEmail = EBCS_Application__c.getInstance('SingleMailBatchJobOrgWideId').Value__c;
    global static integer batchSize = Integer.valueOf(EBCS_Application__c.getInstance('SingleMailBatchJobSize').Value__c);

    global final string queryMailerContact;


    global EB_SingleMailBatchClass(String varMailerId){

        this.mailerId = varMailerId;
        //useOrgWideEmail = EBCS_Application__c.getInstance('UseOrgWideEmailAddress').Value__c;
        this.queryMailerContact = 'SELECT EB_AkaMContact__c.Id,  EB_TemplateId__c, EB_AkaMAccount__c,' +
                                  'EB_Status__c, Email_Template__c, EB_Contact__c, ' +
                                  'EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id ' +
                                  'FROM EB_AkaMContact__c '+
                                  'WHERE (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = \'' + mailerId + '\') ' +
                                  'AND (EB_Status__c = \'New\') ' +
                                  'AND (EB_AkaMContact__c.EB_IsBCC__c=false) ' +
                                  'AND (EB_AkaMContact__c.EB_IsCC__c=false)';
    }
        
   global EB_SingleMailBatchClass(){
        this.mailerId = [SELECT Id FROM EB_AkaMailer__c WHERE EB_PickForLaterBatch__c = true LIMIT 1][0].Id;
        //useOrgWideEmail = EBCS_Application__c.getInstance('UseOrgWideEmailAddress').Value__c;
        this.queryMailerContact = 'SELECT EB_AkaMContact__c.Id,  EB_TemplateId__c, EB_AkaMAccount__c,' +
                                  'EB_Status__c, Email_Template__c, EB_Contact__c, ' +
                                  'EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id ' +
                                  'FROM EB_AkaMContact__c '+
                                  'WHERE (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = \'' + mailerId + '\') ' +
                                  'AND (EB_Status__c = \'New\') ' +
                                  'AND (EB_AkaMContact__c.EB_IsBCC__c=false) ' +
                                  'AND (EB_AkaMContact__c.EB_IsCC__c=false)';
    }

    global Database.QueryLocator start(Database.BatchableContext scope){
        system.debug('### Mailer Id' + mailerId);
        system.debug('### Mailer query' + queryMailerContact);
        system.debug('### Mailer query result' + Database.getQueryLocator(queryMailerContact));

        if(isTestCall){
            //queryMailerContact = queryMailerContact + ' LIMIT 10';
        }
        return Database.getQueryLocator(queryMailerContact);
    }

    global void execute(Database.BatchableContext bc, List<SObject> lScope){

        system.debug('## Execute' + mailerId);
        if(isFirstRun){
            isFirstRun = false;
            objAkamMailerToUpdate = [SELECT Id,EB_SendSingleMailBatchSubmitted__c,EB_SingleMailBatchJobId__c,
                                     EB_SendSingleMailBatchComplete__c, EB_OperationStatus__c, EB_BatchStatus__c,
                                     EB_OperationProcessedCount__c,EBValidationOverride__c,EB_PickForLaterBatch__c,
                                     EB_DoNotScheduleAgain__c
                                     FROM EB_AkaMailer__c WHERE Id = :mailerId];

            objAkamMailerToUpdate.EB_SendSingleMailBatchSubmitted__c = true;
            objAkamMailerToUpdate.EB_SingleMailBatchJobId__c = bc.getJobId();
            objAkamMailerToUpdate.EB_PickForLaterBatch__c = false;
            objAkamMailerToUpdate.EBValidationOverride__c = true;
            //objAkamMailerToUpdate.EB_DoNotScheduleAgain__c = false;

            try{
                update objAkamMailerToUpdate;
            }

            catch(exception e){
				EB_SingleMailBatchUtilClass.sendMailOnException(e, 'EB_SingleMailBatchClass', 'execute update objAkamMailerToUpdate');
            }
        }
            List<EB_AkaMContact__c> lContactsToSendEmail = (List<EB_AkaMContact__c>) lScope;
            EB_SingleMailBatchUtilClass.sendSingleEmailToMailerContacts(lScope, useOrgWideEmail);
     }

    global void finish(Database.BatchableContext bc){
        system.debug('##Fininsh '  + objAkamMailerToUpdate);
        if(objAkamMailerToUpdate != null){
            objAkamMailerToUpdate.EB_SendSingleMailBatchComplete__c  = true;
            objAkamMailerToUpdate.EBValidationOverride__c = true;
            objAkamMailerToUpdate.EB_OperationStatus__c = 'End';
            objAkamMailerToUpdate.EB_BatchStatus__c = 'EndOfBatch';
            objAkamMailerToUpdate.EB_OperationProcessedCount__c = 0;
            objAkamMailerToUpdate.EB_Operation__c = 'SendMails';
            objAkamMailerToUpdate.EB_PickForLaterBatch__c = false;
            //objAkamMailerToUpdate.EB_DoNotScheduleAgain__c = false;
            try{
            	update objAkamMailerToUpdate;
            }
            catch(Exception e){
                EB_SingleMailBatchUtilClass.sendMailOnException(e, 'EB_SingleMailBatchClass', 'Finish update objAkamMailerToUpdate');
            }
        }
    }

    global void execute(SchedulableContext sc){
        if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex'
            AND (Status = 'Processing' OR Status = 'Preparing') ] < 5){

            Database.executeBatch(new EB_SingleMailBatchClass(), batchSize);
        }        
    }
}