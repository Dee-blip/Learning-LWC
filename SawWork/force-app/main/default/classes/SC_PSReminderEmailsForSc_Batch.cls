/*---------------------------------------------------------------------------------
    Class name          :   SC_PSReminderEmailsForSc_Batch
    Test Class          :   
    Author              :   Ashin Louis
    Created             :   15-APR-2022
    JIRA                :   ESESP-6983 2.b
    Purpose             :   PS Automation Workflow
             
    Last Modified         Developer                           Purpose            
    ============= ========================         			  ==========
    18-APR-2022     Ashin Louis                             Initial Version
	Test Class : 
* --------------------------------------------------------------------------------*/


public class SC_PSReminderEmailsForSc_Batch implements Schedulable,Database.Batchable<sObject>, database.stateful
{
    Map<Id,PS_Customer_Mailers__c> MailerIdVsMailerToProcessForSC= new Map<Id,PS_Customer_Mailers__c>();
    //Re-usable messaging service
    /*public messaging.SingleEmailMessage mailerInstanceCreationMethod(List < String > toAddress, String Subject, String body, String whatId, List < Attachment > attachList)
     {
        messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
        mail.setToAddresses(toAddress);
        mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
        mail.setSubject(Subject);
        mail.setHtmlBody(body);
        if (whatId != '' && whatId != null) 
        {
          mail.setWhatId(whatId);
          mail.setSaveAsActivity(true);
        }
    
        if (attachList != null && attachList.size() > 0) {
          List < Messaging.EmailFileAttachment > attachmemnts = new List < Messaging.EmailFileAttachment > ();
          Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
          efa.setFileName(attachList[0].Name);
          efa.setBody(attachList[0].body);
          attachmemnts.add(efa);
          mail.setFileAttachments(attachmemnts);
        }
    
        return mail;
    
      }*/

    //Start Method of Batch  
    public Database.QueryLocator start(Database.BatchableContext BC)
    {
        String query = 'select id, Name, Account__r.Name,Manager_Id__c,Reminder_Date_for_SCs__c,Reminder_Date_for_Managers__c, Reminder_Mail_sent_to_Managers__c,Reminder_Mail_sent_to_SC__c, Team_Member_Id__c, Email_forwarded_to_Contacts_On__c from PS_Customer_Mailers__c where Is_Master_Record__c = false AND Publish_Date__c !=NULL AND Reminder_Date_for_SCs__c != NULL AND Reminder_Date_for_Managers__c !=NULL  AND Email_forwarded_to_Contacts_On__c = null AND Reminder_Date_for_SCs__c=Today AND Reminder_Mail_sent_to_SC__c = false AND Reminder_Mail_sent_to_Managers__c=False AND Team_Member_Id__c!=null AND Disabled_Ever__c=false';
        return Database.getQueryLocator(query); 

    }

    //Execute method of Batch
    public void execute(Database.BatchableContext batchableContext, List < PS_Customer_Mailers__c> custMailerList)
    {
        //Method level variables
       List<PS_Customer_Mailers__c> updateMailers = new List<PS_Customer_Mailers__c>();
    try
        {
            for(PS_Customer_Mailers__c c: custMailerList )
                    {
                        MailerIdVsMailerToProcessForSC.put(c.Id,c); //Storing the mailers qualified for email is to be sent to SCs        
                    }

            for(String c:MailerIdVsMailerToProcessForSC.keyset())
                  {
                    PS_Customer_Mailers__c p= new PS_Customer_Mailers__c();
                    p = MailerIdVsMailerToProcessForSC.get(c);
                    p.Reminder_Mail_sent_to_SC__c = true;  // When the reminder mail is sent, setting the relevant field to true
                    updateMailers.add(p);
                  }  
            
             system.debug('Reminder mails SC_Batch, mailers to process size in Execute is '+MailerIdVsMailerToProcessForSC.size());
             system.debug('Reminder mails SC_Batch, mailers to Update size in Execute is '+updateMailers.size());
             
        //Updating the list (Setting the flag to true)
            if(updateMailers.size()>0)
                  {
                      database.update(updateMailers);
                  }

        }
        Catch(Exception e)
        {
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: In execute method of SC_PSReminderEmailsForSc_Batch.';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = SC_PSReminderEmailsForSc_Batch\n' +'Method Name = execute\n';
            errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage); 
        }

    }

    //Finish method
    public void finish(Database.BatchableContext BC) 
    {

        system.debug('Reminder mails SC_Batch, mailers to process size in Finish is '+MailerIdVsMailerToProcessForSC.size());

        //Adding the final mailers to a wrapper so that we can send it to child batch to send emails
        List < SC_PSAutomationController.itemsForSendingRemindersWrapper> wrapperList =   new List < SC_PSAutomationController.itemsForSendingRemindersWrapper>();
        SC_PSAutomationController.itemsForSendingRemindersWrapper wrapperRec = new SC_PSAutomationController.itemsForSendingRemindersWrapper();
        wrapperRec.AccountVsMailerToProcessForSC=MailerIdVsMailerToProcessForSC;
        wrapperList.add(wrapperRec);
   
        system.debug('Reminder mails SC_Batch, mailers to be sent to chilbatch in Finish is'+wrapperList);
    
        if(!wrapperList.isEmpty())
        {
            //Calling the child batch to send emails
            Database.executeBatch(new SC_PSAutomation_ScReminder_ChildBatch(wrapperList), 10);
        }
    }


    //Schedulable context , so that we can schedule from salesforce setup UI
    public void execute(SchedulableContext sc) 
    {
        SC_PSReminderEmailsForSc_Batch reminderBatch = new SC_PSReminderEmailsForSc_Batch();
        Database.executeBatch(reminderBatch, 30);
    }

    
}