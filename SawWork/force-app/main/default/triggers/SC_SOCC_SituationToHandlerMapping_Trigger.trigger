/*
Author          :  Sumukh SS/Pinkesh 
Description     :  Apex Trigger for SOCC Car RunBooks
Test Class      :  SC_SOCC_RunBooks_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh 								SOCC CAR 2 - RunBooks 
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_SOCC_SituationToHandlerMapping_Trigger on SC_SOCC_Situation_to_Handler_Mapping__c (before insert, before update, after insert, after update, before delete, after delete)
{
    
    if(Trigger.isBefore && Trigger.isDelete){
        if(!SC_SOCC_Instruction_Manager.checkIfShiftManagerForS2HMapping())
            Trigger.old[0].addError('Only Shift Managers are allowed to delete an Situation To Handler Mapping. Please contact them.');
    }
    
    if(Trigger.isInsert)
    {
        //Collect all Policy Domains
        set<Id> pdList = new set<Id>();
        
        for(SC_SOCC_Situation_to_Handler_Mapping__c eachrec:Trigger.new)
        {
            pdList.add(eachrec.Policy_Domain__c); 
        }
        
         set<id> accids = new set<id>();
        list<policy_domain__c> accountidlist = [select Account_Name__c	from policy_domain__c where id IN :pdList];
        for(policy_domain__c eachrec : accountidlist)
            accids.add(eachrec.Account_Name__c);
        
        //Checking if user has access to the record
        boolean access=SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(accids);
        if(!access)
        {
            Trigger.new[0].addError('Insufficient privileges to create a situation to handler mapping!');
        }
        
    }
}