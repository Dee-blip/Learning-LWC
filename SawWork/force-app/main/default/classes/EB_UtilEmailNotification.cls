/*
Author: Jayalakshmi A
Description: Contains methods to Send single/mass emails,send mails to individual contacts,
             to create the cc/Bcc List, method to validate everything before sending a mail(checks if all addresses are cc/Bcc)
Modified: 1)On 1/9/2010 by janantha for CR# 785433
            Change: Commented the validateDataForSendEmail function and moved SOQL for setting the orgWideEmailId outside the loop. (sendMails function).
          2)On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
          3)On 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
          4)on 3/21/2011 by janantha for sending emails to all the Contacts belonging to a particular
            Mailer using action poller in order to avoid multiple clicks to the Send Emails button. CR#967107
          5)on 08/25/2011 by janantha for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001
          6)on 11/11/11 by janantha for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function.
            CR 1367516
          7)on 11/11/11 by janantha for Lighter Foot Print Mass Mails CR# 1383743
          8)On 28/08/2013 by ssawhney for adding validation exception for missing issue date start/end times and impacted product
            for non blank templates CR 2308403 
*/

global class EB_UtilEmailNotification
{     
    
    static List<EB_AkaMContact__c> bccCcContactRecords= new List<EB_AkaMContact__c>(); 
    static Map<Id, String> objMapCCEmailIds = new Map<Id, String>();
    static Map<Id, String> objMapBCCEmailIds = new Map<Id, String>();
   
    public static Boolean UpdatedIncident=False;
    
    
    //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
   /* webservice static void loadCcList(List<String> accountIds)
    {
        String strTemp;
        for(EB_AkaMContact__c eb_contact:[select EB_Email_Id__c,EB_Status__c, EB_AkaMAccount__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_AkaMContact__c.EB_IsBCC__c=false) and (EB_AkaMContact__c.EB_IsCC__c=true)) ] ){
            strTemp = '';
            if (objMapCCEmailIds.containsKey(eb_contact.EB_AkaMAccount__c) == true){
                strTemp = objMapCCEmailIds.remove(eb_contact.EB_AkaMAccount__c);
            }
            strTemp = strTemp + ',' + eb_contact.EB_Email_Id__c;
            objMapCCEmailIds.put(eb_contact.EB_AkaMAccount__c, strTemp);
        }
    }

    webservice static void loadBccList(List<String> accountIds)
    {
        String strTemp;
        for(EB_AkaMContact__c eb_contact:[select EB_Email_Id__c,EB_Status__c, EB_AkaMAccount__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_AkaMContact__c.EB_IsBCC__c=true) and (EB_AkaMContact__c.EB_IsCC__c=false)) ] ){
            strTemp = '';
            if (objMapBCCEmailIds.containsKey(eb_contact.EB_AkaMAccount__c) == true){
                strTemp = objMapBCCEmailIds.remove(eb_contact.EB_AkaMAccount__c);
            }
            strTemp = strTemp + ',' + eb_contact.EB_Email_Id__c;
            objMapBCCEmailIds.put(eb_contact.EB_AkaMAccount__c, strTemp);
        }
    }*/
    //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
    
    
    
    //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
    webservice static void loadCcBccList(List<String> accountIds)
    //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
    {
        String strTempCc;
        
        //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        for(EB_AkaMContact__c eb_contact:[select EB_IsCC__c, EB_IsBCC__c, EB_Email_Id__c,EB_Status__c, EB_AkaMAccount__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and ((EB_AkaMContact__c.EB_IsBCC__c=true) or (EB_AkaMContact__c.EB_IsCC__c=true))) ] ){
        //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            if(eb_contact.EB_IsCC__c == true)
            {
                strTempCc = '';
                if (objMapCCEmailIds.containsKey(eb_contact.EB_AkaMAccount__c) == true){
                    strTempCc = objMapCCEmailIds.remove(eb_contact.EB_AkaMAccount__c);
                }
                strTempCc = strTempCc + ',' + eb_contact.EB_Email_Id__c;
                objMapCCEmailIds.put(eb_contact.EB_AkaMAccount__c, strTempCc);
            }
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            if(eb_contact.EB_IsBCC__c == true)
            {
                String strTempBcc;
                for(EB_AkaMContact__c eb_contact1:[select EB_Email_Id__c,EB_Status__c, EB_AkaMAccount__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_AkaMContact__c.EB_IsBCC__c=true) and (EB_AkaMContact__c.EB_IsCC__c=false)) ] ){
                    strTempBcc = '';
                    if (objMapBCCEmailIds.containsKey(eb_contact1.EB_AkaMAccount__c) == true){
                    strTempBcc = objMapBCCEmailIds.remove(eb_contact1.EB_AkaMAccount__c);
                    }
                    strTempBcc = strTempBcc + ',' + eb_contact1.EB_Email_Id__c;
                    objMapBCCEmailIds.put(eb_contact1.EB_AkaMAccount__c, strTempBcc);
                }
            }
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        }
    }
    
    webservice static List<String> getCcList(String strAccountId)
    {
        List<String> ccEmailIds;  
        String strCCList = '';
        if (objMapCCEmailIds.size() > 0){
            strCCList = objMapCCEmailIds.get(strAccountId);
            if (strCCList != null){
                strCCList = strCCList.substring(1);
                ccEmailIds = strCCList.split(',');
            }
        }
        
        return ccEmailIds;
    }
    
    webservice static List<String> getBccList(String strAccountId)
    {
        List<String> BccEmailIds;  
        String strBCCList = '';
        if (objMapBCCEmailIds.size() > 0){
            strBCCList = objMapBCCEmailIds.get(strAccountId);
            if (strBCCList != null){
                strBCCList = strBCCList.substring(1);
                BccEmailIds = strBCCList.split(',');
            }
        }
        return BccEmailIds;
    }
    /* ==============================================================================================
    descripion: this function performs validation checks before sending single mails and mass mails. 
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :on 6/-/2010 
        2.Modified :on 8/-/2010 by janantha commented out the function for raising Salesforce governer's limits for CR# 785433.
        3.Modified:on 9/8/2010 by janantha for checking if the Email Id of a contact is blank for CR# 791787
        4.Modified: on 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
        5.on 11/11/11 by janantha for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function.
          CR 1367516
        6.Modified On 28/08/2013 by ssawhney for adding validation exception for missing issue date start/end times and impacted product
          for non blank templates CR 2308403 
    code review:
    =================================================================================================== */
    webservice static String validateDataForSendEmail(String strMailerId)
    {
        //start of change on 9/8/2010 by janantha for checking if the Email Id of a contact is blank for CR# 791787
        String strExceptionMessage='';
        //start of changes on 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
        List<String> existingTemplateIds = new List<String>();
        List<EB_AkaMContact__c> deletedTemplateIds = new List<EB_AkaMContact__c>();
        List<EB_AkaMContact__c> empty = new List<EB_AkaMContact__c>();
        List<EB_AkaMailer__c> emptyMailer = new List<EB_AkaMailer__c>();
        String mailerType;
        List<EB_AkaMailer__c> deletedMassMailTemplate = new List<EB_AkaMailer__c>();
        //start of changes on 28/08/2013 by ssawhney for checking the issue start/end date, impacted product is blank for CR# 2308403 
        EB_AkaMailer__c  mailer;
        List<String> blankEmailTemplateIds = new List<String>();
        List<EB_AkaMContact__c> nonBlankTemplateIds = new List<EB_AkaMContact__c>();
        List<EB_AkaMailer__c> nonBlankMassMailTemplate = new List<EB_AkaMailer__c>();
        
        //List<EmailTemplate> emailTemplates = [select Id from EmailTemplate WHERE isActive = true];
        
        /*for(EmailTemplate template:[select Id from EmailTemplate])
        {
            existingTemplateIds.add(template.Id);
        }*/
        for(EmailTemplate template:[select Id, Name from EmailTemplate WHERE isActive = true])
        {
            existingTemplateIds.add(template.Id);
            if(template.Name.startsWithIgnoreCase('Blank'))
            {
                blankEmailTemplateIds.add(template.Id);
            }
        }

        //mailerType = [select EB_Type__c from EB_AkaMailer__c where Id = :strMailerId].EB_Type__c;        
        mailer = [select EB_Type__c, EB_IssueEndDateTime__c, EB_IssueStartDateTime__c, EB_ImpactedAkamaiProduct__c
                                     from EB_AkaMailer__c where Id = :strMailerId];
        mailerType  = mailer.EB_Type__c;
        
        if(mailerType == 'Single Email')
        {
            deletedTemplateIds = [select EB_TemplateId__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId) and (EB_TemplateId__c not in :existingTemplateIds) and (EB_TemplateId__c!='' and EB_TemplateId__c!=null)];
            //deletedTemplateIds = [select EB_TemplateId__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId) and (Email_Template__r.EB_SFEmailTemplateId__c not in (select Id from EmailTemplate))];
            if(deletedTemplateIds != null && deletedTemplateIds != empty)
            {
                strExceptionMessage = 'The Email Template being used is deleted.';
            }
            nonBlankTemplateIds = [select EB_TemplateId__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId) and (EB_TemplateId__c not in :blankEmailTemplateIds) and (EB_TemplateId__c!='' and EB_TemplateId__c!=null)];
            if(nonBlankTemplateIds != null && nonBlankTemplateIds.size() > 0 && (mailer.EB_IssueEndDateTime__c == null
                || mailer.EB_IssueStartDateTime__c == null || mailer.EB_ImpactedAkamaiProduct__c == null ||
                mailer.EB_ImpactedAkamaiProduct__c == '') )
            {
               strExceptionMessage = 'Issue Start/End Date/Time and Impacted Product are mandatory for Sending Emails.';
            }
        }
        else if(mailerType == 'Mass Email')
        {
            deletedMassMailTemplate = [select Email_Template__r.EB_SFEmailTemplateId__c from EB_AkaMailer__c where (Id = :strMailerId) and (Email_Template__r.EB_SFEmailTemplateId__c not in :existingTemplateIds) and (Email_Template__r.EB_SFEmailTemplateId__c!='' and Email_Template__r.EB_SFEmailTemplateId__c!=null)];
            if(deletedMassMailTemplate != null && deletedMassMailTemplate != emptyMailer)
            {
                strExceptionMessage = 'The Email Template being used is deleted.';
            }
            nonBlankMassMailTemplate = [Select Email_Template__r.EB_SFEmailTemplateId__c from EB_AkaMailer__c where (Id = :strMailerId) and (Email_Template__r.EB_SFEmailTemplateId__c not in :blankEmailTemplateIds) and (Email_Template__r.EB_SFEmailTemplateId__c!='' and Email_Template__r.EB_SFEmailTemplateId__c!=null)];
            if(nonBlankMassMailTemplate != null && nonBlankMassMailTemplate.size() > 0 && (mailer.EB_IssueEndDateTime__c == null
                || mailer.EB_IssueStartDateTime__c == null || mailer.EB_ImpactedAkamaiProduct__c == null) )
            {
                strExceptionMessage = 'Issue Start/End Date/Time and Impacted Product are mandatory for Sending Emails.';
            }
        }
        //end of changes on 28/08/2013 by ssawhney for checking the issue start/end date, impacted product is blank for CR# 2308403 
        //end of changes on 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
        for(EB_AkaMContact__c eb_contact:[select EB_AkaMContact__c.Id, EB_TemplateId__c, EB_AkaMAccount__c,EB_Email_Id__c, EB_Status__c, Email_Template__c, EB_Contact__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId and EB_Email_Id__c = '')])
        {
            if(eb_contact!=null)
            {
                strExceptionMessage = 'Email Id field is blank';
            }
        }
        return strExceptionMessage;
        //end of change on 9/8/2010 by janantha for checking if the Email Id of a contact is blank for CR# 791787
        //Start of change on 1/9/2010 by janantha for CR# 785433 for raising Salesforce governer's limits
       /* String strExceptionMessage='';
        Integer flag = 0;
        Boolean blnAccountExists = false;
        //Boolean blnReturnVal = true;
    
        try
        {
            //fetch all the account records for the mailer with mailer id:strMailerId
            for(EB_AkaMAccount__c eb_account:[select EB_AkaMAccount__c.Id,  EB_AkaMailer__c, EB_Status__c, Email_Template__c from EB_AkaMAccount__c where EB_AkaMAccount__c.EB_AkaMailer__r.Id = :strMailerId])
            { 
                blnAccountExists = true;
                AggregateResult[] aggResult1 = [select count(EB_AkaMContact__c.Id)count1 from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.Id = :eb_account.Id)];
                if((Integer)aggResult1[0].get('count1') == 0) 
                {
                    strExceptionMessage = 'There must be atleast one contact per account';
                    return strExceptionMessage;
                }
                AggregateResult[] aggResult = [select count(Id)count2 from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.Id = :eb_account.Id) AND ((EB_IsBCC__c = false) AND (EB_IsCC__c = false))];
                if((Integer)aggResult[0].get('count2') == 0) 
                {
                    strExceptionMessage = 'All contacts cannot be cc or bcc';
                    return strExceptionMessage;
                }
            }
            
            if (blnAccountExists == false){
                strExceptionMessage = 'There must be atleast one account per mailer';
                return strExceptionMessage;
            }
        }
        catch(Exception e)
        {
            return e.getMessage(); 
        }
        return strExceptionMessage;*/
    }
    
    //End of change on 1/9/2010 by janantha for CR# 785433 for raising Salesforce governer's limits
    
    /* ==============================================================================================
    descripion: this function sends mail to all contacts in the mailer. 
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
        2.Modified : 8/26/2010 by janantha for providing from email id and reply to email id through orgWideEmailAddress.
        3.Modified : 1/9/2010 by janantha for CR# 785433 for raising Salesforce governer's limits
        4.Modified : 9/6/2010 by janantha for displaying alert messages if email limit is reached and other exceptions for CR# 791787.
        5.Modified: 9/8/2010 by janantha for checking if the Email Id of a contact is blank for CR# 791787.
        6.Modified: 9/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
        7.on 11/11/11 by janantha for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function.
          CR 1367516
    code review:
    =================================================================================================== */
    webservice static String sendMails(String strMailerId)
    { 
        //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        String validateResult = '';
        akamMailer = [select EB_Operation__c, EB_OperationStatus__c, EB_OperationProcessedCount__c, EB_CountToAddresses__c, EB_CalcWarningCount__c, EB_CalcWarningMessage__c, 
                      EB_EmailSentToOwner__c from EB_AkaMailer__c where Id = :strMailerId];
        if(akamMailer.EB_OperationProcessedCount__c == 0)
        {
        
            //start of changes on 9/8/2010 by janantha for checking if the Email Id of a contact is blank for CR# 791787
            validateResult = validateDataForSendEmail(strMailerId);
        }
        //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        if(validateResult == '')
        {
        //end of changes on 9/8/2010 by janantha for checking if the Email Id of a contact is blank for CR# 791787
            Integer exceptionFlag = 0;
            //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
            //List<EB_AkaMAccount__c> accountRecords = new List<EB_AkaMAccount__c>(); 
            //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
            List<EB_AkaMContact__c> contactRecords = new List<EB_AkaMContact__c>();
            List<String> accountIds = new List<String>();
            List<String> templateName = new List<String>();
            List<String> targetObjectIds = new List<String>();
            List<String> ccAddresses = new List<String>();
            List<String> bccAddresses = new List<String>();
            Messaging.SendEmailResult[] objListResult = new List<Messaging.SendEmailResult>();
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Integer i = 0;
            List<EB_AkaMailer__c> mailerTemp = new List<EB_AkaMailer__c>();
            List<EB_AkaMAccount__c> accountTemp = new List<EB_AkaMAccount__c>();
            List<EB_AkaMContact__c> contactTemp = new List<EB_AkaMContact__c>();
            Map<String,Boolean> objEmailErrorsMap = new Map<String,Boolean>();
            Map<String,Boolean> objErrorAccountMap = new Map<String,Boolean>();
            String strTargetObjId;
            String strTemplateName;
            String strTemplateId;
            String strWhatId;
            Messaging.Singleemailmessage objEmail;
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c objMailer;
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            String strExceptionMessage = '';
            List<EB_MailerException__c> mailerExceptionList = new List<EB_MailerException__c>(); 
            Integer k;
            EB_AkaMContact__c objTempContact;   
            String orgWideEmailId='';         
            EB_MailerException__c mailerException = new EB_MailerException__c();
            String useOrgWideEmail;
            String displayName;
            String displayNameReplyTo;
            String orgWideEmailIdReplyTo='';
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            List<Messaging.SendEmailError> emptyList = new List<Messaging.SendEmailError>(); 
            //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
            Integer recordsExists = -1;
            Integer numberOfRecordsProcessed = 0;
            objListResult.clear();
            Integer batch_Size;
            Integer processedFlag = 0; 
            //fetch all the account records for the mailer with mailer id:strMailerId
           /* for(EB_AkaMAccount__c eb_account:[select EB_AkaMAccount__c.Id,  EB_AkaMailer__c, EB_Status__c, Email_Template__c from EB_AkaMAccount__c where EB_AkaMAccount__c.EB_AkaMailer__r.Id = :strMailerId])
            { 
                accountRecords.add(eb_account);
                accountIds.add(eb_account.Id);
            }*/
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //akamMailer = [select EB_Operation__c, EB_OperationStatus__c, EB_OperationProcessedCount__c, EB_CountToAddresses__c, EB_CalcWarningCount__c, EB_CalcWarningMessage__c from EB_AkaMailer__c where Id = :strMailerId];
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            if(akamMailer.EB_CalcWarningCount__c>0)
            {
                return akamMailer.EB_CalcWarningMessage__c;
            }
            else
            {
                akamMailer.EB_Operation__c = 'SendMails';
                akamMailer.EB_OperationStatus__c = 'Start';
                update akamMailer;
                
                EBCS_Application__c batchSize = EBCS_Application__c.getInstance('SingleMailsBatchSize'); 
                batch_Size = Integer.valueof((batchSize.Value__c).trim());
                //fetch all the contact records for the selected accounts
                for(EB_AkaMContact__c eb_contact:[select EB_AkaMContact__c.Id, EB_TemplateId__c, EB_AkaMAccount__c, EB_Status__c, Email_Template__c, EB_Contact__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId) and (EB_Status__c = 'New') and (EB_AkaMContact__c.EB_IsBCC__c=false) and (EB_AkaMContact__c.EB_IsCC__c=false) limit :batch_Size])
                {
                    numberOfRecordsProcessed++;
                    recordsExists++;
                    //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                    contactRecords.add(eb_contact);
                   // accountRecords.add(eb_contact.EB_AkaMAccount__c);
                    accountIds.add(eb_contact.EB_AkaMAccount__c);
                    templateName.add(eb_contact.Email_Template__c);
                    targetObjectIds.add(eb_contact.EB_Contact__c);
                }
                //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                if(numberOfRecordsProcessed == 0)
                {
                    akamMailer.EB_OperationStatus__c = 'End';
                    akamMailer.EB_OperationProcessedCount__c = 0;
                    update akamMailer; 
                    return 'End';
                }
                if(akamMailer.EB_OperationProcessedCount__c == 0)
                {
                    akamMailer.EB_OperationProcessedCount__c = numberOfRecordsProcessed;
                    update akamMailer;
                }
                else
                {
                    akamMailer.EB_OperationProcessedCount__c = akamMailer.EB_OperationProcessedCount__c + numberOfRecordsProcessed;
                    update akamMailer;
                }
                //System.assertEquals(akamMailer.EB_CountToAddresses__c,-1);
                if(akamMailer.EB_OperationProcessedCount__c == akamMailer.EB_CountToAddresses__c)
                {
                    processedFlag = 1;
                    akamMailer.EB_OperationStatus__c = 'End';
                    akamMailer.EB_OperationProcessedCount__c = 0;
                    update akamMailer; 
                    //return 'End';
                }
                
                //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                mailerTemp.clear(); 
                accountTemp.clear();
                contactTemp.clear();
                //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                loadCcBccList(accountIds);
                //loadCcList(accountIds);
                //loadBccList(accountIds);
                //objMailer = [select EB_Status__c,EB_SINumber__c,  Email_Template__c from EB_AkaMailer__c where Id = :strMailerId];
                //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                EBCS_Application__c useorgwide = EBCS_Application__c.getInstance('UseOrgWideEmailAddress'); 
                useOrgWideEmail = useorgwide.Value__c;
                //Start of change on 1/9/2010 by janantha for CR# 785433 for raising Salesforce governer's limits
                if(useOrgWideEmail=='TRUE')
                {
                    EBCS_Application__c orgwidevalue = EBCS_Application__c.getInstance('OrgWideEmailAddressName'); 
                    displayName = orgwidevalue.Value__c;
                    orgWideEmailId = [select Id from OrgWideEmailAddress where DisplayName = :displayName limit 1].Id;
                    EBCS_Application__c orgwidevalueReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
                    displayNameReplyTo = orgwidevalueReplyTo.Value__c;
                    orgWideEmailIdReplyTo = [select Address from OrgWideEmailAddress where DisplayName = :displayNameReplyTo limit 1].Address;
                }
                //End of change on 1/9/2010 by janantha for CR# 785433 for raising Salesforce governer's limits
                i = 0;
                while(i < contactRecords.size())
                { 
                    EB_AkaMContact__c contact = contactRecords.get(i);
                    strTargetObjId = contact.EB_Contact__c;     
                    strTemplateName = contact.Email_Template__c;        
                    strTemplateId = contact.EB_TemplateId__c;           
                    
                    //used to save a record under the activity history
                    strWhatId = contact.Id;
                    
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setTemplateId(strTemplateId);
                    
                    ccAddresses = getCcList(contact.EB_AkaMAccount__c);
                    bccAddresses = getBccList(contact.EB_AkaMAccount__c);
                    if((bccAddresses!=null) && (bccAddresses.size() > 0))
                    {
                        objEmail.setBccAddresses(bccAddresses);
                    }
                    
                    if((ccAddresses!=null) && (ccAddresses.size() > 0))
                    {
                        objEmail.setCcAddresses(ccAddresses);
                    }
                    
                    objEmail.setTargetObjectId(strTargetObjId);
                    objEmail.setWhatId(strWhatId);
      
                    //useOrgWideEmail = EB_UtilApplication.getProperty('UseOrgWideEmailAddress');
                    if(orgWideEmailId!='' && useOrgWideEmail=='TRUE')
                        objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                    //Modified on 26th Aug 2010 for including a different from and To address.
                    if(orgWideEmailIdReplyTo!='' && useOrgWideEmail=='TRUE')
                        objEmail.setReplyTo(orgWideEmailIdReplyTo);
                    
                    mailsToBeSent.add(objEmail);
                    
                    contact.EB_Status__c = 'In-Process';
                    contactTemp.add(contact);
                    i++;
                }
        
                i=0;
                //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                /*while(i<accountRecords.size())
                {
                    EB_AkaMAccount__c accountStatus = accountRecords.get(i);
                    accountStatus.EB_Status__c = 'In-Process';
                    accountTemp.add(accountStatus);
                    i++;
                }
                objMailer.EB_Status__c = 'In-Process';*/
                update contactTemp;
                //update accountTemp;
                //update objMailer;
                //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                try
                {
                    objListResult = Messaging.sendEmail( mailsToBeSent,false );
                    for (k=0; k<objListResult.size(); k++){
                        //start of changes on 9/6/2010 by janantha for CR# 791787-implementing exception handling to display an alert if the email limit is reached, or other exceptions.
                        if (objListResult.get(k).getErrors() != emptyList){
                            //System.assertEquals(objListResult.get(k).getErrors().get(0).getStatusCode(),StatusCode.BAD_CUSTOM_ENTITY_PARENT_DOMAIN);
                            if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.ERROR_IN_MAILER)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR or ERROR_IN_MAILER';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_FIELD_WHEN_USING_TEMPLATE || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_EMAIL_ADDRESS)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: INVALID_FIELD_WHEN_USING_TEMPLATE or INVALID_EMAIL_ADDRESS';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == system.StatusCode.SINGLE_EMAIL_LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: SINGLE_EMAIL_LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNSPECIFIED_EMAIL_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNVERIFIED_SENDER_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNKNOWN_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: UNSPECIFIED_EMAIL_ADDRESS or UNVERIFIED_SENDER_ADDRESS or UNKNOWN_EXCEPTION';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.MAXIMUM_CCEMAILS_EXCEEDED || objListResult.get(k).getErrors().get(0).getStatusCode() ==  StatusCode.LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: MAXIMUM_CCEMAILS_EXCEEDED or LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: FIELD_CUSTOM_VALIDATION_EXCEPTION';
                                }
                            }
              // Samir CR 2503767 : Block to catch any other Errors
              else
              {
                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                {
                  strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                }
                else
                {
                  strExceptionMessage = 'sendEmail failed. Error : Bypassed all standard error conditions';
                }
              }
                            // Samir CR 2503767 : Block to catch any other Errors
              //System.assertEquals(strExceptionMessage,null);
                            //end of changes on 9/6/2010 by janantha for CR# 791787-implementing exception handling to display an alert if the email limit is reached, or other exceptions.
                            objTempContact = contactRecords.get(k);
                            objEmailErrorsMap.put(objTempContact.Id, false);
                            
                        }   
                    }
                    //System.assertEquals(objListResult.size(),0);
                    accountTemp.clear();
                    contactTemp.clear();
                    
                    for(i=0; i<contactRecords.size(); i++){
                        EB_AkaMContact__c contact = contactRecords.get(i);
                        if (objEmailErrorsMap.containsKey(contact.Id) == false){
                            contact.EB_Status__c = 'Processed';
                            
                        }
                        else{
                            //i=0;
                           //strExceptionMessage = objListResult[i].getErrors().get(0).getMessage();
                            contact.EB_Status__c = 'Failed';
                            mailerException.EB_Mailer__c = strMailerId;
                            mailerException.Exception_Message__c = strExceptionMessage;
                            mailerException.EB_Type__c = 'Exception';
                            mailerExceptionList.add(mailerException);
                            //System.assertEquals(mailerException, null);
                            objErrorAccountMap.put(contact.EB_AkaMAccount__c, false);
                            exceptionFlag = 1;
                        }
                        
                        contactTemp.add(contact);
                    }
                    update contactTemp;
                    //System.assertEquals(contactTemp,null);
                    insert mailerException;
                    //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                   /* for(i=0; i<accountRecords.size(); i++){ 
                        EB_AkaMAccount__c accountStatus = accountRecords.get(i);
                        if (objErrorAccountMap.containsKey(accountStatus.Id) == false){
                            accountStatus.EB_Status__c = 'Processed';
                        }
                        else
                        {
                            accountStatus.EB_Status__c = 'Failed';
                            exceptionFlag = 1;
                        }
                        accountTemp.add(accountStatus);
                    }*/
                    
                    //update accountTemp;
                    /*if(exceptionFlag != 1)
                    {
                        objMailer.EB_Status__c = 'Processed';
                        update objMailer;
                    }
                    else{
                        objMailer.EB_Status__c = 'Failed';
                        update objMailer;
                    }*/
                    //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                }
    
                catch(Exception e1){
                    
                    mailerException.EB_Mailer__c = strMailerId;
                    mailerException.Exception_Message__c = e1.getMessage();
                    mailerException.EB_Type__c = 'Exception';
                    insert mailerException;
                     
                    throw e1;
                }
                //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                if(processedFlag == 1 && strExceptionMessage!='')
                {
                    return '-1'+strExceptionMessage;
                    processedFlag = 0;
                }
                else if(processedFlag == 1 && strExceptionMessage=='')
                {
                    return 'End';
                }
                //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                return strExceptionMessage;
            }
        }
        else
        {
            //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
            //return validateResult;
            return 'The Mailer has validation errors';
        }
        return '';
        //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
    }
    /*Start of changes for CR#967107 for using action poller to send mails to all the Contacts belonging 
    to a particular Mailer in order to avoid multiple clicks by the user.*/ 
    /*
    Author: Jayalakshmi A
    Created Date: 21 March 2011
    Description: This function takes the Mailer Id as input and sends mails to all the Contacts of that mailer in batches.
    The progress of the operation is displayed on a visualforce page which uses action poller.CR#967107
    Modified on: on 11/11/11 by janantha for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function.
                 CR 1367516
    */
    webservice static String sendMailsActionPoller(String strMailerId)
    { 
        //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        String validateResult = '';
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        akamMailer = [select EB_Operation__c,EB_BatchStatus__c, EB_OperationStatus__c, EB_OperationProcessedCount__c, Owner.Email, CreatedBy.Email,
                      EB_EmailSentToOwner__c, EB_CountToAddresses__c, EB_CalcWarningCount__c, EB_CalcWarningMessage__c from EB_AkaMailer__c where Id = :strMailerId];
        
        String currentUserEmail = UserInfo.getUserEmail();
        /*if(!akamMailer.EB_EmailSentToOwner__c){
          List<Contact> lContact = [SELECT Id, Name, Account.Id, Email FROM Contact WHERE (Email =:akamMailer.CreatedBy.Email OR Email =:akamMailer.Owner.Email OR Email =:currentUserEmail)
                                      AND Account.Akam_Account_Id__c = '1-599K'];
            List<EB_AkaMContact__c> lMailerContactInternal = [SELECT Id, Mailer__c, EB_Email_Id__c,EB_AkaMAccount__c,Email_Template__c FROM EB_AkaMContact__c
                                                              WHERE EB_AkaMAccount__r.EB_AkaMailer__r.Id =:strMailerId AND EB_AkaMAccount__r.EB_Account__r.Akam_Account_Id__c = '1-599K'];
            String internalAkamAccountId = lMailerContactInternal[0].EB_AkaMAccount__c;
            String emailTemplateId = lMailerContactInternal[0].Email_Template__c;
            Set<String> sInternalContactEmail = new Set<String>();
            for(EB_AkaMContact__c varMailerContact :lMailerContactInternal){
                sInternalContactEmail.add(varMailerContact.EB_Email_Id__c);
            }
            List<EB_AkaMContact__c> insertAkamContact = new List<EB_AkaMContact__c>();
            for(Contact varContact: lContact){
                if(! sInternalContactEmail.contains(varContact.Email)){
                    EB_AkaMContact__c akamContactCreation = new EB_AkaMContact__c();
                    akamContactCreation.EB_Contact__c = varContact.Id;
                akamContactCreation.EB_Status__c = 'New';
                akamContactCreation.EB_AkaMAccount__c = internalAkamAccountId;
                   akamContactCreation.EB_EnableValidationRules__c=false;
                    akamContactCreation.Email_Template__c = emailTemplateId;
                    insertAkamContact.add(akamContactCreation);
                }
            }
            insert insertAkamContact;
            akamMailer.EB_EmailSentToOwner__c = true;
            update akamMailer;
        }*/
        
        if(akamMailer.EB_OperationProcessedCount__c == 0)
        {
            validateResult = validateDataForSendEmail(strMailerId);
        }
        //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        if(validateResult == '')
        {
            Integer exceptionFlag = 0;                                  
            List<EB_AkaMContact__c> contactRecords = new List<EB_AkaMContact__c>();
            List<String> accountIds = new List<String>();
            List<String> templateName = new List<String>();
            List<String> targetObjectIds = new List<String>();
            List<String> ccAddresses = new List<String>();
            List<String> bccAddresses = new List<String>();
            Messaging.SendEmailResult[] objListResult = new List<Messaging.SendEmailResult>();
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Integer i = 0;
            List<EB_AkaMailer__c> mailerTemp = new List<EB_AkaMailer__c>();
            List<EB_AkaMAccount__c> accountTemp = new List<EB_AkaMAccount__c>();
            List<EB_AkaMContact__c> contactTemp = new List<EB_AkaMContact__c>();
            Map<String,Boolean> objEmailErrorsMap = new Map<String,Boolean>();
            Map<String,Boolean> objErrorAccountMap = new Map<String,Boolean>();
            String strTargetObjId;
            String strTemplateName;
            String strTemplateId;
            String strWhatId;
            Messaging.Singleemailmessage objEmail;
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c objMailer;
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            String strExceptionMessage = '';
            List<EB_MailerException__c> mailerExceptionList = new List<EB_MailerException__c>(); 
            Integer k;
            EB_AkaMContact__c objTempContact;   
            String orgWideEmailId='';         
            EB_MailerException__c mailerException = new EB_MailerException__c();
            String useOrgWideEmail;
            String displayName;
            String displayNameReplyTo;
            String orgWideEmailIdReplyTo='';
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            List<Messaging.SendEmailError> emptyList = new List<Messaging.SendEmailError>();        
            Integer recordsExists = -1;
            Integer numberOfRecordsProcessed = 0;
            objListResult.clear();
            Integer batch_Size;
            Integer processedFlag = 0; 
            
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //akamMailer = [select EB_Operation__c,EB_BatchStatus__c, EB_OperationStatus__c, EB_OperationProcessedCount__c, EB_CountToAddresses__c, EB_CalcWarningCount__c, EB_CalcWarningMessage__c from EB_AkaMailer__c where Id = :strMailerId];
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            if(akamMailer.EB_CalcWarningCount__c>0)
            {
                return akamMailer.EB_CalcWarningMessage__c;
            }
            else
            {
                akamMailer.EB_Operation__c = 'SendMails';
                akamMailer.EB_OperationStatus__c = 'Start';      
                /*EB_BatchStatus__c is the batch status. when this goes to 'EndOfBatch' this function is called again for processing the next batch.*/      
                akamMailer.EB_BatchStatus__c = 'StartOfBatch';              
                update akamMailer;
                
                EBCS_Application__c batchSize = EBCS_Application__c.getInstance('SingleMailsBatchSize'); 
                batch_Size = Integer.valueof((batchSize.Value__c).trim());
                //fetch all the contact records for the selected accounts
                for(EB_AkaMContact__c eb_contact:[select EB_AkaMContact__c.Id,  EB_TemplateId__c, EB_AkaMAccount__c, EB_Status__c, Email_Template__c, EB_Contact__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId) and (EB_Status__c = 'New') and (EB_AkaMContact__c.EB_IsBCC__c=false) and (EB_AkaMContact__c.EB_IsCC__c=false) limit :batch_Size])
                {
                    numberOfRecordsProcessed++;
                    recordsExists++;                
                    contactRecords.add(eb_contact);              
                    accountIds.add(eb_contact.EB_AkaMAccount__c);
                    templateName.add(eb_contact.Email_Template__c);
                    targetObjectIds.add(eb_contact.EB_Contact__c);
                }
                                                
                if(numberOfRecordsProcessed == batch_Size || numberOfRecordsProcessed == 0)
                {
                    akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                    update akamMailer;
                }
                
                if(numberOfRecordsProcessed == 0)
                {
                    akamMailer.EB_OperationStatus__c = 'End';                                   
                    akamMailer.EB_BatchStatus__c = 'EndOfBatch';                    
                    akamMailer.EB_OperationProcessedCount__c = 0;
                    update akamMailer; 
                    return 'End';
                }
                if(akamMailer.EB_OperationProcessedCount__c == 0)
                {
                    akamMailer.EB_OperationProcessedCount__c = numberOfRecordsProcessed;
                    update akamMailer;
                }
                else
                {
                    akamMailer.EB_OperationProcessedCount__c = akamMailer.EB_OperationProcessedCount__c + numberOfRecordsProcessed;
                    update akamMailer;
                }
                
                if(akamMailer.EB_OperationProcessedCount__c == akamMailer.EB_CountToAddresses__c)
                {
                    processedFlag = 1;
                    akamMailer.EB_OperationStatus__c = 'End';                   
                    akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                    akamMailer.EB_OperationProcessedCount__c = 0;
                    update akamMailer;                  
                }
                               
                mailerTemp.clear(); 
                accountTemp.clear();
                contactTemp.clear();
                //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                loadCcBccList(accountIds);
                //loadCcList(accountIds);
                //loadBccList(accountIds);
                //objMailer = [select EB_Status__c,EB_SINumber__c,  Email_Template__c from EB_AkaMailer__c where Id = :strMailerId];
                //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                EBCS_Application__c useorgwide = EBCS_Application__c.getInstance('UseOrgWideEmailAddress'); 
                useOrgWideEmail = useorgwide.Value__c;
                
                if(useOrgWideEmail=='TRUE')
                {
                    EBCS_Application__c orgwidevalue = EBCS_Application__c.getInstance('OrgWideEmailAddressName'); 
                    displayName = orgwidevalue.Value__c;
                    orgWideEmailId = [select Id from OrgWideEmailAddress where DisplayName = :displayName limit 1].Id;
                    EBCS_Application__c orgwidevalueReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
                    displayNameReplyTo = orgwidevalueReplyTo.Value__c;
                    orgWideEmailIdReplyTo = [select Address from OrgWideEmailAddress where DisplayName = :displayNameReplyTo limit 1].Address;
                }
                
                i = 0;
                while(i < contactRecords.size())
                { 
                    EB_AkaMContact__c contact = contactRecords.get(i);
                    strTargetObjId = contact.EB_Contact__c;     
                    strTemplateName = contact.Email_Template__c;        
                    strTemplateId = contact.EB_TemplateId__c;           
                                    
                    strWhatId = contact.Id;
                    
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setTemplateId(strTemplateId);
                    objEmail.setSaveAsActivity(false);
                    ccAddresses = getCcList(contact.EB_AkaMAccount__c);
                    bccAddresses = getBccList(contact.EB_AkaMAccount__c);
                    if((bccAddresses!=null) && (bccAddresses.size() > 0))
                    {
                        objEmail.setBccAddresses(bccAddresses);
                    }
                    
                    if((ccAddresses!=null) && (ccAddresses.size() > 0))
                    {
                        objEmail.setCcAddresses(ccAddresses);
                    }
                    
                    objEmail.setTargetObjectId(strTargetObjId);
                    objEmail.setWhatId(strWhatId);
                      
                    if(orgWideEmailId!='' && useOrgWideEmail=='TRUE')
                        objEmail.setOrgWideEmailAddressId(orgWideEmailId);
               
                    if(orgWideEmailIdReplyTo!='' && useOrgWideEmail=='TRUE')
                        objEmail.setReplyTo(orgWideEmailIdReplyTo);
                    
                    mailsToBeSent.add(objEmail);
                    
                    contact.EB_Status__c = 'In-Process';
                    contactTemp.add(contact);
                    i++;
                }
        
                i=0;
                
                update contactTemp;
                                
                try
                {
                    objListResult = Messaging.sendEmail( mailsToBeSent,false );
                    for (k=0; k<objListResult.size(); k++){                     
                        if (objListResult.get(k).getErrors() != emptyList){                     
                            if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.ERROR_IN_MAILER)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR or ERROR_IN_MAILER';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_FIELD_WHEN_USING_TEMPLATE || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_EMAIL_ADDRESS)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: INVALID_FIELD_WHEN_USING_TEMPLATE or INVALID_EMAIL_ADDRESS';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == system.StatusCode.SINGLE_EMAIL_LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: SINGLE_EMAIL_LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNSPECIFIED_EMAIL_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNVERIFIED_SENDER_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNKNOWN_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: UNSPECIFIED_EMAIL_ADDRESS or UNVERIFIED_SENDER_ADDRESS or UNKNOWN_EXCEPTION';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.MAXIMUM_CCEMAILS_EXCEEDED || objListResult.get(k).getErrors().get(0).getStatusCode() ==  StatusCode.LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: MAXIMUM_CCEMAILS_EXCEEDED or LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: FIELD_CUSTOM_VALIDATION_EXCEPTION';
                                }
                            }                                                   
                            objTempContact = contactRecords.get(k);
                            objEmailErrorsMap.put(objTempContact.Id, false);
                            
                        }   
                    }                   
                    accountTemp.clear();
                    contactTemp.clear();
                    
                    for(i=0; i<contactRecords.size(); i++){
                        EB_AkaMContact__c contact = contactRecords.get(i);
                        if (objEmailErrorsMap.containsKey(contact.Id) == false){
                            contact.EB_Status__c = 'Processed';
                            
                        }
                        else{                                                  
                            contact.EB_Status__c = 'Failed';
                            mailerException.EB_Mailer__c = strMailerId;
                            mailerException.Exception_Message__c = strExceptionMessage;
                            mailerException.EB_Type__c = 'Exception';
                            mailerExceptionList.add(mailerException);                           
                            objErrorAccountMap.put(contact.EB_AkaMAccount__c, false);
                            exceptionFlag = 1;
                            
                        }
                        
                        contactTemp.add(contact);
                    }
                    update contactTemp;                 
                    insert mailerException;
                    
                    
                            }
    
                catch(Exception e1){
                    
                    mailerException.EB_Mailer__c = strMailerId;
                    mailerException.Exception_Message__c = e1.getMessage();
                    mailerException.EB_Type__c = 'Exception';
                    upsert mailerException;
                     
                    throw e1;
                }
                
                if(processedFlag == 1 && strExceptionMessage!='')
                {
                    return '-1'+strExceptionMessage;
                    processedFlag = 0;
                }
                else if(processedFlag == 1 && strExceptionMessage=='')
                {
                    return 'End';
                }
                
                return strExceptionMessage;
            }
        }
        else
        {                      
            return 'The Mailer has validation errors';
        }
        return '';      
    }  
   //Vineet
   // CR  CNotify: 2012 Jun-2012 Enhance the Account Team Chatter Notification to include the functionality to send mails
    /*
        Author: Vineet
        CR: 1685596
        Description: Send Mail to a List of email addresss with a Plain Text Body to AccountTeam Members For Single Mail       
    */
   /*NO TEST CLASS COVERAGE*/
     public static void sendMailToAccountTeamMembersForSingleMail(Map<EB_AkaMAccount__c,List<String>> MailsToBeSent)
    {       
            Decimal comp;
            ID IncidentID;
            Messaging.SendEmailResult[] result;
            List<Messaging.Singleemailmessage> emails = new List<Messaging.Singleemailmessage>(); 
            Eb_SI_Url__c URL_String=Eb_SI_Url__c.getInstance('URL');
            String SI_URL=URL_String.SI_URL__c;
            Messaging.Singleemailmessage email;
            List<string> Contactsnotified=new list<string>();
            for(EB_AkaMAccount__c acc:MailsToBeSent.keySet())
            {
               
               try
               {
               comp=acc.EB_SINumber__c;
               IncidentID=[select Id from BMCServiceDesk__Incident__c where EB_SI__c = :comp][0].Id;
               }
               catch (Exception e)
               {
                IncidentID=Null;
               }
               List<EB_AkaMContact__c> AkamContactsnotified=[select EB_Contact__r.Name from EB_AkaMContact__c where EB_AkaMAccount__c=:acc.Id];
               for(EB_AkaMContact__c con:AkamContactsnotified)
               {
                Contactsnotified.add(con.EB_Contact__r.Name);
               
               }
               List<String> tempMembersList = new List<String>();   
               Integer toCount =0;
               String Subject ='Account Team Notification: Account: '+ acc.EB_Account__r.name +' was notified of an ongoing Service Incident: '+acc.EB_SINumber__c;               
               String TextBody ='Customer '+acc.EB_Account__r.name +' may have been impacted by a service incident. Hence, an email notification was sent to 24x7 contacts associated with the account,informing them about the issue. \t\n\n 24x7 contacts notified: ' + Contactsnotified + '\t\n\nPlease go to this Service Incident record for more details: ' + SI_URL+'/'+IncidentID+'\t\nPlease get in touch with the GSS Incident Manager associated with this service incident if you need more details.\t\n\nNote that you are receiving this email since you are listed as being one of the account team members associated with the customer '+acc.EB_Account__r.name+'.\t\nIf this is incorrect:\t\n1. Please pass this information on to the right people associated with the account\t\n2. Work with right account team to have the changes made to Siebel/Salesforce';
                
                for(String emailId : MailsToBeSent.get(acc))
                {
                    toCount++;
                    if(toCount>100)
                    {
                        toCount = 0;
                        email = new Messaging.Singleemailmessage();
                        email.setSaveAsActivity(false); 
                        email.setToAddresses(tempMembersList);
                        email.setSubject(Subject); 
                        email.setPlainTextBody(TextBody);        
                        email.setReplyTo('noreply@akamai.com'); 
                        emails.add(email);
                        tempMembersList = new List<String>();
                       
                    }
                    tempMembersList.add(emailId);
                    
                        
                }
                toCount = 0;
                email = new Messaging.Singleemailmessage();
                email.setSaveAsActivity(false); 
                email.setToAddresses(tempMembersList);
                email.setSubject(Subject); 
                email.setPlainTextBody(TextBody);                 
                emails.add(email);
        
               
               
            }
           result =  Messaging.sendEmail(emails);
           
              
                           
                     
    }
       /*
        Author: Vineet
        CR: 1685596
        Description: Send Mail to a List of email addresss with a Plain Text Body to AccountTeam Members For Mass Mail       
    */
    /*NO TEST CLASS COVERAGE*/
    public static void sendMailToAccountTeamMembersForMassMail(Map<Account,List<String>> MailsToBeSent,EB_AkaMailer__c mailerObject)
    {       
            Messaging.SendEmailResult[] result;
            List<Messaging.Singleemailmessage> emails = new List<Messaging.Singleemailmessage>(); 
          Eb_SI_Url__c URL_String=Eb_SI_Url__c.getInstance('URL');
            String SI_URL=URL_String.SI_URL__c;
            Messaging.Singleemailmessage email;
            for(Account acc:MailsToBeSent.keySet())
            {
              
               List<String> tempMembersList = new List<String>();   
               Integer toCount =0;
               String Subject ='Account Team Notification: Akam Account Id: '+ acc.AKAM_Account_ID__c +', Account: '+ acc.name +' was notified of an ongoing Incident.';               
               String TextBody ='It was noticed that the following customer was impacted by an incident, hence an email notification was sent out to 24x7 contacts associated with the following customer account, informing them about the issue. \n\n Account: ' + acc.name + '\nSI# :' + mailerObject.EB_SINumber__c +'\n\nTo get more details, please view the incident record at'+SI_URL+'?id='+mailerObject.EB_SINumber__c+' or get in touch with the GSS Incident Manager / Business Information Lead associated with the incident.';
                
                for(String emailId : MailsToBeSent.get(acc))
                {
                    toCount++;
                    if(toCount>100)
                    {
                        toCount = 0;
                        email = new Messaging.Singleemailmessage();
                        email.setSaveAsActivity(false); 
                        email.setToAddresses(tempMembersList);
                        email.setSubject(Subject); 
                        email.setPlainTextBody(TextBody);        
                        email.setReplyTo('noreply@akamai.com'); 
                        emails.add(email);
                        tempMembersList = new List<String>();
                       
                    }
                    tempMembersList.add(emailId);
                    
                        
                }
                toCount = 0;
                email = new Messaging.Singleemailmessage();
                email.setSaveAsActivity(false); 
                email.setToAddresses(tempMembersList);
                email.setSubject(Subject); 
                email.setPlainTextBody(TextBody);                 
                emails.add(email);
        
               
               
            }
           result =  Messaging.sendEmail(emails);
           
              
                           
                     
    }
    /*
    
     public static void sendMailToInternalUsers(Map<Id,List<AccountTeamMember>> MailsToBeSent,String templateName, String TypeOfMail)
    {       
            Messaging.SendEmailResult[] result;
            Integer q=0;
            Id templateId;
             for(EmailTemplate et:[select Id from EmailTemplate where name = :templateName limit 1])
             {
                templateId=et.Id;
             } 
            if(templateId!=null)
            {               
                List<Messaging.Singleemailmessage> emails = new List<Messaging.Singleemailmessage>(); 
                Messaging.Singleemailmessage email;
                if(TypeOfMail == 'Single Mail')
                {
                    for(Id accId:MailsToBeSent.keySet())
                    {
                        for(AccountTeamMember member : MailsToBeSent.get(accId))
                        {
                            if(member.User.ContactId!=null)
                            {
                                email = new Messaging.Singleemailmessage();
                                email.setSaveAsActivity(false);
                                email.setTemplateId(templateId);                           
                                email.setTargetObjectId(member.User.ContactId);                         
                                email.setWhatId(accId);
                                emails.add(email);
                                system.assertEquals(accId,null);
                            }
                        }
                    }
                }
                else
                {
                    for(Id accId:MailsToBeSent.keySet())
                    {
                        for(AccountTeamMember member : MailsToBeSent.get(accId))
                        {
                            if(member.User.ContactId!=null)
                            {
                                email = new Messaging.Singleemailmessage();
                                email.setSaveAsActivity(false);                                                         
                                email.setTemplateId(templateId);
                                email.setTargetObjectId(member.User.ContactId);                         
                                email.setWhatId(accId);
                                emails.add(email);
                            }
                        }
                    }
                }
                  result =  Messaging.sendEmail(emails);
                
            
            
            }
                     
    }*//*
    public static void sendMailToInternalUsers(Map<Id,List<String>> MailsToBeSent,String templateName, String TypeOfMail)
    {       
            Messaging.SendEmailResult[] result;
            Integer q=0;
            Id templateId;
             for(EmailTemplate et:[select Id from EmailTemplate where name = :templateName limit 1])
             {
                templateId=et.Id;
             } 
            if(templateId!=null)
            {
                String userid = UserInfo.getUserId();
                if(userid!=null || userid!='')
                {
                    String userEmail;
                    for(User u:[SELECT Email from User where Id= :userid limit 1])
                    {
                        userEmail = u.Email;
                    }
                    if(userEmail!=null )
                    {
                        Id idOfCurrentUser;
                        for(Contact c:[select Id from Contact where Email = :userEmail limit 1])
                        {
                            idOfCurrentUser = c.Id;
                        }
                        if(idOfCurrentUser!=null)
                        {
                                
                            List<Messaging.Singleemailmessage> emails = new List<Messaging.Singleemailmessage>(); 
                            Messaging.Singleemailmessage email;
                            if(TypeOfMail == 'Single Mail')
                            {
                                for(Id accId:MailsToBeSent.keySet())
                                {
                                   List<String> tempMembersList = new List<String>();   
                                    Integer toCount =0;
                                   
                                    for(String emailId : MailsToBeSent.get(accId))
                                    {
                                        toCount++;
                                        if(toCount>24)
                                        {
                                            toCount = 0;
                                            email = new Messaging.Singleemailmessage();
                                            email.setSaveAsActivity(false); 
                                            email.setBccAddresses(tempMembersList);                              
                                            email.setTemplateId(templateId);
                                            email.setTargetObjectId(idOfCurrentUser);                         
                                            email.setWhatId(accId);
                                            emails.add(email);
                                            tempMembersList = new List<String>();
                                           
                                        }
                                        tempMembersList.add(emailId);
                                         q++;
                                            
                                    }
                                    email = new Messaging.Singleemailmessage();
                                    email.setSaveAsActivity(false); 
                                    email.setBccAddresses(tempMembersList);                              
                                    email.setTemplateId(templateId);
                                    email.setTargetObjectId(idOfCurrentUser);                         
                                    email.setWhatId(accId);
                                    emails.add(email);
                                   
                                   
                                }
                            }
                            else
                            {
                                for(Id accId:MailsToBeSent.keySet())
                                {
                                    List<String> tempMembersList = new List<String>();   
                                    Integer toCount =0;
                                   
                                    for(String emailId : MailsToBeSent.get(accId))
                                    {
                                        toCount++;
                                        if(toCount>24)
                                        {
                                            toCount = 0;
                                            email = new Messaging.Singleemailmessage();
                                            email.setSaveAsActivity(false); 
                                            email.setBccAddresses(tempMembersList);                              
                                            email.setTemplateId(templateId);
                                            email.setTargetObjectId(idOfCurrentUser);                         
                                            email.setWhatId(accId);
                                            emails.add(email);
                                            tempMembersList = new List<String>();
                                            
                                        }
                                        tempMembersList.add(emailId);
                                        
                                    }
                                    email = new Messaging.Singleemailmessage();
                                    email.setSaveAsActivity(false); 
                                    email.setBccAddresses(tempMembersList);                              
                                    email.setTemplateId(templateId);
                                    email.setTargetObjectId(idOfCurrentUser);                         
                                    email.setWhatId(accId);
                                    emails.add(email);
                                }
                            }
                              result =  Messaging.sendEmail(emails);
                              
                              
                        }
                            
                    }
                    
                }
            
            }
                     
    }
   */
    //end CR 1685596 
    //end of changes for CR#967107
    
    /* ==============================================================================================
    descripion: this function sends mail to the individual contact. 
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
    code review:
    =================================================================================================== */
    webservice static String sendMailToContact(String targetObjectId, String template, String whatId) 
    {
        Messaging.SendEmailResult[] result;
        String strExceptionMessage='';
        String toAddress;
        EB_AkaMContact__c eb_contact = [select EB_AkaMContact__c.Id,  EB_AkaMAccount__c, EB_Status__c, Email_Template__c, EB_Contact__c from EB_AkaMContact__c where (EB_AkaMContact__c.Id = :whatId)];

        try
        {
            Messaging.Singleemailmessage email = new Messaging.Singleemailmessage(); 
            //select the email template 
            String templateId = [select Id from EmailTemplate where name = :template].Id; 
            String email_Id=templateId;
            email.setTemplateId(email_Id); 
            email.setTargetObjectId(targetObjectId);
            
            //set the recipient email Id to the Email ID of EB_AkaMContact__c
            email.setWhatId(whatId);
            
            //save a record under the Activity History of Contact
            email.setSaveAsActivity(true); 
            result =  Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            
            if(result[0].isSuccess())
            {
                eb_contact.EB_Status__c = 'Processed';
                update eb_contact;
            }
 
        }
        catch(EmailException e){
                
                eb_contact.EB_Status__c = 'Failed';
                update eb_contact;
                
                if(StatusCode.BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED == e.getDmlType(0))
                {
                    strExceptionMessage = e.getMessage();
                }
                
                else if(e.getDmlType(0) == StatusCode.EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR || e.getDmlType(0) == StatusCode.ERROR_IN_MAILER)
                {
                    strExceptionMessage = e.getMessage();
                }
                
                else if(e.getDmlType(0) == StatusCode.INVALID_FIELD_WHEN_USING_TEMPLATE || e.getDmlType(0) == StatusCode.INVALID_EMAIL_ADDRESS)
                {
                    strExceptionMessage = e.getMessage();
                }
                
                else if(e.getDmlType(0) == StatusCode.SINGLE_EMAIL_LIMIT_EXCEEDED || e.getDmlType(0) == StatusCode.MAXIMUM_CCEMAILS_EXCEEDED|| e.getDmlType(0) == StatusCode.LIMIT_EXCEEDED)
                {
                    strExceptionMessage = e.getMessage();
                }
                
                else if(e.getDmlType(0) == StatusCode.UNSPECIFIED_EMAIL_ADDRESS || e.getDmlType(0) == StatusCode.UNVERIFIED_SENDER_ADDRESS || e.getDmlType(0) == StatusCode.UNKNOWN_EXCEPTION)
                {
                    strExceptionMessage = e.getMessage();
                }

                else if(e.getDmlType(0) == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
                {
                    strExceptionMessage = e.getMessage();
                }
                return strExceptionMessage;
        }
        catch(Exception e1){
            
            eb_contact.EB_Status__c = 'Failed';
            update eb_contact;
            
            strExceptionMessage = e1.getMessage(); 
        }
        return strExceptionMessage;
    }  
    
    /* ==============================================================================================
    descripion: this function sends mails to all the contacts under a particular mailer
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :7/20/2010
        2.Modified :8/24/2010 by janantha.
            Change: Added setReplyTo() and setSenderDisplayName() functions to provide the functionality
            of orgWideEmailAddress. 
        3.Modified: 8/26/2010 by janantha.
        Change: ReplyTo email id is retrived from orgWideEmailAddress for the display name stored in the 
        custom setting OrgWideReplyToEmailAddressName
        4.Modified: 9/3/2010 by janantha for changing the Mass mail functionality similar to single mails since the WhatId cannot be set to Contact Id in Mass mails for CR# 785433.
        5.Modified : 9/6/2010 by janantha for displaying alert messages if email limit is reached and other exceptions for CR# 791787.
        6.Modified: 9/8/2010 by janantha for checking if the Email Id of a contact is blank for CR# 791787.
        7.Modified: 9/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
        8.on 11/11/11 by janantha for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function.
          CR 1367516
        9.on 11/11/11 by janantha for Lighter Foot Print Mass Mails CR# 1383743
    code review:
    =================================================================================================== */
    webservice static String sendMassEmails(String strMailerId)
    {
        //start of changes on 9/3/2010 by janantha for changing the Mass mail functionality similar to single mails since the WhatId cannot be set to Contact Id in Mass mails for CR# 785433.
        //start of change by janantha for checking if the Email Id of a contact is blank for CR# 791787
        //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        String validateResult = '';
        
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        akamMailer = [select Email_Template__r.EB_SFEmailTemplateId__c,EB_Operation__c,EB_OperationStatus__c,EB_OperationProcessedCount__c,EB_CalcWarningCount__c, EB_CalcWarningMessage__c, EB_CountToAddresses__c from EB_AkaMailer__c where Id = :strMailerId];
        if(akamMailer.EB_OperationProcessedCount__c == 0)
        {
            validateResult = validateDataForSendEmail(strMailerId);
        }
        //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        if(validateResult == '')
        {
        //end of change by janantha for checking if the Email Id of a contact is blank for CR# 791787
            Integer exceptionFlag = 0;
            List<EB_AkaMAccount__c> accountRecords = new List<EB_AkaMAccount__c>(); 
            List<EB_AkaMContact__c> contactRecords = new List<EB_AkaMContact__c>();
            List<String> accountIds = new List<String>();
            List<String> templateName = new List<String>();
            List<String> targetObjectIds = new List<String>();
            List<String> ccAddresses = new List<String>();
            List<String> bccAddresses = new List<String>();
            Messaging.SendEmailResult[] objListResult = new List<Messaging.SendEmailResult>();
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Integer i = 0;
            List<EB_AkaMailer__c> mailerTemp = new List<EB_AkaMailer__c>();
            List<EB_AkaMAccount__c> accountTemp = new List<EB_AkaMAccount__c>();
            List<EB_AkaMContact__c> contactTemp = new List<EB_AkaMContact__c>();
            Map<String,Boolean> objEmailErrorsMap = new Map<String,Boolean>();
            Map<String,Boolean> objErrorAccountMap = new Map<String,Boolean>();
            String strTargetObjId;
            String strTemplateName;
            String strTemplateId;
            String strWhatId;
            Messaging.Singleemailmessage objEmail;
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c objMailer;
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            String strExceptionMessage = '';
            List<EB_MailerException__c> mailerExceptionList = new List<EB_MailerException__c>(); 
            Integer k;
            EB_AkaMContact__c objTempContact;   
            String orgWideEmailId='';         
            EB_MailerException__c mailerException = new EB_MailerException__c();
            String useOrgWideEmail;
            String displayName;
            String displayNameReplyTo;
            String orgWideEmailIdReplyTo='';
            List<Messaging.SendEmailError> emptyList = new List<Messaging.SendEmailError>();
            //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
            Integer recordsExists = -1;
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            Integer numberOfRecordsProcessed = 0;
            Integer batch_Size;
            Integer processedFlag = 0;
            
            //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
            String internalContactId;
            List<String> contactToListEmailIds = new List<String>();
            
            EBCS_Application__c internalContact = EBCS_Application__c.getInstance('InternalContactId'); 
            internalContactId = internalContact.Value__c;
            //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //akamMailer = [select Email_Template__r.EB_SFEmailTemplateId__c,EB_Operation__c,EB_OperationStatus__c,EB_OperationProcessedCount__c,EB_CalcWarningCount__c, EB_CalcWarningMessage__c, EB_CountToAddresses__c from EB_AkaMailer__c where Id = :strMailerId];
            strTemplateId = akamMailer.Email_Template__r.EB_SFEmailTemplateId__c;
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            
            if(akamMailer.EB_CalcWarningCount__c>0)
            {
                return akamMailer.EB_CalcWarningMessage__c;
            }
            else
            {
                akamMailer.EB_Operation__c = 'SendMassMails';
                akamMailer.EB_OperationStatus__c = 'Start';
                update akamMailer;
                
                EBCS_Application__c batchSize = EBCS_Application__c.getInstance('MassMailsBatchSize'); 
                batch_Size = Integer.valueof((batchSize.Value__c).trim());
                //fetch all the account records for the mailer with mailer id:strMailerId
               /* for(EB_AkaMAccount__c eb_account:[select EB_AkaMAccount__c.Id,  EB_AkaMailer__c, EB_Status__c, Email_Template__c from EB_AkaMAccount__c where EB_AkaMAccount__c.EB_AkaMailer__r.Id = :strMailerId])
                { 
                    accountRecords.add(eb_account);
                    accountIds.add(eb_account.Id);
                }*/
                
                //fetch all the contact records for the selected accounts
                //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                for(EB_AkaMContact__c eb_contact:[select EB_AkaMContact__c.Id, EB_ToList__c, EB_TemplateId__c, EB_AkaMAccount__c, EB_Status__c, Email_Template__c, EB_Contact__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId) and (EB_Status__c = 'New') and (EB_AkaMContact__c.EB_IsBCC__c=false) and (EB_AkaMContact__c.EB_IsCC__c=false) limit :batch_Size])
                //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                { 
                    recordsExists++;
                    numberOfRecordsProcessed++;
                    contactRecords.add(eb_contact);
                   // accountRecords.add(eb_contact.EB_AkaMAccount__c);
                    accountIds.add(eb_contact.EB_AkaMAccount__c);
                    //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                    templateName.add(eb_contact.Email_Template__c); 
                    targetObjectIds.add(eb_contact.EB_Contact__c); 
                }
                //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                if(numberOfRecordsProcessed == 0)
                {
                    akamMailer.EB_OperationStatus__c = 'End';
                    akamMailer.EB_OperationProcessedCount__c = 0;
                    update akamMailer; 
                    return 'End';
                }
                if(akamMailer.EB_OperationProcessedCount__c == 0)
                {
                    akamMailer.EB_OperationProcessedCount__c = numberOfRecordsProcessed;
                    update akamMailer;
                }
                else
                {
                    akamMailer.EB_OperationProcessedCount__c = akamMailer.EB_OperationProcessedCount__c + numberOfRecordsProcessed;
                    update akamMailer;
                }
                if(akamMailer.EB_OperationProcessedCount__c == akamMailer.EB_CountToAddresses__c)
                {
                    akamMailer.EB_OperationStatus__c = 'End';
                    akamMailer.EB_OperationProcessedCount__c = 0;
                    update akamMailer; 
                    processedFlag = 1;
                    //return 'End';
                }
                //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                
                //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                //strTemplateId = [select Email_Template__r.EB_SFEmailTemplateId__c from EB_AkaMailer__c where Id = :strMailerId].Email_Template__r.EB_SFEmailTemplateId__c;
                //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                //strTemplateId = [select EB_SFEmailTemplateId__c from EB_EmailTemplate__c where EB_API_Name__c = :strTemplateName].EB_SFEmailTemplateId__c;
                mailerTemp.clear(); 
                accountTemp.clear();
                contactTemp.clear();
                
                //loadCcList(accountIds);
                //loadBccList(accountIds);
                //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                //objMailer = [select EB_Status__c,EB_SINumber__c,  Email_Template__c from EB_AkaMailer__c where Id = :strMailerId];
                //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                EBCS_Application__c useorgwide = EBCS_Application__c.getInstance('UseOrgWideEmailAddress'); 
                useOrgWideEmail = useorgwide.Value__c;
                if(useOrgWideEmail=='TRUE')
                {
                    EBCS_Application__c orgwidevalue = EBCS_Application__c.getInstance('OrgWideEmailAddressName'); 
                    displayName = orgwidevalue.Value__c;
                    orgWideEmailId = [select Id from OrgWideEmailAddress where DisplayName = :displayName limit 1].Id;
                    EBCS_Application__c orgwidevalueReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
                    displayNameReplyTo = orgwidevalueReplyTo.Value__c;
                    orgWideEmailIdReplyTo = [select Address from OrgWideEmailAddress where DisplayName = :displayNameReplyTo limit 1].Address;
                }
                i = 0;
                while(i < contactRecords.size())
                { 
                    EB_AkaMContact__c contact = contactRecords.get(i);
                    //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                    //strTargetObjId = contact.EB_Contact__c;     
                      
                    if(contact.EB_ToList__c!=null)
                    {
                        contactToListEmailIds = contact.EB_ToList__c.split('\n'); 
                        strTargetObjId = internalContactId; 
                    }
                    else
                    {
                        strTargetObjId = contact.EB_Contact__c;
                    }
                    //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                   // strTemplateName = contact.Email_Template__c;        
                    //strTemplateId = contact.EB_TemplateId__c;           
                    
                    //used to save a record under the activity history
                    strWhatId = contact.Id;
                    
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setTemplateId(strTemplateId);
                    
                    //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                    if(contact.EB_ToList__c!=null)
                    {
                        objEmail.setBccAddresses(contactToListEmailIds);
                    }
                    //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
    
                   // ccAddresses = getCcList(contact.EB_AkaMAccount__c);
                   // bccAddresses = getBccList(contact.EB_AkaMAccount__c);
                  /*  if((bccAddresses!=null) && (bccAddresses.size() > 0))
                    {
                        objEmail.setBccAddresses(bccAddresses);
                    }
                    
                    if((ccAddresses!=null) && (ccAddresses.size() > 0))
                    {
                        objEmail.setCcAddresses(ccAddresses);
                    }
                    */
                    objEmail.setTargetObjectId(strTargetObjId);
                    objEmail.setWhatId(strWhatId);
      
                    //useOrgWideEmail = EB_UtilApplication.getProperty('UseOrgWideEmailAddress');
                    if(orgWideEmailId!='' && useOrgWideEmail=='TRUE')
                        objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                    //Modified on 26th Aug 2010 for including a different from and To address.
                    if(orgWideEmailIdReplyTo!='' && useOrgWideEmail=='TRUE')
                        objEmail.setReplyTo(orgWideEmailIdReplyTo); 
                    
                    mailsToBeSent.add(objEmail);
                    contact.EB_Status__c = 'In-Process';
                    contactTemp.add(contact);
                    i++;
                }
        
                i=0;
                //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                /*while(i<accountRecords.size())
                {
                    EB_AkaMAccount__c accountStatus = accountRecords.get(i);
                    accountStatus.EB_Status__c = 'In-Process';
                    accountTemp.add(accountStatus);
                    i++;
                }
                objMailer.EB_Status__c = 'In-Process';*/
                update contactTemp;
                //update accountTemp;
                //update objMailer;
                //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
    
                try
                {
                    objListResult = Messaging.sendEmail( mailsToBeSent,false );
                    for (k=0; k<objListResult.size(); k++){
                        //start of changes on 9/6/2010 by janantha for displaying alert messages if email limit is reached and other exceptions for CR# 791787
                        if (objListResult.get(k).getErrors() != emptyList){
                            //System.assertEquals(objListResult.get(k).getErrors().get(0).getMessage(),'jkl');
                            if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.ERROR_IN_MAILER)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR or ERROR_IN_MAILER';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_FIELD_WHEN_USING_TEMPLATE || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_EMAIL_ADDRESS)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: INVALID_FIELD_WHEN_USING_TEMPLATE or INVALID_EMAIL_ADDRESS';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == system.StatusCode.SINGLE_EMAIL_LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: MASS_EMAIL_LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNSPECIFIED_EMAIL_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNVERIFIED_SENDER_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNKNOWN_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: UNSPECIFIED_EMAIL_ADDRESS or UNVERIFIED_SENDER_ADDRESS or UNKNOWN_EXCEPTION';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.MAXIMUM_CCEMAILS_EXCEEDED || objListResult.get(k).getErrors().get(0).getStatusCode() ==  StatusCode.LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: MAXIMUM_CCEMAILS_EXCEEDED or LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: FIELD_CUSTOM_VALIDATION_EXCEPTION';
                                }
                            }
                            //end of changes on 9/6/2010 by janantha for displaying alert messages if email limit is reached and other exceptions for CR# 791787
                            objTempContact = contactRecords.get(k);
                            objEmailErrorsMap.put(objTempContact.Id, false);
                        }   
                    }
                    accountTemp.clear();
                    contactTemp.clear();
                    
                    for(i=0; i<contactRecords.size(); i++){
                        EB_AkaMContact__c contact = contactRecords.get(i);
                        if (objEmailErrorsMap.containsKey(contact.Id) == false){
                            contact.EB_Status__c = 'Processed';
                            
                        }
                        else{
                           //strExceptionMessage = objListResult[i].getErrors()[0].getMessage();
                           // System.assertEquals(strExceptionMessage, null); 
                            contact.EB_Status__c = 'Failed';
                            //System.assertEquals(contact, null);
                            mailerException.EB_Mailer__c = strMailerId;
                            mailerException.Exception_Message__c = strExceptionMessage;
                            mailerException.EB_Type__c = 'Exception';
                            mailerExceptionList.add(mailerException);
                            //System.assertEquals(mailerException, null);
                            objErrorAccountMap.put(contact.EB_AkaMAccount__c, false);
                            exceptionFlag = 1;
                        }
                        contactTemp.add(contact);
                    }
                    insert mailerException;
                    //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                    /*for(i=0; i<accountRecords.size(); i++){ 
                        EB_AkaMAccount__c accountStatus = accountRecords.get(i);
                        if (objErrorAccountMap.containsKey(accountStatus.Id) == false){
                            accountStatus.EB_Status__c = 'Processed';
                        }
                        else
                        {
                            accountStatus.EB_Status__c = 'Failed';
                            exceptionFlag = 1;
                        }
                        accountTemp.add(accountStatus);
                    }*/
                    update contactTemp;
                    //start of changes on 9/13/2010 by janantha to overcome the collections limit of 1000.
                    //update accountTemp;
                   /* if(exceptionFlag != 1)
                    {
                        objMailer.EB_Status__c = 'Processed';
                        update objMailer;
                    }
                    else{
                        objMailer.EB_Status__c = 'Failed';
                        update objMailer;
                    }*/
                    //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                }
    
                catch(Exception e1){
                    
                    mailerException.EB_Mailer__c = strMailerId;
                    mailerException.Exception_Message__c = e1.getMessage();
                    mailerException.EB_Type__c = 'Exception';
                    insert mailerException;
                    
                    throw e1;
                }
                //start of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
                if(processedFlag == 1 && strExceptionMessage!='')
                {
                    return '-1'+strExceptionMessage;
                    processedFlag = 0;
                }
                else if(processedFlag == 1 && strExceptionMessage=='')
                {
                    return 'End';
                }
                return strExceptionMessage;
            }
        }
        else
        {
            //return validateResult;
            return 'The Mailer has validation errors';
            //end of changes On 09/27/2010 by janantha for Implementing Custom Batchable to be able to Send Email for more than 1000 records CR# 813459
        }
        
    } 
    //end of changes on 9/3/2010 by janantha for changing the Mass mail functionality similar to single mails since the WhatId cannot be set to Contact Id in Mass mails
    /*Start of changes for CR#967107 for using action poller to send mails to all the Contacts belonging 
    to a particular Mailer in order to avoid multiple clicks by the user.*/  
   /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function uses single mails and mimics the mass mail functionality.
      Modified on: 1. on 11/11/11 by janantha for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function.
                   CR 1367516
                   2. on 11/11/11 by janantha for Lighter Foot Print Mass Mails CR# 1383743*/
    webservice static String sendMassEmailsActionPoller(String strMailerId)
    {
        //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        String validateResult = '';     
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();                 
        akamMailer = [select Email_Template__r.EB_SFEmailTemplateId__c, EB_Operation__c,EB_BatchStatus__c,EB_OperationStatus__c,EB_OperationProcessedCount__c,EB_CalcWarningCount__c, EB_CalcWarningMessage__c, EB_CountToAddresses__c, 
                      Owner.Email, CreatedBy.Email, EB_EmailSentToOwner__c  from EB_AkaMailer__c where Id = :strMailerId];
        if(akamMailer.EB_OperationProcessedCount__c == 0)
        {
            validateResult = validateDataForSendEmail(strMailerId);
        }
        /*
        String currentUserEmail = UserInfo.getUserEmail();
        if(!akamMailer.EB_EmailSentToOwner__c){
          List<Contact> lContact = [SELECT Id, Name, Account.Id, Email FROM Contact WHERE (Email =:akamMailer.CreatedBy.Email OR Email =:akamMailer.Owner.Email OR Email =:currentUserEmail)
                                      AND Account.Akam_Account_Id__c = '1-599K'];
            List<EB_AkaMContact__c> lMailerContactInternal = [SELECT Id, Mailer__c, EB_Email_Id__c,EB_AkaMAccount__c,Email_Template__c, EB_ImpactedAccounts__c,EB_ToList__c FROM EB_AkaMContact__c
                                                              WHERE EB_AkaMAccount__r.EB_AkaMailer__r.Id =:strMailerId];
            String internalAkamAccountId = lMailerContactInternal[0].EB_AkaMAccount__c;
            String emailTemplateId = lMailerContactInternal[0].Email_Template__c;
            Set<String> sInternalContactEmail = new Set<String>();
            for(EB_AkaMContact__c varMailerContact :lMailerContactInternal){
              if(varMailerContact.EB_ImpactedAccounts__c.containsIgnoreCase('Akamai Technologies - Assets') 
           && varMailerContact.EB_ToList__c != null){
                for(String varEmail :varMailerContact.EB_ToList__c.split('\n')){
                  sInternalContactEmail.add(varEmail);
                }
              }
            }
            List<EB_AkaMContact__c> insertAkamContact = new List<EB_AkaMContact__c>();
            String emailIdList = '';
            for(Contact varContact: lContact){
                if(! sInternalContactEmail.contains(varContact.Email)){
                  emailIdList += varContact.Email + '\n';
                }
            }      
                    if(emailIdList.trim() != '' && emailIdList.trim()!=null){
                      EB_AkaMContact__c akamContactCreation = new EB_AkaMContact__c();
                      EBCS_Application__c customSetting = EBCS_Application__c.getInstance('InternalContactId');
                      akamContactCreation.EB_Contact__c = customSetting.Value__c;
                      akamContactCreation.EB_Status__c = 'New';
                      akamContactCreation.EB_AkaMAccount__c = internalAkamAccountId;
                      akamContactCreation.EB_EnableValidationRules__c=false;
                      akamContactCreation.EB_ToList__c = emailIdList.trim();
                      akamContactCreation.EB_ImpactedAccounts__c = 'Akamai Technologies - Assets';
                      insertAkamContact.add(akamContactCreation);
                    }
            if(insertAkamContact.size()>0)
            insert insertAkamContact;
            akamMailer.EB_EmailSentToOwner__c = true;
            update akamMailer;
        } */
        //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
        if(validateResult == '')
        {
            Integer exceptionFlag = 0;
            List<EB_AkaMAccount__c> accountRecords = new List<EB_AkaMAccount__c>(); 
            List<EB_AkaMContact__c> contactRecords = new List<EB_AkaMContact__c>();
            List<String> accountIds = new List<String>();
            List<String> templateName = new List<String>();
            List<String> targetObjectIds = new List<String>();
            List<String> ccAddresses = new List<String>();
            List<String> bccAddresses = new List<String>();
            Messaging.SendEmailResult[] objListResult = new List<Messaging.SendEmailResult>();
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Integer i = 0;
            List<EB_AkaMailer__c> mailerTemp = new List<EB_AkaMailer__c>();
            List<EB_AkaMAccount__c> accountTemp = new List<EB_AkaMAccount__c>();
            List<EB_AkaMContact__c> contactTemp = new List<EB_AkaMContact__c>();
            Map<String,Boolean> objEmailErrorsMap = new Map<String,Boolean>();
            Map<String,Boolean> objErrorAccountMap = new Map<String,Boolean>();
            String strTargetObjId;
            String strTemplateName;
            String strTemplateId;
            String strWhatId;
            Messaging.Singleemailmessage objEmail;
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c objMailer;
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            String strExceptionMessage = '';
            List<EB_MailerException__c> mailerExceptionList = new List<EB_MailerException__c>(); 
            Integer k;
            EB_AkaMContact__c objTempContact;   
            String orgWideEmailId='';         
            EB_MailerException__c mailerException = new EB_MailerException__c();
            String useOrgWideEmail;
            String displayName;
            String displayNameReplyTo;
            String orgWideEmailIdReplyTo='';
            List<Messaging.SendEmailError> emptyList = new List<Messaging.SendEmailError>();         
            Integer recordsExists = -1;
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            Integer numberOfRecordsProcessed = 0;
            Integer batch_Size;
            Integer processedFlag = 0;
            //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
            String internalContactId;
            List<String> contactToListEmailIds = new List<String>();
            
            EBCS_Application__c internalContact = EBCS_Application__c.getInstance('InternalContactId'); 
            internalContactId = internalContact.Value__c;
            //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
            
            //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
            //akamMailer = [select Email_Template__r.EB_SFEmailTemplateId__c, EB_Operation__c,EB_BatchStatus__c,EB_OperationStatus__c,EB_OperationProcessedCount__c,EB_CalcWarningCount__c, EB_CalcWarningMessage__c, EB_CountToAddresses__c from EB_AkaMailer__c where Id = :strMailerId];
            strTemplateId = akamMailer.Email_Template__r.EB_SFEmailTemplateId__c;
            //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                      
            if(akamMailer.EB_CalcWarningCount__c>0)
            {
                return akamMailer.EB_CalcWarningMessage__c;
            }
            else
            {
                akamMailer.EB_Operation__c = 'SendMassMails';
                akamMailer.EB_OperationStatus__c = 'Start';
                //batch status. Only after the EB_BatchStatus__c goes to 'EndOfBatch' this function will be called again.
                akamMailer.EB_BatchStatus__c = 'StartOfBatch';          
                update akamMailer;
                
                EBCS_Application__c batchSize = EBCS_Application__c.getInstance('MassMailsBatchSize'); 
                batch_Size = Integer.valueof((batchSize.Value__c).trim());                             
                
                //fetch all the contact records for the selected accounts
                //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                for(EB_AkaMContact__c eb_contact:[select EB_AkaMContact__c.Id, EB_ToList__c,EB_TemplateId__c, EB_AkaMAccount__c, EB_Status__c, Email_Template__c, EB_Contact__c from EB_AkaMContact__c where (EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.Id = :strMailerId) and (EB_Status__c = 'New') and (EB_AkaMContact__c.EB_IsBCC__c=false) and (EB_AkaMContact__c.EB_IsCC__c=false) limit :batch_Size])
                //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                { 
                    recordsExists++;
                    numberOfRecordsProcessed++;
                    contactRecords.add(eb_contact);                 
                    accountIds.add(eb_contact.EB_AkaMAccount__c);                  
                    templateName.add(eb_contact.Email_Template__c); 
                    targetObjectIds.add(eb_contact.EB_Contact__c); 
                }
                if(numberOfRecordsProcessed == batch_Size || numberOfRecordsProcessed == 0)
                {
                    akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                    update akamMailer;
                }
                
                if(numberOfRecordsProcessed == 0)
                {
                    akamMailer.EB_OperationStatus__c = 'End';
                    akamMailer.EB_OperationProcessedCount__c = 0;                   
                    akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                    update akamMailer; 
                    return 'End';
                }
                if(akamMailer.EB_OperationProcessedCount__c == 0)
                {
                    akamMailer.EB_OperationProcessedCount__c = numberOfRecordsProcessed;
                    update akamMailer;
                }
                else
                {
                    akamMailer.EB_OperationProcessedCount__c = akamMailer.EB_OperationProcessedCount__c + numberOfRecordsProcessed;
                    update akamMailer;
                }
                if(akamMailer.EB_OperationProcessedCount__c == akamMailer.EB_CountToAddresses__c)
                {
                    akamMailer.EB_OperationStatus__c = 'End';
                    akamMailer.EB_OperationProcessedCount__c = 0;                 
                    akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                    update akamMailer; 
                    processedFlag = 1;                  
                }
                
                //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                //strTemplateId = [select Email_Template__r.EB_SFEmailTemplateId__c from EB_AkaMailer__c where Id = :strMailerId].Email_Template__r.EB_SFEmailTemplateId__c;
                //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                
                mailerTemp.clear(); 
                accountTemp.clear();
                contactTemp.clear();
                
                //Start of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function                             
                //objMailer = [select EB_Status__c,EB_SINumber__c,  Email_Template__c from EB_AkaMailer__c where Id = :strMailerId];
                //End of changes for CR 1367516 for increasing the efficiency of single mails and mass mails by reducing unwanted SOQL calls and validate function
                
                EBCS_Application__c useorgwide = EBCS_Application__c.getInstance('UseOrgWideEmailAddress'); 
                useOrgWideEmail = useorgwide.Value__c;
                if(useOrgWideEmail=='TRUE')
                {
                    EBCS_Application__c orgwidevalue = EBCS_Application__c.getInstance('OrgWideEmailAddressName'); 
                    displayName = orgwidevalue.Value__c;
                    orgWideEmailId = [select Id from OrgWideEmailAddress where DisplayName = :displayName limit 1].Id;
                    EBCS_Application__c orgwidevalueReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
                    displayNameReplyTo = orgwidevalueReplyTo.Value__c;
                    orgWideEmailIdReplyTo = [select Address from OrgWideEmailAddress where DisplayName = :displayNameReplyTo limit 1].Address;
                }
                i = 0;
                while(i < contactRecords.size())
                { 
                    EB_AkaMContact__c contact = contactRecords.get(i);
                    //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                    //strTargetObjId = contact.EB_Contact__c;
                    
                    if(contact.EB_ToList__c!=null)
                    {
                        contactToListEmailIds = contact.EB_ToList__c.split('\n'); 
                        strTargetObjId = internalContactId;   
                    }
                    
                    else
                    {
                        strTargetObjId = contact.EB_Contact__c;
                    }
                    //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails                   
                    strWhatId = contact.Id;                    
                    objEmail = new Messaging.Singleemailmessage();
                    objEmail.setTemplateId(strTemplateId);                   
                    objEmail.setTargetObjectId(strTargetObjId);
                    objEmail.setWhatId(strWhatId);
                    objEmail.setSaveAsActivity(false);
                    //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                    if(contact.EB_ToList__c!=null)
                    {
                        objEmail.setBccAddresses(contactToListEmailIds);
                    }
                    //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
                        
                    if(orgWideEmailId!='' && useOrgWideEmail=='TRUE')
                        objEmail.setOrgWideEmailAddressId(orgWideEmailId);
                    //Modified on 26th Aug 2010 for including a different from and To address.
                    if(orgWideEmailIdReplyTo!='' && useOrgWideEmail=='TRUE')
                        objEmail.setReplyTo(orgWideEmailIdReplyTo);
                    
                    mailsToBeSent.add(objEmail);
                    contact.EB_Status__c = 'In-Process';
                    contactTemp.add(contact);
                    i++;
                }
        
                i=0;
                
                update contactTemp;                                             
    
                try
                {
                    objListResult = Messaging.sendEmail( mailsToBeSent,false );
                    for (k=0; k<objListResult.size(); k++){                      
                        if (objListResult.get(k).getErrors() != emptyList){                         
                            if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: BCC_NOT_ALLOWED_IF_BCC_COMPLIANCE_ENABLED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.ERROR_IN_MAILER)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: EMAIL_NOT_PROCESSED_DUE_TO_PRIOR_ERROR or ERROR_IN_MAILER';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_FIELD_WHEN_USING_TEMPLATE || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.INVALID_EMAIL_ADDRESS)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: INVALID_FIELD_WHEN_USING_TEMPLATE or INVALID_EMAIL_ADDRESS';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == system.StatusCode.SINGLE_EMAIL_LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: MASS_EMAIL_LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNSPECIFIED_EMAIL_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNVERIFIED_SENDER_ADDRESS || objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.UNKNOWN_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: UNSPECIFIED_EMAIL_ADDRESS or UNVERIFIED_SENDER_ADDRESS or UNKNOWN_EXCEPTION';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.MAXIMUM_CCEMAILS_EXCEEDED || objListResult.get(k).getErrors().get(0).getStatusCode() ==  StatusCode.LIMIT_EXCEEDED)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: MAXIMUM_CCEMAILS_EXCEEDED or LIMIT_EXCEEDED';
                                }
                            }
                            else if(objListResult.get(k).getErrors().get(0).getStatusCode() == StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION)
                            {
                                if(objListResult.get(k).getErrors().get(0).getMessage() != null)
                                {
                                    strExceptionMessage = objListResult.get(k).getErrors().get(0).getMessage();
                                }
                                else
                                {
                                    strExceptionMessage = 'sendEmail failed. First error: FIELD_CUSTOM_VALIDATION_EXCEPTION';
                                }
                            }
                           
                            objTempContact = contactRecords.get(k);
                            objEmailErrorsMap.put(objTempContact.Id, false);
                        }   
                    }
                    accountTemp.clear();
                    contactTemp.clear();
                    
                    for(i=0; i<contactRecords.size(); i++){
                        EB_AkaMContact__c contact = contactRecords.get(i);
                        if (objEmailErrorsMap.containsKey(contact.Id) == false){
                            contact.EB_Status__c = 'Processed';
                            
                            
                        }
                        else{                        
                            contact.EB_Status__c = 'Failed';                           
                            mailerException.EB_Mailer__c = strMailerId;
                            mailerException.Exception_Message__c = strExceptionMessage;
                            mailerException.EB_Type__c = 'Exception';
                            mailerExceptionList.add(mailerException);                         
                            objErrorAccountMap.put(contact.EB_AkaMAccount__c, false);
                            exceptionFlag = 1;
                            
                        }
                        contactTemp.add(contact);
                    }
                    insert mailerException;                  
                    update contactTemp;
                    /*if(!akamMailer.EB_EmailSentToOwner__c){
                        list<Contact> lContact = [SELECT Id, Name, Account.Id FROM Contact WHERE Email =:akamMailer.CreatedBy.Email OR Email =:akamMailer.Owner.Email];
                        system.debug('### S' + lContact);
                        system.debug('###$$$$' + akamMailer.Owner.Email + ' ' + akamMailer.CreatedBy.Email);
                        List<Messaging.SingleEmailMessage> lSendMailToOwner = new List<Messaging.SingleEmailMessage>();
                            for(Contact varContact :lContact){
                                Messaging.Singleemailmessage objEmailToUsers = new Messaging.Singleemailmessage();
                                objEmailToUsers.setTemplateId(strTemplateId);
 								objEmailToUsers.saveAsActivity = false;   
                                /*if(j==1)
                                objEmailToUsers.setTargetObjectId(varContact.Id);
                                else
                                objEmailToUsers.setTargetObjectId(varContact.Id);
                                if(orgWideEmailIdReplyTo!='' && useOrgWideEmail=='TRUE')
                                objEmailToUsers.setReplyTo(orgWideEmailIdReplyTo);
                                objEmailToUsers.setWhatId(varContact.Account.Id);
                                lSendMailToOwner.add(objEmailToUsers);
                                if(akamMailer.CreatedBy.Id == akamMailer.Owner.Id){
                                	break;
                                }
                            }
                        	                                system.debug('####Kunal ' + lSendMailToOwner);
                            akamMailer.EB_EmailSentToOwner__c = true;
                            update akamMailer;
                            Messaging.sendEmail(lSendMailToOwner);
                    }*/
                    
                }
    
                catch(Exception e1){
                    
                    mailerException.EB_Mailer__c = strMailerId;
                    mailerException.Exception_Message__c = e1.getMessage();
                    mailerException.EB_Type__c = 'Exception';
                    upsert mailerException;
                    
                    throw e1;
                }
                
                if(processedFlag == 1 && strExceptionMessage!='')
                {
                    return '-1'+strExceptionMessage;
                    processedFlag = 0;
                }
                else if(processedFlag == 1 && strExceptionMessage=='')
                {
                    return 'End';
                }
                return strExceptionMessage;
            }
        }
        else
        {           
            return 'The Mailer has validation errors';           
        }
        
    }
    
    public double TotalProcessedMailerContacts{get;set;}
    public double TotalFailedMailerContacts{get;set;}
    public double CountToAddresses{get;set;}
    public EB_AkaMailer__c mailer{get;set;}
    String batchStatus = '';
    String operationStatus = '';
    String mailerStatus = '';
    public String MailerLink = '';
    public String status = 'Pending';
    public String mailerType;
    EBCS_Application__c batchSize = EBCS_Application__c.getInstance('SingleMailsBatchSize'); 
    Integer single_batch_Size = Integer.valueof((batchSize.Value__c).trim());
    EBCS_Application__c massbatchSize = EBCS_Application__c.getInstance('MassMailsBatchSize'); 
    Integer mass_batch_Size = Integer.valueof((massbatchSize.Value__c).trim());
    double toAddresses;
    double failedCount;
   
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function invokes the sendMailsActionPoller() if the current batch is completed and sets the 'status' to
      'Completed' after all the mails are sent out and builds the 'MailerLink'. The progress information of send mails 
      is displayed on a VF Page which uses Action Poller to send out mails in batches.
      Modified: On 28/08/2013 by ssawhney for adding validation exception for missing issue date start/end times and impacted product
            for non blank templates CR 2308403 */
    public PageReference sendEmailActionPoller()
    {
        String validationErrors = '';
        String strMailer_Id = ApexPages.currentPage().getParameters().get('id');
        EB_AkaMailer__c mailer1 = [select EB_BatchStatus__c,EB_Operation__c,EB_OperationStatus__c,EB_Type__c,EB_CountToAddresses__c,EB_Status__c from EB_AkaMailer__c where Id = :strMailer_Id];
        batchStatus = mailer1.EB_BatchStatus__c;    
        operationStatus = mailer1.EB_OperationStatus__c;
        mailerStatus = mailer1.EB_Status__c;
        toAddresses = mailer1.EB_CountToAddresses__c;
        if((batchStatus == 'EndOfBatch' && operationStatus != 'End' && (mailer1.EB_Operation__c == 'SendMails' || mailer1.EB_Operation__c == 'SendMassMails')) ||(batchStatus == 'EndOfBatch' && operationStatus == 'End' && mailer1.EB_Operation__c == null)||(batchStatus == 'EndOfBatch' && operationStatus == null && mailer1.EB_Operation__c == null))
        {
            /*Check for the type of mailer.*/
            if(mailer1.EB_Type__c == 'Single Email')
            {
                String result = sendMailsActionPoller(strMailer_Id);
                /*Check for validation errors.*/
                if(result == 'The Mailer has validation errors')
                {
                    //CR 2308403 28/08/2013 by ssawhney changed error message
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'The Email Id for one of the Contacts is blank OR the Email Template being used is deleted or Issue Start or End Date/Time or Akamai Impacted Product is/are missing.'));
                }
            }
            
            else 
            {
                String result = sendMassEmailsActionPoller(strMailer_Id);
                if(result == 'The Mailer has validation errors')
                {
                    //CR 2308403 28/08/2013 by ssawhney changed error message
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The Email Id for one of the Contacts is blank OR the Email Template being used is deleted or Issue Start or End Date/Time or Akamai Impacted Product is/are missing.'));
                }
            }
        }
        
        EB_AkaMailer__c mailer2 = [select EB_ChatterNotification__c,EB_OperationStatus__c,EB_TotalFailedMailerContacts__c from EB_AkaMailer__c where Id = :strMailer_Id];
        failedCount = mailer2.EB_TotalFailedMailerContacts__c;
        /*EB_OperationStatus__c in 'End' implies all the mails have been sent out.*/
        if(mailer2.EB_OperationStatus__c == 'End')
        {
                          
            status = 'Completed';
            failedCount = mailer2.EB_TotalFailedMailerContacts__c;
            MailerLink = EB_UtilMailer.getUrl()+strMailer_Id;
            
            
            /* 11/18/2011 - CR 1367210 Chatter Notification changes - Sharath
            
            if(mailer2.EB_ChatterNotification__c == true){
                 EB_CtrlChatterNotfication chatterController = new EB_CtrlChatterNotfication();
                 chatterController.sendChatterNotification(strMailer_Id);
                 Pagereference pg = new PageReference('/apex/EB_vfpChatterNotification?id='+strMailer_Id);
                 return pg;
            }
            */
        }
        return null;
    }
    
    double pendingCount;
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the total number of Contacts in the Mailer if the number of contacts is less than the batch size
      else it returns the batch size.*/
    public double getPendingBatchSize()
    {
        mailerType = ApexPages.currentPage().getParameters().get('mailerType'); 
        /*The total number of Contacts is passed as a url parameter.*/
        /* Start of changes for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001 */
        String strTotalToAddress = ApexPages.currentPage().getParameters().get('totalContacts');
        String newStrTotalToAddress = strTotalToAddress.replaceAll(',','');
        Integer totalToAddress = Integer.valueOf(newStrTotalToAddress);
        //Integer totalToAddress = Integer.valueOf(ApexPages.currentPage().getParameters().get('totalContacts')); 
        /* End of changes for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001 */
        if(status != 'Completed')
        {
            if(mailerType == 'Single Email')
            {
                /*totalToAddress gives the total number of Contacts for a particular mailer.*/
                if(totalToAddress< single_batch_Size)
                {
                    return totalToAddress; 
                }
                else if(totalToAddress>single_batch_Size)
                {
                    return single_batch_Size;
                }
            }
            else if(mailerType == 'Mass Email')
            {
                if(totalToAddress< mass_batch_Size)
                {
                    return totalToAddress; 
                }
                else if(totalToAddress>mass_batch_Size)
                {
                    return mass_batch_Size;
                }
            }
        }
        else
        {
            return 0;
        }
        return 0;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns either the single email batch size or mass email batch size based on the Mailer type*/
    public Integer getBatchSizeCustomSetting()
    {
        mailerType = ApexPages.currentPage().getParameters().get('mailerType');
        if(mailerType == 'Single Email')
        {
            return single_batch_Size;
        }
        else if(mailerType == 'Mass Email')
        {
            return mass_batch_Size;
        }
        return 0;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the mailer record and also sets the pendingCount.
      Modified: 12/6/2011 by janantha for obtaining the correct processed, failed count for Lighter Foot Print Mass Mails CR# 1383743*/
    public EB_AkaMailer__c getMailerRecord()
    {
        String strMailer_Id = ApexPages.currentPage().getParameters().get('id');
        /*returns the count of processed, failed, total mailer contacts.*/
       // mailer = [select EB_TotalProcessedMailerContacts__c,EB_TotalFailedMailerContacts__c,EB_CountToAddresses__c,Id from EB_AkaMailer__c where Id = :strMailer_Id];
       //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
       mailer = [select EB_ProcessedCountFormula__c,EB_FailedCountFormula__c,EB_CountToAddressFormula__c,Id from EB_AkaMailer__c where Id = :strMailer_Id];
       pendingCount = mailer.EB_CountToAddressFormula__c - (mailer.EB_ProcessedCountFormula__c+mailer.EB_FailedCountFormula__c);
       //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
       return mailer;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the number of Contacts in 'Pending' status.*/
    public double getPendingContacts()
    {
        return pendingCount;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the appropriate icon corresponding to the Mailer status.*/
    public String getImage()
    {       
        EBCS_CNProgressImages__c inProcess = EBCS_CNProgressImages__c.getOrgDefaults();
        String inProcessImage = inProcess.InProcess__c;
        
        EBCS_CNProgressImages__c processed = EBCS_CNProgressImages__c.getOrgDefaults();
        String processedImage = processed.Processed2__c;
        
        EBCS_CNProgressImages__c failed = EBCS_CNProgressImages__c.getOrgDefaults();
        String failedImage = failed.Failed__c;
        
        String strOrganizationId = ApexPages.currentPage().getParameters().get('OrganizationId');
        
        String url = EB_UtilMailer.getUrl();
        
        if(status!='Completed')
        {
            if(failedCount > 0)
            {           
                return url+'servlet/servlet.ImageServer?id='+failedImage+'&oid='+strOrganizationId;
            }
            return url+'servlet/servlet.ImageServer?id='+inProcessImage+'&oid='+strOrganizationId;
        }
        else if(status == 'Completed')
        {
            if(failedCount > 0)
            {           
                return url+'servlet/servlet.ImageServer?id='+failedImage+'&oid='+strOrganizationId;
            }
            else
                return url+'servlet/servlet.ImageServer?id='+processedImage+'&oid='+strOrganizationId;
        }
        return url+'servlet/servlet.ImageServer?id='+inProcessImage+'&oid='+strOrganizationId;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the link which takes the user back to the Mailer. getRenderMailerLink() renders this link once all the mails  have been sent.*/
    public PageReference MailerLink()
    {
    
        String MailerId = ApexPages.currentPage().getParameters().get('id');      
        EB_AkaMailer__c CurrentMailer = [select EB_ChatterNotification__c,EB_OperationStatus__c,EB_TotalFailedMailerContacts__c from EB_AkaMailer__c where Id = :MailerId];
     
        if(CurrentMailer.EB_ChatterNotification__c == true)
        {
             EB_CtrlChatterNotfication chatterController = new EB_CtrlChatterNotfication();
            // chatterController.sendChatterNotification(MailerId);
             Pagereference pg = new PageReference('/apex/EB_vfpChatterNotification?id='+MailerId);
             return pg;
        }
     
        if(MailerLink == '' || MailerLink == null)
            return null;
        else{
             Pagereference pg = new PageReference('/'+ MailerId); 
             pg.setRedirect(true);
            return   pg;
            }    
    }
    
    
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function renders the 'Finish' link which will take the user back to the mailer when all the mails are sent out*/
    public Boolean getRenderMailerLink()
    {
        
        if(status == 'Completed')
            {
            //updateendtime();
                return true;
            }
               // return true;
            else
                return false;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function renderes the warning message on the VF Page while sending mails is in progress.*/
    public Boolean getRenderWarningText()
    {
        if(status == 'Completed')
            return false;
        else
            return true;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the appropriate status message after the sending of mails is completed. This message is rendered
      on the visualforce page based on the value returned by getRenderWarningText()*/
    public String getStatusMessage()
    {
        if(status =='Completed')
        {
            if(failedCount>0)
            {
                return ' Send Mail operation has been completed, Not all mails were sent out  successfully. Please click on the link to navigate to the Mailer.';
            }
            else
            {
                return ' Send Mail operation has been successfully completed. Please click on the link to navigate to the Mailer.';
            }
        }
        else
        {
            return '';
        }
        return '';
    }
    //end of changes for CR#967107
    
    /*NO TEST CLASS COVERAGE FROM THIS POINT AND NO FUNCTION COMMENTS AS TO WHO WROTE THE FUNCTION*/
    public Boolean getRenderNAT() 
    {
        String MailerId = ApexPages.currentPage().getParameters().get('id');      
        EB_AkaMailer__c CurrentMailer = [select EB_ChatterNotification__c,EB_OperationStatus__c,EB_TotalFailedMailerContacts__c from EB_AkaMailer__c where Id = :MailerId];
     
        if(CurrentMailer.EB_ChatterNotification__c == true)
        {
            if(status == 'Completed')
            {
                return true;
            }              
            else
                return false;
        }
        else
        {
        return false;
        }
    }
    
    public String getFinishText() {
        String MailerId = ApexPages.currentPage().getParameters().get('id');      
        EB_AkaMailer__c CurrentMailer = [select EB_ChatterNotification__c,EB_OperationStatus__c,EB_TotalFailedMailerContacts__c from EB_AkaMailer__c where Id = :MailerId];
     
        if(CurrentMailer.EB_ChatterNotification__c == true)
        {
            return 'Notify Account Teams';
        }
        return 'Finish';
    }
    public PageReference NotifyAccountTeam()
    {
     String MailerId = ApexPages.currentPage().getParameters().get('id');
        
     EB_CtrlChatterNotfication chatterController = new EB_CtrlChatterNotfication();
    // chatterController.sendChatterNotification(MailerId);
     Pagereference pg = new PageReference('/apex/EB_vfpChatterNotification?id='+MailerId);
     //system.assertEquals(MailerId,null);
     return pg;
    }    
    
    //Start of changes CR: 1899199, MSHARDUL
    public PageReference redirectToMailer(){
    String mailerId = Apexpages.currentpage().getparameters().get('id');
    if(mailerId!= null){
        PageReference pg = new PageReference('/'+ mailerId);
        return pg;
    }
    return null;
}
//End of changes CR: 1899199, MSHARDUL
//Start of changes by Samir to update Incident with Mailer details
  webservice static void UpdateIncidentNote(String strMailerId)
{
   String mailerId =strMailerId;
    String MailerLink;
    Id SIId;
    Eb_SI_Url__c URL_String=Eb_SI_Url__c.getInstance('URL');
    String SI_URL=URL_String.SI_URL__c;
    EB_MailerException__c mailerException=new EB_MailerException__c (); 
    if(mailerId!= null)
    {
     EB_AkaMailer__c Mailer=[Select Id,Name,EB_SINumber__c,EB_Type__c,EB_ImpactedAkamaiProduct__c,EB_ImpactedRegion__c,EB_Description__c,EB_AdditionalIssueDescription__c,EB_IssueStartDateTime__c,EB_IssueEndDateTime__c from EB_AkaMailer__c where Id=:mailerId][0];
   
    try
    {
          SIId=[Select id from BMCServiceDesk__Incident__c where EB_SI__c = :Mailer.EB_SINumber__c][0].id;
        FeedItem post = new FeedItem();
            post.ParentId = SIId;
            //post.Title = 'SI Notification - Internal';
            post.Body = 'An email notification was sent out to 24x7 contacts associated with this customer account related to  this  to #SI-'+  Mailer.EB_SINumber__c + ' . Please contact the GSS Incident Manager associated with the Service Incident to get more details.';
             post.LinkUrl = SI_URL+'/' + mailerId;
            database.insert(post);
        Note Inc_note = new Note();
         Inc_note.ParentId = SIId;
            Inc_note.Title = 'Mailer: '+Mailer.Name;
            
            
            Inc_note.body = 'Id: '+ Mailer.Id +'\nSI#: '+ Mailer.EB_SINumber__c + '\nType: '+ Mailer.EB_Type__c+'\nImpacted Product: '+Mailer.EB_ImpactedAkamaiProduct__c+'\nImpacted Region:'+Mailer.EB_ImpactedRegion__c+'\nDescription:'+Mailer.EB_Description__c+'\nAdditional Issue Description: '+Mailer.EB_AdditionalIssueDescription__c+'\nIssue Start Date: '+Mailer.EB_IssueStartDateTime__c+'\nIssue End Date:'+Mailer.EB_IssueEndDateTime__c +'\nMailer Link: '+ SI_URL+'/'+Mailer.Id;
        insert Inc_note;
        
    }
    catch(exception e)
    {
                            mailerException.EB_Mailer__c = Mailer.Id;
                            mailerException.Exception_Message__c = 'Error in Updating Incident' +e.getMessage();
                            mailerException.EB_Type__c = 'Exception';
                            insert mailerException;
    
    
    
    }
    
    
    
        
    }
    
}

//end of changes by Samir to update Incident with Mailer details 

//Start of changes for CR 2044819 : MSHARDUL

 webservice static void updatestarttime(String Mailerid)
    {
        Datetime dt = Datetime.NOW();
        EB_AkaMailer__c CurrentMailer = [select EB_Email_Notification_Start_Time__c from EB_AkaMailer__c where Id = :Mailerid];
        CurrentMailer.EB_Email_Notification_Start_Time__c = dt;
        Update CurrentMailer;
        
    }
//End of changes for CR 2044819 : MSHARDUL    
}