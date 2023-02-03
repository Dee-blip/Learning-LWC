/*=====================================================================================================+
    Class name                :   SCCaseAttachmentHandler 
    Purpose                   :   Methods to update and case and send emails on adding attachment or comments on the case
    
   Last Modified     Developer      CR              Purpose            
   =============     =========      ==              ======= 
   28-JUN-2016       Vamsee         3171341(16.7)   EPE Send Email Notification
   
+=====================================================================================================*/  

public class SCCaseAttachmentHandler {
    public static list<Case> lCasesToUpdate;
    public static list<string> lEmailTemplateIds;
    public static map<string, list<Attachment>> mCaseAndAttachments;
    public void updateCaseAndSendMail(map<string, list<Attachment>> mCaseAndAttachment){
        mCaseAndAttachments = mCaseAndAttachment;
        lCasesToUpdate = [SELECT Id,Recent_Update__c,OwnerId,Contact_Portal_Login__c,
                          Support_Level__c,Owner.email,Recordtype.Name,
                          Contact.Name,AKAM_Created_Date__c,Akam_Case_ID__c FROM Case 
                          WHERE Id IN :mCaseAndAttachment.keySet()];
        if(lCasesToUpdate.size()>0){
            updateCaseAlert(lCasesToUpdate);
            sendEmailToCaseOwner(lCasesToUpdate);
        }
    }
    public void sendEmailOnTaskCreation(list<Task> lTask, map<Id,Case> mCase){
        list<Messaging.SingleEmailMessage> lEmails = new list<Messaging.SingleEmailMessage>();
        for(Task varTask :lTask){
            if(String.valueOf(mCase.get(varTask.WhatId).OwnerId).startsWith('005')|| 
              (String.valueOf(mCase.get(varTask.WhatId).OwnerId).startsWith('00G') && mCase.get(varTask.WhatId).Recordtype.Name == 'Emerging Products Engineering' && mCase.get(varTask.WhatId).Support_Level__c == 'Reseller' && mCase.get(varTask.WhatId).Owner.email!= null)){
                Messaging.SingleEmailmessage email = new Messaging.SingleEmailMessage();    
                system.debug('!!!!!' + mCase.get(varTask.WhatId));
                email.setHtmlBody(createEmailBody(false,mCase.get(varTask.WhatId),varTask));
                email.setSaveAsActivity(false);
                //If target object is Queue then use method toAddresses
                if(String.valueOf(mCase.get(varTask.WhatId).OwnerId).startsWith('005')){
                       email.setTargetObjectId(mCase.get(varTask.WhatId).OwnerId);
                }else{
                       String[] toAddresses = new String[]{mCase.get(varTask.WhatId).Owner.email};
                       email.setToAddresses(toAddresses);
                }
                email.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('TechnialCaseNotification').OrgAddressId__c);
                email.setSubject(createEmailSubject(false, mCase.get(varTask.WhatId).Akam_Case_ID__c));
                lEmails.add(email);
            }
        }
        if(lEmails.size() >0)
        Messaging.sendEmail(lEmails);
    }
    private void updateCaseAlert(list<Case> lCases){
        for(Case varCase :lCases){
            if(!varCase.Recent_Update__c){
                varCase.Recent_Update__c = true;
            }
        }
        
        update lCases;
    }
    private void sendEmailToCaseOwner(list<Case> lCases){
        list<Messaging.SingleEmailMessage> lEmails = new list<Messaging.SingleEmailMessage>();
        //list<string> templateId = getEmailTemplateId();
        for(Case varCase :lCases){
            if(String.valueOf(varCase.OwnerId).startsWith('005')||
               (String.valueOf(varCase.OwnerId).startsWith('00G') && varCase.Recordtype.Name == 'Emerging Products Engineering' && varCase.Support_Level__c == 'Reseller' && varCase.Owner.email!= null)){
                Messaging.SingleEmailmessage email = new Messaging.SingleEmailMessage();
                email.setHtmlBody(createEmailBody(true,varCase,null));
                email.setSaveAsActivity(false);
                //If target object is Queue then use method toAddresses
                if(String.valueOf(varCase.OwnerId).startsWith('005')){
                       email.setTargetObjectId(varCase.OwnerId);
                }else{
                       String[] toAddresses = new String[]{varCase.Owner.email};
                       email.setToAddresses(toAddresses);
                }
                email.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('TechnialCaseNotification').OrgAddressId__c);
                email.setSubject(createEmailSubject(true, varCase.Akam_Case_ID__c));
                lEmails.add(email);
            }
        }  
        if(lEmails.size()>0)  
        Messaging.sendEmail(lEmails);
                    
    }
    /*
    private list<string> getEmailTemplateId(){
        lEmailTemplateIds = new list<string>();
        if(lEmailTemplateIds.size()==0){
            for(EmailTemplate varEmailTemplate :[SELECT Id,Name FROM EmailTemplate]){
                lEmailTemplateIds.add(varEmailTemplate.Id);
            }
        }
        
        return lEmailTemplateIds;
    }
    */
    private string createEmailBody(boolean isAttachment,Case varCase, Task varTask){
        //system.debug('%%%%%' + varTask.Description); 
        string emailBody = '';
        emailBody +=  varCase.Contact.Name + ' (' + varCase.Contact_Portal_Login__c +') has added ';
        emailBody +=  isAttachment? 'an Attachment ':'a Comment ';
        emailBody += 'to Case ' + varCase.AKAM_Case_ID__c + ' <br /><br />';
        emailBody +=  isAttachment? 'Attachment: <br />'+ mCaseAndAttachments.get(varCase.Id)[0].Name + '<br /><br />':'comment : <br />' + varTask.Description + '<br /><br />';
        emailBody += 'Link to Case: <br />' + '<a href=' + Environment_Setup__c.getOrgDefaults().CName_Url__c + varCase.Akam_Case_Id__c + '>Case</a><br /><br />';
        emailBody +=  isAttachment? 'Link to Attachment: <br />' +  '<a href=' + URL.getSalesforceBaseUrl().toExternalForm() + '/' +mCaseAndAttachments.get(varCase.Id)[0].Id + '>Attachment</a><br /><br />':
                                    'Link to Comment: <br />' +  '<a href=' + Environment_Setup__c.getOrgDefaults().CName_Url__c + varTask.AKAM_Activity_ID__c + '>Comment</a><br /><br />';
        return emailBody;
    }
    private string createEmailSubject(boolean isCase, string akamCaseId){
        string subject = '';
        if(isCase){
            subject = 'Customer Has Added an Attachment To Your Case: [AKAM-CASE #' + akamCaseId + ']';
        }
        else{
            subject = 'Customer Has Added a Comment To Your Case: [AKAM-CASE #' + akamCaseId + ']';
        }
        return subject;
    }
}