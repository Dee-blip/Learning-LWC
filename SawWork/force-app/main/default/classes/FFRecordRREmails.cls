/***
Author: janantha
Description: This class processes all the emails on Resource Request object including attachments.
            CR - 2922042.
Date: 10/3/2015
*/

global class FFRecordRREmails implements Messaging.InboundEmailHandler 
{
  static String plainTextBody = '';
  static String tempSubStr = '';
  static integer indexOfBracket;
  static String rrId = '';
  static Integer indexOfRRForResourceHeld;
  static integer indexOfFirstSpaceForResourceHeld;
  static String rrIdForResourceHeld = '';
  static String tempSubStrForResourceHeld = '';
  static String commaSepratedToAddresses='';
  static String commaSeparatedCcAddresses = '';

  /* This method processes the email body and attachments and inserts this data to salesforce */
  public static void insertEmailToRR(String rrName,Messaging.InboundEmail email)
  {
    PSA_RR_Notes_And_Attachments__c emailDetails = new PSA_RR_Notes_And_Attachments__c();
    List<Attachment> attachments = new List<Attachment>();
    emailDetails.Subject__c = email.subject;
    if(email.toAddresses != null && email.toAddresses.size()>0)
    {
      for(String str : email.toAddresses)
      {
        commaSepratedToAddresses += str + ',' ;
      }
      
      commaSepratedToAddresses = commaSepratedToAddresses.subString(0,commaSepratedToAddresses.length()-1);
      emailDetails.To__c = commaSepratedToAddresses;   
    }
    if(email.ccAddresses != null && email.ccAddresses.size()>0)
    {
      for(String str : email.ccAddresses)
      {
        commaSeparatedCcAddresses += str + ',' ; 
      }
      commaSeparatedCcAddresses = commaSeparatedCcAddresses.subString(0,commaSeparatedCcAddresses.length()-1);
      emailDetails.CC__c = commaSeparatedCcAddresses;    
    }

    if(email.htmlBody != null)
    {
        if(email.htmlBody.length()>131072)
        {
          emailDetails.Email_Body__c = email.htmlBody.substring(0,131071);
        }
        else
        {
          emailDetails.Email_Body__c = email.htmlBody;
        }
    }
    else
    {
      if(email.plainTextBody != null)
      {
        if(email.plainTextBody.length()>131072)
        {
          plainTextBody = email.plainTextBody.substring(0,131071).replaceAll('\n','<br/>');
          emailDetails.Email_Body__c = plainTextBody;
        }
        else
        {
          plainTextBody = email.plainTextBody.replaceAll('\n','<br/>');
          emailDetails.Email_Body__c = plainTextBody;
        }
      }
    }
    
    emailDetails.From_Address__c = email.fromAddress;
    emailDetails.Date__c = Datetime.now();

    Id parentRRId = [select Id from pse__Resource_Request__c where Name = :rrName].Id;
    emailDetails.Resource_Request__c = parentRRId;
    insert emailDetails;   
    
    if(email.textAttachments != null && email.textAttachments.size()>0)
    {
        for (integer i = 0 ; i < email.textAttachments.size() ; i++) 
        {
            Attachment attach = new Attachment();
            String textAtt = String.valueOf(email.textAttachments[i].body);
            EncodingUtil.urlEncode(textAtt, 'UTF-8');
            attach.body = Blob.valueOf(textAtt);
            attach.name = email.textAttachments[i].fileName;
            attach.ParentId = emailDetails.Id;
            attachments.add(attach);          
        }
    }  
    
    if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) 
    {
      for (integer i = 0 ; i < email.binaryAttachments.size() ; i++) 
      {
          Attachment attachment = new Attachment();
          
          attachment.ParentId = emailDetails.Id;
          attachment.Name = email.binaryAttachments[i].filename;
          attachment.Body = email.binaryAttachments[i].body;
          attachments.add(attachment);
      }
    } 
    if(attachments!=null && attachments.size()>0)
        insert attachments;  
  } 

  global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
  {
    Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
    String emailSubject = email.subject;

    /* Subject line always should contain 'Resource Request' followed by the RR name */
    Integer indexOfRR = emailSubject.IndexOf('AKAM-RR #');
    System.debug('**** indexOfRR '+indexOfRR);
    if(indexOfRR != -1)
    {
        indexOfRR = indexOfRR + 9;       
        tempSubStr = emailSubject.substring(indexOfRR);
        indexOfBracket = tempSubStr.IndexOf(']');   
        /* This will give the RR name */
        rrId = tempSubStr.substring(0,indexOfBracket);
        System.debug('**** rrId '+rrId);
        insertEmailToRR(rrId,email);       
        return result;
    }
    /*else
    {
        indexOfRRForResourceHeld = emailSubject.indexOf('RR');
        if(indexOfRRForResourceHeld != -1)
        {
            indexOfRRForResourceHeld = indexOfRRForResourceHeld;
            tempSubStrForResourceHeld = emailSubject.substring(indexOfRRForResourceHeld);
            
            indexOfFirstSpaceForResourceHeld = tempSubStrForResourceHeld.indexOf(' ');

            rrIdForResourceHeld = tempSubStrForResourceHeld.substring(0,indexOfFirstSpaceForResourceHeld);
            
            insertEmailToRR(rrIdForResourceHeld,email); 
        }        
        
        
    }*/
    return null;
  }
}