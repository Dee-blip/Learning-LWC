global class PSA_APPROVE_PENDING_TIMECARDS implements Database.Batchable<sObject> 
{  
    PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
    list<pse__Timecard_Header__c> tch = new list<pse__Timecard_Header__c>();
    private string query;
    public string batchQuery = NULL;
    static String TestClass_Query = null;
  global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        Date dt1 = Date.newInstance(2015, 7, 1);
        //Date dt1 = dt.addMonths(-3);
        query = 'Select Id,pse__Project__r.pse__Closed_for_Time_Entry__c,pse__Milestone__r.pse__Closed_for_Time_Entry__c, pse__Assignment__r.pse__Closed_for_Time_Entry__c from pse__Timecard_Header__c where (pse__Status__c = \'Submitted\' OR pse__Status__c = \'Approver Level 1\') and CreatedDate < :dt1';
        TestClass_Query = query + ' limit 10';
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : query;
        return Database.getQueryLocator(batchQuery);
    }
    global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
        tch = scope;
        list<Id> TCH2ApproveIds = new list<Id>();
        for(pse__Timecard_Header__c tch1:tch)
        {
            TCH2ApproveIds.add(tch1.Id);
        }
        LIST<ProcessInstance> piBatch = [Select id,TargetObjectId,Status, (Select Id,ProcessInstance.TargetObjectId from Workitems) from ProcessInstance where TargetObjectId in :TCH2ApproveIds and Status = 'Pending'];
        //system.assertEquals(.size(), 11);
        List<ProcessInstanceWorkItem> PIWITem = new List<ProcessInstanceWorkItem>();
        for(ProcessInstance pi:piBatch)
        {
            for(ProcessInstanceWorkItem pwItem1:pi.Workitems)
            {
                PIWITem.add(pwItem1);
                
            }
        }
        Approval.ProcessWorkitemRequest req2;
        Approval.ProcessResult result2;
        App_Log_BackUp__c ap1;
        list<App_Log_BackUp__c> ap2Insert = new list<App_Log_BackUp__c>();
        list<Id> TC2UpdateId = new list<Id>();
        for(ProcessInstanceWorkItem piWitem1:PIWITem)
        {
            
            try
            {
                req2 = new Approval.ProcessWorkitemRequest();
              req2.setComments('System Approved');
              req2.setAction('Approve');
              req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
              req2.setWorkitemId(piWitem1.Id);
              result2 =  Approval.process(req2);
              if(!result2.isSuccess())
                {
                    Messaging.Singleemailmessage objEmail = new Messaging.Singleemailmessage();
                    Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
                    objEmail.setReplyTo('noreply@akamai.com');
                    objEmail.setSenderDisplayName('FinancialForce PSA Engineering Notification');
                    objEmail.setToAddresses(new list<String>{EnggEmail.Value__c});
                    objEmail.setSubject('APPROVAL FOR TIMECARD ERROR');
                    objEmail.setPlainTextBody('Team,\n There was an error encountered in approving the WorkItem: ' + piWitem1.Id+' \nPlease investigate.\nThanks & Regards, \nPSA Autobot'); 
                    mailsToBeSent.add(objEmail);
                    Messaging.sendEmail(mailsToBeSent,false);
                }
            }
            catch(Exception e)
            {
                Messaging.Singleemailmessage objEmail = new Messaging.Singleemailmessage();
                Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
                objEmail.setReplyTo('noreply@akamai.com');
                objEmail.setSenderDisplayName('FinancialForce PSA Engineering Notification');
                objEmail.setToAddresses(new list<String>{EnggEmail.Value__c});
                objEmail.setSubject('APPROVAL FOR TIMECARD ERROR Catch Block');
                objEmail.setPlainTextBody('Team,\n There was an error encountered in approving the WorkItem: ' + e.getMessage() +' \nPlease investigate.\nThanks & Regards, \nPSA Autobot'); 
                mailsToBeSent.add(objEmail);
                Messaging.sendEmail(mailsToBeSent,false);
                ap1 = new App_Log_BackUp__c ();
                ap1.Name = 'TC System Approval Issue';
                ap1.Level__c = 1;
                ap1.Origin__c = 'TC System Approval Issue';
                ap1.Data__c =e.getMessage();
                ap1.Data2__c = 'Timecard: ' + piWitem1.ProcessInstance.TargetObjectId;
                ap2Insert.add(ap1);
                Database.insert(ap2Insert,False);
            }
                                              
        }
        
    }
    global void finish(Database.BatchableContext BC)
    {
        
    }
}