/*
 * Author   : Vamsee Surya S
 * Date     : 28th Feb 2017
 * Purpose  : This class is the controller of CMC_EmailPreview page and it will be used to display the Email Preview.
 *            This is implemented as part of CMC project (CR 3426181)             
 */
public class CMC_EmailPreviewCtrl {
    public String htmlBody {get;set;}
    //This is to display the subject
    public String subject{get;set;}
    
    //This list stores the Email body
    public List<String> textBody {get;set;}
    public boolean isTextEmail {get;set;}
    
    //This is to store the Mailer Id
    public string mailerId;
    
    //Email Preview will be stored as attachment on the mailer. This String will store the Email body
    Public String emailBody;
    
    //Contructor
    Public CMC_EmailPreviewCtrl(){
        mailerId = ApexPages.currentPage().getParameters().get('mailerId');
    }
    
    //Method to display the Email Preview
    public void FetchEmailBody(){
        Try{
            EB_AkaMailer__c mailerObject = [SELECT CMC_Template_ID__c, CMC_Subject__c , EB_AdditionalIssueDescription__c FROM EB_AkaMailer__c WHERE Id =:mailerId LIMIT 1];
            Messaging.SingleEmailMessage emailMessage=new Messaging.SingleEmailMessage();
            //If Template is not selected
            if(String.isBlank(mailerObject.CMC_Template_ID__c)){
                List<String> toAddress = new List<String>();
                toAddress.add(userinfo.getUserEmail());
                emailMessage.setToAddresses(toAddress);
                emailMessage.setSubject(mailerObject.CMC_Subject__c);
                emailMessage.setHtmlBody(mailerObject.EB_AdditionalIssueDescription__c);  
            }
            //If Template is Selected
            else{
                isTextEmail = false;
                Contact userContact = [Select Id from Contact where email =: userinfo.getUserEmail() Limit 1];
                Messaging.reserveSingleEmailCapacity(1);
                emailMessage.setUseSignature(false);
                emailMessage.setSaveAsActivity(false);
                emailMessage.setTargetObjectId(userContact.Id);
                emailMessage.setTemplateId(mailerObject.CMC_Template_ID__c);
                emailMessage.setWhatId(mailerObject.Id);
            }
            //Get the Email Preview and rollback the changes
            Savepoint sp = Database.setSavepoint();
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {emailMessage});
            //Email will not send because of rollback
            Database.rollback(sp);
            subject = emailMessage.getSubject();
            htmlBody = emailMessage.getHTMLBody();
            emailBody = htmlBody;
            if(htmlBody == null){
                emailBody = emailMessage.getPlainTextBody().replaceAll('\n','<br/>');
                textBody = emailMessage.getPlainTextBody().split('\n');
                isTextEmail = true;
            }
      
        }
        Catch(Exception ex){
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    //This method will called on click of Send mailer
    public void PostMailer(){
        System.debug('---Entered PostMailer Method---');
        //Creating the attachment to store the email preview on the mailer
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf(emailBody);
        attachment.Name = String.valueOf('EmailPreview.html');
        attachment.ParentId = mailerId;
        insert attachment;
        System.debug('---attachment---'+ attachment.Id);
        //Sending Emails
        CMC_postMailerActivityBatchJob  postMailerJob = new CMC_postMailerActivityBatchJob(null, true, mailerId);
        postMailerJob.postMailerActivity(mailerId);
        System.debug('---Exited PostMailer Method---');
        
    }
}