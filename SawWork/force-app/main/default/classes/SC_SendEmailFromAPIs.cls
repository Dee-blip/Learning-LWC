/*
Author          : Kunal Sharma
Changes by Sharath for considering escalation via case email
*/

public without sharing class SC_SendEmailFromAPIs {
  public SC_SendEmailFromAPIs() {
  }
  String invalidEmailAddress = '';
  public Static Boolean sendEmailFromMuleSoft = false;
  public Static String senderId = '';
  private Boolean validateEmailAddresses(
    List<String> lCaseIds,
    Map<String, String> mAddressToValidate
  ) {
    List<Case> lCaseToSendEmail = [
      SELECT AuthorizedContacts__c, Contact.Email,Case_Situation_Handler__r.Handler__r.Escalation_List__c,
        Policy_Domain__c,Case_Situation_Handler__c,Do_Not_Show_in_Portal__c
      FROM Case
      WHERE Id IN :lCaseIds
    ];
    Set<Id> escalationIds = new Set<Id>();
    for(Case caseRec: lCaseToSendEmail)
    {
        if(!caseRec.Do_Not_Show_in_Portal__c && 
           caseRec.Case_Situation_Handler__c != null && caseRec.Policy_Domain__c != null && caseRec.Case_Situation_Handler__r.Handler__r.Escalation_List__c != null)
        {
            escalationIds.add(caseRec.Case_Situation_Handler__r.Handler__r.Escalation_List__c);
        }
    }
    Map<Id,Set<String>> escalationToEmails = new Map<Id,Set<String>>();
    if(!escalationIds.isEmpty())
    {
        for (SC_SOCC_Escalation_via_Case_Email__c emailRec: [Select Authorized_Contact__r.Contact_Name__r.Email,Escalation_List__c from 
                                                             SC_SOCC_Escalation_via_Case_Email__c where Escalation_List__c in :escalationIds and Authorized_Contact__r.Contact_Name__r.Email != null])
        {
            if(!escalationToEmails.containsKey(emailRec.Escalation_List__c))
            {
                escalationToEmails.put(emailRec.Escalation_List__c,new Set<String> ());
            }
            escalationToEmails.get(emailRec.Escalation_List__c).add(emailRec.Authorized_Contact__r.Contact_Name__r.Email.trim());
        }
    }
    System.debug('######## %%% ' + lCaseToSendEmail);  
    Set<String> sValidEmailIds = new Set<String>();
    for (Case varCase : lCaseToSendEmail) {
      if (varCase.AuthorizedContacts__c != null) 
      {
          List<String> authContacts = varCase.AuthorizedContacts__c.replace(';',',').replaceAll('\r\n|\n',',').split(',');
          for(String eachEmail : authContacts)
          {
              if(String.isNotBlank(eachEmail))
                  sValidEmailIds.add(eachEmail.trim());
          }
      }
      sValidEmailIds.add(varCase.Contact.Email);
      if(varCase.Case_Situation_Handler__r.Handler__r.Escalation_List__c != null && 
         escalationToEmails.containsKey(varCase.Case_Situation_Handler__r.Handler__r.Escalation_List__c))
      {
          sValidEmailIds.addAll(escalationToEmails.get(varCase.Case_Situation_Handler__r.Handler__r.Escalation_List__c));
      }
      for (
        String varToAddresses : mAddressToValidate.get(varCase.Id).split(',')
      ) {
            System.debug('###EmailAddressList sValidEmailIds ' + varToAddresses + ' ' + sValidEmailIds);
        if (  
          !String.isBlank(varToAddresses) &&       
          varToAddresses != 'null' &&
          !sValidEmailIds.contains(varToAddresses) &&
          varToAddresses != '' &&
          !varToAddresses.containsIgnoreCase('@akamai.com')
        ) {
          System.debug('###EmailAddressListError ' + varToAddresses);
          System.debug('###validList ' + sValidEmailIds);
          invalidEmailAddress = varToAddresses;
          return false;
        }
      }
    }
    return true;
  }

  private List<String> getListFromString(String stringToConvert) {
    if (stringToConvert != null) {
      return stringToConvert.split(',');
    }
    return null;
  }

  /*private Map<String, String> getParentEmailId(List<String> lCaseIds) {
    Map<String, String> mCaseIdAndEmailMessageBody = new Map<String, String>();
    List<EmailMessage> lEmailMessages = [
      SELECT
        Id,
        ParentId,
        FromName,
        FromAddress,
        ToAddress,
        CcAddress,
        TextBody,
        HtmlBody
      FROM EmailMessage
      WHERE ParentId IN :lCaseIds
      ORDER BY CreatedDate DESC
    ];
    for (EmailMessage varEmailMessage : lEmailMessages) {
      if (!mCaseIdAndEmailMessageBody.containsKey(varEmailMessage.ParentId)) {
        String previousThread =
          varEmailMessage.FromAddress +
          '<br>' +
          varEmailMessage.ToAddress +
          '<br>';
        previousThread += varEmailMessage.CcAddress;
        mCaseIdAndEmailMessageBody.put(
          varEmailMessage.ParentId + 'tBody',
          previousThread + varEmailMessage.TextBody
        );
        mCaseIdAndEmailMessageBody.put(
          varEmailMessage.ParentId + 'hBody',
          previousThread + varEmailMessage.HtmlBody
        );
      }
    }
    return mCaseIdAndEmailMessageBody;
  }*/

  public void sendEmailToCase(
    List<Case_Email_Content__c> lCaseEmailContent,
    Map<Id, Case_Email_Content__c> mCaseEmailContent
  ) {
    List<Messaging.SingleEmailMessage> lEmailsToSend = new List<Messaging.SingleEmailMessage>();
    Map<String, String> mAddressToValidate = new Map<String, String>();
    Map<String, String> mCaseIdToCaseEmailContentId = new Map<String, String>();
    List<String> lCaseIds = new List<String>();
    List<String> contentVersionIdList = new List<String>();
    //  lCaseIds.addAll(mCaseEmailContent.keySet());
    for (Case_Email_Content__c varCaseEmailContent : lCaseEmailContent) {
        senderId = varCaseEmailContent.Sender__c;
      lCaseIds.add(varCaseEmailContent.Case__c);
      mAddressToValidate.put(
        varCaseEmailContent.Case__c,
        varCaseEmailContent.To_Addresses__c +
        ',' +
        varCaseEmailContent.CC_Addresses__c +
        ',' +
        varCaseEmailContent.BCC_Addresses__c
      );
      mCaseIdToCaseEmailContentId.put(
        varCaseEmailContent.Case__c,
        varCaseEmailContent.Id
      );
      if(varCaseEmailContent.Email_Attachment_Ids__c != NULL )
        contentVersionIdList.addAll(varCaseEmailContent.Email_Attachment_Ids__c.split(','));
    }
    Map<Id, ContentVersion> contVersMap = new Map<id, ContentVersion>();
    if(contentVersionIdList.size() > 0)
      contVersMap = new Map<id, ContentVersion>([SELECT Id, Title, FileExtension , VersionData FROM ContentVersion where  id In: contentVersionIdList]);
    if (!validateEmailAddresses(lCaseIds, mAddressToValidate)) {
      lCaseEmailContent[0].addError('Bummer! It looks like ' + invalidEmailAddress + ' is not available on the "Additional Emails" field on Case, or "Notify via Case Email" preferences in Runbook Escalation List.');
    }
    Map<String, String> mCaseIdAndEmailMessageBody = new Map<String, String>(); //getParentEmailId(lCaseIds);
    for (Case_Email_Content__c varCaseEmailContent : lCaseEmailContent) {
      String textBody = '';
      String htmlBody = '';
      if (
        mCaseIdAndEmailMessageBody.containsKey(
          varCaseEmailContent.Case__c + 'tBody'
        )
      ) {
        textBody = mCaseIdAndEmailMessageBody.get(
          varCaseEmailContent.Case__c + 'tBody'
        );
      }
      if (
        mCaseIdAndEmailMessageBody.containsKey(
          varCaseEmailContent.Case__c + 'hBody'
        )
      ) {
        htmlBody = mCaseIdAndEmailMessageBody.get(
          varCaseEmailContent.Case__c + 'hBody'
        );
      }

      Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
      emailToSend.setHtmlBody(varCaseEmailContent.Email_Body__c + htmlBody);
      emailToSend.setPlainTextBody(
        varCaseEmailContent.Email_Body__c + textBody
      );
      emailToSend.setToAddresses(
        getListFromString(varCaseEmailContent.To_Addresses__c)
      );
      emailToSend.setCcAddresses(
        getListFromString(varCaseEmailContent.CC_Addresses__c)
      );
      emailToSend.setBccAddresses(
        getListFromString(varCaseEmailContent.BCC_Addresses__c)
      );
      List<Messaging.Emailfileattachment> fileAttachments = new list<Messaging.Emailfileattachment>();
      if( varCaseEmailContent.Email_Attachment_Ids__c != NULL )  {
          for(String cvId : getListFromString(varCaseEmailContent.Email_Attachment_Ids__c)){
              if(contVersMap.containsKey(cvId)){
                  Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
                  attachment.setBody(contVersMap.get(cvId).VersionData);
                  attachment.setFileName(contVersMap.get(cvId).Title); 
                  attachment.setContenttype(setAttachmentContentType(contVersMap.get(cvId).FileExtension));
                  fileAttachments.add(attachment); 
              }
          }
          
      }
      if(fileAttachments.size()>0)
          emailToSend.setFileAttachments (fileAttachments); 
      emailToSend.setSubject(varCaseEmailContent.Email_Subject__c);
      emailToSend.setWhatId(varCaseEmailContent.Case__c);
      emailToSend.setOrgWideEmailAddressId(varCaseEmailContent.From_Email_Address__c);
      //emailToSend.setReferences(mCaseIdAndEmailMessageBody.get(varCaseEmailContent.Case__c));
      lEmailsToSend.add(emailToSend);
    }
    sendEmailFromMuleSoft = true;
    Messaging.sendEmail(lEmailsToSend);
  }
  
  public String setAttachmentContentType(string ct){
        if( ct == 'pdf')
            return 'application/pdf';
        else if( ct == 'png')
            return 'image/png';
        else if( ct == 'xlsx' || ct == 'xls')
            return 'application/vnd.ms-excel';
        else if( ct == 'docx' || ct == 'doc')
            return 'application/msword';
        else if( ct == 'snote')
            return 'text/snote';
        else if( ct == 'jpg' || ct == 'jpeg')
            return 'image/jpeg';
        else if( ct == 'text')
            return 'text/plain';
        else if( ct == 'ppt' || ct == 'pptx')
            return 'application/vnd.ms-powerpoint';
        else if( ct == 'xlsm')
            return 'application/vnd.ms-excel.sheet.macroEnabled.12';
        else if( ct == 'zip')
            return 'application/zip';
        else if( ct == 'csv')
            return 'text/csv';
        else if( ct == 'gif')
            return 'image/gif';
        else if( ct == 'rtf')
            return 'text/rtf';
        else if( ct == 'mp4')
            return 'audio/mp4';
        else if( ct == 'tiff' || ct == 'tif')
            return 'image/tiff';
        else if( ct == 'html' || ct == 'htm')
            return 'text/html';
        else return '';
    }
}