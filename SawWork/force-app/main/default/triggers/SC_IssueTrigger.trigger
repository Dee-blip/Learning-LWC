/*=====================================================================================================+
    Trigger name        :   SC_IssueTrigger 
    Author              :   Akhila Vidapanapati
    Created             :   24-Jul-13
    Purpose             :   This trigger is called from Issue object when a issue record is inserted.
    Last Modified       :   23-OCT-13
    Purpose             :   Initial Development 
 
+=====================================================================================================*/


trigger SC_IssueTrigger on SC_Issues__c (After insert) {
    if (!SC_CaseTriggerHelperClass.flagvalue) {
        
        //List of issue objects
        List<Case_Issue__c> caseissuelist = new List<Case_Issue__c>();
        Case_Issue__c newCaseIssue;
        
        //List of case-issue formula field
        List<string> caseIssueFormulaList = new List<string>();
        List<Id> IssueIdList = new List<Id>();
        
        //For each new Issue object, create a corresponding Case-Issue object
        for(SC_Issues__c eachIssue : Trigger.new){
            
            if(eachIssue.related_Case__c <> NULL){
                newCaseIssue = new Case_Issue__c();
                newCaseIssue.related_Case__c = eachIssue.Related_Case__c;
                newCaseIssue.related_Issue__c=eachIssue.ID;
                caseissuelist.add(newCaseIssue); 
                
                if(eachIssue.Related_Case__c <> NULL){
                    caseIssueFormulaList.add(string.valueOf(eachIssue.related_Case__c).substring(0,15) + '-'+ eachIssue.Name);
                    //caseIssueFormulaList.add(eachIssue.Case_Issue__c);
                }
                IssueIdList.add(eachIssue.Id);
            }
        }
            system.debug('$$$$$');
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
        // Handling duplication
            if(caseIssueFormulaList.size() > 0){
                for(SC_Issues__c eachIssueRec : [select Id,Name,Related_Case__r.CaseNumber from SC_Issues__c where Case_Issue_Ext__c In :caseIssueFormulaList and Id Not In :IssueIdList])
                {
                    system.debug('...Inside Exception...');
                    Trigger.New[0].addError('Error : Duplicate Record for Combination Issue Id : CaseNumber = (' + eachIssueRec.Name + ' : ' + eachIssueRec.Related_Case__r.CaseNumber + ')');
                    break;
                }
            }
        
        }

        
        if(caseissuelist.size()>0){
            insert caseissuelist;
        }
    }   
}