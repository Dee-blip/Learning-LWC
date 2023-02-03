global class SC_CaseTransitionHistoryController {
/*
    global Case currentCase{get;set;}
    global List<Case_transition__c> caseTransitionObjectList{get;set;}
    public string caseTransitionId {get;set;}
    public string transitionQuality {get;set;}
    public string transitionFeedback {get;set;}
    
    global SC_CaseTransitionHistoryController(ApexPages.StandardController stdController) {
        Id caseId = ApexPages.currentPage().getParameters().get('id');
        currentCase = [SELECT id,
                       		  ownerId,
                       		isClosed,	
                       		  has_active_transition__c
                       FROM case
                       WHERE id = :caseId
                       LIMIT 1];
    }
    
    public void updateTransition(){
        try{
            case_transition__c c = new case_transition__c(id=caseTransitionId);
            c.transition_quality__c = transitionQuality;
            c.Transition_Quality_Reason__c = transitionFeedback;
            update c;
            initialiseHistory();
        }
        catch(exception e){
            
        }
    }
    
    public void initialiseHistory(){
         caseTransitionObjectList = [SELECT case__c,
                                            id,
                                    		name,
                                            approved_date__c,
                                            Issue_Summary__c,
                                            Troubleshooting_to_Date__c,
                                            Data_Collected__c,
                                            Customer_Expectations__c,
                                            Next_Action_Recommendation__c,
                                            Approved_by__c,
                                            Target_Shift__c,
                                            Warm_Transition_Needed__c,
                                            New_Owner__c,
                                            new_owner__r.name,
                                            Previous_Owner__c,
                                            Previous_Owner__r.name, 
                                            previous_Shift__c,
                                            New_Shift__c,
                                            preevious_shift_assignment__c ,
                                            Next_Shift_Assignment__c,
                                            completed__c,
                                            violation__c,
                                            start_date__c,
                                            targetDate__c,
                                            Completed_Date__c ,
                                    		Time_Remaining__c,
                                    		Transition_Quality__c,
                                     		Transition_Quality_reason__c
                                    FROM  case_transition__c
                                    WHERE case__c = :currentCase.id
                                    AND Approved_by__c != null
                                    ORDER by createddate desc
                                    ];
    }
    
    public boolean getHistoryVisible(){
        return caseTransitionObjectList != null && caseTransitionObjectList.size() > 0;
    }
    
    public List<SelectOption> getTargetShiftValues(){
		List<SelectOption> options = new List<SelectOption>();
        
		Schema.DescribeFieldResult fieldResult = case_transition__c.Transition_Quality__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry f : ple) {
			options.add(new SelectOption(f.getLabel(), f.getValue()));
        }       
		return options;
	}
*/
}