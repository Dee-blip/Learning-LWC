/*
CR 2812593 - Email preview in Mailer not working for HTML templates 
Created On: 1 January 2016
Created By: ssawhney
Description: Controller class to display the preview for email templates 
*/
public class Eb_CntlEmailPreview
{
    public String htmlBody {get;set;}
    public List<String> textBody {get;set;}
    public boolean isTextEmail {get;set;}
    private String contactId;
    private String templateId;
    private String akamContactId;

    public Eb_CntlEmailPreview()
    {
        akamContactId = ApexPages.currentPage().getParameters().get('Id');
        String mailerType = ApexPages.currentPage().getParameters().get('MailerType');
              
        //Fetch the mailer details 
        EB_AkaMContact__c akamContact = [select EB_Contact__c, EB_AkaMAccount__r.EB_AkaMailer__r.Id from EB_AkaMContact__c where Id = :akamContactId];

        String mailerId = akamContact.EB_AkaMAccount__r.EB_AkaMailer__r.Id;
        contactId = akamContact.EB_Contact__c;
        if(mailerType == 'Single Email')
        {
            templateId = [select EB_TemplateId__c from EB_AkamContact__c where Id = :akamContactId].EB_TemplateId__c;

        }
        else if(mailerType == 'Mass Email')
        {
            templateId = [select Email_Template__r.EB_SFEmailTemplateId__c from EB_AkaMailer__c where Id = :mailerId].Email_Template__r.EB_SFEmailTemplateId__c;
            if(templateId == null || templateId == '')
            {
                ApexPages.Message myMsg1;
                myMsg1 = new ApexPages.Message(ApexPages.Severity.FATAL,'Email Template at the Mailer cannot be blank for Mass Emails.');
                ApexPages.addMessage(myMsg1);
            }
        }
    }

    public void FetchEmailBody()
    {
    	try
        {
			//Send the emails and then rollback the transaction
            //This is a kind of hack to make sure the letter head is merged and all merged field values are correctly displayed
            if(templateId!=null && akamContactId != null)
		    {
		        isTextEmail = false;
                Messaging.reserveSingleEmailCapacity(1);
		        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		        email.setUseSignature(false);
				email.setSaveAsActivity(false);
				email.setTargetObjectId(contactId);
				email.setTemplateId(templateId);
				email.setWhatId(akamContactId);

		        Savepoint sp = Database.setSavepoint();
		        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
			    Database.rollback(sp);

			    htmlBody = email.getHTMLBody();
		    	if(htmlBody == null)
		    	{
		    		textBody = email.getPlainTextBody().split('\n');
                    isTextEmail = true;
		    	}
		    }
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg;
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'This Email Template has been deleted');
            ApexPages.addMessage(myMsg);
        }
    }
}