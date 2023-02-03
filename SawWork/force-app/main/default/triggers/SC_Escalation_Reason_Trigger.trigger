/*
Author          :  Pinkesh 
Description     :  Apex Trigger for SC_Escalation_Reason__c
Test Class      :  SC_Escalation_Reason_Trigger_TC

Date                 Developer				JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Jul 2020         Pinkesh					ESESP-3636      MSS Analytics
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_Escalation_Reason_Trigger on SC_Escalation_Reason__c (before insert) {
    
    if(Trigger.isBefore && Trigger.isInsert){
        Set<Id> sParentCaseId = new Set<Id>();
        List<SC_Escalation_Reason__c> lLatestEscalationReason = new List<SC_Escalation_Reason__c>();
        for(SC_Escalation_Reason__c eachRec : Trigger.new){
            if(sParentCaseId.add(eachRec.Case__c))
                lLatestEscalationReason.add(eachRec);
        }
		
        //Removing the Latest_Escalation__c flag on the existing records on the particular case
		List<SC_Escalation_Reason__c> lOldEscalationReason = [SELECT Id, Case__c, Latest_Escalation__c FROM SC_Escalation_Reason__c WHERE Case__c IN :sParentCaseId AND Latest_Escalation__c = TRUE];
        for(SC_Escalation_Reason__c eachRec : lOldEscalationReason){
            eachRec.Latest_Escalation__c = false;
        }
        
        if(lOldEscalationReason.size() > 0)
            update lOldEscalationReason;
		
        //Addding the Latest_Escalation__c flag on the newly/latest inserted record on the particular case
        for(SC_Escalation_Reason__c eachRec : lLatestEscalationReason){
            eachRec.Latest_Escalation__c = true;
        }
    }

}