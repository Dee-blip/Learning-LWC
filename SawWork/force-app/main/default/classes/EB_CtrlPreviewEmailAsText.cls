/*
#########################################
Author: Jayalakshmi A
Description: Provide preview for text based email templates
Modified : On 10/06/2010 by janantha for incliding the merge fields from EB_AkaMailer__c object.CR# 794811
           On 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
           On 11/14/2011 by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
##########################################
*/
public class EB_CtrlPreviewEmailAsText
{
    public String subject{get;set;}
    public String body{get;set;}
    public List<String> bodyWithLineBreaks{get;set;}
    public String contactId;
    public String templateId;
    //start of changes On 10/06/2010 by janantha for incliding the merge fields from EB_AkaMailer__c object.CR# 794811
    public String mailerId;
    //end of changes On 10/06/2010 by janantha for incliding the merge fields from EB_AkaMailer__c object.CR# 794811
    public EmailTemplate emailTemplate;
    //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    public String mailerType;
    //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    public EB_CtrlPreviewEmailAsText()
    {
        contactId = ApexPages.currentPage().getParameters().get('id');
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        mailerType = ApexPages.currentPage().getParameters().get('MailerType');
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        
        //start of changes on 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
        try
        {
        //end of changes on 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
            //start of changes On 10/06/2010 by janantha for incliding the merge fields from EB_AkaMailer__c object.CR# 794811
            mailerId = [select EB_AkaMAccount__r.EB_AkaMailer__r.Id from EB_AkaMContact__c where Id = :contactId].EB_AkaMAccount__r.EB_AkaMailer__r.Id;
            //System.assertEquals(mailerId,'def');
            //end of changes On 10/06/2010 by janantha for incliding the merge fields from EB_AkaMailer__c object.CR# 794811
            
            //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
            if(mailerType == 'Single Email')
            {
                templateId = [select EB_TemplateId__c from EB_AkamContact__c where Id = :contactId].EB_TemplateId__c;
            }
            else if(mailerType == 'Mass Email')
            {
                templateId = [select Email_Template__r.EB_SFEmailTemplateId__c from EB_AkaMailer__c where Id = :mailerId].Email_Template__r.EB_SFEmailTemplateId__c;
                //System.assertEquals(templateId,'abc');
                if(templateId == null || templateId == '')
                {
                    ApexPages.Message myMsg1;
                    myMsg1 = new ApexPages.Message(ApexPages.Severity.FATAL,'Email Template at the Mailer cannot be blank for Mass Emails.');
                    ApexPages.addMessage(myMsg1);
                }
            }
            //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
            
            emailTemplate = [select subject, body from EmailTemplate where Id = :templateId];
        //start of changes on 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
        }
        catch(System.QueryException e)
        {
            ApexPages.Message myMsg;
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'This Email Template has been deleted');
            ApexPages.addMessage(myMsg);
        }
        
        if(emailTemplate!=null)
        {
            subject = emailTemplate.subject;
            body = emailTemplate.body;
            body = substitute(body, contactId);
            bodyWithLineBreaks = body.split('\n');
        }
        //end of changes on 11/2/2010 by janantha for checking if the email template is deleted. CR#856235
    }
    
    public String substitute(String emailBody, String contactId) {
        
        List<String> objects = new List<String>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
        Map<String, String> fieldsValues = new Map<String,String>{}; 
        
        objects.add('EB_AkaMContact__c');
        //start of changes On 10/06/2010 by janantha for incliding the merge fields from EB_AkaMailer__c object.CR# 794811
        objects.add('EB_AkaMailer__c');
        //end of changes On 10/06/2010 by janantha for incliding the merge fields from EB_AkaMailer__c object.CR# 794811
        for (String objName : objects){
            
            Schema.SObjectType obj = gd.get(objName) ;
            Map<String, Schema.SObjectField> M = obj.getDescribe().fields.getMap() ;
            String objFields = '';
            for (Schema.SObjectField field : M.values()){
                    String fieldname = field.getDescribe().getName();
                    objFields += fieldname + ',';
            }
            
            objFields = objFields.substring(0, objFields.lastIndexOf(',')); //trim last comma;
            System.debug('objFields: ' + objFields);  
            Sobject relObj;
            String qryString = 'SELECT ' + objFields + ' FROM ' + objName + ' WHERE Id = '+'\''+contactId+'\'' + ' or Id = '+'\''+mailerId+'\'';
            //System.assertEquals(qryString,null);
            relObj = Database.query(qryString + ' limit 1');    
            
            for(String s : M.keySet()) {
                 try {
                     
                     if (relObj.get(s) != null){
                        fieldsValues.put('{!' + objName + '.' + m.get(s).getDescribe().getName() + '}', String.valueOf(relObj.get(s)) );
                     } else {
                        fieldsValues.put('{!' + objName + '.' + m.get(s).getDescribe().getName() + '}', '');
                     }
                 } catch(System.Exception e) {
                     
                 }
            }
    
        }
        //System.assertEquals(fieldsValues.keySet(),null);
        for(String s : fieldsValues.keySet()) {
            
            if(emailBody.contains(s))
            {
                emailBody = emailBody.replace(s, fieldsValues.get(s));
                //System.assertEquals(s,null);
            }
        }
        return emailBody;
    }
}