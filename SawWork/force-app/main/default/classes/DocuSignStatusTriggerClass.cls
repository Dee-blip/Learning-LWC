/**
    DocuSignStatusTriggerClass
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This class is used to send out Reminder Emails to the Sender based on NextReminderDate and RepeatReminderNdays fields on DocuSign Status Object
            
    @History
    --Developer           --Date            --Change
  Ali KM          20/06/2011    CR 1130608 eSignature enhancements
                        -> Invoking Update to NextReminder Date on DocuSign Status object.
                        -> Invoking a job that pulls sends out Email to Initiator (sender) after RepeatReminderNdays days inactivity by the 
                        Signeed on the Envelope
  Ali KM          23/06/2011    CR 1171027 E-Sign: Initiator Reminder Email should list out Pending Signee details only
                        -> Updated the Custom Setting to Include following Status List for NOT sending Reminder Email: Voided, Declined, Completed
                        -> Changed the Recipient & DocuSign Status Queries to not pick records with above Status for DocuSign & DocuSign Recipients.
                        -> Removed Signed Date / Declined Date / Declined Reason from the Recipient template.  
  Ali KM          05/11/2012    CR 1895176 - Systems Allows Oppty to be moved to SS-6 even after the expiration of Valid Until Date
                        -> Updated existing reminder alert system (method: getDocuSignStatusReminderAlertRecords()) to NOT send reminder email if OrderApproval.ValidUntilDate (API: DD_CCG_Expiration_Date__c)
                        is past current date.
  Ali KM          05/11/2012    CR 1895176 - Systems Allows Oppty to be moved to SS-6 even after the expiration of Valid Until Date
                        -> Added 2 new methods to handle new Cron job Type: E-Sign alert for expired Valid Until Date
                          - invokePendingESignWithExpiredOrderFormEmailAlert()
                            -> Handler for invoking 'pending e-Sign requet having Expired OA.ValidUntilDates.
                          - pendingESignWithExpiredOrderFormEmailAlert()
                            -> Worker method that qualifies DocuSignRequests and mails out Alerts to Opportunity.Owner & SA User.

  Hitesh 
                  03/11/2015    
                          Jira - SFDC-331Adding filter condition to not pick records if corresponding OrderApproval's Oppty's stages are Closed Won or Closed lost or admin closed
    
*/

global class DocuSignStatusTriggerClass implements Schedulable {
  //DocuSign Config object
    public static dsfs__DocuSignAccountConfiguration__c dsConfiguration;
    public static Boolean emailAlertOFExpiredESignCompeletedFirsRunFlag=true;
  //DocuSign Custom Setting object
  public static Map<String,OA_eSign_Intermediate__c> customSettings = OA_eSign_Intermediate__c.getAll();
   private static Messaging.SendEmailResult[] sendEmailResultList = new List<Messaging.SendEmailResult>();  
    private static Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
    private static EmailTemplate initiatorEmailTemplate;
  
  /**
    GetCustomSettingValue(String pPropertyName)
    - Generic function to return Custom Setting values for the single Custom Setting Object model
    - Key Value pair kindda Custom Settings
    */
    public static String GetCustomSettingValue(String pPropertyName)
    {
        //SFDC-2686
        //return GSM_Custom_Settings__c.getInstance('ESignature#'+pPropertyName).Value__c;
        String settingName = 'ESignature_'+pPropertyName;
        return GsmUtilClass.getGSMSettingValue(settingName);
    }
    /**
    GetCustomSettingValue(String pPropertyName)
    - Generic function to return Custom Setting values for the single Custom Setting Object model
      -  method to fetch customsettings OLD STYLE - table field kindda Custom Settings
  */
    private static String getCustomSettingsValue(String pName)
    {
        return customSettings.get(pName).Value__c;
    }
    
    private static EmailTemplate getEmailTemplate(String pTemplateId)
    {
      EmailTemplate emailTemplate=null;
    for(EmailTemplate template : [select Subject, Id, Body from EmailTemplate where Id = :pTemplateId])
            emailTemplate = template;
      return emailTemplate;
    }
    
  /*
    This method fetches the DSAccountConfigurationRecord
  */
  public static void initDSConfiguration()
  {
    if (dsConfiguration == null)
    {
          for (dsfs__DocuSignAccountConfiguration__c dsConfig : [Select dsfs__EmailSubject__c, dsfs__EmailBody__c, dsfs__DefaultWarnOfExpireNDays__c, dsfs__DefaultReminderNDays__c,
                                       dsfs__DefaultRepeatReminderNDays__c, dsfs__DefaultExpireNDays__c From dsfs__DocuSignAccountConfiguration__c 
                                       where Name =: getCustomSettingsValue('dsConfigRecordName') ORDER BY CreatedDate DESC LIMIT 1])
                                        dsConfiguration = dsConfig;
    }
  }
  
  /*
    This method stamps the NextReminderDate based on DocuSignAccountConfiguration record default values.
  */
          public static void initializeNextReminderDate(List<dsfs__DocuSign_Status__c> dssUpdateNextAlertRunList)
    {   
      initDSConfiguration();
      // if Config is missing this feature will NOT WORK
      if (dsConfiguration != null && dsConfiguration.dsfs__DefaultRepeatReminderNDays__c !=null)
      {
        for (dsfs__DocuSign_Status__c dss : dssUpdateNextAlertRunList)
       {  
         Datetime tempSentDateTime = dss.dsfs__Sent_Date_Time__c;
        //System.debug('SentDateTime Date=' + tempSentDateTime);
        Decimal reminderDays = dsConfiguration.dsfs__DefaultRepeatReminderNDays__c; //
        Datetime tempNextReminderDateTime = tempSentDateTime.addDays(reminderDays.intValue());
        dss.RepeatReminderNDays__c = dsConfiguration.dsfs__DefaultRepeatReminderNDays__c; 
        //System.debug('NextReminderDate=' + tempNextReminderDateTime);
        if (tempSentDateTime < Datetime.now() && tempNextReminderDateTime >= Datetime.now()) // if next alert date is less than now then default it to now + reminderDays.
           dss.Next_Reminder_Alert__c = tempNextReminderDateTime;
         else 
           dss.Next_Reminder_Alert__c = Datetime.now().addDays(reminderDays.intValue());
         //System.debug('Next_Reminder_Alert__c=' + dss.Next_Reminder_Alert__c);
       }
      }
    }
    
    // Declare class variables here
    /*
      Method fetches DocuSign Status records that qualify for Email Alert and sends out email to the Sender.
      if( dss.dsfs__Sent_Date_Time__c != null && !strDSEnvelopeExceptionStatus.contains(dss.dsfs__Envelope_Status__c) && dss.dsfs__DocuSign_Envelope_ID__c !=null
         && (Trigger.isInsert || (!Trigger.isInsert && dss.Next_Reminder_Alert__c == null && Trigger.oldMap.get(dss.Id).Next_Reminder_Alert__c == null)))
       
     */
    public String sendReminderEmail()
    {  
      // Map of all DocuSign_Status Records that qualify for an EmailSenderAlert      
      Map<Id, dsfs__DocuSign_Status__c> dssReminderMap;
      // DS recipient status List
      List<dsfs__DocuSign_Recipient_Status__c> dsrsMailList;
      // Map of DocuSign Status Id & DocuSign Recipient Status records
      Map<Id, List<dsfs__DocuSign_Recipient_Status__c>> dssDsrsMap = new Map<Id, List<dsfs__DocuSign_Recipient_Status__c>>();
      //Boolean hasRecipients = false;
      
      List<dsfs__DocuSign_Status__c> updateNextReminderDateList = new List<dsfs__DocuSign_Status__c>();
    Map<Integer, dsfs__DocuSign_Status__c> emailSequenceToDSSMap = new Map<Integer, dsfs__DocuSign_Status__c>();
      
      // fetch the DocuSignStatus records.
      dssReminderMap = getDocuSignStatusReminderAlertRecords();
      //System.debug('dssReminderMap Size=' + dssReminderMap.size());
      //System.debug('dssReminderMap=' + dssReminderMap);
      if (dssReminderMap.size()>0)
      {
        List<dsfs__DocuSign_Recipient_Status__c> dsrsList;  
        Set<Id> dssReminderSet = dssReminderMap.keySet();
        //System.debug('dssReminderSet=' + dssReminderSet);
        for (Id dssId : dssReminderSet)
        {  
          dsrsList = getRecipientList(dssId);
          //System.debug('dssId =' + dssId + ', dsrsList=' + dsrsList + '\n');
          if (dsrsList.size()>0)
          {
            dssDsrsMap.put(dssId, dsrsList);
          }  
        }
        //System.debug('dssDsrsMap Size=' + dssDsrsMap.size());
        //System.debug('dssDsrsMap=' + dssDsrsMap);
      }

    if (dssDsrsMap.size()>0)
    {  
      String strEmailSubject, strEmailBody;
      // Template Subject & Body for the email
      if (initiatorEmailTemplate==null)
        initiatorEmailTemplate = getEmailTemplate(GetCustomSettingValue('EmailTemplateIdSender'));
      
      if (initiatorEmailTemplate!=null)
      {
        strEmailSubject = initiatorEmailTemplate.Subject;
        strEmailBody = initiatorEmailTemplate.Body;
      }
      else
      {
        strEmailSubject = 'E-Signature Reminder: Pending Signature for Order Approval: ##OA-Name##';
        strEmailBody = 'Dear ##sender##,\n\nE-Signature Alert! Pending signee(s) action on your E-Signature request for Order Approval: ##OA-Name##.';
        strEmailBody += '\nOrder Approval link: ##OA-Link## '; // + GetCustomSettingValue('SFOrgURL') + '/##OA-ID##';
        strEmailBody += '\nE-Signature Envelope link: ##ESign-Link## : '; // + GetCustomSettingValue('SFOrgURL') + '/##OA-ID##';
        strEmailBody += '\n##Recipients##';
        strEmailBody += '\nIf you need further assistance, please mail CRM Admins <eae-ops@akamai.com>.';
        strEmailBody += '\n\nThank You';
        strEmailBody += '\n\nCRM Admins';
      }
      // dummyDSS
      dsfs__DocuSign_Status__c dssRecord ;//= new dsfs__DocuSign_Status__c();
      String strBody;
      String strSubject;
      String strRecipientSummary;
      
      Boolean emailSent;
      //List<dsfs__DocuSign_Status__c> updateNextReminderDateList = new List<dsfs__DocuSign_Status__c>();
      //Map<Integer, dsfs__DocuSign_Status__c> emailSequenceToDSSMap = new Map<Integer, dsfs__DocuSign_Status__c>(); 
      Integer mailCount = 0;
      for (Id dssId : dssDsrsMap.keySet())
      {  
        //System.debug('mailCount=' + mailCount);
        // refresh to templated values.
        strSubject = strEmailSubject;
        strBody = strEmailBody;
        emailSent = false;
        // fetch the recipient for associated list of DocuSign Reciepient Status entries.
        strRecipientSummary = getEmailMessageRecipientSummary(dssDsrsMap.get(dssId));
        if (strRecipientSummary == null)
          continue;
        // fetch the relevant DocuSign Status record
        dssRecord = dssReminderMap.get(dssId);
        //System.debug('dssRecord=' + dssRecord);
        // construct message subject & body
        strSubject = strSubject.replaceAll('##OA-Name##', dssRecord.Order_Approval__r.Name);
        strBody = strBody.replaceAll('##sender##', dssRecord.dsfs__Sender__c);
        strBody = strBody.replaceAll('##OA-Name##', dssRecord.Order_Approval__r.Name);
        strBody = strBody.replaceAll('##OA-Link##', GetCustomSettingValue('SFOrgURL') + '/' + dssRecord.Order_Approval__r.Id);
        strBody = strBody.replaceAll('##ESign-Link##', GetCustomSettingValue('SFOrgURL') + '/' + dssRecord.Id);
        strBody = strBody.replaceAll('##Recipients##', strRecipientSummary);
        //System.debug('Message Subject=' + strSubject + ', Body=' + strBody);
        
        String [] recipient=new String[]{dssRecord.dsfs__Sender_Email__c};
        System.debug('recipientList=' + recipient);
          //emailSent = sendEmail(recipient, null, strSubject, strBody);
          //if (emailSent)
            //updateNextReminderDateList.add(dssRecord);
          sendEmailList.add(createSingleEmail(recipient, null, strSubject, strBody));
          emailSequenceToDSSMap.put(mailCount, dssRecord);
          mailCount++;
      }
      
      if (sendEmailList.size()>0)
      {
        //System.debug('emailSequenceToDSSMap=' + emailSequenceToDSSMap);
        //System.debug('sendEmailList=' + sendEmailList);  
        sendEmailResultList = sendEmail(sendEmailList);
        //System.debug('sendEmailResultList=' + sendEmailResultList);
        // Iterate over each list and send out Success OR Failure Emails.
        for (Integer k=0; k<sendEmailResultList.size(); k++)
        {
          if (sendEmailResultList.get(k).isSuccess())
            updateNextReminderDateList.add(emailSequenceToDSSMap.get(k));
          //else
            //reminderEmailSuccess = false;
            // need to add try catch to mail failures to the SF Recipient.
        }  
        //System.debug('updateNextReminderDateList=' + updateNextReminderDateList);   
      }
      
      // update the NextReminderDate for successfully Mailed DocuSign Status records
      if (updateNextReminderDateList.size()>0)
      {
        System.debug('updateNextReminderDateList=' + updateNextReminderDateList);
        //try 
        //{
          update updateNextReminderDate(updateNextReminderDateList);
          System.debug('updateNextReminderDate Was Successfull');
        //} catch(Exception e)
          //{
          //  String [] recipient=new String[]{GetCustomSettingValue('RecipientEmail__c')};
          //  sendEmail(recipient, null,'Error Occured  while updating DocuSign Status record',e.getMessage());
          //}
      }
    }
    String result = updateNextReminderDateList.size().format();
    if (updateNextReminderDateList.size()>0)
    {
      result += ', Sent Reminder Email for following DocuSign Status Id(s):';
      for (dsfs__DocuSign_Status__c dss : updateNextReminderDateList)
      {
        result += dss.Id + ',';
      }
    }
    return result;    
    }
    
    /**
      Created by Chandra.
    sendEmail(List<String> toRecipient,List<String> ccRecipient,String subject, String message)
     @retrun  - Boolean
     @param   - List<String> , List<String>,String,String 
  */
  public Boolean sendEmail(List<String> toRecipient,List<String> ccRecipient,String subject, String message)
    {
    Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        mail.setToAddresses(toRecipient);
        mail.setSubject(subject);
        if(ccRecipient!=null)
        {
          mail.setCcAddresses(ccRecipient);
        }
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(message);
        List<Messaging.Sendemailresult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        if(results[0].isSuccess()==true)
        {
          return true;
        }
         return false;
    }
    
    /*
      sendEmail(Messaging.SingleEmailMessage[] sendSingleEmailList)
      
    */
    public Messaging.SendEmailResult[] sendEmail(Messaging.SingleEmailMessage[] sendSingleEmailList)
    {
      return Messaging.sendEmail(sendSingleEmailList, false);
         //List<Messaging.Sendemailresult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        //List<Messaging.Sendemailresult> results = Messaging.sendEmail(sendSingleEmailList, false);
        //objListResult = Messaging.sendEmail( mailsToBeSent,false );
    }
    
    /*
    This method stamps the NextReminderDate
    - Its called after Reminder Email is successfully sent.
  */
  public List<dsfs__DocuSign_Status__c> updateNextReminderDate(List<dsfs__DocuSign_Status__c> updateNextReminderDateList)
    {   
    for (dsfs__DocuSign_Status__c dss : updateNextReminderDateList)
     {  
       Decimal reminderDays;
       if (dss.RepeatReminderNDays__c !=null)
         reminderDays = dss.RepeatReminderNDays__c;
       else
         reminderDays = 2;
       Datetime tempNextReminderDateTime = dss.Next_Reminder_Alert__c.addDays(reminderDays.intValue());
       if (tempNextReminderDateTime <= Datetime.now())
         dss.Next_Reminder_Alert__c = Datetime.now().addDays(reminderDays.intValue());
       else 
         dss.Next_Reminder_Alert__c = tempNextReminderDateTime;
       //System.debug('Next_Reminder_Alert__c=' + dss.Next_Reminder_Alert__c);
     }
    return updateNextReminderDateList;
    }

  /**
  createSingleEmail(List<String> toRecipient,List<String> ccRecipient,String subject, String message)
   @retrun  - Messaging.SingleEmailMessage
   @param   - List<String> , List<String>, String, String 
   
   - This method generates single Email template
  */
  public Messaging.SingleEmailMessage createSingleEmail(List<String> toRecipient,List<String> ccRecipient,String subject, String message)
  {  
    Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
        mail.setToAddresses(toRecipient);
        mail.setSubject(subject);
        if(ccRecipient!=null)
        {
           mail.setCcAddresses(ccRecipient);
        }
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(message);
        //List<Messaging.Sendemailresult> results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        //List<Messaging.Sendemailresult> results = Messaging.sendEmail(testBulkMsg, false);
        //objListResult = Messaging.sendEmail( mailsToBeSent,false );
        return mail;
  }
    
    // Construct Email Message Recipient Summary
    public String getEmailMessageRecipientSummary(List<dsfs__DocuSign_Recipient_Status__c> dsrsList)
    {
      if (!(dsrsList.size()>0))
        return null;
      String recipientSummary = null;
      String strRecipientSummaryFinal = '';
      String strRecipientTemplate = '\nRecipient ##count##:\n' + 'Name: ##rName##\n' + 'Title: ##rTitle##\n' + 'Email: ##rEmail##\n';
    strRecipientTemplate += 'Signature Status: ##rStatus##\n' + 'Routing Order: ##rRoutingOrder##\n' + 'Date Sent: ##rDateSent##\n';
    //strRecipientTemplate += 'Date Signed: ##rDateSigned##\n' + 'Date Declined: ##rDateDeclined##\n' + 'Decline Reason: ##rDeclineReason##\n';
    //System.debug('strRecipientTemplate=' + strRecipientTemplate);
      Integer count = 0;
      for (dsfs__DocuSign_Recipient_Status__c dsrs: dsrsList)
      {  
        // refresh the values
        recipientSummary = strRecipientTemplate;
        count++;
        //System.debug('count=' + count);
        // replace relevant data value
        recipientSummary = recipientSummary.replaceAll('##count##', count.format());
        if (dsrs.Name != null)
          recipientSummary = recipientSummary.replaceAll('##rName##', dsrs.Name);
        else 
          recipientSummary = recipientSummary.replaceAll('##rName##', 'NA');
        
        if (dsrs.dsfs__DocuSign_Recipient_Title__c != null)
          recipientSummary = recipientSummary.replaceAll('##rTitle##', dsrs.dsfs__DocuSign_Recipient_Title__c);
        else 
          recipientSummary = recipientSummary.replaceAll('##rTitle##', 'NA');
        
        if (dsrs.dsfs__DocuSign_Recipient_Email__c != null)
          recipientSummary = recipientSummary.replaceAll('##rEmail##', dsrs.dsfs__DocuSign_Recipient_Email__c);
        else
          recipientSummary = recipientSummary.replaceAll('##rEmail##', 'NA');
        
        if (dsrs.dsfs__Recipient_Status__c != null)
          recipientSummary = recipientSummary.replaceAll('##rStatus##', dsrs.dsfs__Recipient_Status__c);
        else 
          recipientSummary = recipientSummary.replaceAll('##rStatus##', 'NA');
        
        if (dsrs.dsfs__DocuSign_Routing_Order__c != null)
          recipientSummary = recipientSummary.replaceAll('##rRoutingOrder##', dsrs.dsfs__DocuSign_Routing_Order__c.format());
        else 
          recipientSummary = recipientSummary.replaceAll('##rRoutingOrder##', 'NA');
        
        if (dsrs.dsfs__Date_Sent__c != null)
          recipientSummary = recipientSummary.replaceAll('##rDateSent##', dsrs.dsfs__Date_Sent__c.format());
        else
          recipientSummary = recipientSummary.replaceAll('##rDateSent##', 'NA');
        /*
        if (dsrs.dsfs__Date_Signed__c != null)
          recipientSummary = recipientSummary.replaceAll('##rDateSigned##', (dsrs.dsfs__Date_Signed__c).format());
        else
          recipientSummary = recipientSummary.replaceAll('##rDateSigned##', 'NA');
        if (dsrs.dsfs__Date_Declined__c != null)
        {  
          recipientSummary = recipientSummary.replaceAll('##rDateDeclined##', dsrs.dsfs__Date_Declined__c.format());
          recipientSummary = recipientSummary.replaceAll('##rDeclineReason##', dsrs.dsfs__Decline_Reason__c);
        }
      else
      {
          recipientSummary = recipientSummary.replaceAll('##rDateDeclined##', 'NA');
          recipientSummary = recipientSummary.replaceAll('##rDeclineReason##', 'NA');
      }
      */
      //System.debug('recipientSummary #' + count + ':' + recipientSummary);
      
      strRecipientSummaryFinal = strRecipientSummaryFinal + recipientSummary;
      }
      return strRecipientSummaryFinal;
    }                  
    
    /*
      Fetch All DocuSign Status Records that qualify for Intiator Email Alert
      // Pick records meeting below criteria: that DO NOT have following details: 
      // DO Have - Next Reminder Date <= now
      // DO NOT Have - DocuSign Envelope ID = null, Sent Date > now, Envelope Status = Voided, Completed, Sender Email = null
    */
    public Map<Id, dsfs__DocuSign_Status__c> getDocuSignStatusReminderAlertRecords()
    {
      Map<Id, dsfs__DocuSign_Status__c> dssReminderMap = new Map<Id, dsfs__DocuSign_Status__c>();
      String strDSEnvelopeExceptionStatus = DocuSignStatusTriggerClass.GetCustomSettingValue('DSEnvlopStatusInvalid');
      List<String> invalidEnvelopeStatus = strDSEnvelopeExceptionStatus.split('\\,');
      System.debug('invalidEnvelopeStatus=' + invalidEnvelopeStatus);
      String opptyStageNameExclusion = DocuSignStatusTriggerClass.GetCustomSettingValue('OpptyStageExclusionList');
      List<String> opptyStageNameExclusionList = opptyStageNameExclusion.split('\\,');
      System.debug('Oppty Excluded Stages '+opptyStageNameExclusionList);

      for (dsfs__DocuSign_Status__c dss : [SELECT Id, Name, dsfs__DocuSign_Envelope_ID__c, dsfs__Envelope_Status__c, dsfs__Sent_Date_Time__c, RepeatReminderNDays__c,  
      Next_Reminder_Alert__c, dsfs__Sender_Email__c, dsfs__Sender__c, Order_Approval__c, Order_Approval__r.Id, Order_Approval__r.Name, Order_Approval__r.DD_CCG_Expiration_Date__c
      FROM dsfs__DocuSign_Status__c WHERE Order_Approval__c != null AND dsfs__Envelope_Status__c != null AND dsfs__Envelope_Status__c NOT IN :invalidEnvelopeStatus 
      AND Next_Reminder_Alert__c <= :Datetime.now() AND  dsfs__Sender_Email__c != null AND dsfs__DocuSign_Envelope_ID__c !=null AND dsfs__Sent_Date_Time__c <= :Datetime.now() 
      AND CreatedDate>=LAST_N_YEARS:2 AND Order_Approval__r.Associated_Opportunity__r.StageName NOT IN :opptyStageNameExclusionList])
      {
        // if OA.ValidUntildate is less than now, do NOT send a reminder.
        if (dss.Order_Approval__r.DD_CCG_Expiration_Date__c != null && dss.Order_Approval__r.DD_CCG_Expiration_Date__c < Date.today())
          continue;
        else
          dssReminderMap.put(dss.Id, dss);
          //system.debug('dssSendReminderEmail=' + dss);
      }
    return   dssReminderMap;
    }
    
    /*
      Fetches list of recipients based on @param: String - DocuSign Envelelope ID
      
    */
    public List<dsfs__DocuSign_Recipient_Status__c> getRecipientList(Id dssID)
    {
      String strDSEnvelopeExceptionStatus = DocuSignStatusTriggerClass.GetCustomSettingValue('DSEnvlopStatusInvalid');
      List<dsfs__DocuSign_Recipient_Status__c> dsrsList = new List<dsfs__DocuSign_Recipient_Status__c>();
      List<String> invalidEnvelopeStatus = strDSEnvelopeExceptionStatus.split('\\,');  
      for (dsfs__DocuSign_Recipient_Status__c dsrs : [SELECT Id, dsfs__DocuSign_Routing_Order__c, dsfs__DocuSign_Recipient_Title__c, Name, dsfs__DocuSign_Recipient_Id__c, 
      dsfs__Envelope_Id__c, dsfs__Parent_Status_Record__c, dsfs__Date_Declined__c, dsfs__Date_Delivered__c, dsfs__Date_Sent__c, dsfs__Date_Signed__c, dsfs__Decline_Reason__c, 
      dsfs__DocuSign_Recipient_Email__c, dsfs__Recipient_Status__c FROM dsfs__DocuSign_Recipient_Status__c WHERE dsfs__Parent_Status_Record__c = :dssID 
      AND dsfs__Recipient_Status__c != null AND dsfs__Recipient_Status__c NOT IN :invalidEnvelopeStatus AND CreatedDate>=LAST_N_YEARS:2 ORDER BY dsfs__DocuSign_Routing_Order__c ASC])  
        {
          dsrsList.add(dsrs);
        }
      //System.debug('DocuSign Recipient List=' + dsrsList);
    return dsrsList;        
    }
    
    /**
    ButtonExecute()
    - Used to invoke sendReminderEmail() via UI button.
  */  
  WebService static String ButtonExecute()
  {
    String result='1:';
    String [] recipient=new String[]{GetCustomSettingValue('RecipientEmail__c')};
    DocuSignStatusTriggerClass dssTriggerClass = new DocuSignStatusTriggerClass();
    try 
    {
      String reminderEmailCount = dssTriggerClass.sendReminderEmail();
      result += '\n Count: ' + reminderEmailCount;
    }
    catch(Exception ex)
    {
      dssTriggerClass.sendEmail(recipient, null, 'Error Occured  while sending email notifications', ex.getMessage());
      result='0#'+ex;
    }
    System.debug('result=' + result);
    return result;    
  }
  
  /**
    invokeDocuSignInitiatorReminderJob() 
    - Used to invoke sendReminderEmail via Cronkit Job.
  */
  public static String invokeDocuSignInitiatorReminderJob(String jobType)
  {
    if(!jobType.equals('SendDocuSignInitiatorReminderEmail'))
      return '0#Job type ' + jobType + ' not found!';
    String result='1:';
    String [] recipient=new String[]{GetCustomSettingValue('RecipientEmail__c')};
    DocuSignStatusTriggerClass dssTriggerClass = new DocuSignStatusTriggerClass();
    try 
    {
      String reminderEmailCount = dssTriggerClass.sendReminderEmail();
      result += '\n Count: ' + reminderEmailCount;
    }
    catch(Exception ex)
    {
      dssTriggerClass.sendEmail(recipient, null, 'Error Occured while sending email notifications', ex.getMessage());
      result='0#'+ex;
    }
    System.debug('result=' + result);
    return result;    
  }
  
  /**
    execute()
    - Used to invoke sendReminderEmail() via a scheduled job.
  */     
    global void execute(SchedulableContext sc) 
    {
    String result;
    DocuSignStatusTriggerClass dssTriggerClass = new DocuSignStatusTriggerClass();
    result = dssTriggerClass.sendReminderEmail();
    }
    
    /**
      pendingESignWithExpiredOrderFormEmailAlert()
      
      // below criteria is built-in to the formula field: 'sendOFExpiredAlert'
      //WHERE Order_Approval__c != null AND dsfs__Envelope_Status__c != null AND dsfs__Envelope_Status__c NOT IN :invalidEnvelopeStatus AND dsfs__Sender_Email__c != null AND 
      //sendOFExpiredAlert__c='Y' AND dsfs__DocuSign_Envelope_ID__c !=null AND isCustomerEnvelope__c AND CreatedDate>=LAST_N_YEARS:1])
    */
  public String pendingESignWithExpiredOrderFormEmailAlert()
  {
    if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('pendingESignWithExpiredOFAlert'))
      return '1:' + GsmUtilClass.featureToggleMsg('pendingESignWithExpiredOFAlert');
    
    String result='';
    Map<Id, dsfs__DocuSign_Status__c> dssExpiredOFMap = new Map<Id, dsfs__DocuSign_Status__c>();
    Set<Id> dssOpptyOwnerIdSet = new Set<Id>();
    Map<Id,Id> dssIdOpptyOwnerIdMap = new Map<Id,Id>();
    Map<Id,Id> dssIdSAUserIdMap = new Map<Id,Id>();
    String strDSEnvelopeExceptionStatus = DocuSignStatusTriggerClass.GetCustomSettingValue('DSEnvlopStatusInvalid'); 
    List<String> invalidEnvelopeStatus = strDSEnvelopeExceptionStatus.split('\\,');
      
    for (dsfs__DocuSign_Status__c dss : [SELECT Id,
    											Name,
    											sendOFExpiredAlert__c,
    											PreviousOFExpiredAlertsValidUntilDate__c,
    											dsfs__DocuSign_Envelope_ID__c,
    											dsfs__Envelope_Status__c,
    											CreatedById,
    											CreatedBy.isActive,
    											Order_Approval__c,
    											Order_Approval__r.Name,
    											Order_Approval__r.DD_CCG_Expiration_Date__c,
    											Order_Approval__r.Order_Expires_Unless_Duly_Executed_By__c,
    											Order_Approval__r.CCG_Owner__c,
    											Order_Approval__r.CCG_Owner__r.Name,
    											Order_Approval__r.CCG_Owner__r.Email, 
    											Order_Approval__r.CCG_Owner__r.isActive,
    											Order_Approval__r.Associated_Opportunity__c,
    											OA_Oppty_OwnerId__c,
    											Order_Approval__r.Opportunity_Owner__c
    											FROM dsfs__DocuSign_Status__c 
    											WHERE  sendOFExpiredAlert__c='Y'
    											AND dsfs__Envelope_Status__c != null
    											AND dsfs__Envelope_Status__c NOT IN :invalidEnvelopeStatus
    											AND CreatedDate>=LAST_N_YEARS:1])
    {
	    dssExpiredOFMap.put(dss.Id,dss);
	    dssOpptyOwnerIdSet.add(dss.OA_Oppty_OwnerId__c);
    }
    if (dssExpiredOFMap.size()<1)
	    return '1:No records to process.';

    System.debug('dss list=' + dssExpiredOFMap);  

    Set<Id> activeOpptyOwnerSet = new Set<Id>();
    for (User usr : [Select Id from User where Id IN : dssOpptyOwnerIdSet AND IsActive=true])
    {
	    activeOpptyOwnerSet.add(usr.Id);
    }  
    if (activeOpptyOwnerSet.size()<1)
	    return '1:No records were processed as zero active Opportunity Owners found.';

    System.debug('Active Oppty Owners=' + activeOpptyOwnerSet);
    //SFDC-2686
    String strOFExpiredEmailTemplateId_OA = GsmUtilClass.getGSMSettingValue('OFExpiredAlert_EmailTemplateId');
    String strOFExpiredEmailTemplateId_Agmt = GsmUtilClass.getGSMSettingValue('OFExpiredAlertForAgmt_EmailTemplateId');
    String strCRMAdminOrgWideId= GsmUtilClass.getGSMSettingValue('OrgWideId_CRMADMINS');
    String strCCEmailIds= GsmUtilClass.getGSMSettingValue('OFExpiredAlert_2CCEmailIds');
    String finalTemplateId;
    Messaging.SingleEmailMessage[] sendOFExpiredAlertEmailList = new List<Messaging.SingleEmailMessage>();
    String err = '';
    Integer emailIdcounter = 0;
    Id toEmail;
    String ccEmail;  
    Boolean inActiveOpptyOwner=false;
    List<String> errList = new List<String>();
    List<dsfs__DocuSign_Status__c> dsstoUpdateList = new List<dsfs__DocuSign_Status__c>();

    System.debug('strOFExpiredEmailTemplateId_OA=' + strOFExpiredEmailTemplateId_OA);
    System.debug('strOFExpiredEmailTemplateId_Agmt=' + strOFExpiredEmailTemplateId_Agmt);
    System.debug('strCRMAdminOrgWideId=' + strCRMAdminOrgWideId);

    for(dsfs__DocuSign_Status__c dss : dssExpiredOFMap.values())
    {
	    err = 'Errors for DSSID:' + dss.Id + '\n';
	    toEmail=null;
	    ccEmail='';
	    inActiveOpptyOwner=false;
	    finalTemplateId = dss.Order_Approval__c != null? strOFExpiredEmailTemplateId_OA : strOFExpiredEmailTemplateId_Agmt;

	    if(activeOpptyOwnerSet.contains(dss.OA_Oppty_OwnerId__c))
	    {
		    toEmail=dss.OA_Oppty_OwnerId__c;
		    emailIdcounter++;
	    }
	    else
	    {
		    err+= 'Inactive Oppty Owner.\n';
		    inActiveOpptyOwner=true;
	    }

	    if(dss.Order_Approval__r.CCG_Owner__c!=null && dss.Order_Approval__r.CCG_Owner__r.isActive)
	    {
		    ccEmail = dss.Order_Approval__r.CCG_Owner__r.Email;
		    emailIdcounter++;
	    }
	    else
		    err+= 'Inactive SA User.\n';

	    if (inActiveOpptyOwner || ccEmail=='')
	    {  
		    errList.add(err);
		    if (inActiveOpptyOwner)
			    continue;
	    }

	    if (strCCEmailIds!=null && strCCEmailIds.trim().contains('@'))
	    {
		    if (ccEmail=='')
			    ccEmail = strCCEmailIds;
		    else
			    ccEmail += ',' + strCCEmailIds;

	    }
	    sendOFExpiredAlertEmailList.add(GsmUtilClass.createSingleEmail(dss.Id,toEmail,ccEmail,finalTemplateId,strCRMAdminOrgWideId));  

	    // Process the DocuSign Request Record.

	  }

    System.debug('errList=' + errList);

    if (errList.size()>0)
    {
	    result ='\nErrors:\n' + errList;
	    System.debug('errList=' + errList);
    }

    if (sendOFExpiredAlertEmailList.size()<1)
	    return '1:No records to process.' + result;

    System.debug('sendOFExpiredAlertEmailList=' + sendOFExpiredAlertEmailList);

    result+='\nSending Email started:';
    Boolean HasError=false;
    integer count=0;
    integer failedcount=0;

    System.debug('emailIdcounter=' + emailIdcounter);
    Messaging.reserveSingleEmailCapacity(emailIdcounter);

    sendEmailResultList = Messaging.sendEmail(sendOFExpiredAlertEmailList, false);
    for(Messaging.SendEmailResult sr:sendEmailResultList)
    {
	    System.debug('sr=' + sr);
	    if(!sr.isSuccess())
	    {
		    //string err = sr.getErrors();//[0];
		    result+='\nError getMessage:'+sr.getErrors()[0].getMessage();
		    result+='##getFields:'+sr.getErrors()[0].getFields();
		    result+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
		    result+='##getTargetObjectId:'+sr.getErrors()[0].getTargetObjectId();
		    result+='##record count:'+count;
		    failedcount++;
		    HasError=true;
	    }
	    count++;
    }
    result+='\nNo. Of emails sent:'+(count-failedcount);

    if (dsstoUpdateList.size()>0)
	    update dsstoUpdateList;

    if (HasError)
	    return '0:' + result;
    else
	    return '1:' + result;
  }

  /**
    invokePendingESignWithExpiredOrderFormEmailAlert()
   */
  public static String invokePendingESignWithExpiredOrderFormEmailAlert()
  {  
	  String result = '';
	  try 
	  {
		  DocuSignStatusTriggerClass dsClassHandle = new DocuSignStatusTriggerClass();
		  result=dsClassHandle.pendingESignWithExpiredOrderFormEmailAlert();
		  return result;
	  } catch (Exception ex)
	  {
		  String errMsg = '0:###Exception(s) Occured###';
		  errMsg += '\n##Cause##=' + ex.getCause();
		  errMsg += '\n##At LineNumber##=' + ex.getLineNumber();
		  errMsg += '\n##Error Message##=' + ex.getMessage();
		  errMsg += '\n##Error Type##=' + ex.getTypeName();
		  errMsg += '\n##Stack Trace##=' + ex.getStackTraceString();
		  return errMsg + result;
	  }
  }
  
          public static String getErrorMessage() {
        String errorMessage;
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Not A Valid Contract';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Please validate if all required Fields are present';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Opportunity';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Account';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate pageReference';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate errorMessage';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        errorMessage+= '<b>';
        errorMessage+= '<p>';
        errorMessage+= 'Validate Test';
        errorMessage+= '</b>';
        errorMessage+= '</p>';
        
        return errorMessage;
    }
}