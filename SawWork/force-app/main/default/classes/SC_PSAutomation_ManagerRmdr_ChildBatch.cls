/*---------------------------------------------------------------------------------
    Class name          :   SC_PSAutomation_ManagerRmdr_ChildBatch
    Test Class          :   
    Author              :   Ashin Louis
    Created             :   04-MAY-2022
    JIRA                :   ESESP-6983 2.c
    Purpose             :   PS Automation Workflow
             
    Last Modified         Developer                           Purpose            
    =============   ========================         	     ==========
    04-MAY-2022     Ashin Louis                             Initial Version
	Test Class : 
* --------------------------------------------------------------------------------*/


public class SC_PSAutomation_ManagerRmdr_ChildBatch implements Database.Batchable<String>, Database.Stateful
{

    map<String, list<PS_Customer_Mailers__c>> managerVsMailers = new Map<String,list<PS_Customer_Mailers__c>>();
    Map<String, list<String>> ManagerVsTeammemberName = new Map<String, list<String>>();
    Map < Id, User > userMap = new Map < Id, User > ();

//Constructor with incomming wrapper list from parent batch
    public SC_PSAutomation_ManagerRmdr_ChildBatch(List < SC_PSAutomationController.itemsForReminderManagerEmails> incomingWrapperList) 
    {
        this.managerVsMailers=incomingWrapperList[0].managerVsMailers;
        this.ManagerVsTeammemberName=incomingWrapperList[0].ManagerVsTeammemberName;
        this.userMap=incomingWrapperList[0].userMap;

        system.debug('In reminder Manager child_batch, manager vs members size in constructor is:- '+ManagerVsTeammemberName.size());
        system.debug('In reminder Manager child_batch, Manager vs mailers size in constructor is +++ :- '+managerVsMailers.size());

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

//Start method of the batch
    public Iterable < String > start(Database.BatchableContext BC)
    {
        List<String> managerIdsList = new list<String>();
        if(!ManagerVsTeammemberName.isEmpty())
        {
            for(String s: ManagerVsTeammemberName.keyset())
            {
                managerIdsList.add(s);
            }
        }
        system.debug('Manager reminder Child Batch, in start method recipient list size is '+managerIdsList.size());
        return managerIdsList; //This is the list that contains all the recipient manager userIds
    }

//Execute method of the batch
    public void execute(Database.BatchableContext batchableContext, List < String > recipientManagerIds)
    {

        system.debug('Manager reminder Child Batch, recipient list size in execute is '+recipientManagerIds.size());
        system.debug('Manager reminder Child Batch, recipient list in execute is '+recipientManagerIds);
        //Method level variables
        String finalBody = '';
        String subject = '';
        List<String> teamMembersList1 = new list<String>();
        messaging.SingleEmailMessage mailerInstance;
        List < messaging.SingleEmailMessage > finalMailerListForManager = new List < messaging.SingleEmailMessage > ();
        String finalConsultantName = '';
        //method level variables

        try
        {
            if(!recipientManagerIds.isEmpty())
            {
            for(String s: recipientManagerIds)
            {
                System.debug('Manager is '+s);
                list<PS_Customer_Mailers__c> mailers = managerVsMailers.get(s); //Getting the list of mailers associated to the Unique managerId
                finalBody = '';
                finalBody +='Hi, You are receiving this email because your reportees have not sent out the security bulletin to their customers. Please work with your reportees to ensure that security bulletins are sent out to customers.';
                finalBody += '<table id= "myTable" border="2" style="border-collapse: collapse; width=30%"><caption>List of Accounts and Child Mailers:- </caption><tr><th style="background-color:#D3D3D3; width=10%">Account Name</th><th style="background-color:#D3D3D3; width=10%">Child Mailer Link</th><th style="background-color:#D3D3D3; width=10%">Consultants Name</th></tr>';
                subject = 'Reminder for your team to send security bulletins to customers' ;

                for(PS_Customer_Mailers__c dmailer:mailers) //Looping through the list of mailers of the Manager
                {
                    system.debug('Mailers belonging to the above manager is '+dmailer.Name);
                    String accName = dmailer.Account__r.Name; 
                    String mailerName = dmailer.Name;
                    teamMembersList1 = dmailer.Team_Member_Id__c.split(';');
                    String Recordlink = '<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+dmailer.Id+' >'+dmailer.name+'</a> <br/>';
                    String ConsultantName = string.join(ManagerVsTeammemberName.get(s),';');
                
                //This loop is used to check if the Team_member_id of the mailer is a reportee of the current Manager or not
                    for(String mem : teamMembersList1)
                    {
                        //Here we are checking if the Team_member_id.Name is present in ManagerVsTeammemberName Map
                        if(ConsultantName.contains(userMap.get(mem).Name))
                        {
                            finalConsultantName += userMap.get(mem).Name + ';'; //If its matching, then we are storing the SC name
                        }
                    }
                    String scName = finalConsultantName.removeEnd(';');
                    finalBody += '<tr><td>' + accName + '</td><td>'+ Recordlink + '</td><td>'+ scName + '</td></tr>';
                    finalConsultantName='';
                    scName='';
                }
                finalBody += '</table>';
                finalBody +='<br/><br/>Thanks,<br/>PS Automation Team.';
                mailerInstance = mailerInstanceCreationMethod(Id.valueOf(s), subject, finalBody, null, null);
                finalMailerListForManager.add(mailerInstance);     
            }
        }

        if (finalMailerListForManager.size() > 0) 
        {
            Messaging.sendEmail(finalMailerListForManager);  
        }
    }
    Catch(Exception e)
        {
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: In execute method of SC_PSAutomation_ManagerRmdr_ChildBatch.';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = SC_PSAutomation_ManagerRmdr_ChildBatch\n' +'Method Name = execute\n';
            errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage); 
        }

}

//Finish method of batch
    public void finish(Database.BatchableContext BC)
    {

    }
}