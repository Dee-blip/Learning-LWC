/**
@CreatedBy : Aayushi Agrawal
@CreatedDate : 12 Nov , 2020
@Purpose : SFDC-7505 - to send email on job failure
*/

public class SendEmailOnJobFailure{
    @InvocableMethod(label='Send Email on Job Failure' description='Send Email on Job Failure' category='Job_Scheduler__c')
    public static void sendEmailOnFailure(List<ID> ids) {
        List<Job_Scheduler__c> jobSchedulerList = [SELECT ID, Email_Receipients__c,job_id__c,Name ,(SELECT ID , Error_Message__c FROM Job_Runs__r order by createdDate desc limit 1) 
        FROM Job_Scheduler__c WHERE id in : ids and Email_Receipients__c != null];
        List<Messaging.SingleEmailMessage > mailList = new List<Messaging.SingleEmailMessage >();
               
        for(Job_Scheduler__c js : jobSchedulerList){
            if(js.Job_Runs__r.size() > 0){
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                List<String> toListEmail = new List<String>();
                List<String> emailReceipients = js.Email_Receipients__c.split(',');
                toListEmail.addAll(emailReceipients);
                message.setToAddresses(ToListEmail); 
                String emailText = js.Job_Runs__r[0].error_message__c;
                message.setHTMLBody (emailText);
                message.setSubject(js.name +' Failure');
                mailList.add(message);
               
            }
        }
        Messaging.sendEmail(mailList);         
                 
    }
}