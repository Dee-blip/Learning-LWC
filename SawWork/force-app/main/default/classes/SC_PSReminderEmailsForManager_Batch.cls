/*---------------------------------------------------------------------------------
    Class name          :   SC_PSReminderEmailsForManager_Batch
    Test Class          :   
    Author              :   Ashin Louis
    Created             :   18-APR-2022
    JIRA                :   ESESP-6983 2.c
    Purpose             :   PS Automation Workflow
             
    Last Modified         Developer                           Purpose            
    ============= ========================         			  ==========
    18-APR-2022     Ashin Louis                             Initial Version
	Test Class : 
* --------------------------------------------------------------------------------*/


public class SC_PSReminderEmailsForManager_Batch implements Schedulable, Database.Batchable<sObject>, database.stateful
{
    //Class level variables
    map<String, list<PS_Customer_Mailers__c>> managerVsMailers = new Map<String,list<PS_Customer_Mailers__c>>();
    Map<String, list<String>> ManagerVsTeammemberName = new Map<String, list<String>>();
    Map < Id, User > userMap = new Map < Id, User > ();
    Set<String> finalToUserIds = new Set<String>();
    //Class level variables

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

            if (attachList != null && attachList.size() > 0) 
            {
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
    String query = 'select id, Name, Account__r.Name,Manager_Id__c,Reminder_Date_for_SCs__c,Reminder_Date_for_Managers__c, Reminder_Mail_sent_to_Managers__c,Reminder_Mail_sent_to_SC__c, Team_Member_Id__c, Email_forwarded_to_Contacts_On__c from PS_Customer_Mailers__c where Is_Master_Record__c = false AND Publish_Date__c !=NULL AND Reminder_Date_for_SCs__c != NULL AND Reminder_Date_for_Managers__c !=NULL  AND Email_forwarded_to_Contacts_On__c = null AND Reminder_Date_for_Managers__c=Today AND Reminder_Mail_sent_to_Managers__c=false AND Reminder_Mail_sent_to_SC__c=true AND Manager_Id__c!=null  AND Disabled_Ever__c=false';
    return Database.getQueryLocator(query); 
}

//Execute method of Batch
public void execute(Database.BatchableContext batchableContext, List < PS_Customer_Mailers__c > custMailerList)
{
    //Method level variables
        List<PS_Customer_Mailers__c> updateMailers = new List<PS_Customer_Mailers__c>();
        List<String> toUserIds = new list<String>();
        List<String>toUserIdsForManager= new List<String>();
        string memberIds='';
        string memberIdsForManagerEmail='';
        string FinalmemberIds='';
        String FinalmemberIdsForManagerEmail='';
        Set<String> finalToUserIdsForManager = new Set<String>();
        String fetchedUniqueManagerIds='';
        String managerId ='';
        map<string, string> teammemberVsManager = new Map<String, string>();
    //Method level variables

        system.debug('Reminder mails Manager_Batch, mailers to process size in Execute is '+custMailerList.size());

    try
    {   if(!custMailerList.isEmpty())
        {
            //Looping through the stored mailer list to fetch the Manager_Ids and in the end store Unique manager_Ids from all mailers 
            for(PS_Customer_Mailers__c c:custMailerList)
                {
                    c.Reminder_Mail_sent_to_Managers__c = true;  // When the reminder mail is sent, setting the relevant field to true
                    updateMailers.add(c);

                    memberIdsForManagerEmail += c.Manager_Id__c;
                    memberIdsForManagerEmail +=';';
                    FinalmemberIdsForManagerEmail=memberIdsForManagerEmail.removeEnd(';');
                    toUserIdsForManager = FinalmemberIdsForManagerEmail.split(';');
                    finalToUserIdsForManager.addAll(toUserIdsForManager);   

                    //Here we are looping through the unique Manager_Ids again, because it may contain a text like "null". So we need to remove it
                    for(String u : finalToUserIdsForManager)
                        {
                            fetchedUniqueManagerIds= u;
                            if(fetchedUniqueManagerIds.contains('null'))
                                {
                                    finalToUserIdsForManager.remove(u); //This is the final set of Unique Manager_ids to which we need to send Email
                                }
                        }

                    memberIds += c.Team_Member_Id__c; //Storing the team_member_ids from the mailers
                    memberIds +=';';      
                }
        }
        system.debug('Reminder mails Manager_Batch, mailers to update size in Execute is '+updateMailers.size());

        //Here we are looping through the mailers and storing the unique Manager_id Vs list of Applicable mailers for that manager
        if(!finalToUserIdsForManager.isEmpty())
        {
        for(PS_Customer_Mailers__c c:custMailerList)
        {
            for(String s : finalToUserIdsForManager)
            {
                managerId=c.Manager_Id__c;
                if(managerId.contains(s))
                {
                    if(managerVsMailers.containsKey(s))
                    {
                        managerVsMailers.get(s).add(c);  //Storing Manager_Id Vs List of Applicable Mailer
                    }
                    else {
                        managerVsMailers.put(s, new list<PS_Customer_Mailers__c>{c}); //Storing Manager_Id Vs List of Applicable Mailer
                    }
                    
                }
                managerId='';
            }
        }
        }   
        system.debug(' Reminder mails Manager_Batch, Map of Manager Vs List of Applicable mailers in execute size:- '+managerVsMailers.size());

        //Here we are storing the unique team_member_ids from all mailers
        FinalmemberIds=memberIds.removeEnd(';');
        toUserIds = FinalmemberIds.split(';');
        finalToUserIds.addAll(toUserIds);   
        system.debug('Reminder mails Manager_Batch, Unique team member Ids in execute:- '+finalToUserIds); //This contains the Unique team_member_ids from the mailers
        
        //Using SOQL to get the names
        userMap = new Map < Id, User > ([Select id, name, Manager.Name, ManagerId from User where Id In:finalToUserIds]);

        for(Id s:userMap.keySet())
        {
            teammemberVsManager.put(s,userMap.get(s).ManagerId); //Here we are storing the UserId(Team_member_id) Vs Their Manager Id
        }

        //Here we are processing and stroing Manager Vs team member names
        for(String s : managerVsMailers.keyset())
        {
             for(String tm:finalToUserIds)
             {
                if(teammemberVsManager.get(tm)==s) //Checking if Manager is same
                {
                    if(ManagerVsTeammemberName.containsKey(s))
                    {
                       //Storing unique ManagerID Vs list of team_member_ids from the mailer list. To these unique managers we will send Emails later
                       ManagerVsTeammemberName.get(s).add(userMap.get(tm).name); 
                    }
                    else 
                    {
                    //Storing unique ManagerID Vs list of team_member_ids from the mailer list. To these unique managers we will send Emails later
                    ManagerVsTeammemberName.put(s, new list<String>{userMap.get(tm).name}); 
                    }   
                }
             }
        }

        system.debug('Reminder mails Manager_Batch, Manager Vs Team member Ids in execute size:- '+ManagerVsTeammemberName.size());
        
        //Updating the mailer and setting reminder_mail_sent_to_manager = true
        if(updateMailers.size()>0)
        {
            database.update(updateMailers);
        }
       
    }
    Catch(Exception e)
    {
        System.debug('Exception occured  :: ' + e.getMessage());
        string setEmailSub          = 'Exception: In execute method of SC_PSReminderEmailsForManager_Batch.';
        string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = SC_PSReminderEmailsForManager_Batch\n' +'Method Name = execute\n';
        errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
        SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
        sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage); 
    }

}

//Finish method of batch
public void finish(Database.BatchableContext BC) 
{
    
  system.debug('Reminder mails Manager_Batch, manager Vs teammembers in Finish size:- '+ManagerVsTeammemberName.size());
  system.debug('Reminder mails Manager_Batch, manager Vs mailers in Finish size:-'+managerVsMailers.size());

  List < SC_PSAutomationController.itemsForReminderManagerEmails> wrapperList =   new List < SC_PSAutomationController.itemsForReminderManagerEmails>();
  SC_PSAutomationController.itemsForReminderManagerEmails wrapperRec = new SC_PSAutomationController.itemsForReminderManagerEmails();
  wrapperRec.ManagerVsTeammemberName=ManagerVsTeammemberName;
  wrapperRec.managerVsMailers=managerVsMailers;
  wrapperRec.userMap=userMap;
  wrapperList.add(wrapperRec);
       
  system.debug('Reminder mails Manager_Batch, sending Wrapper list is '+wrapperList);
        
  if(!wrapperList.isEmpty())
    {
        //Calling the child batch to send emails
        Database.executeBatch(new SC_PSAutomation_ManagerRmdr_ChildBatch(wrapperList), 10);
    }
}

//schedulable context , so that we can schedule this batch class from salesforce setup UI
public void execute(SchedulableContext sc) 
{
    SC_PSReminderEmailsForManager_Batch reminderBatch = new SC_PSReminderEmailsForManager_Batch();
    Database.executeBatch(reminderBatch, 30);
}

}