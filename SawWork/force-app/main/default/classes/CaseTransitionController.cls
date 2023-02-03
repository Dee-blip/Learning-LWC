/*****************************************************************************
 * Name             : CaseTransitionController
 * Created By       : Pitamber Sharma
 * Created Date     : 20-May-2013
 * Purpose          : Controller class for Case Transitions VF Page
  Last Modified Developer   Purpose            
  ============= =========   ========
    17-Feb-14   Himanshu    Handled Exception in "saveCTOwner" method(CR#2485560) 
	07-AUG-14   Himanshu    Added @TestVisible to "isNotEmpty" method for calling in test class 
 *****************************************************************************/
 
public with sharing class CaseTransitionController {
    public Case currentCase{get;set;}
    public List<Case_Transition__c> caseTransitions{get;set;}
    public Boolean showEditBlock{get;set;}
    public Boolean showDetailBlock{get;set;}
    public Boolean showOwnerPrompt{get;set;}
    public Case_Transition__c ctDetail{get;set;}
    public Case_Transition__c ctEdit{get;set;}
    public String ctID{get;set;}
    @TestVisible Id oldOwnerId;
    
    public CaseTransitionController(ApexPages.StandardController stdController) {
        currentCase = (Case) stdController.getRecord();
        currentCase = [Select Id, IsEscalated, ownerId From Case Where Id =: currentCase.Id];
        
        populateCTList();
        
        showDetailBlock = false;
        showEditBlock = false;
        showOwnerPrompt = false;
    }
    
    private void populateCTList() {
        caseTransitions = new List<Case_Transition__c>();
        for(Case_Transition__c ct : [Select Id,
                                                                                Name,
                                                                                New_Owner__r.Name,
                                                                                Previous_Owner__r.Name,
                                                                                Transition_Date__c
                                                                    From Case_Transition__c
                                                                    Where Case__c =: currentCase.Id
                                                                    Order By CreatedDate desc]) {
            caseTransitions.add(ct);
        }
        if(caseTransitions.size() <= 0) {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'No Case Transitions Available.');
            ApexPages.addMessage(myMsg);
        }
    }
    
    public Pagereference showEdit() {
        showDetailBlock = false;
        showEditBlock = true;
        if(ctID != null && !ctID.equals('')) {
            ctEdit = [Select Id,
                                             Case__c,
                                             Customer_Expectations__c,
                                             Data_Collected__c,
                                             Escalated__c,
                                             Escalation_Expectations__c,
                                             Issue_Summary__c,
                                             New_Owner__c,
                                             Next_Action_Recommendation__c,
                                             Previous_Owner__c,
                                             Reason__c,
                                             Transition_Date__c,
                                             Troubleshooting_to_Date__c 
                                From Case_Transition__c
                                Where Id =: ctID];
        } else {
            ctEdit = new Case_Transition__c(Case__c = currentCase.Id);
        }
        return null;
    }
    
    public Pagereference showDetail() {
        showDetailBlock = true;
        showEditBlock = false;
        ctDetail = [Select Id,
                                             Case__c,
                                             Customer_Expectations__c,
                                             Data_Collected__c,
                                             Escalated__c,
                                             Escalation_Expectations__c,
                                             Issue_Summary__c,
                                             New_Owner__r.Name,
                                             Next_Action_Recommendation__c,
                                             Previous_Owner__r.Name,
                                             Reason__c,
                                             Transition_Date__c,
                                             Troubleshooting_to_Date__c 
                                From Case_Transition__c
                                Where Id =: ctID];
        return null;
    }
    
    public Pagereference saveCase() {
        upsert ctEdit;
        
        showDetailBlock = false;
        showEditBlock = false;
        
        populateCTList();
        return null;
    }
    
    public Pagereference assignUser() {
        if(ctID != null && !ctID.equals('')) {
            ctEdit = [Select Id,
                                             New_Owner__c,
                                             Previous_Owner__c,
                                             Case__c,
                                             Customer_Expectations__c,
                                             Data_Collected__c,
                                             Escalated__c,
                                             Escalation_Expectations__c,
                                             Issue_Summary__c,
                                             New_Owner__r.Name,
                                             Next_Action_Recommendation__c,
                                             Previous_Owner__r.Name,
                                             Reason__c,
                                             Transition_Date__c,
                                             Troubleshooting_to_Date__c 
                                From Case_Transition__c
                                Where Id =: ctID];
            showOwnerPrompt = true;
            if(ctEdit.New_Owner__c != null) {
                oldOwnerId = ctEdit.New_Owner__c;
            } else {
                oldOwnerId = null;
            }
        }
        return null;
    }
    
    public Pagereference saveCTOwner () {
    
        // Fetching Case Owner Value
        string currCaseOwner = currentCase.ownerId;
        try{
          if(ctEdit.New_Owner__c != null && oldOwnerId != ctEdit.New_Owner__c && !(currCaseOwner.startsWith('00G'))) {
            ctEdit.Previous_Owner__c = currentCase.ownerId;
            ctEdit.Transition_Date__c = Date.today();
        
            update ctEdit;
            if(currentCase.OwnerId != ctEdit.New_Owner__c) {
                currentCase.OwnerId = ctEdit.New_Owner__c;
                update currentCase;
            }
            
            populateCTList();
            showOwnerPrompt = false;
          }
          else
          {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'This case is assigned to a Queue. ' + 
                                'Currently Case Transitions can be used for user-to-user transitions only.'));
          }
          
       } catch(exception e){}
        return null;
    }
    
    public Pagereference cancelRequest() {
        showDetailBlock = false;
        showEditBlock = false;
        showOwnerPrompt = false;
        return null;
    }
    
    @TestVisible private Boolean isNotEmpty(String s) {
        if(s != null && !s.trim().equals(''))
            return true;
        return false;
    }

}