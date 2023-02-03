/*
* Author: Sharath Prasanna
* This is the controller for the PSA_BulkApproveTimecardPoller page. This is used for the bulk approval of Timecards
*/

public  class PSA_BulkApproveTimecardPollerController {

    public Integer TimecardBatchSize {get;set;}
    //TimecardBatchSize stores the number of TCs to be processed per batch
    public Integer PendingTimecards {get;set;}
    //PendingTimecards stores the number of TCs that are pending
    public Integer ErrorCount {get;set;}
    //ErrorCount stores the number of errors in the current batch run
    public Integer TotalErrors {get;set;}
    //TotalErrors stores the total errors 
    public Integer SuccessCount {get;set;}
    //SuccessCount stores the successes per batch
    public Integer TotalSuccesses {get;set;}
    //TotalSuccesses stores the total successes
    public Integer CurrentBatch {get;set;}
    //CurrentBatch stores the current batch number starting from 1
    public  String  Action {get;set;}
    //Action stores the action to be performed: Approve or Reject
    public  String  Comment {get;set;}
    //Comment stores the comment
    public  String  TimeCardIDs {get;set;}
    //TimeCardIDs stores the string of TC ids to be processed
    public  Boolean  EnablePoller {get;set;}
    //EnablePoller is set to false to disable the poller
    public  Boolean RenderWarningText {get;set;}
    //RenderWarningText is set to false to remove the warning text on the poller page
    public Boolean MailSent{get;set;}
    //MailSent is set to true when mail is sent to the manager
    List <Id> TimecardIDList {get;set;}
    //TimecardIDList is the list of TC ids to process
    List<id> SelectedTimecardIDs {get;set;}
    //SelectedTimecardIDs is the list of TC ids that have been processed or the ids that have already been queried
    public String Body{get;set;} 
    //Body stores the body of the email to be sent
    public String ErrorMessages{get;set;}
    //ErrorMessages has the error messages. It is stored in the form of one table row per TC
    //public String orderBy {get;set;} 
    public PSE_Timecard_Approval_Object__c approvalObject{get;set;}
    //The record of the PSE_Timecard_Approval_Object__c object created for the TC processing is queried and stored in approvalObject
    //String fromAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c;
    String fromAddress = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'FromEmailAdress'].Value_Long__c ;
        
    String orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
    //String TimecardBatchSizeCustomSetting = PSA_Settings__c.getInstance('TimecardBatchSize').Value__c;
    String TimecardBatchSizeCustomSetting = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'TimecardBatchSize'].Value_Long__c;

    //The constructor function. All the variables are initialised.
    public PSA_BulkApproveTimecardPollerController()
    {

        ErrorCount = 0;
        SuccessCount = 0;
        TotalErrors = 0;
        TotalSuccesses = 0;
        MailSent = false;
        TimecardBatchSize = integer.valueof(TimecardBatchSizeCustomSetting);
        //getting the Id of the PSE_Timecard_Approval_Object__c object from the url
        ID ApprovalObjectID = ApexPages.currentPage().getParameters().get('ApprovalObjectID');
        //Querying for the PSE_Timecard_Approval_Object__c record
        approvalObject = [Select id,Timecard_IDs__c,Comments__c,Action__c from PSE_Timecard_Approval_Object__c where ID = :ApprovalObjectID limit 1];
        Comment = approvalObject.Comments__c;
        Action = approvalObject.Action__c;
        TimeCardIDs = approvalObject.Timecard_IDs__c;
        TimecardIDList = TimeCardIDs.split(',');
        PendingTimecards = TimecardIDList.size();
        SelectedTimecardIDs = new List<ID> ();
        EnablePoller = true;
        CurrentBatch = 1;
        RenderWarningText = true;
        Body='';
        //creating a table for the errors
        ErrorMessages = '<table>' + '<tr>' + '<th>Timecard ID</th>' + '<th>Project</th>' + '<th>Resource</th>'+ '<th>Start Date</th>'+ '<th>Milestone</th>'+ '<th>Validation Message</th>' + '</tr>';
        //FailedToProcess = 
    }

    //The function called from the poller
    //This function processes TCs and disables the poller once the processing of all the TCs are complete
    public PageReference ApproveorRejectTimecards()
    {
        ErrorCount = 0;
        SuccessCount = 0;
        Map <ID,pse__Timecard_Header__c> tch;
        //CurrentBatch++;
        //List <pse__Timecard_Header__c> tch = [SELECT Id,Name,pse__Resource__r.Name,pse__Resource__c,pse__Status__c, pse__Friday_Hours__c , pse__Monday_Hours__c , pse__Saturday_Hours__c , pse__Sunday_Hours__c , pse__Thursday_Hours__c , pse__Tuesday_Hours__c , pse__Wednesday_Hours__c , pse__Friday_Notes__c , pse__Monday_Notes__c , pse__Saturday_Notes__c , pse__Sunday_Notes__c , pse__Thursday_Notes__c , pse__Tuesday_Notes__c , pse__Wednesday_Notes__c ,pse__Additional_Notes__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Total_Hours__c,pse__Start_Date__c from pse__Timecard_Header__c where pse__Status__c!='Approved' and pse__Status__c!='Saved' and Id in :TimecardIDList Limit :TimecardBatchSize ];
        //Map <ID,pse__Timecard_Header__c> tch = new  Map <ID,pse__Timecard_Header__c> (new List<pse__Timecard_Header__c>([SELECT Id,Name,pse__Resource__r.Name,pse__Resource__c,pse__Status__c, pse__Friday_Hours__c , pse__Monday_Hours__c , pse__Saturday_Hours__c  , pse__Sunday_Hours__c , pse__Thursday_Hours__c , pse__Tuesday_Hours__c , pse__Wednesday_Hours__c , pse__Friday_Notes__c , pse__Monday_Notes__c , pse__Saturday_Notes__c , pse__Sunday_Notes__c , pse__Thursday_Notes__c , pse__Tuesday_Notes__c , pse__Wednesday_Notes__c ,pse__Additional_Notes__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Total_Hours__c,pse__Start_Date__c from pse__Timecard_Header__c where pse__Status__c!='Approved' and pse__Status__c!='Saved' and Id in :TimecardIDList Limit :TimecardBatchSize ]));
        //Doing an order by total hours. For Approvals, the order is descending and for rejects, the order is ascending
        if (Action == 'Approve')
        {
                  tch = new  Map <ID,pse__Timecard_Header__c> (new List<pse__Timecard_Header__c>([SELECT Id,Name,pse__Resource__r.Name,pse__Resource__c,pse__Status__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Total_Hours__c,pse__Start_Date__c from pse__Timecard_Header__c where pse__Status__c!='Approved' and pse__Status__c!='Rejected' and pse__Status__c!='Saved' and Id in :TimecardIDList and Id not in :SelectedTimecardIDs order by pse__Start_Date__c desc, pse__Total_Hours__c  desc Limit :TimecardBatchSize ]));

        }
        else
        {
                  tch = new  Map <ID,pse__Timecard_Header__c> (new List<pse__Timecard_Header__c>([SELECT Id,Name,pse__Resource__r.Name,pse__Resource__c,pse__Status__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Total_Hours__c,pse__Start_Date__c from pse__Timecard_Header__c where pse__Status__c!='Approved' and pse__Status__c!='Rejected' and pse__Status__c!='Saved' and Id in :TimecardIDList and Id not in :SelectedTimecardIDs order by pse__Start_Date__c desc, pse__Total_Hours__c  asc Limit :TimecardBatchSize ]));
        }
        
        //adding the retrieved TC ids to SelectedTimecardIDs 
        SelectedTimecardIDs.addAll(tch.keySet());

       // List <ID> TCH2ApproveIds = new List <ID> ();
        //for(pse__Timecard_Header__c timecard : tch.keySet())
        //{
        //    TCH2ApproveIds.add(timecard.Id);
        //}        
        //querying for the ProcessInstanceWorkitem record corresponding to the TCs        
        List<ProcessInstanceWorkitem> piwItem = [Select Id,ProcessInstance.TargetObjectId from ProcessInstanceWorkitem where ProcessInstance.Status = 'Pending' and ProcessInstance.TargetObjectId in:tch.keySet() ];
        Approval.ProcessWorkitemRequest req2;
        //creating a ProcessWorkitemRequest list to approve or reject TC
        List<Approval.ProcessWorkitemRequest> listReq = new List<Approval.ProcessWorkitemRequest>();
        //the result of the ProcessWorkitemRequest is stored in  ProcessResult 
        List<Approval.ProcessResult> result2 = new List<Approval.ProcessResult>();
        for(ProcessInstanceWorkitem piw1:piwItem)
        {
            req2 = new Approval.ProcessWorkitemRequest();
            if (Comment != null )
            {
                req2.setComments(Comment);                
            }
            req2.setAction(Action);
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req2.setWorkitemId(piw1.Id);
            listReq.add(req2);
            
        }
        //try
        //{

        //}
        try
        {
               //approving or rejecting the TCs. the results are stored in result2   
              result2 =  Approval.process(listReq,False);
        }
        catch (Exception e)
        {
            //List<String> sendTo1 = new List<String>();
            //List<Messaging.SingleEmailMessage> mailsToBeSent1 = new List<Messaging.SingleEmailMessage>();
            //sendTo1.add(UserInfo.getUserEmail());
            //Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();      
            //email1.setToAddresses(sendTo1);
            //email1.setOrgWideEmailAddressId(orgWideEmailId);
            //email1.setSubject('Timecard Bulk Action Mail');
            //email1.setPlainTextBody('Hi ' + UserInfo.getName() + '\n\n There was as error in processing the timecards: ' + e.getMessage());
            //mailsToBeSent1.add(email1);
            //Messaging.sendEmail(mailsToBeSent1,false);

            PSA_AutoCreateProjectUtil.sendErrorMails('There was as error in processing the timecards: ',e.getMessage());

        }
        //result2 =  Approval.process(listReq,False);
        //for(Approval.ProcessResult result1:result2)
        if(result2!=NULL)
        {
            //Iterating over the result list, for every failure, create a table row in the ErrorMessages variable
            for (Integer index = 0;index < result2.size(); index++)
            {
                Approval.ProcessResult result1 = result2.get(index);
                if(!result1.isSuccess())
                {
                    pse__Timecard_Header__c timecard = tch.get(piwItem.get(index).ProcessInstance.TargetObjectId);
                     ErrorMessages += '<tr>' 
                                   + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.ID+ '">'+timecard.Name + '</a>'+ '</td>'
                                        + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.pse__Project__c+ '">'+timecard.pse__Project__r.Name + '</a>'+ '</td>'
                                        + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.pse__Resource__c+ '">'+timecard.pse__Resource__r.Name + '</a>'+ '</td>'
                                        + '<td>' + timecard.pse__Start_Date__c+ '</td>'
                                        + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.pse__Milestone__c+ '">'+timecard.pse__Milestone__r.Name + '</a>'+ '</td>'
                                        + '<td>' +result1.getErrors()[0].getMessage() + '</td>' 
                                        + '</tr>';

                    ErrorCount++;
                    TotalErrors++;
                }
                if(result1.isSuccess())
                {
                    SuccessCount++;
                    TotalSuccesses++;
                }
            }
        }
        //If no TCs were processed in this batch, exit the process. The poller is disabled        
        if ((PendingTimecards -  tch.size()) == PendingTimecards)
        {
                //TotalErrors += PendingTimecards;
                PendingTimecards = 0;
                //UnprocessedTimecardsError();
                sendMailToUser();
                MailSent = true;
                EnablePoller = false;
                RenderWarningText = false;
        }
        //If the PendingTimecards becomes 0, that is the processing is complete for all TCs, exit the process and disable the poller
        else if ((PendingTimecards -  tch.size()) == 0 || (PendingTimecards -  tch.size()) < 0)
        {
                //FailedToProcess = '<br/><br /><table>' + '<tr>' + '<th>Timecard ID</th>' + '<th>Validation Message</th></tr>';
                PendingTimecards = 0;
                MailSent = true;
                sendMailToUser();
                EnablePoller = false;
                RenderWarningText = false;
        }
        //The processing is not complete, subtract the TCs processed in this batch from the Pendingtimecards
        else
        {
                CurrentBatch++;
                PendingTimecards -= tch.size();
        }
        return null;
    }
    //The function that is called when the user closes the browser or refreshes the poller page
    public void UnprocessedTimecardsError()
    {
        //This function gets a list of all TC ids that were to be processed, that is TimecardIDList and that were not in the list of TC ids that were actually processed, that is SelectedTimecardIDs
        //A row is created for each of these unprocessed TC in the ErrorMessages variable
          Map <ID,String> processedIDsToEmptyString = new  Map <ID,String>();
          List<ID> tchids = new List<ID>();
          List <pse__Timecard_Header__c> timecardList= new List <pse__Timecard_Header__c>();
          for (ID timecardID: SelectedTimecardIDs)
          {
                //system.assertEquals(1,0);
                processedIDsToEmptyString.put(timecardID,'');                
          } 
          for (ID timecardIDS : TimecardIDList)
          {
                  
                if (!processedIDsToEmptyString.containsKey(timecardIDS))
                {    
                    //system.assertEquals(2,0);
                    tchids.add(timecardIDS);
                }
          }
          timecardList = [SELECT Id,Name,pse__Resource__r.Name,pse__Resource__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Start_Date__c from pse__Timecard_Header__c where Id in :tchids ];
          for (pse__Timecard_Header__c timecard: timecardList)
          {
                ErrorMessages += '<tr>' 
                               + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.ID+ '">'+timecard.Name + '</a>'+ '</td>'
                                    + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.pse__Project__c+ '">'+timecard.pse__Project__r.Name + '</a>'+ '</td>'
                                    + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.pse__Resource__c+ '">'+timecard.pse__Resource__r.Name + '</a>'+ '</td>'
                                    + '<td>' + timecard.pse__Start_Date__c+ '</td>'
                                    + '<td>' +'<a href = "' +URL.getSalesforceBaseUrl().toExternalForm() + '/' + timecard.pse__Milestone__c+ '">'+timecard.pse__Milestone__r.Name + '</a>'+ '</td>'
                                    + '<td>' +'Timecard Could not be processed' + '</td>' 
                                    + '</tr>';            
          }
    }
    //The function that is called to send a mail to the user
    public void sendMailToUser()
    {
        Integer TotalTimecardsProcessed = TotalSuccesses + TotalErrors;
        String mailAction;
        if (Action == 'Approve')
        {
            mailAction = 'Approved';
        }
        else
        {
            mailAction = 'Rejected';    
        }
        Body = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + UserInfo.getName() + ',<br/><br/>' + '<ol><li>Total Timecards '+ mailAction + ' -> ' + TotalSuccesses + '</li><li>' +'Total Timecards that could not be ' + mailAction + ' -> ' + TotalErrors + '</li></ol>';
        List<String> sendTo = new List<String>();
        List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        sendTo.add(UserInfo.getUserEmail());
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();      
        email.setToAddresses(sendTo);
        email.setOrgWideEmailAddressId(orgWideEmailId);
        email.setSubject('Timecard Bulk Action Mail');
        if (TotalErrors > 0)
        {
            ErrorMessages += '</table>';
            Body += ErrorMessages;
        }
        email.setHTMLBody( Body + '</body></html>');
        mailsToBeSent.add(email);
        Messaging.sendEmail(mailsToBeSent,false);

    }

    //The function that is called when the user closes the browser or refreshes the poller page
    public void sendProcessTerminationMail()
    {
        //delete the approval object record
        try{
            Database.delete(approvalObject);
           }
        catch(Exception e){

        }    
        TotalErrors += PendingTimecards;
        //Check if a mail is not sent to the user
        if (!MailSent)
        {
            UnprocessedTimecardsError();
            sendMailToUser();
        }
    }

    //The function that is called when the finish link is clicked on the poller page
    public PageReference redirectToApprovalPage()
    {
        //Database.delete(approvalObject);
        PageReference pg = new PageReference('/apex/PSA_TCApproveNew');
        return pg;
    }
}