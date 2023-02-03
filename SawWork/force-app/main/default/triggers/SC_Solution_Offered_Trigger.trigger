/*
Author          :  Pinkesh 
Description     :  Apex Trigger for SC_Solution_Offered__c
Test Class      :  SC_Solution_Offered_Trigger_TC

Date                 Developer				JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Jul 2020         Pinkesh					ESESP-3636      MSS Analytics
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_Solution_Offered_Trigger on SC_Solution_Offered__c (before insert) {
    if(Trigger.isBefore && Trigger.isInsert){
        Set<Id> sParentCaseId = new Set<Id>();
        List<SC_Solution_Offered__c> lLatestSolutionOffered = new List<SC_Solution_Offered__c>();
        for(SC_Solution_Offered__c eachRec : Trigger.new){
            if(sParentCaseId.add(eachRec.Case__c))
                lLatestSolutionOffered.add(eachRec);
        }
		
        //Removing the Latest_Solution__c flag on the existing records on the particular case
		List<SC_Solution_Offered__c> lOldSolutionOffered = [SELECT Id, Case__c, Latest_Solution__c FROM SC_Solution_Offered__c WHERE Case__c IN :sParentCaseId AND Latest_Solution__c = TRUE];
        for(SC_Solution_Offered__c eachRec : lOldSolutionOffered){
            eachRec.Latest_Solution__c = false;
        }
        
        if(lOldSolutionOffered.size() > 0)
            update lOldSolutionOffered;
		
        //Addding the Latest_Solution__c flag on the newly/latest inserted record on the particular case
        for(SC_Solution_Offered__c eachRec : lLatestSolutionOffered){
            eachRec.Latest_Solution__c = true;
        }
    }
}