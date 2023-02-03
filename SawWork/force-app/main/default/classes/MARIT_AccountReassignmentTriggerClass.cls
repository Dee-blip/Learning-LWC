public without sharing class MARIT_AccountReassignmentTriggerClass {
    
    public static void createPlatformPublisher(Map<Id, Id> accToRuleIDMap){
        
        List<DRA_Process__e> eventList = new List<DRA_Process__e>();
        Map<Id, Id> reassignRuleToOwnerIDMap = new Map<Id, Id>();
        //Either below queries can be moved to Consumer part and save two queries from current transaction but then for each new Request record, an event will be published
        //Might change based on feedback
        List<Account> accList = [Select id, name, ownerId, adg_Projected_Account_Owner__c from Account where id in :accToRuleIDMap.keySet() and (adg_Projected_Account_Owner__r.Name LIKE 'OLD_%')];
        
        if(accList!= null && !accList.isEmpty()){
            List<Account_Reassignment_Rule__c> newReassignRuleList = [Select id, Associated_User__c from Account_Reassignment_Rule__c  where id in :accToRuleIDMap.values()];
            
            for(Account_Reassignment_Rule__c ar : newReassignRuleList){
                reassignRuleToOwnerIDMap.put(ar.id, ar.Associated_User__c);
            }
            for(Account acc: accList){
                //Will publish event only if Account's PAO doesn't match with Account Reassignment Request's Rule record ID AND
                //Account's Owner is equal to Account's Reassignment Request's Rule's Owner (and that's the actual case when Marketing PAO logic is not getting triggered)
                if(accToRuleIDMap.containsKey(acc.Id) && acc.adg_Projected_Account_Owner__c != accToRuleIDMap.get(acc.Id)
                    && acc.OwnerId == reassignRuleToOwnerIDMap.get(accToRuleIDMap.get(acc.Id)) ){
                    DRA_Process__e evnt = new DRA_Process__e();
                    evnt.AccountID__c  = acc.id;
                    evnt.AccountReassignRuleId__c = accToRuleIDMap.get(acc.Id);
                    eventList.add(evnt);
                }
            }
            EventBus.publish(eventList);
        }
    }

}