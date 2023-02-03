/*---------------------------------------------------------------------------------
* Class Name           : SC_PostChatAgentsAction_Ctrl
* Developer Name       : Pinkesh Rathore
* Date                 : 15th Oct,2018
* JIRA                 : ESESP-420
* Test class           : SC_PostChatAgentsAction_Ctrl_Test
---------------------------------------------------------------------------------*/

public class SC_PostChatAgentsAction_Ctrl {
    
    public String scenario{get;set;}
    public String isResolved{get;set;}
    public String resolutionShortDescription{get;set;}
    public String whyNotResolved{get;set;}
    public String severity{get;set;}
    public String customerExpectations{get;set;}
    public String troubleshootingToDate{get;set;}
    public String caseId{get;set;}
    public Case currentCase{get;set;}
    public LiveChatTranscript currentChatTranscript{get;set;}
    
    public List<SelectOption> resolutionValues{
        get{
            if(resolutionValues == null){
                resolutionValues = new List<SelectOption>();
                resolutionValues.add(new SelectOption('Resolved', 'Resolved'));
                resolutionValues.add(new SelectOption('Not Resolved', 'Not Resolved'));
            }
            return resolutionValues;
        }
        set;
    }
    
    public List<SelectOption> reasonsWhyNotResolved{
        get{
            if(reasonsWhyNotResolved == null){
                reasonsWhyNotResolved = new List<SelectOption>();
                reasonsWhyNotResolved.add(new SelectOption('Urgent Issue', 'Urgent Issue'));
                reasonsWhyNotResolved.add(new SelectOption('More analysis needed', 'More analysis needed'));
                reasonsWhyNotResolved.add(new SelectOption('Hot Customer', 'Hot Customer'));
                reasonsWhyNotResolved.add(new SelectOption('Work with PTSE', 'Work with PTSE'));
            }
            return reasonsWhyNotResolved;
        }
        set;
    }
    
    public List<SelectOption> severityValues{
        get{
            if(severityValues == null){
                severityValues = new List<SelectOption>();
                severityValues.add(new SelectOption('1', '1'));
                severityValues.add(new SelectOption('2', '2'));
                severityValues.add(new SelectOption('3', '3'));
            }
            return severityValues;
        }
        set;
    }
    
    public Boolean hasError { 
        get { 
            return ApexPages.hasMessages(ApexPages.Severity.ERROR);
        } 
        set;
    }
    
    public SC_PostChatAgentsAction_Ctrl(ApexPages.StandardController stdController){
        isResolved = 'Resolved';
        caseId = ApexPages.CurrentPage().getParameters().get('Id');
        System.debug('--CaseId : ' + caseId);
        currentCase = [Select Id, Recordtypeid, RecordType.Name, Origin, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c from Case where id = :caseId];
        List<LiveChatTranscript> chatTranscript = new List<LiveChatTranscript>();
        
        //Added by Vikas for ESESP-1769
        Map<String,String> PLValuesMap = new Map<String,String>();
        for(SC_Utility__mdt  liveChatMetadata : [SELECT MasterLabel,Value__c FROM SC_Utility__mdt where Active__c = true]){
            PLValuesMap.put(liveChatMetadata.MasterLabel,liveChatMetadata.Value__c);
        }
        
        if(currentCase.RecordType.Name == PLValuesMap.get('Pre_Chat_RT_AMG')){
            chatTranscript = [Select Id, CaseID, ChatDuration, ContactID, EndTime, StartTime from LiveChatTranscript where CaseID =:caseId order by createdDate desc Limit 1];
            if(chatTranscript == null || chatTranscript.size() == 0)
                scenario = 'Invalid';
            else if(!String.isEmpty(currentCase.Chat_Resolution__c))
                scenario = 'Completed';
            else{
                scenario = 'Valid';
                currentChatTranscript = chatTranscript[0];
            }
        }
        else if(currentCase.RecordType.Name == PLValuesMap.get('Pre_Chat_RT_Akatech')){
            if(!(String.valueOf(currentCase.Origin)).contains('AkaChat') && String.isEmpty(currentCase.Chat_Resolution__c))
                scenario = 'Invalid';
            else if(!String.isEmpty(currentCase.Chat_Resolution__c))
                scenario = 'Completed';
            else{
                scenario = 'Valid';
            }
        }
    }
    
    public void techincalCaseResolved(){
        Case thisCase = [Select Id, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c, AKAM_Created_Date__c from Case where id = :caseId];
        if(String.isEmpty(thisCase.Chat_Resolution__c)){
            thisCase.Chat_Resolution__c = isResolved;
            thisCase.Root_Cause_Identified_Date__c = system.now();
            thisCase.Resolved_Date__c = system.now();
            thisCase.Status = 'Mitigated / Solution Provided';
            thisCase.Root_Cause__c = resolutionShortDescription;
            thisCase.Validation_Override__c = True;
            try{
                update thisCase;
            }catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error:: ' + e.getStackTraceString() +' :: '+ e.getMessage()));
            }
            
            Task t = new Task();
            t.WhatId = caseId;
            t.Type__c = 'Task';
            t.Subject = 'Live Chat';
            //Added by Vikas for ESESP-1769
            Long dt2Long = system.now().getTime();
            Long dt1Long = thisCase.AKAM_Created_Date__c.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            t.LOE_hours__c = (((Decimal) seconds/3600).setScale(1) > 0.0) ? ((Decimal) seconds/3600) : 0.1;
            //t.LOE_hours__c = (((Decimal) currentChatTranscript.ChatDuration/3600).setScale(1) > 0.0) ? ((Decimal) currentChatTranscript.ChatDuration/3600) : 0.1;
            t.Status = 'Completed';
            try{
                insert t;   
            }catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error:: ' + e.getStackTraceString() +' :: '+ e.getMessage()));
            }
            //Updating the Milestone once post action done ESESP-1842
            updateMilestone(thisCase.Id);
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'This action has already been performed!'));
        }
    }
    
    public void amgCaseResolved(){
        Case thisCase = [Select Id, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c from Case where id = :caseId];
        if(String.isEmpty(thisCase.Chat_Resolution__c)){
            thisCase.Chat_Resolution__c = isResolved;
            thisCase.Resolved_Date__c = currentChatTranscript.EndTime;
            thisCase.LOE_Hours__c = currentChatTranscript.ChatDuration/3600;
            thisCase.LOE_Minutes__c = math.mod(currentChatTranscript.ChatDuration,3600)/60;
            thisCase.Resolution__c = resolutionShortDescription;
            thisCase.Resolution_Field__c = 'Work Completed';
            thisCase.Validation_Override__c = True;
            try{
                update thisCase;    
            }catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error:: ' + e.getStackTraceString() +' :: '+ e.getMessage()));
            }
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'This action has already been performed!'));
        }
    }
    
    public void techincalCaseNotResolved(){
        Case thisCase = [Select Id, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c,AKAM_Created_Date__c from Case where id = :caseId];
        if(String.isEmpty(thisCase.Chat_Resolution__c)){
            thisCase.Chat_Resolution__c = isResolved;
            thisCase.Why_not_Resolved__c = whyNotResolved;
            thisCase.Severity__c = severity;
            thisCase.Customer_Expectations__c = customerExpectations;
            thisCase.Troubleshooting_to_Date__c = troubleshootingToDate;
            thisCase.Case_Assignment_Using_Active_Rules__c = True;
            thisCase.Validation_Override__c = True;
            try{
                update thisCase;
            }catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error:: ' + e.getStackTraceString() +' :: '+ e.getMessage()));
            }
            
            Task t = new Task();
            t.WhatId = caseId;
            t.Type__c = 'Task';
            t.Subject = 'Live Chat';
            //Added by Vikas for ESESP-1769
            Long dt2Long = system.now().getTime();
            Long dt1Long = thisCase.AKAM_Created_Date__c.getTime();
            Long milliseconds = dt2Long - dt1Long;
            Long seconds = milliseconds / 1000;
            t.LOE_hours__c = (((Decimal) seconds/3600).setScale(1) > 0.0) ? ((Decimal) seconds/3600) : 0.1;
            //t.LOE_hours__c = (((Decimal) currentChatTranscript.ChatDuration/3600).setScale(1) > 0.0) ? ((Decimal) currentChatTranscript.ChatDuration/3600) : 0.1;
            t.Status = 'Completed';
            try{
                insert t;
            }catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error:: ' + e.getStackTraceString() +' :: '+ e.getMessage()));
            }
            //Updating the Milestone once post action done ESESP-1842
            updateMilestone(thisCase.Id);
            
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Completed Successfully. Your case has been re-routed to a queue.'));
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'This action has already been performed!'));
        }
    }
    public void amgCaseNotResolved(){
        Case thisCase = [Select Id, Recordtypeid, RecordType.Name, Validation_Override__c ,Root_Cause_Identified_Date__c, Resolved_Date__c, Status, LOE_Hours__c, LOE_Minutes__c, Resolution__c, Root_Cause__c, Service__c, Request_Type__c, Sub_Type__c, ResolvableByPartner__c, Severity__c, Customer_Expectations__c, Troubleshooting_to_Date__c, Chat_Resolution__c, Why_not_Resolved__c, Resolution_Field__c from Case where id = :caseId];
        if(String.isEmpty(thisCase.Chat_Resolution__c)){
            thisCase.Chat_Resolution__c = isResolved;
            thisCase.Why_not_Resolved__c = whyNotResolved;
            thisCase.Validation_Override__c = True;
            try{
                update thisCase;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Completed Successfully.'));
            }catch(exception e){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error:: ' + e.getStackTraceString() +' :: '+ e.getMessage()));
            }
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'This action has already been performed!'));
        }
    }
    private void updateMilestone(Id lCaseIdForMilestone){
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
}