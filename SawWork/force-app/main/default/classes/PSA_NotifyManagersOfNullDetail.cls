/* ========================================================================
    Author: Samir Jha
    Description: Class used for sending weekly email reminder to all Project owners 
    which have have "ONLY NULL" contract line items associated.                 
    Created Date : 01/04/2015
    ======================================================================== */
global class PSA_NotifyManagersOfNullDetail implements Database.Batchable<sObject>
{
    private string query;
    //PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');  // Email Address to send completion Notification.
    PSA_Common_Setting__mdt EnggEmail = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'Engineering Team Email' limit 1] ; 

    //PSA_Settings__c GSSEmail = PSA_Settings__c.getInstance('GSS Team Email');       // Email Address to add in cc field for all mails.  
    PSA_Common_Setting__mdt GSSEmail = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'GSS Team Email' limit 1] ; 
    list<Project_Contract_Line_Item__c> pclBatch = new list<Project_Contract_Line_Item__c>();
    list<pse__proj__c> pBatch = new list<pse__proj__c>();
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        query = 'Select Id,pse__Stage__c,pse__Is_Billable__c,Project_Manager_Email__c,Name,pse__Project_ID__c,pse__Project_Manager__r.Name,(select Id,Contract_Detail__c,Original_Contract_Id__c from pse__Proj__c.Project_Contract_Line_Items__r where Contract_Detail__c!= NULL) from pse__Proj__c where pse__Is_Billable__c = TRUE and pse__Stage__c != \'Closed\'and Id in (Select Project__c from Project_Contract_Line_Item__c where Contract_Detail__c = NULL )';
        if (Test.isRunningTest()){
            query = 'Select Id,pse__Stage__c,pse__Is_Billable__c,Project_Manager_Email__c,Name,pse__Project_ID__c,pse__Project_Manager__r.Name,(select Id,Contract_Detail__c,Original_Contract_Id__c from pse__Proj__c.Project_Contract_Line_Items__r where Contract_Detail__c!= NULL) from pse__Proj__c where pse__Is_Billable__c = TRUE and pse__Stage__c != \'Closed\'and Id in (Select Project__c from Project_Contract_Line_Item__c where Contract_Detail__c = NULL ) LIMIT 2';
        }        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
       Boolean Valid;
       list<pse__proj__c> Proj2Notify = new list<pse__proj__c>();
       list<Id> listProjectIds = new list<Id>();
       Map<pse__proj__c,list<Project_Contract_Line_Item__c>> ProjectProjectContractMap = new Map<pse__proj__c,list<Project_Contract_Line_Item__c>>();
       pBatch = scope;
       system.debug(pBatch);
       //System.assertEquals(pBatch, NULL);
       for(pse__proj__c p : pBatch)
       {
          if(p.Project_Contract_Line_Items__r == NULL || p.Project_Contract_Line_Items__r.size() == 0)
      {
        Proj2Notify.add(p);
          }   
    
       }
       NotifyProjectManagers(Proj2Notify);
     
  }
    
    global void finish(Database.BatchableContext BC)
    {
        Messaging.Singleemailmessage objEmail = new Messaging.Singleemailmessage();
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setSenderDisplayName('FinancialForce PSA Engineering Notification');
        objEmail.setToAddresses(new list<String>{EnggEmail.Value_Long__c});
        objEmail.setSubject('Notification sent for Invalid Contract Details');
        objEmail.setPlainTextBody('Team, \n\nNotifications have been successfully sent to Project managers regarding Null Contract Details.\n\nThanks,PSA Notification Autobot');
        mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);
    }
    
    public void NotifyProjectManagers(list<pse__proj__c> ListProj2Notify)
    {
        system.debug(ListProj2Notify);
        //list<pse__proj__c> ListProj2Notify = [select Id,Name,pse__Project_ID__c,Project_Manager_Email__c,pse__Project_Manager__r.Name from pse__proj__c where Id in: Proj2NotifyList];
        //string fromEmailAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c.trim();
        String fromEmailAddress = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'FromEmailAdress' limit 1].Value_Long__c ; 
        string orgWideEmailId = [select Id from OrgWideEmailAddress where Address= :fromEmailAddress limit 1].Id;
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        for(pse__proj__c p1:ListProj2Notify)
        {
            objEmail = new Messaging.Singleemailmessage();
            objEmail.setReplyTo('noreply@akamai.com');
            //objEmail.setSenderDisplayName('FinancialForce PSA Notification');
            objEmail.setOrgWideEmailAddressId(orgWideEmailId);
            objEmail.setToAddresses(new list<String>{p1.Project_Manager_Email__c});
            objEmail.setCcAddresses(new list<String>{GSSEmail.Value_Long__c});
            objEmail.setSubject('ACTION REQUIRED: Update Contract Line Item on Project ' + p1.Name);
            objEmail.setPlainTextBody('Dear ' +p1.pse__Project_Manager__r.Name+ ',\n\nACTION REQUIRED: There has been a contract change related to the contract line item associated to the following project.  As a result, the contract line item on the project needs to be updated.  Please review the project and take action immediately, to meet project compliance and billing needs.  Thank you for your timely attention!' + '\n\n' + 'Project ID: '
                                      + p1.pse__Project_ID__c + '\n' + 'Project Name: ' + p1.Name + '\nProject Manager: '+p1.pse__Project_Manager__r.Name
                                      + '\nProject Link: ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + p1.Id);
            
         mailsToBeSent.add(objEmail);
        }
        Messaging.sendEmail(mailsToBeSent,false);
    }

}