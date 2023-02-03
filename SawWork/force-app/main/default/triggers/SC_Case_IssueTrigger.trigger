/*=====================================================================================================+
    Trigger name        :   SC_Case_IssueTrigger 
    Author              :   Himanshu Kar
    Created             :   22-Aug-13
    Purpose             :   This trigger is called from Case Issue object and validates Duplicate issue Seletion.
    Last Modified       :   22-Aug-13
    Purpose             :   Initial Development
 
+=====================================================================================================*/


trigger SC_Case_IssueTrigger on Case_Issue__c (After insert) {
    
        
        //List of case-issue formula field
        List<string> caseIssueFormulaList = new List<string>();
        
        // Set To store Case-IssueId
        set<Id> caseIssueId = new set<Id>();
        
        //For each new Issue object, create a corresponding Case-Issue object
        for(Case_Issue__c eachCaseIssue : Trigger.new){
            
            caseIssueFormulaList.add(eachCaseIssue.CaseId_AKIssueId__c);
            caseIssueId.add(eachCaseIssue.Id);
                  
        }
            
        // Handling duplication
        if(caseIssueFormulaList.size() > 0){
            for(Case_Issue__c eachCaseIssueRec : [select Id,Related_Case__r.CaseNumber,Related_Issue__r.Name
                                                 from Case_Issue__c 
                                                 where CaseId_AKIssueId__c In :caseIssueFormulaList 
                                                 and Id Not In :caseIssueId
                                                 ])
            {
                
                Trigger.New[0].addError('Error : Duplicate Record for Combination Issue Id : CaseNumber = (' + 
                                        eachCaseIssueRec.Related_Issue__r.Name + ' : ' + 
                                        eachCaseIssueRec.Related_Case__r.CaseNumber + ')');
                break;
            }
        }

}