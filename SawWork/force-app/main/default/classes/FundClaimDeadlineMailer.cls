public class FundClaimDeadlineMailer
{
    
    public static String sendMails() 
    {
        List<String> statusList = new List<String>{'Approved', 'Closed'};
            /* Start Of SFDC-2261 */
            Date reminderDate = System.today() - Integer.valueOf(Label.NetAlliance_MDF_Alert_Interval);
            List<SFDC_MDF__c> fundRequestList = [SELECT Id,Owner.Id, Owner.Email,Program_End_Date__c FROM SFDC_MDF__c where 
                                                 (Program_End_Date__c = TODAY or Program_End_Date__c =: reminderDate) and Status__c IN :statusList and Owner.Id!=null and Owner.Email!=null];
            /* End Of SFDC-2261 */
        if(fundRequestList.size()==0)
            return 'No Fund Requests have passed activity end date';
        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id templateId60Days, templateIdGeneric; 
        try 
        {
            /* Start Of SFDC-2261 */
            for(EmailTemplate template : [Select Id, DeveloperName From EmailTemplate Where 
                                          (DeveloperName = 'Fund_Request_Deadline_Reminder' or DeveloperName = 'Fund_Claim_Deadline_Reminder')]){
                                              If(template.DeveloperName == 'Fund_Request_Deadline_Reminder')
                                                  templateId60Days = template.Id;
                                              Else
                                                  templateIdGeneric = template.Id;
                                          }
            /* End Of SFDC-2261 */
        }
        catch (Exception e) 
        {
            return 'Unable to locate EmailTemplate';
        }
        
        for (SFDC_MDF__c fundRequest : fundRequestList) 
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setWhatId(fundRequest.id);
            mail.setTargetObjectId(fundRequest.Owner.id);  
            /* Start Of SFDC-2261 */
            If(fundRequest.Program_End_Date__c == System.today())
                mail.setTemplateId(templateId60Days);
            Else
                mail.setTemplateId(templateIdGeneric);
            /* End Of SFDC-2261 */
            mail.setSaveAsActivity(false);
            mails.add(mail);
        }
        
        String resultMessage ='No. of emails to be sent - '+ mails.size()+'\n';
        integer failedcount=0;
        Integer count=0;
        Messaging.SendEmailResult[] sendEmailResultList = Messaging.sendEmail(mails, false);
        String statusMessage='';
        for(Messaging.SendEmailResult sr:sendEmailResultList)
        {
            if(!sr.isSuccess())
            {
                statusMessage+='\n Errored ID : ' + mails[count].getWhatId() + 'Error : ' + sr.getErrors()[0].getMessage();
                failedcount++;
            }
            else
            {
                statusMessage += '\n Succeeded ID : ' + mails[count].getWhatId();
            }
            count=count+1;
        }
        
        resultMessage+= 'Failure count - '+failedCount+'\n';
        return  resultMessage + statusMessage;
    }   
}