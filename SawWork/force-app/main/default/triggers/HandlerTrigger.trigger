/*
Author          : Pinkesh / Sumukh SS
Description     : Apex Trigger for SOCC Car RunBooks Handler.
Test Class      : 

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh 								SOCC CAR 2 - RunBooks. Checks if user has access and checks for duplicates
------------------------------------------------------------------------------------------------------------------
*/
trigger HandlerTrigger on Handler__c (before insert,before update) 
{
    
    if(Trigger.isinsert)
    {
        //Collect all Policy Domains
        Set<Id> pdList = new set<Id>();
        
        for(Handler__c varHandler:Trigger.new)
        {
            pdList.add(varHandler.Policy_Domain__c); 
        }
        
        set<id> accids = new set<id>();
        list<policy_domain__c> accountidlist = [select Account_Name__c	from policy_domain__c where id IN :pdList];
        for(policy_domain__c eachrec : accountidlist)
            accids.add(eachrec.Account_Name__c);
        
        boolean access=SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(accids);
        
        if(access)
            SC_Handler_Trigger_Handler.checkHandlerDuplicates(Trigger.new);
        else
            trigger.new[0].addError('Insufficient privileges to create handler!');
    }
    
    if(Trigger.isUpdate)
    {
        List<Handler__c> listHandl = new List<Handler__c>();
        set<Id> pdList = new set<Id>();
        for(Handler__c varHandler:Trigger.new)
        {
            pdList.add(varHandler.Policy_Domain__c); 
        }
        
        set<id> accids = new set<id>();
        list<policy_domain__c> accountidlist = [select Account_Name__c	from policy_domain__c where id IN :pdList];
        for(policy_domain__c eachrec : accountidlist)
            accids.add(eachrec.Account_Name__c);
        
        
        boolean access=SC_SOCC_RUN_BOOK.getUserAccessToEditRecord(accids);
        if(access){
            for(Handler__c varHand:Trigger.New)
            {
                if(Trigger.OldMap.get(varHand.Id).Name!=Trigger.NewMap.get(varHand.Id).Name)
                {
                    listHandl.add(varHand);
                }
            }
            
            if(listHandl.size()>0)
            {
                SC_Handler_Trigger_Handler.checkHandlerDuplicates(listHandl);
            }
        }
        else
            trigger.new[0].addError('Insufficient privileges to update handler!');
        
    }
    
}