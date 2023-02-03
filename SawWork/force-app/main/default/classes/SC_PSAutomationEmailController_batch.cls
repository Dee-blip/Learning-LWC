/*---------------------------------------------------------------------------------
    Class name          :   SC_PSAutomationEmailController_batch
    Test Class          :   
    Author              :   Ashin Louis
    Created             :   29-Apr-2022
    JIRA                :   ESESP-6983 2.a
    Purpose             :   Batch class for both batch_job and Publish batch
             
    Last Modified            Developer                           Purpose            
    =============     ========================         		    	  ==========
    29-Apr-2022            Ashin Louis                            Initial Version
	Test Class : SC_PS_AutomationTest
* --------------------------------------------------------------------------------*/


public class SC_PSAutomationEmailController_batch implements Database.Batchable<SC_PSAutomationController.memberVsChildmailerWrapper >, Database.Stateful
{

   public Map<String, List<SC_PSAutomationController.targetAccountWrapperClass>>  memberIdVsApplicableAccounts = new Map<String, List<SC_PSAutomationController.targetAccountWrapperClass>>();
   public Map < String, list<PS_Customer_Mailers__c> > accVsMailerRec = new Map < String, list<PS_Customer_Mailers__c> > ();
   SC_PSAutomationController.EmailWrapper  emailDetailsTofetch= new SC_PSAutomationController.EmailWrapper();
   public string instructions='';
   
   public List < SC_PSAutomationController.itemsForSendingEmailsWrapper> wrapperList1 =   new List < SC_PSAutomationController.itemsForSendingEmailsWrapper>();
   SC_PSAutomationController.itemsForSendingEmailsWrapper wrapperRec1 = new SC_PSAutomationController.itemsForSendingEmailsWrapper();
   public map<String, List<PS_Customer_Mailers__c>> membervsChildMailers = new map<String, List<PS_Customer_Mailers__c>>();

   public SC_PSAutomationEmailController_batch(list<SC_PSAutomationController.itemsForSendingEmailsWrapper> incomingWrapperList)
   {
      if(!incomingWrapperList.isEmpty())
        {
         accVsMailerRec = incomingWrapperList[0].AccountsVsChildMailers;
         memberIdVsApplicableAccounts = incomingWrapperList[0].memberVsApplicableAccountsMap;
         emailDetailsTofetch=incomingWrapperList[0].emailDetails;
         instructions=incomingWrapperList[0].instructions;

        }   
           system.debug('In constructore , acc VS mailer '+accVsMailerRec);
           system.debug('In constructore , memper vs app accounts '+memberIdVsApplicableAccounts);
           system.debug('In constructore , email detail '+emailDetailsTofetch);
    }

    public messaging.SingleEmailMessage mailerInstanceCreationMethod(id toAddress, String Subject, String body, String whatId, List < Attachment > attachList,Boolean setName) {
      messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
      mail.setTargetObjectId(toAddress);
     
      // Not Setting display name for missing team member mails 
     if(setName){
     mail.setSenderDisplayName(UserInfo.getFirstName()+' '+UserInfo.getLastName());
     }
      mail.setSubject(Subject);
      mail.setHtmlBody(body);
      mail.saveAsActivity = false;  
      if (whatId != '' && whatId != null) {
        mail.setWhatId(whatId);
        //mail.SaveAsActivity(false);
      
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


   //Start Method of Batch  
public Iterable < SC_PSAutomationController.memberVsChildmailerWrapper  > start(Database.BatchableContext BC)
{
  SC_PSAutomationController.memberVsChildmailerWrapper mailerWrapper = new SC_PSAutomationController.memberVsChildmailerWrapper ();
  List<SC_PSAutomationController.memberVsChildmailerWrapper> mailerWrapperList = new List<SC_PSAutomationController.memberVsChildmailerWrapper>();

                    for(String s:memberIdVsApplicableAccounts.keySet())
                    { 

                      List<SC_PSAutomationController.targetAccountWrapperClass> wrapperList = memberIdVsApplicableAccounts.get(s);
                    for (SC_PSAutomationController.targetAccountWrapperClass wr:wrapperList)
                    {
                      
                      system.debug('Account is +++ '+wr.Name);
                      List<PS_Customer_Mailers__c> mailerList = accVsMailerRec.get(wr.id);
                      for(PS_Customer_Mailers__c dmailer:mailerList)
                      {
                        if(membervsChildMailers.containsKey(s))
                        {
                          membervsChildMailers.get(s).add(dmailer);
                        }
                        else {
                          membervsChildMailers.put(s, new list<PS_Customer_Mailers__c>{dmailer});
                        }
                      }
                      
                    }
                  }

                  system.debug('member VS child mailer is -------- '+membervsChildMailers);

                  for(String s: membervsChildMailers.keyset())
                  {
                    mailerWrapper= new SC_PSAutomationController.memberVsChildmailerWrapper ();
                    mailerWrapper.MemberId=s;
                    mailerWrapper.childMailers=membervsChildMailers.get(s);
                    mailerWrapperList.add(mailerWrapper);

                  }

                  /*List < SC_PSAutomationController.itemsForSendingEmailsWrapper> wrapperList1 =   new List < SC_PSAutomationController.itemsForSendingEmailsWrapper>();
                  SC_PSAutomationController.itemsForSendingEmailsWrapper wrapperRec1 = new SC_PSAutomationController.itemsForSendingEmailsWrapper();
                  wrapperRec1.mailerListStr='demo';
                  wrapperList1.add(wrapperRec1);*/


   return mailerWrapperList;
}

    
public void execute(Database.BatchableContext batchableContext, List < SC_PSAutomationController.memberVsChildmailerWrapper > executeWrapperList1)
{

    //String NotifyMultipleCustomerMailersLink = URL.getSalesforceBaseUrl().toExternalForm(); //Added on May 26 2022, after 1st user demo
    //NotifyMultipleCustomerMailersLink +='/lightning/n/PS_Automation_List_View_Mass_Mailer'; 
    String notifyMultipleMailersLink = '<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/n/PS_Automation_List_View_Mass_Mailer'+' >'+'Click Here'+'</a> <br/>';

    String finalBody = '';
    String subject = ''; 
    List < messaging.SingleEmailMessage > finalMailerList = new List < messaging.SingleEmailMessage > ();
    messaging.SingleEmailMessage mailerInstance;
    list<Id> accountIds = new list<Id>();
    Map < Id, Account > AccountidVsMap = new Map < Id, Account > ();

   system.debug('In execute method , acc VS mailer '+accVsMailerRec);
   system.debug('In execute method , memper vs child mailer wrapper '+executeWrapperList1);
   system.debug('In execute method , email detail '+emailDetailsTofetch);
  
   
  for(SC_PSAutomationController.memberVsChildmailerWrapper s:executeWrapperList1)
  {
    for(PS_Customer_Mailers__c mailers:s.childMailers)
    {
      accountIds.add(mailers.Account__c);
    }
  }


  AccountidVsMap = new Map < Id, Account > ([Select id, name from Account where Id In:accountIds]);

  for(SC_PSAutomationController.memberVsChildmailerWrapper s:executeWrapperList1)
  {
    
    system.debug('memebr is '+s.MemberId);
    finalBody = '';
    finalBody += 'Hi, <br></br> You are receiving this email because a master mailer record has been created by '+UserInfo.getFirstName()+' '+UserInfo.getLastName()+' and you are the "Security Services Primary member" for the accounts listed below. Please take action on the Child mailers to send to your respective customers. <br></br>';
    finalBody += 'Please click this link to notify multiple customers with one single click:- ' + notifyMultipleMailersLink + '<br></br>';
    finalBody += '<table border="2" style="border-collapse: collapse; width=30%"><caption>List of Accounts and Child Mailers:- </caption><tr><th style="background-color:#D3D3D3; width=10%">Account Name</th><th style="background-color:#D3D3D3; width=10%">Child Mailer Link</th></tr>';

    for(PS_Customer_Mailers__c wr:s.childMailers)
    {
      String accName = AccountidVsMap.get(wr.Account__c).Name; 
      system.debug('Account name is '+accName);
      String Recordlink = '<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+wr.id+' >'+'View'+'</a> <br/>';
      finalBody += '<tr><td>' + accName + '</td><td>' + Recordlink + '</td></tr>';
      
    }
    subject = 'Customer mailer record creation:- '+ emailDetailsTofetch.subject;
    finalBody += '</table>';
    finalBody+='<br></br><b><u>Instructions:-</u></b> ' + instructions +'<br></br><b><u>Content:-</u></b> ' + emailDetailsTofetch.body + '<br/><br/>Thanks,<br/>PS Automation Team.';
    mailerInstance = mailerInstanceCreationMethod(Id.valueOf(s.MemberId), subject, finalBody, null, null,true);
    finalMailerList.add(mailerInstance); 

  }
  if(!finalMailerList.isEmpty())
                  {
                    Messaging.sendEmail(finalMailerList);
                  }


}

public void finish(Database.BatchableContext BC)
    
    
    {
    
   }
}