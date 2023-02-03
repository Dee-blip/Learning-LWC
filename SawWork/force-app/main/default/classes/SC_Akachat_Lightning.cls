/*
Author          : Sheena Bhan
Description     : Controller Class for Post Chat Action in Lightning
Test Class		: SC_Akachat_Lightning_Test


Date                Developer             JIRA #                            Description                                                       
-------------------------------------------------------------------------------------------------------------------------------------------------
13 May 2020         Sheena               ESESP-2347               		Akachat Migration to Lightning
2 Sept 2021			Sheena				 ESESP-5492						Send transcript email from future method in techincalCaseResolved method
-------------------------------------------------------------------------------------------------------------------------------------------------
*/

public class SC_Akachat_Lightning {
    public static LiveChatTranscript currentChatTranscript;
    public static String previousCaseOwnerEmail = '';
    
    
    @AuraEnabled
    public static List<String> getRadioOptions(){
        List<String> pickListValuesList= new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.Chat_Resolution__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }
    
    
    @AuraEnabled
    public static String getValidations(String caseId){
        String scenario;
        System.debug('--CaseId : ' + caseId);
        Case currentCase = [Select Id, Recordtypeid, RecordType.Name, Origin, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c from Case where id = :caseId];
        List<LiveChatTranscript> chatTranscript = new List<LiveChatTranscript>();
        chatTranscript = [Select Id, CaseID, ChatDuration, ContactID, EndTime, StartTime,Body from LiveChatTranscript where CaseID =:caseId order by createdDate desc Limit 1];
        if(currentCase.RecordType.Name == 'AMG'){
            if(chatTranscript == null || chatTranscript.size() == 0)
                scenario = 'Invalid';
            else if(chatTranscript[0].EndTime==null || chatTranscript[0].ChatDuration==null || chatTranscript[0].Body=='')
                scenario = 'Close Transcript';
            else if(!String.isEmpty(currentCase.Chat_Resolution__c))
                scenario = 'Completed';
            else{
                scenario = 'Valid';
                currentChatTranscript = chatTranscript[0];
            }
        }
        else if(currentCase.RecordType.Name == 'Technical' || currentCase.RecordType.Name == 'Managed Security'){
            if(!(String.valueOf(currentCase.Origin)).contains('AkaChat') && String.isEmpty(currentCase.Chat_Resolution__c))
                scenario = 'Invalid';
            else if(!chatTranscript.isEmpty() && (chatTranscript[0].EndTime==null || chatTranscript[0].ChatDuration==null || chatTranscript[0].Body==''))
                scenario = 'Close Transcript';
            else if(!String.isEmpty(currentCase.Chat_Resolution__c))
                scenario = 'Completed';
            else{
                scenario = 'Valid';
            }
        }
        else{
            scenario = 'Invalid';
        }
        system.debug('scenario//'+scenario);
        return scenario;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static map<String,String> getCaseRecType(String caseId)
    {  
        map<string,string> mRecTypeIdName = new map<string,string>();
        Case cs = [Select id, RecordType.Name from Case where id =: caseId];
        mRecTypeIdName.put(cs.RecordTypeId, cs.RecordType.Name);
        return mRecTypeIdName;   
    }
    
    @AuraEnabled
    public static void techincalCaseResolved(String caseId, map<string,string> fieldValues, String radioOption){
        Case thisCase = [Select Id, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c, AKAM_Created_Date__c from Case where id = :caseId];
        thisCase.Chat_Resolution__c = radioOption;
        thisCase.Root_Cause_Identified_Date__c = system.now();
        thisCase.Resolved_Date__c = system.now();
        thisCase.Status = 'Mitigated / Solution Provided';
        thisCase.Root_Cause__c = fieldValues.get('Root_Cause__c') != '' ? fieldValues.get('Root_Cause__c') : '';
        thisCase.Validation_Override__c = True;
        try{
            update thisCase;
            
            //Calling future method to send Chat Transcript
            if(!(System.isFuture() || System.isBatch()))
            {
                sendTranscript(thisCase.Id,thisCase.Root_Cause__c,true);
            }
            
            Task t = new Task();
            t.WhatId = caseId;
            t.Type__c = 'Task';
            t.Subject = 'Live Chat';
            Long dt2Long = system.now().getTime();
            Long dt1Long = thisCase.AKAM_Created_Date__c.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            t.LOE_hours__c = (((Decimal) seconds/3600).setScale(1) > 0.0) ? ((Decimal) seconds/3600) : 0.1;
            t.Status = 'Completed';
            try{
                insert t;   
                updateMilestone(thisCase.Id);
            }catch(exception e){
                e.getMessage();
            }
            
        }catch(exception e){
            e.getMessage();
        }
        
    }
    
    @future
    public static void sendTranscript(Id caseId, String rootCause, Boolean isResolved) {
        // Send Chat Transcript to Customers  
        sendTranscriptToCustomers(caseId,rootCause,isResolved);
    }
    
    @AuraEnabled
    public static void amgCaseResolved(String caseId, map<string,string> fieldValues, String radioOption){
        String amgScenario;
        List<LiveChatTranscript> chatTranscript = new List<LiveChatTranscript>();
        Case thisCase = [Select Id, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c from Case where id = :caseId];
        chatTranscript = [Select Id, CaseID, ChatDuration, ContactID, StartTime, EndTime from LiveChatTranscript where CaseID =:caseId order by createdDate desc Limit 1];
        
        thisCase.Chat_Resolution__c = radioOption;
        thisCase.Resolved_Date__c = chatTranscript[0].EndTime;
        thisCase.LOE_Hours__c = chatTranscript[0].ChatDuration/3600;
        thisCase.LOE_Minutes__c = math.mod(chatTranscript[0].ChatDuration,3600)/60;
        thisCase.Resolution__c = fieldValues.get('Resolution__c') != '' ? fieldValues.get('Resolution__c') : '';
        thisCase.Resolution_Field__c = 'Work Completed';
        thisCase.Validation_Override__c = True;
        try{
            update thisCase;
            sendTranscriptToCustomers(thisCase.Id,thisCase.Resolution__c,true);
        }catch(exception e){
            system.debug('error//'+e.getMessage());
        }
        
    }
    
    @AuraEnabled
    public static void techincalCaseNotResolved(String caseId, map<string,string> fieldValues, String radioOption){
        Case thisCase = [Select Id, Owner.Email, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c,AKAM_Created_Date__c from Case where id = :caseId];
        previousCaseOwnerEmail = thisCase.Owner.Email;
        thisCase.Chat_Resolution__c = radioOption;
        thisCase.Why_not_Resolved__c = fieldValues.get('Why_not_Resolved__c') != '' ? fieldValues.get('Why_not_Resolved__c') : '';
        thisCase.Severity__c = fieldValues.get('Severity__c') != '' ? fieldValues.get('Severity__c') : '';
        thisCase.Customer_Expectations__c = fieldValues.get('Customer_Expectations__c') != '' ? fieldValues.get('Customer_Expectations__c') : '';
        thisCase.Troubleshooting_to_Date__c = fieldValues.get('Troubleshooting_to_Date__c') != '' ? fieldValues.get('Troubleshooting_to_Date__c') : '';
        thisCase.Case_Assignment_Using_Active_Rules__c = True;
        thisCase.Validation_Override__c = True;
        try{
            update thisCase;
            //Calling future method to send Chat Transcript
            if(!(System.isFuture() || System.isBatch()))
            {
                sendTranscript(thisCase.Id,thisCase.Troubleshooting_to_Date__c,false);
            }
            //sendTranscriptToCustomers(thisCase.Id,thisCase.Troubleshooting_to_Date__c,false);
            Task t = new Task();
            t.WhatId = caseId;
            t.Type__c = 'Task';
            t.Subject = 'Live Chat';
            Long dt2Long = system.now().getTime();
            Long dt1Long = thisCase.AKAM_Created_Date__c.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            t.LOE_hours__c = (((Decimal) seconds/3600).setScale(1) > 0.0) ? ((Decimal) seconds/3600) : 0.1;
            t.Status = 'Completed';
            try{
                insert t;
                updateMilestone(thisCase.Id);
            }catch(exception e){
                e.getMessage();
            }
            
        }catch(exception e){
            e.getMessage();
        }
        
    }
    
    @AuraEnabled
    public static void amgCaseNotResolved(String caseId, map<string,string> fieldValues, String radioOption){
        Case thisCase = [Select Id, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c from Case where id = :caseId];
        thisCase.Chat_Resolution__c = radioOption;
        thisCase.Why_not_Resolved__c = fieldValues.get('Why_not_Resolved__c') != '' ? fieldValues.get('Why_not_Resolved__c') : '';
        thisCase.Validation_Override__c = True;
        thisCase.Troubleshooting_to_Date__c = fieldValues.get('Troubleshooting_to_Date__c') != '' ? fieldValues.get('Troubleshooting_to_Date__c') : '';
        try{
            update thisCase;
            sendTranscriptToCustomers(thisCase.Id,thisCase.Troubleshooting_to_Date__c,false);
        }catch(exception e){
            e.getMessage();
        }
        
    }
    
    public static void updateMilestone(Id lCaseIdForMilestone){
        List<CaseMilestone> lCaseMilestones = new List<caseMilestone>();
        for(CaseMilestone eachrec : [Select id, MilestoneType.Name, CaseId, StartDate, CompletionDate, IsCompleted from CaseMilestone
                                     where CaseId =:lCaseIdForMilestone and
                                     IsCompleted = false and
                                     MilestoneType.Name IN ('Initial Response') and
                                     case.IsClosed = false]){
                                         eachrec.CompletionDate = eachrec.StartDate;  
                                         lCaseMilestones.add(eachrec);
                                     }
        if(lCaseMilestones.size() > 0)
            update lCaseMilestones;
    }
    
    public static void sendTranscriptToCustomers(Id caseId, String CaseData, Boolean isResolved)
    {
        List<LiveChatTranscript> transcriptList = [Select id, body, CaseId, Case.Root_Cause__c, Case.Resolution__c, Case.Troubleshooting_to_Date__c, Case.Chat_Resolution__c, Case.ContactId, Case.Contact.Email, Case.Contact.Name, Case.AKAM_Case_ID__c, Case.Description, Case.Owner.Email, Case.Account.Mailing_List_for_Technical_Case_auto_cc__c from LiveChatTranscript where CaseId =: caseId ORDER BY CreatedDate DESC limit 1];
        Case updateCase = [Select id,Resolution_Sent__c,Validation_Override__c from case where id =:caseId];
        SC_Utility__mdt  no_reply = [SELECT Value__c FROM SC_Utility__mdt where DeveloperName  = 'no_reply_id'];
        OrgWideEmailAddress orgWideEmailAdd = [select id, Address, DisplayName from OrgWideEmailAddress where Address =: no_reply.Value__c];
        if(!transcriptList.isEmpty())
        {
            for(LiveChatTranscript chatTrans : transcriptList)
            {
                
                Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                attach.setContentType('application/pdf');
                attach.setFileName('Chat Transcript.pdf');

                String body;
                String emailSubject;
                body = '<html><body><h2 style=\"text-align:center;\">Chat Transcript</h2><br/><br/>' + chatTrans.body + '</body></html>';
                attach.Body = Blob.toPDF(body);
                
                if(isResolved){
                    emailSubject = 'Resolution Summary [AKAM-CASE #'+chatTrans.Case.AKAM_Case_ID__c+']';
                }
                else{
                    emailSubject = 'Chat Summary [AKAM-CASE #'+chatTrans.Case.AKAM_Case_ID__c+']';
                }
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                
                string[] toAddress = new string[] {chatTrans.Case.Contact.Email};
                string[] ccAddress = new string[]{};
                 
                if(chatTrans.Case.Owner.Email != null){
                    toAddress.add(chatTrans.Case.Owner.Email);
                }
                if(previousCaseOwnerEmail != ''){
                    toAddress.add(previousCaseOwnerEmail);
                }
                if(chatTrans.Case.Account.Mailing_List_for_Technical_Case_auto_cc__c != null){
                    ccAddress.add(chatTrans.Case.Account.Mailing_List_for_Technical_Case_auto_cc__c);
                }
                   
                email.setToAddresses(toAddress);
                if(ccAddress.size() > 0)
                	email.setCcAddresses(ccAddress); 
                email.setOrgWideEmailAddressId(orgWideEmailAdd.Id);
                email.setSubject(emailSubject);
                //email.setSaveAsActivity(true);
                email.setHtmlBody('Hi '+ chatTrans.Case.Contact.Name + ','+ '<br> <br>' +
                                  'Please find below chat summary for Case: ' + chatTrans.Case.AKAM_Case_ID__c + ' - ' + chatTrans.Case.Description + '<br> <br>' +
                                  'CHAT SUMMARY: ' + CaseData + '<br> <br> <br>' +
                                  'You may open a new support request at any time through Control Center at https://control.akamai.com/' + '<br>'+
                                  'You can also ask questions and connect with product experts in the Akamai Community at https://community.akamai.com');
                email.setFileAttachments(new Messaging.EmailFileAttachment[] { attach }); 
                try{
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                    updateCase.Resolution_Sent__c = true;
                    updateCase.Validation_Override__c = true;
                    update updateCase;
                    
                    EmailMessage emailMsg = new EmailMessage(); // Created a EmailMessage and copy all details from above.
                    emailMsg.ToAddress=(email.getToAddresses())[0];
                    emailMsg.fromAddress=orgWideEmailAdd.Address;
                    if(email.getCcAddresses() != null)
                    	emailMsg.CcAddress=(email.getCcAddresses())[0];
                    emailMsg.Subject=email.getSubject();
                    emailMsg.HtmlBody=email.getHtmlBody();
                    emailMsg.ParentId = caseId; //Attach with the case
                    emailMsg.MessageDate = system.now();
                    emailMsg.Status = '0';
                    insert emailMsg;
                    
                }catch(exception e){
                    e.getMessage();
                    system.debug('error//'+e.getMessage());
                }
            }
        }
    }
    
    
}