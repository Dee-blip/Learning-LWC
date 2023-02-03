/*---------------------------------------------------------------------------------
    Class name          :   SC_PSAutomation_ScReminder_ChildBatch
    Test Class          :   
    Author              :   Ashin Louis
    Created             :   04-MAY-2022
    JIRA                :   ESESP-6983 2.b
    Purpose             :   PS Automation Workflow
             
    Last Modified         Developer                               Purpose            
    =============   ========================         			  ==========
    04-MAY-2022       Ashin Louis                             Initial Version
	Test Class : 
* --------------------------------------------------------------------------------*/


public class SC_PSAutomation_ScReminder_ChildBatch implements Database.Batchable<string>, Database.Stateful
{

    //Class level variables
    Map<Id,PS_Customer_Mailers__c> MaileridVsMailerToProcessForSC= new Map<Id,PS_Customer_Mailers__c>();
    Set<String> finalToUserIds = new Set<String>();
    //Class level variables


    //Constructor recievibg the incoming wrapper list
    public SC_PSAutomation_ScReminder_ChildBatch(List < SC_PSAutomationController.itemsForSendingRemindersWrapper> incomingWrapperList) 
    {
        this.MaileridVsMailerToProcessForSC=incomingWrapperList[0].AccountVsMailerToProcessForSC;
        system.debug('In child SC-batch constructor, Mailers list size is :- '+MaileridVsMailerToProcessForSC.size());

    }

//Re-usable messaging instance
    public messaging.SingleEmailMessage mailerInstanceCreationMethod(id toAddress, String Subject, String body, String whatId, List < Attachment > attachList)
    {
       messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
       mail.setTargetObjectId(toAddress);
       mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
       mail.setSubject(Subject);
       mail.setHtmlBody(body);
        mail.setSaveAsActivity(false);
       if (whatId != '' && whatId != null) 
       {
         mail.setWhatId(whatId);
         //mail.setSaveAsActivity(true);
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
     }

//Start method 
public Iterable < string > start(Database.BatchableContext BC)
{
    //Method level variables
    string memberIds='';
    string FinalmemberIds='';
    List<String> toUserIds = new list<String>();
    List<String> MainTouserIdList = new list<String>();
    //Method level variables

    for(PS_Customer_Mailers__c mailer : MaileridVsMailerToProcessForSC.Values())
    {
        memberIds += mailer.Team_Member_Id__c; //Storing all the memberIds from the incoming mailers
        memberIds +=';';
    }

    FinalmemberIds=memberIds.removeEnd(';');
    toUserIds = FinalmemberIds.split(';');
    finalToUserIds.addAll(toUserIds);   
    
    if(!finalToUserIds.isEmpty())
    {
        MainTouserIdList.addAll(finalToUserIds);
    }
    
    system.debug('In child SC-batch, Unique user Ids in start method '+MainTouserIdList);
    system.debug('In child SC-batch, Unique user Ids in start method size is '+MainTouserIdList.size());
    return MainTouserIdList;

}
  

public void execute(Database.BatchableContext batchableContext, List < string > RecipientUserIds)
{

    system.debug('In child SC-batch, In execute, Recipient userids list size is '+RecipientUserIds.size());
    system.debug('In child SC-batch, Unique user Ids in execute method'+RecipientUserIds);

    //String NotifyMultipleCustomerMailersLink = URL.getSalesforceBaseUrl().toExternalForm(); //Added on May 26 2022, after 1st user demo
    //NotifyMultipleCustomerMailersLink +='/lightning/n/PS_Automation_List_View_Mass_Mailer'; 

    String notifyMultipleMailersLink = '<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/n/PS_Automation_List_View_Mass_Mailer'+' >'+'Click Here'+'</a> <br/>';
    String finalBody = '';
    string subject = '';
    messaging.SingleEmailMessage mailerInstance;
    List < messaging.SingleEmailMessage > finalMailerList = new List < messaging.SingleEmailMessage > ();
    String teamMemberIds ='';

    try
    {
        if(!RecipientUserIds.isEmpty())
        {
            for(String s :RecipientUserIds)
            {
                system.debug('User is +++++++ '+s);
                finalBody = '';
                finalBody += 'Hi, You are receiving this email because you have not responded to the following customers yet. Please take immediate action.';
                finalBody += '<br></br>Please click this link to notify multiple customers with one single click:- ' + notifyMultipleMailersLink + '<br></br>';
                finalBody += '<br></br><table id= "myTable" border="2" style="border-collapse: collapse; width=30%"><caption>List of Accounts and Child Mailers:- </caption><tr><th style="background-color:#D3D3D3; width=10%">Account Name</th><th style="background-color:#D3D3D3; width=10%">Child Mailer Link</th></tr>';
                subject = 'Reminder to send security bulletins to customers' ;

                for(PS_Customer_Mailers__c dmailer:MaileridVsMailerToProcessForSC.values())
                    {
                        teamMemberIds += dmailer.Team_Member_Id__c;
                        if(teamMemberIds.contains(s))
                        {
                            teamMemberIds='';
                            String accName = dmailer.Account__r.Name; 
                            String mailerName = dmailer.Name;
                            system.debug('mailer name is +++++ '+mailerName);
                            String Recordlink = '<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+dmailer.Id+' >'+dmailer.Name+'</a> <br/>';
                            finalBody += '<tr><td>' + accName + '</td><td>'+ Recordlink + '</td></tr>';
                        }
                        teamMemberIds='';
                    }
                finalBody += '</table>';
                finalBody +='<br/><br/>Thanks,<br/>PS Automation Team.';
                if(s!='')
                {
                mailerInstance = mailerInstanceCreationMethod(Id.valueOf(s), subject, finalBody, null, null);
                finalMailerList.add(mailerInstance);
                }
            }
        }
        
        if (finalMailerList.size() > 0) 
            {
                Messaging.sendEmail(finalMailerList); //Sending emails to the team members
            }
    }
    Catch(Exception e)
        {
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: In execute method of SC_PSAutomation_ScReminder_ChildBatch.';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = SC_PSAutomation_ScReminder_ChildBatch\n' +'Method Name = execute\n';
            errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage); 
        }
                     
}

//Finish method
public void finish(Database.BatchableContext BC)
{
    
}

}