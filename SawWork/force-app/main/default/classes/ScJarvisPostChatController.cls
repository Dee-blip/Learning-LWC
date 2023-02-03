/**
 * @description       : ScJarvisPostChatController
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 01-23-2022
 * @last modified by  : Vishnu Vardhan
 * @testlass          : ScJarvisPostChatControllerTest
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   01-23-2022   Vishnu Vardhan   Initial Version
**/
public class ScJarvisPostChatController {
    public string feedbackOverallExperience{get;set;}
    public string feedbackIssueResolved{get;set;}
    public string feedbackOtherMedium{get;set;}
    public String attachedRecords {get;set;}
    public String akamCaseIdValue {get;set;}
    public String feedbackOverAllExpSel {get;set;}
    public String feedbackAdditionalAdded {get;set;}
    public String feedbackIssueResolvedSel {get;set;}
    public String feedbackOtherMediumSel {get;set;}
    Public Case thisCase {get;set;}
    public Chat_Feedback__c thisFeedback {get;set;}
    public String chatTransId;
   
    
    public ScJarvisPostChatController() {
        attachedRecords = ApexPages.currentPage().getParameters().get('attachedRecords');
        system.debug('attachedRecords: '+attachedRecords);
        string chatKey = ApexPages.currentPage().getParameters().get('chatKey');
        List<LiveChatTranscript> chatTrans = new List<LiveChatTranscript>();
        chatTrans = [select Id, CaseId, Case.Akam_Case_Id__c, Name from LiveChatTranscript where ChatKey =: chatKey limit 1];
        if(!chatTrans.isEmpty()){
            chatTransId = chatTrans[0].Id;
        }

        if(attachedRecords != null){
            thisCase = new Case();
            thisFeedback = new Chat_Feedback__c();
            Map<String, String> caseIdMap = (Map<String,String>) JSON.deserialize(attachedRecords, Map<String,String>.class);
            system.debug('caseIdMap: '+caseIdMap.size());
            if(caseIdMap != null && caseIdMap.size() > 0) {
                akamCaseIdValue = [Select Akam_Case_Id__c from case where id =: Id.valueOf(caseIdMap.get('CaseId'))].Akam_Case_Id__c;
            } else if(chatTrans.size() > 0 && String.isNotBlank(chatTrans[0].CaseId)){
                akamCaseIdValue = chatTrans[0].Case.Akam_Case_Id__c;
            }
        }
        
        
        Schema.DescribeFieldResult fieldResult; 
        List<Schema.PicklistEntry> PLE;
        
        fieldResult = Chat_Feedback__c.Feedback_Overall_Experience__c.getDescribe();
        PLE = fieldResult.getPicklistValues();
        feedbackOverallExperience = json.serialize (PLE);
        
        fieldResult = Chat_Feedback__c.Feedback_Issue_Resolved__c.getDescribe();
        PLE = fieldResult.getPicklistValues();
        feedbackIssueResolved = json.serialize (PLE);
        
        fieldResult = Chat_Feedback__c.Feedback_Other_Medium__c .getDescribe();
        PLE = fieldResult.getPicklistValues();
        feedbackOtherMedium = json.serialize (PLE);
    }
    public PageReference saveRecord() { 
        try{
            if(akamCaseIdValue != null){
                Case updateCase = [Select id from Case where Akam_Case_Id__c =: akamCaseIdValue];
                Chat_Feedback__c updateFeedback = new Chat_Feedback__c();
                updateFeedback.Feedback_Overall_Experience__c = feedbackOverAllExpSel;
                updateFeedback.Feedback_Additional_Comments__c = feedbackAdditionalAdded;
                updateFeedback.Feedback_Issue_Resolved__c = feedbackIssueResolvedSel;
                updateFeedback.Feedback_Other_Medium__c = feedbackOtherMediumSel;
                updateFeedback.Case__c = updateCase.Id;
                if(!String.isBlank(chatTransId)){
                    updateFeedback.Chat_Transcript__c = chatTransId;
                }
                insert updateFeedback;
            }
        }
        catch(exception e){
            SC_Jarvis_utility.sendErrorMails('Jarvis Post Chat','Exception: ' , e.getMessage());
        }
        return null;
    }
    
}