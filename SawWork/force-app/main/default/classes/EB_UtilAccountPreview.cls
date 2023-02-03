/* @author:Jayalakshmi (janantha@akamai.com)
   @version:1.0
   @created date:17/08/2010
   @description: Email Preview at the Mailer Account. 
   This function takes the Mailer Account Id as the input and returns the preview url for text and html emails.
   @Modified on: 11/14/11 for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
                 01/01/16 by ssawhney for changing the email preview link CR# 2812593
*/

global class EB_UtilAccountPreview
{
    webservice static String getAkamContactId(String akamAccountId)
    {
        String url = EB_UtilApplication.getProperty_EnvironmentURL();
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        EB_AkaMAccount__c akamAccount = [select Id,EB_MailerType__c,(select Id from EB_AkaMContacts__r limit 1) from EB_AkaMAccount__c where Id = :akamAccountId];
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        EB_AkaMContact__c akamContact = akamAccount.EB_AkaMContacts__r;
        String akamContactId = akamContact.Id;

        //Added by ssawhney for CR 2812593
        String previewUrl = '/apex/EB_EmailPreview?Id='+akamContactId+'&MailerType='+akamAccount.EB_MailerType__c;
        return previewUrl;
        //commented out by ssawhney for CR 2812593
        /*
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        if(akamAccount.EB_MailerType__c == 'Single Email')
        { 
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
            String templateId = akamAccount.Email_Template__r.EB_SFEmailTemplateId__c;
            
            if(akamAccount.Email_Template__r.EB_Template_Type__c == 'html')
            {
                String previewHtml = url+'email/author/emailauthorframe.jsp?email_type=html&template_id='+ templateId +'&id=00YS0000000S3Zk&p2_lkid=' +'&p3_lkid='+ akamContactId+'&preview=1'; 
                return previewHtml;
            }
            else if(akamAccount.Email_Template__r.EB_Template_Type__c == 'text')
            {
                //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
                String textUrl = url+'apex/EB_VfpPreviewEmailAsText?Id='+akamContactId+'&MailerType='+akamAccount.EB_MailerType__c;
                //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
                return textUrl;
            }
            return '';
        }
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        else if(akamAccount.EB_MailerType__c == 'Mass Email')
        {
            String template = akamAccount.EB_AkaMailer__r.Email_Template__r.EB_SFEmailTemplateId__c;
            
            if(akamAccount.EB_AkaMailer__r.Email_Template__r.EB_Template_Type__c == 'html')
            {
                String previewHtml = url+'email/author/emailauthorframe.jsp?email_type=html&template_id='+ template +'&id=00YS0000000S3Zk&p2_lkid=' +'&p3_lkid='+ akamContactId+'&preview=1'; 
                return previewHtml;
            }
            else if(akamAccount.EB_AkaMailer__r.Email_Template__r.EB_Template_Type__c == 'text')
            {
                String textUrl = url+'apex/EB_VfpPreviewEmailAsText?Id='+akamContactId+'&MailerType='+akamAccount.EB_MailerType__c;
                return textUrl;
            }
            return '';
        }
        return '';
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        */
    }
}