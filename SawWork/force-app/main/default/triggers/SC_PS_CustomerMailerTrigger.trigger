trigger SC_PS_CustomerMailerTrigger on PS_Customer_Mailers__c (before update,before delete) {
    
    // Before update logic for sending reminder emails
    /*if(trigger.isBefore && trigger.isUpdate){
        messaging.SingleEmailMessage mailerInstance = new messaging.SingleEmailMessage();
        List<messaging.SingleEmailMessage> finalMailerList = new List<messaging.SingleEmailMessage>();
        List<String> toUserIds = new List<String>();
        List<Id> applicableMailersForReminder = new List<Id>();

        for(PS_Customer_Mailers__c iteratedMailerRec : trigger.new){
            if((trigger.oldMap.get(iteratedMailerRec.Id).Reminder_Mail_sent_to_SC__c == false && iteratedMailerRec.Reminder_Mail_sent_to_SC__c && iteratedMailerRec.Team_Member_Id__c != '' && iteratedMailerRec.Team_Member_Id__c != null) 
             ||
                (trigger.oldMap.get(iteratedMailerRec.Id).Reminder_Mail_sent_to_Managers__c == false && iteratedMailerRec.Reminder_Mail_sent_to_Managers__c && iteratedMailerRec.Manager_Id__c != '' && iteratedMailerRec.Manager_Id__c != null))
                {
                    applicableMailersForReminder.add(iteratedMailerRec.Id);
                }
        } 
        // Creating map to fetch Account name from mailer record while sending reminder email.
        Map<Id,PS_Customer_Mailers__c> mailerMap = new Map<Id,PS_Customer_Mailers__c>([Select Id,Account__r.Name from PS_Customer_Mailers__c where Id IN:applicableMailersForReminder ]);
        
        for(PS_Customer_Mailers__c iteratedMailerRec : trigger.new){
            if(trigger.oldMap.get(iteratedMailerRec.Id).Reminder_Mail_sent_to_SC__c == false && iteratedMailerRec.Reminder_Mail_sent_to_SC__c && iteratedMailerRec.Team_Member_Id__c != '' && iteratedMailerRec.Team_Member_Id__c != null){
           System.debug(iteratedMailerRec.Team_Member_Id__c);
                toUserIds = iteratedMailerRec.Team_Member_Id__c.split(';');

            mailerInstance = SC_PSAutomationController.mailerInstanceCreationMethod(toUserIds,'Customer Mailer Publish reminder email for SC','Hi , <br/> <br/>You have not taken any action on Customer Mailer record : '+iteratedMailerRec.Name+' created for Account : '+mailerMap.get(iteratedMailerRec.Id).Account__r.Name+'.<br/>You can forward email to customers at <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+iteratedMailerRec.Id+'">Customer Mailer Link</a>.<br/><br/>Thanks,<br/>PS Automation Team',null,null);
            finalMailerList.add(mailerInstance);
            }else if(trigger.oldMap.get(iteratedMailerRec.Id).Reminder_Mail_sent_to_Managers__c == false && iteratedMailerRec.Reminder_Mail_sent_to_Managers__c && iteratedMailerRec.Manager_Id__c != '' && iteratedMailerRec.Manager_Id__c != null){
                toUserIds = iteratedMailerRec.Manager_Id__c.split(';');
    
                mailerInstance = SC_PSAutomationController.mailerInstanceCreationMethod(toUserIds,'Customer Mailer Publish reminder email for SCs Managers','Hi , <br/> <br/>Your reportee have not taken any action on Customer Mailer record : '+iteratedMailerRec.Name+' created for Account : '+mailerMap.get(iteratedMailerRec.Id).Account__r.Name+'.<br/>You can forward email to customers at <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+iteratedMailerRec.Id+'">Customer Mailer Link</a>.<br/><br/>Thanks,<br/>PS Automation Team',null,null);
                finalMailerList.add(mailerInstance);
            }

        }

        if(finalMailerList.size() > 0){
            Messaging.sendEmail(finalMailerList);
        }
    }*/


    // Before delete logic to prevent mailer record deletion.
    if(trigger.isBefore && trigger.isDelete){
        for(PS_Customer_Mailers__c itrMailer : trigger.old){
            if(!itrMailer.Is_Master_Record__c){
                itrMailer.addError('Child Customer Mailer Records can not be deleted.');
            }
            if(itrMailer.Is_Master_Record__c && itrMailer.Publish_Date__c != null){
                itrMailer.addError('Published Master Customer Mailer records can not be deleted.');
            }
        }
    }
}