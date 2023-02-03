/*
Author : Shomil
Description: Trigger Class for sending out Email by Admin 
Created Date: 16/12/2014

CR 2923140 : nakodand - Added Idea Title in the mail    
WIZMIG-78 : ashish - Added Reply to fields for appbattery. Querying submitter using Sender__c because Sender__r.Email/Name was not working as expected
WIZARDS-118 : laxmi - Moving soql outside the loop
*/
public class Wizards_SendEmailByAdminTriggerClass {
    public static void sendEmail(List < IdeaEmail__c > ideaEmails) {
        String Subject = '';
        String Msg = '';
        String mailType = '';
        String feedbackType = '';
        Map<Id, String> ideaIdtoNameMap = new Map<Id, String>();
        Map<Id, User> usrIdtoUsrMap = new Map<Id, User>();
        Set<Id> IdeaId = new Set<Id>();
        Set<Id> userIds = new Set<Id>();

        Messaging.SingleEmailMessage[] listOfMail = new List < Messaging.SingleEmailMessage > ();
        for (IdeaEmail__c iEmail: ideaEmails) {
            IdeaId.add(iEmail.IdeaId__c);
            userIds.add(iEmail.Sender__c);
        }
        for (Idea wiz: [Select Id, Title from Idea where Id IN: IdeaId]) {
            ideaIdtoNameMap.put(wiz.Id, wiz.Title);
        }
        for (User usr: [Select Id, Name, Email from User where Id IN: userIds]) {
            usrIdtoUsrMap.put(usr.Id, usr);
        }
        
        for (IdeaEmail__c email: ideaEmails) {
            Subject = '';
            Msg = '';
            mailType = '';
            feedbackType = '';
            Messaging.SingleEmailMessage mailToBeSent = new Messaging.SingleEmailMessage();
            if (email.Mail_Type__c != NULL)
                mailType = email.Mail_Type__c;
            if (email.Feedback_Type__c != NULL)
                feedbackType = email.Feedback_Type__c;
            if (mailType.equalsIgnoreCase('IdeaMail'))
                Subject += 'Wizard ';
            else
                Subject += feedbackType + ' ';

            if (email.Subject__c != NULL)
                Subject += email.Subject__c;
            if (mailType.equalsIgnoreCase('IdeaMail')) {
                Msg = '<html><body>' + 'Click on the link below to view more about Idea<br/>';
                Msg += '<a href=https://wizards.akamai.com/#/idea/' + email.IdeaId__c + '>' + ideaIdtoNameMap.get(email.IdeaId__c) + '</a><br/><br/></html></body>';
            }
            if (email.Msg__c != NULL)
                Msg = Msg + email.Msg__c;
            if (mailType.equalsIgnoreCase('IdeaMail'))
                Msg += '<html><body>' + '<br/><hr>Best Regards,<br/>Team Wizards<br/>akamai-wizards@akamai.com' + '</html></body>';

            mailToBeSent.setHtmlBody(Msg);
            mailToBeSent.setSubject(Subject);

            //setting reply to
            if(!Test.isRunningTest()){
                if(usrIdtoUsrMap.get(email.Sender__c) != null) {
                    mailToBeSent.setReplyTo(usrIdtoUsrMap.get(email.Sender__c).Email.toLowerCase());
                    mailToBeSent.setSenderDisplayName(usrIdtoUsrMap.get(email.Sender__c).Name);
                }    
            }

            if (email.To__c != NULL){
                mailToBeSent.setToAddresses(email.To__c.split(';'));
            }

            listofMail.add(mailToBeSent);
        }
        if (listofMail.size() > 0)
            Messaging.sendEmail(listofMail);
    }
}