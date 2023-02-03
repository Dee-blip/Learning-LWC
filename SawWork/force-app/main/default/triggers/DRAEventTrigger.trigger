trigger DRAEventTrigger on DRA_Process__e (after insert) {
    
    List<Account> accList = new List<Account>();
    for(DRA_Process__e evnt: Trigger.New){
        
        if(evnt.AccountID__c != null && evnt.AccountReassignRuleId__c  != null){
            Account acc = new Account();
            acc.Id = evnt.AccountID__c;
            acc.adg_Projected_Account_Owner__c = evnt.AccountReassignRuleId__c;
            accList.add(acc);
        }
    }
    Database.update(accList, false);

}